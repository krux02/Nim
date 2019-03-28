discard """
  output: '''
key: 1 val: 1
key: 2 val: 2
i: 0 key: 1
i: 1 key: 2
i: 0 val: 1
i: 1 val: 2
i: 0 key: 1 val: 1
i: 1 key: 2 val: 2
'''
"""
import sugar, macros, tables

block distinctBase:
  block:
    type
      Foo[T] = distinct seq[T]
    var a: Foo[int]
    doAssert a.type.distinctBase is seq[int]

  block:
    # simplified from https://github.com/nim-lang/Nim/pull/8531#issuecomment-410436458
    macro uintImpl(bits: static[int]): untyped =
      if bits >= 128:
        let inner = getAST(uintImpl(bits div 2))
        result = newTree(nnkBracketExpr, ident("UintImpl"), inner)
      else:
        result = ident("uint64")

    type
      BaseUint = UintImpl or SomeUnsignedInt
      UintImpl[Baseuint] = object
      Uint[bits: static[int]] = distinct uintImpl(bits)

    doAssert Uint[128].distinctBase is UintImpl[uint64]

{.experimental: "forLoopMacros".}

var d = toTable({1: 1, 2: 2})

for key, val in d:
  echo "key: ", key, " val: ", val

for i, key in enumerate(d.keys()):
  echo "i: ", i, " key: ", key

for i, val in enumerate(d.values()):
  echo "i: ", i, " val: ", val

for i, (key, val) in enumerate(d.pairs()):
  echo "i: ", i, " key: ", key, " val: ", val
