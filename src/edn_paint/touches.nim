
import options
import math

import cirru_edn

import ./error_util
import ./types
import ./edn_util

var mousedownPoint: EdnPosition
var mousedownTracked* = false
var mousedownTrackedAction*: CirruEdnValue
var mousedownTrackedPath*: CirruEdnValue
var mousedownTrackedData*: CirruEdnValue

type TouchEvent* = enum
  touchDown,
  touchMotion,
  touchUp,

type TouchArea* = object
  x: float
  y: float
  dx: float
  dy: float
  inRect: bool
  path*: CirruEdnValue
  action*: CirruEdnValue
  data*: CirruEdnValue

var touchItemsStack: seq[TouchArea]

proc resetTouchStack*() =
  touchItemsStack = @[]

proc addTouchArea*(x: float, y: float, dx: float, dy: float, inRect: bool, tree: CirruEdnValue) =
  if tree.kind != crEdnMap: showError("Expects object for touch area")
  if tree.contains("path").not: showError("Expects path field")
  if tree.contains("action").not: showError("Expects action field")

  touchItemsStack.add TouchArea(
    x: x, y: y, dx: dx, dy: dy, inRect: inRect,
    path: tree["path"],
    action: tree["action"],
    data: if tree.contains("data"): tree["data"] else: genCrEdn()
  )

proc findTouchArea*(x: cint, y: cint, eventKind: TouchEvent): Option[TouchArea] =
  let lastIdx = touchItemsStack.len - 1
  for idx in 0..lastIdx:
    let item = touchItemsStack[lastIdx - idx]
    if item.inRect:
      if (x.float - item.x).abs < item.dx and (y.float - item.y).abs <= item.dy:
        return some(item)
    else:
      if (x.float - item.x).pow(2) + (y.float - item.y).pow(2) <= item.dx.pow(2):
        return some(item)
  return none(TouchArea)

proc trackMousedownPoint*(x, y: int) =
  mousedownPoint.x = x.float
  mousedownPoint.y = y.float

proc calcMousePositionDelta*(x, y: int): EdnPosition =
  (x.float - mousedownPoint.x, y.float - mousedownPoint.y)
