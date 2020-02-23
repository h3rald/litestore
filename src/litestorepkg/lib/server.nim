import
  asynchttpserver,
  asyncdispatch,
  times,
  strutils,
  pegs,
  logger,
  cgi,
  os,
  json,
  tables,
  strtabs,
  base64,
  asyncnet,
  jwt
import 
  types, 
  utils, 
  core,
  api_v1,
  api_v2,
  api_v3,
  api_v4,
  api_v5,
  api_v6

export
  api_v5


proc decodeUrlSafeAsString*(s: string): string =
  var s = s.replace('-', '+').replace('_', '/')
  while s.len mod 4 > 0:
    s &= "="
  base64.decode(s)

proc decodeUrlSafe*(s: string): seq[byte] =
  cast[seq[byte]](decodeUrlSafeAsString(s))

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
  
template auth(uri: string, jwt: JWT): void =
  let cfg = access[uri]
  if cfg.hasKey(reqMethod):
    LOG.debug("Authenticating: " & reqMethod & " " & uri)
    if not req.headers.hasKey("Authorization"): 
      return resError(Http401, "Unauthorized - No token")
    let token = req.headers["Authorization"].replace(peg"^ 'Bearer '", "")
    # Validate token
    try:
      jwt = token.toJwt()
      let parts = token.split(".")
      var sig = LS.auth["signature"].getStr 
      discard verifySignature(parts[0] & "." & parts[1], decodeUrlSafe(parts[2]), sig)
      verifyTimeClaims(jwt)
      let scopes = cfg[reqMethod]
      # Validate scope
      var authorized = ""
      let reqScopes = ($jwt.claims["scope"].node.str).split(peg"\s+")
      LOG.debug("Resource scopes: " & $scopes)
      LOG.debug("Request scopes: " & $reqScopes)
      for scope in scopes:
        for reqScope in reqScopes:
          if reqScope == scope.getStr:
            authorized = scope.getStr
            break
      if authorized == "":
        return resError(Http403, "Forbidden - You are not permitted to access this resource")
      LOG.debug("Authorization successful: " & authorized)
    except:
      echo getCurrentExceptionMsg()
      writeStackTrace()
      return resError(Http401, "Unauthorized - Invalid token")

proc processApiUrl(req: LSRequest, LS: LiteStore, info: ResourceInfo): LSResponse = 
  var reqUri = "/" & info.resource & "/" & info.id
  if reqUri[^1] == '/':
    reqUri.removeSuffix({'/'})
  let reqMethod = $req.reqMethod
  var jwt: JWT
  # Authentication/Authorization
  if LS.auth != newJNull():
    var uri = reqUri
    let access = LS.auth["access"]
    while true:
      # Match exact url
      if access.hasKey(uri):
        auth(uri, jwt)
        break
      # Match exact url adding /* (e.g. /docs would match also /docs/* in auth.json)
      elif uri[^1] != '*' and uri[^1] != '/':
        if access.hasKey(uri & "/*"):
          auth(uri & "/*", jwt)
          break
      var parts = uri.split("/")
      if parts[^1] == "*":
        discard parts.pop
      discard parts.pop
      if parts.len > 0:
        # Go up one level
        uri = parts.join("/") & "/*"
      else:
        # If at the end of the URL, check generic URL
        uri = "/*"
        if access.hasKey(uri):
          auth(uri, jwt)
        break
  if info.version == "v6":
    if info.resource.match(peg"^docs / info / tags / indexes$"):
      var nReq = req
      if jwt.signature.len != 0:
        nReq.jwt = jwt
      return api_v6.execute(nReq, LS, info.resource, info.id)
    elif info.resource.match(peg"^dir$"):
      if LS.directory.len > 0:
        return api_v6.serveFile(req, LS, info.id)
      else:
        return resError(Http400, "Bad Request - Not serving any directory." % info.version)
    else:
      return resError(Http404, "Resource Not Found: $1" % info.resource)
  elif info.version == "v5":
    if info.resource.match(peg"^docs / info / tags / indexes$"):
      return api_v5.route(req, LS, info.resource, info.id)
    elif info.resource.match(peg"^dir$"):
      if LS.directory.len > 0:
        return api_v5.serveFile(req, LS, info.id)
      else:
        return resError(Http400, "Bad Request - Not serving any directory." % info.version)
    else:
      return resError(Http404, "Resource Not Found: $1" % info.resource)
  elif info.version == "v4":
    if info.resource.match(peg"^docs / info / tags$"):
      return api_v4.route(req, LS, info.resource, info.id)
    elif info.resource.match(peg"^dir$"):
      if LS.directory.len > 0:
        return api_v4.serveFile(req, LS, info.id)
      else:
        return resError(Http400, "Bad Request - Not serving any directory." % info.version)
    else:
      return resError(Http404, "Resource Not Found: $1" % info.resource)
  elif info.version == "v3":
    if info.resource.match(peg"^docs / info$"):
      return api_v3.route(req, LS, info.resource, info.id)
    elif info.resource.match(peg"^dir$"):
      if LS.directory.len > 0:
        return api_v3.serveFile(req, LS, info.id)
      else:
        return resError(Http400, "Bad Request - Not serving any directory." % info.version)
    else:
      return resError(Http404, "Resource Not Found: $1" % info.resource)
  elif info.version == "v2":
    if info.resource.match(peg"^docs / info$"):
      return api_v2.route(req, LS, info.resource, info.id)
    elif info.resource.match(peg"^dir$"):
      if LS.directory.len > 0:
        return api_v2.serveFile(req, LS, info.id)
      else:
        return resError(Http400, "Bad Request - Not serving any directory." % info.version)
    else:
      return resError(Http404, "Resource Not Found: $1" % info.resource)
  elif info.version == "v1":
    if info.resource.match(peg"^docs / info$"):
      return api_v1.route(req, LS, info.resource, info.id)
    elif info.resource.match(peg"^dir$"):
      if LS.directory.len > 0:
        return api_v1.serveFile(req, LS, info.id)
      else:
        return resError(Http400, "Bad Request - Not serving any directory." % info.version)
    else:
      return resError(Http404, "Resource Not Found: $1" % info.resource)
  else:
    if info.version == "v1" or info.version == "v2" or info.version == "v3" or info.version == "v4" or info.version == "v5":
      return resError(Http400, "Bad Request - Invalid API version: $1" % info.version)
    else:
      if info.resource.decodeURL.strip == "":
        return resError(Http400, "Bad Request - No resource specified." % info.resource)
      else:
        return resError(Http404, "Resource Not Found: $1" % info.resource)

