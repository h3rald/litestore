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
  base64,
  logging
import
  lib/types,
  lib/utils, 
  lib/core,
  lib/cli,
  lib/server

from asyncdispatch import runForever

{.compile: "vendor/sqlite/libsqlite3.c".}
{.passC: "-DSQLITE_OMIT_LOAD_EXTENSION=1 -DSQLITE_ENABLE_FTS4=1 -DSQLITE_ENABLE_LOCKING_STYLE=0 -DSQLITE_THREADSAFE=0".}

when isMainModule:
  # Initialize Datastore
  if not LS.file.fileExists:
    try:
      LS.file.createDatastore()
    except:
      fail(200, "Unable to create datastore '$1'" % [LS.file])
  try:
    LS.store = LS.file.openDatastore()
    if LS.mirror:
      try:
        LS.store.mountDir(LS.directory)
      except:
        echo(getCurrentExceptionMsg())
        fail(202, "Unable to mount directory '$1'" % [LS.directory])
  except:
    fail(201, "Unable to open datastore '$1'" % [LS.file])
  case LS.operation:
    of opImport:
      LS.store.importDir(LS.directory)
    of opExport:
      LS.store.exportDir(LS.directory)
    of opDelete:
      LS.store.deleteDir(LS.directory)
    of opRun:
      LS.serve
      runForever()
