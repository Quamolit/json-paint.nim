
import json
import options
import math

import ./error_util
import ./types

var mousedownPoint: JsonPosition
var mousedownTracked* = false
var mousedownTrackedAction*: JsonNode
var mousedownTrackedPath*: JsonNode
var mousedownTrackedData*: JsonNode

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
  path*: JsonNode
  action*: JsonNode
  data*: JsonNode

var touchItemsStack: seq[TouchArea]

proc resetTouchStack*() =
  touchItemsStack = @[]

proc addTouchArea*(x: float, y: float, dx: float, dy: float, inRect: bool, tree: JsonNode) =
  if tree.kind != JObject: showError("Expects object for touch area")
  if tree.contains("path").not: showError("Expects path field")
  if tree.contains("action").not: showError("Expects action field")

  touchItemsStack.add TouchArea(
    x: x, y: y, dx: dx, dy: dy, inRect: inRect,
    path: tree["path"],
    action: tree["action"],
    data: if tree.contains("data"): tree["data"] else: newJNull()
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

proc calcMousePositionDelta*(x, y: int): JsonPosition =
  (x.float - mousedownPoint.x, y.float - mousedownPoint.y)
