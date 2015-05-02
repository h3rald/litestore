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
  lib/queries,
  lib/server

from asyncdispatch import runForever

{.compile: "vendor/sqlite/libsqlite3.c".}
{.passC: "-DSQLITE_ENABLE_FTS4=1 -DSQLITE_ENABLE_LOCKING_STYLE=1".}

when isMainModule:
  # Initialize Datastore
  if not LS.file.fileExists:
    try:
      info("Creating datastore: ", LS.file)
      LS.file.createDatastore()
    except:
      fail(200, "Unable to create datastore '$1'" % [LS.file])
  # Manage vacuum operation separately
  if LS.operation == opVacuum:
    let data = db.open(LS.file, "", "", "")
    try:
      data.exec(SQL_VACUUM)
      db.close(data)
    except:
      eWarn()
      quit(203)
    quit(0)
  # Open Datastore and execute operation
  try:
    LS.store = LS.file.openDatastore()
    if LS.mount:
      try:
        LS.store.mountDir(LS.directory, LS.reset)
      except:
        echo(getCurrentExceptionMsg())
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

