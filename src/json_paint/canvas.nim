
import sdl2
import cairo

const
  rmask = uint32 0x00ff0000
  gmask = uint32 0x0000ff00
  bmask = uint32 0x000000ff
  amask = uint32 0xff000000

var surface: ptr cairo.Surface
var renderer: RendererPtr
var mainSurface: sdl2.SurfacePtr

proc initCanvas*(title: string, w: int, h: int) =

  discard sdl2.init(INIT_EVERYTHING)

  let window = createWindow(title, 0, 0, cint w, cint h, SDL_WINDOW_SHOWN)
  surface = imageSurfaceCreate(FORMAT_ARGB32, cint w, cint h)
  renderer = createRenderer(window, -1, 0)
  mainSurface = createRGBSurface(0, cint w, cint h, 32, rmask, gmask, bmask, amask)

proc renderCanvas*(a: bool) =
  ## Called every frame by main while loop

  # draw shiny sphere on gradient background
  var ctx = surface.create()

  echo ctx.getOperator()

  ctx.setSourceRGB(0.3, 0.3, 0.3)
  ctx.setOperator(OperatorSource)
  ctx.paint()

  ctx.setOperator(OperatorOver)

  if a:
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

proc startRenderLoop*() =
  renderCanvas(true)

  while true:
    echo "loop"
    delay(400)
    takeCanvasEvents()
