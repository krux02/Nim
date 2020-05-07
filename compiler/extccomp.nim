#
#
#           The Nim Compiler
#        (c) Copyright 2013 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# Module providing functions for calling the different external C compilers
# Uses some hard-wired facts about each C/C++ compiler, plus options read
# from a lineinfos file, to provide generalized procedures to compile
# nim files.

import
  ropes, os, strutils, osproc, platform, condsyms, options, msgs,
  lineinfos, std / sha1, streams, pathutils, times, strtabs

type
  TInfoCCProp* = enum         ## properties of the C compiler:
    hasSwitchRange,           ## CC allows ranges in switch statements (GNU C)
    hasComputedGoto,          ## CC has computed goto (GNU C extension)
    hasCpp,                   ## CC is/contains a C++ compiler
    hasAssume,                ## CC has __assume (Visual C extension)
    hasGcGuard,               ## CC supports GC_GUARD to keep stack roots
    hasGnuAsm,                ## CC's asm uses the absurd GNU assembler syntax
    hasDeclspec,              ## CC has __declspec(X)
    hasAttribute,             ## CC has __attribute__((X))
  TInfoCCProps* = set[TInfoCCProp]
  TInfoCC* = object
    name*: string          ## the short name of the compiler
    objExt*: string        ## the compiler's object file extension
    optSpeed*: string      ## the options for optimization for speed
    optSize*: string       ## the options for optimization for size
    compilerExe*: string   ## the compiler's executable
    cppCompiler*: string   ## name of the C++ compiler's executable (if supported)
    compileTmpl*: string   ## the compile command template
    buildGui*: string      ## command to build a GUI application
    buildDll*: string      ## command to build a shared library
    buildLib*: string      ## command to build a static library
    linkerExe*: string     ## the linker's executable (if not matching compiler's)
    linkTmpl*: string      ## command to link files to produce an exe
    includeCmd*: string    ## command to add an include dir
    linkDirCmd*: string    ## command to add a lib dir
    linkLibCmd*: string    ## command to link an external library
    debug*: string         ## flags for debug build
    pic*: string           ## command for position independent code
                           ## used on some platforms
    asmStmtFrmt*: string   ## format of ASM statement
    structStmtFmt*: string ## Format for struct statement
    produceAsm*: string    ## Format how to produce assembler listings
    cppXsupport*: string   ## what to do to enable C++X support
    props*: TInfoCCProps   ## properties of the C compiler


# Configuration settings for various compilers.
# When adding new compilers, the cmake sources could be a good reference:
# http://cmake.org/gitweb?p=cmake.git;a=tree;f=Modules/Platform;

template compiler(name, settings: untyped): untyped =
  proc name: TInfoCC {.compileTime.} = settings

const
  gnuAsmListing = "-Wa,-acdl=$asmfile -g -fverbose-asm -masm=intel"

# GNU C and C++ Compiler
compiler gcc:
  result.name = "gcc"
  result.objExt = "o"
  result.optSpeed = " -O3 -fno-ident"
  result.optSize = " -Os -fno-ident"
  result.compilerExe = "gcc"
  result.cppCompiler = "g++"
  result.compileTmpl = "-c $options $include -o $objfile $file"
  result.buildGui = " -mwindows"
  result.buildDll = " -shared"
  result.buildLib = "ar rcs $libfile $objfiles"
  result.linkerExe = ""
  result.linkTmpl = "$buildgui $builddll -o $exefile $objfiles $options"
  result.includeCmd = " -I"
  result.linkDirCmd = " -L"
  result.linkLibCmd = " -l$1"
  result.debug = ""
  result.pic = "-fPIC"
  result.asmStmtFrmt = "asm($1);$n"
  result.structStmtFmt = "$1 $3 $2 " # struct|union [packed] $name
  result.produceAsm = gnuAsmListing
  result.cppXsupport = "-std=gnu++14 -funsigned-char"
  result.props = {hasSwitchRange, hasComputedGoto, hasCpp, hasGcGuard,
                   hasGnuAsm, hasAttribute}

# GNU C and C++ Compiler
compiler nintendoSwitchGCC:
  result.name = "switch_gcc"
  result.objExt = "o"
  result.optSpeed = " -O3 "
  result.optSize = " -Os "
  result.compilerExe = "aarch64-none-elf-gcc"
  result.cppCompiler = "aarch64-none-elf-g++"
  result.compileTmpl = "-w -MMD -MP -MF $dfile -c $options $include -o $objfile $file"
  result.buildGui = " -mwindows"
  result.buildDll = " -shared"
  result.buildLib = "aarch64-none-elf-gcc-ar rcs $libfile $objfiles"
  result.linkerExe = "aarch64-none-elf-gcc"
  result.linkTmpl = "$buildgui $builddll -Wl,-Map,$mapfile -o $exefile $objfiles $options"
  result.includeCmd = " -I"
  result.linkDirCmd = " -L"
  result.linkLibCmd = " -l$1"
  result.debug = ""
  result.pic = "-fPIE"
  result.asmStmtFrmt = "asm($1);$n"
  result.structStmtFmt = "$1 $3 $2 " # struct|union [packed] $name
  result.produceAsm = gnuAsmListing
  result.cppXsupport = "-std=gnu++14 -funsigned-char"
  result.props = {hasSwitchRange, hasComputedGoto, hasCpp, hasGcGuard,
                   hasGnuAsm, hasAttribute}

# LLVM Frontend for GCC/G++
compiler llvmGcc:
  result = gcc() # Uses settings from GCC

  result.name = "llvm_gcc"
  result.compilerExe = "llvm-gcc"
  result.cppCompiler = "llvm-g++"
  when defined(macosx):
    # OS X has no 'llvm-ar' tool:
    result.buildLib = "ar rcs $libfile $objfiles"
  else:
    result.buildLib = "llvm-ar rcs $libfile $objfiles"

# Clang (LLVM) C/C++ Compiler
compiler clang:
  result = llvmGcc() # Uses settings from llvmGcc

  result.name = "clang"
  result.compilerExe = "clang"
  result.cppCompiler = "clang++"

