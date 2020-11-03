
import sdl2
import cairo
import json

import json_paint/shape_renderer
import json_paint/color_util

var surface: ptr cairo.Surface
var renderer: RendererPtr
var mainSurface: sdl2.SurfacePtr

var bgBlack: RgbaColor = (0.0, 0.0, 0.0, 1.0)

proc initCanvas*(title: string, w: int, h: int, bg: RgbaColor = bgBlack) =

  discard sdl2.init(INIT_EVERYTHING)

  let window = createWindow(title, 0, 0, cint w, cint h, SDL_WINDOW_SHOWN)
  surface = imageSurfaceCreate(FORMAT_ARGB32, cint w, cint h)
  renderer = createRenderer(window, -1, 0)

  bgBlack = bg
  const
    rmask = uint32 0x00ff0000
    gmask = uint32 0x0000ff00
    bmask = uint32 0x000000ff
    amask = uint32 0xff000000

  mainSurface = createRGBSurface(0, cint w, cint h, 32, rmask, gmask, bmask, amask)

proc renderCanvas*(tree: JsonNode) =
  ## Called every frame by main while loop

  # draw shiny sphere on gradient background
  var ctx = surface.create()

  # clear whole canvas before redraw
  ctx.setSourceRGB(bgBlack.r, bgBlack.g, bgBlack.b)
  ctx.setOperator(OperatorSource)
  ctx.paint()

  # reset operator
  ctx.setOperator(OperatorOver)

  ctx.processJsonTree(tree)

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

proc setJsonPaintVerbose*(v: bool) =
  verboseMode = v

export RgbaColor, hslToRgb
