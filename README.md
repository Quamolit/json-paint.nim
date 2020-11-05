
JSON Paint
----

> JSON based painter based on SDL2 and Cario.

### Usage

```nim
requires "https://github.com/Quamolit/json-paint.nim#v0.0.4"
```

```nim
import json_paint

initCanvas("title", 400, 400)
# it also takes an optional RgbaColor as background

renderCanvas({
  "type": "group",
  "children": [] # see specs for currently supported shapes
})

takeCanvasEvents(proc(event: JsonNode) =
  if event.kind == JObject:
    if event["type"].getStr == "quit":
      quit 0
  echo "event: ", event
)

hslToRgb(0,0,10,1)
```

Try in dev:

```
nimble t
```

### Specs

JSON described in CoffeeScript.

This library uses hsl colors:

```coffee
[359,99,99,1]
```

* Group

```coffee
type: 'group'
x: 1
y: 1
children: []
```

* Text

```coffee
type: 'text'
x: 1
y: 1
text: 'DEMO'
'font-size': 14
'font-family': 'Arial'
color: Color
align: "center" # 'left' | 'center' | 'right'
```

* Arc

```coffee
type: 'arc'
x: 1
y: 1
radius: 1
'from-angle': 0
'to-angle': 0 # 0 ~ 2*PI
'negative?': false
'stroke-color': Color
'stroke-width': 1
'fill-color': Color
```

* Operations

```coffee
type: 'ops'
x: 1
y: 1
ops: [
  ['stroke'],
  ['fill'],
  ['stroke-preserve'],
  ['fill-preserve'],
  ['line-width', 1],
  ['source-rgb', Color],
  ['move-to', [1, 1]],
  ['line-to', [1, 1]],
  ['relative-line-to', [1, 1]],
  ['curve-to', [1, 2], [3, 4], [5, 6]],
  ['relative-curve-to', [1, 2], [3, 4], [5, 6]],
  ['arc', [1, 2], 1, [0, 6.28], false],
  ['close-path']
]
```

* Polyline

```coffee
type: 'polyline'
from: [1, 1]
stops: [
  [2, 2], [3, 3], [4, 4]
]
'relative-stops': [
  [2, 2], [3, 3], [4, 4]
]
'stroke-color': Color
'line-width': 1
'line-join': 'round' # 'round' | 'milter' | 'bevel'
'fill-color': Color
```

### Events

```coffee
type: 'mouse-motion'
x: 1
y: 1
```

```coffee
type: 'key-down'
sym: 97
repeat: false
scancode: "SDL_SCANCODE_D"
```

```coffee
type: 'key-up'
sym: 97
repeat: false
scancode: "SDL_SCANCODE_D"
```

```coffee
type: 'text-input',
text: 'a'
```

```coffee
type: 'quit'
```

```coffee
type: 'mouse-button-down'
clicks: 1
x: 100
y: 100
```

```coffee
type: 'mouse-button-up'
clicks: 1
x: 100
y: 100
```

```coffee
type: 'window'
event: "WindowEvent_FocusGained"
```

```coffee
type: 'window-resized'
x: 100
y: 100
```

### License

MIT