# Zig cc (Clang) C/C++ Compiler
compiler zig:
  result = clang() # Uses settings from llvmGcc

  result.name = "zig"
  result.compilerExe = "zig"
  result.cppCompiler = "zig"
  result.compileTmpl = "cc " & result.compileTmpl
  result.linkTmpl = "cc " & result.linkTmpl

# Microsoft Visual C/C++ Compiler
compiler vcc:
  result.name = "vcc"
  result.objExt = "obj"
  result.optSpeed = " /Ogityb2 "
  result.optSize = " /O1 "
  result.compilerExe = "cl"
  result.cppCompiler = "cl"
  result.compileTmpl = "/c$vccplatform $options $include /Fo$objfile $file"
  result.buildGui = " /link /SUBSYSTEM:WINDOWS "
  result.buildDll = " /LD"
  result.buildLib = "lib /OUT:$libfile $objfiles"
  result.linkerExe = "cl"
  result.linkTmpl = "$builddll$vccplatform /Fe$exefile $objfiles $buildgui $options"
  result.includeCmd = " /I"
  result.linkDirCmd = " /LIBPATH:"
  result.linkLibCmd = " $1.lib"
  result.debug = " /RTC1 /Z7 "
  result.pic = ""
  result.asmStmtFrmt = "__asm{$n$1$n}$n"
  result.structStmtFmt = "$3$n$1 $2"
  result.produceAsm = "/Fa$asmfile"
  result.cppXsupport = ""
  result.props = {hasCpp, hasAssume, hasDeclspec}

compiler clangcl:
  result = vcc()
  result.name = "clang_cl"
  result.compilerExe = "clang-cl"
  result.cppCompiler = "clang-cl"
  result.linkerExe = "clang-cl"

# Intel C/C++ Compiler
compiler icl:
  result = vcc()
  result.name = "icl"
  result.compilerExe = "icl"
  result.linkerExe = "icl"

# Intel compilers try to imitate the native ones (gcc and msvc)
compiler icc:
  result = gcc()
  result.name = "icc"
  result.compilerExe = "icc"
  result.linkerExe = "icc"

# Local C Compiler
compiler lcc:
  result.name = "lcc"
  result.objExt = "obj"
  result.optSpeed = " -O -p6 "
  result.optSize = " -O -p6 "
  result.compilerExe = "lcc"
  result.cppCompiler = ""
  result.compileTmpl = "$options $include -Fo$objfile $file"
  result.buildGui = " -subsystem windows"
  result.buildDll = " -dll"
  # result.buildLib = ... not supported yet
  result.linkerExe = "lcclnk"
  result.linkTmpl = "$options $buildgui $builddll -O $exefile $objfiles"
  result.includeCmd = " -I"
  # result.linkDirCmd = ... not supported yet
  # result.linkLibCmd = ... not supported yet
  result.debug = " -g5 "
  result.pic = ""
  result.asmStmtFrmt = "_asm{$n$1$n}$n"
  result.structStmtFmt = "$1 $2"
  result.produceAsm = ""
  result.cppXsupport = ""
  result.props = {}

# Borland C Compiler
compiler bcc:
  result.name = "bcc"
  result.objExt = "obj"
  result.optSpeed = " -O3 -6 "
  result.optSize = " -O1 -6 "
  result.compilerExe = "bcc32c"
  result.cppCompiler = "cpp32c"
  result.compileTmpl = "-c $options $include -o$objfile $file"
  result.buildGui = " -tW"
  result.buildDll = " -tWD"
  result.buildLib = "" # XXX: not supported yet
  result.linkerExe = "bcc32"
  result.linkTmpl = "$options $buildgui $builddll -e$exefile $objfiles"
  result.includeCmd = " -I"
  result.linkDirCmd = "" # XXX: not supported yet
  result.linkLibCmd = "" # XXX: not supported yet
  result.debug = ""
  result.pic = ""
  result.asmStmtFrmt = "__asm{$n$1$n}$n"
  result.structStmtFmt = "$1 $2"
  result.produceAsm = ""
  result.cppXsupport = ""
  result.props = {hasSwitchRange, hasComputedGoto, hasCpp, hasGcGuard,
            hasAttribute}

# Digital Mars C Compiler
compiler dmc:
  result.name = "dmc"
  result.objExt = "obj"
  result.optSpeed = " -ff -o -6 "
  result.optSize = " -ff -o -6 "
  result.compilerExe = "dmc"
  result.cppCompiler = ""
  result.compileTmpl = "-c $options $include -o$objfile $file"
  result.buildGui = " -L/exet:nt/su:windows"
  result.buildDll = " -WD"
  result.buildLib = "" # XXX: not supported yet
  result.linkerExe = "dmc"
  result.linkTmpl = "$options $buildgui $builddll -o$exefile $objfiles"
  result.includeCmd = " -I"
  result.linkDirCmd = "" # XXX: not supported yet
  result.linkLibCmd = "" # XXX: not supported yet
  result.debug = " -g "
  result.pic = ""
  result.asmStmtFrmt = "__asm{$n$1$n}$n"
  result.structStmtFmt = "$3$n$1 $2"
  result.produceAsm = ""
  result.cppXsupport = ""
  result.props = {hasCpp}

# Watcom C Compiler
compiler wcc:
  result.name = "wcc"
  result.objExt = "obj"
  result.optSpeed = " -ox -on -6 -d0 -fp6 -zW "
  result.optSize = ""
  result.compilerExe = "wcl386"
  result.cppCompiler = ""
  result.compileTmpl = "-c $options $include -fo=$objfile $file"
  result.buildGui = " -bw"
  result.buildDll = " -bd"
  result.buildLib = "" # XXX: not supported yet
  result.linkerExe = "wcl386"
  result.linkTmpl = "$options $buildgui $builddll -fe=$exefile $objfiles "
  result.includeCmd = " -i="
  result.linkDirCmd = "" # XXX: not supported yet
  result.linkLibCmd = "" # XXX: not supported yet
  result.debug = " -d2 "
  result.pic = ""
  result.asmStmtFrmt = "__asm{$n$1$n}$n"
  result.structStmtFmt = "$1 $2"
  result.produceAsm = ""
  result.cppXsupport = ""
  result.props = {hasCpp}

