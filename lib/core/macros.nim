#
#
#            Nim's Runtime Library
#        (c) Copyright 2015 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

include "system/inclrtl"

## This module contains the interface to the compiler's abstract syntax
## tree (`AST`:idx:). Macros operate on this tree.
##
## See also:
## * `macros tutorial <tut3.html>`_
## * `macros section in Nim manual <manual.html#macros>`_

## .. include:: ../../doc/astspec.txt

# If you look for the implementation of the magic symbol
# ``{.magic: "Foo".}``, search for `mFoo` and `opcFoo`.

type
  NimNodeKind* = enum
    nnkNone, nnkEmpty, nnkIdent, nnkSym,
    nnkType, nnkCharLit, nnkIntLit, nnkInt8Lit,
    nnkInt16Lit, nnkInt32Lit, nnkInt64Lit, nnkUIntLit, nnkUInt8Lit,
    nnkUInt16Lit, nnkUInt32Lit, nnkUInt64Lit, nnkFloatLit,
    nnkFloat32Lit, nnkFloat64Lit, nnkFloat128Lit, nnkStrLit, nnkRStrLit,
    nnkTripleStrLit, nnkNilLit, nnkComesFrom, nnkDotCall,
    nnkCommand, nnkCall, nnkCallStrLit, nnkInfix,
    nnkPrefix, nnkPostfix, nnkHiddenCallConv,
    nnkExprEqExpr,
    nnkExprColonExpr, nnkIdentDefs, nnkVarTuple,
    nnkPar, nnkObjConstr, nnkCurly, nnkCurlyExpr,
    nnkBracket, nnkBracketExpr, nnkPragmaExpr, nnkRange,
    nnkDotExpr, nnkCheckedFieldExpr, nnkDerefExpr, nnkIfExpr,
    nnkElifExpr, nnkElseExpr, nnkLambda, nnkDo, nnkAccQuoted,
    nnkTableConstr, nnkBind,
    nnkClosedSymChoice,
    nnkOpenSymChoice,
    nnkHiddenStdConv,
    nnkHiddenSubConv, nnkConv, nnkCast, nnkStaticExpr,
    nnkAddr, nnkHiddenAddr, nnkHiddenDeref, nnkObjDownConv,
    nnkObjUpConv, nnkChckRangeF, nnkChckRange64, nnkChckRange,
    nnkStringToCString, nnkCStringToString, nnkAsgn,
    nnkFastAsgn, nnkGenericParams, nnkFormalParams, nnkOfInherit,
    nnkImportAs, nnkProcDef, nnkMethodDef, nnkConverterDef,
    nnkMacroDef, nnkTemplateDef, nnkIteratorDef, nnkOfBranch,
    nnkElifBranch, nnkExceptBranch, nnkElse,
    nnkAsmStmt, nnkPragma, nnkPragmaBlock, nnkIfStmt, nnkWhenStmt,
    nnkForStmt, nnkParForStmt, nnkWhileStmt, nnkCaseStmt,
    nnkTypeSection, nnkVarSection, nnkLetSection, nnkConstSection,
    nnkConstDef, nnkTypeDef,
    nnkYieldStmt, nnkDefer, nnkTryStmt, nnkFinally, nnkRaiseStmt,
    nnkReturnStmt, nnkBreakStmt, nnkContinueStmt, nnkBlockStmt, nnkStaticStmt,
    nnkDiscardStmt, nnkStmtList,
    nnkImportStmt,
    nnkImportExceptStmt,
    nnkExportStmt,
    nnkExportExceptStmt,
    nnkFromStmt,
    nnkIncludeStmt,
    nnkBindStmt, nnkMixinStmt, nnkUsingStmt,
    nnkCommentStmt, nnkStmtListExpr, nnkBlockExpr,
    nnkStmtListType, nnkBlockType,
    nnkWith, nnkWithout,
    nnkTypeOfExpr, nnkObjectTy,
    nnkTupleTy, nnkTupleClassTy, nnkTypeClassTy, nnkStaticTy,
    nnkRecList, nnkRecCase, nnkRecWhen,
    nnkRefTy, nnkPtrTy, nnkVarTy,
    nnkConstTy, nnkMutableTy,
    nnkDistinctTy,
    nnkProcTy,
    nnkIteratorTy,         # iterator type
    nnkSharedTy,           # 'shared T'
    nnkEnumTy,
    nnkEnumFieldDef,
    nnkArglist, nnkPattern
    nnkHiddenTryStmt,
    nnkClosure,
    nnkGotoState,
    nnkState,
    nnkBreakState,
    nnkFuncDef,
    nnkTupleConstr

  NimNodeKinds* = set[NimNodeKind]
  NimTypeKind* = enum  # some types are no longer used, see ast.nim
    ntyNone, ntyBool, ntyChar, ntyEmpty,
    ntyAlias, ntyNil, ntyExpr, ntyStmt,
    ntyTypeDesc, ntyGenericInvocation, ntyGenericBody, ntyGenericInst,
    ntyGenericParam, ntyDistinct, ntyEnum, ntyOrdinal,
    ntyArray, ntyObject, ntyTuple, ntySet,
    ntyRange, ntyPtr, ntyRef, ntyVar,
    ntySequence, ntyProc, ntyPointer, ntyOpenArray,
    ntyString, ntyCString, ntyForward, ntyInt,
    ntyInt8, ntyInt16, ntyInt32, ntyInt64,
    ntyFloat, ntyFloat32, ntyFloat64, ntyFloat128,
    ntyUInt, ntyUInt8, ntyUInt16, ntyUInt32, ntyUInt64,
    ntyUnused0, ntyUnused1, ntyUnused2,
    ntyVarargs,
    ntyUncheckedArray,
    ntyError,
    ntyBuiltinTypeClass, ntyUserTypeClass, ntyUserTypeClassInst,
    ntyCompositeTypeClass, ntyInferred, ntyAnd, ntyOr, ntyNot,
    ntyAnything, ntyStatic, ntyFromExpr, ntyOpt, ntyVoid

  NimSymKind* = enum
    nskUnknown, nskConditional, nskDynLib, nskParam,
    nskGenericParam, nskTemp, nskModule, nskType, nskVar, nskLet,
    nskConst, nskResult,
    nskProc, nskFunc, nskMethod, nskIterator,
    nskConverter, nskMacro, nskTemplate, nskField,
    nskEnumField, nskForVar, nskLabel,
    nskStub

const
  nnkLiterals* = {nnkCharLit..nnkNilLit}
  nnkCallKinds* = {nnkCall, nnkInfix, nnkPrefix, nnkPostfix, nnkCommand,
                   nnkCallStrLit}
  nnkPragmaCallKinds = {nnkExprColonExpr, nnkCall, nnkCallStrLit}

proc `==`*(a, b: NimNode): bool {.magic: "EqNimrodNode", noSideEffect.}
  ## Compare two Nim nodes. Return true if nodes are structurally
  ## equivalent. This means two independently created nodes can be equal.

proc sameType*(a, b: NimNode): bool {.magic: "SameNodeType", noSideEffect.} =
  ## Compares two Nim nodes' types. Return true if the types are the same,
  ## eg. true when comparing alias with original type.
  discard

proc len*(n: NimNode): int {.magic: "NLen", noSideEffect.}
  ## Returns the number of children of `n`.

proc `[]`*(n: NimNode, i: int): NimNode {.magic: "NChild", noSideEffect.}
  ## Get `n`'s `i`'th child.

proc `[]`*(n: NimNode, i: BackwardsIndex): NimNode = n[n.len - i.int]
  ## Get `n`'s `i`'th child.

proc `[]`*[T, U](n: NimNode, x: HSlice[T, U]): seq[NimNode] =
  ## Slice operation for NimNode.
  ## Returns a seq of child of `n` who inclusive range [n[x.a], n[x.b]].
  let xa = n ^^ x.a
  let L = (n ^^ x.b) - xa + 1
  result = newSeq[NimNode](L)
  for i in 0..<L:
    result[i] = n[i + xa]

proc `[]=`*(n: NimNode, i: int, child: NimNode) {.magic: "NSetChild",
  noSideEffect.}
  ## Set `n`'s `i`'th child to `child`.

proc `[]=`*(n: NimNode, i: BackwardsIndex, child: NimNode) =
  ## Set `n`'s `i`'th child to `child`.
  n[n.len - i.int] = child

template `or`*(x, y: NimNode): NimNode =
  ## Evaluate ``x`` and when it is not an empty node, return
  ## it. Otherwise evaluate to ``y``. Can be used to chain several
  ## expressions to get the first expression that is not empty.
  ##
  ## .. code-block:: nim
  ##
  ##   let node = mightBeEmpty() or mightAlsoBeEmpty() or fallbackNode

  let arg = x
  if arg != nil and arg.kind != nnkEmpty:
    arg
  else:
    y

proc add*(father, child: NimNode): NimNode {.magic: "NAdd", discardable,
  noSideEffect, locks: 0.}
  ## Adds the `child` to the `father` node. Returns the
  ## father node so that calls can be nested.

