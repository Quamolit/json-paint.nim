
import cairo
import math
import tables

import cirru_edn
import cirru_edn/gen

import ./error_util
import ./color_util
import ./edn_util
import ./touches
import ./types
import ./key_listener

var verboseMode* = false

type TreeContext* = object
  x*: float
  y*: float

proc readPointVec(raw: CirruEdnValue): EdnPosition =
  if raw.kind != crEdnVector:
    return (0.0, 0.0)
  if raw.vectorVal.len < 2:
    echo "WARNING: too few numbers for a position"
    return (0.0, 0.0)
  if raw.vectorVal[0].kind != crEdnNumber: showError("Expects number for a point")
  let x = raw.vectorVal[0].numberVal
  if raw.vectorVal[1].kind != crEdnNumber: showError("Expects number for a point")
  let y = raw.vectorVal[1].numberVal
  return (x, y)

# mutual recursion
proc processEdnTree*(ctx: ptr Context, tree: CirruEdnValue, base: TreeContext): void

proc renderArc(ctx: ptr Context, tree: CirruEdnValue, base: TreeContext) =
  ctx.newPath()
  if tree.kind != crEdnMap: showError("Expects arc options in map")
  let position = if tree.contains("position"): readPointVec(tree.mapVal[genCrEdnKeyword("position")]) else: (0.0, 0.0)
  let x = base.x + position.x
  let y = base.y + position.y
  let radius = if tree.contains("radius"): tree.getFloat("radius") else: 20
  let startAngle = if tree.contains("start-angle"): tree.getFloat("start-angle") else: 0
  let endAngle = if tree.contains("end-angle"): tree.getFloat("end-angle") else: 2 * PI
  let negative = if tree.contains("negative?"): tree.getBool("negative?") else: false

  if negative:
    ctx.arcNegative(x, y, radius, startAngle, endAngle)
  else:
    ctx.arc(x, y, radius, startAngle, endAngle)

  let hasStroke = tree.contains("stroke-color")
  let hasFill = tree.contains("fill-color")
  if hasStroke:
    let color = readEdnColor(tree[kwd("stroke-color")])
    ctx.setSourceRgba(color.r, color.g, color.b, color.a)
    let lineWidth = if tree.contains("line-width"): tree.getFloat("line-width") else: 1.0
    ctx.setLineWidth(lineWidth)
    if hasFill:
      ctx.strokePreserve()
    else:
      ctx.stroke()

  if hasFill:
    let color = readEdnColor(tree["fill-color"])
    ctx.setSourceRgba(color.r, color.g, color.b, color.a)
    ctx.closePath()
    ctx.fill()

  if hasStroke.not and hasFill.not:
    echo "WARNING: arc is invisible."

proc renderGroup(ctx: ptr Context, tree: CirruEdnValue, base: TreeContext) =
  if tree.contains("children"):
    let position = if tree.contains("position"): readPointVec(tree["position"]) else: (0.0, 0.0)
    let children = tree["children"]
    if children.kind == crEdnVector:
      for item in children.vectorVal:
        let newBase = TreeContext(x: base.x + position.x, y: base.y + position.y)
        ctx.processEdnTree item, newBase
    else:
      showError("Unknown children" & $children.kind)

proc renderPolyline(ctx: ptr Context, tree: CirruEdnValue, base: TreeContext) =
  ctx.newPath()
  let position: EdnPosition = if tree.contains("position"): readPointVec(tree["position"]) else: (0.0, 0.0)
  ctx.moveTo position.x + base.x, position.y + base.y
  if tree.contains("stops"):
    let stops = tree["stops"]
    if stops.kind != crEdnVector: showError("Expects vector stops, but got " & $stops.kind)
    for idx, stop in stops.vectorVal:
      let point = readPointVec(stop)
      if idx == 0:
        ctx.moveTo position.x + point.x + base.x, position.y + point.y + base.y
      else:
        ctx.lineTo position.x + point.x + base.x, position.y + point.y + base.y
  else:
    echo "WARNING: stops not defined"

  let hasFill = tree.contains("fill-color")
  let hasStroke = tree.contains("stroke-color")
  if hasStroke:
    let color = readEdnColor(tree["stroke-color"])
    ctx.setSourceRgba(color.r, color.g, color.b, color.a)
    if tree.contains("line-width"):
      ctx.setLineWidth tree.getFloat("line-width")
    if tree.contains("line-join"):
      case tree.getStr("line-join")
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
    let color = readEdnColor(tree["stroke-color"])
    ctx.setSourceRgba(color.r, color.g, color.b, color.a)
    ctx.fill()