# Tiny C Compiler
compiler tcc:
  result.name = "tcc"
  result.objExt = "o"
  result.optSpeed = ""
  result.optSize = ""
  result.compilerExe = "tcc"
  result.cppCompiler = ""
  result.compileTmpl = "-c $options $include -o $objfile $file"
  result.buildGui = "-Wl,-subsystem=gui"
  result.buildDll = " -shared"
  result.buildLib = "" # XXX: not supported yet
  result.linkerExe = "tcc"
  result.linkTmpl = "-o $exefile $options $buildgui $builddll $objfiles"
  result.includeCmd = " -I"
  result.linkDirCmd = "" # XXX: not supported yet
  result.linkLibCmd = "" # XXX: not supported yet
  result.debug = " -g "
  result.pic = ""
  result.asmStmtFrmt = "asm($1);$n"
  result.structStmtFmt = "$1 $2"
  result.produceAsm = gnuAsmListing
  result.cppXsupport = ""
  result.props = {hasSwitchRange, hasComputedGoto, hasGnuAsm}

# Pelles C Compiler
compiler pcc:
  # Pelles C
  result.name = "pcc"
  result.objExt = "obj"
  result.optSpeed = " -Ox "
  result.optSize = " -Os "
  result.compilerExe = "cc"
  result.cppCompiler = ""
  result.compileTmpl = "-c $options $include -Fo$objfile $file"
  result.buildGui = " -SUBSYSTEM:WINDOWS"
  result.buildDll = " -DLL"
  result.buildLib = "" # XXX: not supported yet
  result.linkerExe = "cc"
  result.linkTmpl = "$options $buildgui $builddll -OUT:$exefile $objfiles"
  result.includeCmd = " -I"
  result.linkDirCmd = "" # XXX: not supported yet
  result.linkLibCmd = "" # XXX: not supported yet
  result.debug = " -Zi "
  result.pic = ""
  result.asmStmtFrmt = "__asm{$n$1$n}$n"
  result.structStmtFmt = "$1 $2"
  result.produceAsm = ""
  result.cppXsupport = ""
  result.props = {}

# Your C Compiler
compiler ucc:
  result.name = "ucc"
  result.objExt = "o"
  result.optSpeed = " -O3 "
  result.optSize = " -O1 "
  result.compilerExe = "cc"
  result.cppCompiler = ""
  result.compileTmpl = "-c $options $include -o $objfile $file"
  result.buildGui = ""
  result.buildDll = " -shared "
  result.buildLib = "" # XXX: not supported yet
  result.linkerExe = "cc"
  result.linkTmpl = "-o $exefile $buildgui $builddll $objfiles $options"
  result.includeCmd = " -I"
  result.linkDirCmd = "" # XXX: not supported yet
  result.linkLibCmd = "" # XXX: not supported yet
  result.debug = ""
  result.pic = ""
  result.asmStmtFrmt = "__asm{$n$1$n}$n"
  result.structStmtFmt = "$1 $2"
  result.produceAsm = ""
  result.cppXsupport = ""
  result.props = {}

const
  CC*: array[succ(low(TSystemCC))..high(TSystemCC), TInfoCC] = [
    ccGcc:            gcc(),
    ccNintendoSwitch: nintendoSwitchGCC(),
    ccLLVM_Gcc:       llvmGcc(),
    ccCLang:          clang(),
    ccZig:            zig(),
    ccLcc:            lcc(),
    ccBcc:            bcc(),
    ccDmc:            dmc(),
    ccWcc:            wcc(),
    ccVcc:            vcc(),
    ccTcc:            tcc(),
    ccPcc:            pcc(),
    ccUcc:            ucc(),
    ccIcl:            icl(),
    ccIcc:            icc(),
    ccClangCl:        clangcl()
  ]

  hExt* = ".h"

proc libNameTmpl(conf: ConfigRef): string {.inline.} =
  result = if conf.target.targetOS == osWindows: "$1.lib" else: "lib$1.a"

proc nameToCC*(name: string): TSystemCC =
  ## Returns the kind of compiler referred to by `name`, or ccNone
  ## if the name doesn't refer to any known compiler.
  for i in succ(ccNone)..high(TSystemCC):
    if cmpIgnoreStyle(name, CC[i].name) == 0:
      return i
  result = ccNone

proc listCCnames(): string =
  result = ""
  for i in succ(ccNone)..high(TSystemCC):
    if i > succ(ccNone): result.add ", "
    result.add CC[i].name

proc isVSCompatible*(conf: ConfigRef): bool =
  return conf.cCompiler == ccVcc or
          conf.cCompiler == ccClangCl or
          (conf.cCompiler == ccIcl and conf.target.hostOS in osDos..osWindows)

proc getConfigVar(conf: ConfigRef; c: TSystemCC, suffix: string): string =
  # use ``cpu.os.cc`` for cross compilation, unless ``--compileOnly`` is given
  # for niminst support
  let fullSuffix =
    if conf.cmd == cmdCompileToCpp:
      ".cpp" & suffix
    elif conf.cmd == cmdCompileToOC:
      ".objc" & suffix
    elif conf.cmd == cmdCompileToJS:
      ".js" & suffix
    else:
      suffix

  if (conf.target.hostOS != conf.target.targetOS or conf.target.hostCPU != conf.target.targetCPU) and
      optCompileOnly notin conf.globalOptions:
    let fullCCname = platform.CPU[conf.target.targetCPU].name & '.' &
                     platform.OS[conf.target.targetOS].name & '.' &
                     CC[c].name & fullSuffix
    result = getConfigVar(conf, fullCCname)
    if result.len == 0:
      # not overridden for this cross compilation setting?
      result = getConfigVar(conf, CC[c].name & fullSuffix)
  else:
    result = getConfigVar(conf, CC[c].name & fullSuffix)

