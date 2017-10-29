### High-Level Nim API

The following [proc](class:kwd)s map 1:1 to the corresponding HTTP methods. This API is recommended for most uses, as every method triggers exactly the same logic as the corresponding HTTP request.

{{ p-resource => resource
: The resource to perform the operation on ([info](class:kwd) or [docs](class:kwd)).}}
{{ p-params => params
: The parameters to pass to the operation (see the corresponding HTTP querystring parameters).}}
{{ p-id => id 
: The identifier of the resource (set to an empty string if not needed).}}
{{ p-body => body
: The request body. }}
{{ p-headers => headers 
: An [HttpHeaders](class:kwd) object containing the headers of the request. Use the [Content-Type](class:kwd) header to specify the content type of the [body](class:kwd) parameter.}}

#### get

     proc get*(resource, id: string, params = newStringTable(), headers = newHttpHeaders()): LSResponse

Retrieves a resource.

##### Parameters

{{p-resource}}
{{p-id}}
{{p-params}}
{{p-headers}}

#### post

     proc post*(resource, id, body: string, headers = newHttpHeaders()): LSResponse

Creates a new resource.

##### Parameters

{{p-resource}}
{{p-id}}
{{p-body}}
{{p-headers}}

#### put

     proc put*(resource, id, body: string, headers = newHttpHeaders()): LSResponse

Modifies an existing resource.

##### Parameters

{{p-resource}}
{{p-id}}
{{p-body}}
{{p-headers}}

#### patch

     proc patch*(resource, id, body: string, headers = newHttpHeaders()): LSResponse

Modifies the tags of an existing resource.

##### Parameters

{{p-resource}}
{{p-id}}
{{p-body}}
{{p-headers}}

#### delete

     proc delete*(resource, id: string, headers = newHttpHeaders()): LSResponse

Deletes an existing resource.

##### Parameters

{{p-resource}}
{{p-id}}
{{p-headers}}

#### head

     proc head*(resource, id: string, headers = newHttpHeaders()): LSResponse

Checks whether a resource exists or not.

##### Parameters

{{p-resource}}
{{p-id}}
{{p-headers}}

#### options

     proc options*(resource, id: string, headers = newHttpHeaders()): LSResponse

Checks what HTTP methods are supported by the specified resource.

##### Parameters

{{p-resource}}
{{p-id}}
{{p-headers}}
