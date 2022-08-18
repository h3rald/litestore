import
  parseopt,
  strutils,
  json, 
  os,
  strtabs
import
  core,
  config,
  types,
  utils

const favicon = "../../admin/favicon.ico".slurp

var
  operation = opRun
  directory:string = ""
  readonly = false
  logLevel = "warn"
  system = false
  importTags = false
  notSerachable = false
  mount = false
  auth = newJNull()
  middleware = newStringTable()
  configuration = newJNull()
  authFile = ""
  configFile = ""
  exOperation = ""
  exFile = ""
  exBody = ""
  exType = ""
  exUri = ""
  cliSettings = newJObject()

let
  usage* = appname & " v" & pkgVersion & " - Lightweight REST Document Store" & """

(c) 2015-2020 Fabio Cevasco

  Usage:
    litestore [command] [option1 option2 ...]

  Commands:
    delete              Delete a previously-imported specified directory (requires -d).
    execute             Execute an operation on data stored in the datastore (requires -o, -u, and in certain cases -f or -b and -t).
    import              Import the specified directory into the datastore (requires -d).
    export              Export the previously-imported specified directory to the current directory (requires -d).
    optimize            Optimize search indexes.
    vacuum              Vacuum datastore.

  Options:
    -a, --address       Specify server address (default: 127.0.0.1).
    --auth              Specify an authentication/authorization configuration file.
    -b, --body          Specify a string containing input data for an operation to be executed.
    -d, --directory     Specify a directory to serve, import, export, delete, or mount.
    -c, --config        Specify a configuration file.
    -f, --file          Specify a file containing input data for an operation to be executed.
    -h, --help          Display this message.
    -l, --log           Specify the log level: debug, info, warn, error, none (default: info)
    -m, --mount         Mirror database changes to the specified directory on the filesystem.
    -o, --operation     Specify an operation to execute via the execute command: get, put, delete, patch, post, head, options.
    -p, --port          Specify server port number (default: 9500).
    -r, --readonly      Allow only data retrieval operations.
    -s, --store         Specify a datastore file (default: data.db)
    --system            Set the system flag for import, export, and delete operations
    --import-tags       During import read tags from '_tags' file and apply them to imported documents from the same directory.
    --not-searchable    During import exclude content of files and folders starting with '_' from full text search.
    -t, --type          Specify a content type for the body an operation to be executed via the execute command.
    -u, --uri           Specify an uri to execute an operation through the execute command.
    -v, --version       Display the program version.
    -w, --middleware    Specify a path to a folder containing middleware definitions.
"""

proc run*() =
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
            cliSettings["address"] = %address
          of "port", "p":
            if val == "":
              fail(101, "Port not specified.")
            port = val.parseInt
            cliSettings["port"] = %port
          of "store", "s":
            file = val
            cliSettings["store"]  = %file
          of "system":
            system =  true
          of "log", "l":
            if val == "":
              fail(102, "Log level not specified.")
            setLogLevel(val)
            logLevel = val
            cliSettings["log"] = %logLevel
          of "directory", "d":
            if val == "":
              fail(104, "Directory not specified.")
            directory = val
            cliSettings["directory"] = %directory
          of "middleware", "w":
            if val == "":
              fail(115, "Middleware path not specified.")
            if not val.dirExists():
              fail(116, "Middleware directory does not exist.")
            for file in val.walkDir():
              if file.kind == pcFile or file.kind == pcLinkToFile:
                middleware[file.path.splitFile[1]] = file.path.readFile()
            cliSettings["middleware"] = %val
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
          of "auth":
            if val == "":
              fail(114, "Authentication/Authorization configuration file not specified.")
            authFile = val
          of "config", "c":
            if val == "":
              fail(115, "Configuration file not specified.")
            configuration = val.parseFile()
            configFile = val
          of "mount", "m":
            mount = true
            cliSettings["mount"] = %mount
          of "import-tags":
            importTags = true
            cliSettings["import-tags"] = %importTags
          of "not-searchable":
            notSerachable = true
            cliSettings["not-searchable"] = %notSerachable
          of "version", "v":
            echo pkgVersion
            quit(0)
          of "help", "h":
            echo usage
            quit(0)
          of "readonly", "r":
            readonly = true
            cliSettings["readonly"] = %readonly
          else:
            discard
      else:
        discard

  LS.config = configuration
  LS.configFile = configFile
  LS.operation = operation
  LS.address = address
  LS.port = port
  LS.file = file
  if LS.config != newJNull() and LS.config.hasKey("settings") and LS.config["settings"].hasKey("store"):
    # Need to be overridden before setup (called before config is initialized)
    LS.file = LS.config["settings"]["store"].getStr
  LS.directory = directory
  LS.readonly = readonly
  LS.favicon = favicon
  LS.logLevel = logLevel
  LS.cliSettings = cliSettings
  LS.auth = auth
  LS.manageSystemData = system
  LS.middleware = middleware
  LS.authFile = authFile
  LS.importTags = importTags
  LS.notSerachable = notSerachable
  LS.mount = mount
  LS.execution.file = exFile
  LS.execution.body = exBody
  LS.execution.ctype = exType
  LS.execution.uri = exUri
  LS.execution.operation = exOperation
