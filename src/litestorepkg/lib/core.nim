import
  x_sqlite3,
  x_db_sqlite as db,
  strutils,
  os,
  oids,
  json,
  pegs,
  strtabs,
  strutils,
  base64,
  math
import
  types,
  contenttypes,
  queries,
  logger,
  utils

# Manage Datastores

var LS_TRANSACTION = false

proc createIndexes(db: DbConn) =
  db.exec SQL_CREATE_INDEX_DOCUMENTS_DOCID
  db.exec SQL_CREATE_INDEX_DOCUMENTS_ID
  db.exec SQL_CREATE_INDEX_TAGS_TAG_ID
  db.exec SQL_CREATE_INDEX_TAGS_DOCUMENT_ID

proc dropIndexes(db: DbConn) =
  db.exec SQL_DROP_INDEX_DOCUMENTS_DOCID
  db.exec SQL_DROP_INDEX_DOCUMENTS_ID
  db.exec SQL_DROP_INDEX_TAGS_TAG_ID
  db.exec SQL_DROP_INDEX_TAGS_DOCUMENT_ID

proc createDatastore*(file: string) =
  if file.fileExists():
    raise newException(EDatastoreExists, "Datastore '$1' already exists." % file)
  LOG.debug("Creating datastore '$1'", file)
  let data = db.open(file, "", "", "")
  LOG.debug("Creating tables")
  data.exec(SQL_CREATE_DOCUMENTS_TABLE)
  data.exec(SQL_CREATE_SEARCHDATA_TABLE)
  data.exec(SQL_CREATE_TAGS_TABLE)
  data.exec(SQL_CREATE_INFO_TABLE)
  data.exec(SQL_INSERT_INFO, 1, 0, 0)
  LOG.debug("Creating indexes")
  data.createIndexes()
  LOG.debug("Database created")

proc closeDatastore*(store: Datastore) =
  try:
    db.close(store.db)
  except:
    raise newException(EDatastoreUnavailable,
        "Datastore '$1' cannot be closed." % store.path)

proc destroyDatastore*(store: Datastore) =
  try:
    if store.path.fileExists():
      store.closeDataStore()
      store.path.removeFile()
  except:
    raise newException(EDatastoreUnavailable,
        "Datastore '$1' cannot destroyed." % store.path)

proc openDatastore*(file: string): Datastore =
  if not file.fileExists:
    raise newException(EDatastoreDoesNotExist,
        "Datastore '$1' does not exists." % file)
  try:
    result.db = db.open(file, "", "", "")
    # Register custom function & PRAGMAs
    LOG.debug("Registering custom functions...")
    discard create_function(cast[PSqlite3](result.db), "rank", -1, SQLITE_ANY,
        cast[pointer](SQLITE_DETERMINISTIC), okapi_bm25f_kb, nil, nil)
    LOG.debug("Executing PRAGMAs...")
    discard result.db.tryExec("PRAGMA locking_mode = exclusive".sql)
    discard result.db.tryExec("PRAGMA page_size = 4096".sql)
    discard result.db.tryExec("PRAGMA cache_size = 10000".sql)
    discard result.db.tryExec("PRAGMA foreign_keys = ON".sql)
    LOG.debug("Done.")
    result.path = file
    result.mount = ""
  except:
    raise newException(EDatastoreUnavailable,
        "Datastore '$1' cannot be opened." % file)

proc retrieveInfo*(store: Datastore): array[0..1, int] =
  var data = store.db.getRow(SQL_SELECT_INFO)
  return [data[0].parseInt, data[1].parseInt]

proc hasMirror(store: Datastore): bool =
  return store.mount.len > 0

proc begin(store: Datastore) =
  if not LS_TRANSACTION:
    LOG.debug("Beginning transaction")
    LS_TRANSACTION = true
    store.db.exec("BEGIN".sql)

proc commit(store: Datastore) =
  if LS_TRANSACTION:
    LOG.debug("Committing transaction")
    LS_TRANSACTION = false
    store.db.exec("COMMIT".sql)
    LOG.debug("Committed.")