proc renderText(ctx: ptr Context, tree: CirruEdnValue, base: TreeContext) =
  ctx.newPath()
  let position = if tree.contains("position"): readPointVec(tree["position"]) else: (0.0, 0.0)
  let x = base.x + position.x
  let y = base.y + position.y
  let fontSize = if tree.contains("font-size"): tree.getFloat("font-size") else: 14
  let text = if tree.contains("text"): tree.getStr("text") else: "TEXT"
  let align = if tree.contains("align"): tree.getStr("align") else: "left"
  let fontFace = if tree.contains("font-face"): tree.getStr("font-face") else: "Arial"
  let color = if tree.contains("color"): readEdnColor(tree["color"]) else: failedColor
  var weight = FontWeightNormal
  if tree.contains("font-weight") and tree.getStr("font-weight") == "bold":
    weight = FontWeightBold
  ctx.selectFontFace fontFace.cstring, FontSlantNormal, weight
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

proc callOps(ctx: ptr Context, tree: CirruEdnValue, parentBase: TreeContext) =
  let position = if tree.contains("position"): readPointVec(tree["position"]) else: (0.0, 0.0)
  let base = TreeContext(x: parentBase.x + position.x, y: parentBase.y + position.y)
  ctx.newPath()
  if tree.contains("ops").not or tree["ops"].kind != crEdnVector: showError("Expects `ops` field")
  for item in tree["ops"].vectorVal:
    if item.kind != crEdnVector: showError("Expects list in ops")
    if item.vectorVal.len < 1: showError("Expects `type` field at index `0`")
    let opType = item.getStr(0)
    case opType
    of "move-to":
      if item.vectorVal.len < 2: showError("Expects a point at index 1")
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
      if item.vectorVal.len < 2: showError("Expects width at index 1")
      ctx.setLineWidth item.getFloat(1)
    of "source-rgb", "hsl":
      if item.vectorVal.len < 2: showError("Expects color at index 1 for source-rgb")
      let color = readEdnColor(item[1])
      ctx.setSourceRgba color.r, color.g, color.b, color.a
    of "line-to":
      if item.vectorVal.len < 2: showError("Expects point at index 1 for line-to")
      let point = readPointVec item[1]
      ctx.lineTo point.x + base.x, point.y + base.y
    of "relative-line-to":
      if item.vectorVal.len < 2: showError("Expects point at index 1 for relative-line-to")
      let point = readPointVec item[1]
      ctx.relLineTo point.x, point.y
    of "curve-to":
      if item.vectorVal.len < 4: showError("Expects 3 points for curve-to")
      let p0 = readPointVec item[1]
      let p1 = readPointVec item[2]
      let p2 = readPointVec item[3]
      ctx.curveTo p0.x + base.x, p0.y + base.y, p1.x + base.x, p1.y + base.y, p2.x + base.x, p2.y + base.y
    of "relative-curve-to":
      if item.vectorVal.len < 4: showError("Expects 3 points for relative-curve-to")
      let p0 = readPointVec item[1]
      let p1 = readPointVec item[2]
      let p2 = readPointVec item[3]
      ctx.relCurveTo p0.x, p0.y, p1.x, p1.y, p2.x, p2.y
    of "arc":
      if item.vectorVal.len < 4: showError("Expects 3~4 points for arc")
      let point = readPointVec item[1]
      let radius = item.getFloat(2)
      let angle = readPointVec item[3] # actuall start-angle/end-angle

      let negative = if item.vectorVal.len >= 5: item.getBool(4) else: false

      if negative:
        ctx.arcNegative(point.x + base.x, point.y + base.y, radius, angle.x, angle.y)
      else:
        ctx.arc(point.x + base.x, point.y + base.y, radius, angle.x, angle.y)
    of "rectangle":
      if item.vectorVal.len < 3: showError("Expects 2 arguments for rectangle")
      let point = readPointVec item[1]
      let size = readPointVec item[2]
      ctx.rectangle point.x + base.x, point.y + base.y, size.x, size.y
    of "close-path":
      ctx.closePath()
    of "new-path":
      ctx.newPath()
    else:
      echo "WARNING: unknown op type: ", opType

