
import json

import ./types
import ./error_util

type KeyListener* = object
  key*: string
  path*: JsonNode
  action*: JsonNode
  data*: JsonNode

var keyListenersStack: seq[KeyListener]

proc resetKeyListenerStack*() =
  keyListenersStack = @[]

proc addKeyListener*() =
  discard

proc findKeyListener*() =
  discard

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
