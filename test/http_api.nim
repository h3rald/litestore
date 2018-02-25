import unittest, json, httpclient, strutils, os

suite "LiteStore HTTP API":

  var contents = newSeq[JsonNode](0)
  for i in 1..8:
    contents.add parseFile("data/$1.json" % i.intToStr)
  var rpost: Response;
  var ids = newSeq[string](0)

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

  proc total(resp: Response): BiggestInt =
    return resp.body.parseJson["total"].getNum

  setup:
    var count = 0
    for c in contents:
      rpost = jpost("docs/test/", c)
      var id = rpost.body.parseJson["id"].getStr
      ids.add(id)
      var ops = """
      [
        {"op": "add", "path": "/tags/3", "value": "tag1$1"},
        {"op": "add", "path": "/tags/4", "value": "tag$2"}
      ]
      """ % [$count, $(count mod 2)]
      discard jpatch("docs/" & ids[count], ops.parseJson)
      count += 1

  teardown:
    for i in ids:
      jdelete("docs/$1" % i)
    ids = newSeq[string](0)


  test "GET info":
    check(info("datastore_version") == %1)

  test "POST document":
    var rpost = jpost("docs", contents[0])
    var id = rpost.body.parseJson["id"].getStr
    check(rpost.body.parseJson["data"]["_id"] == %"5a6c566020d0d4ba242d6501")
    var rget = jget("docs/$1" % id)
    check(rget.body.parseJson["_id"] == %"5a6c566020d0d4ba242d6501")
    var rdel = jdelete("docs/$1" % id)
    check(rdel.status == "204 No Content")
    check(info("total_documents") == %8)
    rpost = jpost("docs/f1/f2/", contents[0])
    id = rpost.body.parseJson["id"].getStr
    check(id.startsWith("f1/f2/"))
    check(rpost.body.parseJson["data"]["_id"] == %"5a6c566020d0d4ba242d6501")
    rget = jget("docs/$1" % id)
    check(rget.body.parseJson["_id"] == %"5a6c566020d0d4ba242d6501")
    check(info("total_documents") == %9)
    rdel = jdelete("docs/$1" % id)
    check(rdel.status == "204 No Content")
    check(info("total_documents") == %8)

  test "DELETE document":
    for i in ids:
      jdelete("docs/$1" % i)
    ids = newSeq[string](0)

  test "PUT document":
    var rput = jput("docs/" & ids[5], contents[0])
    var id = rput.body.parseJson["id"].getStr
    check(id == ids[5])
    var rget = jget("docs/" & ids[5])
    check(rget.body.parseJson["_id"] == %"5a6c566020d0d4ba242d6501")

  test "PATCH document tags":
    var rget = jget("docs?tags=t1")
    check(rget.status == "404 Not Found")
    var ops = %*[
      {"op": "add", "path": "/tags/3", "value": "t1"},
      {"op": "add", "path": "/tags/4", "value": "t2"},
      {"op": "add", "path": "/tags/5", "value": "t3"}
    ]
    var rpatch = jpatch("docs/" & ids[0], ops)
    check(rpatch.status == "200 OK")
    rget = jget("docs/?tags=t1")
    check(rget.body.parseJson["total"] == %1)
    ops = %*[
      {"op": "add", "path": "/tags/3", "value": "t1"},
      {"op": "add", "path": "/tags/4", "value": "t3"}
    ]
    rpatch = jpatch("docs/" & ids[1], ops)
    check(rpatch.status == "200 OK")
    ops = %*[
      {"op": "add", "path": "/tags/3", "value": "t2"},
      {"op": "add", "path": "/tags/4", "value": "t3"}
    ]
    rpatch = jpatch("docs/" & ids[2], ops)
    check(rpatch.status == "200 OK")
    ops = %*[
      {"op": "replace", "path": "/tags/3", "value": "t4"},
      {"op": "remove", "path": "/tags/4"}
    ]
    rpatch = jpatch("docs/" & ids[0], ops)
    check(rpatch.status == "200 OK")
    rget = jget("docs/?tags=t2,t3")
    check(rget.body.parseJson["total"] == %1)
    check(info("total_documents") == %8)

  test "PATCH document data":
    var ops = %*[
      {"op": "remove", "path": "/data/name/first"},
      {"op": "add", "path": "/data/test", "value": 111},
      {"op": "replace", "path": "/data/friends/0", "value": {"id": 11, "name": "Tom Paris"}}
    ] 
    var rpatch = jpatch("docs/" & ids[0], ops)
    var data = rpatch.body.parseJson["data"]
    check(data["name"] == %*{"last": "Walters"})
    check(data["test"] == %111)
    check(data["friends"][0] == %*{"id": 11, "name": "Tom Paris"})
    ops = %*[
      {"op": "add", "path": "/data/not_added", "value": "!!!"},
      {"op": "test", "path": "/data/test", "value": 222},
      {"op": "replace", "path": "/data/test", "value": "!!!"}
    ] 
    rpatch = jpatch("docs/" & ids[0], ops)
    data = rpatch.body.parseJson["data"]
    check(data["test"] == %111)
    check(data.hasKey("not_added") == false)
    ops = %*[
      {"op": "replace", "path": "/data/test", "value": 222},
      {"op": "test", "path": "/data/test", "value": 222},
      {"op": "add", "path": "/data/not_added", "value": "!!!"}
    ] 
    rpatch = jpatch("docs/" & ids[0], ops)
    data = rpatch.body.parseJson["data"]
    check(data["test"] == %111)
    check(data.hasKey("not_added") == false)

  test "HEAD documents":
    var rhead = jhead("docs/invalid/")
    check(rhead.status == "404 Not Found")
    rhead = jhead("docs/test/")
    check(rhead.status == "200 OK")

  test "GET documents by tags":
    var rget = jget("docs/?tags=tag1")
    check(total(rget) == 4)
    rget = jget("docs/?tags=tag10,tag0")
    check(total(rget) == 1)
    rget = jget("docs/?tags=$type:application,$subtype:json")
    check(total(rget) == 8)

  test "GET documents by search":
    var rget = jget("docs/?search=Lorem&contents=false")
    check(rget.body.parseJson["total"] == %5)

  test "GET documents by filter":
    var rget = jget("docs/?filter=$.age%20gte%2034%20and%20$.age%20lte%2036%20and%20$.tags%20contains%20\"labore\"")
    check(rget.body.parseJson["total"] == %1)
    rget = jget("docs/?filter=$.age%20eq%2034%20or%20$.age%20eq%2036%20or%20$.eyeColor%20eq%20\"brown\"")
    check(rget.body.parseJson["total"] == %5)
    rget = jget("docs/?filter=$.name.first%20eq%20\"Jensen\"")
    check(rget.body.parseJson["total"] == %1)

  test "GET documents selecting fields":
    var rget = jget("docs/?select=$.age%20as%20age,$.email%20as%20email")
    var json = rget.body.parseJson
    var testdata = %*{
      "age": 36,
      "email": "lawson.logan@trasola.co.uk"
    }
    check(json["total"] == %8)
    check(json["results"][3]["data"] == testdata)
    rget = jget("docs/" & ids[2] & "?select=$.age%20as%20age&raw=true")
    json = rget.body.parseJson
    testdata = %*{
      "age": 31
    }
    check(json["data"] == testdata)

  test "GET documents sorting by fields":
    var rget = jget("docs/?sort=+$.age,+$.name.first")
    var json = rget.body.parseJson
    check(json["results"][2]["data"]["age"] == %31)
    check(json["results"][5]["data"]["name"]["first"] == %"Hart")