proc add*(father: NimNode, children: varargs[NimNode]): NimNode {.
  magic: "NAddMultiple", discardable, noSideEffect, locks: 0.}
  ## Adds each child of `children` to the `father` node.
  ## Returns the `father` node so that calls can be nested.

proc del*(father: NimNode, idx = 0, n = 1) {.magic: "NDel", noSideEffect.}
  ## Deletes `n` children of `father` starting at index `idx`.

proc kind*(n: NimNode): NimNodeKind {.magic: "NKind", noSideEffect.}
  ## Returns the `kind` of the node `n`.

proc intVal*(n: NimNode): BiggestInt {.magic: "NIntVal", noSideEffect.}
  ## Returns an integer value from any integer literal or enum field symbol.

proc floatVal*(n: NimNode): BiggestFloat {.magic: "NFloatVal", noSideEffect.}
  ## Returns a float from any floating point literal.

when defined(nimSymKind):
  proc symKind*(symbol: NimNode): NimSymKind {.magic: "NSymKind", noSideEffect.}
  proc getImpl*(symbol: NimNode): NimNode {.magic: "GetImpl", noSideEffect.}
    ## Returns a copy of the declaration of a symbol or `nil`.
  proc strVal*(n: NimNode): string  {.magic: "NStrVal", noSideEffect.}
    ## Returns the string value of an identifier, symbol, comment, or string literal.
    ##
    ## See also:
    ## * `strVal= proc<#strVal=,NimNode,string>`_ for setting the string value.

when defined(nimSymImplTransform):
  proc getImplTransformed*(symbol: NimNode): NimNode {.magic: "GetImplTransf", noSideEffect.}
    ## For a typed proc returns the AST after transformation pass.

when defined(nimHasSymOwnerInMacro):
  proc owner*(sym: NimNode): NimNode {.magic: "SymOwner", noSideEffect.}
    ## Accepts a node of kind `nnkSym` and returns its owner's symbol.
    ## The meaning of 'owner' depends on `sym`'s `NimSymKind` and declaration
    ## context. For top level declarations this is an `nskModule` symbol,
    ## for proc local variables an `nskProc` symbol, for enum/object fields an
    ## `nskType` symbol, etc. For symbols without an owner, `nil` is returned.
    ##
    ## See also:
    ## * `symKind proc<#symKind,NimNode>`_ to get the kind of a symbol
    ## * `getImpl proc<#getImpl,NimNode>`_ to get the declaration of a symbol

when defined(nimHasInstantiationOfInMacro):
  proc isInstantiationOf*(instanceProcSym, genProcSym: NimNode): bool {.magic: "SymIsInstantiationOf", noSideEffect.}
    ## Checks if a proc symbol is an instance of the generic proc symbol.
    ## Useful to check proc symbols against generic symbols
    ## returned by `bindSym`.

proc getType*(n: NimNode): NimNode {.magic: "NGetType", noSideEffect, deprecated: "Use either `getTypeInst` or `getTypeImpl`.".}
  ## With 'getType' you can access the node's `type`:idx:. A Nim type is
  ## mapped to a Nim AST too, so it's slightly confusing but it means the same
  ## API can be used to traverse types. Recursive types are flattened for you
  ## so there is no danger of infinite recursions during traversal. To
  ## resolve recursive types, you have to call 'getType' again. To see what
  ## kind of type it is, call `typeKind` on getType's result.

proc getType*(n: typedesc): NimNode {.magic: "NGetType", noSideEffect, deprecated: "Use either `getTypeInst` or `getTypeImpl`.".}
  ## Version of ``getType`` which takes a ``typedesc``.

proc typeKind*(n: NimNode): NimTypeKind {.magic: "NGetType", noSideEffect.}
  ## Returns the type kind of the node 'n' that should represent a type, that
  ## means the node should have been obtained via ``getType``.

proc getTypeInst*(n: NimNode): NimNode {.magic: "NGetType", noSideEffect.} =
  ## Returns the `type`:idx: of a node in a form matching the way the
  ## type instance was declared in the code.
  runnableExamples:
    type
      Vec[N: static[int], T] = object
        arr: array[N, T]
      Vec4[T] = Vec[4, T]
      Vec4f = Vec4[float32]
    var a: Vec4f
    var b: Vec4[float32]
    var c: Vec[4, float32]
    macro dumpTypeInst(x: typed): untyped =
      newLit(x.getTypeInst.repr)
    doAssert(dumpTypeInst(a) == "Vec4f")
    doAssert(dumpTypeInst(b) == "Vec4[float32]")
    doAssert(dumpTypeInst(c) == "Vec[4, float32]")

proc getTypeInst*(n: typedesc): NimNode {.magic: "NGetType", noSideEffect.}
  ## Version of ``getTypeInst`` which takes a ``typedesc``.

proc getTypeImpl*(n: NimNode): NimNode {.magic: "NGetType", noSideEffect.} =
  ## Returns the `type`:idx: of a node in a form matching the implementation
  ## of the type. Any intermediate aliases are expanded to arrive at the final
  ## type implementation. You can instead use ``getImpl`` on a symbol if you
  ## want to find the intermediate aliases.
  runnableExamples:
    type
      Vec[N: static[int], T] = object
        arr: array[N, T]
      Vec4[T] = Vec[4, T]
      Vec4f = Vec4[float32]
    var a: Vec4f
    var b: Vec4[float32]
    var c: Vec[4, float32]
    macro dumpTypeImpl(x: typed): untyped =
      newLit(x.getTypeImpl.repr)
    let t = """
object
  arr: array[0 .. 3, float32]
"""
    doAssert(dumpTypeImpl(a) == t)
    doAssert(dumpTypeImpl(b) == t)
    doAssert(dumpTypeImpl(c) == t)

when defined(nimHasSignatureHashInMacro):
  proc signatureHash*(n: NimNode): string {.magic: "NSigHash", noSideEffect.}
    ## Returns a stable identifier derived from the signature of a symbol.
    ## The signature combines many factors such as the type of the symbol,
    ## the owning module of the symbol and others. The same identifier is
    ## used in the back-end to produce the mangled symbol name.

proc symBodyHash*(s: NimNode): string {.noSideEffect.} =
  ## Returns a stable digest for symbols derived not only from type signature
  ## and owning module, but also implementation body. All procs/variables used in
  ## the implementation of this symbol are hashed recursively as well, including
  ## magics from system module.
  discard

proc getTypeImpl*(n: typedesc): NimNode {.magic: "NGetType", noSideEffect.}
  ## Version of ``getTypeImpl`` which takes a ``typedesc``.

proc `intVal=`*(n: NimNode, val: BiggestInt) {.magic: "NSetIntVal", noSideEffect.}
proc `floatVal=`*(n: NimNode, val: BiggestFloat) {.magic: "NSetFloatVal", noSideEffect.}

proc `strVal=`*(n: NimNode, val: string) {.magic: "NSetStrVal", noSideEffect.}
  ## Sets the string value of a string literal or comment.
  ## Setting `strVal` is disallowed for `nnkIdent` and `nnkSym` nodes; a new node
  ## must be created using `ident` or `bindSym` instead.
  ##
  ## See also:
  ## * `strVal proc<#strVal,NimNode>`_ for getting the string value.
  ## * `ident proc<#ident,string>`_ for creating an identifier.
  ## * `bindSym proc<#bindSym%2C%2CBindSymRule>`_ for binding a symbol.

proc newNimNode*(kind: NimNodeKind,
                 lineInfoFrom: NimNode = nil): NimNode
  {.magic: "NNewNimNode", noSideEffect.}
  ## Creates a new AST node of the specified kind.
  ##
  ## The ``lineInfoFrom`` parameter is used for line information when the
  ## produced code crashes. You should ensure that it is set to a node that
  ## you are transforming.

proc copyNimNode*(n: NimNode): NimNode {.magic: "NCopyNimNode", noSideEffect.}
proc copyNimTree*(n: NimNode): NimNode {.magic: "NCopyNimTree", noSideEffect.}

proc error*(msg: string, n: NimNode = nil) {.magic: "NError", benign.}
  ## Writes an error message at compile time. The optional ``n: NimNode``
  ## parameter is used as the source for file and line number information in
  ## the compilation error message.

proc warning*(msg: string, n: NimNode = nil) {.magic: "NWarning", benign.}
  ## Writes a warning message at compile time.

proc hint*(msg: string, n: NimNode = nil) {.magic: "NHint", benign.}
  ## Writes a hint message at compile time.

proc newStrLitNode*(s: string): NimNode {.compileTime, noSideEffect.} =
  ## Creates a string literal node from `s`.
  result = newNimNode(nnkStrLit)
  result.strVal = s

proc newCommentStmtNode*(s: string): NimNode {.compileTime, noSideEffect.} =
  ## Creates a comment statement node.
  result = newNimNode(nnkCommentStmt)
  result.strVal = s

proc newIntLitNode*(i: BiggestInt): NimNode {.compileTime.} =
  ## Creates an int literal node from `i`.
  result = newNimNode(nnkIntLit)
  result.intVal = i

