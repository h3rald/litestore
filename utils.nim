import json, db_sqlite, strutils, pegs
import types, queries, contenttypes

let PEG_TAG* = peg"""
^\$? [a-zA-Z0-9_-?~:.@#^%!]+$
"""

let PEG_USER_TAG* = peg"""
^[a-zA-Z0-9_-?~:.@#^%!]+$
"""
proc dbQuote*(s: string): string =
  result = "'"
  for c in items(s):
    if c == '\'': add(result, "''")
    else: add(result, c)
  add(result, '\'')

proc selectDocumentsByTags(tags: string): string =
  var select_tagged = "SELECT document_id FROM tags WHERE tag_id = \""
  result = ""
  for tag in tags.split(','):
    if not tag.match(PEG_TAG):
      raise newException(EInvalidTag, "Invalid tag '$1'" % tag)
    result = result & "AND id IN (" & select_tagged & tag & "\") "
   
proc validOrderBy*(clause):bool =
  return clause == "id ASC" or 
         clause == "id DESC" or
         clause == "created ASC" or
         clause == "created DESC" or
         clause == "modified ASC" or
         clause == "modified DESC"

proc prepareSelectDocumentsQuery*(options: QueryOptions): string =
  result = "SELECT * "
  if options.search.len > 0:
    result = result & "FROM documents, searchcontents "
    result = result & "WHERE documents.id = searchcontents.document_id "
  else:
    result = result & "FROM documents "
  if options.single:
    result = result & "AND id = ?"
  if options.tags.len > 0:
    result = result & options.tags.selectDocumentsByTags()
  if options.search.len > 0:
    result = result & "AND content MATCH \"" & options.search & "\""
  if options.orderby.validOrderBy():
    result = result & "ORDER BY " & options.orderby & " " 
  if options.limit > 0:
    result = result & "LIMIT " & $options.limit & " "
  echo result

proc prepareSelectTagsQuery*(options: QueryOptions): string =
  result = "SELECT tag_id, COUNT(document_ID) "
  result = result & "FROM tags "
  if options.single:
    result = result & "WHERE tag_id = ?"
  result = result & "GROUP BY tag_id"
  if options.orderby.validOrderBy():
    result = result & "ORDER BY " & options.orderby&" " 
  if options.limit > 0:
    result = result & "LIMIT " & $options.limit & " "

proc prepareJsonDocument*(store:Datastore, doc: TRow): JsonNode =
  var raw_tags = store.db.getAllRows(SQL_SELECT_DOCUMENT_TAGS, doc[0])
  var tags = newSeq[JsonNode](0)
  for tag in raw_tags:
    tags.add(%($(tag[0])))
  return %[("id", %doc[0]), 
             ("data", %doc[1]), 
             ("created", %doc[5]),
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

proc deleteDocumentSystemTags*(store: Datastore, docid) = 
  store.db.exec(SQL_DELETE_DOCUMENT_SYSTEM_TAGS, docid)

