import 
  sqlite3, 
  db_sqlite as db, 
  strutils, 
  os,
  oids,
  times,
  json,
  pegs, 
  strtabs,
  base64
import
  lib/types,
  lib/utils, 
  lib/core,
  lib/cli,
  lib/server

from asyncdispatch import runForever

{.compile: "vendor/sqlite/libsqlite3.c".}
{.passC: "-DSQLITE_ENABLE_FTS3 -DSQLITE_ENABLE_FTS3_PARENTHESIS".}

when isMainModule:
  # Initialize Datastore
  if not LS.file.fileExists:
    try:
      LS.file.createDatastore()
    except:
      fail(200, "Unable to create datastore '$1'" % [LS.file])
  try:
    LS.store = LS.file.openDatastore()
  except:
    fail(201, "Unable to open datastore '$1'" % [LS.file])
  case LS.operation:
    of opImport:
      LS.store.importDir(LS.directory)
    of opExport:
      LS.store.exportDir(LS.directory, LS.purge)
    of opRun:
      # STARTTEST
      LS.file.destroyDatastore()
      LS.file.createDatastore()
      LS.store = LS.file.openDatastore()
      LS.store.importDir("nimcache")
      LS.store.importDir("lib")
      # ENDTEST
      LS.serve
      runForever()