proc newFloatLitNode*(f: BiggestFloat): NimNode {.compileTime.} =
  ## Creates a float literal node from `f`.
  result = newNimNode(nnkFloatLit)
  result.floatVal = f

proc newIdentNode*(i: string): NimNode {.magic: "StrToIdent", noSideEffect, compilerproc.}
  ## Creates an identifier node from `i`. It is simply an alias for
  ## ``ident(string)``. Use that, it's shorter.

type
  BindSymRule* = enum    ## specifies how ``bindSym`` behaves
    brClosed,            ## only the symbols in current scope are bound
    brOpen,              ## open wrt overloaded symbols, but may be a single
                         ## symbol if not ambiguous (the rules match that of
                         ## binding in generics)
    brForceOpen          ## same as brOpen, but it will always be open even
                         ## if not ambiguous (this cannot be achieved with
                         ## any other means in the language currently)

proc bindSym*(ident: string | NimNode, rule: BindSymRule = brClosed): NimNode {.
              magic: "NBindSym", noSideEffect.}
  ## Ceates a node that binds `ident` to a symbol node. The bound symbol
  ## may be an overloaded symbol.
  ## if `ident` is a NimNode, it must have ``nnkIdent`` kind.
  ## If ``rule == brClosed`` either an ``nnkClosedSymChoice`` tree is
  ## returned or ``nnkSym`` if the symbol is not ambiguous.
  ## If ``rule == brOpen`` either an ``nnkOpenSymChoice`` tree is
  ## returned or ``nnkSym`` if the symbol is not ambiguous.
  ## If ``rule == brForceOpen`` always an ``nnkOpenSymChoice`` tree is
  ## returned even if the symbol is not ambiguous.
  ##
  ## Experimental feature:
  ## use {.experimental: "dynamicBindSym".} to activate it.
  ## If called from template / regular code, `ident` and `rule` must be
  ## constant expression / literal value.
  ## If called from macros / compile time procs / static blocks,
  ## `ident` and `rule` can be VM computed value.

proc genSym*(kind: NimSymKind = nskLet; ident = ""): NimNode {.
  magic: "NGenSym", noSideEffect.}
  ## Generates a fresh symbol that is guaranteed to be unique. The symbol
  ## needs to occur in a declaration context.

proc callsite*(): NimNode {.magic: "NCallSite", benign.}
  ## Returns the call expression that invokes this macro.

proc toStrLit*(n: NimNode): NimNode {.compileTime.} =
  ## Converts the AST `n` to the concrete Nim code and wraps that
  ## in a string literal node.
  return newStrLitNode(repr(n))

type
  LineInfo* = object
    filename*: string
    line*,column*: int

proc `$`*(arg: LineInfo): string =
  ## Return a string representation in the form `filepath(line, column)`.
  # BUG: without `result = `, gives compile error
  result = arg.filename & "(" & $arg.line & ", " & $arg.column & ")"

proc getLine(arg: NimNode): int {.magic: "NLineInfo", noSideEffect.}
proc getColumn(arg: NimNode): int {.magic: "NLineInfo", noSideEffect.}
proc getFile(arg: NimNode): string {.magic: "NLineInfo", noSideEffect.}

proc copyLineInfo*(arg: NimNode, info: NimNode) {.magic: "NLineInfo", noSideEffect.}
  ## Copy lineinfo from ``info``.

proc lineInfoObj*(n: NimNode): LineInfo {.compileTime.} =
  ## Returns ``LineInfo`` of ``n``, using absolute path for ``filename``.
  result.filename = n.getFile
  result.line = n.getLine
  result.column = n.getColumn

proc lineInfo*(arg: NimNode): string {.compileTime.} =
  ## Return line info in the form `filepath(line, column)`.
  $arg.lineInfoObj

proc internalParseExpr(s: string): NimNode {.
  magic: "ParseExprToAst", noSideEffect.}

proc internalParseStmt(s: string): NimNode {.
  magic: "ParseStmtToAst", noSideEffect.}

proc internalErrorFlag*(): string {.magic: "NError", noSideEffect.}
  ## Some builtins set an error flag. This is then turned into a proper
  ## exception. **Note**: Ordinary application code should not call this.

proc parseExpr*(s: string): NimNode {.noSideEffect, compileTime.} =
  ## Compiles the passed string to its AST representation.
  ## Expects a single expression. Raises ``ValueError`` for parsing errors.
  result = internalParseExpr(s)
  let x = internalErrorFlag()
  if x.len > 0: raise newException(ValueError, x)

proc parseStmt*(s: string): NimNode {.noSideEffect, compileTime.} =
  ## Compiles the passed string to its AST representation.
  ## Expects one or more statements. Raises ``ValueError`` for parsing errors.
  result = internalParseStmt(s)
  let x = internalErrorFlag()
  if x.len > 0: raise newException(ValueError, x)

proc getAst*(macroOrTemplate: untyped): NimNode {.magic: "ExpandToAst", noSideEffect.}
  ## Obtains the AST nodes returned from a macro or template invocation.
  ## Example:
  ##
  ## .. code-block:: nim
  ##
  ##   macro FooMacro() =
  ##     var ast = getAst(BarTemplate())

proc quote*(bl: typed, op = "``"): NimNode {.magic: "QuoteAst", noSideEffect.}
  ## Quasi-quoting operator.
  ## Accepts an expression or a block and returns the AST that represents it.
  ## Within the quoted AST, you are able to interpolate NimNode expressions
  ## from the surrounding scope. If no operator is given, quoting is done using
  ## backticks. Otherwise, the given operator must be used as a prefix operator
  ## for any interpolated expression.
  ##
  ## Example:
  ##
  ## .. code-block:: nim
  ##
  ##   macro check(ex: untyped) =
  ##     # this is a simplified version of the check macro from the
  ##     # unittest module.
  ##
  ##     # If there is a failed check, we want to make it easy for
  ##     # the user to jump to the faulty line in the code, so we
  ##     # get the line info here:
  ##     var info = ex.lineinfo
  ##
  ##     # We will also display the code string of the failed check:
  ##     var expString = ex.toStrLit
  ##
  ##     # Finally we compose the code to implement the check:
  ##     result = quote do:
  ##       if not `ex`:
  ##         echo `info` & ": Check failed: " & `expString`

proc expectKind*(n: NimNode, k: NimNodeKind) {.compileTime.} =
  ## Checks that `n` is of kind `k`. If this is not the case,
  ## compilation aborts with an error message. This is useful for writing
  ## macros that check the AST that is passed to them.
  if n.kind != k: error("Expected a node of kind " & $k & ", got " & $n.kind, n)

proc expectMinLen*(n: NimNode, min: int) {.compileTime.} =
  ## Checks that `n` has at least `min` children. If this is not the case,
  ## compilation aborts with an error message. This is useful for writing
  ## macros that check its number of arguments.
  if n.len < min: error("Expected a node with at least " & $min & " children, got " & $n.len, n)

proc expectLen*(n: NimNode, len: int) {.compileTime.} =
  ## Checks that `n` has exactly `len` children. If this is not the case,
  ## compilation aborts with an error message. This is useful for writing
  ## macros that check its number of arguments.
  if n.len != len: error("Expected a node with " & $len & " children, got " & $n.len, n)

proc expectLen*(n: NimNode, min, max: int) {.compileTime.} =
  ## Checks that `n` has a number of children in the range ``min..max``.
  ## If this is not the case, compilation aborts with an error message.
  ## This is useful for writing macros that check its number of arguments.
  if n.len < min or n.len > max:
    error("Expected a node with " & $min & ".." & $max & " children, got " & $n.len, n)

proc newTree*(kind: NimNodeKind,
              children: varargs[NimNode]): NimNode {.compileTime.} =
  ## Produces a new node with children.
  result = newNimNode(kind)
  result.add(children)

proc newCall*(theProc: NimNode,
              args: varargs[NimNode]): NimNode {.compileTime.} =
  ## Produces a new call node. `theProc` is the proc that is called with
  ## the arguments ``args[0..]``.
  result = newNimNode(nnkCall)
  result.add(theProc)
  result.add(args)

proc newCall*(theProc: string,
              args: varargs[NimNode]): NimNode {.compileTime.} =
  ## Produces a new call node. `theProc` is the proc that is called with
  ## the arguments ``args[0..]``.
  result = newNimNode(nnkCall)
  result.add(newIdentNode(theProc))
  result.add(args)

proc newLit*(c: char): NimNode {.compileTime.} =
  ## Produces a new character literal node.
  result = newNimNode(nnkCharLit)
  result.intVal = ord(c)

proc newLit*(i: int): NimNode {.compileTime.} =
  ## Produces a new integer literal node.
  result = newNimNode(nnkIntLit)
  result.intVal = i

proc newLit*(i: int8): NimNode {.compileTime.} =
  ## Produces a new integer literal node.
  result = newNimNode(nnkInt8Lit)
  result.intVal = i

proc newLit*(i: int16): NimNode {.compileTime.} =
  ## Produces a new integer literal node.
  result = newNimNode(nnkInt16Lit)
  result.intVal = i

