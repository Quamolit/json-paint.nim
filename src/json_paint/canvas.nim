
import sdl2, sdl2/gfx, math, random
import cairo

const
  rmask = uint32 0x000000ff
  gmask = uint32 0x0000ff00
  bmask = uint32 0x00ff0000
  amask = uint32 0xff000000

const
  w = 256
  h = 256

discard sdl2.init(INIT_EVERYTHING)

let window = createWindow("Real time SDL/Cairo example", 100, 100, cint w, cint h, SDL_WINDOW_SHOWN)
let surface = imageSurfaceCreate(FORMAT_ARGB32, 256, 256)
let render = createRenderer(window, -1, 0)

var mainSerface = createRGBSurface(0, cint w, cint h, 32, rmask, gmask, bmask, amask)

proc display() =
  ## Called every frame by main while loop

  # draw shiny sphere on gradient background
  var ctx = surface.create()

  ctx.moveTo(128.0, 25.6)
  ctx.lineTo(230.4, 230.4)
  ctx.rel_lineTo(-102.4, 0.0)
  ctx.curveTo(51.2, 230.4, 51.2, 128.0, 128.0, 128.0)
  ctx.close_path()

  ctx.moveTo(64.0, 25.6)
  ctx.relLineTo(51.2, 51.2)
  ctx.relLineTo(-51.2, 51.2)
  ctx.relLineTo(-51.2, -51.2)
  ctx.closePath()

  ctx.setLineWidth(10.0)
  ctx.setSourceRGB(1, 1, 0)
  ctx.fillPreserve()
  ctx.setSourceRGB(0, 1, 0)
  ctx.stroke()

  # cairo surface -> sdl serface -> sdl texture -> copy to render
  var dataPtr = surface.getData()
  mainSerface.pixels = dataPtr
  let mainTexture = render.createTextureFromSurface(mainSerface)
  render.copy(mainTexture, nil, nil)
  render.present()

while true:
  var event = sdl2.defaultEvent
  while pollEvent(event):
    echo "event: ", event
    if event.kind == QuitEvent:
      quit(0)
  delay(14)
  display()
