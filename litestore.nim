import 
  sqlite3, 
  db_sqlite as db, 
  strutils, 
  os,
  oids,
  times,
  json,
  pegs
import
  types,
  contenttypes,
  queries,
  utils

{.compile: "vendor/sqlite/libsqlite3.c".}
{.passC: "-DSQLITE_ENABLE_FTS3 -DSQLITE_ENABLE_FTS3_PARENTHESIS".}


# TODO manage stores directory
let cwd = getCurrentDir()

# Manage Datastores

proc createDatastore*(name:string) = 
  if name.changeFileExt("ls").fileExists:
    raise newException(EDatastoreExists, "Datastore '$1' already exists." % name)
  let store = db.open(cwd.joinPath(name.changeFileExt("ls")), "", "", "")
  store.exec(SQL_CREATE_DOCUMENTS_TABLE)
  store.exec(SQL_CREATE_SEARCHCONTENTS_TABLE)
  store.exec(SQL_CREATE_TAGS_TABLE)

proc deleteDatastore*(name:string) =
  try:
    cwd.joinPath(name.changeFileExt("ls")).removeFile
  except:
    raise newException(EDatastoreUnavailable, "Datastore '$1' cannot deleted." % name)

proc openDatastore(name:string): Datastore =
  if not name.changeFileExt("ls").fileExists:
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

proc retrieveDatastores*(): string =
  var stores = newSeq[JsonNode](0)
  for f in walkFiles(cwd.joinPath("*.ls")):
    var name = f.extractFilename.changeFileExt("")
    var store = name.openDataStore()
    var n_documents = store.db.getRow(SQL_COUNT_DOCUMENTS)[0].parseInt
    var n_tags = store.db.getRow(SQL_COUNT_TAGS)[0].parseInt
    stores.add(%[("id", %name), ("documents", %n_documents), ("tags", %n_tags)])
    store.closeDatastore()
  return $(%(stores))

# Manage Documents

proc createDocument*(store: Datastore,  data = "", contenttype = "text/plain", binary = -1, searchable = 1): string =
  var binary = checkIfBinary(binary, contenttype)
  result = $genOid()
  # Store document
  store.db.exec(SQL_INSERT_DOCUMENT, result, data, contenttype, binary, searchable, getTime().getGMTime().format("yyyy-MM-dd'T'hh:mm:ss'Z'"))
  if binary == 0 and searchable == 1:
    # Add to search index
    store.db.exec(SQL_INSERT_SEARCHCONTENT, result, data)
  store.addDocumentSystemTags(result, contenttype)
  return result

proc updateDocument*(store: Datastore, id: string, data: string, contenttype = "text/plain", binary = -1, searchable = true) =
  var binary = checkIfBinary(binary, contenttype)
  store.db.exec(SQL_UPDATE_DOCUMENT, data, contenttype, binary, searchable, getTime().getGMTime().format("yyyy-MM-dd'T'hh:mm:ss'Z'"), id)
  store.deleteDocumentSystemTags(id)
  store.addDocumentSystemTags(id, contenttype)
  store.db.exec(SQL_UPDATE_SEARCHCONTENT, data, id)

proc deleteDocument*(store: Datastore, id: string) =
  store.db.exec(SQL_DELETE_DOCUMENT, id)
  store.db.exec(SQL_DELETE_SEARCHCONTENT, id)
  store.db.exec(SQL_DELETE_DOCUMENT_TAGS, id)

proc retrieveDocument*(store: Datastore, id: string, options: QueryOptions = newQueryOptions()): string =
  var options = options
  options.single = true
  var select = prepareSelectDocumentsQuery(options)
  var raw_document = store.db.getRow(select.sql, id)
  return $store.prepareJsonDocument(raw_document)

proc retrieveDocuments*(store: Datastore, options: QueryOptions = newQueryOptions()): string =
  var select = prepareSelectDocumentsQuery(options)
  var raw_documents = store.db.getAllRows(select.sql)
  var documents = newSeq[JsonNode](0)
  for doc in raw_documents:
    documents.add store.prepareJsonDocument(doc)
  return $(%documents)

# Manage Tags

proc createTag*(store: Datastore, tagid, documentid: string) =
  if not tagid.match(PEG_USER_TAG):
    raise newException(EInvalidTag, "Invalid Tag: $1" % tagid)
  store.db.exec(SQL_INSERT_TAG, tagid, documentid)

proc deleteTag*(store: Datastore, tagid, documentid: string) =
  if not tagid.match(PEG_USER_TAG):
    raise newException(EInvalidTag, "Invalid Tag: $1" % tagid)
  store.db.exec(SQL_DELETE_TAG, documentid, tagid)

proc retrieveTag*(store: Datastore, id: string, options: QueryOptions = newQueryOptions()): string =
  var options = options
  options.single = true
  var query = prepareSelectTagsQuery(options)
  var raw_tag = store.db.getRow(query.sql, id)
  return $(%[("id", %raw_tag[0]), ("documents", %(raw_tag[1].parseInt))])

proc retrieveTags*(store: Datastore, options: QueryOptions = newQueryOptions()): string =
  var query = prepareSelectTagsQuery(options)
  var raw_tags = store.db.getAllRows(query.sql)
  var tags = newSeq[JsonNode](0)
  for tag in raw_tags:
    tags.add(%[("id", %tag[0]), ("documents", %(tag[1].parseInt))])
  return $(%tags)

# TODO Pack/Unpack Directories

proc packDir*(store: Datastore, dir: string) =
  discard

proc unpackDir*(store: Datastore, dir: string) =
  discard

# Test

var name = "test"
var file = cwd.joinPath(name&".ls")
if file.fileExists:
  file.removeFile
createDatastore(name)
var store = name.openDatastore
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
echo store.retrieveDocuments(opts)
