discard """
  errormsg: "type mismatch"
  line: 13
cmd: "nim $target --experimental:notnil $options $file"
"""
type
  PObj = ref TObj not nil
  TObj = object
    x: int

proc q2(x: string) = discard

q2(nil)
