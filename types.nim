import db_sqlite

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
  Settings* = object
    store*: Datastore
    address*: string
    port*: int
    operation*: Operation
    directory*: string
    file*: string

proc newQueryOptions*(): QueryOptions =
  return QueryOptions(single: false, limit: 0, orderby: "", tags: "", search: "")