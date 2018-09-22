## Nim API Reference

Besides exposing an HTTP API, LiteStore also provides a basic Nim API to use it as a library within other Nim projects.

### Data Types

The following data types are used by the LiteStore Nim API [proc](class:kwd)s

#### LSResponse

An HTTP Response.

```
LSResponse* = tuple[
  code: HttpCode,
  content: string,
  headers: HttpHeaders]
```

#### QueryOptions

The set of options SQL-like to be used to compose a LiteStore query.

```
QueryOptions* = object
  select*: seq[string]
  single*:bool         
  limit*: int           
  offset*: int           
  orderby*: string      
  tags*: string
  folder*: string
  search*: string
```


### Example: Jester Web Framework Integration

The following code example shows how to use the [proc](class:kwd)s provided by LiteStore Nim API to expose LiteStore HTTP routes using the [Jester](https://github.com/dom96/jester) web framework for Nim:

```
import 
  jester,
  litestore, 
  asyncdispatch, 
  re, 
  strtabs, 
  asyncnet

litestore.setup()

routes:

  # Just a simple, unrelated Jester route
  get "/": 
    resp "Hello, World!"
  
  # Remapping LiteStore routes on Jester
  get re"^\/litestore\/(docs|info)\/?(.*)":
    let r = get(request.matches[0], 
                request.matches[1], 
                request.params, 
                request.headers)
    resp(r.code, r.content, r.headers["Content-Type"]) 

  post re"^\/litestore\/docs\/?(.*)":
    let r = post("docs", 
                 request.matches[0], 
                 request.body, 
                 request.headers)
    resp(r.code, r.content, r.headers["Content-Type"]) 

  put re"^\/litestore\/docs\/?(.*)":
    let r = put("docs", 
                request.matches[0], 
                request.body, 
                request.headers)
    resp(r.code, r.content, r.headers["Content-Type"]) 

  patch re"^\/litestore\/docs\/?(.*)":
    let r = patch("docs", 
                  request.matches[0], 
                  request.body, 
                  request.headers)
    resp(r.code, r.content, r.headers["Content-Type"]) 

  delete re"^\/litestore\/docs\/?(.*)":
    let r = delete("docs", 
                   request.matches[0], 
                   request.headers)
    resp(r.code, r.content) 

  head re"^\/litestore\/docs\/?(.*)":
    let r = head("docs", 
                 request.matches[0], 
                 request.headers)
    headers = newStringTable()
    for key, value in r.headers.pairs:
      headers[key] = value
    await response.sendHeaders(r.code, headers)
    response.client.close()

  options re"^\/litestore\/docs\/?(.*)":
    let r = options("docs", 
                    request.matches[0], 
                    request.headers)
    headers = newStringTable()
    for key, value in r.headers.pairs:
      headers[key] = value
    await response.sendHeaders(r.code, headers)
    response.client.close()

runForever()

```



