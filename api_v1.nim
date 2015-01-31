import asynchttpserver2, asyncdispatch, strutils, cgi, strtabs, pegs, json
import types, core, utils

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
    of "tags":
      options.tags = pair[1]
    of "limit":
      try:
        options.limit = pair[1].parseInt
      except:
        raise newException(EInvalidRequest, "Invalid limit value: $1" % getCurrentExceptionMsg())
    of "sort":
      let orderby = pair[1].orderByClause()
      if orderby != "":
        options.orderby = orderby
      else:
        raise newException(EInvalidRequest, "Invalid sort value: $1" % pair[1])
    else:
      return

proc parseQueryOptions(querystring: string, options: var QueryOptions) =
  var fragments = querystring.split('&')
  for f in fragments:
    f.parseQueryOption(options)


proc validate(req: Request, LS: LiteStore, id: string, cb: proc(req: Request, LS: LiteStore, id: string):Response): Response = 
  if req.reqMethod == "POST" or req.reqMethod == "PUT" or req.reqMethod == "PATCH":
    var ct =  ""
    let body = req.body.strip
    if body == "":
      return resError(Http400, "Bad request: No content specified for document.")
    if req.headers.hasKey("Content-type"):
      ct = req.headers["Content-type"]
      case ct:
        of "application/json":
          try:
            discard body.parseJson()
          except:
            return resError(Http400, "Invalid JSON content - $1" % getCurrentExceptionMsg())
        else:
          discard
  return cb(req, LS, id)

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
        result.headers = {"Content-Length": "0"}.newStringTable
        result.content = ""
        result.code = Http204
    except:
      result = resError(Http500, "Unable to delete document '$1'" % id)

proc getRawDocuments(LS: LiteStore, options = newQueryOptions()): Response =
  let docs = LS.store.retrieveRawDocuments(options) 
  if docs == "[]":
    result = resError(Http404, "No documents found.")
  else:
    result.headers = ctJsonHeader()
    result.content = docs
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
    result = resError(Http500, "Unable to create document.")

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
      result = resError(Http500, "Unable to update document '$1'." % id)

# Main routing

proc options(req: Request, LS: LiteStore, id = ""): Response =
  if id != "":
    result.code = Http204
    result.content = ""
    result.headers = {"Allow": "HEAD,GET,PUT,PATCH,DELETE"}.newStringTable
  else:
    result.code = Http204
    result.content = ""
    result.headers = {"Allow": "HEAD,GET,POST"}.newStringTable

proc head(req: Request, LS: LiteStore, id = ""): Response =
  var options = newQueryOptions()
  options.select = "id, content_type, binary, searchable, created, modified"
  try:
    parseQueryOptions(req.url.query, options);
    if id != "":
      return LS.getRawDocument(id, options)
    else:
      return LS.getRawDocuments(options)
  except:
    return resError(Http400, "Bad request - $1" % getCurrentExceptionMsg())

proc get(req: Request, LS: LiteStore, id = ""): Response =
  var options = newQueryOptions()
  try:
    parseQueryOptions(req.url.query, options);
    if id != "":
      if req.url.query.contains("raw=true") or req.headers["Content-Type"] == "application/json":
        return LS.getRawDocument(id, options)
      else:
        return LS.getDocument(id, options)
    else:
      return LS.getRawDocuments(options)
  except:
    return resError(Http400, "Bad request - $1" % getCurrentExceptionMsg())

proc post(req: Request, LS: LiteStore, id = ""): Response = 
  if id == "":
    var ct = "text/plain"
    if req.headers.hasKey("Content-type"):
      ct = req.headers["Content-type"]
    return LS.postDocument(req.body.strip, ct)
  else:
    return resError(Http400, "Bad request: document ID cannot be specified in POST requests.")

proc put(req: Request, LS: LiteStore, id = ""): Response = 
  if id != "":
    var ct = "text/plain"
    if req.headers.hasKey("Content-type"):
      ct = req.headers["Content-type"]
    return LS.putDocument(id, req.body.strip, ct)
  else:
    return resError(Http400, "Bad request: document ID must be specified in PUT requests.")

proc delete(req: Request, LS: LiteStore, id = ""): Response = 
  if id != "":
    return LS.deleteDocument(id)
  else:
    return resError(Http400, "Bad request: document ID must be specified in DELETE requests.")

proc route*(req: Request, LS: LiteStore, id = ""): Response = 
  case req.reqMethod:
    of "POST":
      return validate(req, LS, id, post)
    of "PUT":
      return validate(req, LS, id, put)
    of "DELETE":
      return validate(req, LS, id, delete)
    of "HEAD":
      return validate(req, LS, id, head)
    of "OPTIONS":
      return validate(req, LS, id, options)
    of "GET":
      return validate(req, LS, id, get)
    else:
      return resError(Http405, "Method not allowed: $1" % req.reqMethod) 
