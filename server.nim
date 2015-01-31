import asynchttpserver2, asyncdispatch, times, strutils, pegs, strtabs, cgi
import types, utils, api_v1

proc getReqInfo(req: Request): string =
  return $getLocalTime(getTime()) & " - " & req.hostname & " " & req.reqMethod & " " & req.url.path

proc handleCtrlC() {.noconv.} =
  echo "\nExiting..."
  quit()

proc parseApiUrl(req: Request): ResourceInfo =
  var matches = @["", "", ""]
  if req.url.path.find(PEG_URL, matches) != -1:
    result.version = matches[0]
    result.resource = matches[1]
    result.id = matches[2]
  else:
    raise newException(EInvalidRequest, req.url.path&"?"&req.url.query)

proc route(req: Request, LS: LiteStore): Response =
  try:
    var info = req.parseApiUrl
    if info.version == "v1" and info.resource == "docs":
      return api_v1.route(req, LS, info.id)
    else:
      if info.version != "v1":
        return resError(Http400, "Bad request - Invalid API version: $1" % info.version)
      else:
        if info.resource.decodeURL.strip == "":
          return resError(Http400, "Bad request - No resource specified" % info.resource)
        else:
          return resError(Http400, "Bad request - Invalid resource: $1" % info.resource)
  except:
    return resError(Http400, "Bad request: $1" % getCurrentExceptionMsg())

setControlCHook(handleCtrlC)

proc serve*(LS: LiteStore) =
  var server = newAsyncHttpServer()
  proc handleHttpRequest(req: Request): Future[void] {.async.} =
    echo getReqInfo(req)
    let res = req.route(LS)
    await req.respond(res.code, res.content, res.headers)
  echo LS.appname, " v", LS.appversion, " started on ", LS.address, ":", LS.port, "." 
  asyncCheck server.serve(LS.port.Port, handleHttpRequest, LS.address)

