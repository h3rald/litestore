import 
  x_db_sqlite, 
  x_asynchttpserver, 
  pegs, 
  strtabs,
  parsecfg,
  strutils,
  streams

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
  Datastore* = object
    db*: TDbConn
    path*: string
    mount*: string
  MachineTag* = tuple[
    namespace: string,
    predicate: string,
    value: string
  ]
  QueryOptions* = object
    select*: seq[string]
    single*:bool         
    limit*: int           
    offset*: int           
    orderby*: string      
    tags*: seq[MachineTag]
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
    opOptimize
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
  Response* = tuple[
    code: HttpCode,
    content: string,
    headers: StringTableRef]
  ResourceInfo* = tuple[
    resource: string,
    id: string,
    version: string
  ]

const
  SYS_NAMESPACE* = "sys"
  SYS_COLLECTION_PREDICATE* = "dir"
  SYS_FORMAT_PREDICATE* = "format"
  SYS_TYPE_PREDICATE* = "type"
  SYS_SUBTYPE_PREDICATE* = "subtype"

var 
  PEG_NAMESPACE* {.threadvar.}: Peg
  PEG_PREDICATE* {.threadvar.}: Peg
  PEG_DEFAULT_URL* {.threadvar.}: Peg
  PEG_URL* {.threadvar.}: Peg

PEG_DEFAULT_URL = peg"""^\/{(docs / info)} (\/ {(.+)} / \/?)$"""
PEG_URL = peg"""^\/({(v\d+)} \/) {([^\/]+)} (\/ {(.+)} / \/?)$"""
PEG_NAMESPACE = peg"""^[a-z][a-z0-9_]+$"""
PEG_PREDICATE = peg"""^[a-z][a-z0-9_]+$"""

const cfgfile = "litestore.nimble".slurp

var
  file*, address*, version*, appname*: string
  port*: int
  f = newStringStream(cfgfile)

if f != nil:
  var p: CfgParser
  open(p, f, "litestore.nimble")
  while true:
    var e = next(p)
    case e.kind
    of cfgEof:
      break
    of cfgKeyValuePair:
      case e.key:
        of "version":
          version = e.value
        of "appame":
          appname = e.value
        of "port":
          port = e.value.parseInt
        of "address":
          address = e.value
        of "file":
          file = e.value
        else:
          discard
    of cfgError:
      stderr.writeln("Configuration error.")
      quit(1)
    else: 
      discard
  close(p)
else:
  stderr.writeln("Cannot process configuration file.")
  quit(2)

# Initialize LiteStore
var LS* {.threadvar.}: LiteStore
var TAB_HEADERS* {.threadvar.}: array[0..2, (string, string)]


LS.port = port
LS.address = address
LS.file = file
LS.appversion = version
LS.appname = appname

TAB_HEADERS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "Content-Type",
  "Server": LS.appname & "/" & LS.appversion
}

proc newQueryOptions*(): QueryOptions =
  return QueryOptions(select: @["documents.id AS id", "documents.data AS data", "content_type", "binary", "searchable", "created", "modified"], single: false, limit: 0, offset: 0, orderby: "", tags: newSeq[MachineTag](0), search: "")
