import
  db_connector/sqlite3,
  db_connector/db_sqlite as db,
  os,
  oids,
  json,
  pegs,
  strtabs,
  strutils,
  sequtils,
  httpclient,
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
  data.exec(SQL_CREATE_SYSTEM_DOCUMENTS_TABLE)
  data.exec(SQL_CREATE_TAGS_TABLE)
  data.exec(SQL_CREATE_INFO_TABLE)
  data.exec(SQL_INSERT_INFO, 2, 0)
  LOG.debug("Creating indexes")
  data.createIndexes()
  LOG.debug("Database created")

proc closeDatastore*(store: Datastore) =
  try:
    db.close(store.db)
  except CatchableError:
    raise newException(EDatastoreUnavailable,
        "Datastore '$1' cannot be closed." % store.path)

proc destroyDatastore*(store: Datastore) =
  try:
    if store.path.fileExists():
      store.closeDataStore()
      store.path.removeFile()
  except CatchableError:
    raise newException(EDatastoreUnavailable,
        "Datastore '$1' cannot destroyed." % store.path)

proc retrieveInfo*(store: Datastore): array[0..1, int] =
  var data = store.db.getRow(SQL_SELECT_INFO)
  return [data[0].parseInt, data[1].parseInt]

proc upgradeDatastore*(store: Datastore) =
  let info = store.retrieveInfo()
  if info[0] == 1:
    LOG.debug("Upgrading datastore to version 2...")
    let bkp_path = store.path & "__v1_backup"
    copyFile(store.path, bkp_path)
    try:
      store.db.exec(SQL_CREATE_SYSTEM_DOCUMENTS_TABLE)
      store.db.exec(SQL_UPDATE_VERSION, 2)
      LOG.debug("Done.")
    except CatchableError:
      store.closeDatastore()
      store.path.removeFile()
      copyFile(bkp_path, store.path)
      let e = getCurrentException()
      LOG.error(getCurrentExceptionMsg())
      LOG.debug(e.getStackTrace())
      LOG.error("Unable to upgrade datastore '$1'." % store.path)

proc openDatastore*(file: string): Datastore {.gcsafe.} =
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
    discard result.db.tryExec("PRAGMA journal_mode = WAL".sql)
    discard result.db.tryExec("PRAGMA page_size = 4096".sql)
    discard result.db.tryExec("PRAGMA cache_size = 10000".sql)
    discard result.db.tryExec("PRAGMA foreign_keys = ON".sql)
    LOG.debug("Done.")
    result.path = file
    result.mount = ""
  except CatchableError:
    raise newException(EDatastoreUnavailable,
        "Datastore '$1' cannot be opened." % file)

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
  let query = sql("CREATE INDEX json_index_$1 ON documents(json_extract(data, ?) COLLATE NOCASE) WHERE json_valid(data)" %
      [indexId])
  store.begin()
  store.db.exec(query, field)
  store.commit()

proc dropIndex*(store: Datastore, indexId: string) =
  let query = sql("DROP INDEX json_index_" & indexId);
  store.begin()
  store.db.exec(query)
  store.commit()

proc retrieveIndex*(store: Datastore, id: string,
    options: QueryOptions = newQueryOptions()): JsonNode =
  var options = options
  options.single = true
  let query = prepareSelectIndexesQuery(options)
  let raw_index = store.db.getRow(query.sql, "json_index_" & id)
  if raw_index[0] == "":
    return newJNull()
  var matches: array[0..0, string]
  let fieldPeg = peg"'CREATE INDEX json_index_test ON documents(json_extract(data, \'' {[^']+}"
  discard raw_index[1].match(fieldPeg, matches)
  return %[("id", %raw_index[0].replace("json_index_", "")), ("field", %matches[0])]

proc retrieveIndexes*(store: Datastore, options: QueryOptions = newQueryOptions()): JsonNode =
  var query = prepareSelectIndexesQuery(options)
  var raw_indexes: seq[Row]
  if (options.like.len > 0):
    if (options.like[options.like.len-1] == '*' and options.like[0] != '*'):
      let str = "json_index_" & options.like.substr(0, options.like.len-2)
      raw_indexes = store.db.getAllRows(query.sql, str, str & "{")
    else:
      let str = "json_index_" & options.like.replace("*", "%")
      raw_indexes = store.db.getAllRows(query.sql, str)
  else:
    raw_indexes = store.db.getAllRows(query.sql)
  var indexes = newSeq[JsonNode](0)
  for index in raw_indexes:
    var matches: array[0..0, string]
    let fieldPeg = peg"'CREATE INDEX json_index_test ON documents(json_extract(data, \'' {[^']+}"
    discard index[1].match(fieldPeg, matches)
    indexes.add(%[("id", %index[0].replace("json_index_", "")), ("field",
        %matches[0])])
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
  if raw_tag[0] == "":
    return newJNull()
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
    except CatchableError:
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
    let time = currentTime()
    var res = store.db.insertID(SQL_INSERT_DOCUMENT, id, data, contenttype,
        binary, searchable, time, time)
    if res > 0:
      store.db.exec(SQL_INCREMENT_DOCS)
      if binary <= 0 and searchable > 0:
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
  except CatchableError:
    store.rollback()
    eWarn()
    raise