proc setCC*(conf: ConfigRef; ccname: string; info: TLineInfo) =
  conf.cCompiler = nameToCC(ccname)
  if conf.cCompiler == ccNone:
    localError(conf, info, "unknown C compiler: '$1'. Available options are: $2" % [ccname, listCCnames()])
  conf.compileOptions = getConfigVar(conf, conf.cCompiler, ".options.always")
  conf.linkOptions = ""
  conf.cCompilerPath = getConfigVar(conf, conf.cCompiler, ".path")
  for i in low(CC)..high(CC): undefSymbol(conf.symbols, CC[i].name)
  defineSymbol(conf.symbols, CC[conf.cCompiler].name)

proc addOpt(dest: var string, src: string) =
  if dest.len == 0 or dest[^1] != ' ': dest.add(" ")
  dest.add(src)

proc addLinkOption*(conf: ConfigRef; option: string) =
  addOpt(conf.linkOptions, option)

proc addCompileOption*(conf: ConfigRef; option: string) =
  if strutils.find(conf.compileOptions, option, 0) < 0:
    addOpt(conf.compileOptions, option)

proc addLinkOptionCmd*(conf: ConfigRef; option: string) =
  addOpt(conf.linkOptionsCmd, option)

proc addCompileOptionCmd*(conf: ConfigRef; option: string) =
  conf.compileOptionsCmd.add(option)

proc initVars*(conf: ConfigRef) =
  # we need to define the symbol here, because ``CC`` may have never been set!
  for i in low(CC)..high(CC): undefSymbol(conf.symbols, CC[i].name)
  defineSymbol(conf.symbols, CC[conf.cCompiler].name)
  addCompileOption(conf, getConfigVar(conf, conf.cCompiler, ".options.always"))
  #addLinkOption(getConfigVar(cCompiler, ".options.linker"))
  if conf.cCompilerPath.len == 0:
    conf.cCompilerPath = getConfigVar(conf, conf.cCompiler, ".path")

proc completeCfilePath*(conf: ConfigRef; cfile: AbsoluteFile,
                        createSubDir: bool = true): AbsoluteFile =
  result = completeGeneratedFilePath(conf, cfile, createSubDir)

proc toObjFile*(conf: ConfigRef; filename: AbsoluteFile): AbsoluteFile =
  # Object file for compilation
  result = AbsoluteFile(filename.string & "." & CC[conf.cCompiler].objExt)

proc addFileToCompile*(conf: ConfigRef; cf: Cfile) =
  conf.toCompile.add(cf)

proc addLocalCompileOption*(conf: ConfigRef; option: string; nimfile: AbsoluteFile) =
  let key = completeCfilePath(conf, withPackageName(conf, nimfile)).string
  var value = conf.cfileSpecificOptions.getOrDefault(key)
  if strutils.find(value, option, 0) < 0:
    addOpt(value, option)
    conf.cfileSpecificOptions[key] = value

proc resetCompilationLists*(conf: ConfigRef) =
  conf.toCompile.setLen 0
  ## XXX: we must associate these with their originating module
  # when the module is loaded/unloaded it adds/removes its items
  # That's because we still need to hash check the external files
  # Maybe we can do that in checkDep on the other hand?
  conf.externalToLink.setLen 0

proc addExternalFileToLink*(conf: ConfigRef; filename: AbsoluteFile) =
  conf.externalToLink.insert(filename.string, 0)

proc execWithEcho(conf: ConfigRef; cmd: string, msg = hintExecuting): int =
  rawMessage(conf, msg, if msg == hintLinking and not(optListCmd in conf.globalOptions or conf.verbosity > 1): "" else: cmd)
  result = execCmd(cmd)

proc execExternalProgram*(conf: ConfigRef; cmd: string, msg = hintExecuting) =
  if execWithEcho(conf, cmd, msg) != 0:
    rawMessage(conf, errGenerated, "execution of an external program failed: '$1'" %
      cmd)

proc generateScript(conf: ConfigRef; script: Rope) =
  let (_, name, _) = splitFile(conf.outFile.string)
  let filename = getNimcacheDir(conf) / RelativeFile(addFileExt("compile_" & name,
                                     platform.OS[conf.target.targetOS].scriptExt))
  if not writeRope(script, filename):
    rawMessage(conf, errGenerated, "could not write to file: " & filename.string)

proc getOptSpeed(conf: ConfigRef; c: TSystemCC): string =
  result = getConfigVar(conf, c, ".options.speed")
  if result == "":
    result = CC[c].optSpeed   # use default settings from this file

proc getDebug(conf: ConfigRef; c: TSystemCC): string =
  result = getConfigVar(conf, c, ".options.debug")
  if result == "":
    result = CC[c].debug      # use default settings from this file

proc getOptSize(conf: ConfigRef; c: TSystemCC): string =
  result = getConfigVar(conf, c, ".options.size")
  if result == "":
    result = CC[c].optSize    # use default settings from this file

proc noAbsolutePaths(conf: ConfigRef): bool {.inline.} =
  # We used to check current OS != specified OS, but this makes no sense
  # really: Cross compilation from Linux to Linux for example is entirely
  # reasonable.
  # `optGenMapping` is included here for niminst.
  result = conf.globalOptions * {optGenScript, optGenMapping} != {}

proc cFileSpecificOptions(conf: ConfigRef; nimname, fullNimFile: string): string =
  result = conf.compileOptions
  addOpt(result, conf.cfileSpecificOptions.getOrDefault(fullNimFile))

  for option in conf.compileOptionsCmd:
    if strutils.find(result, option, 0) < 0:
      addOpt(result, option)

  if optCDebug in conf.globalOptions:
    let key = nimname & ".debug"
    if existsConfigVar(conf, key): addOpt(result, getConfigVar(conf, key))
    else: addOpt(result, getDebug(conf, conf.cCompiler))
  if optOptimizeSpeed in conf.options:
    let key = nimname & ".speed"
    if existsConfigVar(conf, key): addOpt(result, getConfigVar(conf, key))
    else: addOpt(result, getOptSpeed(conf, conf.cCompiler))
  elif optOptimizeSize in conf.options:
    let key = nimname & ".size"
    if existsConfigVar(conf, key): addOpt(result, getConfigVar(conf, key))
    else: addOpt(result, getOptSize(conf, conf.cCompiler))
  let key = nimname & ".always"
  if existsConfigVar(conf, key): addOpt(result, getConfigVar(conf, key))

