discard """
  nimout:    "instantiated for string\ninstantiated for int\ninstantiated for bool"
  output: "int\nseq[string]\nA\nB\n100\ntrue"
"""

import typetraits

proc plus(a, b: auto): auto = a + b
proc makePair(a, b: auto): auto = (first: a, second: b)

proc `+`(a, b: string): seq[string] = @[a, b]

var i = plus(10, 20)
var s = plus("A", "B")

var p = makePair("key", 100)
static: assert p[0] is string

echo typeof(i).name
echo typeof(s).name

proc inst(a: auto): auto =
  static: echo "instantiated for ", typeof(a).name
  result = a

echo inst("A")
echo inst("B")
echo inst(100)
echo inst(true)

# XXX: [string, tyGenericParam] is cached instead of [string, string]
# echo inst[string, string]("C")