proc createSystemDocument*(store: Datastore, id = "", rawdata = "",
    contenttype = "text/plain", binary = -1): string =
  let singleOp = not LS_TRANSACTION
  var id = id
  var contenttype = contenttype.replace(peg"""\;(.+)$""", "") # Strip charset for now
  var binary = checkIfBinary(binary, contenttype)
  var data = rawdata
  if contenttype == "application/json":
    # Validate JSON data
    try:
      discard data.parseJson
    except CatchableError:
      raise newException(JsonParsingError, "Invalid JSON content - " &
          getCurrentExceptionMsg())
  if id == "":
    id = $genOid()
  elif id.isFolder:
    id = id & $genOid()
  # Store document
  try:
    LOG.debug("Creating system document '$1'" % id)
    store.begin()
    discard store.db.insertID(SQL_INSERT_SYSTEM_DOCUMENT, id, data, contenttype,
        binary, currentTime())
    if singleOp:
      store.commit()
    return $store.retrieveRawDocument(id)
  except CatchableError:
    store.rollback()
    eWarn()
    raise

proc updateSystemDocument*(store: Datastore, id: string, rawdata: string,
    contenttype = "text/plain", binary = -1): string =
  let singleOp = not LS_TRANSACTION
  var contenttype = contenttype.replace(peg"""\;(.+)$""", "") # Strip charset for now
  var binary = checkIfBinary(binary, contenttype)
  var data = rawdata
  if contenttype == "application/json":
    # Validate JSON data
    try:
      discard data.parseJson
    except CatchableError:
      raise newException(JsonParsingError, "Invalid JSON content - " &
          getCurrentExceptionMsg())
  try:
    LOG.debug("Updating system document '$1'" % id)
    store.begin()
    var res = store.db.execAffectedRows(SQL_UPDATE_SYSTEM_DOCUMENT, data,
        contenttype, binary, currentTime(), id)
    if res > 0:
      result = $store.retrieveRawDocument(id)
    else:
      result = ""
    if singleOp:
      store.commit()
  except CatchableError:
    eWarn()
    store.rollback()
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
    except CatchableError:
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
      if binary <= 0 and searchable > 0:
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
  except CatchableError:
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
  except CatchableError:
    eWarn()
    store.rollback()

proc findDocumentId*(store: Datastore, pattern: string): string =
  var select = "SELECT id FROM documents WHERE id LIKE ? ESCAPE '\\' "
  var raw_document = store.db.getRow(select.sql, pattern)
  LOG.debug("Retrieving document '$1'" % pattern)
  if raw_document[0] == "":
    LOG.debug("(No Such Document)")
    result = ""
  else:
    result = raw_document[0]
    LOG.debug("Found id: $1" % result)

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

proc importFile*(store: Datastore, f: string, dir = "/", system = false,
    notSearchable = false): string =
  if not f.fileExists:
    raise newException(EFileNotFound, "File '$1' not found." % f)
  let split = f.splitFile
  var d_id: string
  if system:
    # Do not save original directory name
    d_id = f.replace("\\", "/")[dir.len+1..f.len-1];
  else:
    d_id = f.replace("\\", "/");
  var d_contents = f.readFile
  var d_ct = "application/octet-stream"
  if CONTENT_TYPES.hasKey(split.ext):
    d_ct = CONTENT_TYPES[split.ext].replace("\"", "")
  var d_binary = 0
  var d_searchable = 1
  if notSearchable and (split.name.startsWith("_") or split.dir.startsWith("_")):
    # Don't search in special files (and files in special folders)
    # when the flag was set
    d_searchable = 0
    LOG.debug("Importing not-searchable file $1", f)
  if d_ct.isBinary:
    d_binary = 1
    d_searchable = 0
    d_contents = d_contents.encode # Encode in Base64.
  let singleOp = not LS_TRANSACTION
  store.begin()
  try:
    if system:
      discard store.createSystemDocument(d_id, d_contents, d_ct, d_binary)
    else:
      discard store.createDocument(d_id, d_contents, d_ct, d_binary, d_searchable)
    if dir != "/" and not system:
      store.db.exec(SQL_INSERT_TAG, "$dir:"&dir, d_id)
  except CatchableError:
    store.rollback()
    eWarn()
    raise
  if singleOp:
    store.commit()
  return d_id

