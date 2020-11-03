
import cairo
import json
import math

import ./error_util
import ./color_util

var verboseMode* = false

type JsonPosition = tuple[x: float, y: float]

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
proc processJsonTree*(ctx: ptr Context, tree: JsonNode): void

proc renderArc(ctx: ptr Context, tree: JsonNode) =
  let x = if tree.contains("x"): tree["x"].getFloat else: 0
  let y = if tree.contains("y"): tree["y"].getFloat else: 0
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

proc renderGroup(ctx: ptr Context, tree: JsonNode) =
  if tree.contains("children"):
    let children = tree["children"]
    if children.kind == JArray:
      for item in children.elems:
        ctx.processJsonTree item
    else:
      showError("Unknown children" & $children.kind)

proc renderPolyline(ctx: ptr Context, tree: JsonNode) =
  let basePoint: JsonPosition = if tree.contains("from"): readPointVec(tree["from"]) else: (0.0, 0.0)
  ctx.moveTo basePoint.x, basePoint.y
  if tree.contains("stops"):
    let stops = tree["stops"]
    if stops.kind != JArray: showError("Expects array of stops")
    for stop in stops.elems:
      let point = readPointVec(stop)
      ctx.lineTo point.x, point.y
  elif tree.contains("relative-stops"):
    let stops = tree["stops"]
    if stops.kind != JArray: showError("Expects array of relative stops")
    for stop in stops.elems:
      let point = readPointVec(stop)
      ctx.lineTo basePoint.x + point.x, basePoint.y + point.y
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

proc renderText(ctx: ptr Context, tree: JsonNode) =
  let x = if tree.contains("x"): tree["x"].getFloat else: 0
  let y = if tree.contains("y"): tree["y"].getFloat else: 0
  let fontSize = if tree.contains("font-size"): tree["font-size"].getFloat else: 14
  let text = if tree.contains("text"): tree["text"].getStr else: "TEXT"
  let align = if tree.contains("align"): tree["align"].getStr else: "left"
  let fontFamily = if tree.contains("font-family"): tree["font-family"].getStr else: "Arial"
  let color = if tree.contains("color"): readJsonColor(tree["color"]) else: failedColor
  ctx.selectFontFace text.cstring, FontSlantNormal, FontWeightNormal
  ctx.setFontSize fontSize
  var extents: TextExtents
  ctx.textExtents text.cstring, addr extents
  var realX = x - extents.xBearing
  case text
  of "center":
    realX = x - extents.width / 2 - extents.xBearing
  of "right":
    realX = x - extents.width - extents.xBearing
  else:
    discard
  let realY = y - extents.height / 2 - extents.yBearing
  ctx.moveTo realX, realY
  ctx.showText text

proc callOps(ctx: ptr Context, tree: JsonNode) =
  if tree.contains("ops").not or tree["ops"].kind != JArray: showError("Expects `ops` field")
  for item in tree["ops"].elems:
    if item.contains("type").not: showError("Expects `type` field")
    let opType = item["type"].getStr
    case opType
    of "move-to":
      let x = if item.contains("x"): item["x"].getFloat else: 0
      let y = if item.contains("y"): item["y"].getFloat else: 0
      ctx.moveTo x, y
    of "stroke":
      ctx.stroke()
    of "fill":
      ctx.fill()
    of "stroke-preserve":
      ctx.strokePreserve()
    of "fill-preserve":
      ctx.fillPreserve()
    of "line-width":
      let width = if item.contains("width"): item["width"].getFloat else: 0
      ctx.setLineWidth width
    of "source-rgb":
      let color = if item.contains("color"): readJsonColor(item["color"]) else: failedColor
      ctx.setSourceRgba color.r, color.g, color.b, color.a
    of "line-to":
      let x = if item.contains("x"): item["x"].getFloat else: 0
      let y = if item.contains("y"): item["y"].getFloat else: 0
      ctx.lineTo x, y
    of "relative-line-to":
      let x = if item.contains("x"): item["x"].getFloat else: 0
      let y = if item.contains("y"): item["y"].getFloat else: 0
      ctx.relLineTo x, y
    of "curve-to":
      if item.contains("path").not: showError("Expects `path` field in curve")
      let controlPoints = item["path"]
      if controlPoints.kind != JArray or controlPoints.elems.len < 3: showError("Expects path or 3")
      let p0 = readPointVec controlPoints.elems[0]
      let p1 = readPointVec controlPoints.elems[1]
      let p2 = readPointVec controlPoints.elems[2]
      ctx.curveTo p0.x, p0.y, p1.x, p1.y, p2.x, p2.y
    of "relative-curve-to":
      if item.contains("path").not: showError("Expects `path` field in curve")
      let controlPoints = item["path"]
      if controlPoints.kind != JArray or controlPoints.elems.len < 3: showError("Expects path or 3")
      let p0 = readPointVec controlPoints.elems[0]
      let p1 = readPointVec controlPoints.elems[1]
      let p2 = readPointVec controlPoints.elems[2]
      ctx.relCurveTo p0.x, p0.y, p1.x, p1.y, p2.x, p2.y
    of "arc":
      renderArc(ctx, item)
    else:
      echo "WARNING: unknown op type: ", opType

proc processJsonTree*(ctx: ptr Context, tree: JsonNode) =
  if verboseMode:
    echo tree.pretty

  case tree.kind
  of JArray:
    for item in tree.elems:
      ctx.processJsonTree(item)
  of JObject:
    if tree.contains("type"):
      let nodeType = tree["type"].getStr
      case nodeType
      of "arc":
        ctx.renderArc(tree)
      of "group":
        ctx.renderGroup(tree)
      of "polyline":
        ctx.renderPolyline(tree)
      of "text":
        ctx.renderText(tree)
      of "ops":
        ctx.callOps(tree)
      else:
        echo tree.pretty
        showError("Unknown type")
    else:
      showError("Expects a `type` field on JSON data")
  else:
    echo "Invalid JSON node:"
    echo pretty(tree)
    showError("Unexpected JSON structure for rendering")