proc renderTouchArea(ctx: ptr Context, tree: CirruEdnValue, base: TreeContext) =
  ctx.newPath()
  let position: EdnPosition = if tree.contains("position"): readPointVec(tree["position"]) else: (0.0, 0.0)
  let x = base.x + position.x
  let y = base.y + position.y

  let rectMode = if tree.contains("rect?"): tree.getBool("rect?") else: false
  if rectMode:
    let dx = if tree.contains("dx"): tree.getFloat("dx") else: 20
    let dy = if tree.contains("dy"): tree.getFloat("dy") else: 10
    ctx.rectangle x - dx, y - dy, 2 * dx, 2 * dy
    addTouchArea(x, y, dx, dy, true, tree)

  else:
    let radius = if tree.contains("radius"): tree.getFloat("radius") else: 20
    ctx.arc(x, y, radius, 0, 2 * PI)
    addTouchArea(x, y, radius, radius, false, tree)

  ctx.closePath()

  if tree.contains("stroke-color"):
    let color = readEdnColor(tree["stroke-color"])
    ctx.setSourceRgba(color.r, color.g, color.b, color.a)
  else:
    ctx.setSourceRgba(0.9, 0.9, 0.5, 0.3)

  let lineWidth = if tree.contains("line-width"): tree.getFloat("line-width") else: 1.0
  ctx.setLineWidth(lineWidth)
  ctx.strokePreserve()

  if tree.contains("fill-color"):
    let color = readEdnColor(tree["fill-color"])
    ctx.setSourceRgba(color.r, color.g, color.b, color.a)
  else:
    ctx.setSourceRgba(0.7, 0.5, 0.8, 0.2)

  ctx.fill()

proc renderKeyListener*(ctx: ptr Context, tree: CirruEdnValue) =
  addKeyListener(tree)

proc processEdnTree*(ctx: ptr Context, tree: CirruEdnValue, base: TreeContext) =
  if verboseMode:
    echo $tree

  if tree.kind == crEdnNil:
    return

  case tree.kind
  of crEdnVector:
    for item in tree.vectorVal:
      ctx.processEdnTree(item, base)
  of crEdnMap:
    if tree.contains("type"):
      let nodeType = tree.getStr("type")
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
      of "key-listener":
        ctx.renderKeyListener(tree)
      else:
        echo $tree
        showError("Unknown type: " & nodeType)
    else:
      showError("Expects a `type` field on EDN data: " & $tree)
  else:
    echo "Invalid EDN node:"
    echo $(tree)
    showError("Unexpected EDN structure for rendering")

proc renderCostTime*(ctx: ptr Context, cost: float, width: int, height: int, base: TreeContext) =
  ctx.processEdnTree(genCrEdnMap(
      kwd("type"), genCrEdn("text"),
      kwd("text"), genCrEdn($cost.round(1) & "ms"),
      kwd("x"), genCrEdn(width - 8),
      kwd("y"), genCrEdn(8),
      kwd("color"), genCrEdnVector(genCrEdn(200), genCrEdn(90), genCrEdn(90), genCrEdn(0.6)),
      kwd("font-size"), genCrEdn(10),
      kwd("font-face"), genCrEdn("monospace"),
      kwd("align"), genCrEdn("right"),
    ), base)