proc importTags*(store: Datastore, d_id: string, tags: openArray[string]) =
  let singleOp = not LS_TRANSACTION
  store.begin()
  try:
    for tag in tags:
      store.db.exec(SQL_INSERT_TAG, tag, d_id)
  except CatchableError:
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
  except CatchableError:
    eWarn()

proc vacuum*(file: string) =
  let data = db.open(file, "", "", "")
  try:
    data.exec(SQL_VACUUM)
    db.close(data)
  except CatchableError:
    eWarn()
    quit(203)
  quit(0)

proc getTagsForFile*(f: string): seq[string] =
  result = newSeq[string]()
  let tags_file = f.splitFile.dir / "_tags"
  if tags_file.fileExists:
    for tag in tags_file.lines:
      result.add(tag)


proc importDir*(store: Datastore, dir: string, system = false,
    importTags = false, notSearchable = false) =
  var files = newSeq[string]()
  if not dir.dirExists:
    raise newException(EDirectoryNotFound, "Directory '$1' not found." % dir)
  for f in dir.walkDirRec():
    if f.dirExists:
      continue
    let dirs = f.split(DirSep)
    if dirs.any(proc (s: string): bool = return s.startsWith(".")):
      # Ignore hidden directories and files
      continue
    let fileName = f.splitFile.name
    if fileName == "_tags" and not importTags:
      # Ignore tags file unless the CLI flag was set
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
      let docId = store.importFile(f, dir, system, notSearchable)
      if not system and importTags:
        let tags = getTagsForFile(f)
        if tags.len > 0:
          store.importTags(docId, tags)
      cFiles.inc
      if (cFiles-1) mod batchSize == 0:
        cBatches.inc
        store.commit()
        LOG.info("Importing batch $1/$2...", cBatches, nBatches)
        store.begin()
    except CatchableError:
      LOG.warn("Unable to import file: $1", f)
      eWarn()
      store.rollback()
  LOG.debug("Recreating column indexes...")
  store.db.createIndexes()
  store.commit()
  LOG.info("Imported $1/$2 files", cFiles, files.len)

proc exportDir*(store: Datastore, dir: string, system = false) =
  var docs: seq[Row]
  if system:
    docs = store.db.getAllRows(SQL_SELECT_SYSTEM_DOCUMENTS)
  else:
    docs = store.db.getAllRows(SQL_SELECT_DOCUMENTS_BY_TAG, "$dir:"&dir)
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

proc deleteDir*(store: Datastore, dir: string, system = false) =
  if system:
    store.db.exec(SQL_DELETE_SYSTEM_DOCUMENTS)
  else:
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

proc setLogLevel*(val: string) =
  case val:
    of "info":
      LOG.level = lvInfo
    of "warn":
      LOG.level = lvWarn
    of "debug":
      LOG.level = lvDebug
    of "error":
      LOG.level = lvError
    of "none":
      LOG.level = lvNone
    else:
      fail(103, "Invalid log level '$1'" % val)


proc downloadJwks*(uri: string) =
  let file = getCurrentDir() / "jwks.json"
  let client = newHttpClient()
  client.downloadFile(uri, file)

proc processAuthConfig(configuration: var JsonNode, auth: var JsonNode) =
  if auth == newJNull() and configuration != newJNull():
    auth = newJObject();
    auth["access"] = newJObject();
    if configuration.hasKey("jwks_uri"):
      LOG.debug("Authentication: Downloading JWKS file.")
      downloadJwks(configuration["jwks_uri"].getStr)
    elif configuration.hasKey("signature"):
      LOG.debug("Authentication: Signature found, processing authentication rules in configuration.")
      auth["signature"] = configuration["signature"].getStr.replace(
          "-----BEGIN CERTIFICATE-----\n", "").replace(
          "\n-----END CERTIFICATE-----").strip().newJString
    for k, v in configuration["resources"].pairs:
      auth["access"][k] = newJObject()
      for meth, content in v.pairs:
        if content.hasKey("auth"):
          auth["access"][k][meth] = content["auth"]

