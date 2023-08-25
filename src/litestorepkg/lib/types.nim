import 
  db_connector/db_sqlite, 
  asynchttpserver, 
  asyncnet,
  uri,
  pegs, 
  json,
  strtabs,
  strutils,
  sequtils,
  nativesockets,
  jwt,
  tables
import
  config

type
  EDatastoreExists* = object of CatchableError 
  EDatastoreDoesNotExist* = object of CatchableError
  EDatastoreUnavailable* = object of CatchableError
  EInvalidTag* = object of CatchableError
  EDirectoryNotFound* = object of CatchableError
  EFileNotFound* = object of CatchableError
  EFileExists* = object of CatchableError
  EInvalidRequest* = object of CatchableError
  ConfigFiles* = object
    auth*: string
    config*: string
  ExecutionData* = object
    operation*: string
    file*: string
    body*: string
    ctype*: string
    uri*: string
  Datastore* = object
    db*: DbConn
    path*: string
    mount*: string
  QueryOptions* = object
    tables*: seq[string]
    jsonFilter*: string
    jsonSelect*: seq[tuple[path: string, alias: string]]
    select*: seq[string]
    single*:bool
    system*:bool
    limit*: int
    offset*: int
    orderby*: string
    tags*: string
    like*: string
    createdAfter*: string
    createdBefore*: string
    modifiedAfter*: string
    modifiedBefore*: string
    folder*: string
    search*: string
  TagExpression* = object
    tag*: string
    startswith*: bool
    endswith*: bool
    negated*: bool
  Operation* = enum
    opRun,
    opImport,
    opExport,
    opDelete,
    opVacuum,
    opOptimize,
    opExecute
  LogLevel* = enum
    lvDebug
    lvInfo
    lvWarn
    lvError
    lvNone
  Logger* = object
    level*: LogLevel
  LiteStore* = object
    store*: Datastore
    execution*: ExecutionData
    address*: string
    port*: int
    operation*: Operation
    config*: JsonNode
    configFile*: string
    cliSettings*: JsonNode
    directory*: string
    manageSystemData*: bool
    file*: string
    importTags*: bool
    notSerachable*: bool
    mount*: bool
    readonly*: bool
    appname*: string
    middleware*: StringTableRef
    appversion*: string
    auth*: JsonNode
    authFile*: string
    favicon*:string
    loglevel*:string
  LSRequest* = object
    reqMethod*: HttpMethod
    headers*: HttpHeaders
    protocol*: tuple[orig: string, major, minor: int]
    url*: Uri
    jwt*: JWT
    hostname*: string 
    body*: string
  LSResponse* = object
    code*: HttpCode
    content*: string
    headers*: HttpHeaders
  ResourceInfo* = tuple[
    resource: string,
    id: string,
    version: string
  ]

proc initLiteStore*(): LiteStore = 
  result.config = newJNull()
  result.configFile = ""
  result.cliSettings = newJObject()
  result.directory = ""
  result.manageSystemData = false
  result.file = ""
  result.mount = false
  result.readonly = false
  result.loglevel = "warn"
  result.auth = newJNull()
  result.authFile = ""

proc httpMethod*(meth: string): HttpMethod =
  case meth:
    of "GET":
      return HttpGet
    of "POST":
      return HttpPost
    of "PUT":
      return HttpPut
    of "HEAD":
      return HttpHead
    of "PATCH":
      return HttpPatch
    of "OPTIONS":
      return HttpOptions
    of "DELETE":
      return HttpDelete
    else:
      return HttpGet
  

proc `%`*(protocol: tuple[orig: string, major: int, minor: int]): JsonNode =
  result = newJObject()
  result["orig"] = %protocol.orig
  result["major"] = %protocol.major
  result["minor"] = %protocol.minor

proc `%`*(code: HttpCode): JsonNode =
  return %(int(code))

proc `%`*(table: Table[string, seq[string]]): JsonNode =
  result = newJObject()
  for k, v in table:
    result[k] = %v

proc `%`*(req: LSRequest): JsonNode =
  result = newJObject()
  result["method"] = %($req.reqMethod)
  result["jwt"] = newJObject();
  if req.jwt.signature.len > 0:
    result["jwt"]["header"] = %req.jwt.header
    result["jwt"]["claims"] = %req.jwt.claims
  result["headers"] = newJObject()
  let headers = %req.headers
  result["headers"] = newJObject()
  for k, v in headers["table"].pairs:
    result["headers"][k] = %join(v.mapIt(it.getStr), ", ")
  result["protocol"] = %req.protocol.orig
  result["hostname"] = %req.url.hostname
  result["port"] = %req.url.port.parseInt
  result["path"] = %req.url.path
  result["query"] = %req.url.query
  result["content"] = %req.body

