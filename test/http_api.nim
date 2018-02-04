import unittest, json, httpclient, strutils, os

suite "LiteStore HTTP API":

  var contents = newSeq[JsonNode](0)
  for i in 1..8:
    contents.add parseFile("data/$1.json" % i.intToStr)

  const srv = "http://localhost:9500/"
  let cli = newHttpClient()
  cli.headers = newHttpHeaders({ "Content-Type": "application/json" })

  proc jget(url: string): Response =
    return cli.request(srv & url, HttpGet)

  proc jhead(url: string): Response =
    return cli.request(srv & url, HttpHead)

  proc jpost(url: string, body: JsonNode): Response {.discardable.} =
    return cli.request(srv & url, HttpPost, $body)

  proc jput(url: string, body: JsonNode): Response {.discardable.} =
    return cli.request(srv & url, HttpPut, $body)

  proc jpatch(url: string, body: JsonNode): Response =
    return cli.request(srv & url, HttpPatch, $body)

  proc jdelete(url: string): Response {.discardable.} =
    return cli.request(srv & url, HttpDelete)

  proc info(prop: string): JsonNode =
    return jget("info").body.parseJson[prop]

  test "GET info":
    check(info("datastore_version") == %1)

  test "POST/GET/DELETE document":
    var rpost = jpost("docs", contents[0])
    var id = rpost.body.parseJson["id"].getStr
    check(rpost.body.parseJson["data"]["_id"] == %"5a6c566020d0d4ba242d6501")
    var rget = jget("docs/$1" % id)
    check(rget.body.parseJson["_id"] == %"5a6c566020d0d4ba242d6501")
    var rdel = jdelete("docs/$1" % id)
    check(rdel.status == "204 No Content")
    check(info("total_documents") == %0)
    rpost = jpost("docs/f1/f2/", contents[0])
    id = rpost.body.parseJson["id"].getStr
    check(id.startsWith("f1/f2/"))
    check(rpost.body.parseJson["data"]["_id"] == %"5a6c566020d0d4ba242d6501")
    rget = jget("docs/$1" % id)
    check(rget.body.parseJson["_id"] == %"5a6c566020d0d4ba242d6501")
    rdel = jdelete("docs/$1" % id)
    check(rdel.status == "204 No Content")
    check(info("total_documents") == %0)

  test "PUT/PATCH/GET/DELETE document":
    var rput = jput("docs/1", contents[0])
    var id = rput.body.parseJson["id"].getStr
    check(id == "1")
    var rget = jget("docs/1")
    check(rget.body.parseJson["_id"] == %"5a6c566020d0d4ba242d6501")
    rget = jget("docs?tags=t1")
    check(rget.status == "404 Not Found")
    var ops = """
    [
      {"op": "add", "path": "/tags/3", "value": "t1"},
      {"op": "add", "path": "/tags/4", "value": "t2"},
      {"op": "add", "path": "/tags/5", "value": "t3"}
    ]
    """
    var rpatch = jpatch("docs/1", ops.parseJson)
    check(rpatch.status == "200 OK")
    rget = jget("docs/?tags=t1")
    check(rget.body.parseJson["total"] == %1)
    rput = jput("docs/2", contents[1])
    ops = """
    [
      {"op": "add", "path": "/tags/3", "value": "t1"},
      {"op": "add", "path": "/tags/4", "value": "t3"}
    ]
    """
    rpatch = jpatch("docs/2", ops.parseJson)
    check(rpatch.status == "200 OK")
    rput = jput("docs/test/3", contents[2])
    rget = jget("docs/test/3")
    check(rget.body.parseJson["_id"] == %"5a6c5660d613e4c504bbf860")
    ops = """
    [
      {"op": "add", "path": "/tags/3", "value": "t2"},
      {"op": "add", "path": "/tags/4", "value": "t3"}
    ]
    """
    rpatch = jpatch("docs/test/3", ops.parseJson)
    check(rpatch.status == "200 OK")
    ops = """
    [
      {"op": "replace", "path": "/tags/3", "value": "t4"},
      {"op": "remove", "path": "/tags/4"}
    ]
    """
    rpatch = jpatch("docs/1", ops.parseJson)
    check(rpatch.status == "200 OK")
    rget = jget("docs/?tags=t2,t3")
    check(rget.body.parseJson["total"] == %1)
    jdelete("docs/1")
    jdelete("docs/2")
    jdelete("docs/test/3")
    check(info("total_documents") == %0)

  test "HEAD/GET documents":
    var ids = newSeq[string](0)
    var rpost: Response;
    for c in contents:
      rpost = jpost("docs/test/", c)
      ids.add(rpost.body.parseJson["id"].getStr)
    var rhead = jhead("docs/invalid/")
    check(rhead.status == "404 Not Found")
    rhead = jhead("docs/test/")
    check(rhead.status == "200 OK")
    var rget = jget("docs/?search=Lorem&contents=false")
    check(rget.body.parseJson["total"] == %5)
    rget = jget("docs/?filter=$.age%20gte%2034%20and%20$.age%20lte%2036%20and%20$.tags%20contains%20%22labore%22")
    check(rget.body.parseJson["total"] == %1)
    rget = jget("docs/?filter=$.age%20eq%2034%20or%20$.age%20eq%2036%20or%20$.eyeColor%20eq%20\"brown\"")
    check(rget.body.parseJson["total"] == %5)
    for i in ids:
      jdelete("docs/$1" % i)
    check(info("total_documents") == %0)
