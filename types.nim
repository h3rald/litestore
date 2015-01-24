import db_sqlite 
from asynchttpserver import HttpCode 
from strtabs import StringTableRef, newStringTable

type 
  EDatastoreExists* = object of Exception
  EDatastoreDoesNotExist* = object of Exception
  EDatastoreUnavailable* = object of Exception
  EInvalidTag* = object of Exception
  EDirectoryNotFound* = object of Exception
  Datastore* = object
    db*: TDbConn
    path*: string
  QueryOptions* = object
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

const 
  CT_JSON* = {"Content-type": "application/json"}

proc ctHeader*(ct: string): StringTableRef =
  return {"Content-type": ct}.newStringTable

proc ctJsonHeader*(): StringTableRef =
  return CT_JSON.newStringTable

proc newQueryOptions*(): QueryOptions =
  return QueryOptions(single: false, limit: 0, orderby: "", tags: "", search: "")
