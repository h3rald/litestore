import 
  lib/x_sqlite3, 
  lib/x_db_sqlite as db, 
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
  lib/logger,
  lib/utils, 
  lib/core,
  lib/cli,
  lib/server

export
  server,
  types,
  core,
  server

from asyncdispatch import runForever

{.compile: "vendor/sqlite/libsqlite3.c".}
{.passC: "-DSQLITE_ENABLE_FTS3=1 -DSQLITE_ENABLE_FTS3_PARENTHESIS -DSQLITE_ENABLE_JSON1".}

proc init*(LS: var LiteStore, open = true) =
  if not LS.file.fileExists:
    try:
      LOG.debug("Creating datastore: ", LS.file)
      LS.file.createDatastore()
    except:
      eWarn()
      fail(200, "Unable to create datastore '$1'" % [LS.file])
  if (open):
    try:
      LS.store = LS.file.openDatastore()
      if LS.mount:
        try:
          LS.store.mountDir(LS.directory)
        except:
          eWarn()
          fail(202, "Unable to mount directory '$1'" % [LS.directory])
    except:
      fail(201, "Unable to open datastore '$1'" % [LS.file])

when isMainModule:

  # Initialize Datastore
  LS.init()

  # Manage vacuum operation separately
  if LS.operation == opVacuum:
    LS.init(false)
    vacuum LS.file
  else:
    # Open Datastore 
    LS.init(true)

  case LS.operation:
    of opRun:
      LS.serve
      runForever()
    of opImport:
      LS.store.importDir(LS.directory)
    of opExport:
      LS.store.exportDir(LS.directory)
    of opDelete:
      LS.store.deleteDir(LS.directory)
    of opOptimize:
      LS.store.optimize
    else:
      discard