proc getCompileOptions(conf: ConfigRef): string =
  result = cFileSpecificOptions(conf, "__dummy__", "__dummy__")

proc vccplatform(conf: ConfigRef): string =
  # VCC specific but preferable over the config hacks people
  # had to do before, see #11306
  if conf.cCompiler == ccVcc:
    let exe = getConfigVar(conf, conf.cCompiler, ".exe")
    if "vccexe.exe" == extractFilename(exe):
      result = case conf.target.targetCPU
        of cpuI386: " --platform:x86"
        of cpuArm: " --platform:arm"
        of cpuAmd64: " --platform:amd64"
        else: ""

proc getLinkOptions(conf: ConfigRef): string =
  result = conf.linkOptions & " " & conf.linkOptionsCmd & " "
  for linkedLib in items(conf.cLinkedLibs):
    result.add(CC[conf.cCompiler].linkLibCmd % linkedLib.quoteShell)
  for libDir in items(conf.cLibs):
    result.add(join([CC[conf.cCompiler].linkDirCmd, libDir.quoteShell]))

proc needsExeExt(conf: ConfigRef): bool {.inline.} =
  result = (optGenScript in conf.globalOptions and conf.target.targetOS == osWindows) or
           (conf.target.hostOS == osWindows)

proc useCpp(conf: ConfigRef; cfile: AbsoluteFile): bool =
  conf.cmd == cmdCompileToCpp and not cfile.string.endsWith(".c")

proc getCompilerExe(conf: ConfigRef; compiler: TSystemCC; cfile: AbsoluteFile): string =
  result = if useCpp(conf, cfile):
             CC[compiler].cppCompiler
           else:
             CC[compiler].compilerExe
  if result.len == 0:
    rawMessage(conf, errGenerated,
      "Compiler '$1' doesn't support the requested target" %
      CC[compiler].name)

proc getLinkerExe(conf: ConfigRef; compiler: TSystemCC): string =
  result = if CC[compiler].linkerExe.len > 0: CC[compiler].linkerExe
           elif optMixedMode in conf.globalOptions and conf.cmd != cmdCompileToCpp: CC[compiler].cppCompiler
           else: getCompilerExe(conf, compiler, AbsoluteFile"")

proc getCompileCFileCmd(conf: ConfigRef; cfile: Cfile, produceOutput: bool): string =
  let c = conf.cCompiler
  # We produce files like module.nim.cpp, so the absolute Nim filename is not
  # cfile.name but `cfile.cname.changeFileExt("")`:
  var options = cFileSpecificOptions(conf, cfile.nimname, cfile.cname.changeFileExt("").string)
  if useCpp(conf, cfile.cname):
    # needs to be prepended so that --passc:-std=c++17 can override default.
    # we could avoid allocation by making cFileSpecificOptions inplace
    options = CC[c].cppXsupport & ' ' & options

  var exe = getConfigVar(conf, c, ".exe")
  if exe.len == 0: exe = getCompilerExe(conf, c, cfile.cname)

  if needsExeExt(conf): exe = addFileExt(exe, "exe")
  if (optGenDynLib in conf.globalOptions) and
      ospNeedsPIC in platform.OS[conf.target.targetOS].props:
    options.add(' ' & CC[c].pic)

  var compilePattern: string
  # compute include paths:
  var includeCmd = CC[c].includeCmd & quoteShell(conf.libpath)
  if not noAbsolutePaths(conf):
    for includeDir in items(conf.cIncludes):
      includeCmd.add(join([CC[c].includeCmd, includeDir.quoteShell]))

    compilePattern = joinPath(conf.cCompilerPath, exe)
  else:
    compilePattern = getCompilerExe(conf, c, cfile.cname)

  includeCmd.add(join([CC[c].includeCmd, quoteShell(conf.projectPath.string)]))

  var cf = if noAbsolutePaths(conf): AbsoluteFile extractFilename(cfile.cname.string)
           else: cfile.cname

  var objfile =
    if cfile.obj.isEmpty:
      if CfileFlag.External notin cfile.flags or noAbsolutePaths(conf):
        toObjFile(conf, cf).string
      else:
        completeCfilePath(conf, toObjFile(conf, cf)).string
    elif noAbsolutePaths(conf):
      extractFilename(cfile.obj.string)
    else:
      cfile.obj.string

  # D files are required by nintendo switch libs for
  # compilation. They are basically a list of all includes.
  let dfile = objfile.changeFileExt(".d").quoteShell

  let cfsh = quoteShell(cf)
  result = quoteShell(compilePattern % [
    "dfile", dfile,
    "file", cfsh, "objfile", quoteShell(objfile), "options", options,
    "include", includeCmd, "nim", getPrefixDir(conf).string,
    "lib", conf.libpath.string])

  if optProduceAsm in conf.globalOptions:
    if CC[conf.cCompiler].produceAsm.len > 0:
      let asmfile = objfile.changeFileExt(".asm").quoteShell
      addOpt(result, CC[conf.cCompiler].produceAsm % ["asmfile", asmfile])
      if produceOutput:
        rawMessage(conf, hintUserRaw, "Produced assembler here: " & asmfile)
    else:
      if produceOutput:
        rawMessage(conf, hintUserRaw, "Couldn't produce assembler listing " &
          "for the selected C compiler: " & CC[conf.cCompiler].name)

  result.add(' ')
  result.addf(CC[c].compileTmpl, [
    "dfile", dfile,
    "file", cfsh, "objfile", quoteShell(objfile),
    "options", options, "include", includeCmd,
    "nim", quoteShell(getPrefixDir(conf)),
    "lib", quoteShell(conf.libpath),
    "vccplatform", vccplatform(conf)])

proc getCompileCFileCmd*(conf: ConfigRef; cfile: Cfile): string =
  getCompileCFileCmd(conf, cfile, produceOutput = false)