proc rollback(store: Datastore) =
  if LS_TRANSACTION:
    LOG.debug("Rolling back transaction")
    LS_TRANSACTION = false
    store.db.exec("ROLLBACK".sql)
    LOG.debug("Rolled back.")

# Manage Indexes

proc createIndex*(store: Datastore, indexId, field: string) =
  let query = sql("CREATE INDEX json_index_$1 ON documents(json_extract(data, ?) COLLATE NOCASE)" % [indexId])
  store.begin()
  store.db.exec(query, field)
  store.commit()

proc dropIndex*(store: Datastore, indexId: string) =
  let query = sql("DROP INDEX json_index_" & indexId);
  store.begin()
  store.db.exec(query)
  store.commit()

proc retrieveIndex*(store: Datastore, id: string, options: QueryOptions = newQueryOptions()): JsonNode =
  var options = options
  options.single = true
  let query = prepareSelectIndexesQuery(options)
  let raw_index = store.db.getRow(query.sql, "json_index_" & id)
  var matches: array[0..0, string]
  let fieldPeg = peg"'CREATE INDEX json_index_test ON documents(json_extract(data, \'' {[^']+}"
  discard raw_index[1].match(fieldPeg, matches)
  return %[("id", %raw_index[0].replace("json_index_", "")), ("field", %matches[0])]

proc retrieveIndexes*(store: Datastore, options: QueryOptions = newQueryOptions()): JsonNode =
  var query = prepareSelectIndexesQuery(options)
  var raw_indexes: seq[Row]
  if (options.like.len > 0):
    echo options.like
    if (options.like[options.like.len-1] == '*' and options.like[0] != '*'):
      let str = "json_index_" & options.like.substr(0, options.like.len-2)
      echo str
      raw_indexes = store.db.getAllRows(query.sql, str, str & "{")
    else:
      let str =  "json_index_" & options.like.replace("*", "%")
      echo str, "---"
      raw_indexes = store.db.getAllRows(query.sql, str)
  else:
    raw_indexes = store.db.getAllRows(query.sql)
  var indexes = newSeq[JsonNode](0)
  for index in raw_indexes:
    var matches: array[0..0, string]
    let fieldPeg = peg"'CREATE INDEX json_index_test ON documents(json_extract(data, \'' {[^']+}"
    discard index[1].match(fieldPeg, matches)
    indexes.add(%[("id", %index[0]), ("field", %matches[0])])
  return %indexes

proc countIndexes*(store: Datastore, q = "", like = ""): int64 =
  var query = SQL_COUNT_INDEXES
  if q.len > 0:
    query = q.sql
  if like.len > 0:
    if (like[like.len-1] == '%' or like[like.len-1] == '*'):
      let str = like.substr(0, like.len-2)
      return store.db.getRow(query, str, str & "{")[0].parseInt
    else:
      return store.db.getRow(query, like)[0].parseInt
  return store.db.getRow(query)[0].parseInt

# Manage Tags

proc createTag*(store: Datastore, tagid, documentid: string, system = false) =
  if tagid.match(PEG_USER_TAG) or system and tagid.match(PEG_TAG):
    store.begin()
    store.db.exec(SQL_INSERT_TAG, tagid, documentid)
    store.commit()
  else:
    store.rollback()
    raise newException(EInvalidTag, "Invalid Tag: $1" % tagid)

proc destroyTag*(store: Datastore, tagid, documentid: string,
    system = false): int64 =
  if tagid.match(PEG_USER_TAG) or system and tagid.match(PEG_TAG):
    store.begin()
    result = store.db.execAffectedRows(SQL_DELETE_TAG, tagid, documentid)
    store.commit()
  else:
    store.rollback()
    raise newException(EInvalidTag, "Invalid Tag: $1" % tagid)

proc retrieveTag*(store: Datastore, id: string,
    options: QueryOptions = newQueryOptions()): JsonNode =
  var options = options
  options.single = true
  var query = prepareSelectTagsQuery(options)
  var raw_tag = store.db.getRow(query.sql, id)
  return %[("id", %raw_tag[0]), ("documents", %(raw_tag[1].parseInt))]

