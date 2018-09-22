### High-Level Nim API

The following [proc](class:kwd)s map 1:1 to the corresponding HTTP methods. This API is recommended for most uses, as every method triggers exactly the same logic as the corresponding HTTP request.

#### get

     proc get*(resource, id: string, params = newStringTable(), headers = newHttpHeaders()): LSResponse

Retrieves a resource.

##### Parameters

<dl>
<dt>resource</dt>
<dd>The resource to perform the operation on ([info](class:kwd) or [docs](class:kwd)).</dd>
<dt>id</dt> 
<dd>The identifier of the resource (set to an empty string if not needed).</dd>
<dt>params</dt>
<dd>The parameters to pass to the operation (see the corresponding HTTP querystring parameters).</dd>
<dt>headers</dt>
<dd>An [HttpHeaders](class:kwd) object containing the headers of the request. Use the [Content-Type](class:kwd) header to specify the content type of the [body](class:kwd) parameter.</dd>
</dl>

#### post

     proc post*(resource, id, body: string, headers = newHttpHeaders()): LSResponse

Creates a new resource.

##### Parameters

<dl>
<dt>resource</dt>
<dd>The resource to perform the operation on ([info](class:kwd) or [docs](class:kwd)).</dd>
<dt>folder</dt>
<dd>The folder that will contain the resource (set to an empty string if not needed).</dd>
<dt>body</dt>
<dd>The request body.</dd>
<dt>headers</dt>
<dd>An [HttpHeaders](class:kwd) object containing the headers of the request. Use the [Content-Type](class:kwd) header to specify the content type of the [body](class:kwd) parameter.</dd>
</dl>

#### put

     proc put*(resource, id, body: string, headers = newHttpHeaders()): LSResponse

Modifies an existing resource.

##### Parameters

<dl>
<dt>resource</dt>
<dd>The resource to perform the operation on ([info](class:kwd) or [docs](class:kwd)).</dd>
<dt>id</dt> 
<dd>The identifier of the resource (set to an empty string if not needed).</dd>
<dt>body</dt>
<dd>The request body.</dd>
<dt>headers</dt>
<dd>An [HttpHeaders](class:kwd) object containing the headers of the request. Use the [Content-Type](class:kwd) header to specify the content type of the [body](class:kwd) parameter.</dd>
</dl>

#### patch

     proc patch*(resource, id, body: string, headers = newHttpHeaders()): LSResponse

Modifies the tags of an existing resource (or the data of a JSON document).

##### Parameters

<dl>
<dt>resource</dt>
<dd>The resource to perform the operation on ([info](class:kwd) or [docs](class:kwd)).</dd>
<dt>id</dt> 
<dd>The identifier of the resource (set to an empty string if not needed).</dd>
<dt>body</dt>
<dd>The request body.</dd>
<dt>headers</dt>
<dd>An [HttpHeaders](class:kwd) object containing the headers of the request. Use the [Content-Type](class:kwd) header to specify the content type of the [body](class:kwd) parameter.</dd>
</dl>

#### delete

     proc delete*(resource, id: string, headers = newHttpHeaders()): LSResponse

Deletes an existing resource.

##### Parameters

<dl>
<dt>resource</dt>
<dd>The resource to perform the operation on ([info](class:kwd) or [docs](class:kwd)).</dd>
<dt>id</dt> 
<dd>The identifier of the resource (set to an empty string if not needed).</dd>
<dt>headers</dt>
<dd>An [HttpHeaders](class:kwd) object containing the headers of the request. Use the [Content-Type](class:kwd) header to specify the content type of the [body](class:kwd) parameter.</dd>
</dl>

#### head

     proc head*(resource, id: string, headers = newHttpHeaders()): LSResponse

Checks whether a resource exists or not.

##### Parameters

<dl>
<dt>resource</dt>
<dd>The resource to perform the operation on ([info](class:kwd) or [docs](class:kwd)).</dd>
<dt>id</dt> 
<dd>The identifier of the resource (set to an empty string if not needed).</dd>
<dt>headers</dt>
<dd>An [HttpHeaders](class:kwd) object containing the headers of the request. Use the [Content-Type](class:kwd) header to specify the content type of the [body](class:kwd) parameter.</dd>
</dl>

#### options

     proc options*(resource, id: string, headers = newHttpHeaders()): LSResponse

Checks what HTTP methods are supported by the specified resource.

##### Parameters

<dl>
<dt>resource</dt>
<dd>The resource to perform the operation on ([info](class:kwd) or [docs](class:kwd)).</dd>
<dt>id</dt> 
<dd>The identifier of the resource (set to an empty string if not needed).</dd>
<dt>headers</dt>
<dd>An [HttpHeaders](class:kwd) object containing the headers of the request. Use the [Content-Type](class:kwd) header to specify the content type of the [body](class:kwd) parameter.</dd>
</dl>