proc `%`*(res: LSResponse): JsonNode =
  result = newJObject()
  result["code"] = %($res.code)
  result["headers"] = %res.headers
  result["content"] = %res.content

proc newLSResponse*(res: JsonNode): LSResponse =
  result.code = HttpCode(res["code"].getInt)
  result.content = $res["content"]
  result.headers = newHttpHeaders()
  for k, v in res["headers"].pairs:
    result.headers[k] = v.getStr

proc newLSRequest*(req: JsonNode): LSRequest =
  result.reqMethod = httpMethod(req["method"].getStr)
  result.headers = newHttpHeaders()
  for k, v in req["headers"].pairs:
    result.headers[k] = v.getStr
  let protocol = req["protocol"].getStr
  let  parts = protocol.split("/")
  let version = parts[1].split(".")
  result.protocol = (orig: parts[0], major: version[0].parseInt, minor: version[1].parseInt)
  result.url = initUri()
  result.url.hostname = req["hostname"].getStr
  result.url.port = req["port"].getStr
  result.url.path = req["path"].getStr
  result.url.query = req["query"].getStr
  result.hostname = req["hostname"].getStr
  result.body = req["content"].getStr

proc newLSRequest*(req: Request): LSRequest =
  result.reqMethod = req.reqMethod
  result.headers = req.headers
  result.protocol = req.protocol
  result.url = req.url
  result.hostname = req.hostname
  result.body = req.body

proc newRequest*(req: LSRequest, client: AsyncSocket): Request =
  result.client = client
  result.reqMethod = req.reqMethod
  result.headers = req.headers
  result.protocol = req.protocol
  result.url = req.url
  result.hostname = req.hostname
  result.body = req.body

var
  PEG_TAG* {.threadvar.}: Peg
  PEG_USER_TAG* {.threadvar.}: Peg
  PEG_INDEX* {.threadvar}: Peg
  PEG_STORE* {.threadvar}: Peg
  PEG_JSON_FIELD* {.threadvar.}: Peg
  PEG_DEFAULT_URL* {.threadvar.}: Peg
  PEG_STORE_URL* {.threadvar.}: Peg
  PEG_URL* {.threadvar.}: Peg

PEG_TAG = peg"""^\$? [a-zA-Z0-9_\-?~:.@#^!+]+$"""
PEG_USER_TAG = peg"""^[a-zA-Z0-9_\-?~:.@#^!+]+$"""
PEG_INDEX = peg"""^[a-zA-Z0-9_]+$"""
PEG_STORE = peg"""^[a-zA-Z0-9_]+$"""
PEG_JSON_FIELD = peg"""'$' ('.' [a-z-A-Z0-9_]+)+"""
PEG_DEFAULT_URL = peg"""^\/{(assets / docs / info / dir / tags / indexes / stores)} (\/ {(.+)} / \/?)$"""
PEG_STORE_URL = peg"""^\/stores \/ {([a-z0-9_]+)} (\/ {(.+)} / \/?)$"""
PEG_URL = peg"""^\/({(v\d+)} \/) {([^\/]+)} (\/ {(.+)} / \/?)$"""

# Initialize LiteStore
var LS* {.threadvar.}: LiteStore
var LSDICT* {.threadvar.}: OrderedTable[string, LiteStore]
var TAB_HEADERS* {.threadvar.}: array[0..2, (string, string)]
LSDICT  = initOrderedTable[string, LiteStore]()

LS.appversion = pkgVersion
LS.appname = appname

TAB_HEADERS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "Authorization, Content-Type",
  "Server": LS.appname & "/" & LS.appversion
}

proc newQueryOptions*(system = false): QueryOptions =
  var select = @["documents.id AS id", "documents.data AS data", "content_type", "binary", "searchable", "created", "modified"]
  if system:
    select = @["system_documents.id AS id", "system_documents.data AS data", "content_type", "binary", "created", "modified"]
  return QueryOptions(select: select,
    single: false, limit: 0, offset: 0, orderby: "", tags: "", search: "", folder: "", like: "", system: system,
    createdAfter: "", createdBefore: "", modifiedAfter: "", modifiedBefore: "", jsonFilter: "", jsonSelect: newSeq[tuple[path: string, alias: string]](), tables: newSeq[string]())
