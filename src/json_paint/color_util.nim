
import json
import strformat

# based on algorithm
# https://stackoverflow.com/a/9493060/883571

# rgba 0~1.0
type RgbaColor* = tuple[r: float, g: float, b: float, a: float]

const failedColor*: RgbaColor = (1.0, 0.0, 0.0, 1.0)

proc hslHelper(p, q: float, t0: float): float =
  var t = t0
  if t < 0: t += 1
  elif t > 1: t -= 1

  if t < 1/6: return p + (q - p) * 6 * t
  if t < 1/2: return q
  if t < 2/3: return p + (q - p) * (2/3 - t) * 6

  else: return p

proc hslToRgb*(h0, s0, l0: float, a: float): RgbaColor =
  var h = h0 / 360
  var s = s0 * 0.01
  var l = l0 * 0.01
  if s == 0:
    return (l, l, l, a)
  else:
    let q = if l < 0.5: l * (1 + s) else: l + s - l * s
    let p = 2 * l - q
    let r = hslHelper(p, q, h + 1/3)
    let g = hslHelper(p, q, h)
    let b = hslHelper(p, q, h - 1/3)

    echo fmt"rgb: {r} {g} {b} {a}"

    return (r, g, b, a)

# fallbacks to red
proc readJsonColor*(raw: JsonNode): RgbaColor =
  if raw.kind == JArray:
    if raw.len < 3:
      echo "WARNING: too few numbers for a color"
      return failedColor
    let h = raw.elems[0].getFloat
    let s = raw.elems[1].getFloat
    let l = raw.elems[2].getFloat
    let a = if raw.elems.len >= 4: raw.elems[3].getFloat else: 1
    echo fmt"hsl: {h} {s} {l} {a}"
    return hslToRgb(h, s, l, a)

  if raw.kind == JObject:
    let h = if raw.contains("h"): raw["h"].getFloat else: 0
    let s = if raw.contains("s"): raw["s"].getFloat else: 0
    let l = if raw.contains("l"): raw["l"].getFloat else: 0
    let a = if raw.contains("a"): raw["a"].getFloat else: 1
    return hslToRgb(h, s, l, a)

  return failedColor
