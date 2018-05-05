import 
  x_db_sqlite, 
  asynchttpserver, 
  pegs, 
  strtabs
import
  config

type 
  EDatastoreExists* = object of Exception
  EDatastoreDoesNotExist* = object of Exception
  EDatastoreUnavailable* = object of Exception
  EInvalidTag* = object of Exception
  EDirectoryNotFound* = object of Exception
  EFileNotFound* = object of Exception
  EFileExists* = object of Exception
  EInvalidRequest* = object of Exception
  uarray* {.unchecked.} [T] = array[0..0, T] 
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
    limit*: int           
    offset*: int           
    orderby*: string      
    tags*: string
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
    directory*: string
    file*: string
    mount*: bool
    readonly*: bool
    appname*: string
    appversion*: string
    favicon*:string
    loglevel*:string
  LSRequest* = asynchttpserver.Request
  LSResponse* = tuple[
    code: HttpCode,
    content: string,
    headers: HttpHeaders]
  ResourceInfo* = tuple[
    resource: string,
    id: string,
    version: string
  ]

var 
  PEG_TAG* {.threadvar.}: Peg
  PEG_USER_TAG* {.threadvar.}: Peg
  PEG_DEFAULT_URL* {.threadvar.}: Peg
  PEG_URL* {.threadvar.}: Peg

PEG_TAG = peg"""^\$? [a-zA-Z0-9_\-?~:.@#^!+]+$"""
PEG_USER_TAG = peg"""^[a-zA-Z0-9_\-?~:.@#^!+]+$"""
PEG_DEFAULT_URL = peg"""^\/{(docs / info / dir)} (\/ {(.+)} / \/?)$"""
PEG_URL = peg"""^\/({(v\d+)} \/) {([^\/]+)} (\/ {(.+)} / \/?)$"""

# Initialize LiteStore
var LS* {.threadvar.}: LiteStore
var TAB_HEADERS* {.threadvar.}: array[0..2, (string, string)]

LS.appversion = version
LS.appname = appname

TAB_HEADERS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "Content-Type",
  "Server": LS.appname & "/" & LS.appversion
}

proc newQueryOptions*(): QueryOptions =
  return QueryOptions(select: @["documents.id AS id", "documents.data AS data", "content_type", "binary", "searchable", "created", "modified"], single: false, limit: 0, offset: 0, orderby: "", tags: "", search: "", folder: "", jsonFilter: "", jsonSelect: newSeq[tuple[path: string, alias: string]](), tables: newSeq[string]())
