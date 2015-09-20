import
  parseopt2,
  strutils,
  strtabs
import
  logger,
  config,
  types,
  utils

const favicon = "admin/favicon.ico".slurp

var 
  operation = opRun
  directory:string = nil
  readonly = false
  logLevel = "info"
  mount = false
  
let
  usage* = appname & " v" & version & " - Lightweight REST Document Store" & """
  (c) 2015 Fabio Cevasco

  Usage:
    litestore [command] [option1 option2 ...]

  Commands:
    run                 Start LiteStore server (default if no command specified).
    delete              Delete a previously-imported specified directory (requires -d).
    import              Import the specified directory into the datastore (requires -d).
    export              Export the previously-imported specified directory to the current directory (requires -d).
    optimize            Optimize search indexes.
    vacuum              Vacuum datastore.

  Options:
    -a, --address       Specify server address (default: 127.0.0.1).
    -d, --directory     Specify a directory to import, export, delete, or mount.
    -h, --help          Display this message.
    -l, --log           Specify the log level: debug, info, warn, error, none (default: info)
    -m, --mount         Mirror database changes to the specified directory on the filesystem.
    -p, --port          Specify server port number (default: 9500).
    -r, --readonly      Allow only data retrieval operations.
    -s, --store         Specify a datastore file (default: data.db)
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

if directory == nil and (operation in [opDelete, opImport, opExport] or mount):
  fail(105, "Directory option not specified.")

LS.operation = operation
LS.directory = directory
LS.readonly = readonly
LS.favicon = favicon
LS.loglevel = loglevel
LS.mount = mount
