discard """
  output: '''
c_func
12
'''
"""

import macros, strutils

# bug #1025

macro foo(icname: untyped): untyped =
  let ic = newStrLitNode($icname)
  result = quote do:
    proc x* =
      proc private {.exportc: `ic`.} = discard
      echo `ic`
      private()

foo(c_func)
x()


template volatileLoad[T](x: ptr T): T =
  var res: T
  {.emit: [res, " = (*(", typeof(x[]), " volatile*)", x, ");"].}
  res

template volatileStore[T](x: ptr T; y: T) =
  {.emit: ["*((", typeof(x[]), " volatile*)(", x, ")) = ", y, ";"].}

proc main =
  var st: int
  var foo: ptr int = addr st
  volatileStore(foo, 12)
  echo volatileLoad(foo)

main()
