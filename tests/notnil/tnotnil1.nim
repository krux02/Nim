discard """
errormsg: "'y' is provably nil"
line:25
cmd: "nim $target --experimental:notnil $options $file"
"""

import strutils

type
  TObj = object
    x, y: int

proc q(x: pointer not nil) =
  discard

proc p() =
  var x: pointer
  if not x.isNil:
    q(x)

  let y = x
  if not y.isNil:
    q(y)
  else:
    q(y)

p()
