discard """
"""

import macros

type
  Vec[N: static[int],T] = object
    arr: array[N,T]

  Vec4[T] = Vec[4,T]

  Vec4f = Vec4[float32]

  MyObject = object
    a,b,c: int

  MyObjectAlias = MyObject

  MyObjectSubAlias = MyObjectAlias

macro bar(arg: typed): untyped =
  echo arg.getTypeInst.isAlias

var a: Vec4f            # true
var b: Vec4[float32]    # true
var c: Vec[4,float32]   # false
var d: float32          # false
var e: MyObject         # false
var f: MyObjectAlias    # true
var g: MyObjectSubAlias # true

bar(a)
bar(b)
bar(c)
bar(d)
bar(e)
bar(f)
bar(g)

macro foobar(arg: typed; expected: static[string]): untyped =
  var typ = arg.getTypeInst
  while typ.isAlias:
    typ = typ.resolveAlias

  if typ.repr != expected:
    echo "error: ", typ.repr, " != ", expected

  echo typ.repr, " == ", expected

template test(type1,type2: untyped) =
  var a: type1
  foobar(a, astToStr(type2))

test(Vec4f,            Vec[4, float32])
test(Vec[4,float32],   Vec[4, float32])

test(Vec4[float32],    Vec[4, float32])
test(float32,          float32)
test(MyObject,         MyObject)
test(MyObjectAlias,    MyObject)
test(MyObjectSubAlias, MyObject)

# Local Variables:
# compile-command: "./koch test run macros/tresolvealias.nim"
# End:
