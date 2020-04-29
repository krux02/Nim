discard """
targets: "cpp"
output: '''
test1
xest1
5
'''
"""
{.passC: "-std=c++14".}

import macros

type
  stdString {.importcpp: "std::string", header: "<string>".} = object
  stdUniquePtr[T] {.importcpp: "std::unique_ptr", header: "<memory>".} = object

proc c_str(a: stdString): cstring {.importcpp: "(char *)(#.c_str())", header: "<string>".}

proc length(a: stdString): csize_t {.importcpp: "(#.length())", header: "<string>".}

proc len(a: stdString): int = cast[int](a.length)

proc setChar(a: var stdString, i: csize_t, c: char) {.importcpp: "(#[#] = #)", header: "<string>".}

proc `*`*[T](this: stdUniquePtr[T]): var T {.noSideEffect, importcpp: "(* #)", header: "<memory>".}

proc make_unique_str(a: cstring): stdUniquePtr[stdString] {.importcpp: "std::make_unique<std::string>(#)", header: "<string>".}

macro `->`*[T](this: stdUniquePtr[T], call: untyped): untyped =
  if call.kind == nnkIdent:
    result = newDotExpr(prefix(this, "*"), call)
  else:
    call.expectKind nnkCall
    result = newCall(newDotExpr(prefix(this, "*"), call[0]))
    for i in 1 ..< call.len:
      result.add call[i]

var val = make_unique_str("test1")
echo val->c_str()
val->setChar(0, 'x')
echo val->c_str()
echo val->len
