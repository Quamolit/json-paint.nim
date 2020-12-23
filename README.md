## EDN Paint

> Cirru EDN based painter based on SDL2 and Cario.

### Usage

```nim
requires "https://github.com/calcit-runner/edn-paint.nim#v0.2.0"
```

```nim
import edn_paint

initCanvas("title", 400, 400)
# it also takes an optional RgbaColor as background

renderCanvas({
  "type": "group",
  "children": [] # see specs for currently supported shapes
})

takeCanvasEvents(proc(event: CirruEdnValue) =
  if event.kind == crEdnKeyword:
    if event["type"].getStr == "quit":
      quit 0
  echo "event: ", event
)

hslToRgb(0,0,10,1)
```

Try in dev:

```bash
nimble t
```

Find example in [`tests/demo.nim`](tests/demo.nim).

### Specs

EDN described in CoffeeScript.

This library uses HSL/HSLA colors:

```coffee
[360,100,100]

[360,100,100,1]
```

- Group

```coffee
type: 'group'
position: [1, 1],
children: []
```

- Text

```coffee
type: 'text'
text: 'DEMO'
position: [1, 1]
'font-size': 14
'font-face': 'Arial'
'font-weight': 'normal',
color: Color
align: "center" # 'left' | 'center' | 'right'
```

- Arc

```coffee
type: 'arc'
position: [1, 1]
radius: 1
'from-angle': 0
'to-angle': 2*PI # 0 ~ 2*PI
'negative?': false
'stroke-color': Color
'line-width': 1
'fill-color': Color
```

- Operations

```coffee
type: 'ops'
position: [1, 1]
ops: [
  ['stroke'],
  ['fill'],
  ['stroke-preserve'],
  ['fill-preserve'],
  ['line-width', 1],
  ['source-rgb', Color],  # which is actually using HSL colors
  ['hsl', Color],         # alias for 'source-rgb'
  ['move-to', [1, 1]],
  ['line-to', [1, 1]],
  ['relative-line-to', [1, 1]],
  ['curve-to', [1, 2], [3, 4], [5, 6]],
  ['relative-curve-to', [1, 2], [3, 4], [5, 6]],
  ['arc', [1, 2], 1, [0, 6.28], false],
  ['new-path'],
  ['close-path'],
]
```

- Polyline

```coffee
type: 'polyline'
position: [1, 1]
stops: [
  [2, 2], [3, 3], [4, 4]
]
'stroke-color': Color
'line-width': 1
'line-join': 'round' # 'round' | 'milter' | 'bevel'
'fill-color': Color
'skip-first?': false
```

- Touch Area

```coffee
type: 'touch-area'
path: ["a", 1] # EDN
action: Action # EDN
data: Data # EDN
position: [1, 1]
radius: 20
'fill-color': Color
'stroke-color': Color
'line-width': 1

'rect?': true # enabled rect mode
dx: 24 # half of rect width
dy: 8  # half of rect height
```

- Key Listener

```coffee
type: 'key-listener'
path: ['a', 2] # EDN
action: Action # EDN
data: Data # EDN
key: 'a'
```

### Events

```coffee
type: 'mouse-move'
x: 1
y: 1
path: [] # data, defined in "touch-area"
action: Action # data, defined in "touch-area"
data: Data # data, defined in "touch-area"
```

```coffee
type: 'key-down'
sym: 97
repeat: false
scancode: "SDL_SCANCODE_D"
name: 'a'
```

```coffee
type: 'key-up'
sym: 97
repeat: false
scancode: "SDL_SCANCODE_D"
name: 'a'
```

```coffee
type: 'text-input',
text: 'a'
```

```coffee
type: 'quit'
```

```coffee
type: 'mouse-down'
clicks: 1
path: [] # data, defined in "touch-area"
action: Action # data, defined in "touch-area"
data: Data # data, defined in "touch-area"
x: 100
y: 100
```

```coffee
type: 'mouse-up'
clicks: 1
path: [] # data, defined in "touch-area"
action: Action # data, defined in "touch-area"
data: Data # data, defined in "touch-area"
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

Example logs:

```js
// normal moves
{"type":"mouse-move","x":430,"y":162}
{"type":"mouse-move","x":377,"y":120}

// a normal click
{"type":"mouse-down","clicks":1,"x":377,"y":120}
{"type":"mouse-up","clicks":1,"x":377,"y":120}
{"type":"mouse-move","x":385,"y":128}
{"type":"mouse-move","x":388,"y":134}

// a normal drag
{"type":"mouse-down","clicks":1,"x":388,"y":134}
{"type":"mouse-move","x":407,"y":155}
{"type":"mouse-move","x":408,"y":156}
{"type":"mouse-move","x":415,"y":165}
{"type":"mouse-move","x":416,"y":165}
{"type":"mouse-move","x":416,"y":166}
{"type":"mouse-up","clicks":0,"x":416,"y":166}
{"type":"mouse-move","x":406,"y":164}

{"type":"mouse-move","x":291,"y":102}

// move from touch-area
{"type":"mouse-down","clicks":1,"path":["a",1],"action":":demo","data":null,"x":291,"y":102}
{"type":"mouse-move","x":293,"y":105,"dx":2.0,"dy":3.0,"path":["a",1],"action":":demo","data":null}
{"type":"mouse-move","x":318,"y":135,"dx":27.0,"dy":33.0,"path":["a",1],"action":":demo","data":null}
{"type":"mouse-move","x":323,"y":142,"dx":32.0,"dy":40.0,"path":["a",1],"action":":demo","data":null}
{"type":"mouse-move","x":326,"y":150,"dx":35.0,"dy":48.0,"path":["a",1],"action":":demo","data":null}
{"type":"mouse-move","x":327,"y":150,"dx":36.0,"dy":48.0,"path":["a",1],"action":":demo","data":null}
{"type":"mouse-move","x":327,"y":151,"dx":36.0,"dy":49.0,"path":["a",1],"action":":demo","data":null}
{"type":"mouse-up","clicks":0,"path":["a",1],"action":":demo","data":null,"x":327,"y":151,"dx":36.0,"dy":49.0}
{"type":"mouse-move","x":311,"y":132}
{"type":"mouse-move","x":310,"y":132}
{"type":"mouse-move","x":308,"y":129}
{"type":"mouse-move","x":307,"y":129}
{"type":"mouse-move","x":303,"y":120}

// click in touch-area
{"type":"mouse-down","clicks":1,"path":["a",1],"action":":demo","data":null,"x":303,"y":120}
{"type":"mouse-up","clicks":1,"path":["a",1],"action":":demo","data":null,"x":303,"y":120,"dx":0.0,"dy":0.0}

// keyboard events
event: {"type":"key-down","sym":100,"repeat":false,"scancode":"SDL_SCANCODE_D","name":"d"}
event: {"type":"text-input","text":"d"}
event: {"type":"key-up","sym":100,"repeat":false,"scancode":"SDL_SCANCODE_D","name":"d"}
// keydown with actions
event: {"type":"key-down","sym":97,"repeat":false,"scancode":"SDL_SCANCODE_A","name":"a","path":["a",1],"action":":hit-key","data":"demo data"}
event: {"type":"text-input","text":"a"}
event: {"type":"key-up","sym":97,"repeat":false,"scancode":"SDL_SCANCODE_A","name":"a","path":["a",1],"action":":hit-key","data":"demo data"}
```

### License

MIT
