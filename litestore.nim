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

# Test
when false:
  var file = "test.ls"
  if file.fileExists:
    file.removeFile
  createDatastore(file)
  var store = file.openDatastore
  var id1 = store.createDocument "This is a test document"
  var id2 = store.createDocument "This is another test document"
  var id3 = store.createDocument "This is yet another test document"
  store.createTag "test1", id1
  store.createTag "test2", id2
  store.createTag "test3", id2
  store.createTag "test", id1
  store.createTag "test", id2
  store.createTag "test", id3
  var opts = newQueryOptions()
  #opts.tags = "test,test2"
  #opts.search = "another yet"
  store.packDir("nimcache")
  "test".createDir
  "test".setCurrentDir
  store.unpackDir("nimcache")
  echo store.destroyDocumentsByTag("$dir:nimcache")
  
when isMainModule:
  # Initialize Datastore
  if not settings.file.fileExists:
    try:
      settings.file.createDatastore()
    except:
      error(1, "Unable to create datastore '$1'" % [settings.file])
  try:
    settings.store = settings.file.openDatastore()
  except:
    error(2, "Unable to open datastore '$1'" % [settings.file])
  case settings.operation:
    of opPack:
      settings.store.packDir(settings.directory)
    of opUnpack:
      settings.store.unpackDir(settings.directory)
    of opRun:
      # STARTTEST
      settings.file.destroyDatastore()
      settings.file.createDatastore()
      settings.store = settings.file.openDatastore()
      settings.store.packDir("nimcache")
      # ENDTEST
      settings.serve
      runForever()
