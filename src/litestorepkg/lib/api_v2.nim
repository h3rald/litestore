import
  asynchttpserver,
  asyncdispatch,
  strutils,
  cgi,
  strtabs,
  pegs,
  json,
  os,
  times
import
  types,
  contenttypes,
  core,
  utils,
  logger

# Helper procs

proc orderByClauses*(str: string): string =
  var clauses = newSeq[string]()
  var fragments = str.split(",")
  for f in fragments:
    var matches = @["", ""]
    if f.find(peg"{[-+ ]} {(id / created / modified)}", matches) != -1:
      if matches[0] == "-":
        clauses.add("$1 DESC" % matches[1])
      else:
        clauses.add("$1 ASC" % matches[1])
  return clauses.join(", ")

proc parseQueryOption*(fragment: string, options: var QueryOptions) =
  var pair = fragment.split('=')
  if pair.len < 2 or pair[1] == "":
    raise newException(EInvalidRequest, "Invalid query string fragment '$1'" % fragment)
  try:
    pair[1] = pair[1].replace("+", "%2B").decodeURL
  except:
    raise newException(EInvalidRequest, "Unable to decode query string fragment '$1'" % fragment)
  case pair[0]:
    of "search":
      options.search = pair[1]
    of "tags":
      options.tags = pair[1]
    of "limit":
      try:
        options.limit = pair[1].parseInt
      except:
        raise newException(EInvalidRequest, "Invalid limit value: $1" % getCurrentExceptionMsg())
    of "offset":
      try:
        options.offset = pair[1].parseInt
      except:
        raise newException(EInvalidRequest, "Invalid offset value: $1" % getCurrentExceptionMsg())
    of "sort":
      let orderby = pair[1].orderByClauses()
      if orderby != "":
        options.orderby = orderby
      else:
        raise newException(EInvalidRequest, "Invalid sort value: $1" % pair[1])
    else:
      return

proc parseQueryOptions*(querystring: string, options: var QueryOptions) =
  var fragments = querystring.split('&')
  for f in fragments:
    f.parseQueryOption(options)

proc validate*(req: LSRequest, LS: LiteStore, resource: string, id: string, cb: proc(req: LSRequest, LS: LiteStore, resource: string, id: string):LSResponse): LSResponse =
  if req.reqMethod == HttpPost or req.reqMethod == HttpPut or req.reqMethod == HttpPatch:
    var ct =  ""
    let body = req.body.strip
    if body == "":
      return resError(Http400, "Bad request: No content specified for document.")
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

proc applyPatchOperation*(tags: var seq[string], op: string, path: string, value: string): bool =
  var matches = @[""]
  if path.find(peg"^\/tags\/{\d+}$", matches) == -1:
    raise newException(EInvalidRequest, "cannot patch path '$1'" % path)
  let index = matches[0].parseInt
  LOG.debug("- PATCH -> $1 tag index '$2' - Total tags: $3." % [op, $index, $tags.len])
  case op:
    of "remove":
      let tag = tags[index]
      if not tag.startsWith("$"):
        tags[index] = "" # Not removing element, otherwise subsequent indexes won't work!
      else:
        raise newException(EInvalidRequest, "Cannot remove system tag: $1" % tag)
    of "add":
      if value.match(PEG_USER_TAG):
        tags.insert(value, index)
      else:
        if value.strip == "":
          raise newException(EInvalidRequest, "tag not specified." % value)
        else:
          raise newException(EInvalidRequest, "invalid tag: $1" % value)
    of "replace":
      if value.match(PEG_USER_TAG):
        if tags[index].startsWith("$"):
          raise newException(EInvalidRequest, "Cannot replace system tag: $1" % tags[index])
        else:
          tags[index] = value
      else:
        if value.strip == "":
          raise newException(EInvalidRequest, "tag not specified." % value)
        else:
          raise newException(EInvalidRequest, "invalid tag: $1" % value)
    of "test":
      if tags[index] != value:
        return false
    else:
      raise newException(EInvalidRequest, "invalid operation: $1" % op)
  return true

# Low level procs

proc getRawDocument*(LS: LiteStore, id: string, options = newQueryOptions()): LSResponse =
  let doc = LS.store.retrieveRawDocument(id, options)
  result.headers = ctJsonHeader()
  if doc == "":
    result = resDocumentNotFound(id)
  else:
    result.content = doc
    result.code = Http200

