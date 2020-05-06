import typetraits
import macros


static:
  doAssert $typeof(42) == "int"
  doAssert int.name == "int"

const a1 = name(int)
const a2 = $(int)
const a3 = $int
doAssert a1 == "int"
doAssert a2 == "int"
doAssert a3 == "int"

proc fun[T: typedesc](t: T) =
  const a1 = name(t)
  const a2 = $(t)
  const a3 = $t
  doAssert a1 == "int"
  doAssert a2 == "int"
  doAssert a3 == "int"

fun(int)

block: # isNamedTuple
  type Foo1 = typeof((a:1,))
  type Foo2 = typeof((Field0:1,))
  type Foo3 = typeof(())
  type Foo4 = object
  type Foo5[T] = tuple[x:int, y: T]
  type Foo6[T] = (T,)

  doAssert typeof((a:1,)).isNamedTuple
  doAssert Foo1.isNamedTuple
  doAssert Foo2.isNamedTuple
  doAssert isNamedTuple(tuple[key: int])
  doAssert not Foo3.isNamedTuple
  doAssert not Foo4.isNamedTuple
  doAssert not typeof((1,)).isNamedTuple
  doAssert isNamedTuple(Foo5[int8])
  doAssert not isNamedTuple(Foo5)
  doAssert not isNamedTuple(Foo6[int8])

proc typeToString*(t: typedesc, prefer = "preferTypeName"): string {.magic: "TypeTrait".}
  ## Returns the name of the given type, with more flexibility than `name`,
  ## and avoiding the potential clash with a variable named `name`.
  ## prefer = "preferResolved" will resolve type aliases recursively.
  # Move to typetraits.nim once api stabilized.

block: # typeToString
  type MyInt = int
  type
    C[T0, T1] = object
  type C2=C # alias => will resolve as C
  type C2b=C # alias => will resolve as C (recursively)
  type C3[U,V] = C[V,U]
  type C4[X] = C[X,X]
  template name2(T: untyped): string = typeToString(T, "preferResolved")
  doAssert MyInt.name2 == "int"
  doAssert C3[MyInt, C2b].name2 == "C3[int, C]"
    # C3 doesn't get resolved to C, not an alias (nor does C4)
  doAssert C2b[MyInt, C4[cstring]].name2 == "C[int, C4[cstring]]"
  doAssert C4[MyInt].name2 == "C4[int]"
  when BiggestFloat is float and cint is int:
    doAssert C2b[cint, BiggestFloat].name2 == "C3[int, C3[float, int32]]"

  template name3(T: untyped): string = typeToString(T, "preferMixed")
  doAssert MyInt.name3 == "MyInt{int}"
  doAssert (tuple[a: MyInt, b: float]).name3 == "tuple[a: MyInt{int}, b: float]"
  doAssert (tuple[a: C2b[MyInt, C4[cstring]], b: cint, c: float]).name3 ==
    "tuple[a: C[MyInt{int}, C4[cstring]], b: cint{int32}, c: float]"

block distinctBase:
  block:
    type
      Foo[T] = distinct seq[T]
    var a: Foo[int]
    doAssert typeof(a).distinctBase is seq[int]

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

    block:
      type
        AA = distinct seq[int]
        BB = distinct string
        CC = distinct int
        AAA = AA

      static:
        var a2: AAA
        var b2: BB
        var c2: CC

        doAssert(a2 is distinct)
        doAssert(b2 is distinct)
        doAssert(c2 is distinct)

        doAssert($distinctBase(typeof(a2)) == "seq[int]")
        doAssert($distinctBase(typeof(b2)) == "string")
        doAssert($distinctBase(typeof(c2)) == "int")

block: # tupleLen
  doAssert not compiles(len(int))

  type
    MyTupleType = (int,float,string)

  static: doAssert default(MyTupleType).len == 3

  type
    MyGenericTuple[T] = (T,int,float)
    MyGenericAlias = MyGenericTuple[string]
  static: doAssert MyGenericAlias.len == 3

  type
    MyGenericTuple2[T,U] = (T,U,string)
    MyGenericTuple2Alias[T] =  MyGenericTuple2[T,int]

    MyGenericTuple2Alias2 =   MyGenericTuple2Alias[float]
  static: doAssert MyGenericTuple2Alias2.len == 3

  static: doAssert (int, float).len == 2
  static: doAssert (1, ).len == 1
  static: doAssert ().len == 0

  let x = (1,2,)
  doAssert x.len == 2
  doAssert ().len == 0
  doAssert (1,).len == 1
  doAssert (int,).len == 1
  doAssert typeof(x).len == 2
  doAssert typeof(x).default.len == 2
  type T1 = (int,float)
  type T2 = T1
  doAssert T2.len == 2

##############################################
# bug 13095

type
  CpuStorage[T] = ref object
    when supportsCopyMem(T):
      raw_buffer*: ptr UncheckedArray[T] # 8 bytes
      memalloc*: pointer                 # 8 bytes
      isMemOwner*: bool                  # 1 byte
    else: # Tensors of strings, other ref types or non-trivial destructors
      raw_buffer*: seq[T]                # 8 bytes (16 for seq v2 backed by destructors?)

var x = CpuStorage[string]()

static:
  doAssert(not string.supportsCopyMem)
  doAssert x.T is string          # true
  doAssert x.raw_buffer is seq
