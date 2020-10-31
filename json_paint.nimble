# Package

version       = "0.0.1"
author        = "jiyinyiyong"
description   = "JSON DSL for canvas rendering"
license       = "MIT"
srcDir        = "src"



# Dependencies

requires "nim >= 1.2.6"
requires "sdl2"
requires "cairo"


task once, "run once":
  exec "nim compile --verbosity:0 --hints:off --threads:on -r tests/demo.nim"
