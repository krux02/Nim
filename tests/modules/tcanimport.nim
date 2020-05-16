discard """
  output: '''ABC
nope'''
"""

template canImport(x: untyped): bool =
  compiles:
    import x

when canImport(strutils):
  import strutils
  echo "abc".toUpperAscii
else:
  echo "meh"

when canImport(none):
  echo "what"
else:
  echo "nope"
