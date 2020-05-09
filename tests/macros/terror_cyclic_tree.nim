discard """
errormsg: "macro produced a cyclic tree"
"""

import macros

macro foo1(): untyped =
  let a = newStmtList()
  let b = newStmtList()
  a.add b
  b.add a

foo1()
