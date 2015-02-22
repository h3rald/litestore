import 
  sqlite3, 
  db_sqlite as db, 
  strutils, 
  os,
  oids,
  json,
  pegs, 
  strtabs,
  strutils,
  base64
import
  types,
  contenttypes,
  queries,
  utils

# Manage Datastores

proc createDatastore*(file:string) = 
  if file.fileExists():
    raise newException(EDatastoreExists, "Datastore '$1' already exists." % file)
  let store = db.open(file, "", "", "")
  store.exec(SQL_CREATE_DOCUMENTS_TABLE)
  store.exec(SQL_CREATE_SEARCHCONTENTS_TABLE)
  store.exec(SQL_CREATE_TAGS_TABLE)

proc closeDatastore*(store:Datastore) = 
  try:
    db.close(store.db)
  except:
    raise newException(EDatastoreUnavailable, "Datastore '$1' cannot be closed." % store.path)

proc destroyDatastore*(store:Datastore) =
  try:
    if store.path.fileExists():
      store.closeDataStore()
      store.path.removeFile()
  except:
    raise newException(EDatastoreUnavailable, "Datastore '$1' cannot destroyed." % store.path)

proc openDatastore*(file:string): Datastore =
  if not file.fileExists:
    raise newException(EDatastoreDoesNotExist, "Datastore '$1' does not exists." % file)
  try:
    result.db = db.open(file, "", "", "")
    result.path = file
  except:
    raise newException(EDatastoreUnavailable, "Datastore '$1' cannot be opened." % file)

# Manage Documents

proc retrieveRawDocument*(store: Datastore, id: string, options: QueryOptions = newQueryOptions()): string =
  var options = options
  options.single = true
  var select = prepareSelectDocumentsQuery(options)
  var raw_document = store.db.getRow(select.sql, id)
  if  raw_document[0] == "":
    return ""
  else:
    return $store.prepareJsonDocument(raw_document)

proc createDocument*(store: Datastore,  id="", data = "", contenttype = "text/plain", binary = -1, searchable = 1): string =
  var id = id
  var contenttype = contenttype.replace(peg"""\;(.+)$""", "") # Strip charset for now
  var binary = checkIfBinary(binary, contenttype)
  var data = data
  if binary == 1:
    data = data.encode(data.len*2)
  if id == "":
    id = $genOid()
  # Store document
  store.db.exec(SQL_INSERT_DOCUMENT, id, data, contenttype, binary, searchable, currentTime())
  if binary <= 0 and searchable >= 0:
    # Add to search index
    store.db.exec(SQL_INSERT_SEARCHCONTENT, id, data)
  store.addDocumentSystemTags(id, contenttype)
  return $store.retrieveRawDocument(id)

proc updateDocument*(store: Datastore, id: string, data: string, contenttype = "text/plain", binary = -1, searchable = 1): string =
  var contenttype = contenttype.replace(peg"""\;(.+)$""", "") # Strip charset for now
  var binary = checkIfBinary(binary, contenttype)
  var data = data
  if binary == 1:
    data = data.encode(data.len*2)
  var res = store.db.execAffectedRows(SQL_UPDATE_DOCUMENT, data, contenttype, binary, searchable, currentTime(), id)
  if res > 0:
    store.destroyDocumentSystemTags(id)
    store.addDocumentSystemTags(id, contenttype)
    store.db.exec(SQL_UPDATE_SEARCHCONTENT, data, id)
    return $store.retrieveRawDocument(id)
  else:
    return ""

proc setDocumentModified*(store: Datastore, id: string): string =
  store.db.exec(SQL_SET_DOCUMENT_MODIFIED, id, currentTime())

proc destroyDocument*(store: Datastore, id: string): int64 =
  result = store.db.execAffectedRows(SQL_DELETE_DOCUMENT, id)
  store.db.exec(SQL_DELETE_SEARCHCONTENT, id)
  store.db.exec(SQL_DELETE_DOCUMENT_TAGS, id)

proc retrieveDocument*(store: Datastore, id: string, options: QueryOptions = newQueryOptions()): tuple[data: string, contenttype: string] =
  var options = options
  options.single = true
  var select = prepareSelectDocumentsQuery(options)
  var raw_document = store.db.getRow(select.sql, id)
  if raw_document[0] == "":
    return (data: "", contenttype: "")
  else:
    if raw_document[3].parseInt == 1:
      return (data: raw_document[1].decode, contenttype: raw_document[2])
    else:
      return (data: raw_document[1], contenttype: raw_document[2])

proc retrieveRawDocuments*(store: Datastore, options: QueryOptions = newQueryOptions()): JsonNode =
  var select = prepareSelectDocumentsQuery(options)
  var raw_documents = store.db.getAllRows(select.sql)
  var documents = newSeq[JsonNode](0)
  for doc in raw_documents:
    documents.add store.prepareJsonDocument(doc)
  return %documents

proc countDocuments*(store: Datastore): int64 =
  return store.db.getRow(SQL_COUNT_DOCUMENTS)[0].parseInt

# Manage Tags

proc createTag*(store: Datastore, tagid, documentid: string, system=false) =
  if tagid.match(PEG_USER_TAG) or system and tagid.match(PEG_TAG):
    store.db.exec(SQL_INSERT_TAG, tagid, documentid)
  else:
    raise newException(EInvalidTag, "Invalid Tag: $1" % tagid)

proc destroyTag*(store: Datastore, tagid, documentid: string, system=false): int64 =
  if tagid.match(PEG_USER_TAG) or system and tagid.match(PEG_TAG):
    return store.db.execAffectedRows(SQL_DELETE_TAG, tagid, documentid)
  else:
    raise newException(EInvalidTag, "Invalid Tag: $1" % tagid)

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

proc countTags*(store: Datastore): int64 =
  return store.db.getRow(SQL_COUNT_TAGS)[0].parseInt

proc retrieveTagsWithTotals*(store: Datastore): JsonNode =
  var data = store.db.getAllRows(SQL_SELECT_TAGS_WITH_TOTALS)
  var tag_array = newSeq[JsonNode](0)
  for row in data:
    var obj = newJObject()
    obj[row[0]] = %row[1].parseInt
    tag_array.add(obj)
  return %tag_array

proc importDir*(store: Datastore, dir: string) =
  if not dir.dirExists:
    raise newException(EDirectoryNotFound, "Directory '$1' not found." % dir)
  for f in dir.walkDirRec():
    if f.existsDir:
      continue
    if f.splitFile.name.startsWith("."):    
      # Ignore hidden files
      continue
    let ext = f.splitFile.ext
    var d_id = f
    var d_contents = f.readFile
    var d_ct = "application/octet-stream"
    if CONTENT_TYPES.hasKey(ext):
      d_ct = CONTENT_TYPES[ext].replace("\"", "")
    var d_binary = 0
    var d_searchable = 1
    if d_ct.isBinary:
      d_binary = 1
      d_searchable = 0
    discard store.createDocument(d_id, d_contents, d_ct, d_binary, d_searchable)
    store.db.exec(SQL_INSERT_TAG, "$dir:"&dir, d_id)

proc  exportDir*(store: Datastore, dir: string, purge = false) =
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
  if purge:
    store.db.exec(SQL_DELETE_DOCUMENTS_BY_TAG, "$dir:"&dir)

proc destroyDocumentsByTag*(store: Datastore, tag: string): int64 =
  result = 0
  var ids = store.db.getAllRows(SQL_SELECT_DOCUMENT_IDS_BY_TAG, tag)
  for id in ids:
    result.inc(store.destroyDocument(id[0]).int)



