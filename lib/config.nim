import
  parsecfg,
  streams,
  strutils

const
  cfgfile   = "../litestore.nimble".slurp

var
  file*     = "data.db"
  address*  = "127.0.0.1"
  appname*  = "LiteStore"
  port*     = 9500
  version*: string
  f = newStringStream(cfgfile)

if f != nil:
  var p: CfgParser
  open(p, f, "../litestore.nimble")
  while true:
    var e = next(p)
    case e.kind
    of cfgEof:
      break
    of cfgKeyValuePair:
      case e.key:
        of "version":
          version = e.value
        else:
          discard
    of cfgError:
      stderr.writeLine("Configuration error.")
      quit(1)
    else: 
      discard
  close(p)
else:
  stderr.writeLine("Cannot process configuration file.")
  quit(2)


