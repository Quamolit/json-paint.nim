
import json
import options
import sets
import math

import ./error_util

type TouchEvent* = enum
  touchDown,
  touchMotion,
  touchUp,

type TouchArea* = object
  x: float
  y: float
  radius: float
  path*: JsonNode
  events: HashSet[TouchEvent]

var touchItemsStack: seq[TouchArea]

proc resetTouchStack*() =
  touchItemsStack = @[]

proc addTouchArea*(x: float, y: float, radius: float, tree: JsonNode) =
  var area: TouchArea
  if tree.kind != JObject: showError("Expects object for touch area")
  if tree.contains("path").not: showError("Expects path field")
  let path = tree["path"]
  var events: HashSet[TouchEvent]
  if tree.contains("events"):
    for item in tree["events"].elems:
      if item.kind == JString:
        case item.getStr
          of "touch-down":
            events.incl(touchDown)
          of "touch-up":
            events.incl(touchUp)
          of "touch-motion":
            events.incl(touchMotion)
          else:
            showError("Unexpected event: " & item.getStr)
      else:
        echo "Expects string for event, got: ", item.kind

  touchItemsStack.add TouchArea(x: x, y: y, radius: radius, path: path, events: events)

proc findTouchArea*(x: cint, y: cint, eventKind: TouchEvent): Option[TouchArea] =
  let lastIdx = touchItemsStack.len - 1
  for idx in 0..lastIdx:
    let item = touchItemsStack[lastIdx - idx]
    if item.events.contains(eventKind):
      if (x.float - item.x).pow(2) + (y.float - item.y).pow(2) <= item.radius.pow(2):
        return some(item)
  return none(TouchArea)
