import asynchttpserver, asyncdispatch, times, strutils, pegs
from strtabs import StringTableRef, newStringTable
import types, api

proc getReqInfo(req: Request): string =
  return $getLocalTime(getTime()) & " - " & req.hostname & " " & req.reqMethod & " " & req.url.path

proc handleCtrlC() {.noconv.} =
  echo "\nExiting..."
  quit()

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
  var options = newQueryOptions()
  options.select = "id, content_type, binary, searchable, created, modified"
  if req.url.path.rDocs(matches):
    if matches[0] != "":
      # Retrieve a single document
      return LS.getRawDocument(matches[0], options)
    else:
      # Retrieve a multiple documents
      return LS.getRawDocuments(options)
  else:
    return resError(Http400, "Bad request: $1" % req.url.path) 

proc getRoutes(req: Request, LS: LiteStore): Response =
  var matches = @[""]
  if req.url.path.rDocs(matches):
    if matches[0] != "":
      # Retrieve a single document
      if req.url.query.contains("raw=true"):
        return LS.getRawDocument(matches[0])
      else:
        return LS.getDocument(matches[0])
    else:
      # Retrieve a multiple documents
      return LS.getRawDocuments()
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

