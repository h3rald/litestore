import 
  sqlite3, 
  db_sqlite as db, 
  strutils, 
  os

{.compile: "vendor/sqlite/libsqlite3.c".}
{.passC: "-DSQLITE_ENABLE_FTS3 -DSQLITE_ENABLE_FTS3_PARENTHESIS".}


type 
  EDatastoreExists* = object of Exception
  EDatastoreDoesNotExist* = object of Exception
  EDatastoreUnavailable* = object of Exception
  Datastore* = object
    db: TDbConn
    path: string
    name: string
  QueryOptions* = object
    count*: bool
    limit*: int
    orderby*: seq[string]
    tags*: seq[string]
    search*: string
    select*: seq[string]
    raw*: bool

# TODO manage stores directory
let cwd = getCurrentDir()

const DOCUMENTS_TABLE = sql"""
CREATE TABLE documents (
key TEXT PRIMARY KEY,
bvalue BLOB,
tvalue TEXT,
mimetype TEXT,
created TEXT,
modified TEXT)
"""

const SEARCHINDEX_TABLE = sql"""
CREATE VIRTUAL TABLE searchindex USING fts4(
key TEXT REFERENCES documents (key) ON DELETE CASCADE,
content TEXT)
"""

const TAGS_TABLE = sql"""
CREATE TABLE tags (
tag TEXT,
key TEXT REFERENCES documents (key) ON DELETE CASCADE,
PRIMARY KEY (tag, key))
"""

# Manage Datastores

proc createDatastore*(name:string) = 
  if name.changeFileExt("ls").fileExists:
    raise newException(EDatastoreExists, "Datastore '$1' already exists." % name)
  let store = db.open(cwd.joinPath(name.changeFileExt("ls")), "", "", "")
  store.exec(DOCUMENTS_TABLE)
  store.exec(SEARCHINDEX_TABLE)
  store.exec(TAGS_TABLE)

proc deleteDatastore*(name:string) =
  try:
    cwd.joinPath(name.changeFileExt("ls")).removeFile
  except:
    raise newException(EDatastoreUnavailable, "Datastore '$1' cannot deleted." % name)

proc openDatastore(name:string): Datastore =
  if not name.fileExists:
    raise newException(EDatastoreDoesNotExist, "Datastore '$1' does not exists." % name)
  try:
    result.db = db.open(cwd.joinPath(name.changeFileExt("ls")), "", "", "")
    result.name = name
    result.path = cwd.joinPath(name)
  except:
    raise newException(EDatastoreUnavailable, "Datastore '$1' cannot be opened." % name)

proc closeDatastore(store:Datastore) = 
  try:
    db.close(store.db)
  except:
    raise newException(EDatastoreUnavailable, "Datastore '$1' cannot be closed." % store.name)

proc retrieveDatastores*(): seq[string] =
  result = newSeq[string](0)
  for f in walkFiles(cwd.joinPath("*.ls")):
    result.add f.extractFilename.changeFileExt("")

# TODO Implement
proc createDocument*(store: Datastore, value: string, content = "", mimetype = "text/plain") =
  discard

proc updateDocument*(store: Datastore, key: string, value: string, content = "", mimetype = "text/plain") =
  discard

proc deleteDocument*(store: Datastore, key: string) =
  discard

proc retrieveDocument*(store: Datastore, key: string, options: QueryOptions = QueryOptions()) =
  discard

proc retrieveDocuments*(store: Datastore, options: QueryOptions = QueryOptions()) =
  discard

proc createTag*(store: Datastore, tag, key: string) =
  discard

proc deleteTag*(store: Datastore, tag, key: string) =
  discard

proc retrieveTags*(store: Datastore, options: QueryOptions = QueryOptions()) =
  discard

# Test

var store = "test"
createDatastore(store)
echo retrieveDatastores()

