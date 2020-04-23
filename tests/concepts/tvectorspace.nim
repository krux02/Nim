discard """
  joinable: false
"""

type VectorSpace[K] = concept x, y
  x + y is type(x)
  zero(typeof(x)) is typeof(x)
  -x is typeof(x)
  x - y is typeof(x)
  var k: K
  k * x is typeof(x)

proc zero(T: typedesc): T = 0

static:
  assert float is VectorSpace[float]
  # assert float is VectorSpace[int]
  # assert int is VectorSpace
