template accept(e: untyped) =
  static: assert(compiles(e))

template reject(e: untyped) =
  static: assert(not compiles(e))