proc newLit*(i: int32): NimNode {.compileTime.} =
  ## Produces a new integer literal node.
  result = newNimNode(nnkInt32Lit)
  result.intVal = i

proc newLit*(i: int64): NimNode {.compileTime.} =
  ## Produces a new integer literal node.
  result = newNimNode(nnkInt64Lit)
  result.intVal = i

proc newLit*(i: uint): NimNode {.compileTime.} =
  ## Produces a new unsigned integer literal node.
  result = newNimNode(nnkUIntLit)
  result.intVal = BiggestInt(i)

proc newLit*(i: uint8): NimNode {.compileTime.} =
  ## Produces a new unsigned integer literal node.
  result = newNimNode(nnkUInt8Lit)
  result.intVal = BiggestInt(i)

proc newLit*(i: uint16): NimNode {.compileTime.} =
  ## Produces a new unsigned integer literal node.
  result = newNimNode(nnkUInt16Lit)
  result.intVal = BiggestInt(i)

proc newLit*(i: uint32): NimNode {.compileTime.} =
  ## Produces a new unsigned integer literal node.
  result = newNimNode(nnkUInt32Lit)
  result.intVal = BiggestInt(i)

proc newLit*(i: uint64): NimNode {.compileTime.} =
  ## Produces a new unsigned integer literal node.
  result = newNimNode(nnkUInt64Lit)
  result.intVal = BiggestInt(i)

proc newLit*(b: bool): NimNode {.compileTime.} =
  ## Produces a new boolean literal node.
  result = if b: bindSym"true" else: bindSym"false"

proc newLit*(s: string): NimNode {.compileTime.} =
  ## Produces a new string literal node.
  result = newNimNode(nnkStrLit)
  result.strVal = s

proc newLit*(f: float32): NimNode {.compileTime.} =
  ## Produces a new float literal node.
  result = newNimNode(nnkFloat32Lit)
  result.floatVal = f

proc newLit*(f: float64): NimNode {.compileTime.} =
  ## Produces a new float literal node.
  result = newNimNode(nnkFloat64Lit)
  result.floatVal = f

when declared(float128):
  proc newLit*(f: float128): NimNode {.compileTime.} =
    ## Produces a new float literal node.
    result = newNimNode(nnkFloat128Lit)
    result.floatVal = f

proc newLit*(arg: enum): NimNode {.compileTime.} =
  result = newCall(
    getTypeInst(typeof(arg)),
    newLit(int(arg))
  )

proc newLit*[N,T](arg: array[N,T]): NimNode {.compileTime.}
proc newLit*[T](arg: seq[T]): NimNode {.compileTime.}
proc newLit*[T](s: set[T]): NimNode {.compileTime.}
proc newLit*(arg: tuple): NimNode {.compileTime.}

proc newLit*(arg: object): NimNode {.compileTime.} =
  result = nnkObjConstr.newTree(typeof(arg).getTypeInst)
  for a, b in arg.fieldPairs:
    result.add nnkExprColonExpr.newTree( newIdentNode(a), newLit(b) )

proc newLit*(arg: ref object): NimNode {.compileTime.} =
  ## produces a new ref type literal node.
  result = nnkObjConstr.newTree(getTypeInst(typeof(arg)))
  for a, b in fieldPairs(arg[]):
    result.add nnkExprColonExpr.newTree(newIdentNode(a), newLit(b))

proc newLit*[N,T](arg: array[N,T]): NimNode {.compileTime.} =
  result = nnkBracket.newTree
  for x in arg:
    result.add newLit(x)

proc newLit*[T](arg: seq[T]): NimNode {.compileTime.} =
  let bracket = nnkBracket.newTree
  for x in arg:
    bracket.add newLit(x)
  result = nnkPrefix.newTree(
    bindSym"@",
    bracket
  )
  if arg.len == 0:
    # add type cast for empty seq
    var typ = getTypeInst(typeof(arg))
    result = newCall(typ,result)

proc newLit*[T](s: set[T]): NimNode {.compileTime.} =
  result = nnkCurly.newTree
  for x in s:
    result.add newLit(x)

proc newLit*(arg: tuple): NimNode {.compileTime.} =
  result = nnkPar.newTree
  for a,b in arg.fieldPairs:
    result.add nnkExprColonExpr.newTree(newIdentNode(a), newLit(b))

proc newLit*(n: NimNode): NimNode {.compileTime, benign.} =
  ## Convert the AST ``n`` to the code required to generate that AST. Does currently not preserve line information.
  const LitKinds = nnkLiterals-{nnkNilLit}
  case n.kind
  of nnkNilLit:
    result = newCall(newIdentNode("newNimNode"), newIdentNode("nnkNilLit"))
  of nnkEmpty:
    result = newCall(newIdentNode("newEmptyNode"))
  of nnkIdent:
    result = nnkCallStrLit.newTree(newIdentNode("ident"), newLit(n.strVal))
  of nnkSym:
    assert false, "cannot preserve symbol binding through newLit"
  of nnkNone:
    result = newCall(newIdentNode("newNimNode"), newIdentNode("nnkNone"))
  of nnkCommentStmt:
    result = newCall("newCommentStmtNode", newLit(n.strVal))
  of LitKinds:
    result = newCall(bindSym"newLit", n)
  else:
    # some nodes kinds have constructor procs
    case n.kind
    of nnkStmtList:
      result = newCall(newIdentNode"newStmtList")
    of nnkCall:
      result = newCall(newIdentNode"newCall")
    of nnkAsgn:
      result = newCall(newIdentNode"newAssignment")
    of nnkDotExpr:
      result = newCall(newIdentNode"newDotExpr")
    of nnkExprColonExpr:
      result = newCall(newIdentNode"newColonExpr")
    else:
      result = newCall(nnkDotExpr.newTree(newIdentNode($n.kind), newIdentNode("newTree")))
    for i in 0 ..< n.len:
      result.add newLit(n[i])

macro undistinct[T: distinct](arg: T): untyped =
  ## convert and distinct value to its base type.
  let baseTyp = getTypeImpl(arg)[0]
  result = newCall(baseTyp, arg)

proc newLit*[T : distinct](arg: T): NimNode {.compileTime, since: (1,1).} =
  result = newCall(bindSym"T", newLit(undistinct(arg)))

proc nestList*(op: NimNode; pack: NimNode): NimNode {.compileTime.} =
  ## Nests the list `pack` into a tree of call expressions:
  ## ``[a, b, c]`` is transformed into ``op(a, op(c, d))``.
  ## This is also known as fold expression.
  if pack.len < 1:
    error("`nestList` expects a node with at least 1 child")
  result = pack[^1]
  for i in countdown(pack.len - 2, 0):
    result = newCall(op, pack[i], result)

proc nestList*(op: NimNode; pack: NimNode; init: NimNode): NimNode {.compileTime.} =
  ## Nests the list `pack` into a tree of call expressions:
  ## ``[a, b, c]`` is transformed into ``op(a, op(c, d))``.
  ## This is also known as fold expression.
  result = init
  for i in countdown(pack.len - 1, 0):
    result = newCall(op, pack[i], result)

proc treeTraverse(n: NimNode; res: var string; level = 0; isLisp = false, indented = false) {.benign.} =
  if level > 0:
    if indented:
      res.add("\n")
      for i in 0 .. level-1:
        if isLisp:
          res.add(" ")          # dumpLisp indentation
        else:
          res.add("  ")         # dumpTree indentation
    else:
      res.add(" ")

  if isLisp:
    res.add("(")
  res.add(($n.kind).substr(3))

  case n.kind
  of nnkEmpty, nnkNilLit:
    discard # same as nil node in this representation
  of nnkCharLit .. nnkInt64Lit:
    res.add(" " & $n.intVal)
  of nnkFloatLit .. nnkFloat64Lit:
    res.add(" " & $n.floatVal)
  of nnkStrLit .. nnkTripleStrLit, nnkCommentStmt, nnkIdent, nnkSym:
    res.add(" " & $n.strVal.newLit.repr)
  of nnkNone:
    assert false
  else:
    for j in 0 .. n.len-1:
      n[j].treeTraverse(res, level+1, isLisp, indented)

  if isLisp:
    res.add(")")

proc treeRepr*(n: NimNode): string {.compileTime, benign.} =
  ## Convert the AST `n` to a human-readable tree-like string.
  ##
  ## See also `repr`, `lispRepr`, and `astGenRepr`.
  n.treeTraverse(result, isLisp = false, indented = true)

proc lispRepr*(n: NimNode; indented = false): string {.compileTime, benign.} =
  ## Convert the AST ``n`` to a human-readable lisp-like string.
  ##
  ## See also ``repr``, ``treeRepr``, and ``astGenRepr``.
  n.treeTraverse(result, isLisp = true, indented = indented)

