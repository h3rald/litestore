import asynchttpserver2, asyncdispatch, times, strutils, pegs, strtabs, cgi, logging
import types, utils, api_v1

proc getReqInfo(req: Request): string =
  var url = req.url.path
  if req.url.anchor != "":
    url = url & "#" & req.url.anchor
  if req.url.query != "":
    url = url & "?" & req.url.query
  return req.hostname & " " & req.reqMethod & " " & url

proc handleCtrlC() {.noconv.} =
  echo ""
  info("Exiting...")
  quit()

proc parseApiUrl(req: Request): ResourceInfo =
  var matches = @["", "", ""]
  if req.url.path.find(PEG_URL, matches) != -1:
    result.version = matches[0]
    result.resource = matches[1]
    result.id = matches[2]
  else:
    raise newException(EInvalidRequest, req.getReqInfo())

proc route(req: Request, LS: LiteStore): Response =
  if req.url.path == "/favicon.ico":
    result.code = Http200
    result.content = LS.favicon
    result.headers = {"Content-Type": "image/x-icon"}.newStringTable
    return result
  try:
    var info = req.parseApiUrl
    if info.version == "v1" and info.resource.match(peg"^docs / info$"):
      return api_v1.route(req, LS, info.resource, info.id)
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
    info(getReqInfo(req).replace("$", "$$"))
    let res = req.route(LS)
    await req.respond(res.code, res.content, res.headers)
  info(LS.appname & " v" & LS.appversion & " started on " & LS.address & ":" & $LS.port & ".")
  asyncCheck server.serve(LS.port.Port, handleHttpRequest, LS.address)

