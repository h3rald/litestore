import asynchttpserver, asyncdispatch, times, strutils, pegs
from strtabs import StringTableRef, newStringTable
import types, api

proc getReqInfo(req: Request): string =
  return $getLocalTime(getTime()) & " - " & req.hostname & " " & req.reqMethod & " " & req.url.path

proc handleCtrlC() {.noconv.} =
  echo "\nExiting..."
  quit()

proc rDocs(path: string, matches: var seq[string]): bool =
  return path.find(peg"""^\/docs\/? {(.*)}""", matches) != -1

proc rTags(path: string, matches: var seq[string]): bool =
  return path.find(peg"""^\/tags\/? {(.*)}(\/{.*})?""", matches) != -1

proc route(req: Request, LS: LiteStore): Response =
  case req.reqMethod:
    of "GET":
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

