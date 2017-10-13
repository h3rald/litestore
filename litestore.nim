import 
  lib/x_sqlite3, 
  lib/x_db_sqlite as db, 
  strutils, 
  os,
  oids,
  times,
  json,
  pegs, 
  uri,
  strtabs,
  httpcore,
  cgi,
  base64
import
  lib/types,
  lib/logger,
  lib/utils, 
  lib/core,
  lib/cli,
  lib/server

export
  types,
  server

from asyncdispatch import runForever

{.compile: "vendor/sqlite/libsqlite3.c".}
{.passC: "-DSQLITE_ENABLE_FTS3=1 -DSQLITE_ENABLE_FTS3_PARENTHESIS -DSQLITE_ENABLE_JSON1".}

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

  case LS.operation:
    of opRun:
      LS.serve
      runForever()
    of opImport:
      LS.store.importDir(LS.directory)
    of opExport:
      LS.store.exportDir(LS.directory)
    of opDelete:
      LS.store.deleteDir(LS.directory)
    of opOptimize:
      LS.store.optimize
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
      params.add("$1=$2" % @[key, value.encodeUrl])
    return params.join("&")

  proc newLSRequest(meth: HttpMethod, resource, id,  body = "", params = newStringTable(), headers = newHttpHeaders()): LSRequest = 
    result.reqMethod = meth
    result.body = body
    result.headers = headers
    result.url = parseUri("$1://$2:$3/$4/$5?$6" % @["http", "localhost", "9500", resource, id, params.query()])

  # Public API: Low-level

  proc getInfo*(): LSResponse =
    return LS.getInfo()

  proc getRawDocuments*(options = newQueryOptions()): LSResponse =
    return LS.getRawDocuments(options)

  proc getDocument*(id: string, options = newQueryOptions()): LSResponse =
    return LS.getDocument(id, options)

  proc getRawDocument*(id: string, options = newQueryOptions()): LSResponse =
    return LS.getRawDocument(id, options)

  proc deleteDocument*(id: string): LSResponse =
    return LS.deleteDocument(id)

  proc postDocument*(body, ct: string, folder=""): LSResponse =
    return LS.postDocument(body, ct, folder)

  proc putDocument*(id, body, ct: string): LSResponse =
    return LS.putDocument(id, body, ct)

  proc patchDocument*(id, body: string): LSResponse =
    return LS.patchDocument(id, body)

  # Public API: High-level

  proc get*(resource, id: string, params = newStringTable(), headers = newHttpHeaders()): LSResponse =
    return newLSRequest(HttpGet, resource, id, "", params, headers).get(LS, resource, id)

  proc post*(resource, id, body: string, headers = newHttpHeaders()): LSResponse =
    return newLSRequest(HttpPost, resource, id, body, newStringTable(), headers).post(LS, resource, id)

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