proc footprint(conf: ConfigRef; cfile: Cfile): SecureHash =
  result = secureHash(
    $secureHashFile(cfile.cname.string) &
    platform.OS[conf.target.targetOS].name &
    platform.CPU[conf.target.targetCPU].name &
    extccomp.CC[conf.cCompiler].name &
    getCompileCFileCmd(conf, cfile))

proc externalFileChanged(conf: ConfigRef; cfile: Cfile): bool =
  if conf.cmd notin {cmdCompileToC, cmdCompileToCpp, cmdCompileToOC, cmdCompileToLLVM, cmdNone}:
    return false

  var hashFile = toGeneratedFile(conf, conf.withPackageName(cfile.cname), "sha1")
  var currentHash = footprint(conf, cfile)
  var f: File
  if open(f, hashFile.string, fmRead):
    let oldHash = parseSecureHash(f.readLine())
    close(f)
    result = oldHash != currentHash
  else:
    result = true
  if result:
    if open(f, hashFile.string, fmWrite):
      f.writeLine($currentHash)
      close(f)

proc addExternalFileToCompile*(conf: ConfigRef; c: var Cfile) =
  if optForceFullMake notin conf.globalOptions and fileExists(c.obj) and
      not externalFileChanged(conf, c):
    c.flags.incl CfileFlag.Cached
  else:
    # make sure Nim keeps recompiling the external file on reruns
    # if compilation is not successful
    discard tryRemoveFile(c.obj.string)
  conf.toCompile.add(c)

proc addExternalFileToCompile*(conf: ConfigRef; filename: AbsoluteFile) =
  var c = Cfile(nimname: splitFile(filename).name, cname: filename,
    obj: toObjFile(conf, completeCfilePath(conf, filename, false)),
    flags: {CfileFlag.External})
  addExternalFileToCompile(conf, c)

proc getLinkCmd(conf: ConfigRef; output: AbsoluteFile,
                objfiles: string, isDllBuild: bool): string =
  if optGenStaticLib in conf.globalOptions:
    var libname: string
    if not conf.outFile.isEmpty:
      libname = conf.outFile.string.expandTilde
      if not libname.isAbsolute():
        libname = getCurrentDir() / libname
    else:
      libname = (libNameTmpl(conf) % splitFile(conf.projectName).name)
    result = CC[conf.cCompiler].buildLib % ["libfile", quoteShell(libname),
                                            "objfiles", objfiles]
  else:
    var linkerExe = getConfigVar(conf, conf.cCompiler, ".linkerexe")
    if linkerExe.len == 0: linkerExe = getLinkerExe(conf, conf.cCompiler)
    # bug #6452: We must not use ``quoteShell`` here for ``linkerExe``
    if needsExeExt(conf): linkerExe = addFileExt(linkerExe, "exe")
    if noAbsolutePaths(conf): result = linkerExe
    else: result = joinPath(conf.cCompilerPath, linkerExe)
    let buildgui = if optGenGuiApp in conf.globalOptions and conf.target.targetOS == osWindows:
                     CC[conf.cCompiler].buildGui
                   else:
                     ""
    let builddll = if isDllBuild: CC[conf.cCompiler].buildDll else: ""
    let exefile = quoteShell(output)

    when false:
      if optCDebug in conf.globalOptions:
        writeDebugInfo(exefile.changeFileExt("ndb"))

    # Map files are required by Nintendo Switch compilation. They are a list
    # of all function calls in the library and where they come from.
    let mapfile = quoteShell(getNimcacheDir(conf) / RelativeFile(splitFile(output).name & ".map"))

    let linkOptions = getLinkOptions(conf) & " " &
                      getConfigVar(conf, conf.cCompiler, ".options.linker")
    var linkTmpl = getConfigVar(conf, conf.cCompiler, ".linkTmpl")
    if linkTmpl.len == 0:
      linkTmpl = CC[conf.cCompiler].linkTmpl
    result = quoteShell(result % ["builddll", builddll,
        "mapfile", mapfile,
        "buildgui", buildgui, "options", linkOptions, "objfiles", objfiles,
        "exefile", exefile, "nim", getPrefixDir(conf).string, "lib", conf.libpath.string])
    result.add ' '
    result.addf(linkTmpl, ["builddll", builddll,
        "mapfile", mapfile,
        "buildgui", buildgui, "options", linkOptions,
        "objfiles", objfiles, "exefile", exefile,
        "nim", quoteShell(getPrefixDir(conf)),
        "lib", quoteShell(conf.libpath),
        "vccplatform", vccplatform(conf)])
  if optCDebug in conf.globalOptions and conf.cCompiler == ccVcc:
    result.add " /Zi /FS /Od"

template getLinkCmd(conf: ConfigRef; output: AbsoluteFile, objfiles: string): string =
  getLinkCmd(conf, output, objfiles, optGenDynLib in conf.globalOptions)

template tryExceptOSErrorMessage(conf: ConfigRef; errorPrefix: string = "", body: untyped) =
  try:
    body
  except OSError:
    let ose = (ref OSError)(getCurrentException())
    if errorPrefix.len > 0:
      rawMessage(conf, errGenerated, errorPrefix & " " & ose.msg & " " & $ose.errorCode)
    else:
      rawMessage(conf, errGenerated, "execution of an external program failed: '$1'" %
        (ose.msg & " " & $ose.errorCode))
    raise

proc execLinkCmd(conf: ConfigRef; linkCmd: string) =
  tryExceptOSErrorMessage(conf, "invocation of external linker program failed."):
    execExternalProgram(conf, linkCmd, hintLinking)

proc maybeRunDsymutil(conf: ConfigRef; exe: AbsoluteFile) =
  when defined(osx):
    if optCDebug notin conf.globalOptions: return
    # if needed, add an option to skip or override location
    let cmd = "dsymutil " & $(exe).quoteShell
    conf.extraCmds.add cmd
    tryExceptOSErrorMessage(conf, "invocation of dsymutil failed."):
      execExternalProgram(conf, cmd, hintExecuting)

