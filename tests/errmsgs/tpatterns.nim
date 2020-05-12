discard """
action: reject
cmd: "nim check $options $file"
nimout: '''
tpatterns.nim(11, 14) Error: template pattern parameters not supported by this compiler A
tpatterns.nim(22, 10) Error: pattern not supported by this comiler C
tpatterns.nim(26, 19) Error: template pattern parameters not supported by this compiler B
'''
"""

template cse{f(a, a, x)}(a: typed{(nkDotExpr|call|nkBracketExpr)&noSideEffect},
                       f: typed, x: varargs[typed]): untyped =
  let aa = a
  f(aa, aa, x)+4

var
  a: array[0..10, int]
  i = 3

doAssert a[i] + a[i] == 4

proc foo{f(a,a,x)}(a,b,c: int): int =
  discard

template bar() =
  template subbar{f(a,b,c)}(a,b,c: int): untyped =
    discard

discard foo(1,2,3)
