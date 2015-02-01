import json, db_sqlite, strutils, pegs, asyncdispatch, asynchttpserver2, times
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
   
proc prepareSelectDocumentsQuery*(options: QueryOptions): string =
  result = "SELECT " & options.select & " "
  if options.search.len > 0:
    result = result & "FROM documents, searchcontents "
    result = result & "WHERE documents.id = searchcontents.document_id "
  else:
    result = result & "FROM documents WHERE 1=1 "
  if options.single:
    result = result & "AND id = ?"
  if options.tags.len > 0:
    result = result & options.tags.selectDocumentsByTags()
  if options.search.len > 0:
    result = result & "AND content MATCH \"" & options.search & "\""
  if options.orderby.len > 0:
    result = result & "ORDER BY " & options.orderby & " " 
  if options.limit > 0:
    result = result & "LIMIT " & $options.limit & " "
    if options.offset > 0:
      result = result & "OFFSET " & $options.offset & " "

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

proc prepareJsonDocument*(store:Datastore, doc: TRow): JsonNode =
  var raw_tags = store.db.getAllRows(SQL_SELECT_DOCUMENT_TAGS, doc[0])
  var tags = newSeq[JsonNode](0)
  for tag in raw_tags:
    tags.add(%($(tag[0])))
  if doc.len == 1:
    # COUNT(id)
    return %(doc[0].parseInt)
  elif doc.len > 6:
    return % [("id", %doc[0]), 
             ("data", %doc[1]), 
             ("created", %doc[5]),
             ("modified", %doc[6]),
             ("tags", %tags)]
  else:
    # data was not retrieved
    return % [("id", %doc[0]), 
             ("created", %doc[4]),
             ("modified", %doc[5]),
             ("tags", %tags)]

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

proc error*(code, msg) =
  stderr.writeln(msg)
  quit(code)

proc resError*(code: HttpCode, message: string): Response =
  result.code = code
  result.content = """{"error":"$1"}""" % message
  result.headers = ctJsonHeader()

proc resDocumentNotFound*(id): Response =
  resError(Http404, "Document '$1' not found." % id)

