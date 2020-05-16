# test the new 'compiles' feature:

template supports(opr, x: untyped): bool =
  compiles(opr(x)) or compiles(opr(x, x))

template ok(x: untyped) =
  static:
    assert(x)

template no(x: untyped) =
  static:
    assert(not x)

type
  TObj = object

var
  myObj {.compileTime.}: TObj

ok supports(`==`, myObj)
ok supports(`==`, 45)

no supports(`++`, 34)
ok supports(`not`, true)
ok supports(`+`, 34)

no compiles(4+5.0 * "hallo")

no compiles(undeclaredIdentifier)
no compiles(undeclaredIdentifier)
