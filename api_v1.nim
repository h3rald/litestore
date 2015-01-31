import asynchttpserver, asyncdispatch, strutils, cgi, strtabs, pegs
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

proc getRawDocuments(LS: LiteStore, options = newQueryOptions()): Response =
  let docs = LS.store.retrieveRawDocuments(options) 
  if docs == "[]":
    result = resError(Http404, "No documents found.")
  else:
    result.headers = ctJsonHeader()
    result.content = docs
    result.code = Http200

# Main routing

proc options(req: Request, LS: LiteStore, id = ""): Response =
  if id != "":
    result.code = Http202
    result.content = ""
    result.headers = {"Allow": "HEAD,GET,PUT,PATCH,DELETE"}.newStringTable
  else:
    result.code = Http202
    result.content = ""
    result.headers = {"Allow": "HEAD,GET,POST,DELETE"}.newStringTable

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

proc route*(req: Request, LS: LiteStore, id = ""): Response = 
  case req.reqMethod:
    of "HEAD":
      return req.head(LS, id)
    of "OPTIONS":
      return req.options(LS, id)
    of "GET":
      return req.get(LS, id)
    else:
      return resError(Http405, "Method not allowed: $1" % req.reqMethod) 
