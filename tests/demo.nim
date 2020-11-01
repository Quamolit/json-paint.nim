
# import asyncdispatch
import json
import os

import json_paint/canvas

proc ap1() =
  initCanvas("This is a title", 600, 300)
  renderCanvas(%* {
    "type": "arc",
    "x": 20,
    "y": 20,
    "radius": 40,
    "line-color": {
      "r": 50,
      "g": 80,
      "b": 80
    },
    "fill-color": {
      "r": 20,
      "g": 20,
      "b": 80
    }
  })

  while true:
    echo "loop"
    sleep(400)
    takeCanvasEvents()

ap1()

echo "doing"
