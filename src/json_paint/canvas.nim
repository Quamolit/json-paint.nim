
import sdl2
import cairo
import json
import math

import ./errors

const
  rmask = uint32 0x00ff0000
  gmask = uint32 0x0000ff00
  bmask = uint32 0x000000ff
  amask = uint32 0xff000000

var surface: ptr cairo.Surface
var renderer: RendererPtr
var mainSurface: sdl2.SurfacePtr

var verboseMode = false

type Color = tuple[r: float, g: float, b: float, a: float]

proc rgb*(r, g, b, a: float = 1): Color =
  return (r: r/100, g: g/100, b: b/100, a: a)

const failedColor: Color = (100.0, 0.0, 0.0, 1.0)

# fallbacks to red
proc readJsonColor*(raw: JsonNode): Color =
  if raw.kind != JObject:
    return failedColor
  let r = if raw.contains("r"): raw["r"].getFloat else: 0
  let g = if raw.contains("g"): raw["g"].getFloat else: 0
  let b = if raw.contains("b"): raw["b"].getFloat else: 0
  let a = if raw.contains("a"): raw["a"].getFloat else: 1
  return rgb(r, g, b, a)

proc initCanvas*(title: string, w: int, h: int) =

  discard sdl2.init(INIT_EVERYTHING)

  let window = createWindow(title, 0, 0, cint w, cint h, SDL_WINDOW_SHOWN)
  surface = imageSurfaceCreate(FORMAT_ARGB32, cint w, cint h)
  renderer = createRenderer(window, -1, 0)
  mainSurface = createRGBSurface(0, cint w, cint h, 32, rmask, gmask, bmask, amask)

proc processJsonTree(ctx: ptr Context, tree: JsonNode) =
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
        let x = if tree.contains("x"): tree["x"].getFloat else: 0
        let y = if tree.contains("y"): tree["y"].getFloat else: 0
        let radius = if tree.contains("radius"): tree["radius"].getFloat else: 20
        let startAngle = if tree.contains("start-angle"): tree["start-angle"].getFloat else: 0
        let endAngle = if tree.contains("end-angle"): tree["end-angle"].getFloat else: 2 * PI
        let negative = if tree.contains("negative?"): tree["negative?"].getBool else: false
        echo "running arc:", x, y, radius
        if negative:
          ctx.arcNegative(x, y, radius, startAngle, endAngle)
        else:
          ctx.arc(x, y, radius, startAngle, endAngle)

        let hasLine = tree.contains("line-color")
        let hasFill = tree.contains("fill-color")
        if hasLine:
          let color = readJsonColor(tree["line-color"])
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
          ctx.fill()

        if hasLine.not and hasFill.not:
          echo "WARNING: arc is invisible."

      else:
        echo tree.pretty
        showError("Unknown type")
    else:
      raise newException(ValueError, "Expects a `type` field on JSON data")
  else:
    echo "Invalid JSON node:"
    echo pretty(tree)
    raise newException(ValueError, "Unexpected JSON structure for rendering")

proc renderCanvas*(tree: JsonNode) =
  ## Called every frame by main while loop

  # draw shiny sphere on gradient background
  var ctx = surface.create()

  # clear whole canvas before redraw
  ctx.setSourceRGB(0.3, 0.3, 0.3)
  ctx.setOperator(OperatorSource)
  ctx.paint()

  # reset operator
  ctx.setOperator(OperatorOver)

  ctx.processJsonTree(tree)

  if true:
    ctx.moveTo(128.0, 25.6)
    ctx.lineTo(230.4, 230.4)
    ctx.rel_lineTo(-102.4, 0.0)
    ctx.curveTo(51.2, 230.4, 51.2, 128.0, 128.0, 128.0)
    ctx.close_path()
  else:
    ctx.moveTo(64.0, 25.6)
    ctx.relLineTo(51.2, 51.2)
    ctx.relLineTo(-51.2, 51.2)
    ctx.relLineTo(-51.2, -51.2)
    ctx.closePath()

  ctx.setLineWidth(10.0)
  ctx.setSourceRGB(1, 0.4, 0.4)
  ctx.fillPreserve()
  ctx.setSourceRGB(0.4, 0.4, 1)
  ctx.stroke()

  # cairo surface -> sdl serface -> sdl texture -> copy to render
  var dataPtr = surface.getData()
  mainSurface.pixels = dataPtr
  let mainTexture = renderer.createTextureFromSurface(mainSurface)
  renderer.copy(mainTexture, nil, nil)
  renderer.present()

proc takeCanvasEvents*() =
  var event: sdl2.Event
  while pollEvent(event):
    discard
    # if event.kind != MouseMotion:
    #   echo "event: ", event.kind
    if event.kind == QuitEvent:
      quit(0)

# probably just a demo for using
proc startRenderLoop*() =
  renderCanvas(%* {
    "type": "arc",
    "x": 20,
    "y": 20,
    "radius": 40,
    "line-color": {
      "r": 50,
      "g": 80,
      "b": 80
    },
    "fill-color": {
      "r": 20,
      "g": 20,
      "b": 80
    }
  })

  while true:
    echo "loop"
    delay(400)
    takeCanvasEvents()

proc setJsonPaintVervose*(v: bool) =
  verboseMode = v
