import
  strutils,
  strtabs,
  os,
  uri,
  httpcore,
  json
import
  litestorepkg/lib/types,
  litestorepkg/lib/logger,
  litestorepkg/lib/utils,
  litestorepkg/lib/core,
  litestorepkg/lib/cli,
  litestorepkg/lib/server

export
  types,
  server,
  logger,
  utils

from asyncdispatch import runForever

{.compile: "litestorepkg/vendor/sqlite/sqlite3.c".}
{.passC: "-DSQLITE_ENABLE_FTS3=1 -DSQLITE_ENABLE_FTS3_PARENTHESIS -DSQLITE_ENABLE_JSON1".}
when defined(linux):
  {.passL:"-static".}

proc processAuthConfig(configuration: JsonNode, auth: var JsonNode) =
  if auth == newJNull() and configuration != newJNull() and configuration.hasKey("signature"):
    auth = newJObject();
    auth["access"] = newJObject();
    auth["signature"] = configuration["signature"]
    for k, v in configuration["resources"].pairs:
      auth["access"][k] = newJObject()
      for meth, content in v.pairs:
        if content.hasKey("auth"):
          auth["access"][k][meth] = content["auth"]

proc processConfigSettings() =
  # Process config settings if present and if no cli settings are set
  if LS.config != newJNull() and LS.config.hasKey("settings"):
    let settings = LS.config["settings"]
    let cliSettings = LS.cliSettings
    if not cliSettings.hasKey("address") and settings.hasKey("address"):
      LS.address = settings["address"].getStr
    if not cliSettings.hasKey("port") and settings.hasKey("port"):
      LS.port = settings["port"].getInt
    if not cliSettings.hasKey("store") and settings.hasKey("store"):
      LS.file = settings["store"].getStr
    if not cliSettings.hasKey("directory") and settings.hasKey("directory"):
      LS.directory = settings["directory"].getStr
    if not cliSettings.hasKey("middleware") and settings.hasKey("middleware"):
      let val = settings["middleware"].getStr
      for file in val.walkDir():
        if file.kind == pcFile or file.kind == pcLinkToFile:
          LS.middleware[file.path.splitFile[1]] = file.path.readFile()
    if not cliSettings.hasKey("log") and settings.hasKey("log"):
      LS.logLevel = settings["log"].getStr
      setLogLevel(LS.logLevel)
    if not cliSettings.hasKey("mount") and settings.hasKey("mount"):
      LS.mount = settings["mount"].getBool
    if not cliSettings.hasKey("readonly") and settings.hasKey("readonly"):
      LS.readonly = settings["readonly"].getBool

proc executeOperation*() =
  let file = LS.execution.file
  let body = LS.execution.body
  let ctype = LS.execution.ctype
  let uri = LS.execution.uri
  let operation = LS.execution.operation
  var req:LSRequest
  case operation.toUpperAscii:
    of "GET":
      req.reqMethod = HttpGet
    of "POST":
      req.reqMethod = HttpPost
    of "PUT":
      req.reqMethod = HttpPut
    of "PATCH":
      req.reqMethod = HttpPatch
    of "DELETE":
      req.reqMethod = HttpDelete
    of "OPTIONS":
      req.reqMethod = HttpOptions
    of "HEAD":
      req.reqMethod = HttpHead
    else:
      fail(203, "Operation '$1' is not supported" % [operation])
  if body.len > 0:
    req.body = body
  elif file.len > 0:
    req.body = file.readFile
  req.headers = newHttpHeaders()
  if ctype.len > 0:
    req.headers["Content-Type"] = ctype
  req.hostname = "<cli>"
  req.url = parseUri("$1://$2:$3/$4" % @["http", "localhost", "9500", uri])
  let resp = req.process(LS)
  echo resp.content
  if resp.code.int < 300 and resp.code.int >= 200:
    quit(0)
  else:
    quit(resp.code.int)

proc setup*(open = true) =
  if not LS.file.fileExists:
    try:
      LOG.debug("Creating datastore: ", LS.file)
      LS.file.createDatastore()
    except:
      eWarn()
      fail(200, "Unable to create datastore '$1'" % [LS.file])
  if (open):
    try:
      LS.store = LS.file.openDatastore()
      try:
        LS.store.upgradeDatastore()
      except:
        echo getCurrentExceptionMsg()
        fail(203, "Unable to upgrade datastore '$1'" % [LS.file])
      if LS.mount:
        try:
          LS.store.mountDir(LS.directory)
        except:
          eWarn()
          fail(202, "Unable to mount directory '$1'" % [LS.directory])
    except:
      fail(201, "Unable to open datastore '$1'" % [LS.file])

