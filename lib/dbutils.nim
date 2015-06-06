import 
  x_db_sqlite,
  strutils,
  json

import
  utils,
  types,
  logger,
  queries

proc q(s: string): string =
  if s.isNil: return "NULL"
  result = "'"
  for c in items(s):
    if c == '\'': add(result, "''")
    else: add(result, c)
  add(result, '\'')

proc tagConditions(value = "*", predicate = "*", namespace = "*"): string = 
  var conditions = newSeq[string](0)
  if value != "*":
    conditions.add("value = " & q(value))
  if predicate != "*":
    conditions.add("predicate = " & q(predicate))
  if namespace != "*":
    conditions.add("namespace = " & q(namespace)) 
  return conditions.join(" AND ")

#####

proc prepareMultipleTagConditions(tags: seq[MachineTag]): string =
  var clauses = newSeq[string](0)
  for tag in tags:
    clauses.add("(" & tagConditions(tag.value, tag.predicate, tag.namespace) & ")")
  return clauses.join(" OR ")

# TODO: REWRITE
proc prepareSelectTagsQuery*(options: QueryOptions): string =
  result = "SELECT tag_id, COUNT(document_id) "
  result = result & "FROM tags "
  if options.single:
    result = result & "WHERE tag_id = ?"
  result = result & "GROUP BY tag_id"
  if options.orderby.len > 0:
    result = result & "ORDER BY " & options.orderby&" " 
  if options.limit > 0:
    result = result & "LIMIT " & $options.limit & " "
  LOG.debug(result.replace("$", "$$"))

proc prepareSelectDocumentIdByTag(value: string, predicate = "*", namespace = "*"): string =
  return """
  SELECT document_id FROM tags WHERE value = ?
  AND """ & tagConditions(value, predicate, namespace)

proc prepareSelectDocumentsQuery*(options: var QueryOptions): string =
  result = "SELECT "
  if options.search.len > 0:
    if options.select[0] != "COUNT(docid)":
      let rank = "rank(matchinfo(searchdata, 'pcxnal'), 1.20, 0.75, 5.0, 0.5) AS rank"
      let snippet = "snippet(searchdata, \"<strong>\", \"</strong>\", \"<strong>&hellip;</strong>\", -1, 30) as highlight" 
      options.select.add(snippet)
      options.select.add("ranktable.rank AS rank")
      options.orderby = "rank DESC"
      # Create inner select 
      var innerSelect = "SELECT docid, " & rank & " FROM searchdata WHERE searchdata MATCH '" & options.search.replace("'", "''") & "' "
      if options.tags.len > 0:
        innerSelect = innerSelect & " AND " & options.tags.prepareMultipleTagConditions()
      innerSelect = innerSelect & " ORDER BY rank DESC "
      if options.limit > 0:
        innerSelect = innerSelect & "LIMIT " & $options.limit
        if options.offset > 0:
          innerSelect = innerSelect & " OFFSET " & $options.offset
      result = result & options.select.join(", ")
      result = result & " FROM documents JOIN (" & innerSelect & ") as ranktable USING(docid) JOIN searchdata USING(docid) "
      result = result & "WHERE 1=1 "
    else:
      result = result & options.select.join(", ")
      result = result & " FROM searchdata "
      result = result & "WHERE 1=1 "
      options.orderby = ""
  else:
    result = result & options.select.join(", ")
    result = result & " FROM documents WHERE 1=1 "
  if options.single:
    result = result & "AND id = ?"
  if options.tags.len > 0:
    result = result & " AND " & options.tags.prepareMultipleTagConditions()
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

###

# Is it really needed?
proc getDocsByTag*(store: Datastore, selection = "*", value = "*", predicate = "*", namespace = "*"): seq[TRow] =
  var query = """
  SELECT  """ & selection & """ FROM documents, tags
  WHERE documents.id = tags.document_id 
  AND """ & tagConditions(value, predicate, namespace)
  return store.db.getAllRows(query.sql)

proc deleteDocsByTag*(store: Datastore, value: string, predicate = "*", namespace = "*"): int64 =
  var query = """
  DELETE FROM documents
  WHERE documents.id IN 
  """
  var subquery = prepareSelectDocumentIdByTag(value, predicate, namespace)
  query &= "(" & subquery & ")"
  return store.db.execAffectedRows(query.sql)

