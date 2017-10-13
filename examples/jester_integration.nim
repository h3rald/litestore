import jester, ../litestore, asyncdispatch, re

litestore.setup()

routes:

  # Just a simple, unrelated Jester route
  get "/": 
    resp "Hello, World!"
  
  # Remapping LiteStore routes on Jester
  get re"^\/litestore\/(docs|info)\/?(.*)":
    let r = get(request.matches[0], request.matches[1], request.params, request.headers)
    resp(r.code, r.content, r.headers["Content-Type"]) 

  post re"^\/litestore\/docs\/?(.*)":
    let r = post("docs", request.matches[0], request.body, request.headers)
    resp(r.code, r.content, r.headers["Content-Type"]) 

  put re"^\/litestore\/docs\/?(.*)":
    let r = put("docs", request.matches[0], request.body, request.headers)
    resp(r.code, r.content, r.headers["Content-Type"]) 

  patch re"^\/litestore\/docs\/?(.*)":
    let r = patch("docs", request.matches[0], request.body, request.headers)
    resp(r.code, r.content, r.headers["Content-Type"]) 

  delete re"^\/litestore\/docs\/?(.*)":
    let r = delete("docs", request.matches[0], request.headers)
    resp(r.code, r.content) 

  head re"^\/litestore\/docs\/?(.*)":
    let r = head("docs", request.matches[0], request.headers)
    resp(r.code, r.content) 

  options re"^\/litestore\/docs\/?(.*)":
    let r = options("docs", request.matches[0], request.headers)
    resp(r.code, r.content) 

runForever()