proc retrieveTags*(store: Datastore, options: QueryOptions = newQueryOptions()): JsonNode =
  var query = prepareSelectTagsQuery(options)
  var raw_tags: seq[Row]
  if (options.like.len > 0):
    if (options.like[options.like.len-1] == '*'):
      let str = options.like.substr(0, options.like.len-2)
      raw_tags = store.db.getAllRows(query.sql, str, str & "{")
    else:
      raw_tags = store.db.getAllRows(query.sql, options.like.replace("*", "%"))
  else:
    raw_tags = store.db.getAllRows(query.sql)
  var tags = newSeq[JsonNode](0)
  for tag in raw_tags:
    tags.add(%[("id", %tag[0]), ("documents", %(tag[1].parseInt))])
  return %tags

proc countTags*(store: Datastore, q = "", like = ""): int64 =
  var query = SQL_COUNT_TAGS
  if q.len > 0:
    query = q.sql
  if like.len > 0:
    if (like[like.len-1] == '%' or like[like.len-1] == '*'):
      let str = like.substr(0, like.len-2)
      return store.db.getRow(query, str, str & "{")[0].parseInt
    else:
      return store.db.getRow(query, like)[0].parseInt
  return store.db.getRow(query)[0].parseInt

proc retrieveTagsWithTotals*(store: Datastore): JsonNode =
  var data = store.db.getAllRows(SQL_SELECT_TAGS_WITH_TOTALS)
  var tag_array = newSeq[JsonNode](0)
  for row in data:
    var obj = newJObject()
    obj[row[0]] = %row[1].parseInt
    tag_array.add(obj)
  return %tag_array

# Manage Documents

proc retrieveRawDocument*(store: Datastore, id: string,
    options: QueryOptions = newQueryOptions()): string =
  var options = options
  options.single = true
  var select = prepareSelectDocumentsQuery(options)
  var raw_document = store.db.getRow(select.sql, id)
  if raw_document[0] == "":
    return ""
  else:
    return $store.prepareJsonDocument(raw_document, options)

proc createDocument*(store: Datastore, id = "", rawdata = "",
    contenttype = "text/plain", binary = -1, searchable = 1): string =
  let singleOp = not LS_TRANSACTION
  var id = id
  var contenttype = contenttype.replace(peg"""\;(.+)$""", "") # Strip charset for now
  var binary = checkIfBinary(binary, contenttype)
  var searchable = searchable
  if binary == 1:
    searchable = 0
  var data = rawdata
  if contenttype == "application/json":
    # Validate JSON data
    try:
      discard data.parseJson
    except:
      raise newException(JsonParsingError, "Invalid JSON content - " &
          getCurrentExceptionMsg())
  if id == "":
    id = $genOid()
  elif id.isFolder:
    id = id & $genOid()
  # Store document
  try:
    LOG.debug("Creating document '$1'" % id)
    store.begin()
    var res = store.db.insertID(SQL_INSERT_DOCUMENT, id, data, contenttype,
        binary, searchable, currentTime())
    if res > 0:
      store.db.exec(SQL_INCREMENT_DOCS)
      if binary <= 0 and searchable >= 0:
        # Add to search index
        store.db.exec(SQL_INSERT_SEARCHCONTENT, res, id, data.toPlainText)
      store.addDocumentSystemTags(id, contenttype)
      if store.hasMirror and id.startsWith(store.mount):
        # Add dir tag
        store.createTag("$dir:"&store.mount, id, true)
        var filename = id.unixToNativePath
        if not fileExists(filename):
          filename.parentDir.createDir
          filename.writeFile(rawdata)
        else:
          raise newException(EFileExists, "File already exists: $1" % filename)
    if singleOp:
      store.commit()
    return $store.retrieveRawDocument(id)
  except:
    store.rollback()
    eWarn()
    raise

