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
  contenttypes,
  queries,
  utils,
  cli

{.compile: "vendor/sqlite/libsqlite3.c".}
{.passC: "-DSQLITE_ENABLE_FTS3 -DSQLITE_ENABLE_FTS3_PARENTHESIS".}


# Manage Datastores

proc createDatastore*(file:string) = 
  if file.fileExists:
    raise newException(EDatastoreExists, "Datastore '$1' already exists." % file)
  let store = db.open(file, "", "", "")
  store.exec(SQL_CREATE_DOCUMENTS_TABLE)
  store.exec(SQL_CREATE_SEARCHCONTENTS_TABLE)
  store.exec(SQL_CREATE_TAGS_TABLE)

proc deleteDatastore*(file:string) =
  try:
    file.removeFile
  except:
    raise newException(EDatastoreUnavailable, "Datastore '$1' cannot deleted." % file)

proc openDatastore*(file:string): Datastore =
  if not file.fileExists:
    raise newException(EDatastoreDoesNotExist, "Datastore '$1' does not exists." % file)
  try:
    result.db = db.open(file, "", "", "")
    result.path = file
  except:
    raise newException(EDatastoreUnavailable, "Datastore '$1' cannot be opened." % file)

proc closeDatastore*(store:Datastore) = 
  try:
    db.close(store.db)
  except:
    raise newException(EDatastoreUnavailable, "Datastore '$1' cannot be closed." % store.path)

# Manage Documents

proc createDocument*(store: Datastore,  id="", data = "", contenttype = "text/plain", binary = -1, searchable = 1): string =
  var binary = checkIfBinary(binary, contenttype)
  var data = data
  if binary == 1:
    data = data.encode(data.len*2)
  if id == "":
    result = $genOid()
  else:
    result = id
  # Store document
  store.db.exec(SQL_INSERT_DOCUMENT, result, data, contenttype, binary, searchable, getTime().getGMTime().format("yyyy-MM-dd'T'hh:mm:ss'Z'"))
  if binary == 0 and searchable == 1:
    # Add to search index
    store.db.exec(SQL_INSERT_SEARCHCONTENT, result, data)
  store.addDocumentSystemTags(result, contenttype)
  return result

proc updateDocument*(store: Datastore, id: string, data: string, contenttype = "text/plain", binary = -1, searchable = 1): int64 =
  var binary = checkIfBinary(binary, contenttype)
  var data = data
  if binary == 1:
    data = data.encode(data.len*2)
  result = store.db.execAffectedRows(SQL_UPDATE_DOCUMENT, data, contenttype, binary, searchable, getTime().getGMTime().format("yyyy-MM-dd'T'hh:mm:ss'Z'"), id)
  store.deleteDocumentSystemTags(id)
  store.addDocumentSystemTags(id, contenttype)
  store.db.exec(SQL_UPDATE_SEARCHCONTENT, data, id)

proc deleteDocument*(store: Datastore, id: string): int64 =
  result = store.db.execAffectedRows(SQL_DELETE_DOCUMENT, id)
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

proc deleteTag*(store: Datastore, tagid, documentid: string): int64 =
  if not tagid.match(PEG_USER_TAG):
    raise newException(EInvalidTag, "Invalid Tag: $1" % tagid)
  return store.db.execAffectedRows(SQL_DELETE_TAG, documentid, tagid)

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

proc packDir*(store: Datastore, dir: string) =
  if not dir.dirExists:
    raise newException(EDirectoryNotFound, "Directory '$1' not found." % dir)
  for f in dir.walkDirRec():
    let ext = f.splitFile.ext
    var d_id = f
    var d_contents = f.readFile
    var d_ct = "text/plain"
    if CONTENT_TYPES.hasKey(ext):
      d_ct = CONTENT_TYPES[ext]
    var d_binary = 0
    var d_searchable = 1
    if d_ct.isBinary:
      d_binary = 1
      d_searchable = 0
    discard store.createDocument(d_id, d_contents, d_ct, d_binary, d_searchable)
    store.db.exec(SQL_INSERT_TAG, "$dir:"&dir, d_id)

proc unpackDir*(store: Datastore, dir: string) =
  let docs = store.db.getAllRows(SQL_SELECT_DOCUMENTS_BY_TAG, "$dir:"&dir)
  for doc in docs:
    let file = doc[0]
    var data: string
    if doc[3].parseInt == 1:
      data = doc[1].decode
    else:
      data = doc[1]
    file.parentDir.createDir
    file.writeFile(data)

proc deleteDocumentsByTag*(store: Datastore, tag: string): int64 =
  result = 0
  var ids = store.db.getAllRows(SQL_SELECT_DOCUMENT_IDS_BY_TAG, tag)
  for id in ids:
    result.inc(store.deleteDocument(id[0]).int)




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
  echo store.deleteDocumentsByTag("$dir:nimcache")
  
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
      #TODO
      discard