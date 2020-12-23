
import cirru_edn
# import strformat

import ./edn_util

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

    return (r, g, b, a)

# fallbacks to red
proc readEdnColor*(raw: CirruEdnValue): RgbaColor =
  case raw.kind
  of crEdnVector:
    if raw.vectorVal.len < 3:
      echo "WARNING: too few numbers for a color"
      return failedColor
    let h = raw.getFloat(0)
    let s = raw.getFloat(1)
    let l = raw.getFloat(2)
    let a = if raw.vectorVal.len >= 4: raw.getFloat(3) else: 1
    return hslToRgb(h, s, l, a)

  of crEdnMap:
    let h = if raw.contains("h"): raw.getFloat("h") else: 0
    let s = if raw.contains("s"): raw.getFloat("s") else: 0
    let l = if raw.contains("l"): raw.getFloat("l") else: 0
    let a = if raw.contains("a"): raw.getFloat("a") else: 1
    return hslToRgb(h, s, l, a)

  else:
    echo "WARNING: unknown Edn color: ", raw
    return failedColor
