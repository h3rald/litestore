import
  strutils,
  times

import
  types

proc currentTime*(plain = false): string =
  if plain:
    return getTime().utc.format("yyyy-MM-dd' @ 'HH:mm:ss")
  else:
    return getTime().utc.format("yyyy-MM-dd'T'HH:mm:ss'Z'")

proc msg(logger: Logger, kind, message: string, params: varargs[string, `$`]) =
  let s = format(message, params)
  if kind == "WARNING":
    stderr.writeLine(currentTime(true) & " " & kind & ": " & s)
  else:
    echo currentTime(true), " ", kind, ": ", s

proc error*(logger: Logger, message: string, params: varargs[string, `$`]) =
  if logger.level <= lvError:
    logger.msg("  ERROR", message, params)

proc warn*(logger: Logger, message: string, params: varargs[string, `$`]) =
  if logger.level <= lvWarn:
    logger.msg("WARNING", message, params)

proc info*(logger: Logger, message: string, params: varargs[string, `$`]) =
  if logger.level <= lvInfo:
    logger.msg("   INFO", message, params)

proc  debug*(logger: Logger, message: string, params: varargs[string, `$`]) =
  if logger.level <= lvDebug:
    logger.msg("  DEBUG", message, params)

var LOG* {.threadvar.}: Logger

LOG.level = lvWarn
