discard """
ccodecheck: "baz"
target: c
"""

proc foo(): void {.exportc: "bar".} =
  echo "Hello World"

foo()
