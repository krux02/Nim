discard """
  output: '''true'''
"""

import tables

static:
  var table = newTable[string, int]()

  table["hallo"] = 123
  doAssert table["hallo"] == 123
  table["welt"]  = 456
  doAssert table["welt"] == 456
  table["hallo"] = 789
  doAssert table["hallo"] == 789
  doAssert table["welt"] == 456


block:
  var table = newTable[string, int]()

  table["hallo"] = 123
  doAssert table["hallo"] == 123
  table["welt"]  = 456
  doAssert table["welt"] == 456
  table["hallo"] = 789
  doAssert table["hallo"] == 789
  doAssert table["welt"] == 456

echo "true"
