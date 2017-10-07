import jester, ../litestore, asyncdispatch, uri, strutils, sequtils, httpcore

proc lsReq(req: jester.Request): LSRequest =
  var params = newSeq[string](0)
  for key, value in pairs(req.params):
    params.add("$1=$2" % @[key, value])
  let query = params.join("&")
  var protocol = "http"
  if req.secure:
    protocol = "https"
  result.reqMethod = req.reqMeth
  result.url = parseUri("$1://$2:$3/$4?$5" % @[protocol, req.host, $req.port, req.path, query])
  result.hostname = req.host
  result.body = req.body

LS.init()

routes:

  # Just a simple, unrelated Jester route
  get "/": 
    resp "Hello, World!"
  
  # Remapping LiteStore routes on Jester
  get "/litestore/@resource/@id?":
    let r = get(request.lsReq, LS, @"resource", @"id")
    resp(r.code, r.content, r.headers["content-type"]) 

  post "/litestore/@resource/@id?":
    let r = post(request.lsReq, LS, @"resource", @"id")
    resp(r.code, r.content, r.headers["content-type"]) 

  put "/litestore/@resource/@id?":
    let r = put(request.lsReq, LS, @"resource", @"id")
    resp(r.code, r.content, r.headers["content-type"]) 

  patch "/litestore/@resource/@id?":
    let r = patch(request.lsReq, LS, @"resource", @"id")
    resp(r.code, r.content, r.headers["content-type"]) 

  delete "/litestore/@resource/@id?":
    let r = delete(request.lsReq, LS, @"resource", @"id")
    resp(r.code, r.content, r.headers["content-type"]) 

  head "/litestore/@resource/@id?":
    let r = head(request.lsReq, LS, @"resource", @"id")
    resp(r.code, r.content, r.headers["content-type"]) 

  options "/litestore/@resource/@id?":
    let r = options(request.lsReq, LS, @"resource", @"id")
    resp(r.code, r.content, r.headers["content-type"]) 

runForever()
