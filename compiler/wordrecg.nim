#
#
#           The Nim Compiler
#        (c) Copyright 2015 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# This module contains a word recognizer, i.e. a simple
# procedure which maps special words to an enumeration.
# It is primarily needed because Pascal's case statement
# does not support strings. Without this the code would
# be slow and unreadable.

from strutils import cmpIgnoreStyle

# Keywords must be kept sorted and within a range

type
  TSpecialWord* = enum
    wInvalid,

    wAddr, wAnd, wAs, wAsm,
    wBind, wBlock, wBreak, wCase, wCast, wConcept, wConst,
    wContinue, wConverter, wDefer, wDiscard, wDistinct, wDiv, wDo,
    wElif, wElse, wEnd, wEnum, wExcept, wExport,
    wFinally, wFor, wFrom, wFunc, wIf, wImport, wIn,
    wInclude, wInterface, wIs, wIsnot, wIterator, wLet,
    wMacro, wMethod, wMixin, wMod, wNil,
    wNot, wNotin, wObject, wOf, wOr, wOut, wProc, wPtr, wRaise, wRef, wReturn,
    wShl, wShr, wStatic, wTemplate, wTry, wTuple, wType, wUsing, wVar,
    wWhen, wWhile, wXor, wYield,

    wColon, wColonColon, wEquals, wDot, wDotDot,
    wStar, wMinus,
    wMagic, wThread, wFinal, wProfiler, wMemTracker, wObjChecks,
    wIntDefine, wStrDefine, wBoolDefine, wCursor,

    wImmediate, wConstructor, wDestructor, wDelegator, wOverride,
    wImportCpp, wImportObjC,
    wImportCompilerProc,
    wImportc, wImportJs, wExportc, wExportCpp, wExportNims, wIncompleteStruct, wRequiresInit,
    wAlign, wNodecl, wPure, wSideEffect, wHeader,
    wNoSideEffect, wGcSafe, wNoreturn, wNosinks, wMerge, wLib, wDynlib,
    wCompilerProc, wCore, wProcVar, wBase, wUsed,
    wFatal, wError, wWarning, wHint, wWarningAsError, wLine, wPush, wPop, wDefine, wUndef,
    wLineDir, wStackTrace, wLineTrace, wLink, wCompile,
    wLinksys, wDeprecated, wVarargs, wCallconv, wDebugger,
    wNimcall, wStdcall, wCdecl, wSafecall, wSyscall, wInline, wNoInline,
    wFastcall, wClosure, wNoconv, wOn, wOff, wChecks, wRangeChecks,
    wBoundChecks, wOverflowChecks, wNilChecks,
    wFloatChecks, wNanChecks, wInfChecks, wStyleChecks, wStaticBoundchecks,
    wAssertions, wPatterns, wTrMacros, wSinkInference, wWarnings,
    wHints, wOptimization, wRaises, wWrites, wReads, wSize, wEffects, wTags,
    wRequires, wEnsures, wInvariant, wAssume, wAssert,
    wDeadCodeElimUnused,  # deprecated, dead code elim always happens
    wSafecode, wPackage, wNoForward, wReorder, wNoRewrite, wNoDestroy,
    wPragma,
    wCompileTime, wNoInit,
    wPassc, wPassl, wLocalPassc, wBorrow, wDiscardable,
    wFieldChecks,
    wSubsChar, wAcyclic, wShallow, wUnroll, wLinearScanEnd, wComputedGoto,
    wInjectStmt, wExperimental,
    wWrite, wGensym, wInject, wDirty, wInheritable, wThreadVar, wEmit,
    wAsmNoStackFrame,
    wImplicitStatic, wGlobal, wCodegenDecl, wUnchecked, wGuard, wLocks,
    wExplain,

    wAuto, wBool, wCatch, wChar, wClass, wCompl
    wConst_cast, wDefault, wDelete, wDouble, wDynamic_cast,
    wExplicit, wExtern, wFalse, wFloat, wFriend,
    wGoto, wInt, wLong, wMutable, wNamespace, wNew, wOperator,
    wPrivate, wProtected, wPublic, wRegister, wReinterpret_cast, wRestrict,
    wShort, wSigned, wSizeof, wStatic_cast, wStruct, wSwitch,
    wThis, wThrow, wTrue, wTypedef, wTypeid, wTypeof, wTypename,
    wUnion, wPacked, wUnsigned, wVirtual, wVoid, wVolatile, wWchar_t,

    wAlignas, wAlignof, wConstexpr, wDecltype, wNullptr, wNoexcept,
    wThread_local, wStatic_assert, wChar16_t, wChar32_t,

    wStdIn, wStdOut, wStdErr,

    wInOut, wByCopy, wByRef, wOneWay,
    wBitsize

  TSpecialWords* = set[TSpecialWord]

