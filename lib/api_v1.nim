import 
  x_asynchttpserver,
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
  core,
  utils,
  logger


# Helper procs

proc orderByClause(clause: string): string =
  var matches = @["", ""]
  if clause.find(peg"{[-+ ]} {(id / created / modified)}", matches) != -1:
    if matches[0] == "-":
      return "$1 DESC" % matches[1]
    else:
      return "$1 ASC" % matches[1]
  else:
    return ""

proc parseQueryOption(fragment: string, options: var QueryOptions) =
  var pair = fragment.split('=')
  if pair.len < 2 or pair[1] == "":
    raise newException(EInvalidRequest, "Invalid query string fragment '$1'" % fragment)
  try:
    pair[1] = pair[1].decodeURL
  except:
    raise newException(EInvalidRequest, "Unable to decode query string fragment '$1'" % fragment)
  case pair[0]:
    of "search":
      options.search = pair[1]
    of "limit":
      try:
        options.limit = pair[1].parseInt
      except:
        raise newException(EInvalidRequest, "Invalid limit value: $1" % pair[1]) 
    of "offset":
      try:
        options.offset = pair[1].parseInt
      except:
        raise newException(EInvalidRequest, "Invalid offset value: $1" % pair[1])
    of "sort":
      let orderby = pair[1].orderByClause()
      if orderby != "":
        options.orderby = orderby
      else:
        raise newException(EInvalidRequest, "Invalid sort value: $1" % pair[1])
    of "contents", "raw":
      discard
    else:
      # Process tags
      var tag: MachineTag
      var matches: array[0..1, string]
      if pair[0].match(PEG_NAMESPACE_PREDICATE, matches):
        tag.value = pair[1]
        tag.namespace = matches[0]
        tag.predicate = matches[1]
        options.tags.add(tag)
      else:
        raise newException(EInvalidRequest, "Invalid option or tag: $1" % pair[0])

proc parseQueryOptions(querystring: string, options: var QueryOptions) =
  var fragments = querystring.split(peg"[&;]")
  for f in fragments:
    f.parseQueryOption(options)


proc validate(req: Request, LS: LiteStore, resource: string, id: string, cb: proc(req: Request, LS: LiteStore, resource: string, id: string):Response): Response = 
  if req.reqMethod == "POST" or req.reqMethod == "PUT" or req.reqMethod == "PATCH":
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
            return resExError(Http400, "Invalid JSON content - $1")
        else:
          discard
  return cb(req, LS, resource, id)

proc applyPatchOperation(tags: var JsonNode, op: string, path: string, value: string): bool =
  var matches: array[0..1, string]
  if not path.match(PEG_TAG_PATH, matches):
    raise newException(EInvalidRequest, "Cannot patch path '$1' " % path)
  var tag: MachineTag
  tag.namespace = matches[0]
  tag.predicate = matches[1]
  if tag.namespace != nil and not tag.namespace.match(PEG_NAMESPACE):
    raise newException(EInvalidRequest, "Invalid tag namespace: $1" % tag.namespace)
  if tag.predicate != nil and not tag.predicate.match(PEG_PREDICATE):
    raise newException(EInvalidRequest, "Invalid tag predicate: $1" % tag.predicate)
  case op:
    of "remove":
      if tag.namespace != nil:
        if tag.namespace != SYS_NAMESPACE:
          if tag.predicate != nil:
            tags[tag.namespace].delete(tag.predicate)
          else:
            tags.delete(tag.namespace)
        else:
          raise newException(EInvalidRequest, "Cannot remove system tag: $1" % path)
      else:
        raise newException(EInvalidRequest, "No tag path specified.")
    of "add":
      if tag.namespace != nil:
        if tag.namespace != SYS_NAMESPACE:
          if tag.predicate != nil:
            if tags[tag.namespace] == nil:
              tags.add(tag.namespace, newJObject())
            tags[tag.namespace].add(tag.predicate, %value)
          else:
            let jvalue = value.parseJson()
            for pd, val in jvalue.pairs:
              if not pd.match(PEG_PREDICATE):
                raise newException(EInvalidRequest, "Invalid tag predicate: $1" % pd)
              tags[tag.namespace].add(pd, val)
        else:
          raise newException(EInvalidRequest, "Cannot add system tag: $1" % path)
      else:
        let jvalue = value.parseJson()
        for ns, val in jvalue.pairs:
          if not ns.match(PEG_NAMESPACE):
            raise newException(EInvalidRequest, "Invalid tag namespace: $1" % ns)
          tags.add(ns, val)
    of "replace":
      if tag.namespace != nil:
        if tag.namespace != SYS_NAMESPACE:
          if tag.predicate != nil:
            tags[tag.namespace][tag.predicate] = %value
          else:
            tags[tag.namespace] = %value
        else:
          raise newException(EInvalidRequest, "Cannot replace system tag: $1" % path)
      else:
        raise newException(EInvalidRequest, "No tag path specified.")
    of "test":
      if tag.namespace != nil:
        if tag.predicate != nil:
          if tags[tag.namespace][tag.predicate] == %value:
            return true
          else:
            return false
        else:
          if tags[tag.namespace] == %value:
            return true
          else:
            return false
      else:
        raise newException(EInvalidRequest, "No tag path specified.")
    else:
      raise newException(EInvalidRequest, "invalid operation: $1" % op)
  return true

