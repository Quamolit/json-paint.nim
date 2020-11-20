
import cairo
import json
import math

import ./error_util
import ./color_util
import ./touches
import ./types

var verboseMode* = false

type TreeContext* = object
  x*: float
  y*: float

proc readPointVec(raw: JsonNode): JsonPosition =
  if raw.kind != JArray:
    return (0.0, 0.0)
  if raw.elems.len < 2:
    echo "WARNING: too few numbers for a position"
    return (0.0, 0.0)
  let x = raw.elems[0].getFloat
  let y = raw.elems[1].getFloat
  return (x, y)

# mutual recursion
proc processJsonTree*(ctx: ptr Context, tree: JsonNode, base: TreeContext): void

proc renderArc(ctx: ptr Context, tree: JsonNode, base: TreeContext) =
  ctx.newPath()
  let x = base.x + (if tree.contains("x"): tree["x"].getFloat else: 0)
  let y = base.y + (if tree.contains("y"): tree["y"].getFloat else: 0)
  let radius = if tree.contains("radius"): tree["radius"].getFloat else: 20
  let startAngle = if tree.contains("start-angle"): tree["start-angle"].getFloat else: 0
  let endAngle = if tree.contains("end-angle"): tree["end-angle"].getFloat else: 2 * PI
  let negative = if tree.contains("negative?"): tree["negative?"].getBool else: false

  if negative:
    ctx.arcNegative(x, y, radius, startAngle, endAngle)
  else:
    ctx.arc(x, y, radius, startAngle, endAngle)

  let hasStroke = tree.contains("stroke-color")
  let hasFill = tree.contains("fill-color")
  if hasStroke:
    let color = readJsonColor(tree["stroke-color"])
    ctx.setSourceRgba(color.r, color.g, color.b, color.a)
    let lineWidth = if tree.contains("line-width"): tree["lineWidth"].getFloat else: 1.0
    ctx.setLineWidth(lineWidth)
    if hasFill:
      ctx.strokePreserve()
    else:
      ctx.stroke()

  if hasFill:
    let color = readJsonColor(tree["fill-color"])
    ctx.setSourceRgba(color.r, color.g, color.b, color.a)
    ctx.closePath()
    ctx.fill()

  if hasStroke.not and hasFill.not:
    echo "WARNING: arc is invisible."

proc renderGroup(ctx: ptr Context, tree: JsonNode, base: TreeContext) =
  if tree.contains("children"):
    let x = if tree.contains("x"): tree["x"].getFloat else: 0
    let y = if tree.contains("y"): tree["y"].getFloat else: 0
    let children = tree["children"]
    if children.kind == JArray:
      for item in children.elems:
        let newBase = TreeContext(x: base.x + x, y: base.y + y)
        ctx.processJsonTree item, newBase
    else:
      showError("Unknown children" & $children.kind)

proc renderPolyline(ctx: ptr Context, tree: JsonNode, base: TreeContext) =
  ctx.newPath()
  let basePoint: JsonPosition = if tree.contains("from"): readPointVec(tree["from"]) else: (0.0, 0.0)
  ctx.moveTo basePoint.x + base.x, basePoint.y + base.y
  let skipFirst = if tree.contains("skip-first?"): tree["skip-first?"].getBool else: false
  if tree.contains("stops"):
    let stops = tree["stops"]
    if stops.kind != JArray: showError("Expects array of stops")
    for idx, stop in stops.elems:
      let point = readPointVec(stop)
      if skipFirst and idx == 0:
        ctx.moveTo point.x + base.x, point.y + base.y
      else:
        ctx.lineTo point.x + base.x, point.y + base.y
  elif tree.contains("relative-stops"):
    let stops = tree["relative-stops"]
    if stops.kind != JArray: showError("Expects array of relative stops")
    for idx, stop in stops.elems:
      let point = readPointVec(stop)
      if skipFirst and idx == 0:
        ctx.moveTo basePoint.x + point.x + base.x, basePoint.y + point.y + base.y
      else:
        ctx.lineTo basePoint.x + point.x + base.x, basePoint.y + point.y + base.y
  else:
    echo "WARNING: stops not defined"

  let hasFill = tree.contains("fill-color")
  let hasStroke = tree.contains("stroke-color")
  if hasStroke:
    let color = readJsonColor(tree["stroke-color"])
    ctx.setSourceRgba(color.r, color.g, color.b, color.a)
    if tree.contains("line-width"):
      ctx.setLineWidth tree["line-width"].getFloat
    if tree.contains("line-join"):
      case tree["line-join"].getStr
      of "round":
        ctx.setLineJoin LineJoinRound
      of "milter":
        ctx.setLineJoin LineJoinMiter
      of "bevel":
        ctx.setLineJoin LineJoinBevel
      else:
        echo "WARNING: unknown line-join: ", tree["line-join"]
    if hasFill:
      ctx.strokePreserve()
    else:
      ctx.stroke()
  elif hasFill:
    let color = readJsonColor(tree["stroke-color"])
    ctx.setSourceRgba(color.r, color.g, color.b, color.a)
    ctx.fill()

