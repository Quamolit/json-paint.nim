
import sdl2
import cairo
import options
import times

import cirru_edn

import edn_paint/shape_renderer
import edn_paint/color_util
import edn_paint/touches
import edn_paint/key_listener
import edn_paint/edn_util

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

proc renderCanvas*(tree: CirruEdnValue) =
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
  resetKeyListenerStack()

  let t0 = cpuTime()
  ctx.processEdnTree(tree, base)
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

proc takeCanvasEvents*(handleEvent: proc(e: CirruEdnValue):void) =
  var event: sdl2.Event
  while pollEvent(event):
    case event.kind
    of MouseMotion:
      # echo "mouse motion: ", event.motion.x, ",", event.motion.y, " ", event.motion[]
      let x = event.motion.x
      let y = event.motion.y

      let moved = calcMousePositionDelta(x, y)

      if mousedownTracked:
        handleEvent(genCrEdnMap(
          kwd("type"), genCrEdn("mouse-move"),
          kwd("x"), genCrEdn(event.motion.x),
          kwd("y"), genCrEdn(event.motion.y),
          kwd("dx"), genCrEdn(moved.x),
          kwd("dy"), genCrEdn(moved.y),
          kwd("path"), mousedownTrackedPath,
          kwd("action"), mousedownTrackedAction,
          kwd("data"), mousedownTrackedData,
        ))
      else:
        handleEvent(genCrEdnMap(
          kwd("type"), genCrEdn("mouse-move"),
          kwd("x"), genCrEdn(event.motion.x),
          kwd("y"), genCrEdn(event.motion.y),
        ))
    of TextInput:
      # echo "input: ", event.text.text[0]
      handleEvent(genCrEdnMap(
        kwd("type"), genCrEdn("text-input"),
        kwd("text"), genCrEdn($event.text.text[0]),
      ))
    of KeyDown:
      # echo "keydown event: ", event.key[]
      let name = attachKeyName(event.key.keysym.sym)
      let targets = findKeyListener(name)
      # echo "targets", targets, " ", name
      if targets.len > 0:
        for item in targets:
          handleEvent(genCrEdnMap(
            kwd("type"), genCrEdn("key-down"),
            kwd("sym"), genCrEdn(event.key.keysym.sym),
            kwd("repeat"), genCrEdn(event.key.repeat),
            kwd("scancode"), genCrEdn($event.key.keysym.scancode),
            kwd("name"), genCrEdn(attachKeyName(event.key.keysym.sym)),
            kwd("path"), item.path,
            kwd("action"), item.action,
            kwd("data"), item.data,
          ))
      else:
        handleEvent(genCrEdnMap(
          kwd("type"), genCrEdn("key-down"),
          kwd("sym"), genCrEdn(event.key.keysym.sym),
          kwd("repeat"), genCrEdn(event.key.repeat),
          kwd("scancode"), genCrEdn($event.key.keysym.scancode),
          kwd("name"), genCrEdn(attachKeyName(event.key.keysym.sym))
        ))
    of KeyUp:
      let name = attachKeyName(event.key.keysym.sym)
      let targets = findKeyListener(name)
      if targets.len > 0:
        for item in targets:
          handleEvent(genCrEdnMap(
            kwd("type"), genCrEdn("key-up"),
            kwd("sym"), genCrEdn(event.key.keysym.sym),
            kwd("repeat"), genCrEdn(event.key.repeat),
            kwd("scancode"), genCrEdn($event.key.keysym.scancode),
            kwd("name"), genCrEdn(name),
            kwd("path"), item.path,
            kwd("action"), item.action,
            kwd("data"), item.data,
          ))
      else:
        handleEvent(genCrEdnMap(
          kwd("type"), genCrEdn("key-up"),
          kwd("sym"), genCrEdn(event.key.keysym.sym),
          kwd("repeat"), genCrEdn(event.key.repeat),
          kwd("scancode"), genCrEdn($event.key.keysym.scancode),
          kwd("name"), genCrEdn(name),
        ))
    of QuitEvent:
      handleEvent(genCrEdnMap(
        kwd("type"), genCrEdn("quit")
      ))
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

        handleEvent(genCrEdnMap(
          kwd("type"), genCrEdn("mouse-down"),
          kwd("clicks"), genCrEdn(event.button[].clicks.float),
          kwd("x"), genCrEdn(x),
          kwd("y"), genCrEdn(y),
          kwd("path"), target.get.path,
          kwd("action"), target.get.action,
          kwd("data"), target.get.data,
        ))
      else:
        handleEvent(genCrEdnMap(
          kwd("type"), genCrEdn("mouse-down"),
          kwd("clicks"), genCrEdn(event.button[].clicks.float),
          kwd("x"), genCrEdn(x),
          kwd("y"), genCrEdn(y),
        ))
    of MouseButtonUp:
      # echo "mouse up: ", event.button[]
      let x = event.button[].x
      let y = event.button[].y

      if mousedownTracked:
        let moved = calcMousePositionDelta(x, y)
        handleEvent(genCrEdnMap(
          kwd("type"), genCrEdn("mouse-up"),
          kwd("clicks"), genCrEdn(event.button[].clicks.float),
          kwd("x"), genCrEdn(event.button[].x),
          kwd("y"), genCrEdn(event.button[].y),
          kwd("dx"), genCrEdn(moved.x),
          kwd("dy"), genCrEdn(moved.y),
          kwd("path"), mousedownTrackedPath,
          kwd("action"), mousedownTrackedAction,
          kwd("data"), mousedownTrackedData,
        ))
        mousedownTracked = false

      else:
        handleEvent(genCrEdnMap(
          kwd("type"), genCrEdn("mouse-up"),
          kwd("clicks"), genCrEdn(event.button[].clicks.float),
          kwd("x"), genCrEdn(event.button[].x),
          kwd("y"), genCrEdn(event.button[].y),
        ))

    of WindowEvent:
      # echo "window event: ", event.window[]
      case event.window[].event
      of WindowEvent_Resized:
        let newSize = window.getSize()

        surface = imageSurfaceCreate(FORMAT_ARGB32, cint newSize.x, cint newSize.y)
        mainSurface = createRGBSurface(0, cint newSize.x, cint newSize.y, 32, rmask, gmask, bmask, amask)

        windowWidth = newSize.x
        windowHeight = newSize.y
        handleEvent(genCrEdnMap(
          kwd("type"), genCrEdn("window-resized"),
          kwd("x"), genCrEdn(newSize.x),
          kwd("y"), genCrEdn(newSize.y),
        ))
      else:

        handleEvent(genCrEdnMap(
          kwd("type"), genCrEdn("window"),
          kwd("event"), genCrEdn($event.window[].event),
        ))

    of AudioDeviceAdded:
      discard
    of ClipboardUpdate:
      discard
    else:
      echo "unkown event kind: ", event.kind

proc setEdnPaintVerbose*(v: bool) =
  verboseMode = v

export RgbaColor, hslToRgb
