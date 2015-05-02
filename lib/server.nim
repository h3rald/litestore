import 
  asynchttpserver2,
  asyncdispatch, 
  times, 
  strutils, 
  pegs, 
  strtabs, 
  #logging,
  cgi 
import 
  types, 
  utils, 
  api_v1

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

proc processApiUrl(req: Request, LS: LiteStore, info: ResourceInfo): Response = 
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


proc process(req: Request, LS: LiteStore): Response {.gcsafe.}=
  var matches = @["", "", ""]
  template route(req, peg: expr, op: stmt): stmt {.immediate.}=
    if req.url.path.find(peg, matches) != -1:
      op
  try: 
    var info: ResourceInfo
    req.route peg"^\/?$":
      info.version = "v1"
      info.resource = "info"
      return req.processApiUrl(LS, info)
    req.route peg"^\/favicon.ico$":
      result.code = Http200
      result.content = LS.favicon
      result.headers = {"Content-Type": "image/x-icon"}.newStringTable
      return result
    req.route PEG_DEFAULT_URL:
      info.version = "v1"
      info.resource = matches[0]
      info.id = matches[1]
      return req.processApiUrl(LS, info)
    req.route PEG_URL:
      info.version = matches[0]
      info.resource = matches[1]
      info.id = matches[2]
      return req.processApiUrl(LS, info)
    raise newException(EInvalidRequest, req.getReqInfo())
  except EInvalidRequest:
    let e = (ref EInvalidRequest)(getCurrentException())
    let trace = e.getStackTrace()
    return resError(Http400, "Bad Request: $1" % getCurrentExceptionMsg(), trace)
  except:
    let e = getCurrentException()
    let trace = e.getStackTrace()
    return resError(Http500, "Internal Server Error: $1" % getCurrentExceptionMsg(), trace)

setControlCHook(handleCtrlC)

proc serve*(LS: LiteStore) =
  var server = newAsyncHttpServer()
  proc handleHttpRequest(req: Request): Future[void] {.async, gcsafe, closure.} =
    info(getReqInfo(req).replace("$", "$$"))
    let res = req.process(LS)
    await req.respond(res.code, res.content, res.headers)
  info(LS.appname & " v" & LS.appversion & " started on " & LS.address & ":" & $LS.port & ".")
  if LS.mount:
    info("Mirroring datastore changes to: " & LS.directory)
  asyncCheck server.serve(LS.port.Port, handleHttpRequest, LS.address)

