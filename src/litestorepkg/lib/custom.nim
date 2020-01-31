import 
    json,
    asynchttpserver,
    strtabs,
    duktape,
    httpcore,
    tables
import
    types,
    utils

proc createRequest(LS: LiteStore, ctx: DTContext, obj: duk_idx_t, req: LSRequest) =
  var req_idx = ctx.duk_push_object()
  discard ctx.duk_push_string($req.reqMethod)
  discard ctx.duk_put_prop_string(req_idx, "method")
  # url
  var uri_idx = ctx.duk_push_object()
  discard ctx.duk_push_string(LS.address)
  discard ctx.duk_put_prop_string(uri_idx, "hostname")
  ctx.duk_push_int(cast[cint](LS.port))
  discard ctx.duk_put_prop_string(uri_idx, "port")
  discard ctx.duk_push_string(req.url.query)
  discard ctx.duk_put_prop_string(uri_idx, "search")
  discard ctx.duk_push_string(req.url.path)
  discard ctx.duk_put_prop_string(uri_idx, "path")
  discard ctx.duk_put_prop_string(req_idx, "url")
  discard ctx.duk_push_string(req.body)
  discard ctx.duk_put_prop_string(req_idx, "body")
  var hd_idx = ctx.duk_push_object()
  for k, v in pairs(req.headers):
    discard ctx.duk_push_string(v)
    discard ctx.duk_put_prop_string(hd_idx, k)
  discard ctx.duk_put_prop_string(req_idx, "headers")
  discard ctx.duk_put_prop_string(obj, "request")

proc createResponse(LS: LiteStore, ctx: DTContext, obj: duk_idx_t) =
  var res_idx = ctx.duk_push_object()
  ctx.duk_push_int(200)
  discard ctx.duk_put_prop_string(res_idx, "code")
  discard ctx.duk_push_string("")
  discard ctx.duk_put_prop_string(res_idx, "content")
  var hd_idx = ctx.duk_push_object()
  discard ctx.duk_push_string("*")
  discard ctx.duk_put_prop_string(hd_idx, "Access-Control-Allow-Origin")
  discard ctx.duk_push_string("Authorization, Content-Type")
  discard ctx.duk_put_prop_string(hd_idx, "Access-Control-Allow-Headers")
  discard ctx.duk_push_string(LS.appname & "/" & LS.appversion)
  discard ctx.duk_put_prop_string(hd_idx, "Server")
  discard ctx.duk_push_string("application/json")
  discard ctx.duk_put_prop_string(hd_idx, "Content-Type")
  discard ctx.duk_put_prop_string(res_idx, "headers")
  discard ctx.duk_put_prop_string(obj, "response")
      

proc execute*(req: LSRequest, LS:LiteStore, id: string): LSResponse =
  # Create execution context
  var ctx = duk_create_heap_default()
  duk_console_init(ctx)
  duk_print_alert_init(ctx)
  var ctx_idx = ctx.duk_push_object()
  LS.createRequest(ctx, ctx_idx, req)
  LS.createResponse(ctx, ctx_idx)
  discard ctx.duk_put_global_string("ctx")
  # Evaluate custom resource 
  try:
    ctx.duk_eval_string(LS.customResources[id])
  except:
    return resError(Http500, "An error occurred when executing custom resource code.")
  # Retrieve response
  ctx.duk_eval_string("JSON.stringify(ctx.response)")
  let jResponse = parseJson($(ctx.duk_get_string(-1)))
  ctx.duk_destroy_heap();
  result.code = HttpCode(jResponse["code"].getInt)
  result.content = jResponse["content"].getStr
  result.headers = newHttpHeaders()
  for k, v in pairs(jResponse["headers"]):
    result.headers[k] = v.getStr
  result.headers["Content-Length"] = $result.content.len
