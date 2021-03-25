import
  x_sqlite3,
  x_db_sqlite,
  json,
  strutils,
  pegs,
  asynchttpserver,
  math,
  sequtils

import
  types,
  queries,
  contenttypes,
  logger

proc setOrigin*(LS: LiteStore, req: LSRequest, headers: var HttpHeaders) =
  var host = ""
  var port = ""
  var protocol = "http"
  headers["Vary"] = "Origin"
  if req.headers.hasKey("Origin"):
    headers["Access-Control-Allow-Origin"] = req.headers["Origin"]
    return
  elif req.url.hostname != "" and req.url.port != "":
    host = req.url.hostname
    port = req.url.port
  elif req.headers.hasKey("origin"):
    let parts = req.headers["origin"].split("://")
    protocol = parts[0]
    let server = parts[1].split(":")
    if (server.len >= 2):
      host = server[0]
      port = server[1]
    else:
      host = server[0]
      port = "80"
  else:
    headers["Access-Control-Allow-Origin"] = "*"
    return
  headers["Vary"] = "Origin"
  headers["Access-Control-Allow-Origin"] = "$1://$2:$3" % [protocol, host, port]

proc isFolder*(id: string): bool =
  return (id.len == 0 or id.len > 0 and id[id.len-1] == '/')

proc dbQuote*(s: string): string =
  result = "'"
  for c in items(s):
    if c == '\'': add(result, "''")
    else: add(result, c)
  add(result, '\'')

proc selectDocumentsByTags(tags: string, doc_id_col = "id"): string =
  var select_tagged = "SELECT document_id FROM tags WHERE tag_id = '"
  result = ""
  for tag in tags.split(','):
    if not tag.match(PEG_TAG):
      raise newException(EInvalidTag, "Invalid Tag '$1'" % tag)
    result = result & "AND " & doc_id_col & " IN (" & select_tagged & tag & "') "

proc prepareSelectDocumentsQuery*(options: var QueryOptions): string =
  var documents_table = "documents"
  if options.system:
    documents_table = "system_documents"
  var tables = options.tables
  result = "SELECT "
  if options.jsonFilter.len > 0 or options.jsonSelect.len > 0:
    if options.tags.len == 0:
      options.tags = "$subtype:json"
    elif not options.tags.contains("$subtype:json"):
      options.tags = options.tags.split(",").concat(@["$subtype:json"]).join(",")
  if options.search.len > 0:
    if options.select[0] != "COUNT(docid)":
      let rank = "rank(matchinfo(searchdata, 'pcxnal'), 1.20, 0.75, 5.0, 0.5) AS rank"
      let snippet = "snippet(searchdata, \"<strong>\", \"</strong>\", \"<strong>&hellip;</strong>\", -1, 30) as highlight"
      options.select.add(snippet)
      options.select.add("ranktable.rank AS rank")
      if (options.orderby == ""):
        options.orderby = "rank DESC"
      # Create inner select
      var innerSelect = "SELECT docid, " & rank & " FROM searchdata WHERE searchdata MATCH '" & options.search.replace("'", "''") & "' "
      if options.tags.len > 0:
        innerSelect = innerSelect & options.tags.selectDocumentsByTags()
      innerSelect = innerSelect & " ORDER BY rank DESC "
      if options.limit > 0:
        innerSelect = innerSelect & "LIMIT " & $options.limit
        if options.offset > 0:
          innerSelect = innerSelect & " OFFSET " & $options.offset
      tables = options.tables & @[documents_table]
      result = result & options.select.join(", ")
      result = result & " FROM " & tables.join(", ") & " JOIN (" & innerSelect & ") as ranktable USING(docid) JOIN searchdata USING(docid) "
      result = result & "WHERE 1=1 "
    else:
      tables = options.tables & @["searchdata"]
      if options.jsonFilter != "":
        options.select[0] = "COUNT($1.docid)" % documents_table
        tables = tables & @[documents_table]
      result = result & options.select.join(", ")
      result = result & " FROM "&tables.join(", ")&" "
      result = result & "WHERE 1=1 "
      if options.jsonFilter != "":
        result = result & "AND $1.id = searchdata.id " % documents_table
      options.orderby = ""
  else:
    tables = options.tables & @[documents_table]
    result = result & options.select.join(", ")
    result = result & " FROM "&tables.join(", ")&" WHERE 1=1 "
  if options.single:
    if options.like.len > 0:
      result = result & "AND id LIKE ? ESCAPE '\\' "
      options.limit = 1
    else:
      result = result & "AND id = ?"
  var doc_id_col: string
  if options.tags.len > 0 or options.folder.len > 0:
    if options.jsonFilter.len > 0 or (options.search.len > 0 and options.select[0] != "COUNT(docid)"):
      doc_id_col = "$1.id" % documents_table
    else:
      doc_id_col = "id"
  if options.createdAfter != "":
    result = result & "AND created > \"" & $options.createdAfter & "\" "
  if options.createdBefore != "":
    result = result & "AND created < \"" & $options.createdBefore & "\" "
  if options.modifiedAfter != "":
    result = result & "AND modified > \"" & $options.modifiedAfter & "\" "
  if options.modifiedBefore != "":
    result = result & "AND modified < \"" & $options.modifiedBefore & "\" "
  if options.folder.len > 0:
    result = result & "AND " & doc_id_col & " BETWEEN ? and ? "
  if options.tags.len > 0:
    result = result & options.tags.selectDocumentsByTags(doc_id_col)
  if options.jsonFilter.len > 0:
    result = result & "AND " & options.jsonFilter
  if options.search.len > 0:
    result = result & "AND searchdata MATCH '" & options.search.replace("'", "''") & "' "
  if options.orderby.len > 0 and options.select[0] != "COUNT(docid)":
    result = result & "ORDER BY " & options.orderby & " "
  if options.limit > 0 and options.search.len == 0:
    # If searching, do not add limit to the outer select, it's already in the nested select (ranktable)
    result = result & "LIMIT " & $options.limit & " "
    if options.offset > 0:
      result = result & "OFFSET " & $options.offset & " "
  LOG.debug(result.replace("$", "$$"))

