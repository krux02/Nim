discard """
  errormsg: '''
undeclared field: 'a3' for type m8794.Foo3 [declared in m8794.nim(1, 6)]
'''
line: 39
"""













## line 20

## issue #8794

import m8794

when false: # pending https://github.com/nim-lang/Nim/pull/10091 add this
  type Foo = object
    a1: int

  discard Foo().a2

type Foo3b = Foo3
var x2: Foo3b

proc getFun[T](): T =
  var a: T
  a

discard getFun[typeof(x2)]().a3