when isMainModule:

  # Manage vacuum operation separately
  if LS.operation == opVacuum:
    setup(false)
    vacuum LS.file
  else:
    # Open Datastore
    setup(true)

  if LS.configFile == "":
    # Attempt to retrieve config.json from system documents
    let options = newQueryOptions(true)
    let rawDoc = LS.store.retrieveRawDocument("config.json", options)
    if rawDoc != "":
      LS.config = rawDoc.parseJson()["data"]

  if LS.config != newJNull():
    # Process config settings
    processConfigSettings()
    # Process auth from config settings
    processAuthConfig(LS.config, LS.auth)

  if LS.auth == newJNull():
    # Attempt to retrieve auth.json from system documents
    let options = newQueryOptions(true)
    let rawDoc = LS.store.retrieveRawDocument("auth.json", options)
    if rawDoc != "":
      LS.auth = rawDoc.parseJson()["data"]

  # Validation
  if LS.directory == "" and (LS.operation in [opDelete, opImport, opExport] or LS.mount):
    fail(105, "--directory option not specified.")

  if LS.execution.file == "" and (LS.execution.operation in ["put", "post", "patch"]):
    fail(109, "--file option not specified")

  if LS.execution.uri == "" and LS.operation == opExecute:
    fail(110, "--uri option not specified")

  if LS.execution.operation == "" and LS.operation == opExecute:
    fail(111, "--operation option not specified")
  
  case LS.operation:
    of opRun:
      LS.serve
      runForever()
    of opImport:
      LS.store.importDir(LS.directory, LS.manageSystemData)
    of opExport:
      LS.store.exportDir(LS.directory, LS.manageSystemData)
    of opDelete:
      LS.store.deleteDir(LS.directory, LS.manageSystemData)
    of opOptimize:
      LS.store.optimize
    of opExecute:
      executeOperation()
    else:
      discard

else:

  proc params*(query: string): StringTableRef =
    new(result)
    let pairs = query.split("&")
    for pair in pairs:
      let data = pair.split("=")
      result[data[0]] = data[1]

  proc query*(table: StringTableRef): string =
    var params = newSeq[string](0)
    for key, value in pairs(table):
      params.add("$1=$2" % @[key, value])
    return params.join("&")

  proc newLSRequest(meth: HttpMethod, resource, id,  body = "", params = newStringTable(), headers = newHttpHeaders()): LSRequest =
    result.reqMethod = meth
    result.body = body
    result.headers = headers
    result.url = parseUri("$1://$2:$3/$4/$5?$6" % @["http", "localhost", "9500", resource, id, params.query()])

  # Public API: Low-level

  proc getInfo*(): LSResponse =
    return LS.getInfo(newLSRequest("info"))

  proc getRawDocuments*(options = newQueryOptions()): LSResponse =
    return LS.getRawDocuments(options, newLSRequest("docs"))

  proc getDocument*(id: string, options = newQueryOptions()): LSResponse =
    return LS.getDocument(id, options, newLSRequest("docs", id))

  proc getRawDocument*(id: string, options = newQueryOptions()): LSResponse =
    return LS.getRawDocument(id, options, newLSRequest("docs", id))

  proc deleteDocument*(id: string): LSResponse =
    return LS.deleteDocument(id, newLSRequest("docs", id))

  proc postDocument*(body, ct: string, folder=""): LSResponse =
    return LS.postDocument(body, ct, folder, newLSRequest("docs", "", body))

  proc putDocument*(id, body, ct: string): LSResponse =
    return LS.putDocument(id, body, ct newLSRequest("docs", id, body))

  proc patchDocument*(id, body: string): LSResponse =
    return LS.patchDocument(id, body, newLSRequest("docs", id, body))

  # Public API: High-level

  proc get*(resource, id: string, params = newStringTable(), headers = newHttpHeaders()): LSResponse =
    return newLSRequest(HttpGet, resource, id, "", params, headers).get(LS, resource, id)

  proc post*(resource, folder, body: string, headers = newHttpHeaders()): LSResponse =
    return newLSRequest(HttpPost, resource, "", body, newStringTable(), headers).post(LS, resource, folder & "/")

  proc put*(resource, id, body: string, headers = newHttpHeaders()): LSResponse =
    return newLSRequest(HttpPut, resource, id, body, newStringTable(), headers).put(LS, resource, id)

  proc patch*(resource, id, body: string, headers = newHttpHeaders()): LSResponse =
    return newLSRequest(HttpPatch, resource, id, body, newStringTable(), headers).patch(LS, resource, id)

  proc delete*(resource, id: string, headers = newHttpHeaders()): LSResponse =
    return newLSRequest(HttpPatch, resource, id, "", newStringTable(), headers).delete(LS, resource, id)

  proc head*(resource, id: string, headers = newHttpHeaders()): LSResponse =
    return newLSRequest(HttpHead, resource, id, "", newStringTable(), headers).head(LS, resource, id)

  proc options*(resource, id: string, headers = newHttpHeaders()): LSResponse =
    return newLSRequest(HttpOptions, resource, id, "", newStringTable(), headers).options(LS, resource, id)