proc renderText(ctx: ptr Context, tree: JsonNode, base: TreeContext) =
  ctx.newPath()
  let x = base.x + (if tree.contains("x"): tree["x"].getFloat else: 0)
  let y = base.y + (if tree.contains("y"): tree["y"].getFloat else: 0)
  let fontSize = if tree.contains("font-size"): tree["font-size"].getFloat else: 14
  let text = if tree.contains("text"): tree["text"].getStr else: "TEXT"
  let align = if tree.contains("align"): tree["align"].getStr else: "left"
  let fontFamily = if tree.contains("font-family"): tree["font-family"].getStr else: "Arial"
  let color = if tree.contains("color"): readJsonColor(tree["color"]) else: failedColor
  ctx.selectFontFace text.cstring, FontSlantNormal, FontWeightNormal
  ctx.setFontSize fontSize
  ctx.setSourceRgba(color.r, color.g, color.b, color.a)
  var extents: TextExtents
  ctx.textExtents text.cstring, addr extents
  var realX = x - extents.xBearing
  case align
  of "center":
    realX = x - extents.width / 2 - extents.xBearing
  of "right":
    realX = x - extents.width - extents.xBearing
  of "left":
    discard
  else:
    echo "WARNING: unknown align value " & align & ", expects left, center, right"
  let realY = y - extents.height / 2 - extents.yBearing
  ctx.moveTo realX, realY
  ctx.showText text

proc callOps(ctx: ptr Context, tree: JsonNode, base: TreeContext) =
  ctx.newPath()
  if tree.contains("ops").not or tree["ops"].kind != JArray: showError("Expects `ops` field")
  for item in tree["ops"].elems:
    if item.kind != JArray: showError("Expects list in ops")
    if item.elems.len < 1: showError("Expects `type` field at index `0`")
    let opType = item[0].getStr
    case opType
    of "move-to":
      if item.elems.len < 2: showError("Expects a point at index 1")
      let point = readPointVec item[1]
      ctx.moveTo point.x + base.x, point.y + base.y
    of "stroke":
      ctx.stroke()
    of "fill":
      ctx.fill()
    of "stroke-preserve":
      ctx.strokePreserve()
    of "fill-preserve":
      ctx.fillPreserve()
    of "line-width":
      if item.elems.len < 2: showError("Expects width at index 1")
      ctx.setLineWidth item.elems[1].getFloat
    of "source-rgb":
      if item.elems.len < 2: showError("Expects color at index 1 for source-rgb")
      let color = readJsonColor(item.elems[1])
      ctx.setSourceRgba color.r, color.g, color.b, color.a
    of "line-to":
      if item.elems.len < 2: showError("Expects point at index 1 for line-to")
      let point = readPointVec item.elems[1]
      ctx.lineTo point.x + base.x, point.y + base.y
    of "relative-line-to":
      if item.elems.len < 2: showError("Expects point at index 1 for relative-line-to")
      let point = readPointVec item.elems[1]
      ctx.relLineTo point.x, point.y
    of "curve-to":
      if item.elems.len < 4: showError("Expects 3 points for curve-to")
      let p0 = readPointVec item.elems[1]
      let p1 = readPointVec item.elems[2]
      let p2 = readPointVec item.elems[3]
      ctx.curveTo p0.x + base.x, p0.y + base.y, p1.x + base.x, p1.y + base.y, p2.x + base.x, p2.y + base.y
    of "relative-curve-to":
      if item.elems.len < 4: showError("Expects 3 points for relative-curve-to")
      let p0 = readPointVec item.elems[1]
      let p1 = readPointVec item.elems[2]
      let p2 = readPointVec item.elems[3]
      ctx.relCurveTo p0.x, p0.y, p1.x, p1.y, p2.x, p2.y
    of "arc":
      if item.elems.len < 4: showError("Expects 3~4 points for arc")
      let point = readPointVec item.elems[1]
      let radius = item.elems[2].getFloat
      let angle = readPointVec item.elems[3] # actuall start-angle/end-angle

      let negative = if tree.elems.len >= 5: tree.elems[4].getBool else: false

      if negative:
        ctx.arcNegative(point.x + base.x, point.y + base.y, radius, angle.x, angle.y)
      else:
        ctx.arc(point.x + base.x, point.y + base.y, radius, angle.x, angle.y)
    of "rectangle":
      if item.elems.len < 3: showError("Expects 2 arguments for rectangle")
      let point = readPointVec item.elems[1]
      let size = readPointVec item.elems[2]
      ctx.rectangle point.x + base.x, point.y + base.y, size.x, size.y
    of "close-path":
      ctx.closePath()
    of "new-path":
      ctx.newPath()
    else:
      echo "WARNING: unknown op type: ", opType

proc renderTouchArea(ctx: ptr Context, tree: JsonNode, base: TreeContext) =
  ctx.newPath()
  let x = base.x + (if tree.contains("x"): tree["x"].getFloat else: 0)
  let y = base.y + (if tree.contains("y"): tree["y"].getFloat else: 0)
  let radius = if tree.contains("radius"): tree["radius"].getFloat else: 20

  ctx.arc(x, y, radius, 0, 2 * PI)

  ctx.closePath()

  ctx.setSourceRgba(0.9, 0.9, 0.5, 0.3)
  ctx.setLineWidth(1.0)
  ctx.strokePreserve()

  ctx.setSourceRgba(0.7, 0.5, 0.8, 0.2)
  ctx.fill()

  addTouchArea(x, y, radius, tree)

proc processJsonTree*(ctx: ptr Context, tree: JsonNode, base: TreeContext) =
  if verboseMode:
    echo tree.pretty

  case tree.kind
  of JArray:
    for item in tree.elems:
      ctx.processJsonTree(item, base)
  of JObject:
    if tree.contains("type"):
      let nodeType = tree["type"].getStr
      case nodeType
      of "arc":
        ctx.renderArc(tree, base)
      of "group":
        ctx.renderGroup(tree, base)
      of "polyline":
        ctx.renderPolyline(tree, base)
      of "text":
        ctx.renderText(tree, base)
      of "ops":
        ctx.callOps(tree, base)
      of "touch-area":
        ctx.renderTouchArea(tree, base)
      else:
        echo tree.pretty
        showError("Unknown type")
    else:
      showError("Expects a `type` field on JSON data")
  else:
    echo "Invalid JSON node:"
    echo pretty(tree)
    showError("Unexpected JSON structure for rendering")
