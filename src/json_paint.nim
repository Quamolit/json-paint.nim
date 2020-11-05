
import sdl2
import cairo
import json

import json_paint/shape_renderer
import json_paint/color_util

var surface: ptr cairo.Surface
var renderer: RendererPtr
var mainSurface: sdl2.SurfacePtr
var window: WindowPtr

var bgBlack: RgbaColor = (0.0, 0.0, 0.0, 1.0)

const
  rmask = uint32 0x00ff0000
  gmask = uint32 0x0000ff00
  bmask = uint32 0x000000ff
  amask = uint32 0xff000000

proc initCanvas*(title: string, w: int, h: int, bg: RgbaColor = bgBlack) =

  discard sdl2.init(INIT_EVERYTHING)

  # window = createWindow(title, 0, 0, cint w, cint h, SDL_WINDOW_SHOWN)
  window = createWindow(title, 0, 0, cint w, cint h, SDL_WINDOW_RESIZABLE)

  surface = imageSurfaceCreate(FORMAT_ARGB32, cint w, cint h)
  renderer = createRenderer(window, -1, 0)

  bgBlack = bg

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

proc takeCanvasEvents*(handleEvent: proc(e: JsonNode):void) =
  var event: sdl2.Event
  while pollEvent(event):
    case event.kind
    of MouseMotion:
      # echo "mouse motion: ", event.motion.x, ",", event.motion.y, " ", event.motion[]
      handleEvent(%* {
        "type": "mouse-motion",
        "x": event.motion.x,
        "y": event.motion.y
      })
    of KeyDown:
      # echo "keydown event: ", event.key[]
      handleEvent(%* {
        "type": "key-down",
        "sym": event.key.keysym.sym,
        "repeat": event.key.repeat,
        "scancode": $event.key.keysym.scancode,
      })
    of TextInput:
      # echo "input: ", event.text.text[0]
      handleEvent(%* {
        "type": "text-input",
        "text": $event.text.text[0]
      })
    of KeyUp:
      handleEvent(%* {
        "type": "key-up",
        "sym": event.key.keysym.sym,
        "repeat": event.key.repeat,
        "scancode": $event.key.keysym.scancode,
      })
    of QuitEvent:
      handleEvent(%* {
        "type": "quit"
      })
    of MouseButtonDown:
      # echo "mouse down: ", event.button[]
      handleEvent(%* {
        "type": "mouse-button-down",
        "clicks": event.button[].clicks,
        "x": event.button[].x,
        "y": event.button[].y,
      })
    of MouseButtonUp:
      # echo "mouse up: ", event.button[]
      handleEvent(%* {
        "type": "mouse-button-up",
        "clicks": event.button[].clicks,
        "x": event.button[].x,
        "y": event.button[].y,
      })
    of WindowEvent:
      # echo "window event: ", event.window[]
      case event.window[].event
      of WindowEvent_Resized:
        let newSize = window.getSize()

        surface = imageSurfaceCreate(FORMAT_ARGB32, cint newSize.x, cint newSize.y)
        mainSurface = createRGBSurface(0, cint newSize.x, cint newSize.y, 32, rmask, gmask, bmask, amask)

        handleEvent(%* {
          "type": "window-resized",
          "x": newSize.x,
          "y": newSize.y,
        })
      else:

        handleEvent(%* {
          "type": "window",
          "event": $event.window[].event
        })

    of AudioDeviceAdded:
      discard
    of ClipboardUpdate:
      discard
    else:
      echo "unkown event kind: ", event.kind

proc setJsonPaintVerbose*(v: bool) =
  verboseMode = v

export RgbaColor, hslToRgb
