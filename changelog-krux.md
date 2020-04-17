
# v1.0.0 - yyyy-mm-dd

This changelog contains all changes that are specific to the krux-nim branch

## Standard library additions and changes

- remove lib/pure/collections/chains.nim (not used nor usable for anything)
- The $ operator returns a string for every possible type.
- io.write nor strformat does not fall back to the $ operator anymore.
- macros.newLit can be called on NimNode values as well.
- the option type now has logical operators.
- Added a new generic overload of `newLit` for distinct types in
  `macros`

## Language changes


## Compiler changes

- Tuple expressions are now parsed consistently as
  `nnkTupleConstr` node. Will affect macros expecting nodes to be of `nnkPar`.

## Tool changes