const
  oprLow* = ord(wColon)
  oprHigh* = ord(wDotDot)

  nimKeywordsLow* = ord(wAsm)
  nimKeywordsHigh* = ord(wYield)

  ccgKeywordsLow* = ord(wAuto)
  ccgKeywordsHigh* = ord(wOneWay)

  cppNimSharedKeywords* = {wAsm, wBreak, wCase, wConst, wContinue, wDo, wElse, wEnum, wExport,
    wFor, wIf, wReturn, wStatic, wTemplate, wTry, wWhile, wUsing}

  specialWords*: array[TSpecialWord, string] = [
    wInvalid:            "",
    wAddr:               "addr",
    wAnd:                "and",
    wAs:                 "as",
    wAsm:                "asm",
    wBind:               "bind",
    wBlock:              "block",
    wBreak:              "break",
    wCase:               "case",
    wCast:               "cast",
    wConcept:            "concept",
    wConst:              "const",
    wContinue:           "continue",
    wConverter:          "converter",
    wDefer:              "defer",
    wDiscard:            "discard",
    wDistinct:           "distinct",
    wDiv:                "div",
    wDo:                 "do",
    wElif:               "elif",
    wElse:               "else",
    wEnd:                "end",
    wEnum:               "enum",
    wExcept:             "except",
    wExport:             "export",
    wFinally:            "finally",
    wFor:                "for",
    wFrom:               "from",
    wFunc:               "func",
    wIf:                 "if",
    wImport:             "import",
    wIn:                 "in",
    wInclude:            "include",
    wInterface:          "interface",
    wIs:                 "is",
    wIsnot:              "isnot",
    wIterator:           "iterator",
    wLet:                "let",
    wMacro:              "macro",
    wMethod:             "method",
    wMixin:              "mixin",
    wMod:                "mod",
    wNil:                "nil",
    wNot:                "not",
    wNotin:              "notin",
    wObject:             "object",
    wOf:                 "of",
    wOr:                 "or",
    wOut:                "out",
    wProc:               "proc",
    wPtr:                "ptr",
    wRaise:              "raise",
    wRef:                "ref",
    wReturn:             "return",
    wShl:                "shl",
    wShr:                "shr",
    wStatic:             "static",
    wTemplate:           "template",
    wTry:                "try",
    wTuple:              "tuple",
    wType:               "type",
    wUsing:              "using",
    wVar:                "var",
    wWhen:               "when",
    wWhile:              "while",
    wXor:                "xor",
    wYield:              "yield",
    wColon:              ":",
    wColonColon:         "::",
    wEquals:             "=",
    wDot:                ".",
    wDotDot:             "..",
    wStar:               "*",
    wMinus:              "-",
    wMagic:              "magic",
    wThread:             "thread",
    wFinal:              "final",
    wProfiler:           "profiler",
    wMemTracker:         "memtracker",
    wObjChecks:          "objchecks",
    wIntDefine:          "intdefine",
    wStrDefine:          "strdefine",
    wBoolDefine:         "booldefine",
    wCursor:             "cursor",
    wImmediate:          "immediate",
    wConstructor:        "constructor",
    wDestructor:         "destructor",
    wDelegator:          "delegator",
    wOverride:           "override",
    wImportCpp:          "importcpp",
    wImportObjC:         "importobjc",
    wImportCompilerProc: "importcompilerproc",
    wImportc:            "importc",
    wImportJs:           "importjs",
    wExportc:            "exportc",
    wExportCpp:          "exportcpp",
    wExportNims:         "exportnims",
    wIncompleteStruct:   "incompletestruct",
    wRequiresInit:       "requiresinit",
    wAlign:              "align",
    wNodecl:             "nodecl",
    wPure:               "pure",
    wSideEffect:         "sideeffect",
    wHeader:             "header",
    wNoSideEffect:       "nosideeffect",
    wGcSafe:             "gcsafe",
    wNoreturn:           "noreturn",
    wNosinks:            "nosinks",
    wMerge:              "merge",
    wLib:                "lib",
    wDynlib:             "dynlib",
    wCompilerProc:       "compilerproc",
    wCore:               "core",
    wProcVar:            "procvar",
    wBase:               "base",
    wUsed:               "used",
    wFatal:              "fatal",
    wError:              "error",
    wWarning:            "warning",
    wHint:               "hint",
    wWarningAsError:     "warningaserror",
    wLine:               "line",
    wPush:               "push",
    wPop:                "pop",
    wDefine:             "define",
    wUndef:              "undef",
    wLineDir:            "linedir",
    wStackTrace:         "stacktrace",
    wLineTrace:          "linetrace",
    wLink:               "link",
    wCompile:            "compile",
    wLinksys:            "linksys",
    wDeprecated:         "deprecated",
    wVarargs:            "varargs",
    wCallconv:           "callconv",
    wDebugger:           "debugger",
    wNimcall:            "nimcall",
    wStdcall:            "stdcall",
    wCdecl:              "cdecl",
    wSafecall:           "safecall",
    wSyscall:            "syscall",
    wInline:             "inline",
    wNoInline:           "noinline",
    wFastcall:           "fastcall",
    wClosure:            "closure",
    wNoconv:             "noconv",
    wOn:                 "on",
    wOff:                "off",
    wChecks:             "checks",
    wRangeChecks:        "rangechecks",
    wBoundChecks:        "boundchecks",
    wOverflowChecks:     "overflowchecks",
    wNilChecks:          "nilchecks",
    wFloatChecks:        "floatchecks",
    wNanChecks:          "nanchecks",
    wInfChecks:          "infchecks",
    wStyleChecks:        "stylechecks",
    wStaticBoundchecks:  "staticboundchecks",
    wAssertions:         "assertions",
    wPatterns:           "patterns",
    wTrMacros:           "trmacros",
    wSinkInference:      "sinkinference",
    wWarnings:           "warnings",
    wHints:              "hints",
    wOptimization:       "optimization",
    wRaises:             "raises",
    wWrites:             "writes",
    wReads:              "reads",
    wSize:               "size",
    wEffects:            "effects",
    wTags:               "tags",
    wRequires:           "requires",
    wEnsures:            "ensures",
    wInvariant:          "invariant",
    wAssume:             "assume",
    wAssert:             "assert",
    wDeadCodeElimUnused: "deadcodeelim",
    wSafecode:           "safecode",
    wPackage:            "package",
    wNoForward:          "noforward",
    wReorder:            "reorder",
    wNoRewrite:          "norewrite",
    wNoDestroy:          "nodestroy",
    wPragma:             "pragma",
    wCompileTime:        "compiletime",
    wNoInit:             "noinit",
    wPassc:              "passc",
    wPassl:              "passl",
    wLocalPassc:         "localpassc",
    wBorrow:             "borrow",
    wDiscardable:        "discardable",
    wFieldChecks:        "fieldchecks",
    wSubsChar:           "subschar",
    wAcyclic:            "acyclic",
    wShallow:            "shallow",
    wUnroll:             "unroll",
    wLinearScanEnd:      "linearscanend",
    wComputedGoto:       "computedgoto",
    wInjectStmt:         "injectstmt",
    wExperimental:       "experimental",
    wWrite:              "write",
    wGensym:             "gensym",
    wInject:             "inject",
    wDirty:              "dirty",
    wInheritable:        "inheritable",
    wThreadVar:          "threadvar",
    wEmit:               "emit",
    wAsmNoStackFrame:    "asmnostackframe",
    wImplicitStatic:     "implicitstatic",
    wGlobal:             "global",
    wCodegenDecl:        "codegendecl",
    wUnchecked:          "unchecked",
    wGuard:              "guard",
    wLocks:              "locks",
    wExplain:            "explain",
    wAuto:               "auto",
    wBool:               "bool",
    wCatch:              "catch",
    wChar:               "char",
    wClass:              "class",
    wCompl:              "compl",
    wConst_cast:         "const_cast",
    wDefault:            "default",
    wDelete:             "delete",
    wDouble:             "double",
    wDynamic_cast:       "dynamic_cast",
    wExplicit:           "explicit",
    wExtern:             "extern",
    wFalse:              "false",
    wFloat:              "float",
    wFriend:             "friend",
    wGoto:               "goto",
    wInt:                "int",
    wLong:               "long",
    wMutable:            "mutable",
    wNamespace:          "namespace",
    wNew:                "new",
    wOperator:           "operator",
    wPrivate:            "private",
    wProtected:          "protected",
    wPublic:             "public",
    wRegister:           "register",
    wReinterpret_cast:   "reinterpret_cast",
    wRestrict:           "restrict",
    wShort:              "short",
    wSigned:             "signed",
    wSizeof:             "sizeof",
    wStatic_cast:        "static_cast",
    wStruct:             "struct",
    wSwitch:             "switch",
    wThis:               "this",
    wThrow:              "throw",
    wTrue:               "true",
    wTypedef:            "typedef",
    wTypeid:             "typeid",
    wTypeof:             "typeof",
    wTypename:           "typename",
    wUnion:              "union",
    wPacked:             "packed",
    wUnsigned:           "unsigned",
    wVirtual:            "virtual",
    wVoid:               "void",
    wVolatile:           "volatile",
    wWchar_t:            "wchar_t",
    wAlignas:            "alignas",
    wAlignof:            "alignof",
    wConstexpr:          "constexpr",
    wDecltype:           "decltype",
    wNullptr:            "nullptr",
    wNoexcept:           "noexcept",
    wThread_local:       "thread_local",
    wStatic_assert:      "static_assert",
    wChar16_t:           "char16_t",
    wChar32_t:           "char32_t",
    wStdIn:              "stdin",
    wStdOut:             "stdout",
    wStdErr:             "stderr",
    wInOut:              "inout",
    wByCopy:             "bycopy",
    wByRef:              "byref",
    wOneWay:             "oneway",
    wBitsize:            "bitsize"
  ]

