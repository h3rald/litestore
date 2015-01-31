import db_sqlite, pegs, asynchttpserver2, strtabs 

type 
  EDatastoreExists* = object of Exception
  EDatastoreDoesNotExist* = object of Exception
  EDatastoreUnavailable* = object of Exception
  EInvalidTag* = object of Exception
  EDirectoryNotFound* = object of Exception
  EInvalidRequest* = object of Exception
  Datastore* = object
    db*: TDbConn
    path*: string
  QueryOptions* = object
    select*: string
    single*:bool         
    limit*: int           
    orderby*: string      
    tags*: string
    search*: string
  TagExpression* = object
    tag*: string
    startswith*: bool
    endswith*: bool
    negated*: bool
  Operation* = enum opRun, opPack, opUnpack
  LiteStore* = object
    store*: Datastore
    address*: string
    port*: int
    operation*: Operation
    directory*: string
    file*: string
    appname*: string
    appversion*: string
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
^\$? [a-zA-Z0-9_\-?~:.@#^!]+$
"""

let PEG_USER_TAG* = peg"""
^[a-zA-Z0-9_\-?~:.@#^!]+$
"""

let PEG_URL* = peg"""
  ^\/{(v\d+)} \/ {([^\/]+)} (\/ {(.+)} / \/?)$
"""

const 
  CT_JSON* = {"Content-Type": "application/json"}

proc ctHeader*(ct: string): StringTableRef =
  return {"Content-Type": ct}.newStringTable

proc ctJsonHeader*(): StringTableRef =
  return CT_JSON.newStringTable

proc newQueryOptions*(): QueryOptions =
  return QueryOptions(select: "*", single: false, limit: 0, orderby: "", tags: "", search: "")
