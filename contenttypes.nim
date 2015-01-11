import mimetypes, strutils

let CONTENT_TYPES* = newMimetypes()

proc isBinary*(ct: string): bool =
  if ct.endsWith "xml":
    return false
  elif ct.endsWith "html":
    return false
  elif ct.endsWith "json":
    return false
  elif ct.endsWith "script":
    return false
  elif ct.endsWith "sql":
    return false
  elif ct.startsWith "audio/":
    return true
  elif ct.startsWith "image/":
    return true
  elif ct.startsWith "message/":
    return true
  elif ct.startsWith "model/":
    return true
  elif ct.startsWith "multipart/":
    return true
  elif ct.startsWith "text/":
    return false
  elif ct.startsWith "video/":
    return true
  else:
    return true

proc isTextual*(ct: string): bool =
  return not ct.isBinary
