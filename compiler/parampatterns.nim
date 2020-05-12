#
#
#           The Nim Compiler
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module used to implement ast based overloading features.

import ast, types, renderer, trees

type
  TSideEffectAnalysis* = enum
    seUnknown, seSideEffect, seNoSideEffect

proc checkForSideEffects*(n: PNode): TSideEffectAnalysis =
  case n.kind
  of nkCallKinds:
    # only calls can produce side effects:
    let op = n[0]
    if op.kind == nkSym and isRoutine(op.sym):
      let s = op.sym
      if sfSideEffect in s.flags:
        return seSideEffect
      # assume no side effect:
      result = seNoSideEffect
    elif tfNoSideEffect in op.typ.flags:
      # indirect call without side effects:
      result = seNoSideEffect
    else:
      # indirect call: assume side effect:
      return seSideEffect
    # we need to check n[0] too: (FwithSideEffectButReturnsProcWithout)(args)
    for i in 0..<n.len:
      let ret = checkForSideEffects(n[i])
      if ret == seSideEffect: return ret
      elif ret == seUnknown and result == seNoSideEffect:
        result = seUnknown
  of nkNone .. nkNilLit:
    # an atom cannot produce a side effect:
    result = seNoSideEffect
  else:
    # assume no side effect:
    result = seNoSideEffect
    for i in 0..<n.len:
      let ret = checkForSideEffects(n[i])
      if ret == seSideEffect: return ret
      elif ret == seUnknown and result == seNoSideEffect:
        result = seUnknown

type
  TAssignableResult* = enum
    arNone,                   # no l-value and no discriminant
    arLValue,                 # is an l-value
    arLocalLValue,            # is an l-value, but local var; must not escape
                              # its stack frame!
    arDiscriminant,           # is a discriminant
    arStrange                 # it is a strange beast like 'typedesc[var T]'

proc exprRoot*(n: PNode): PSym =
  var it = n
  while true:
    case it.kind
    of nkSym: return it.sym
    of nkHiddenDeref, nkDerefExpr:
      if it[0].typ.skipTypes(abstractInst).kind in {tyPtr, tyRef}:
        # 'ptr' is unsafe anyway and 'ref' is always on the heap,
        # so allow these derefs:
        break
      else:
        it = it[0]
    of nkDotExpr, nkBracketExpr, nkHiddenAddr,
       nkObjUpConv, nkObjDownConv, nkCheckedFieldExpr:
      it = it[0]
    of nkHiddenStdConv, nkHiddenSubConv, nkConv:
      it = it[1]
    of nkStmtList, nkStmtListExpr:
      if it.len > 0 and it.typ != nil: it = it.lastSon
      else: break
    of nkCallKinds:
      if it.typ != nil and it.typ.kind == tyVar and it.len > 1:
        # See RFC #7373, calls returning 'var T' are assumed to
        # return a view into the first argument (if there is one):
        it = it[1]
      else:
        break
    else:
      break

proc isAssignable*(owner: PSym, n: PNode; isUnsafeAddr=false): TAssignableResult =
  ## 'owner' can be nil!
  result = arNone
  case n.kind
  of nkEmpty:
    if n.typ != nil and n.typ.kind == tyVar:
      result = arLValue
  of nkSym:
    let kinds = if isUnsafeAddr: {skVar, skResult, skTemp, skParam, skLet, skForVar}
                else: {skVar, skResult, skTemp}
    if n.sym.kind == skParam and n.sym.typ.kind in {tyVar, tySink}:
      result = arLValue
    elif isUnsafeAddr and n.sym.kind == skParam:
      result = arLValue
    elif n.sym.kind in kinds:
      if owner != nil and owner == n.sym.owner and
          sfGlobal notin n.sym.flags:
        result = arLocalLValue
      else:
        result = arLValue
    elif n.sym.kind == skType:
      let t = n.sym.typ.skipTypes({tyTypeDesc})
      if t.kind == tyVar: result = arStrange
  of nkDotExpr:
    let t = skipTypes(n[0].typ, abstractInst-{tyTypeDesc})
    if t.kind in {tyVar, tySink, tyPtr, tyRef}:
      result = arLValue
    elif isUnsafeAddr and t.kind == tyLent:
      result = arLValue
    else:
      result = isAssignable(owner, n[0], isUnsafeAddr)
    if result != arNone and n[1].kind == nkSym and
        sfDiscriminant in n[1].sym.flags:
      result = arDiscriminant
  of nkBracketExpr:
    let t = skipTypes(n[0].typ, abstractInst-{tyTypeDesc})
    if t.kind in {tyVar, tySink, tyPtr, tyRef}:
      result = arLValue
    elif isUnsafeAddr and t.kind == tyLent:
      result = arLValue
    else:
      result = isAssignable(owner, n[0], isUnsafeAddr)
  of nkHiddenStdConv, nkHiddenSubConv, nkConv:
    # Object and tuple conversions are still addressable, so we skip them
    # XXX why is 'tyOpenArray' allowed here?
    if skipTypes(n.typ, abstractPtrs-{tyTypeDesc}).kind in
        {tyOpenArray, tyTuple, tyObject}:
      result = isAssignable(owner, n[1], isUnsafeAddr)
    elif compareTypes(n.typ, n[1].typ, dcEqIgnoreDistinct):
      # types that are equal modulo distinction preserve l-value:
      result = isAssignable(owner, n[1], isUnsafeAddr)
  of nkHiddenDeref:
    if isUnsafeAddr and n[0].typ.kind == tyLent: result = arLValue
    elif n[0].typ.kind == tyLent: result = arDiscriminant
    else: result = arLValue
  of nkDerefExpr, nkHiddenAddr:
    result = arLValue
  of nkObjUpConv, nkObjDownConv, nkCheckedFieldExpr:
    result = isAssignable(owner, n[0], isUnsafeAddr)
  of nkCallKinds:
    # builtin slice keeps lvalue-ness:
    if getMagic(n) in {mArrGet, mSlice}:
      result = isAssignable(owner, n[1], isUnsafeAddr)
    elif n.typ != nil and n.typ.kind == tyVar:
      result = arLValue
    elif isUnsafeAddr and n.typ != nil and n.typ.kind == tyLent:
      result = arLValue
  of nkStmtList, nkStmtListExpr:
    if n.typ != nil:
      result = isAssignable(owner, n.lastSon, isUnsafeAddr)
  of nkVarTy:
    # XXX: The fact that this is here is a bit of a hack.
    # The goal is to allow the use of checks such as "foo(var T)"
    # within concepts. Semantically, it's not correct to say that
    # nkVarTy denotes an lvalue, but the example above is the only
    # possible code which will get us here
    result = arLValue
  else:
    discard

proc isLValue*(n: PNode): bool =
  isAssignable(nil, n) in {arLValue, arLocalLValue, arStrange}
