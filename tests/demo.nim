
# import asyncdispatch
import json
import os

import json_paint

# probably just a demo for using
proc startRenderLoop() =
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

proc ap1() =
  let bg: RgbaColor = (0.1,0.1,0.1,1.0)
  initCanvas("This is a title", 600, 300, bg)
  renderCanvas(%* {
    "type": "group",
    "children": [
      {
        "type": "arc",
        "x": 20,
        "y": 20,
        "radius": 40,
        "stroke-color": {
          "r": 50,
          "g": 80,
          "b": 80
        },
        "fill-color": {
          "r": 20,
          "g": 20,
          "b": 80
        }
      },
      {
        "type": "polyline",
        "from": [10, 10],
        "stops": [
          [40, 40], [40, 80], [70, 90], [200, 200]
        ],
        "line-width": 2,
        "stroke-color": {"r": 100, "g": 100, "b": 10}
      },
      {
        "type": "text",
        "text": "this is a demo",
        "align": "left",
        "x": 40,
        "y": 40,
        "color": {
          "r": 80, "g": "90", "b": "70"
        }
      },
      {
        "type": "ops",
        "ops": [
          {
            "type": "move-to",
            "x": 100,
            "y": 100
          },
          {
            "type": "line-to",
            "x": 300,
            "y": 200,
          },
          {
            "type": "source-rgb",
            "color": {
              "r": 80,
              "g": 70,
              "b": 40
            }
          },
          {
            "type": "stroke"
          }
        ]
      }
    ]
  })

  while true:
    echo "loop"
    sleep(400)
    takeCanvasEvents()

ap1()

echo "doing"
