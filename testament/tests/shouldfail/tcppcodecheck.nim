discard """
cppcodecheck: "baz"
target: cpp
"""

proc foo(): void {.exportc: "bar".} =
  echo "Hello World"

foo()
