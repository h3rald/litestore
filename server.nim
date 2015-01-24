import asynchttpserver, asyncdispatch, times, strutils, pegs
from strtabs import StringTableRef, newStringTable
import types, core


const 
  CT_JSON = {"Content-type": "application/json"}

proc getReqInfo(req): string =
  return $getLocalTime(getTime()) & " - " & req.hostname & " " & req.reqMethod & " " & req.url.path

proc handleCtrlC() {.noconv.} =
  echo "\nExiting..."
  quit()

proc resDocumentNotFound(id): Response =
  result.content = """{"code": 404, "message": "Document '$1' not found."}""" % id
  result.code = Http404
  result.headers = CT_JSON.newStringTable

proc getRawDocument(settings: Settings, id: string): Response =
  let doc = settings.store.retrieveRawDocument(id)
  result.headers = CT_JSON.newStringTable
  if doc == "":
    result = resDocumentNotFound(id)
  else:
    result.content = doc
    result.code = Http200

proc route(req: Request, settings: Settings): Response =
  case req.reqMethod:
    of "GET":
      var matches = @[""]
      if req.url.path.find(peg"""^\/docs\/? {(.*)}""", matches) != -1:
        if matches[0] != "":
          # Retrieve a single document
          return settings.getRawDocument(matches[0])
        else: 
          result = resDocumentNotFound("-") # TODO CHANGE
      else:
        result.code = Http400
        result.content = """{"code": 400, "message": "Bad request: $1"}""" % req.url.path
        result.headers = CT_JSON.newStringTable
    else:
      result.content = """{"code": 501, "message": "Method $1 not implemented."}""" % req.reqMethod
      result.headers = CT_JSON.newStringTable
      result.code = Http501

setControlCHook(handleCtrlC)

proc serve*(settings: Settings) =
  var server = newAsyncHttpServer()
  proc handleHttpRequest(req: Request): Future[void] {.async.} =
    echo getReqInfo(req)
    let res = req.route(settings)
    await req.respond(res.code, res.content, res.headers)
  echo settings.appname, " v", settings.appversion, " started on ", settings.address, ":", settings.port, "." 
  asyncCheck server.serve(settings.port.Port, handleHttpRequest, settings.address)

