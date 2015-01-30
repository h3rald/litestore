import asynchttpserver, asyncdispatch, times, strutils, pegs, strtabs, cgi
import types, api

proc getReqInfo(req: Request): string =
  return $getLocalTime(getTime()) & " - " & req.hostname & " " & req.reqMethod & " " & req.url.path

proc handleCtrlC() {.noconv.} =
  echo "\nExiting..."
  quit()

proc validOrderBy(clause: string):bool =
  return clause == "id ASC" or 
         clause == "id DESC" or
         clause == "created ASC" or
         clause == "created DESC" or
         clause == "modified ASC" or
         clause == "modified DESC"

proc parseQueryOption(fragment: string, options: var QueryOptions) =
  var pair = fragment.split('=')
  if pair.len < 2:
    return
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
        raise newException(EInvalidRequest, "LIMIT - $1" % getCurrentExceptionMsg())
    of "orderby":
      if pair[1].validOrderBy():
        options.orderby = pair[1]
      else:
        raise newException(EInvalidRequest, "ORDERBY - Invalid clause '$1'" % pair[1])
    else:
      return

proc parseQueryOptions(querystring: string, options: var QueryOptions) =
  var fragments = querystring.split('&')
  for f in fragments:
    f.parseQueryOption(options)


proc rDocs(path: string, matches: var seq[string]): bool =
  return path.find(peg"""^\/? {(.*)}""", matches) != -1

proc optionsRoutes(req: Request, LS: LiteStore): Response =
  var matches = @[""]
  if req.url.path.rDocs(matches):
    if matches[0] != "":
      result.code = Http200
      result.content = ""
      result.headers = {"Allow": "HEAD,GET,PUT,PATCH,DELETE"}.newStringTable
    else:
      result.code = Http200
      result.content = ""
      result.headers = {"Allow": "HEAD,GET,POST,DELETE"}.newStringTable
  else:
    return resError(Http400, "Bad request: $1" % req.url.path) 

proc headRoutes(req: Request, LS: LiteStore): Response =
  var matches = @[""]
  if req.url.path.rDocs(matches):
    var options = newQueryOptions()
    options.select = "id, content_type, binary, searchable, created, modified"
    try:
      parseQueryOptions(req.url.query, options);
      if matches[0] != "":
        # Retrieve a single document
        return LS.getRawDocument(matches[0], options)
      else:
        # Retrieve a multiple documents
        return LS.getRawDocuments(options)
    except:
      return resError(Http400, "Bad request: $1" % getCurrentExceptionMsg())
  else:
    return resError(Http400, "Bad request: $1" % req.url.path) 

proc getRoutes(req: Request, LS: LiteStore): Response =
  var matches = @[""]
  if req.url.path.rDocs(matches):
    var options = newQueryOptions()
    try:
      parseQueryOptions(req.url.query, options);
      if matches[0] != "":
        # Retrieve a single document
        if req.url.query.contains("raw=true") or req.headers["Content-Type"] == "application/json":
          return LS.getRawDocument(matches[0], options)
        else:
          return LS.getDocument(matches[0], options)
      else:
        # Retrieve a multiple documents
        return LS.getRawDocuments(options)
    except:
      return resError(Http400, "Bad request: $1" % getCurrentExceptionMsg())
  else:
    return resError(Http400, "Bad request: $1" % req.url.path) 

proc route(req: Request, LS: LiteStore): Response =
  case req.reqMethod:
    of "HEAD":
      return req.headRoutes(LS)
    of "OPTIONS":
      return req.optionsRoutes(LS)
    of "GET":
      return req.getRoutes(LS)
    else:
      return resError(Http501, "Method $1 not implemented" % req.reqMethod) 

setControlCHook(handleCtrlC)

proc serve*(LS: LiteStore) =
  var server = newAsyncHttpServer()
  proc handleHttpRequest(req: Request): Future[void] {.async.} =
    echo getReqInfo(req)
    let res = req.route(LS)
    await req.respond(res.code, res.content, res.headers)
  echo LS.appname, " v", LS.appversion, " started on ", LS.address, ":", LS.port, "." 
  asyncCheck server.serve(LS.port.Port, handleHttpRequest, LS.address)

