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

from asyncdispatch import runForever

{.compile: "vendor/sqlite/libsqlite3.c".}
{.passC: "-DSQLITE_ENABLE_FTS3=1 -DSQLITE_ENABLE_FTS3_PARENTHESIS".}

when isMainModule:

  # Initialize Datastore
  if not LS.file.fileExists:
    try:
      LOG.debug("Creating datastore: ", LS.file)
      LS.file.createDatastore()
    except:
      eWarn()
      fail(200, "Unable to create datastore '$1'" % [LS.file])

  # Manage vacuum operation separately
  if LS.operation == opVacuum:
    vacuum LS.file

  # Open Datastore and execute operation
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

