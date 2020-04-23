discard """
  output: '''true'''
"""

# bug #3686

type Monoid = concept x, y
  x + y is typeof(x)
  typeof(z(typeof(x))) is typeof(x)

proc z(x: typedesc[int]): int = 0

echo(int is Monoid)

# https://github.com/nim-lang/Nim/issues/8126
type AdditiveMonoid* = concept x, y, type T
  x + y is T

  # some redundant checks to test an alternative approaches:
  type TT = typeof(x)
  x + y is typeof(x)
  x + y is TT

doAssert(1 is AdditiveMonoid)