proc process*(req: LSRequest, LS: LiteStore): LSResponse {.gcsafe.}=
  var matches = @["", "", ""]
  template route(req: LSRequest, peg: Peg, op: untyped): untyped =
    if req.url.path.find(peg, matches) != -1:
      op
  try:
    var info: ResourceInfo
    req.route peg"^\/?$":
      info.version = "v6"
      info.resource = "info"
      return req.processApiUrl(LS, info)
    req.route peg"^\/favicon.ico$":
      result.code = Http200
      result.content = LS.favicon
      result.headers = ctHeader("image/x-icon")
      return result
    req.route PEG_DEFAULT_URL:
      info.version = "v6"
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
    return resError(Http404, "Resource Not Found: $1" % getCurrentExceptionMsg().split(" ")[2], trace)
  except:
    let e = getCurrentException()
    let trace = e.getStackTrace()
    return resError(Http500, "Internal Server Error: $1" % getCurrentExceptionMsg(), trace)

setControlCHook(handleCtrlC)

proc serve*(LS: LiteStore) =
  var server = newAsyncHttpServer()
  proc handleHttpRequest(origReq: Request): Future[void] {.async, gcsafe, closure.} =
    var client = origReq.client
    var req = newLSRequest(origReq)
    let address = client.getLocalAddr()
    req.url.hostname = address[0]
    req.url.port = $int(address[1])
    LOG.info(getReqInfo(req).replace("$", "$$"))
    let res = req.process(LS)
    var newReq = newRequest(req, client)
    await newReq.respond(res.code, res.content, res.headers)
  echo(LS.appname & " v" & LS.appversion & " started on " & LS.address & ":" & $LS.port & ".")
  if LS.configFile != "":
    echo "- Configuration File: " & LS.configFile
  if LS.authFile != "":
    echo "- Auth File: " & LS.authFile
  if LS.mount:
    echo "- Mirroring datastore changes to: " & LS.directory
  if LS.readonly:
    echo "- Read-only mode"
  echo "- Log Level: " & LS.loglevel
  echo "- Store: " & LS.file
  if LS.auth != newJNull():
    echo "- Authorization configured"
  asyncCheck server.serve(LS.port.Port, handleHttpRequest, LS.address)
