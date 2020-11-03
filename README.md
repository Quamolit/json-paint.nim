
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

takeCanvasEvents()

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
path: [
  type: 'move-to', x: 1, y: 1
,
  type: 'stroke'
,
  type: 'fill'
,
  type: 'stroke-preserve'
,
  type: 'fill-preserve'
,
  type: 'line-width', width: 1
,
  type: 'source-rgb', color: Color
,
  type: 'line-to', x: 1, y: 1
,
  type: 'relative-line-to', x: 1, y: 1
,
  type: 'curve-to', path: [
    [1, 2],
    [3, 4],
    [5, 6]
  ]
,
  type: 'relative-curve-to', path: [
    [1, 2],
    [3, 4],
    [5, 6]
  ]
,
  type: 'arc'
  x: 1
  y: 1
  radius: 1
  'start-angle': 0
  'end-angle': 6.28
  'negative?': false
]
```

### Polyline

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

### License

MIT
