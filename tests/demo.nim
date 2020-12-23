
# import asyncdispatch
import tables
import os

import cirru_edn

import edn_paint
import edn_paint/edn_util

# probably just a demo for using
proc startRenderLoop() =
  renderCanvas(genCrEdnMap(
    kwd("type"), genCrEdn("arc"),
    kwd("position"), genCrEdnVector(genCrEdn(20), genCrEdn(20)),
    kwd("radius"), genCrEdn(40),
    kwd("line-color"), genCrEdnVector(genCrEdn(200), genCrEdn(80), genCrEdn(71),genCrEdn( 0.4)),
    kwd("fill-color"), genCrEdnVector(genCrEdn(200), genCrEdn(80), genCrEdn(72),genCrEdn( 0.4)),
  ))

  while true:
    echo "loop"
    sleep(400)
    takeCanvasEvents(proc(event: CirruEdnValue) =
      echo "event: ", event
    )

proc renderSomething() =
  renderCanvas(genCrEdnMap(
    kwd("type"), genCrEdn("group"),
    kwd("position"), genCrEdnVector(genCrEdn(100), genCrEdn(30)),
    kwd("children"), genCrEdnVector(
      genCrEdnMap(
        kwd("type"), genCrEdn("arc"),
        kwd("position"), numbersVec([20, 20]),
        kwd("radius"), genCrEdn(40),
        kwd("stroke-color"), numbersVec([20, 80, 73]),
        kwd("fill-color"), numbersVec([60, 80, 74]),
      ),
      genCrEdnMap(
        kwd("type"), genCrEdn("polyline"),
        kwd("position"), numbersVec([10, 10]),
        kwd("skip-first?"), genCrEdn(true),
        kwd("stops"), genCrEdnVector(
          numbersVec([40, 40]), numbersVec([40, 80]), numbersVec([70, 90]), numbersVec([200, 200])
        ),
        kwd("line-width"), genCrEdn(2),
        kwd("stroke-color"), numbersVec([100, 80, 75]),
      ),
      genCrEdnMap(
        kwd("type"), genCrEdn("text"),
        kwd("text"), genCrEdn("this is a demo"),
        kwd("align"), genCrEdn("center"),
        kwd("font-face"), genCrEdn("Menlo"),
        kwd("font-weight"), genCrEdn("normal"),
        kwd("position"), numbersVec([40, 40]),
        kwd("color"), numbersVec([140, 80, 76]),
      ),
      genCrEdnMap(
        kwd("type"), genCrEdn("ops"),
        kwd("position"), numbersVec([0, 0]),
        kwd("ops"), genCrEdnVector(
          genCrEdnVector(kwd("move-to"), numbersVec([100, 100])),
          genCrEdnVector(kwd("move-to"), numbersVec([300, 200])),
          genCrEdnVector(kwd("source-rgb"), numbersVec([180, 80, 77])),
          genCrEdnVector(kwd("stroke")),
          genCrEdnVector(kwd("rectangle"), numbersVec([200, 200]), numbersVec([40, 40])),
          genCrEdnVector(kwd("stroke")),
        )
      ),
      genCrEdnMap(
        kwd("type"), genCrEdn("touch-area"),
        kwd("position"), numbersVec([200, 80]),
        kwd("path"), numbersVec([2, 1]),
        kwd("radius"), genCrEdn(6),
        kwd("action"), genCrEdn(":demo"),
        kwd("fill-color"), numbersVec([200, 80, 30]),
        kwd("stroke-color"), numbersVec([200, 60, 90]),
        kwd("line-width"), genCrEdn(2),
      ),
      genCrEdnMap(
        kwd("type"), genCrEdn("touch-area"),
        kwd("position"), numbersVec([300, 120]),
        kwd("rect?"), genCrEdn(true),
        kwd("path"), numbersVec([1, 2]),
        kwd("action"), genCrEdn(":demo-rect"),
        kwd("dx"), genCrEdn(80),
        kwd("dy"), genCrEdn(40),
        kwd("fill-color"), numbersVec([0, 80, 70]),
        kwd("stroke-color"), numbersVec([200, 60, 90]),
        kwd("line-width"), genCrEdn(2),
      ),
      genCrEdnMap(
        kwd("type"), genCrEdn("ops"),
        kwd("ops"), genCrEdnVector(
          genCrEdnVector(kwd("arc"), numbersVec([100, 100]), genCrEdn(10), numbersVec([0, 6]), genCrEdn(false)),
          genCrEdnVector(kwd("source-rgb"), numbersVec([0, 80, 80])),
          genCrEdnVector(kwd("fill")),
        )
      ),
      genCrEdn(),
      genCrEdnMap(
        kwd("type"), genCrEdn("key-listener"),
        kwd("key"), genCrEdn("a"),
        kwd("path"), numbersVec([1, 1]),
        kwd("action"), genCrEdn(":hit-key"),
        kwd("data"), genCrEdn("demo data")
      ),
    )
  ))

proc ap1() =
  let bg = hslToRgb(0,0,10,1)
  initCanvas("This is a title", 600, 300, bg)
  renderSomething()

  while true:
    sleep(160)
    takeCanvasEvents(proc(event: CirruEdnValue) =
      if event.kind == crEdnMap:
        let t = event.mapVal[genCrEdnKeyword("type")]
        if t.kind != crEdnString:
          raise newException(ValueError, "expects string type")
        case t.stringVal
        of "quit":
          quit 0
        of "window-resized":
          renderSomething()
        else:
          echo "event: ", event
    )

ap1()

echo "doing"