proc astGenRepr*(n: NimNode): string {.compileTime, benign.} =
  ## Convert the AST ``n`` to the code required to generate that AST.
  ##
  ## See also ``repr``, ``treeRepr``, and ``lispRepr``.
  let tmp = repr(newLit(n))
  # From here on, the rest of the code just rearranges whitespace in
  # ``tmp`` to a human redable form. It would probably be not
  # necessary, if ``repr`` would produce a better output for complex
  # single expression code.
  var i = 0
  var ind = "\n"
  let n = tmp.len
  while i < n:
    if tmp[i] == '\"': # east string literal
      var j = i+1
      while j < n and tmp[j] != '\"' and tmp[j-1] != '\\':
        inc j
      result.add tmp[i..j]
      i = j
    elif tmp[i] == '(' and tmp[i+1] != ')':
      var j = i+1
      while j < n and tmp[j] notin {'(', ')'}:
        inc j
      if tmp[j] == ')' and j - i <= 16:
        result.add tmp[i..j]
        i = j
      else:
        ind.add "  "
        result.add tmp[i]
        result.add ind
        while tmp[i+1] in {'\r', '\n', ' '}:
          inc i
    elif tmp[i] == ')' and tmp[i-1] != '(':
      ind.setLen(ind.len-2)
      result.add ind
      result.add tmp[i]
    elif tmp[i] == ',':
      result.add ','
      result.add ind
      while tmp[i+1] in {'\r', '\n', ' '}:
        inc i
    else:
      result.add tmp[i]
    inc i






macro dumpTree*(s: untyped): untyped = echo s.treeRepr
  ## Accepts a block of nim code and prints the parsed abstract syntax
  ## tree using the ``treeRepr`` proc. Printing is done *at compile time*.
  ##
  ## You can use this as a tool to explore the Nim's abstract syntax
  ## tree and to discover what kind of nodes must be created to represent
  ## a certain expression/statement.
  ##
  ## For example:
  ##
  ## .. code-block:: nim
  ##    dumpTree:
  ##      echo "Hello, World!"
  ##
  ## Outputs:
  ##
  ## .. code-block::
  ##    StmtList
  ##      Command
  ##        Ident "echo"
  ##        StrLit "Hello, World!"
  ##
  ## Also see ``dumpAstGen`` and ``dumpLisp``.

macro dumpLisp*(s: untyped): untyped = echo s.lispRepr(indented = true)
  ## Accepts a block of nim code and prints the parsed abstract syntax
  ## tree using the ``lispRepr`` proc. Printing is done *at compile time*.
  ##
  ## You can use this as a tool to explore the Nim's abstract syntax
  ## tree and to discover what kind of nodes must be created to represent
  ## a certain expression/statement.
  ##
  ## For example:
  ##
  ## .. code-block:: nim
  ##    dumpLisp:
  ##      echo "Hello, World!"
  ##
  ## Outputs:
  ##
  ## .. code-block::
  ##    (StmtList
  ##     (Command
  ##      (Ident "echo")
  ##      (StrLit "Hello, World!")))
  ##
  ## Also see ``dumpAstGen`` and ``dumpTree``.

macro dumpAstGen*(s: untyped): untyped = echo s.astGenRepr
  ## Accepts a block of nim code and prints the parsed abstract syntax
  ## tree using the ``astGenRepr`` proc. Printing is done *at compile time*.
  ##
  ## You can use this as a tool to write macros quicker by writing example
  ## outputs and then copying the snippets into the macro for modification.
  ##
  ## For example:
  ##
  ## .. code-block:: nim
  ##    dumpAstGen:
  ##      echo "Hello, World!"
  ##
  ## Outputs:
  ##
  ## .. code-block:: nim
  ##
  ##    newStmtList(
  ##      nnkCommand.newTree(
  ##        ident"echo",
  ##        newLit("Hello, World!")
  ##      )
  ##    )
  ##
  ## Also see ``dumpTree`` and ``dumpLisp``.

proc newEmptyNode*(): NimNode {.compileTime, noSideEffect.} =
  ## Create a new empty node.
  result = newNimNode(nnkEmpty)

proc newStmtList*(stmts: varargs[NimNode]): NimNode {.compileTime.}=
  ## Create a new statement list.
  result = newNimNode(nnkStmtList).add(stmts)

proc newPar*(exprs: varargs[NimNode]): NimNode {.compileTime.}=
  ## Create a new parentheses-enclosed expression.
  newNimNode(nnkPar).add(exprs)

proc newBlockStmt*(label, body: NimNode): NimNode {.compileTime.} =
  ## Create a new block statement with label.
  return newNimNode(nnkBlockStmt).add(label, body)

proc newBlockStmt*(body: NimNode): NimNode {.compileTime.} =
  ## Create a new block: stmt.
  return newNimNode(nnkBlockStmt).add(newEmptyNode(), body)

proc newVarStmt*(name, value: NimNode): NimNode {.compileTime.} =
  ## Create a new var stmt.
  return newNimNode(nnkVarSection).add(
    newNimNode(nnkIdentDefs).add(name, newNimNode(nnkEmpty), value))

proc newLetStmt*(name, value: NimNode): NimNode {.compileTime.} =
  ## Create a new let stmt.
  return newNimNode(nnkLetSection).add(
    newNimNode(nnkIdentDefs).add(name, newNimNode(nnkEmpty), value))

proc newConstStmt*(name, value: NimNode): NimNode {.compileTime.} =
  ## Create a new const stmt.
  newNimNode(nnkConstSection).add(
    newNimNode(nnkConstDef).add(name, newNimNode(nnkEmpty), value))

proc newAssignment*(lhs, rhs: NimNode): NimNode {.compileTime.} =
  return newNimNode(nnkAsgn).add(lhs, rhs)

proc newDotExpr*(a, b: NimNode): NimNode {.compileTime.} =
  ## Create new dot expression.
  ## a.dot(b) -> `a.b`
  return newNimNode(nnkDotExpr).add(a, b)

proc newColonExpr*(a, b: NimNode): NimNode {.compileTime.} =
  ## Create new colon expression.
  ## newColonExpr(a, b) -> `a: b`
  newNimNode(nnkExprColonExpr).add(a, b)

proc newIdentDefs*(name, kind: NimNode;
                   default = newEmptyNode()): NimNode {.compileTime.} =
  ## Creates a new ``nnkIdentDefs`` node of a specific kind and value.
  ##
  ## ``nnkIdentDefs`` need to have at least three children, but they can have
  ## more: first comes a list of identifiers followed by a type and value
  ## nodes. This helper proc creates a three node subtree, the first subnode
  ## being a single identifier name. Both the ``kind`` node and ``default``
  ## (value) nodes may be empty depending on where the ``nnkIdentDefs``
  ## appears: tuple or object definitions will have an empty ``default`` node,
  ## ``let`` or ``var`` blocks may have an empty ``kind`` node if the
  ## identifier is being assigned a value. Example:
  ##
  ## .. code-block:: nim
  ##
  ##   var varSection = newNimNode(nnkVarSection).add(
  ##     newIdentDefs(ident("a"), ident("string")),
  ##     newIdentDefs(ident("b"), newEmptyNode(), newLit(3)))
  ##   # --> var
  ##   #       a: string
  ##   #       b = 3
  ##
  ## If you need to create multiple identifiers you need to use the lower level
  ## ``newNimNode``:
  ##
  ## .. code-block:: nim
  ##
  ##   result = newNimNode(nnkIdentDefs).add(
  ##     ident("a"), ident("b"), ident("c"), ident("string"),
  ##       newStrLitNode("Hello"))
  newNimNode(nnkIdentDefs).add(name, kind, default)

proc newNilLit*(): NimNode {.compileTime.} =
  ## New nil literal shortcut.
  result = newNimNode(nnkNilLit)

proc last*(node: NimNode): NimNode {.compileTime.} = node[node.len-1]
  ## Return the last item in nodes children. Same as `node[^1]`.


const
  RoutineNodes* = {nnkProcDef, nnkFuncDef, nnkMethodDef, nnkDo, nnkLambda,
                   nnkIteratorDef, nnkTemplateDef, nnkConverterDef, nnkMacroDef}
  AtomicNodes* = {nnkNone..nnkNilLit}
  CallNodes* = {nnkCall, nnkInfix, nnkPrefix, nnkPostfix, nnkCommand,
    nnkCallStrLit, nnkHiddenCallConv}

proc expectKind*(n: NimNode; k: set[NimNodeKind]) {.compileTime.} =
  ## Checks that `n` is of kind `k`. If this is not the case,
  ## compilation aborts with an error message. This is useful for writing
  ## macros that check the AST that is passed to them.
  if n.kind notin k: error("Expected one of " & $k & ", got " & $n.kind, n)

proc newProc*(name = newEmptyNode();
              params: openArray[NimNode] = [newEmptyNode()];
              body: NimNode = newStmtList();
              procType = nnkProcDef;
              pragmas: NimNode = newEmptyNode()): NimNode {.compileTime.} =
  ## Shortcut for creating a new proc.
  ##
  ## The ``params`` array must start with the return type of the proc,
  ## followed by a list of IdentDefs which specify the params.
  if procType notin RoutineNodes:
    error("Expected one of " & $RoutineNodes & ", got " & $procType)
  pragmas.expectKind({nnkEmpty, nnkPragma})
  result = newNimNode(procType).add(
    name,
    newEmptyNode(),
    newEmptyNode(),
    newNimNode(nnkFormalParams).add(params),
    pragmas,
    newEmptyNode(),
    body)