proc prepareSelectTagsQuery*(options: QueryOptions): string =
  var group = true
  if options.select.len > 0 and options.select[0] == "COUNT(tag_id)":
    result  = "SELECT COUNT(DISTINCT tag_id) "
    result = result & "FROM tags "
    group = false
  else:
    result = "SELECT tag_id, COUNT(document_id) "
    result = result & "FROM tags "
  if options.single:
    result = result & "WHERE tag_id = ?"
  elif options.like.len > 0:
    if options.like[options.like.len-1] == '*' and options.like[0] != '*':
      result = result & "WHERE tag_id BETWEEN ? AND ? "
    else:
      result = result & "WHERE tag_id LIKE ? "
  if group:
    result = result & "GROUP BY tag_id "
  if options.limit > 0:
    result = result & "LIMIT " & $options.limit & " "
  if options.offset > 0:
    result = result & "OFFSET " & $options.offset & " "
  LOG.debug(result.replace("$", "$$"))

#  select name, sql from sqlite_master where type = 'index' and tbl_name = 'documents' and name LIKE 'json_index_%'
proc prepareSelectIndexesQuery*(options: QueryOptions): string =
  var group = true
  if options.select.len > 0 and options.select[0] == "COUNT(name)":
    result  = "SELECT COUNT(DISTINCT name) "
    result = result & "FROM sqlite_master WHERE type = 'index' AND tbl_name = 'documents' "
    group = false
  else:
    result = "SELECT name, sql "
    result = result & "FROM sqlite_master WHERE type = 'index' AND tbl_name = 'documents' "
  if options.single:
    result = result & "AND name = ?"
  if options.like.len > 0:
    if options.like[options.like.len-1] == '*' and options.like[0] != '*':
      result = result & "AND name BETWEEN ? AND ? "
    else:
      result = result & "AND name LIKE ? "
  else:
    result = result & "AND name LIKE 'json_index_%' "
  if options.limit > 0:
    result = result & "LIMIT " & $options.limit & " "
  if options.offset > 0:
    result = result & "OFFSET " & $options.offset & " "
  LOG.debug(result.replace("$", "$$"))

