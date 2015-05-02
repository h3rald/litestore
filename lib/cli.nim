import
  parseopt2,
  parsecfg,
  streams,
  #logging,
  strutils
import
  types,
  utils

const cfgfile = "litestore.nimble".slurp
const favicon = "admin/favicon.ico".slurp

var 
  file*, address*, version*, appname*: string
  port*: int
  operation = opRun
  directory:string = nil
  readonly = false
  logLevelLabel = "INFO"
  #logLevel = lvlInfo
  mount = false
  reset = false
  
var f = newStringStream(cfgfile)
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
      fail(1, "Configuration error.")
    else: 
      discard
  close(p)
else:
  fail(2, "Cannot process configuration file.")

let
  usage* = appname & " v" & version & " - Lightweight REST Document Store" & """
  (c) 2015 Fabio Cevasco

  Usage:
    LS [command] [option1 option2 ...]

  Commands:
    run                 Starts LiteStore server.
    delete              Delete a previously-imported specified directory (requires -d).
    import              Import the specified directory into the datastore (requires -d).
    export              Export the previously-imported specified directory to the current directory (requires -d).
    optimize            Optimize search indexes.
    vacuum              Vacuum datastore.

  Options:
    -a, --address       Specify server address (default: 127.0.0.1).
    -d, --directory     Specify a directory to import, export, delete, or mount.
    -h, --help          Display this message.
    -l, --log           Specify the log level: debug, info, warn, error, fatal, none (default: info)
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
          try:
            discard
            #logLevelLabel = val.toUpper
            #logLevel = logging.LevelNames.find(logLevelLabel).Level
          except:
            fail(103, "Invalid log level '$1'" % val)
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

var LS* {.threadvar.}: LiteStore

LS.port = port
LS.address = address
LS.operation = operation
LS.file = file
LS.directory = directory
LS.appversion = version
LS.readonly = readonly
LS.appname = appname
LS.favicon = favicon
LS.loglevel = logLevelLabel
LS.mount = mount
LS.reset = reset

# Initialize loggers

#logging.level = logLevel
#logging.handlers.add(newConsoleLogger(logLevel, "$date $time - "))
#logging.handlers.add(newFileLogger("litestore.log.txt", fmAppend, logLevel, fmtStr = "$date $time - "))
