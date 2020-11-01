
JSON Paint
----

> JSON based painter based on SDL2 and Cario.

### Usage

```nim
requires "https://github.com/Quamolit/json-paint.nim#v0.0.1"
```

```nim
initCanvas("title", 400, 400)

renderCanvas(data.boolVal)

takeCanvasEvents()
```

### Shapes

JSON described in CoffeeScript.

Since Cairo uses RGB color from `0 ~ 1.0` rather than int 256, this library uses 100-based numbers too:

```coffee
r: 1 # 0~100
g: 1 # 0~100
b: 1 # 0~100
a: 100 # 0~100
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
style:
  'font-size': 14
  'font-weight': 300
  'font-family': 'Arial'
color: Color
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

* Path

```coffee
type: 'combo'
x: 1
y: 1
path: [
  type: 'move-to', x: 1, y: 1
,
  type: 'stroke'
,
  type: 'fill'
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
  'negative?': false
]
```

```coffee
type: 'polyline'
x: 1
y: 1
stops: [
  x: 2, y: 2
,
  x: 3, y: 3
,
  x: 4, y: 4
]
color: Color
'stroke-width': 1
'line-join': 'round' # 'round' | 'milter' | 'bevel'
```

### License

MIT