# Low level procs

proc getRawDocument(LS: LiteStore, id: string, options = newQueryOptions()): Response =
  let doc = LS.store.retrieveRawDocument(id, options)
  result.headers = ctJsonHeader()
  if doc == "":
    result = resDocumentNotFound(id)
  else:
    result.content = doc
    result.code = Http200

proc getDocument(LS: LiteStore, id: string, options = newQueryOptions()): Response =
  let doc = LS.store.retrieveDocument(id, options)
  if doc.data == "":
    result = resDocumentNotFound(id)
  else:
    result.headers = doc.contenttype.ctHeader
    result.content = doc.data
    result.code = Http200

proc deleteDocument(LS: LiteStore, id: string): Response =
  let doc = LS.store.retrieveDocument(id)
  if doc.data == "":
    result = resDocumentNotFound(id)
  else:
    try:
      let res = LS.store.destroyDocument(id)
      if res == 0:
        result = resError(Http500, "Unable to delete document '$1'" % id)
      else:
        result.headers = TAB_HEADERS.newStringTable
        result.headers["Content-Length"] = "0"
        result.content = ""
        result.code = Http204
    except:
      result = resExError(Http500, "Unable to delete document '$1'" % id)

proc getRawDocuments(LS: LiteStore, options: QueryOptions = newQueryOptions()): Response =
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
    if options.search != "":
      content["search"] = %(options.search.decodeURL)
    if options.tags.len != 0:
      content["tags"] = %options.tags
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

proc getInfo(LS: LiteStore): Response =
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
  if LS.directory == nil: 
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

proc postDocument(LS: LiteStore, body: string, ct: string): Response =
  try:
    var doc = LS.store.createDocument("", body, ct)
    if doc != "":
      result.headers = ctJsonHeader()
      result.content = doc
      result.code = Http201
    else:
      result = resError(Http500, "Unable to create document.")
  except:
    result = resExError(Http500, "Unable to create document.")

proc putDocument(LS: LiteStore, id: string, body: string, ct: string): Response =
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
      result = resExError(Http500, "Unable to update document '$1'." % id)

# TODO: Testing (especially when modifying entire objects)
proc patchDocument(LS: LiteStore, id: string, body: string): Response =
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
  var tags = jdoc["tags"]
  var c = 1
  for item in jbody.items:
    if item.hasKey("op") and item.hasKey("path"):
      if not item.hasKey("value"):
        item["value"] = %""
      try:
        apply = applyPatchOperation(tags, item["op"].str, item["path"].str, item["value"].str)
      except:
        return resExError(Http400, "Bad request - ")
    else:
        return resError(Http400, "Bad request: patch operation #$1 is malformed." % $c)
    c.inc
  if apply:
    try:
      LS.store.begin()
      # Destroy all namespaces
      for ns, nsval in jdoc["tags"].pairs:
        discard LS.store.destroyTags(documentid = id, namespace = ns, system = true)
      # Recreate all tags
      for ns, nsval in jdoc["tags"].pairs:
        for pd, val in nsval.pairs:
          if val.kind == JString:
            LS.store.createTag(namespace = ns, predicate = pd, value = val.getStr, documentid = id, system = true)
          else:
            raise newException(EInvalidRequest, "Invalid value for tag $1:$2 - $3" % [ns, pd, val.getStr])
      LS.store.commit()
    except:
      LS.store.rollback()
      return resExError(Http500, "Unable to patch document '$1' - " % id) 
  return LS.getRawDocument(id)

# Main routing

