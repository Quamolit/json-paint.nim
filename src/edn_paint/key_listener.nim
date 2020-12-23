
import cirru_edn

import ./error_util
import ./edn_util

type KeyListener* = object
  key*: string
  path*: CirruEdnValue
  action*: CirruEdnValue
  data*: CirruEdnValue

var keyListenersStack: seq[KeyListener]

proc resetKeyListenerStack*() =
  keyListenersStack = @[]

proc addKeyListener*(tree: CirruEdnValue) =
  if tree.kind != crEdnMap: showError("Expects object for touch area")
  if tree.contains("key").not: showError("Expects key field")
  if tree.contains("path").not: showError("Expects path field")
  if tree.contains("action").not: showError("Expects action field")

  keyListenersStack.add(KeyListener(
    key: tree.getStr("key"),
    path: tree["path"],
    action: tree["action"],
    data: if tree.contains("data"): tree["data"] else: genCrEdn()
  ))

proc findKeyListener*(k: string): seq[KeyListener] =
  for item in keyListenersStack:
    # echo "looking for k: ", k, " ", item
    if item.key == k:
      result.add(item)

# https://wiki.libsdl.org/SDLKeycodeLookup
proc attachKeyName*(k: int): string =
  if k < 128:
    case k
      of 0: "unknown"
      of 8: "backspace"
      of 9: "tab"
      of 13: "return"
      of 27: "escape"
      of 32: "space"
      else: $char(k)
  else:
    case k
      of 0x40000052: "up"
      of 0x40000051: "down"
      of 0x40000050: "left"
      of 0x4000004f: "right"
      of 0x4000007A: "undo"
      of 0x4000007B: "cup"
      of 0x4000007C: "copy"
      of 0x4000007D: "paste"
      of 0x4000009C: "clear"
      # left
      of 0x400000E0: "ctrl"
      of 0x400000E1: "shift"
      of 0x400000E2: "alt"
      # right
      of 0x400000E4: "ctrl"
      of 0x400000E5: "shift"
      of 0x400000E6: "alt"
      else:
        "key_" & $k