proc updateDocument*(store: Datastore, id: string, rawdata: string,
    contenttype = "text/plain", binary = -1, searchable = 1): string =
  let singleOp = not LS_TRANSACTION
  var contenttype = contenttype.replace(peg"""\;(.+)$""", "") # Strip charset for now
  var binary = checkIfBinary(binary, contenttype)
  var data = rawdata
  if contenttype == "application/json":
    # Validate JSON data
    try:
      discard data.parseJson
    except:
      raise newException(JsonParsingError, "Invalid JSON content - " &
          getCurrentExceptionMsg())
  var searchable = searchable
  if binary == 1:
    searchable = 0
  try:
    LOG.debug("Updating document '$1'" % id)
    store.begin()
    var res = store.db.execAffectedRows(SQL_UPDATE_DOCUMENT, data, contenttype,
        binary, searchable, currentTime(), id)
    if res > 0:
      if binary <= 0 and searchable >= 0:
        store.db.exec(SQL_UPDATE_SEARCHCONTENT, data.toPlainText, id)
      store.destroyDocumentSystemTags(id)
      store.addDocumentSystemTags(id, contenttype)
      if store.hasMirror and id.startsWith(store.mount):
        var filename = id.unixToNativePath
        if fileExists(filename):
          filename.writeFile(rawdata)
        else:
          raise newException(EFileNotFound, "File not found: $1" % filename)
      result = $store.retrieveRawDocument(id)
    else:
      result = ""
    if singleOp:
      store.commit()
  except:
    eWarn()
    store.rollback()
    raise

proc setDocumentModified*(store: Datastore, id: string): string =
  store.db.exec(SQL_SET_DOCUMENT_MODIFIED, id, currentTime())

proc destroyDocument*(store: Datastore, id: string): int64 =
  try:
    let singleOp = not LS_TRANSACTION
    LOG.debug("Destroying document '$1'" % id)
    store.begin()
    result = store.db.execAffectedRows(SQL_DELETE_DOCUMENT, id)
    if result > 0:
      store.db.exec(SQL_DECREMENT_DOCS)
      store.db.exec(SQL_DELETE_SEARCHCONTENT, id)
      if store.hasMirror and id.startsWith(store.mount):
        var filename = id.unixToNativePath
        if fileExists(filename):
          removeFile(id.unixToNativePath)
        else:
          raise newException(EFileNotFound, "File not found: $1" % filename)
    if singleOp:
      store.commit()
  except:
    eWarn()
    store.rollback()

proc retrieveDocument*(store: Datastore, id: string,
    options: QueryOptions = newQueryOptions()): tuple[data: string,
    contenttype: string] =
  var options = options
  options.single = true
  var select = prepareSelectDocumentsQuery(options)
  var raw_document = store.db.getRow(select.sql, id)
  LOG.debug("Retrieving document '$1'" % id)
  if raw_document[0] == "":
    LOG.debug("(No Data)")
    return (data: "", contenttype: "")
  else:
    LOG.debug("Content Length: $1" % $(raw_document[1].len))
    if raw_document[3].parseInt == 1:
      return (data: raw_document[1].decode, contenttype: raw_document[2])
    else:
      return (data: raw_document[1], contenttype: raw_document[2])

proc retrieveRawDocuments*(store: Datastore,
    options: var QueryOptions = newQueryOptions()): JsonNode =
  var select = prepareSelectDocumentsQuery(options)
  var raw_documents: seq[Row]
  if options.folder != "":
    raw_documents = store.db.getAllRows(select.sql, options.folder,
        options.folder & "{")
  else:
    raw_documents = store.db.getAllRows(select.sql)
  var documents = newSeq[JsonNode](0)
  for doc in raw_documents:
    documents.add store.prepareJsonDocument(doc, options)
  return %documents

proc countDocuments*(store: Datastore): int64 =
  return store.db.getRow(SQL_COUNT_DOCUMENTS)[0].parseInt

