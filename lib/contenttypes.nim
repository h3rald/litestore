import json, strutils, strtabs


proc loadContentTypes(): StringTableRef =
  result = newStringTable(modeCaseInsensitive)
  const raw_json = "lib/contenttypes.json".slurp
  let json = raw_json.parseJson
  for item in json.items:
    for pair in item.pairs:
      result[$pair.key] = $pair.val

let CONTENT_TYPES* = loadContentTypes()

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
