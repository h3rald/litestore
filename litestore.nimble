import
  strutils

from os import parentDir, `/`

template thisModuleFile: string = instantiationInfo(fullPaths = true).filename

when fileExists(thisModuleFile.parentDir / "src/litestorepkg/lib/config.nim"):
  # In the git repository the Nimble sources are in a ``src`` directory.
  import src/litestorepkg/lib/config
else:
  # When the package is installed, the ``src`` directory disappears.
  import litestorepkg/lib/config

# Package

version       = pkgVersion
author        = pkgAuthor
description   = pkgDescription
license       = pkgLicense
bin           = @[pkgName]
srcDir        = "src"
skipDirs      = @["test"]
installExt    = @["nim", "c", "h", "json", "ico"]

# Dependencies

requires "nim >= 1.0.0"

# Build

const
  parallel = "" #"--parallelBuild:1 --verbosity:3"
  compile = "nim c -d:release --threads:on" & " " & parallel
  linux_x64 = "--cpu:amd64 --os:linux"
  windows_x64 = "--cpu:amd64 --os:windows"
  macosx_x64 = ""
  ls = "litestore"
  doc = "LiteStore_UserGuide.htm"
  db = "data.db"
  ls_file = "litestore.nim"
  zip = "zip -X"

proc shell(command, args = "", dest = "") =
  exec command & " " & args & " " & dest

proc filename_for(os: string, arch: string): string =
  return "litestore" & "_v" & version & "_" & os & "_" & arch & ".zip"

task windows_x64_build, "Build LiteStore for Windows (x64)":
  shell compile, windows_x64, ls_file

task linux_x64_build, "Build LiteStore for Linux (x64)":
  shell compile, linux_x64,  ls_file
  
task macosx_x64_build, "Build LiteStore for Mac OS X (x64)":
  shell compile, macosx_x64, ls_file

task release, "Release LiteStore":
  echo "Generating Guide..."
  shell "./build_guide"
  echo "Preparing Data Store preloaded with Admin App..."
  cd "src"
  if db.existsFile:
    db.rmFile
  shell "litestore -d:admin import"
  echo "\n\n\n WINDOWS - x64:\n\n"
  windows_x64_buildTask()
  shell zip, "$1 $2 $3 $4" % [filename_for("windows", "x64"), ls & ".exe", doc, db]
  shell "rm", ls & ".exe"
  echo "\n\n\n LINUX - x64:\n\n"
  linux_x64_buildTask()
  shell zip, "$1 $2 $3 $4" % [filename_for("linux", "x64"), ls, doc, db]
  shell "rm", ls 
  echo "\n\n\n MAC OS X - x64:\n\n"
  macosx_x64_buildTask()
  shell zip, "$1 $2 $3 $4" % [filename_for("macosx", "x64"), ls, doc, db]
  shell "rm", ls 
  echo "\n\n\n ALL DONE!"
