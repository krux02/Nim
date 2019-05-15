discard """
objccodecheck: "baz"
target: js
"""

proc foo(): void =
  echo "Hello World"

foo()