proc deleteSearchdataByTag*(store: Datastore, value: string, predicate = "*", namespace = "*"): int64 =
  var query = """
  DELETE FROM searchdata
  WHERE id IN 
  """
  var subquery = prepareSelectDocumentIdByTag(value, predicate, namespace)
  query &= "(" & subquery & ")"
  return store.db.execAffectedRows(query.sql)

proc deleteTagsByTag*(store: Datastore, value: string, predicate = "*", namespace = "*"): int64 =
  var query = """
  DELETE FROM tags
  WHERE document_id IN 
  """
  var subquery = prepareSelectDocumentIdByTag(value, predicate, namespace)
  query &= "(" & subquery & ")"
  return store.db.execAffectedRows(query.sql)

proc addDocumentSystemTags*(store: Datastore, docid, contenttype: string) =
  let splittype = contenttype.split("/")
  let binary = checkIfBinary(-1, contenttype)
  var format: string
  if binary == 1:
    format = "binary"
  else:
    format = "text"
  store.db.exec(SQL_INSERT_TAG, docid, splittype[0], SYS_TYPE_PREDICATE, SYS_NAMESPACE)
  store.db.exec(SQL_INSERT_TAG, docid, splittype[1], SYS_SUBTYPE_PREDICATE, SYS_NAMESPACE)
  store.db.exec(SQL_INSERT_TAG, docid, format, SYS_FORMAT_PREDICATE, SYS_NAMESPACE)

proc destroyDocumentSystemTags*(store: Datastore, docid: string): int64 = 
  return store.db.execAffectedRows(SQL_DELETE_DOCUMENT_SYSTEM_TAGS, docid)

proc rowToTag(TRow, cols: seq[string]): MachineTag = 
  var i = -1
  for col in cols:
    i.inc
    case col:
      of "namespace":
        result.namespace = TRow[i]
      of "predicate":
        result.predicate = TRow[i]
      of "value":
        result.value = TRow[i]
      else: 
        discard

proc rowToTagCount(row: TRow, cols: seq[string] = @["namespace", "predicate", "value"]): tuple[tag:MachineTag, count:int] = 
  var i = -1
  for col in cols:
    i.inc
    case col:
      of "namespace":
        result.tag.namespace = row[i]
      of "predicate":
        result.tag.predicate = row[i]
      of "value":
        result.tag.value = row[i]
      of "count":
        result.count = row[i].parseInt
      else: 
        discard

proc prepareJsonDocumentTags*(tags: seq[TRow], cols: seq[string] = @["namespace", "predicate", "value"]): JsonNode =
  result = newJObject()
  var namespace = ""
  for row in tags:
    let tag = row.rowToTag(cols)
    if tag.namespace != namespace:
      # Create new object for namespace
      namespace = tag.namespace
      result.add(namespace, newJObject())
    result[namespace].add(tag.predicate, %tag.value)

proc prepareJsonTagCounts*(tags: seq[TRow], cols: seq[string] = @["namespace", "predicate", "value"]): JsonNode =
  result = newJObject()
  var namespace = ""
  var predicate = ""
  for row in tags:
    let tc = row.rowToTagCount(cols)
    if tc.tag.namespace != namespace:
      # Create new object for namespace
      namespace = tc.tag.namespace
      result.add(namespace, newJObject())
    if tc.tag.predicate != predicate:
      # Create new object for predicate
      predicate = tc.tag.predicate
      result[namespace].add(predicate, newJObject())
    result[namespace][predicate].add(tc.tag.value, %tc.count)

proc prepareJsonDocument*(store:Datastore, doc: TRow, cols:seq[string]): JsonNode =
  let raw_tags = store.db.getAllRows(SQL_SELECT_DOCUMENT_TAGS, doc[0])
  let tags = raw_tags.prepareJsonDocumentTags()
  if doc.len == 1:
    # COUNT(id)
    return %(doc[0].parseInt)
  var res = newSeq[tuple[key: string, val: JsonNode]](0)
  var count = 0
  for s in cols:
    var key = s
    count.inc
    if key == "searchable" or key == "binary" or key == "content_type":
      continue
    if s.contains(" "):
      # documents.id AS id...
      let chunks = s.split(" ")
      key = chunks[chunks.len-1]
    var value:JsonNode
    if doc[count-1] == "":
      value = newJNull()
    else:
      value = %doc[count-1]
    res.add((key, value))
  res.add(("tags", tags))
  return %res

