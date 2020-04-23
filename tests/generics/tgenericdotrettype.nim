discard """
output: '''string
int
(int, string)
'''
"""

import typetraits

type
  Foo[T, U] = object
    x: T
    y: U

proc bar[T](a: T): T.U =
  echo typeof(result).name

proc bas(x: auto): x.T =
  echo typeof(result).name

proc baz(x: Foo): (Foo.T, x.U) =
  echo typeof(result).name

var
  f: Foo[int, string]
  x = bar f
  z = bas f
  y = baz f
