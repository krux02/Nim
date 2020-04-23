#
#
#            Nim's Runtime Library
#        (c) Copyright 2012 Nim Contributors
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module defines compile-time reflection procs for
## working with types.
##
## Unstable API.

export system.`$` # for backward compatibility

include "system/inclrtl"

proc name*(t: typedesc): string {.magic: "TypeTrait".}
  ## Returns the name of the given type.
  ##
  ## Alias for system.`$`(t) since Nim v0.20.

proc supportsCopyMem*(t: typedesc): bool {.magic: "TypeTrait".}
  ## This trait returns true iff the type ``t`` is safe to use for
  ## `copyMem`:idx:.
  ##
  ## Other languages name a type like these `blob`:idx:.

proc isNamedTuple*(T: typedesc): bool {.magic: "TypeTrait".}
  ## Return true for named tuples, false for any other type.

import macros

macro distinctBase*[T: distinct](t: typedesc[T]): typedesc =
  ## Returns the base type for the distinct types.
  let impl = getTypeImpl(t)
  impl.expectKind nnkDistinctTy
  return impl[0]

macro distinctBase*[T: distinct](value: T): untyped =
  ## Returns `value` converted back to its distinct base type.
  let impl = value.getTypeImpl
  impl.expectKind nnkDistinctTy
  result = newCall(impl[0], value)
  echo result.lispRepr
