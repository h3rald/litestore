import
  asynchttpserver,
  asyncdispatch,
  strutils,
  pegs,
  logger,
  cgi,
  json,
  tables,
  strtabs,
  asyncnet,
  sequtils
import
  types,
  utils,
  jwt,
  api_v1,
  api_v2,
  api_v3,
  api_v4,
  api_v5,
  api_v6,
  api_v7,
  api_v8

export
  api_v8

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

template auth(uri: string, LS: LiteStore, jwt: JWT): void =
  let cfg = access[uri]
  if cfg.hasKey(reqMethod):
    LOG.debug("Authenticating: " & reqMethod & " " & uri)
    if not req.headers.hasKey("Authorization"):
      return resError(Http401, "Unauthorized - No token")
    let token = req.headers["Authorization"].replace(peg"^ 'Bearer '", "")
    # Validate token
    try:
      jwt = token.newJwt
      var x5c: string
      if LS.config.hasKey("jwks_uri"):
        LOG.debug("Selecting x5c...")
        x5c = LS.getX5c(jwt)
      else:
        LOG.debug("Using stored signature...")
        x5c = LS.config["signature"].getStr
      LOG.debug("Verifying algorithm...")
      jwt.verifyAlgorithm()
      LOG.debug("Verifying signature...")
      try:
        jwt.verifySignature(x5c)
      except EX509Error:
        LOG.warn getCurrentExceptionMsg()
        writeStackTrace()
      LOG.debug("Verifying claims...")
      jwt.verifyTimeClaims()
      let scope = cfg[reqMethod].mapIt(it.getStr)
      LOG.debug("Verifying scope...")
      jwt.verifyScope(scope)
      LOG.debug("Authorization successful")
    except EUnauthorizedError:
      LOG.warn getCurrentExceptionMsg()
      writeStackTrace()
      return resError(Http403, "Forbidden - You are not permitted to access this resource")
    except CatchableError:
      LOG.warn getCurrentExceptionMsg()
      writeStackTrace()
      return resError(Http401, "Unauthorized - Invalid token")

proc isAllowed(LS: LiteStore, resource, id, meth: string): bool =
  if LS.config.kind != JObject or not LS.config.hasKey("resources"):
    return true
  var reqUri = "/" & resource & "/" & id
  var lastItemOffset = 2
  if reqUri[^1] == '/':
    lastItemOffset = 1
    reqUri.removeSuffix({'/'})
  let parts = reqUri.split("/")
  let ancestors = parts[1..parts.len-lastItemOffset]
  var currentPath = ""
  var currentPaths = ""
  for p in ancestors:
    currentPath &= "/" & p
    currentPaths = currentPath & "/*"
    if LS.config["resources"].hasKey(currentPaths) and LS.config["resources"][
        currentPaths].hasKey(meth) and LS.config["resources"][currentPaths][
        meth].hasKey("allowed"):
      let allowed = LS.config["resources"][currentPaths][meth]["allowed"]
      if (allowed == %false):
        return false;
  if LS.config["resources"].hasKey(reqUri) and LS.config["resources"][
      reqUri].hasKey(meth) and LS.config["resources"][reqUri][meth].hasKey("allowed"):
    let allowed = LS.config["resources"][reqUri][meth]["allowed"]
    if (allowed == %false):
      return false
  return true

proc processApiUrl(req: LSRequest, LS: LiteStore,
    info: ResourceInfo): LSResponse =
  var reqUri = "/" & info.resource & "/" & info.id
  if reqUri[^1] == '/':
    reqUri.removeSuffix({'/'})
  let reqMethod = $req.reqMethod
  var jwt: JWT
  if not LS.isAllowed(info.resource, info.id, reqMethod):
    return resError(Http405, "Method not allowed: $1" % reqMethod)
  # Authentication/Authorization
  if LS.auth != newJNull():
    var uri = reqUri
    let access = LS.auth["access"]
    while true:
      # Match exact url
      if access.hasKey(uri):
        auth(uri, LS, jwt)
        break
      # Match exact url adding /* (e.g. /docs would match also /docs/* in auth.json)
      elif uri[^1] != '*' and uri[^1] != '/':
        if access.hasKey(uri & "/*"):
          auth(uri & "/*", LS, jwt)
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
          auth(uri, LS, jwt)
        break
  if info.version == "v8":
    if info.resource.match(peg"^assets / docs / info / tags / indexes / stores$"):
      var nReq = req
      if jwt.signature.len != 0:
        nReq.jwt = jwt
      return api_v8.execute(nReq, LS, info.resource, info.id)
    elif info.resource.match(peg"^dir$"):
      if LS.directory.len > 0:
        return api_v8.serveFile(req, LS, info.id)
      else:
        return resError(Http400, "Bad Request - Not serving any directory." % info.version)
    else:
      return resError(Http404, "Resource Not Found: $1" % info.resource)
  if info.version == "v7":
    if info.resource.match(peg"^docs / info / tags / indexes / stores$"):
      var nReq = req
      if jwt.signature.len != 0:
        nReq.jwt = jwt
      return api_v7.execute(nReq, LS, info.resource, info.id)
    elif info.resource.match(peg"^dir$"):
      if LS.directory.len > 0:
        return api_v7.serveFile(req, LS, info.id)
      else:
        return resError(Http400, "Bad Request - Not serving any directory." % info.version)
    else:
      return resError(Http404, "Resource Not Found: $1" % info.resource)
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
    if info.version == "v1" or info.version == "v2" or info.version == "v3" or
        info.version == "v4" or info.version == "v5":
      return resError(Http400, "Bad Request - Invalid API version: $1" % info.version)
    else:
      if info.resource.decodeURL.strip == "":
        return resError(Http400, "Bad Request - No resource specified." % info.resource)
      else:
        return resError(Http404, "Resource Not Found: $1" % info.resource)

