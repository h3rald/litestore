import db_sqlite, pegs, asynchttpserver2, strtabs 

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
  QueryOptions* = object
    select*: seq[string]
    single*:bool         
    limit*: int           
    offset*: int           
    orderby*: string      
    tags*: string
    search*: string
  TagExpression* = object
    tag*: string
    startswith*: bool
    endswith*: bool
    negated*: bool
  Operation* = enum opRun, opImport, opExport, opDelete
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
    reset*: bool
  Response* = tuple[
    code: HttpCode,
    content: string,
    headers: StringTableRef]
  ResourceInfo* = tuple[
    resource: string,
    id: string,
    version: string
  ]

let PEG_TAG* = peg"""
^\$? [a-zA-Z0-9_\-?~:.@#^!+]+$
"""

let PEG_USER_TAG* = peg"""
^[a-zA-Z0-9_\-?~:.@#^!+]+$
"""

let PEG_DEFAULT_URL* = peg"""
  ^\/{(docs / info)} (\/ {(.+)} / \/?)$
"""

let PEG_URL* = peg"""
  ^\/({(v\d+)} \/) {([^\/]+)} (\/ {(.+)} / \/?)$
"""

const 
  CT_JSON* = {"Content-Type": "application/json"}

proc ctHeader*(ct: string): StringTableRef =
  return {"Content-Type": ct}.newStringTable

proc ctJsonHeader*(): StringTableRef =
  return CT_JSON.newStringTable

proc newQueryOptions*(): QueryOptions =
  return QueryOptions(select: @["id", "data", "content_type", "binary", "searchable", "created", "modified"], single: false, limit: 0, offset: 0, orderby: "", tags: "", search: "")