proc processConfigSettings(LS: var LiteStore) =
  # Process config settings if present and if no cli settings are set
  if LS.config != newJNull() and LS.config.hasKey("settings"):
    let settings = LS.config["settings"]
    let cliSettings = LS.cliSettings
    if not cliSettings.hasKey("address") and settings.hasKey("address"):
      LS.address = settings["address"].getStr
    if not cliSettings.hasKey("port") and settings.hasKey("port"):
      LS.port = settings["port"].getInt
    if not cliSettings.hasKey("store") and settings.hasKey("store"):
      LS.file = settings["store"].getStr
    if not cliSettings.hasKey("directory") and settings.hasKey("directory"):
      LS.directory = settings["directory"].getStr
    if not cliSettings.hasKey("middleware") and settings.hasKey("middleware"):
      let val = settings["middleware"].getStr
      for file in val.walkDir():
        if file.kind == pcFile or file.kind == pcLinkToFile:
          LS.middleware[file.path.splitFile[1]] = file.path.readFile()
    if not cliSettings.hasKey("log") and settings.hasKey("log"):
      LS.logLevel = settings["log"].getStr
      setLogLevel(LS.logLevel)
    if not cliSettings.hasKey("mount") and settings.hasKey("mount"):
      LS.mount = settings["mount"].getBool
    if not cliSettings.hasKey("readonly") and settings.hasKey("readonly"):
      LS.readonly = settings["readonly"].getBool

proc setup*(LS: var LiteStore, open = true) {.gcsafe.} =
  if not LS.file.fileExists:
    try:
      LS.file.createDatastore()
    except CatchableError:
      eWarn()
      fail(200, "Unable to create datastore '$1'" % [LS.file])
  if (open):
    try:
      LS.store = LS.file.openDatastore()
      try:
        LS.store.upgradeDatastore()
      except CatchableError:
        fail(203, "Unable to upgrade datastore '$1'" % [LS.file])
      if LS.mount:
        try:
          LS.store.mountDir(LS.directory)
        except CatchableError:
          eWarn()
          fail(202, "Unable to mount directory '$1'" % [LS.directory])
    except CatchableError:
      fail(201, "Unable to open datastore '$1'" % [LS.file])

proc initStore*(LS: var LiteStore) =
  if LS.configFile == "":
    # Attempt to retrieve config.json from system documents
    let options = newQueryOptions(true)
    let rawDoc = LS.store.retrieveRawDocument("config.json", options)
    if rawDoc != "":
      LS.config = rawDoc.parseJson()["data"]

  if LS.config != newJNull():
    # Process config settings
    LS.processConfigSettings()
    # Process auth from config settings
    LOG.debug("Authentication: Checking configuration for auth rules - Store file: " & LS.file)
    processAuthConfig(LS.config, LS.auth)

  if LS.auth == newJNull():
    # Attempt to retrieve auth.json from system documents
    let options = newQueryOptions(true)
    let rawDoc = LS.store.retrieveRawDocument("auth.json", options)
    if rawDoc != "":
      LS.auth = rawDoc.parseJson()["data"]

  # Validation
  if LS.directory == "" and (LS.operation in [opDelete, opImport, opExport] or LS.mount):
    fail(105, "--directory option not specified.")

  if LS.execution.file == "" and (LS.execution.operation in ["put", "post", "patch"]):
    fail(109, "--file option not specified")

  if LS.execution.uri == "" and LS.operation == opExecute:
    fail(110, "--uri option not specified")

  if LS.execution.operation == "" and LS.operation == opExecute:
    fail(111, "--operation option not specified")

  if LS.importTags and LS.operation != opImport:
    fail(116, "--import-tags option alowed only for import operation.")
  if LS.notSerachable and LS.operation != opImport:
    fail(116, "--not-searchable option alowed only for import operation.")

proc updateConfig*(LS: LiteStore) =
  let rawConfig = LS.config.pretty
  if LS.configFile != "":
    LS.configFile.writeFile(rawConfig)
  else:
    let options = newQueryOptions(true)
    let configDoc = LS.store.retrieveRawDocument("config.json", options)
    if configDoc != "":
      discard LS.store.updateSystemDocument("config.json", rawConfig, "application/json")

proc addStore*(LS: LiteStore, id, file: string, config = newJNull()): LiteStore =
  result = initLiteStore()
  result.address = LS.address
  result.port = LS.port
  result.appname = LS.appname
  result.appversion = LS.appversion
  result.favicon = LS.favicon
  result.file = file
  result.middleware = newStringTable()
  if config != newJNull():
    result.config = config
  result.setup(true)
  result.initStore()
  if not LS.config.hasKey("stores"):
    LS.config["stores"] = newJObject()
  LS.config["stores"][id] = newJObject()
  LS.config["stores"][id]["file"] = %file
  LS.config["stores"][id]["config"] = config
