discard """
objccodecheck: "baz"
target: objc
"""

proc foo(): void {.exportc: "bar".} =
  echo "Hello World"

foo()