proc newIfStmt*(branches: varargs[tuple[cond, body: NimNode]]):
                NimNode {.compileTime.} =
  ## Constructor for ``if`` statements.
  ##
  ## .. code-block:: nim
  ##
  ##    newIfStmt(
  ##      (Ident, StmtList),
  ##      ...
  ##    )
  ##
  result = newNimNode(nnkIfStmt)
  if len(branches) < 1:
    error("If statement must have at least one branch")
  for i in branches:
    result.add(newTree(nnkElifBranch, i.cond, i.body))

proc newEnum*(name: NimNode, fields: openArray[NimNode],
              public, pure: bool): NimNode {.compileTime.} =

  ## Creates a new enum. `name` must be an ident. Fields are allowed to be
  ## either idents or EnumFieldDef
  ##
  ## .. code-block:: nim
  ##
  ##    newEnum(
  ##      name    = ident("Colors"),
  ##      fields  = [ident("Blue"), ident("Red")],
  ##      public  = true, pure = false)
  ##
  ##    # type Colors* = Blue Red
  ##

  expectKind name, nnkIdent
  if len(fields) < 1:
    error("Enum must contain at least one field")
  for field in fields:
    expectKind field, {nnkIdent, nnkEnumFieldDef}

  let enumBody = newNimNode(nnkEnumTy).add(newEmptyNode()).add(fields)
  var typeDefArgs = [name, newEmptyNode(), enumBody]

  if public:
    let postNode = newNimNode(nnkPostfix).add(
      newIdentNode("*"), typeDefArgs[0])

    typeDefArgs[0] = postNode

  if pure:
    let pragmaNode = newNimNode(nnkPragmaExpr).add(
      typeDefArgs[0],
      add(newNimNode(nnkPragma), newIdentNode("pure")))

    typeDefArgs[0] = pragmaNode

  let
    typeDef   = add(newNimNode(nnkTypeDef), typeDefArgs)
    typeSect  = add(newNimNode(nnkTypeSection), typeDef)

  return typeSect

proc copyChildrenTo*(src, dest: NimNode) {.compileTime.}=
  ## Copy all children from `src` to `dest`.
  for i in 0 ..< src.len:
    dest.add src[i].copyNimTree

template expectRoutine(node: NimNode) =
  expectKind(node, RoutineNodes)

proc name*(someProc: NimNode): NimNode {.compileTime.} =
  someProc.expectRoutine
  result = someProc[0]
  if result.kind == nnkPostfix:
    if result[1].kind == nnkAccQuoted:
      result = result[1][0]
    else:
      result = result[1]
  elif result.kind == nnkAccQuoted:
    result = result[0]

proc `name=`*(someProc: NimNode; val: NimNode) {.compileTime.} =
  someProc.expectRoutine
  if someProc[0].kind == nnkPostfix:
    someProc[0][1] = val
  else: someProc[0] = val

proc params*(someProc: NimNode): NimNode {.compileTime.} =
  someProc.expectRoutine
  result = someProc[3]
proc `params=`* (someProc: NimNode; params: NimNode) {.compileTime.}=
  someProc.expectRoutine
  expectKind(params, nnkFormalParams)
  someProc[3] = params

proc pragma*(someProc: NimNode): NimNode {.compileTime.} =
  ## Get the pragma of a proc type.
  ## These will be expanded.
  if someProc.kind == nnkProcTy:
    result = someProc[1]
  else:
    someProc.expectRoutine
    result = someProc[4]
proc `pragma=`*(someProc: NimNode; val: NimNode) {.compileTime.}=
  ## Set the pragma of a proc type.
  expectKind(val, {nnkEmpty, nnkPragma})
  if someProc.kind == nnkProcTy:
    someProc[1] = val
  else:
    someProc.expectRoutine
    someProc[4] = val

proc addPragma*(someProc, pragma: NimNode) {.compileTime.} =
  ## Adds pragma to routine definition.
  someProc.expectKind(RoutineNodes + {nnkProcTy})
  var pragmaNode = someProc.pragma
  if pragmaNode.isNil or pragmaNode.kind == nnkEmpty:
    pragmaNode = newNimNode(nnkPragma)
    someProc.pragma = pragmaNode
  pragmaNode.add(pragma)

template badNodeKind(n, f: untyped) =
  error("Invalid node kind " & $n.kind & " for macros.`" & $f & "`", n)

proc body*(someProc: NimNode): NimNode {.compileTime.} =
  case someProc.kind:
  of RoutineNodes:
    return someProc[6]
  of nnkBlockStmt, nnkWhileStmt:
    return someProc[1]
  of nnkForStmt:
    return someProc.last
  else:
    badNodeKind someProc, "body"

proc `body=`*(someProc: NimNode, val: NimNode) {.compileTime.} =
  case someProc.kind
  of RoutineNodes:
    someProc[6] = val
  of nnkBlockStmt, nnkWhileStmt:
    someProc[1] = val
  of nnkForStmt:
    someProc[len(someProc)-1] = val
  else:
    badNodeKind someProc, "body="

proc basename*(a: NimNode): NimNode {.compileTime, benign.}

proc `$`*(node: NimNode): string {.compileTime.} =
  ## Get the string of an identifier node.
  case node.kind
  of nnkPostfix:
    result = node.basename.strVal & "*"
  of nnkStrLit..nnkTripleStrLit, nnkCommentStmt, nnkSym, nnkIdent:
    result = node.strVal
  of nnkOpenSymChoice, nnkClosedSymChoice:
    result = $node[0]
  of nnkAccQuoted:
    result = $node[0]
  else:
    badNodeKind node, "$"

proc ident*(name: string): NimNode {.magic: "StrToIdent", noSideEffect.}
  ## Create a new ident node from a string.

iterator items*(n: NimNode): NimNode {.inline.} =
  ## Iterates over the children of the NimNode ``n``.
  for i in 0 ..< n.len:
    yield n[i]

iterator pairs*(n: NimNode): (int, NimNode) {.inline.} =
  ## Iterates over the children of the NimNode ``n`` and its indices.
  for i in 0 ..< n.len:
    yield (i, n[i])

iterator children*(n: NimNode): NimNode {.inline.} =
  ## Iterates over the children of the NimNode ``n``.
  for i in 0 ..< n.len:
    yield n[i]

template findChild*(n: NimNode; cond: untyped): NimNode {.dirty.} =
  ## Find the first child node matching condition (or nil).
  ##
  ## .. code-block:: nim
  ##   var res = findChild(n, it.kind == nnkPostfix and
  ##                          it.basename.ident == toNimIdent"foo")
  block:
    var res: NimNode
    for it in n.children:
      if cond:
        res = it
        break
    res

proc insert*(a: NimNode; pos: int; b: NimNode) {.compileTime.} =
  ## Insert node ``b`` into node ``a`` at ``pos``.
  if len(a)-1 < pos:
    # add some empty nodes first
    for i in len(a)-1..pos-2:
      a.add newEmptyNode()
    a.add b
  else:
    # push the last item onto the list again
    # and shift each item down to pos up one
    a.add(a[a.len-1])
    for i in countdown(len(a) - 3, pos):
      a[i + 1] = a[i]
    a[pos] = b

proc basename*(a: NimNode): NimNode =
  ## Pull an identifier from prefix/postfix expressions.
  case a.kind
  of nnkIdent: result = a
  of nnkPostfix, nnkPrefix: result = a[1]
  of nnkPragmaExpr: result = basename(a[0])
  else:
    error("Do not know how to get basename of (" & treeRepr(a) & ")\n" &
      repr(a), a)

proc `basename=`*(a: NimNode; val: string) {.compileTime.}=
  case a.kind
  of nnkIdent:
    a.strVal = val
  of nnkPostfix, nnkPrefix:
    a[1] = ident(val)
  of nnkPragmaExpr: `basename=`(a[0], val)
  else:
    error("Do not know how to get basename of (" & treeRepr(a) & ")\n" &
      repr(a), a)

proc postfix*(node: NimNode; op: string): NimNode {.compileTime.} =
  newNimNode(nnkPostfix).add(ident(op), node)

proc prefix*(node: NimNode; op: string): NimNode {.compileTime.} =
  newNimNode(nnkPrefix).add(ident(op), node)

proc infix*(a: NimNode; op: string;
            b: NimNode): NimNode {.compileTime.} =
  newNimNode(nnkInfix).add(ident(op), a, b)

proc unpackPostfix*(node: NimNode): tuple[node: NimNode; op: string] {.
  compileTime.} =
  node.expectKind nnkPostfix
  result = (node[1], $node[0])

proc unpackPrefix*(node: NimNode): tuple[node: NimNode; op: string] {.
  compileTime.} =
  node.expectKind nnkPrefix
  result = (node[1], $node[0])