proc getDocument*(LS: LiteStore, id: string, options = newQueryOptions()): LSResponse =
  let doc = LS.store.retrieveDocument(id, options)
  if doc.data == "":
    result = resDocumentNotFound(id)
  else:
    result.headers = doc.contenttype.ctHeader
    result.content = doc.data
    result.code = Http200

proc deleteDocument*(LS: LiteStore, id: string): LSResponse =
  let doc = LS.store.retrieveDocument(id)
  if doc.data == "":
    result = resDocumentNotFound(id)
  else:
    try:
      let res = LS.store.destroyDocument(id)
      if res == 0:
        result = resError(Http500, "Unable to delete document '$1'" % id)
      else:
        result.headers = newHttpHeaders(TAB_HEADERS)
        result.headers["Content-Length"] = "0"
        result.content = ""
        result.code = Http204
    except:
      result = resError(Http500, "Unable to delete document '$1'" % id)

proc getRawDocuments*(LS: LiteStore, options: QueryOptions = newQueryOptions()): LSResponse =
  var options = options
  let t0 = cpuTime()
  let docs = LS.store.retrieveRawDocuments(options)
  let orig_limit = options.limit
  let orig_offset = options.offset
  options.limit = 0
  options.offset = 0
  options.select = @["COUNT(docid)"]
  let total = LS.store.retrieveRawDocuments(options)[0].num
  if docs.len == 0:
    result = resError(Http404, "No documents found.")
  else:
    var content = newJObject()
    if options.folder != "":
      content["folder"] = %(options.folder)
    if options.search != "":
      content["search"] = %(options.search.decodeURL)
    if options.tags != "":
      content["tags"] = newJArray()
      for tag in options.tags.replace("+", "%2B").decodeURL.split(","):
        content["tags"].add(%tag)
    if orig_limit > 0:
      content["limit"] = %orig_limit
      if orig_offset > 0:
        content["offset"] = %orig_offset
    if options.orderby != "":
      content["sort"] = %options.orderby
    content["total"] = %total
    content["execution_time"] = %(cputime()-t0)
    content["results"] = docs
    result.headers = ctJsonHeader()
    result.content = content.pretty
    result.code = Http200

proc getInfo*(LS: LiteStore): LSResponse =
  let info = LS.store.retrieveInfo()
  let version = info[0]
  let total_documents = info[1]
  let total_tags = LS.store.countTags()
  let tags = LS.store.retrieveTagsWithTotals()
  var content = newJObject()
  content["version"] = %(LS.appname & " v" & LS.appversion)
  content["datastore_version"] = %version
  content["size"] = %($((LS.file.getFileSize().float/(1024*1024)).formatFloat(ffDecimal, 2)) & " MB")
  content["read_only"] = %LS.readonly
  content["log_level"] = %LS.loglevel
  if LS.directory.len == 0:
    content["directory"] = newJNull()
  else:
    content["directory"] = %LS.directory
  content["mount"] = %LS.mount
  content["total_documents"] = %total_documents
  content["total_tags"] = %total_tags
  content["tags"] = tags
  result.headers = ctJsonHeader()
  result.content = content.pretty
  result.code = Http200

proc postDocument*(LS: LiteStore, body: string, ct: string, folder=""): LSResponse =
  if not folder.isFolder:
    return resError(Http400, "Invalid folder specified when creating document: $1" % folder)
  try:
    var doc = LS.store.createDocument(folder, body, ct)
    if doc != "":
      result.headers = ctJsonHeader()
      result.content = doc
      result.code = Http201
    else:
      result = resError(Http500, "Unable to create document.")
  except:
    result = resError(Http500, "Unable to create document.")

proc putDocument*(LS: LiteStore, id: string, body: string, ct: string): LSResponse =
  if id.isFolder:
    return resError(Http400, "Invalid ID '$1' (Document IDs cannot end with '/')." % id)
  let doc = LS.store.retrieveDocument(id)
  if doc.data == "":
    # Create a new document
    var doc = LS.store.createDocument(id, body, ct)
    if doc != "":
      result.headers = ctJsonHeader()
      result.content = doc
      result.code = Http201
    else:
      result = resError(Http500, "Unable to create document.")
  else:
    # Update existing document
    try:
      var doc = LS.store.updateDocument(id, body, ct)
      if doc != "":
        result.headers = ctJsonHeader()
        result.content = doc
        result.code = Http200
      else:
        result = resError(Http500, "Unable to update document '$1'." % id)
    except:
      result = resError(Http500, "Unable to update document '$1'." % id)

