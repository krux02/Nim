discard """
  targets: "cpp"
  output: "hello"
  cmd: "nim cpp --nilseqs:on --nimblePath:tests/deps $file"

disabled: true
"""

# to enable this, jester needs to be dealt with


# bug #3299

import jester
import asyncdispatch, asyncnet

# bug #5081
#import nre

echo "hello"
