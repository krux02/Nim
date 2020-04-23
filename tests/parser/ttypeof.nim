discard """
  output: '''12
int
int
int'''
"""

import typetraits

# bug #1805

proc foob(x: int): string = "foo"
proc barb(x: string): int = 12

echo(foob(10).barb()) # works
echo(typeof(10).name()) # doesn't work

echo(name(typeof(10))) # works
echo((typeof(10)).name()) # works


# test that 'addr' still works
proc poo(x, y: ptr int) = discard

var someInt: int
poo(addr someInt, addr someInt)
