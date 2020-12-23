
import tables

import cirru_edn

import ./error_util

proc kwd*(x: string): CirruEdnValue =
  genCrEdnKeyword(x)

proc contains*(m: CirruEdnValue, k: CirruEdnValue): bool =
  if m.kind == crEdnMap:
    m.mapVal.contains(k)
  else:
    false

proc contains*(m: CirruEdnValue, k: string): bool =
  contains(m, kwd(k))

proc getFloat*(m: CirruEdnValue, k: string): float =
  if m.kind == crEdnMap:
    let v = m.mapVal[kwd(k)]
    if v.kind == crEdnNumber:
      return v.numberVal
    else:
      showError("Expects value of " & k & "in number")
  else:
    showError("Expects option in map")

proc getFloat*(m: CirruEdnValue, k: int): float =
  if m.kind == crEdnVector:
    let v = m.vectorVal[k]
    if v.kind == crEdnNumber:
      return v.numberVal
    else:
      showError("Expects value of " & $k & "in number")
  else:
    showError("Expects option in vector")

proc getStr*(m: CirruEdnValue, k: string): string =
  if m.kind == crEdnMap:
    let v = m.mapVal[kwd(k)]
    if v.kind == crEdnString:
      return v.stringVal
    elif v.kind == crEdnKeyword:
      return v.keywordVal
    else:
      showError("Expects value of " & k & "in string")
  else:
    showError("Expects option in map")

proc getStr*(m: CirruEdnValue, k: int): string =
  if m.kind == crEdnVector:
    let v = m.vectorVal[k]
    if v.kind == crEdnString:
      return v.stringVal
    elif v.kind == crEdnKeyword:
      return v.keywordVal
    else:
      showError("Expects value of " & $k & " in string. but got " & $v.kind & " value: " & $m)
  else:
    showError("Expects option in vector")

proc getBool*(m: CirruEdnValue, k: string): bool =
  if m.kind == crEdnMap:
    let v = m.mapVal[kwd(k)]
    if v.kind == crEdnBool:
      return v.boolVal
    else:
      showError("Expects value of " & k & "in bool")
  else:
    showError("Expects option in map")

proc getBool*(m: CirruEdnValue, k: int): bool =
  if m.kind == crEdnVector:
    let v = m.vectorVal[k]
    if v.kind == crEdnBool:
      return v.boolVal
    else:
      showError("Expects value of " & $k & "in bool")
  else:
    showError("Expects option in vector")

proc `[]`*(m: CirruEdnValue, k: CirruEdnValue): CirruEdnValue =
  if m.kind == crEdnMap:
    if m.mapVal.contains(k):
      return m.mapVal[k]
    else:
      return genCrEdn()
  else:
    showError("Expects map in []")

proc `[]`*(m: CirruEdnValue, k: string): CirruEdnValue =
  m[kwd(k)]

proc `[]`*(m: CirruEdnValue, k: int): CirruEdnValue =
  if m.kind == crEdnVector:
    if k <  m.vectorVal.len:
      return m.vectorVal[k]
    else:
      return genCrEdn()
  else:
    showError("Expects number index in []")

proc numbersVec*(xs: seq[int]): CirruEdnValue =
  result = CirruEdnValue(kind: crEdnVector, vectorVal: @[])
  for x in xs:
    result.vectorVal.add(genCrEdn(x))

proc numbersVec*(xs: varargs[int]): CirruEdnValue =
  result = CirruEdnValue(kind: crEdnVector, vectorVal: @[])
  for x in xs:
    result.vectorVal.add(genCrEdn(x))
