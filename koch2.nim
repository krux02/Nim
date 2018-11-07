
proc help(): int =
  ## shows this help and quits
  echo "some help"

type
  BootOption {.pure.} = enum
    optLatest ## bundle the installers with a bleeding edge Nimble
    optStable ## bundle the installers with a stable Nimble

  BootFlags {.pure.} = enum
    release  ## produce a release version of the compiler
    useLinenoise ## use the linenoise library for interactive mode (not needed on Windows)

proc boot(option BootOption): int =
  ## bootstraps with given command line options
  echo "booting ..."
  return 0


proc distrohelper(bindir: string): int =
  ## helper for distro packagers


proc tools(): int =
  ## builds Nim related tools

proc nimble(): int =
  ## builds the Nimble tool

proc docs(options: varargs[string]): int =
  ## generates the full documentation

proc csource(): int =
  ## builds the C sources for installation

proc pdf(): int =
  ## builds the PDF documentation

proc zip(): int =
  ## builds the installation zip package

proc xz(): int =
  ## builds the installation tar.xz package

proc testinstall(): int =
  ## test tar.xz package; Unix only!

proc tests(): int =
  ## run the testsuite (run a subset of tests by specifying a category, e.g. `tests cat async`)

proc temp(options: varargs[string]): int =
  ## creates a temporary compiler for testing


proc pushcsource(): int =
  ## push generated C sources to its repo




##  --googleAnalytics:UA-... add the given google analytics code to the docs. To
##                           build the official docs, use UA-48159761-1


#[
type
  Command {.pure.} = enum
    boot
    distrohelper
    tools
    nimble

  Argument = object

+-----------------------------------------------------------------+
|         Maintenance program for Nim                             |
|             Version 0.19.1                                      |
|             (c) 2017 Andreas Rumpf                              |
+-----------------------------------------------------------------+
Build time: 2018-10-23, 13:32:40

Usage:
  koch [options] command [options for command]
Options:
  --help, -h
  --latest
  --stable
Possible Commands:
  boot [options]
  distrohelper [bindir]
  tools
  nimble
Boot options:
  -d:release
  -d:useLinenoise

Commands for core developers:
  docs
  csource -d:release
  pdf
  zip
  xz
  testinstall
  tests

  temp options
  pushcsource
Web options:
]#