proc options(req: Request, LS: LiteStore, resource: string, id = ""): Response =
  case resource:
    of "info":
      if id != "":
        return resError(Http404, "Info '$1' not found." % id)
      else:
        result.code = Http200
        result.content = ""
        result.headers = TAB_HEADERS.newStringTable
        result.headers["Allow"] = "GET,OPTIONS"
        result.headers["Access-Control-Allow-Methods"] = "GET,OPTIONS"
    of "docs":
      if id != "":
        result.code = Http200
        result.content = ""
        if LS.readonly:
          result.headers = TAB_HEADERS.newStringTable
          result.headers["Allow"] = "HEAD,GET,OPTIONS"
          result.headers["Access-Control-Allow-Methods"] = "HEAD,GET,OPTIONS"
        else:
          result.headers = TAB_HEADERS.newStringTable
          result.headers["Allow"] = "HEAD,GET,OPTIONS,PUT,PATCH,DELETE"
          result.headers["Allow-Patch"] = "application/json-patch+json"
          result.headers["Access-Control-Allow-Methods"] = "HEAD,GET,OPTIONS,PUT,PATCH,DELETE"
      else:
        result.code = Http200
        result.content = ""
        if LS.readonly:
          result.headers = TAB_HEADERS.newStringTable
          result.headers["Allow"] = "HEAD,GET,OPTIONS"
          result.headers["Access-Control-Allow-Methods"] = "HEAD,GET,OPTIONS"
        else:
          result.headers = TAB_HEADERS.newStringTable
          result.headers["Allow"] = "HEAD,GET,OPTIONS,POST"
          result.headers["Access-Control-Allow-Methods"] = "HEAD,GET,OPTIONS,POST"
    else:
      discard # never happens really.

proc head(req: Request, LS: LiteStore, resource: string, id = ""): Response =
  var options = newQueryOptions()
  options.select = @["documents.id AS id", "created", "modified"]
  try:
    parseQueryOptions(req.url.query, options);
    if id != "":
      result = LS.getRawDocument(id, options)
      result.content = ""
    else:
      result = LS.getRawDocuments(options)
      result.content = ""
  except:
    return resExError(Http400, "Bad request - ")

proc get(req: Request, LS: LiteStore, resource: string, id = ""): Response =
  let  id = id.decodeURL
  case resource:
    of "docs":
      var options = newQueryOptions()
      if req.url.query.contains("contents=false"):
        options.select = @["documents.id AS id", "created", "modified"]
      try:
        parseQueryOptions(req.url.query, options);
        if id != "":
          if req.url.query.contains("raw=true") or req.headers["Accept"] == "application/json":
            return LS.getRawDocument(id, options)
          else:
            return LS.getDocument(id, options)
        else:
          return LS.getRawDocuments(options)
      except EInvalidRequest:
        return resExError(Http400, "Bad request - ")
      except:
        return resExError(Http500, "Internal Server Error - $1")
    of "info":
      if id != "":
        return resError(Http404, "Info '$1' not found." % id)
      return LS.getInfo()
    else:
      discard # never happens really.


proc post(req: Request, LS: LiteStore, resource: string, id = ""): Response = 
  if id == "":
    var ct = "text/plain"
    if req.headers.hasKey("Content-Type"):
      ct = req.headers["Content-Type"]
    return LS.postDocument(req.body.strip, ct)
  else:
    return resError(Http400, "Bad request: document ID cannot be specified in POST requests.")

proc put(req: Request, LS: LiteStore, resource: string, id = ""): Response = 
  if id != "":
    var ct = "text/plain"
    if req.headers.hasKey("Content-Type"):
      ct = req.headers["Content-Type"]
    return LS.putDocument(id, req.body.strip, ct)
  else:
    return resError(Http400, "Bad request: document ID must be specified in PUT requests.")

proc delete(req: Request, LS: LiteStore, resource: string, id = ""): Response = 
  if id != "":
    return LS.deleteDocument(id)
  else:
    return resError(Http400, "Bad request: document ID must be specified in DELETE requests.")

proc patch(req: Request, LS: LiteStore, resource: string, id = ""): Response = 
  if id != "":
    return LS.patchDocument(id, req.body)
  else:
    return resError(Http400, "Bad request: document ID must be specified in PATCH requests.")

proc route*(req: Request, LS: LiteStore, resource = "docs", id = ""): Response = 
  var reqMethod = req.reqMethod
  if req.headers.hasKey("X-HTTP-Method-Override"):
    reqMethod = req.headers["X-HTTP-Method-Override"]
  case reqMethod.toUpper:
    of "POST":
      if LS.readonly:
        return resError(Http405, "Method not allowed: $1" % req.reqMethod) 
      return validate(req, LS, resource, id, post)
    of "PUT":
      if LS.readonly:
        return resError(Http405, "Method not allowed: $1" % req.reqMethod) 
      return validate(req, LS, resource, id, put)
    of "DELETE":
      if LS.readonly:
        return resError(Http405, "Method not allowed: $1" % req.reqMethod) 
      return validate(req, LS, resource, id, delete)
    of "HEAD":
      return validate(req, LS, resource, id, head)
    of "OPTIONS":
      return validate(req, LS, resource, id, options)
    of "GET":
      return validate(req, LS, resource, id, get)
    of "PATCH":
      if LS.readonly:
        return resError(Http405, "Method not allowed: $1" % req.reqMethod) 
      return validate(req, LS, resource, id, patch)
    else:
      return resError(Http405, "Method not allowed: $1" % req.reqMethod) 
