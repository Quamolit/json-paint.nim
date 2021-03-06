
# import asyncdispatch
import json
import os

import json_paint

# probably just a demo for using
proc startRenderLoop() =
  renderCanvas(%* {
    "type": "arc",
    "position": [20, 20],
    "radius": 40,
    "line-color": [200, 80, 71, 0.4],
    "fill-color": [200, 80, 72, 0.4]
  })

  while true:
    echo "loop"
    sleep(400)
    takeCanvasEvents(proc(event: JsonNode) =
      echo "event: ", event
    )

proc renderSomething() =
  renderCanvas(%* {
    "type": "group",
    "position": [100, 30],
    "children": [
      {
        "type": "arc",
        "position": [20, 20],
        "radius": 40,
        "stroke-color": [20, 80, 73],
        "fill-color": [60, 80, 74]
      },
      {
        "type": "polyline",
        "position": [10, 10],
        "skip-first?": true,
        "stops": [
          [40, 40], [40, 80], [70, 90], [200, 200]
        ],
        "line-width": 2,
        "stroke-color": [100, 80, 75]
      },
      {
        "type": "text",
        "text": "this is a demo",
        "align": "center",
        "font-face": "Menlo",
        "font-weight": "normal",
        "position": [40, 40],
        "color": [140, 80, 76]
      },
      {
        "type": "ops",
        "position": [0, 0],
        "ops": [
          ["move-to", [100, 100]],
          ["move-to", [300, 200]],
          ["source-rgb", [180, 80, 77]],
          ["stroke"],
          ["rectangle", [200, 200], [40, 40]],
          ["stroke"]
        ]
      },
      {
        "type": "touch-area",
        "position": [200, 80],
        "path": ["a", 1],
        "radius": 6,
        "action": ":demo",
        "fill-color": [200, 80, 30],
        "stroke-color": [200, 60, 90],
        "line-width": 2,
      },
      {
        "type": "touch-area",
        "position": [300, 120],
        "rect?": true,
        "path": ["a", 2],
        "action": ":demo-rect",
        "dx": 80,
        "dy": 40,
        "fill-color": [0, 80, 70],
        "stroke-color": [200, 60, 90],
        "line-width": 2,
      },
      {
        "type": "ops",
        "ops": [
          ["arc", [100, 100], 10, [0, 6.2], false],
          ["source-rgb", [0, 80, 80]],
          ["fill"],
        ]
      },
      nil,
      {
        "type": "key-listener",
        "key": "a",
        "path": ["a", 1],
        "action": ":hit-key",
        "data": "demo data"
      },
    ]
  })

proc ap1() =
  let bg = hslToRgb(0,0,10,1)
  initCanvas("This is a title", 600, 300, bg)
  renderSomething()

  while true:
    sleep(160)
    takeCanvasEvents(proc(event: JsonNode) =
      if event.kind == JObject:
        case event["type"].getStr
        of "quit":
          quit 0
        of "window-resized":
          renderSomething()
        else:
          echo "event: ", event
    )

ap1()

echo "doing"
