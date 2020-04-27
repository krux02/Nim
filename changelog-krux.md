
# v1.0.0 - yyyy-mm-dd

This changelog contains all changes that are specific to the krux-nim branch

## Standard library additions and changes

- `getTypeInst` and `getTypeImpl` doesn't return types wrapped in
  `typedesc` anymore. This really breaks stuff. Sorry, but it was necessary.
- remove lib/pure/collections/chains.nim (not used nor usable for anything)
- The $ operator returns a string for every possible type.
- io.write nor strformat does not fall back to the $ operator anymore.
- macros.newLit can be called on NimNode values as well.
- the option type now has logical operators.
- Added a new generic overload of `newLit` for distinct types in
  `macros`
- deprecate `getType` in favor of `getTypeInst`/`getTypeImpl`.
- Using the ``BackwardsIndex`` on arrays that are not accessed by
  integer types (for example enums or characters) is not supported
  anymore.
- Removed arity, genericHead, stripGenericParams, genericParams from
  typetraits module.

## Language changes

- A bug that automatically lifts nodes of kind `stmtList` into lambda
  expressions has been fixed.
- Code blocks that start with a `do` are now consistent of type
  `nkDo`.
- Tuple expressions are now parsed consistently as
  `nnkTupleConstr` node. Will affect macros expecting tuples to be of
  kind `nnkPar`.
- Custom pragma values have now an API for use in macros.
- callsite has been disabled by default

## Compiler changes

- alignment of types is forwarded to allocators
- hot code reloading has been removed (unmaintainable)
- something for concepts broke (sorry)
- pragma `this` is no longer supported.
- statement `using` is no longer supported.

## Tool changes