proc unpackInfix*(node: NimNode): tuple[left: NimNode; op: string;
                                        right: NimNode] {.compileTime.} =
  expectKind(node, nnkInfix)
  result = (node[1], $node[0], node[2])

proc copy*(node: NimNode): NimNode {.compileTime.} =
  ## An alias for `copyNimTree<#copyNimTree,NimNode>`_.
  return node.copyNimTree()

when defined(nimVmEqIdent):
  proc eqIdent*(a: string; b: string): bool {.magic: "EqIdent", noSideEffect.}
    ## Style insensitive comparison.

  proc eqIdent*(a: NimNode; b: string): bool {.magic: "EqIdent", noSideEffect.}
    ## Style insensitive comparison.  ``a`` can be an identifier or a
    ## symbol. ``a`` may be wrapped in an export marker
    ## (``nnkPostfix``) or quoted with backticks (``nnkAccQuoted``),
    ## these nodes will be unwrapped.

  proc eqIdent*(a: string; b: NimNode): bool {.magic: "EqIdent", noSideEffect.}
    ## Style insensitive comparison.  ``b`` can be an identifier or a
    ## symbol. ``b`` may be wrapped in an export marker
    ## (``nnkPostfix``) or quoted with backticks (``nnkAccQuoted``),
    ## these nodes will be unwrapped.

  proc eqIdent*(a: NimNode; b: NimNode): bool {.magic: "EqIdent", noSideEffect.}
    ## Style insensitive comparison.  ``a`` and ``b`` can be an
    ## identifier or a symbol. Both may be wrapped in an export marker
    ## (``nnkPostfix``) or quoted with backticks (``nnkAccQuoted``),
    ## these nodes will be unwrapped.

else:
  # this procedure is optimized for native code, it should not be compiled to nimVM bytecode.
  proc cmpIgnoreStyle(a, b: cstring): int {.noSideEffect.} =
    proc toLower(c: char): char {.inline.} =
      if c in {'A'..'Z'}: result = chr(ord(c) + (ord('a') - ord('A')))
      else: result = c
    var i = 0
    var j = 0
    # first char is case sensitive
    if a[0] != b[0]: return 1
    while true:
      while a[i] == '_': inc(i)
      while b[j] == '_': inc(j) # BUGFIX: typo
      var aa = toLower(a[i])
      var bb = toLower(b[j])
      result = ord(aa) - ord(bb)
      if result != 0 or aa == '\0': break
      inc(i)
      inc(j)


  proc eqIdent*(a, b: string): bool = cmpIgnoreStyle(a, b) == 0
    ## Check if two idents are equal.

  proc eqIdent*(node: NimNode; s: string): bool {.compileTime.} =
    ## Check if node is some identifier node (``nnkIdent``, ``nnkSym``, etc.)
    ## is the same as ``s``. Note that this is the preferred way to check! Most
    ## other ways like ``node.ident`` are much more error-prone, unfortunately.
    case node.kind
    of nnkSym, nnkIdent:
      result = eqIdent(node.strVal, s)
    of nnkOpenSymChoice, nnkClosedSymChoice:
      result = eqIdent($node[0], s)
    else:
      result = false

proc expectIdent*(n: NimNode, name: string) {.compileTime, since: (1,1).} =
  ## Check that ``eqIdent(n,name)`` holds true. If this is not the
  ## case, compilation aborts with an error message. This is useful
  ## for writing macros that check the AST that is passed to them.
  if not eqIdent(n, name):
    error("Expected identifier to be `" & name & "` here", n)

proc hasArgOfName*(params: NimNode; name: string): bool {.compileTime.}=
  ## Search ``nnkFormalParams`` for an argument.
  expectKind(params, nnkFormalParams)
  for i in 1 ..< params.len:
    template node: untyped = params[i]
    if name.eqIdent( $ node[0]):
      return true

proc addIdentIfAbsent*(dest: NimNode, ident: string) {.compileTime.} =
  ## Add ``ident`` to ``dest`` if it is not present. This is intended for use
  ## with pragmas.
  for node in dest.children:
    case node.kind
    of nnkIdent:
      if ident.eqIdent($node): return
    of nnkExprColonExpr:
      if ident.eqIdent($node[0]): return
    else: discard
  dest.add(ident(ident))

proc boolVal*(n: NimNode): bool {.compileTime, noSideEffect.} =
  if n.kind == nnkIntLit: n.intVal != 0
  else: n == bindSym"true" # hacky solution for now

when defined(nimMacrosGetNodeId):
  proc nodeID*(n: NimNode): int {.magic: "NodeId".}
    ## Returns the id of ``n``, when the compiler has been compiled
    ## with the flag ``-d:useNodeids``, otherwise returns ``-1``. This
    ## proc is for the purpose to debug the compiler only.

macro expandMacros*(body: typed): untyped =
  ## Expands one level of macro - useful for debugging.
  ## Can be used to inspect what happens when a macro call is expanded,
  ## without altering its result.
  ##
  ## For instance,
  ##
  ## .. code-block:: nim
  ##   import sugar, macros
  ##
  ##   let
  ##     x = 10
  ##     y = 20
  ##   expandMacros:
  ##     dump(x + y)
  ##
  ## will actually dump `x + y`, but at the same time will print at
  ## compile time the expansion of the ``dump`` macro, which in this
  ## case is ``debugEcho ["x + y", " = ", x + y]``.
  echo body.toStrLit
  result = body

proc findPragmaExprForFieldSym(arg: NimNode, fieldSym: NimNode): NimNode =
  case arg.kind
  of nnkRecList, nnkRecCase:
    for it in arg.children:
      result = findPragmaExprForFieldSym(it, fieldSym)
      if result != nil:
        return
  of nnkOfBranch:
    return findPragmaExprForFieldSym(arg[1], fieldSym)
  of nnkElse:
    return findPragmaExprForFieldSym(arg[0], fieldSym)
  of nnkIdentDefs:
    for i in 0 ..< arg.len-2:
      let child = arg[i]
      result = findPragmaExprForFieldSym(child, fieldSym)
      if result != nil:
        return
  of nnkIdent, nnkSym, nnkPostfix:
    return nil
  of nnkPragmaExpr:
    var ident = arg[0]
    if ident.kind == nnkPostfix: ident = ident[1]
    if ident.kind == nnkAccQuoted: ident = ident[0]
    if eqIdent(ident, fieldSym):
      return arg[1]
  else:
    error("illegal arg: ", arg)

proc getPragmaByName(pragmaExpr: NimNode, name: string): NimNode =
  if pragmaExpr.kind == nnkPragma:
    for it in pragmaExpr:
      if it.kind in nnkPragmaCallKinds:
        if eqIdent(it[0], name):
          return it
      elif it.kind == nnkSym:
        if eqIdent(it, name):
          return it


proc getCustomPragmaNodeFromProcSym(sym: NimNode, name: string): NimNode =
  sym.expectKind nnkSym
  if sym.symKind != nskProc:
    error("expected proc sym", sym)

  let impl = sym.getImpl
  expectKind(impl, nnkProcDef)
  result = getPragmaByName(impl[4], name)

proc getCustomPragmaNodeFromObjFieldSym(sym: NimNode, name: string): NimNode =
  sym.expectKind nnkSym
  if sym.symKind != nskField:
    error("expected field sym", sym)

  # note this is not ``getTypeImpl``, because the result of
  # ``getTypeImpl`` is cleaned up of any pragma expressions.
  let impl = sym.owner.getImpl
  impl.expectKind nnkTypeDef

  var objectTy = impl[2]
  if objectTy.kind == nnkRefTy:
    objectTy = objectTy[0]

  # only works on object types
  objectTy.expectKind nnkObjectTy

  let recList = objectTy[2]
  recList.expectKind nnkRecList
  let pragmaExpr = findPragmaExprForFieldSym(recList, sym)
  getPragmaByName(pragmaExpr, name)

proc getCustomPragmaNodeFromTypeSym(sym: NimNode, name: string): NimNode =
  sym.expectKind nnkSym
  if sym.symKind != nskType:
    error("expected type sym", sym)
  let impl = sym.getImpl
  if impl.len > 0:
    assert impl.kind == nnkTypeDef
    let pragmaExpr = impl[0]
    if pragmaExpr.kind == nnkPragmaExpr:
      result = getPragmaByName(pragmaExpr[1], name)

proc getCustomPragmaNodeFromVarLetSym(sym: NimNode, name: string): NimNode =
  sym.expectKind nnkSym
  if sym.symKind notin {nskVar, nskLet}:
    error("expected var/let sym", sym)

  let impl = sym.getImpl
  assert impl.kind == nnkIdentDefs
  assert impl.len == 3
  if impl.len > 0:
    let pragmaExpr = impl[0]
    if pragmaExpr.kind == nnkPragmaExpr:
      result = getPragmaByName(pragmaExpr[1], name)

