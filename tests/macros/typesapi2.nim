# tests to see if a symbol returned from macros.getType() can
# be used as a type
import macros

macro testTypesym (t:typed): untyped =
    var ty = t.getType
    if ty.typekind == ntyTypedesc:
        # skip typedesc get to the real type
        ty = ty[1].getType

    if ty.kind == nnkSym: return ty
    assert ty.kind == nnkBracketExpr
    assert ty[0].kind == nnkSym
    result = ty[0]
    return

type TestFN = proc(a,b:int):int
var iii: testTypesym(TestFN)
static: assert iii is TestFN

proc foo11 : testTypesym(void) =
    echo "HI!"
static: assert foo11 is (proc():void {.nimcall.})

var sss: testTypesym(seq[int])
static: assert sss is seq[int]
# very nice :>

static: assert array[2,int] is testTypesym(array[2,int])
static: assert(ref int is testTypesym(ref int))
static: assert(void is testTypesym(void))


macro tts2 (t:typed, idx: static[int]): untyped =
  var ty = t.getTypeImpl
  if ty.typekind == ntyTypedesc:
      # skip typedesc get to the real type
      ty = ty[1].getTypeImpl

  result = ty[0][idx]
  if idx != 0:
    result = result[1]
  echo result.repr

type TestFN2 = proc(a:int,b,c:float):string

static:
    assert(tts2(TestFN2, 0) is string)
    assert(tts2(TestFN2, 1) is int)
    assert(tts2(TestFN2, 2) is float)
    assert(tts2(proc(a:int,b,c:float):string, 3) is float)
