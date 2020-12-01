
import sdl2
import cairo
import json
import options
import times
import math

import json_paint/shape_renderer
import json_paint/color_util
import json_paint/touches

var surface: ptr cairo.Surface
var renderer: RendererPtr
var mainSurface: sdl2.SurfacePtr
var window: WindowPtr

var windowWidth = 0
var windowHeight = 0

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
  windowWidth = w
  windowHeight = h

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

  let base = TreeContext(x: 0, y: 0)
  resetTouchStack()

  let t0 = cpuTime()
  ctx.processJsonTree(tree, base)
  let costTime = cpuTime() - t0
  renderCostTime(ctx, costTime * 1000, windowWidth, windowHeight, base)

  ctx.destroy()

  # cairo surface -> sdl serface -> sdl texture -> copy to render
  var dataPtr = surface.getData()
  mainSurface.pixels = dataPtr
  let mainTexture = renderer.createTextureFromSurface(mainSurface)
  renderer.copy(mainTexture, nil, nil)
  renderer.present()
  mainTexture.destroy()

proc takeCanvasEvents*(handleEvent: proc(e: JsonNode):void) =
  var event: sdl2.Event
  while pollEvent(event):
    case event.kind
    of MouseMotion:
      # echo "mouse motion: ", event.motion.x, ",", event.motion.y, " ", event.motion[]
      let x = event.motion.x
      let y = event.motion.y

      let moved = calcMousePositionDelta(x, y)

      if mousedownTracked:
        handleEvent(%* {
          "type": "mouse-move",
          "x": event.motion.x,
          "y": event.motion.y,
          "dx": moved.x,
          "dy": moved.y,
          "path": mousedownTrackedPath,
          "action": mousedownTrackedAction,
          "data": mousedownTrackedData,
        })
      else:
        handleEvent(%* {
          "type": "mouse-move",
          "x": event.motion.x,
          "y": event.motion.y,
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
      let x = event.button[].x
      let y = event.button[].y
      let target = findTouchArea(x, y, touchDown)


      if target.isSome:
        trackMousedownPoint(x, y)
        mousedownTracked = true
        mousedownTrackedPath = target.get.path
        mousedownTrackedAction = target.get.action
        mousedownTrackedData = target.get.data

        handleEvent(%* {
          "type": "mouse-down",
          "clicks": event.button[].clicks,
          "path": target.get.path,
          "action": target.get.action,
          "data": target.get.data,
          "x": x,
          "y": y,
        })
      else:
        handleEvent(%* {
          "type": "mouse-down",
          "clicks": event.button[].clicks,
          "x": x,
          "y": y,
        })
    of MouseButtonUp:
      # echo "mouse up: ", event.button[]
      let x = event.button[].x
      let y = event.button[].y

      if mousedownTracked:
        let moved = calcMousePositionDelta(x, y)
        handleEvent(%* {
          "type": "mouse-up",
          "clicks": event.button[].clicks,
          "path": mousedownTrackedPath,
          "action": mousedownTrackedAction,
          "data": mousedownTrackedData,
          "x": event.button[].x,
          "y": event.button[].y,
          "dx": moved.x,
          "dy": moved.y,
        })
        mousedownTracked = false

      else:
        handleEvent(%* {
          "type": "mouse-up",
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

        windowWidth = newSize.x
        windowHeight = newSize.y
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
