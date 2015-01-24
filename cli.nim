import
  parseopt2,
  strutils
import
  types


const 
  version* = "1.0"
  usage* = "  LiteStore v"& version & " - Lightweight REST Document Store" & """
  (c) 2015 Fabio Cevasco

  Usage:
    LS [-p:<port> -a:<address>] [<file>] [--pack:<directory> | --unpack:<directory>] 

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
  port = 9500
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

var LS*: LiteStore

LS.port = port
LS.address = address
LS.operation = operation
LS.file = file
LS.directory = directory
LS.appversion = version
LS.appname = "LiteStore"
