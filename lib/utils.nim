import json, db_sqlite, strutils, pegs, asyncdispatch, asynchttpserver2, times, logging, math, sqlite3
import types, queries, contenttypes

proc dbQuote*(s: string): string =
  result = "'"
  for c in items(s):
    if c == '\'': add(result, "''")
    else: add(result, c)
  add(result, '\'')

proc currentTime*(): string =
  return getTime().getGMTime().format("yyyy-MM-dd'T'hh:mm:ss'Z'")

proc selectDocumentsByTags(tags: string): string =
  var select_tagged = "SELECT document_id FROM tags WHERE tag_id = \""
  result = ""
  for tag in tags.split(','):
    if not tag.match(PEG_TAG):
      raise newException(EInvalidTag, "Invalid tag '$1'" % tag)
    result = result & "AND id IN (" & select_tagged & tag & "\") "
   
proc prepareSelectDocumentsQuery*(options: var QueryOptions): string =
  result = "SELECT "
  if options.search.len > 0:
    if options.select[0] != "COUNT(id)":
      options.select.add("snippet(searchcontents) AS highlight")
      options.select.add("rank(matchinfo(searchcontents, 'pcxnal'), 1.20, 0.75) AS rank")
      options.orderby = "rank DESC"
    result = result & options.select.join(", ")
    result = result & " FROM documents, searchcontents "
    result = result & "WHERE documents.id = searchcontents.document_id "
  else:
    result = result & options.select.join(", ")
    result = result & " FROM documents WHERE 1=1 "
  if options.single:
    result = result & "AND id = ?"
  if options.tags.len > 0:
    result = result & options.tags.selectDocumentsByTags()
  if options.search.len > 0:
    result = result & "AND searchcontents MATCH \"" & options.search & "\" "
  if options.orderby.len > 0 and options.select[0] != "COUNT(id)":
    result = result & "ORDER BY " & options.orderby & " " 
  if options.limit > 0:
    result = result & "LIMIT " & $options.limit & " "
    if options.offset > 0:
      result = result & "OFFSET " & $options.offset & " "
  debug(result)

proc prepareSelectTagsQuery*(options: QueryOptions): string =
  result = "SELECT tag_id, COUNT(document_ID) "
  result = result & "FROM tags "
  if options.single:
    result = result & "WHERE tag_id = ?"
  result = result & "GROUP BY tag_id"
  if options.orderby.len > 0:
    result = result & "ORDER BY " & options.orderby&" " 
  if options.limit > 0:
    result = result & "LIMIT " & $options.limit & " "
  debug(result)

proc prepareJsonDocument*(store:Datastore, doc: TRow, cols:seq[string]): JsonNode =
  var raw_tags = store.db.getAllRows(SQL_SELECT_DOCUMENT_TAGS, doc[0])
  var tags = newSeq[JsonNode](0)
  for tag in raw_tags:
    tags.add(%($(tag[0])))
  if doc.len == 1:
    # COUNT(id)
    return %(doc[0].parseInt)
  var res = newSeq[tuple[key: string, val: JsonNode]](0)
  var count = 0
  for s in cols:
    var key = s
    if s.contains(" "):
      let chunks = s.split(" ")
      key = chunks[chunks.len-1]
    res.add((key, %doc[count]))
    count.inc
  res.add(("tags", %tags))
  return %res

proc stripXml*(s: string): string =
  let pTag = "\\<\\/?[a-zA-Z!$?%][^<>]+\\>".peg
  return s.replace(pTag)

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

proc destroyDocumentSystemTags*(store: Datastore, docid) = 
  store.db.exec(SQL_DELETE_DOCUMENT_SYSTEM_TAGS, docid)

proc fail*(code, msg) =
  stderr.writeln(msg)
  quit(code)

proc resError*(code: HttpCode, message: string, trace = ""): Response =
  warn(message)
  if trace.len > 0:
    debug(trace)
  result.code = code
  result.content = """{"error":"$1"}""" % message
  result.headers = ctJsonHeader()

proc resDocumentNotFound*(id): Response =
  resError(Http404, "Document '$1' not found." % id)

proc okapi_bm25*(pCtx: Pcontext, nVal: int32, apVal: PValueArg) {.cdecl.} =
  var firstElement = value_blob(apVal[0])
  var matchinfo = cast[ptr uarray[int32]](firstElement)
  var searchTextCol = value_int(apVal[1])
  var K1 = if nVal >= 3: value_double(apVal[2]) else: 1.2
  var B = if nVal >= 4: value_double(apVal[3]) else: 0.75
  var P_OFFSET = 0
  var C_OFFSET = 1
  var X_OFFSET = 2
  var termCount = matchinfo[P_OFFSET].int32
  var colCount = matchinfo[C_OFFSET].int32
  var N_OFFSET = X_OFFSET + 3*termCount*colCount
  var A_OFFSET = N_OFFSET + 1
  var L_OFFSET = A_OFFSET + colCount
  var totalDocs = matchinfo[N_OFFSET].float
  var avgLength = matchinfo[A_OFFSET + searchTextCol].float
  var docLength = matchinfo[L_OFFSET + searchTextCol].float
  var sum = 0.0;
  for i in 0..termCount-1:
    var currentX = X_OFFSET + (3 * searchTextCol * (i + 1))
    var termFrequency = matchinfo[currentX].float
    var docsWithTerm = matchinfo[currentX + 2].float
    var idf: float = ln((totalDocs - docsWithTerm + 0.5) / (docsWithTerm + 0.5))
    var rightSide: float = (termFrequency * (K1 + 1)) / (termFrequency + (K1 * (1 - B + (B * (docLength / avgLength)))))
    sum = sum + (idf * rightSide)
  pCtx.result_double(sum)
