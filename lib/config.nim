import
  parsecfg,
  streams,
  strutils

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