proc findStr*(a: openArray[string], s: string): int =
  for i in low(a)..high(a):
    if cmpIgnoreStyle(a[i], s) == 0:
      return i
  result = - 1

proc canonPragmaSpelling*(w: TSpecialWord): string =
  case w
  of wNoSideEffect: "noSideEffect"
  of wImportCompilerProc: "importCompilerProc"
  of wIncompleteStruct: "incompleteStruct"
  of wRequiresInit: "requiresInit"
  of wSideEffect: "sideEffect"
  of wLineDir: "lineDir"
  of wStackTrace: "stackTrace"
  of wLineTrace: "lineTrace"
  of wRangeChecks: "rangeChecks"
  of wBoundChecks: "boundChecks"
  of wOverflowChecks: "overflowChecks"
  of wNilChecks: "nilChecks"
  of wFloatChecks: "floatChecks"
  of wNanChecks: "nanChecks"
  of wInfChecks: "infChecks"
  of wStyleChecks: "styleChecks"
  of wDeadCodeElimUnused: "deadCodeElim"
  of wCompileTime: "compileTime"
  of wFieldChecks: "fieldChecks"
  of wLinearScanEnd: "linearScanEnd"
  of wComputedGoto: "computedGoto"
  of wInjectStmt: "injectStmt"
  of wAsmNoStackFrame: "asmNoStackFrame"
  of wImplicitStatic: "implicitStatic"
  of wCodegenDecl: "codegenDecl"
  of wLocalPassc: "localPassc"
  of wWarningAsError: "warningAsError"
  else: specialWords[w]