proc prepareJsonDocument*(store:Datastore, doc: Row, options: QueryOptions): JsonNode =
  var raw_tags = store.db.getAllRows(SQL_SELECT_DOCUMENT_TAGS, doc[0])
  var tags = newSeq[JsonNode](0)
  for tag in raw_tags:
    tags.add(%($(tag[0])))
  if doc.len == 1:
    # COUNT(id)
    return %(doc[0].parseInt)
  result = newJObject()
  var count = 0
  var jsondoc = false
  for s in options.select:
    var key = s
    count.inc
    var rawvalue = doc[count-1]
    var value:JsonNode
    if s.contains(" "):
      # documents.id AS id...
      let chunks = s.split(" ")
      key = chunks[chunks.len-1]
    case key:
      of "searchable", "binary":
        continue
      of "content_type":
        if rawvalue == "application/json":
          jsondoc = true
        continue
      else:
        discard
    if rawvalue == "":
      value = newJNull()
    else:
      value = %doc[count-1]
    result[key] = value
  if jsondoc:
    result["data"] = result["data"].getStr().parseJson()
    if options.jsonSelect.len > 0:
      var obj = newJObject()
      for field in options.jsonSelect:
        let keys = field.path.replace("$.", "").split(".")
        let res =  result["data"]{keys}
        if res.isNil:
          obj[field.alias] = newJNull()
        else:
          obj[field.alias] = %res
      result["data"] = obj
  result["tags"] = %tags

proc toPlainText*(s: string): string =
  var str: string
  var json: JsonNode
  var tags = peg"""'<' [^>]+ '>'"""
  var special_chars = peg"""\*\*+ / \_\_+ / \-\-+ / \#\#+ / \+\++ / \~\~+ / \`\`+ """
  try:
    json = s.parseJson()
  except:
    discard
  if not json.isNil:
    if json.kind == JObject:
      # Only process string values
      str = toSeq(json.pairs).filterIt(it.val.kind == JString).mapIt(it.val.getStr).join(" ")
    elif json.kind == JArray:
      # Only process string values
      str = toSeq(json.items).filterIt(it.kind == JString).mapIt(it.getStr).join(" ")
    else:
      str = s
  else:
    str = s
  return str.replace(tags).replace(special_chars)

proc checkIfBinary*(binary:int, contenttype:string): int =
  if binary == -1 and contenttype.isBinary:
    return 1
  else:
    return binary

proc addDocumentSystemTags*(store: Datastore, docid, contenttype: string) =
  var splittype = contenttype.split("/")
  var tags = newSeq[string](0)
  tags.add "$type:"&splittype[0]
  tags.add "$subtype:"&splittype[1]
  var binary = checkIfBinary(-1, contenttype)
  if binary == 1:
    tags.add "$format:binary"
  else:
    tags.add "$format:text"
  for tag in tags:
    store.db.exec(SQL_INSERT_TAG, tag, docid)

proc destroyDocumentSystemTags*(store: Datastore, docid: string) =
  discard store.db.execAffectedRows(SQL_DELETE_DOCUMENT_SYSTEM_TAGS, docid)

proc fail*(code: int, msg: string) =
  LOG.error(msg)
  quit(code)

proc ctHeader*(ct: string): HttpHeaders =
  var h = newHttpHeaders(TAB_HEADERS)
  h["Content-Type"] = ct
  return h

proc ctJsonHeader*(): HttpHeaders =
  return ctHeader("application/json")

proc resError*(code: HttpCode, message: string, trace = ""): LSResponse =
  LOG.warn(message.replace("$", "$$"))
  if trace.len > 0:
    LOG.debug(trace.replace("$", "$$"))
  result.code = code
  result.content = """{"error":"$1"}""" % message
  result.headers = ctJsonHeader()

proc resDocumentNotFound*(id: string): LSResponse =
  resError(Http404, "Document '$1' not found." % id)

proc resTagNotFound*(id: string): LSResponse =
  resError(Http404, "Tag '$1' not found." % id)

proc resIndexNotFound*(id: string): LSResponse =
  resError(Http404, "Index '$1' not found." % id)

proc resStoreNotFound*(id: string): LSResponse =
  resError(Http404, "Store '$1' not found." % id)

proc eWarn*() =
  var e = getCurrentException()
  LOG.warn(e.msg)
  LOG.debug(getStackTrace(e))