proc patchDocument*(LS: LiteStore, id: string, body: string): LSResponse =
  var apply = true
  let jbody = body.parseJson
  if jbody.kind != JArray:
    return resError(Http400, "Bad request: PATCH request body is not an array.")
  var options = newQueryOptions()
  options.select = @["documents.id AS id", "created", "modified"]
  let doc = LS.store.retrieveRawDocument(id, options)
  if doc == "":
    return resDocumentNotFound(id)
  let jdoc = doc.parseJson
  var tags = newSeq[string](0)
  for tag in jdoc["tags"].items:
    tags.add(tag.str)
  var c = 1
  for item in jbody.items:
    if item.hasKey("op") and item.hasKey("path"):
      if not item.hasKey("value"):
        item["value"] = %""
      try:
        apply = applyPatchOperation(tags, item["op"].str, item["path"].str, item["value"].str)
        if not apply:
          break
      except:
        return resError(Http400, "Bad request - $1" % getCurrentExceptionMsg())
    else:
        return resError(Http400, "Bad request: patch operation #$1 is malformed." % $c)
    c.inc
  if apply:
    try:
      for t1 in jdoc["tags"].items:
        discard LS.store.destroyTag(t1.str, id, true)
      for t2 in tags:
        if t2 != "":
          LS.store.createTag(t2, id, true)
    except:
      return resError(Http500, "Unable to patch document '$1' - $2" % [id, getCurrentExceptionMsg()])
  return LS.getRawDocument(id)

# Main routing

proc options*(req: LSRequest, LS: LiteStore, resource: string, id = ""): LSResponse =
  case resource:
    of "info":
      if id != "":
        return resError(Http404, "Info '$1' not found." % id)
      else:
        result.code = Http200
        result.content = ""
        result.headers = newHttpHeaders(TAB_HEADERS)
        result.headers["Allow"] = "GET,OPTIONS"
        result.headers["Access-Control-Allow-Methods"] = "GET,OPTIONS"
    of "dir":
      result.code = Http200
      result.content = ""
      result.headers = newHttpHeaders(TAB_HEADERS)
      result.headers["Allow"] = "GET,OPTIONS"
      result.headers["Access-Control-Allow-Methods"] = "GET,OPTIONS"
    of "docs":
      var folder: string
      if id.isFolder:
        folder = id
      if not folder.len == 0:
        result.code = Http200
        result.content = ""
        if LS.readonly:
          result.headers = newHttpHeaders(TAB_HEADERS)
          result.headers["Allow"] = "HEAD,GET,OPTIONS"
          result.headers["Access-Control-Allow-Methods"] = "HEAD,GET,OPTIONS"
        else:
          result.headers = newHttpHeaders(TAB_HEADERS)
          result.headers["Allow"] = "HEAD,GET,OPTIONS,POST,PUT"
          result.headers["Access-Control-Allow-Methods"] = "HEAD,GET,OPTIONS,POST,PUT"
      elif id != "":
        result.code = Http200
        result.content = ""
        if LS.readonly:
          result.headers = newHttpHeaders(TAB_HEADERS)
          result.headers["Allow"] = "HEAD,GET,OPTIONS"
          result.headers["Access-Control-Allow-Methods"] = "HEAD,GET,OPTIONS"
        else:
          result.headers = newHttpHeaders(TAB_HEADERS)
          result.headers["Allow"] = "HEAD,GET,OPTIONS,PUT,PATCH,DELETE"
          result.headers["Allow-Patch"] = "application/json-patch+json"
          result.headers["Access-Control-Allow-Methods"] = "HEAD,GET,OPTIONS,PUT,PATCH,DELETE"
      else:
        result.code = Http200
        result.content = ""
        if LS.readonly:
          result.headers = newHttpHeaders(TAB_HEADERS)
          result.headers["Allow"] = "HEAD,GET,OPTIONS"
          result.headers["Access-Control-Allow-Methods"] = "HEAD,GET,OPTIONS"
        else:
          result.headers = newHttpHeaders(TAB_HEADERS)
          result.headers["Allow"] = "HEAD,GET,OPTIONS,POST"
          result.headers["Access-Control-Allow-Methods"] = "HEAD,GET,OPTIONS,POST"
    else:
      discard # never happens really.

proc head*(req: LSRequest, LS: LiteStore, resource: string, id = ""): LSResponse =
  var options = newQueryOptions()
  options.select = @["documents.id AS id", "created", "modified"]
  if id.isFolder:
    options.folder = id
  try:
    parseQueryOptions(req.url.query, options);
    if id != "" and options.folder == "":
      result = LS.getRawDocument(id, options)
      result.content = ""
    else:
      result = LS.getRawDocuments(options)
      result.content = ""
  except:
    return resError(Http400, "Bad request - $1" % getCurrentExceptionMsg())