proc importFile*(store: Datastore, f: string, dir = "") =
  if not f.fileExists:
    raise newException(EFileNotFound, "File '$1' not found." % f)
  let ext = f.splitFile.ext
  var d_id = f.replace("\\", "/")
  var d_contents = f.readFile
  var d_ct = "application/octet-stream"
  if CONTENT_TYPES.hasKey(ext):
    d_ct = CONTENT_TYPES[ext].replace("\"", "")
  var d_binary = 0
  var d_searchable = 1
  if d_ct.isBinary:
    d_binary = 1
    d_searchable = 0
    d_contents = d_contents.encode(d_contents.len*2) # Encode in Base64.
  let singleOp = not LS_TRANSACTION
  store.begin()
  try:
    discard store.createDocument(d_id, d_contents, d_ct, d_binary, d_searchable)
    if dir != "":
      store.db.exec(SQL_INSERT_TAG, "$dir:"&dir, d_id)
  except:
    store.rollback()
    eWarn()
    raise
  if singleOp:
    store.commit()

proc optimize*(store: Datastore) =
  try:
    store.begin()
    LOG.debug("Reindexing columns...")
    store.db.exec(SQL_REINDEX)
    LOG.debug("Rebuilding full-text index...")
    store.db.exec(SQL_REBUILD)
    LOG.debug("Optimixing full-text index...")
    store.db.exec(SQL_OPTIMIZE)
    store.commit()
    LOG.debug("Done")
  except:
    eWarn()

proc vacuum*(file: string) =
  let data = db.open(file, "", "", "")
  try:
    data.exec(SQL_VACUUM)
    db.close(data)
  except:
    eWarn()
    quit(203)
  quit(0)

proc importDir*(store: Datastore, dir: string) =
  var files = newSeq[string]()
  if not dir.dirExists:
    raise newException(EDirectoryNotFound, "Directory '$1' not found." % dir)
  for f in dir.walkDirRec():
    if f.existsDir:
      continue
    if f.splitFile.name.startsWith("."):
      # Ignore hidden files
      continue
    files.add(f)
  # Import single files in batch
  let batchSize = 100
  let nBatches = ceil(files.len/batchSize).toInt
  var cFiles = 0
  var cBatches = 0
  store.begin()
  LOG.info("Importing $1 files in $2 batches", files.len, nBatches)
  LOG.debug("Dropping column indexes...")
  store.db.dropIndexes()
  for f in files:
    try:
      store.importFile(f, dir)
      cFiles.inc
      if (cFiles-1) mod batchSize == 0:
        cBatches.inc
        store.commit()
        LOG.info("Importing batch $1/$2...", cBatches, nBatches)
        store.begin()
    except:
      LOG.warn("Unable to import file: $1", f)
      eWarn()
      store.rollback()
  LOG.debug("Recreating column indexes...")
  store.db.createIndexes()
  store.commit()
  LOG.info("Imported $1/$2 files", cFiles, files.len)

proc exportDir*(store: Datastore, dir: string) =
  let docs = store.db.getAllRows(SQL_SELECT_DOCUMENTS_BY_TAG, "$dir:"&dir)
  LOG.info("Exporting $1 files...", docs.len)
  for doc in docs:
    LOG.debug("Exporting: $1", doc[1])
    let file = doc[1].unixToNativePath
    var data: string
    if doc[4].parseInt == 1:
      data = doc[2].decode
    else:
      data = doc[2]
    file.parentDir.createDir
    file.writeFile(data)
  LOG.info("Done.");

proc deleteDir*(store: Datastore, dir: string) =
  store.db.exec(SQL_DELETE_SEARCHDATA_BY_TAG, "$dir:"&dir)
  store.db.exec(SQL_DELETE_DOCUMENTS_BY_TAG, "$dir:"&dir)
  store.db.exec(SQL_DELETE_TAGS_BY_TAG, "$dir:"&dir)
  let total = store.db.getRow(SQL_COUNT_DOCUMENTS)[0].parseInt
  store.db.exec(SQL_SET_TOTAL_DOCS, total)

proc mountDir*(store: var Datastore, dir: string) =
  if not dir.dirExists:
    raise newException(EDirectoryNotFound, "Directory '$1' not found." % dir)
  store.mount = dir

proc destroyDocumentsByTag*(store: Datastore, tag: string): int64 =
  result = 0
  var ids = store.db.getAllRows(SQL_SELECT_DOCUMENT_IDS_BY_TAG, tag)
  for id in ids:
    result.inc(store.destroyDocument(id[0]).int)