proc getCustomPragmaNode*(sym: NimNode, name: string): NimNode =
  sym.expectKind nnkSym
  case sym.symKind
  of nskField:
    result = getCustomPragmaNodeFromObjFieldSym(sym,name)
  of nskProc:
    result = getCustomPragmaNodeFromProcSym(sym, name)
  of nskType:
    result = getCustomPragmaNodeFromTypeSym(sym, name)
  of nskParam:
    # Warning: shitty typedesc handling workarounds ahead. I hate `typedesc` so much.
    # When a typedesc parameter is passed to the macro, it will be of nskParam. , not of
    let typeInst = getTypeInst(sym)
    if typeInst.kind == nnkBracketExpr and eqIdent(typeInst[0], "typeDesc"):
      warning("Pleased don't pass shitty typedesc values to this macro. Please use real type expressions, symbols of kind nskType. Thank you.", sym)
      result = getCustomPragmaNodeFromTypeSym(typeInst[1], name)
    else:
      error("illegal sym kind for argument: " & $sym.symKind, sym)
  of nskVar, nskLet:
    # I think it is a bad idea to fall back to the typeSym. The API
    # explicity requests a var/let symbol, not a type symbol.
    result =
      getCustomPragmaNodeFromVarLetSym(sym, name) or
      getCustomPragmaNodeFromTypeSym(sym.getTypeInst, name)
  else:
    error("illegal sym kind for argument: " & $sym.symKind, sym)

proc hasCustomPragma*(n: NimNode, name: string): bool =
  n.expectKind nnkSym
  let pragmaNode = getCustomPragmaNode(n, name)
  result = pragmaNode != nil

macro hasCustomPragma*(n: typed, cp: typed{nkSym}): bool =
  ## Expands to `true` if expression `n` which is expected to be `nnkDotExpr`
  ## (if checking a field), a proc or a type has custom pragma `cp`.
  ##
  ## See also `getCustomPragmaVal`.
  ##
  ## .. code-block:: nim
  ##   template myAttr() {.pragma.}
  ##   type
  ##     MyObj = object
  ##       myField {.myAttr.}: int
  ##
  ##   proc myProc() {.myAttr.} = discard
  ##
  ##   var o: MyObj
  ##   assert(o.myField.hasCustomPragma(myAttr))
  ##   assert(myProc.hasCustomPragma(myAttr))
  case n.kind
  of nnkDotExpr:
    result = newLit(hasCustomPragma(n[1],$cp))
  of nnkCheckedFieldExpr:
    expectKind n[0], nnkDotExpr
    result = newLit(hasCustomPragma(n[0][1],$cp))
  of nnkSym:
    result = newLit(hasCustomPragma(n,$cp))
  of nnkTypeOfExpr:
    var typeSym = n.getTypeInst
    # dealing with shitty typedesc that sneasks into everything
    while typeSym.kind == nnkBracketExpr and typeSym[0].eqIdent "typeDesc":
      typeSym = typeSym[1]
    case typeSym.kind:
    of nnkSym:
      result = newLit(hasCustomPragma(typeSym, $cp))
    of nnkProcTy:
      # It is a bad idea to support this. The annotation can't be part
      # of a symbol.
      let pragmaExpr = typeSym[1]
      result = newLit(getPragmaByName(pragmaExpr, $cp) != nil)
    else:
      typeSym.expectKind nnkSym
  else:
    n.expectKind({nnkDotExpr, nnkCheckedFieldExpr, nnkSym, nnkTypeOfExpr})

macro getCustomPragmaVal*(n: typed, cp: typed{nkSym}): untyped =
  ## Expands to value of custom pragma `cp` of expression `n` which is expected
  ## to be `nnkDotExpr`, a proc or a type.
  ##
  ## See also `hasCustomPragma`
  ##
  ## .. code-block:: nim
  ##   template serializationKey(key: string) {.pragma.}
  ##   type
  ##     MyObj {.serializationKey: "mo".} = object
  ##       myField {.serializationKey: "mf".}: int
  ##   var o: MyObj
  ##   assert(o.myField.getCustomPragmaVal(serializationKey) == "mf")
  ##   assert(o.getCustomPragmaVal(serializationKey) == "mo")
  ##   assert(MyObj.getCustomPragmaVal(serializationKey) == "mo")

  n.expectKind({nnkDotExpr, nnkCheckedFieldExpr, nnkSym, nnkTypeOfExpr})
  let pragmaNode =
    case n.kind
    of nnkDotExpr:
      getCustomPragmaNode(n[1], $cp)
    of nnkCheckedFieldExpr:
      expectKind n[0], nnkDotExpr
      getCustomPragmaNode(n[0][1],$cp)
    of nnkSym:
      getCustomPragmaNode(n, $cp)
    else:
      var typeSym = n.getTypeInst
      # dealing with shitty typedesc that sneasks into everything
      while typeSym.kind == nnkBracketExpr and typeSym[0].eqIdent "typeDesc":
        typeSym = typeSym[1]
      case typeSym.kind:
      of nnkSym:
        getCustomPragmaNode(typeSym, $cp)
      of nnkProcTy:
        # It is a bad idea to support this. The annotation can't be part
        # of a symbol.
        let pragmaExpr = typeSym[1]
        getPragmaByName(pragmaExpr, $cp)
      else:
        typeSym.expectKind nnkSym
        # dead code just for the type checker
        nil

  case pragmaNode.kind
  of nnkPragmaCallKinds:
    assert(pragmaNode[0] == cp)
    if pragmaNode.len == 2:
      result = pragmaNode[1]
    else:
      # create a named tuple expression for pragmas with multiple arguments
      let def = pragmaNode[0].getImpl[3]
      result = newTree(nnkPar)
      for i in 1 ..< def.len:
        let key = def[i][0]
        let val = pragmaNode[i]
        result.add nnkExprColonExpr.newTree(key, val)
  of nnkSym:
    error("The named pragma " & cp.repr & " in " & n.repr & " has no arguments and therefore no value.")
  else:
    error(n.repr & " doesn't have a pragma named " & cp.repr(), n)

when not defined(booting):
  template emit*(e: static[string]): untyped {.deprecated.} =
    ## Accepts a single string argument and treats it as nim code
    ## that should be inserted verbatim in the program
    ## Example:
    ##
    ## .. code-block:: nim
    ##   emit("echo " & '"' & "hello world".toUpper & '"')
    ##
    ## Deprecated since version 0.15 since it's so rarely useful.
    macro payload: untyped {.gensym.} =
      result = parseStmt(e)
    payload()

macro unpackVarargs*(callee: untyped; args: varargs[untyped]): untyped =
  result = newCall(callee)
  for i in 0 ..< args.len:
    result.add args[i]

proc getProjectPath*(): string = discard
  ## Returns the path to the currently compiling project.
  ##
  ## This is not to be confused with `system.currentSourcePath <system.html#currentSourcePath.t>`_
  ## which returns the path of the source file containing that template
  ## call.
  ##
  ## For example, assume a ``dir1/foo.nim`` that imports a ``dir2/bar.nim``,
  ## have the ``bar.nim`` print out both ``getProjectPath`` and
  ## ``currentSourcePath`` outputs.
  ##
  ## Now when ``foo.nim`` is compiled, the ``getProjectPath`` from
  ## ``bar.nim`` will return the ``dir1/`` path, while the ``currentSourcePath``
  ## will return the path to the ``bar.nim`` source file.
  ##
  ## Now when ``bar.nim`` is compiled directly, the ``getProjectPath``
  ## will now return the ``dir2/`` path, and the ``currentSourcePath``
  ## will still return the same path, the path to the ``bar.nim`` source
  ## file.
  ##
  ## The path returned by this proc is set at compile time.
  ##
  ## See also:
  ## * `getCurrentDir proc <os.html#getCurrentDir>`_

macro stripDoNode*(arg: untyped): untyped =
  ## for templates that expect multiple blocks of code with the do
  ## notation, this macro will strip the do lambda node to inline the
  ## body.
  if arg.kind == nnkDo:
    expectLen(arg[3], 1)
    expectKind(arg[3][0], nnkEmpty)
    result = arg[6]
  else:
    result = arg


when defined(nimMacrosSizealignof):
  proc getSize*(arg: NimNode): int {.magic: "NSizeOf", noSideEffect.} =
    ## Returns the same result as ``system.sizeof`` if the size is
    ## known by the Nim compiler. Returns a negative value if the Nim
    ## compiler does not know the size.
  proc getAlign*(arg: NimNode): int {.magic: "NSizeOf", noSideEffect.} =
    ## Returns the same result as ``system.alignof`` if the alignment
    ## is known by the Nim compiler. It works on ``NimNode`` for use
    ## in macro context. Returns a negative value if the Nim compiler
    ## does not know the alignment.
  proc getOffset*(arg: NimNode): int {.magic: "NSizeOf", noSideEffect.} =
    ## Returns the same result as ``system.offsetof`` if the offset is
    ## known by the Nim compiler. It expects a resolved symbol node
    ## from a field of a type. Therefore it only requires one argument
    ## instead of two. Returns a negative value if the Nim compiler
    ## does not know the offset.

proc isExported*(n: NimNode): bool {.noSideEffect.} =
  ## Returns whether the symbol is exported or not.