proc get*(req: LSRequest, LS: LiteStore, resource: string, id = ""): LSResponse =
  let  id = id.decodeURL
  case resource:
    of "docs":
      var options = newQueryOptions()
      if id.isFolder:
        options.folder = id
      if req.url.query.contains("contents=false"):
        options.select = @["documents.id AS id", "created", "modified"]
      try:
        parseQueryOptions(req.url.query, options);
        if id != "" and options.folder == "":
          if req.url.query.contains("raw=true") or req.headers.hasKey("Accept") and req.headers["Accept"] == "application/json":
            return LS.getRawDocument(id, options)
          else:
            return LS.getDocument(id, options)
        else:
          return LS.getRawDocuments(options)
      except:
        return resError(Http500, "Internal Server Error - $1" % getCurrentExceptionMsg())
    of "info":
      if id != "":
        return resError(Http404, "Info '$1' not found." % id)
      return LS.getInfo()
    else:
      discard # never happens really.


proc post*(req: LSRequest, LS: LiteStore, resource: string, id = ""): LSResponse =
  var ct = "text/plain"
  if req.headers.hasKey("Content-Type"):
    ct = req.headers["Content-Type"]
  return LS.postDocument(req.body.strip, ct, id)

proc put*(req: LSRequest, LS: LiteStore, resource: string, id = ""): LSResponse =
  if id != "":
    var ct = "text/plain"
    if req.headers.hasKey("Content-Type"):
      ct = req.headers["Content-Type"]
    return LS.putDocument(id, req.body.strip, ct)
  else:
    return resError(Http400, "Bad request: document ID must be specified in PUT requests.")

proc delete*(req: LSRequest, LS: LiteStore, resource: string, id = ""): LSResponse =
  if id != "":
    return LS.deleteDocument(id)
  else:
    return resError(Http400, "Bad request: document ID must be specified in DELETE requests.")

proc patch*(req: LSRequest, LS: LiteStore, resource: string, id = ""): LSResponse =
  if id != "":
    return LS.patchDocument(id, req.body)
  else:
    return resError(Http400, "Bad request: document ID must be specified in PATCH requests.")

proc serveFile*(req: LSRequest, LS: LiteStore, id: string): LSResponse =
  let path = LS.directory / id
  var reqMethod = $req.reqMethod
  if req.headers.hasKey("X-HTTP-Method-Override"):
    reqMethod = req.headers["X-HTTP-Method-Override"]
  case reqMethod.toUpperAscii:
    of "OPTIONS":
      return validate(req, LS, "dir", id, options)
    of "GET":
      if path.fileExists:
        try:
          let contents = path.readFile
          let parts = path.splitFile
          if CONTENT_TYPES.hasKey(parts.ext):
            result.headers = CONTENT_TYPES[parts.ext].ctHeader
          else:
            result.headers = ctHeader("text/plain")
          result.content = contents
          result.code = Http200
        except:
          return resError(Http500, "Unable to read file '$1'." % path)
      else:
        return resError(Http404, "File '$1' not found." % path)
    else:
      return resError(Http405, "Method not allowed: $1" % $req.reqMethod)

proc route*(req: LSRequest, LS: LiteStore, resource = "docs", id = ""): LSResponse =
  var reqMethod = $req.reqMethod
  if req.headers.hasKey("X-HTTP-Method-Override"):
    reqMethod = req.headers["X-HTTP-Method-Override"]
  case reqMethod.toUpperAscii:
    of "POST":
      if LS.readonly:
        return resError(Http405, "Method not allowed: $1" % $req.reqMethod)
      return validate(req, LS, resource, id, post)
    of "PUT":
      if LS.readonly:
        return resError(Http405, "Method not allowed: $1" % $req.reqMethod)
      return validate(req, LS, resource, id, put)
    of "DELETE":
      if LS.readonly:
        return resError(Http405, "Method not allowed: $1" % $req.reqMethod)
      return validate(req, LS, resource, id, delete)
    of "HEAD":
      return validate(req, LS, resource, id, head)
    of "OPTIONS":
      return validate(req, LS, resource, id, options)
    of "GET":
      return validate(req, LS, resource, id, get)
    of "PATCH":
      if LS.readonly:
        return resError(Http405, "Method not allowed: $1" % $req.reqMethod)
      return validate(req, LS, resource, id, patch)
    else:
      return resError(Http405, "Method not allowed: $1" % $req.reqMethod)
