discard """
  cmd: "nim -d:testdef $target $file"
  output: '''works 34
34
defined
'''
"""

{.experimental: "codeReordering".}

proc bar(x: T)

proc foo() =
  bar(34)
  whendep()

proc foo(dummy: int) = echo dummy

proc bar(x: T) =
  echo "works ", x
  foo(x)

when defined(testdef):
  proc whendep() = echo "defined"
else:
  proc whendep() = echo "undefined"

foo()

type
  T = int
