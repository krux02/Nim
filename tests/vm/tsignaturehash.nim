# test sym digest is computable at compile time

import macros, algorithm
import md5

macro testmacro(s: typed): string =
  s.expectKind {nnkSym, nnkOpenSymChoice, nnkClosedSymChoice}
  if s.kind == nnkSym:
    let s = getMD5(signaturehash(s) & " - " & symBodyHash(s))
    result = newStrLitNode(s)
  else:
    var str = ""
    for sym in s:
      str &= symBodyHash(sym)
    result = newStrLitNode(getMD5(str))

# something recursive and/or generic
discard testmacro(testmacro)
discard testmacro(`[]`)
discard testmacro(binarySearch)
discard testmacro(sort)