proc execCmdsInParallel(conf: ConfigRef; cmds: seq[string]; prettyCb: proc (idx: int)) =
  let runCb = proc (idx: int, p: Process) =
    let exitCode = p.peekExitCode
    if exitCode != 0:
      rawMessage(conf, errGenerated, "execution of an external compiler program '" &
        cmds[idx] & "' failed with exit code: " & $exitCode & "\n\n")
  if conf.numberOfProcessors == 0: conf.numberOfProcessors = countProcessors()
  var res = 0
  if conf.numberOfProcessors <= 1:
    for i in 0..high(cmds):
      tryExceptOSErrorMessage(conf, "invocation of external compiler program failed."):
        res = execWithEcho(conf, cmds[i])
      if res != 0:
        rawMessage(conf, errGenerated, "execution of an external program failed: '$1'" %
          cmds[i])
  else:
    tryExceptOSErrorMessage(conf, "invocation of external compiler program failed."):
      res = execProcesses(cmds, {poStdErrToStdOut, poUsePath, poParentStreams},
                            conf.numberOfProcessors, prettyCb, afterRunEvent=runCb)
  if res != 0:
    if conf.numberOfProcessors <= 1:
      rawMessage(conf, errGenerated, "execution of an external program failed: '$1'" %
        cmds.join())

proc linkViaResponseFile(conf: ConfigRef; cmd: string) =
  # Extracting the linker.exe here is a bit hacky but the best solution
  # given ``buildLib``'s design.
  var i = 0
  var last = 0
  if cmd.len > 0 and cmd[0] == '"':
    inc i
    while i < cmd.len and cmd[i] != '"': inc i
    last = i
    inc i
  else:
    while i < cmd.len and cmd[i] != ' ': inc i
    last = i
  while i < cmd.len and cmd[i] == ' ': inc i
  let linkerArgs = conf.projectName & "_" & "linkerArgs.txt"
  let args = cmd.substr(i)
  # GCC's response files don't support backslashes. Junk.
  if conf.cCompiler == ccGcc or conf.cCompiler == ccCLang:
    writeFile(linkerArgs, args.replace('\\', '/'))
  else:
    writeFile(linkerArgs, args)
  try:
    execLinkCmd(conf, cmd.substr(0, last) & " @" & linkerArgs)
  finally:
    removeFile(linkerArgs)

proc getObjFilePath(conf: ConfigRef, f: Cfile): string =
  if noAbsolutePaths(conf): f.obj.extractFilename
  else: f.obj.string

proc displayProgressCC(conf: ConfigRef, path, compileCmd: string): string =
  if conf.hasHint(hintCC):
    if optListCmd in conf.globalOptions or conf.verbosity > 1:
      result = MsgKindToStr[hintCC] % (demanglePackageName(path.splitFile.name) & ": " & compileCmd)
    else:
      result = MsgKindToStr[hintCC] % demanglePackageName(path.splitFile.name)

proc callCCompiler*(conf: ConfigRef) =
  var
    linkCmd: string
  if conf.globalOptions * {optCompileOnly, optGenScript} == {optCompileOnly}:
    return # speed up that call if only compiling and no script shall be
           # generated
  #var c = cCompiler
  var script: Rope = nil
  var cmds: TStringSeq
  var prettyCmds: TStringSeq
  let prettyCb = proc (idx: int) =
    if prettyCmds[idx].len > 0: echo prettyCmds[idx]

  for it in conf.toCompile.items:
    # call the C compiler for the .c file:
    if CfileFlag.Cached in it.flags: continue
    let compileCmd = getCompileCFileCmd(conf, it, produceOutput=true)
    if optCompileOnly notin conf.globalOptions:
      cmds.add(compileCmd)
      prettyCmds.add displayProgressCC(conf, $it.cname, compileCmd)
    if optGenScript in conf.globalOptions:
      script.add(compileCmd)
      script.add("\n")

  if optCompileOnly notin conf.globalOptions:
    execCmdsInParallel(conf, cmds, prettyCb)
  if optNoLinking notin conf.globalOptions:
    # call the linker:
    var objfiles = ""
    for it in conf.externalToLink:
      let objFile = if noAbsolutePaths(conf): it.extractFilename else: it
      objfiles.add(' ')
      objfiles.add(quoteShell(
          addFileExt(objFile, CC[conf.cCompiler].objExt)))

    for x in conf.toCompile:
      let objFile = if noAbsolutePaths(conf): x.obj.extractFilename else: x.obj.string
      objfiles.add(' ')
      objfiles.add(quoteShell(objFile))
    let mainOutput = if optGenScript notin conf.globalOptions: conf.prepareToWriteOutput
                     else: AbsoluteFile(conf.projectName)
    linkCmd = getLinkCmd(conf, mainOutput, objfiles)
    if optCompileOnly notin conf.globalOptions:
      const MaxCmdLen = when defined(windows): 8_000 else: 32_000
      if linkCmd.len > MaxCmdLen:
        # Windows's command line limit is about 8K (don't laugh...) so C compilers on
        # Windows support a feature where the command line can be passed via ``@linkcmd``
        # to them.
        linkViaResponseFile(conf, linkCmd)
      else:
        execLinkCmd(conf, linkCmd)
      maybeRunDsymutil(conf, mainOutput)
  else:
    linkCmd = ""
  if optGenScript in conf.globalOptions:
    script.add(linkCmd)
    script.add("\n")
    generateScript(conf, script)

#from json import escapeJson
import json, std / sha1

template hashNimExe(): string = $secureHashFile(os.getAppFilename())

