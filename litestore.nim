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
  types,
  utils, 
  core,
  cli,
  server

from asyncdispatch import runForever

{.compile: "vendor/sqlite/libsqlite3.c".}
{.passC: "-DSQLITE_ENABLE_FTS3 -DSQLITE_ENABLE_FTS3_PARENTHESIS".}

when isMainModule:
  # Initialize Datastore
  if not LS.file.fileExists:
    try:
      LS.file.createDatastore()
    except:
      error(1, "Unable to create datastore '$1'" % [LS.file])
  try:
    LS.store = LS.file.openDatastore()
  except:
    error(2, "Unable to open datastore '$1'" % [LS.file])
  case LS.operation:
    of opPack:
      LS.store.packDir(LS.directory)
    of opUnpack:
      LS.store.unpackDir(LS.directory)
    of opRun:
      # STARTTEST
      LS.file.destroyDatastore()
      LS.file.createDatastore()
      LS.store = LS.file.openDatastore()
      LS.store.packDir("nimcache")
      # ENDTEST
      LS.serve
      runForever()