proc validate*(req: LSRequest, LS: LiteStore, resource: string, id: string, cb: proc(req: LSRequest, LS: LiteStore, resource: string, id: string):LSResponse): LSResponse =
  if req.reqMethod == HttpPost or req.reqMethod == HttpPut or req.reqMethod == HttpPatch:
    var ct =  ""
    let body = req.body.strip
    if body == "":
      return resError(Http400, "Bad Request: No content specified for document.")
    if req.headers.hasKey("Content-Type"):
      ct = req.headers["Content-Type"]
      case ct:
        of "application/json":
          try:
            discard body.parseJson()
          except:
            return resError(Http400, "Invalid JSON content - $1" % getCurrentExceptionMsg())
        else:
          discard
  return cb(req, LS, resource, id)

#  Created by Joshua Wilson on 27/05/14.
#  Copyright (c) 2014 Joshua Wilson. All rights reserved.
#  https://github.com/neozenith/sqlite-okapi-bm25
#
# This is an extension to the work of "Radford 'rads' Smith"
# found at: https://github.com/rads/sqlite-okapi-bm25
# which is covered by the MIT License
# http://opensource.org/licenses/MIT
# the following code shall also be covered by the same MIT License
proc okapi_bm25f_kb*(pCtx: Pcontext, nVal: int32, apVal: PValueArg) {.cdecl.} =
  var matchinfo = cast[ptr UncheckedArray[int32]](value_blob(apVal[0]))
  # Setting the default values and ignoring argument based inputs so the extra
  # arguments can be the column weights instead.
  if nVal < 2:
    pCtx.result_error("wrong number of arguments to function okapi_bm25_kb(), expected k1 parameter", -1)
  if nVal < 3:
    pCtx.result_error("wrong number of arguments to function okapi_bm25_kb(), expected b parameter", -1);
  let K1 = value_double(apVal[1]) # 1.2
  let B = value_double(apVal[2])  # 0.75
  # For a good explanation fo the maths and how to choose these variables
  # http://stackoverflow.com/a/23161886/622276
  # NOTE: the rearranged order of parameters to match the order presented on
  # SQLite3 FTS3 documentation 'pcxnals' (http://www.sqlite.org/fts3.html#matchinfo)
  let P_OFFSET = 0
  let C_OFFSET = 1
  let X_OFFSET = 2
  let termCount = matchinfo[P_OFFSET].int32
  let colCount = matchinfo[C_OFFSET].int32
  let N_OFFSET = X_OFFSET + 3*termCount*colCount
  let A_OFFSET = N_OFFSET + 1
  let L_OFFSET = A_OFFSET + colCount
  let totalDocs = matchinfo[N_OFFSET].float
  var avgLength:float = 0.0
  var docLength:float = 0.0
  for col in 0..colCount-1:
    avgLength = avgLength + matchinfo[A_OFFSET + col].float
    docLength = docLength + matchinfo[L_OFFSET + col].float
  var epsilon = 1.0 / (totalDocs*avgLength)
  var sum = 0.0;
  for i in 0..termCount-1:
    for col in 0..colCount-1:
      let currentX = X_OFFSET + (3 * col * (i + 1))
      let termFrequency = matchinfo[currentX].float
      let docsWithTerm = matchinfo[currentX + 2].float
      var idf: float = ln((totalDocs - docsWithTerm + 0.5) / (docsWithTerm + 0.5))
      # "...terms appearing in more than half of the corpus will provide negative contributions to the final document score."
      # http://en.wikipedia.org/wiki/Okapi_BM25
      idf = if idf < 0: epsilon else: idf
      var rightSide: float = (termFrequency * (K1 + 1)) / (termFrequency + (K1 * (1 - B + (B * (docLength / avgLength)))))
      rightSide = rightSide+1.0
      # To comply with BM25+ that solves a lower bounding issue where large documents that match are unfairly scored as
      # having similar relevancy as short documents that do not contain as many terms
      # Yuanhua Lv and ChengXiang Zhai. 'Lower-bounding term frequency normalization.' In Proceedings of CIKM'2011, pages 7-16.
      # http://sifaka.cs.uiuc.edu/~ylv2/pub/cikm11-lowerbound.pdf
      let weight:float = if nVal > col+3: value_double(apVal[col+3]) else: 1.0
      sum = sum + (idf * rightSide) * weight
  pCtx.result_double(sum)