proc writeJsonBuildInstructions*(conf: ConfigRef) =
  template lit(x: untyped) = f.write x
  template str(x: untyped) =
    buf.setLen 0
    escapeJson(x, buf)
    f.write buf

  proc cfiles(conf: ConfigRef; f: File; buf: var string; clist: CfileList, isExternal: bool) =
    var comma = false
    for i, it in clist:
      if CfileFlag.Cached in it.flags: continue
      let compileCmd = getCompileCFileCmd(conf, it)
      if comma: lit ",\L" else: comma = true
      lit "["
      str it.cname.string
      lit ", "
      str compileCmd
      lit "]"

  proc linkfiles(conf: ConfigRef; f: File; buf, objfiles: var string; clist: CfileList;
                 llist: seq[string]) =
    var pastStart = false
    for it in llist:
      let objfile = if noAbsolutePaths(conf): it.extractFilename
                    else: it
      let objstr = addFileExt(objfile, CC[conf.cCompiler].objExt)
      objfiles.add(' ')
      objfiles.add(objstr)
      if pastStart: lit ",\L"
      str objstr
      pastStart = true

    for it in clist:
      let objstr = quoteShell(it.obj)
      objfiles.add(' ')
      objfiles.add(objstr)
      if pastStart: lit ",\L"
      str objstr
      pastStart = true
    lit "\L"

  proc depfiles(conf: ConfigRef; f: File; buf: var string) =
    var i = 0
    for it in conf.m.fileInfos:
      let path = it.fullPath.string
      if isAbsolute(path): # TODO: else?
        if i > 0: lit "],\L"
        lit "["
        str path
        lit ", "
        str $secureHashFile(path)
        inc i
    lit "]\L"


  var buf = newStringOfCap(50)

  let jsonFile = conf.getNimcacheDir / RelativeFile(conf.projectName & ".json")

  var f: File
  if open(f, jsonFile.string, fmWrite):
    lit "{\"compile\":[\L"
    cfiles(conf, f, buf, conf.toCompile, false)
    lit "],\L\"link\":[\L"
    var objfiles = ""
    # XXX add every file here that is to link
    linkfiles(conf, f, buf, objfiles, conf.toCompile, conf.externalToLink)

    lit "],\L\"linkcmd\": "
    str getLinkCmd(conf, conf.absOutFile, objfiles)

    lit ",\L\"extraCmds\": "
    lit $(%* conf.extraCmds)

    lit ",\L\"stdinInput\": "
    lit $(%* conf.projectIsStdin)

    if optRun in conf.globalOptions or isDefined(conf, "nimBetterRun"):
      lit ",\L\"cmdline\": "
      str conf.commandLine
      lit ",\L\"depfiles\":[\L"
      depfiles(conf, f, buf)
      lit "],\L\"nimexe\": \L"
      str hashNimExe()
      lit "\L"

    lit "\L}\L"
    close(f)

proc changeDetectedViaJsonBuildInstructions*(conf: ConfigRef; projectfile: AbsoluteFile): bool =
  let jsonFile = toGeneratedFile(conf, projectfile, "json")
  if not fileExists(jsonFile): return true
  if not fileExists(conf.absOutFile): return true
  result = false
  try:
    let data = json.parseFile(jsonFile.string)
    if not data.hasKey("depfiles") or not data.hasKey("cmdline"):
      return true
    let oldCmdLine = data["cmdline"].getStr
    if conf.commandLine != oldCmdLine:
      return true
    if hashNimExe() != data["nimexe"].getStr:
      return true
    if not data.hasKey("stdinInput"): return true
    let stdinInput = data["stdinInput"].getBool
    if conf.projectIsStdin or stdinInput:
      # could optimize by returning false if stdin input was the same,
      # but I'm not sure how to get full stding input
      return true

    let depfilesPairs = data["depfiles"]
    doAssert depfilesPairs.kind == JArray
    for p in depfilesPairs:
      doAssert p.kind == JArray
      # >= 2 for forwards compatibility with potential later .json files:
      doAssert p.len >= 2
      let depFilename = p[0].getStr
      let oldHashValue = p[1].getStr
      let newHashValue = $secureHashFile(depFilename)
      if oldHashValue != newHashValue:
        return true
  except IOError, OSError, ValueError:
    echo "Warning: JSON processing failed: ", getCurrentExceptionMsg()
    result = true

proc runJsonBuildInstructions*(conf: ConfigRef; projectfile: AbsoluteFile) =
  let jsonFile = toGeneratedFile(conf, projectfile, "json")
  try:
    let data = json.parseFile(jsonFile.string)
    let toCompile = data["compile"]
    doAssert toCompile.kind == JArray
    var cmds: TStringSeq
    var prettyCmds: TStringSeq
    let prettyCb = proc (idx: int) =
      if prettyCmds[idx].len > 0: echo prettyCmds[idx]

    for c in toCompile:
      doAssert c.kind == JArray
      doAssert c.len >= 2

      cmds.add(c[1].getStr)
      prettyCmds.add displayProgressCC(conf, c[0].getStr, c[1].getStr)

    execCmdsInParallel(conf, cmds, prettyCb)

    let linkCmd = data["linkcmd"]
    doAssert linkCmd.kind == JString
    execLinkCmd(conf, linkCmd.getStr)
    if data.hasKey("extraCmds"):
      let extraCmds = data["extraCmds"]
      doAssert extraCmds.kind == JArray
      for cmd in extraCmds:
        doAssert cmd.kind == JString, $cmd.kind
        let cmd2 = cmd.getStr
        execExternalProgram(conf, cmd2, hintExecuting)

  except:
    let e = getCurrentException()
    quit "\ncaught exception:\n" & e.msg & "\nstacktrace:\n" & e.getStackTrace() &
         "error evaluating JSON file: " & jsonFile.string

proc genMappingFiles(conf: ConfigRef; list: CfileList): Rope =
  for it in list:
    result.addf("--file:r\"$1\"$N", [rope(it.cname.string)])

proc writeMapping*(conf: ConfigRef; symbolMapping: Rope) =
  if optGenMapping notin conf.globalOptions: return
  var code = rope("[C_Files]\n")
  code.add(genMappingFiles(conf, conf.toCompile))
  code.add("\n[C_Compiler]\nFlags=")
  code.add(strutils.escape(getCompileOptions(conf)))

  code.add("\n[Linker]\nFlags=")
  code.add(strutils.escape(getLinkOptions(conf) & " " &
                            getConfigVar(conf, conf.cCompiler, ".options.linker")))

  code.add("\n[Environment]\nlibpath=")
  code.add(strutils.escape(conf.libpath.string))

  code.addf("\n[Symbols]$n$1", [symbolMapping])
  let filename = conf.projectPath / RelativeFile"mapping.txt"
  if not writeRope(code, filename):
    rawMessage(conf, errGenerated, "could not write to file: " & filename.string)
