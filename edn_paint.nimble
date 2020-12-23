# Package

version       = "0.2.0"
author        = "jiyinyiyong"
description   = "EDN DSL for canvas rendering"
license       = "MIT"
srcDir        = "src"



# Dependencies

requires "nim >= 1.2.6"
requires "sdl2"
requires "cairo"
requires "https://github.com/Cirru/cirru-edn.nim#v0.4.0"

task t, "run once":
  exec "nim compile --verbosity:0 --hints:off --threads:on -r tests/demo.nim"
