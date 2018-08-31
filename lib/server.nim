import 
  asynchttpserver,
  asyncdispatch, 
  times, 
  strutils, 
  pegs, 
  strtabs, 
  logger,
  cgi,
  os
import 
  types, 
  utils, 
  api_v1,
  api_v2,
  api_v3

export 
  api_v3

proc getReqInfo(req: LSRequest): string =
  var url = req.url.path
  if req.url.anchor != "":
    url = url & "#" & req.url.anchor
  if req.url.query != "":
    url = url & "?" & req.url.query
  return req.hostname & " " & $req.reqMethod & " " & url

proc handleCtrlC() {.noconv.} =
  echo ""
  LOG.info("Exiting...")
  quit()

proc processApiUrl(req: LSRequest, LS: LiteStore, info: ResourceInfo): LSResponse = 
  if info.version == "v3":
    if info.resource.match(peg"^docs / info$"):
      return api_v3.route(req, LS, info.resource, info.id)
    elif info.resource.match(peg"^dir$"):
      if LS.directory.len > 0:
        return api_v3.serveFile(req, LS, info.id)
      else:
        return resError(Http400, "Bad Request - Not serving any directory." % info.version)
    else:
      return resError(Http400, "Bad Request - Invalid resource: $1" % info.resource)
  elif info.version == "v2":
    if info.resource.match(peg"^docs / info$"):
      return api_v2.route(req, LS, info.resource, info.id)
    elif info.resource.match(peg"^dir$"):
      if LS.directory.len > 0:
        return api_v2.serveFile(req, LS, info.id)
      else:
        return resError(Http400, "Bad Request - Not serving any directory." % info.version)
    else:
      return resError(Http400, "Bad Request - Invalid resource: $1" % info.resource)
  elif info.version == "v1": 
    if info.resource.match(peg"^docs / info$"):
      return api_v1.route(req, LS, info.resource, info.id)
    elif info.resource.match(peg"^dir$"):
      if LS.directory.len > 0:
        return api_v1.serveFile(req, LS, info.id)
      else:
        return resError(Http400, "Bad Request - Not serving any directory." % info.version)
    else:
      return resError(Http400, "Bad Request - Invalid resource: $1" % info.resource)
  else:
    if info.version == "v1" or info.version == "v2" or info.version == "v3":
      return resError(Http400, "Bad Request - Invalid API version: $1" % info.version)
    else:
      if info.resource.decodeURL.strip == "":
        return resError(Http400, "Bad Request - No resource specified." % info.resource)
      else:
        return resError(Http400, "Bad Request - Invalid resource: $1" % info.resource)

proc process*(req: LSRequest, LS: LiteStore): LSResponse {.gcsafe.}=
  var matches = @["", "", ""]
  template route(req: LSRequest, peg: Peg, op: untyped): untyped =
    if req.url.path.find(peg, matches) != -1:
      op
  try: 
    var info: ResourceInfo
    req.route peg"^\/?$":
      info.version = "v3"
      info.resource = "info"
      return req.processApiUrl(LS, info)
    req.route peg"^\/favicon.ico$":
      result.code = Http200
      result.content = LS.favicon
      result.headers = ctHeader("image/x-icon")
      return result
    req.route PEG_DEFAULT_URL:
      info.version = "v3"
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
  proc handleHttpRequest(req: LSRequest): Future[void] {.async, gcsafe, closure.} =
    LOG.info(getReqInfo(req).replace("$", "$$"))
    let res = req.process(LS)
    let areq = asynchttpserver.Request(req)
    await areq.respond(res.code, res.content, res.headers)
  echo(LS.appname & " v" & LS.appversion & " started on " & LS.address & ":" & $LS.port & ".")
  if LS.mount:
    echo("Mirroring datastore changes to: " & LS.directory)
  asyncCheck server.serve(LS.port.Port, handleHttpRequest, LS.address)