proc process*(req: LSRequest, LS: LiteStore): LSResponse {.gcsafe.} =
  var matches = @["", "", ""]
  template route(req: LSRequest, peg: Peg, op: untyped): untyped =
    if req.url.path.find(peg, matches) != -1:
      op
  try:
    var info: ResourceInfo
    req.route peg"^\/?$":
      info.version = "v8"
      info.resource = "info"
      return req.processApiUrl(LS, info)
    req.route peg"^\/favicon.ico$":
      result.code = Http200
      result.content = LS.favicon
      result.headers = ctHeader("image/x-icon")
      return result
    req.route PEG_DEFAULT_URL:
      info.version = "v8"
      info.resource = matches[0]
      info.id = matches[1].decodeUrl
      return req.processApiUrl(LS, info)
    req.route PEG_URL:
      info.version = matches[0]
      info.resource = matches[1]
      info.id = matches[2].decodeUrl
      return req.processApiUrl(LS, info)
    raise newException(EInvalidRequest, req.getReqInfo())
  except EInvalidRequest:
    let e = (ref EInvalidRequest)(getCurrentException())
    let trace = e.getStackTrace()
    return resError(Http404, "Resource Not Found: $1" % getCurrentExceptionMsg(
      ).split(" ")[2], trace)
  except CatchableError:
    let e = getCurrentException()
    let trace = e.getStackTrace()
    return resError(Http500, "Internal Server Error: $1" %
        getCurrentExceptionMsg(), trace)


proc process*(req: LSRequest, LSDICT: OrderedTable[string,
    LiteStore]): LSResponse {.gcsafe.} =
  var matches = @["", ""]
  if req.url.path.find(PEG_STORE_URL, matches) != -1:
    let id = matches[0]
    let path = matches[1]
    if path == "":
      var info: ResourceInfo
      info.version = "v7"
      info.resource = "stores"
      info.id = id
      return req.processApiUrl(LS, info)
    else:
      var newReq = req
      newReq.url.path = "/$1" % path
      return newReq.process(LSDICT[id])
  else:
    return req.process(LS)

setControlCHook(handleCtrlC)

proc printCfg(id: string, indent = "") =
  let store = LSDICT[id]
  if (indent == ""):
    echo "Master Store: $2" % [id, store.file]
  else:
    echo indent & "Additional Store ($1): $2" % [id, store.file]
  if store.configFile != "":
    echo indent & "- Configuration file: " & store.configFile
  if store.authFile != "":
    echo indent & "- Auth file: " & store.authFile
  if store.mount:
    echo indent & "- Mirroring datastore changes to: " & store.directory
  elif store.directory != "":
    echo indent & "- Serving directory: " & store.directory
  echo indent & "- Log level: " & LS.loglevel
  if store.readonly:
    echo indent & "- Read-only mode"
  if store.middleware.len > 0:
    echo indent & "- Middleware configured"
  if store.auth != newJNull():
    echo indent & "- Authorization configured"


proc serve*(LS: LiteStore) =
  var server = newAsyncHttpServer()
  proc handleHttpRequest(origReq: Request): Future[void] {.async, gcsafe, closure.} =
    var client = origReq.client
    var req = newLSRequest(origReq)
    let address = client.getLocalAddr()
    req.url.hostname = address[0]
    req.url.port = $int(address[1])
    LOG.info(getReqInfo(req).replace("$", "$$"))
    let res = req.process(LSDICT)
    var newReq = newRequest(req, client)
    await newReq.respond(res.code, res.content, res.headers)
  echo(LS.appname & " v" & LS.appversion & " started on " & LS.address & ":" &
      $LS.port & ".")
  printCfg("master")
  let storeIds = toSeq(LSDICT.keys)
  if (storeIds.len > 1):
    for i in countdown(storeIds.len-2, 0):
      printCfg(storeIds[i], "  ")
  asyncCheck server.serve(LS.port.Port, handleHttpRequest, LS.address)
