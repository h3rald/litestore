import
  parseopt,
  strutils,
  strtabs
import
  logger,
  config,
  types,
  utils

const favicon = "../admin/favicon.ico".slurp

var 
  operation = opRun
  directory:string = nil
  readonly = false
  logLevel = "warn"
  mount = false
  exOperation:string = nil
  exFile:string = nil
  exBody:string = nil
  exType:string = nil
  exUri:string = nil
  
let
  usage* = appname & " v" & version & " - Lightweight REST Document Store" & """
  
(c) 2015-2018 Fabio Cevasco

  Usage:
    litestore [command] [option1 option2 ...]

  Commands:
    run                 Start LiteStore server (default if no command specified).
    delete              Delete a previously-imported specified directory (requires -d).
    execute             Execute an operation on data stored in the datastore (requires -o, -u, and in certain cases -f or -b and -t).
    import              Import the specified directory into the datastore (requires -d).
    export              Export the previously-imported specified directory to the current directory (requires -d).
    optimize            Optimize search indexes.
    vacuum              Vacuum datastore.

  Options:
    -a, --address       Specify server address (default: 127.0.0.1).
    -b, --body          Specify a string containing input data for an operation to be executed.
    -d, --directory     Specify a directory to serve, import, export, delete, or mount.
    -b, --body          Specify a file containing input data for an operation to be executed.
    -h, --help          Display this message.
    -l, --log           Specify the log level: debug, info, warn, error, none (default: info)
    -m, --mount         Mirror database changes to the specified directory on the filesystem.
    -o, --operation     Specify an operation to execute via the execute command: get, put, delete, patch, post, head, options.
    -p, --port          Specify server port number (default: 9500).
    -r, --readonly      Allow only data retrieval operations.
    -s, --store         Specify a datastore file (default: data.db)
    -t, --type          Specify a content type for the body an operation to be executed via the execute command.
    -u, --uri           Specify an uri to execute an operation through the execute command.
    -v, --version       Display the program version.
"""

for kind, key, val in getOpt():
  case kind:
    of cmdArgument:
      case key:
        of "run":
          operation = opRun
        of "import":
          operation = opImport
        of "execute":
          operation = opExecute
        of "export":
          operation = opExport
        of "delete":
          operation = opDelete
        of "optimize":
          operation = opOptimize
        of "vacuum":
          operation = opVacuum
        else:
          discard
    of cmdLongOption, cmdShortOption:
      case key:
        of "address", "a":
          if val == "":
            fail(100, "Address not specified.")
          address = val
        of "port", "p":
          if val == "":
            fail(101, "Port not specified.")
          port = val.parseInt
        of "store", "s":
          file = val
        of "log", "l":
          if val == "":
            fail(102, "Log level not specified.")
          case val:
            of "info":
              LOG.level = lvInfo
            of "warn":
              LOG.level = lvWarn
            of "debug":
              LOG.level = lvDebug
            of "error":
              LOG.level = lvError
            of "none":
              LOG.level = lvNone
            else:
              fail(103, "Invalid log level '$1'" % val)
          loglevel = val
        of "directory", "d":
          if val == "":
            fail(104, "Directory not specified.")
          directory = val
        of "operation", "o":
          if val == "":
            fail(106, "Operation not specified.")
          exOperation = val
        of "file", "f":
          if val == "":
            fail(107, "File not specified.")
          exFile = val
        of "uri", "u":
          if val == "":
            fail(108, "URI not specified.")
          exUri = val
        of "body", "b":
          if val == "":
            fail(112, "Body not specified.")
          exBody = val
        of "type", "t":
          if val == "":
            fail(113, "Content type not specified.")
          exType = val
        of "mount", "m":
          mount = true
        of "version", "v":
          echo version
          quit(0)
        of "help", "h":
          echo usage
          quit(0)
        of "readonly", "r":
          readonly = true
        else:
          discard
    else:
      discard

# Validation

if directory.isNil and (operation in [opDelete, opImport, opExport] or mount):
  fail(105, "--directory option not specified.")

if exFile.isNil and (exOperation in ["put", "post", "patch"]):
  fail(109, "--file option not specified")

if exUri.isNil and operation == opExecute:
  fail(110, "--uri option not specified")

if exOperation.isNil and operation == opExecute:
  fail(111, "--operation option not specified")

LS.operation = operation
LS.address = address
LS.port = port
LS.file = file
LS.directory = directory
LS.readonly = readonly
LS.favicon = favicon
LS.loglevel = loglevel
LS.mount = mount
LS.execution.file = exFile
LS.execution.body = exBody
LS.execution.ctype = exType
LS.execution.uri = exUri
LS.execution.operation = exOperation
