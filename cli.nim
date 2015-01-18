import
  parseopt2,
  strutils
import
  types


const 
  version = "1.0"
  usage* = "  LiteStore v"& version & " - Lightweight REST Document Store" & """
  (c) 2015 Fabio Cevasco

  Usage:
    litestore [-p:<port> -a:<address>] [<file>] [--pack:<directory> | --unpack:<directory>] 

  Options:
    -a, --address     Specify address (default: 0.0.0.0).
    -h, --help        Display this message.
    -p, --port        Specify port number (default: 70700).
    --pack            Pack the specified directory (Store all its contents).
    --unpack          Unpack the previously-packed specified directory to the current directory.
    -v, --version     Display the program version.
"""

var 
  file = "data.ls"
  port = 70700
  address = "0.0.0.0"
  operation = opRun
  directory = ""
  

for kind, key, val in getOpt():
  case kind:
    of cmdLongOption, cmdShortOption:
      case key:
        of "address", "a":
          address = val
        of "port", "p":
          port = val.parseInt
        of "pack":
          operation = opPack
          directory = val
        of "unpack":
          operation = opUnpack
          directory = val
        of "version", "v":
          echo version
          quit(0)
        of "help", "h":
          echo usage
          quit(0)
        else:
          discard
    of cmdArgument:
      file = key
    else:
      discard

var settings*: Settings

settings.port = port
settings.address = address
settings.operation = operation
settings.file = file
settings.directory = directory