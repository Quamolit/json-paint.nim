
import asyncdispatch
import json_paint/canvas

proc ap1() {.async.} =
  initCanvas("This is a title", 600, 300)
  startRenderLoop()

discard ap1()

echo "doing"
