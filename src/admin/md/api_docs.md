### docs (LiteStore Documents)

A document is the main resource type managed by LiteStore. Any LiteStore document can be represented as a JSON object exposing the following properties:

* id: The unique identifier of the document.
* data: The document contents (base64-encoded if binary).
* created: The document creation date expressed as combined date and time in UTC ([ISO 8601](http://en.wikipedia.org/wiki/ISO_8601) compliant).
* modified: The document modification date (if applicable) expressed as combined date and time in UTC ([ISO 8601](http://en.wikipedia.org/wiki/ISO_8601) compliant).
* tags: A list of tags associated to the document.

> %note%
> JSON Documents
>
> Documents with content type "application/json" are special: their **data** property is _not_ set to a string like for all other textual and binary documents, but a real, non-escaped JSON object. This little quirk makes JSON documents _different_ from other documents, but also makes things so much easier when you just want to use LiteStore as a simple JSON document store.

#### Example Document

```
{
    "id": "test_document",
    "data": "This is a test document",
    "created": "2015-02-07T10:36:09Z",
    "modified": null,
    "tags": ["$type:text", "$subtype:plain", "$format:text", "another_tag"]
}
```

#### OPTIONS docs

Returns the allowed HTTP verbs for this resource.

##### Example

```
$ curl -i -X OPTIONS 'http://127.0.0.1:9500/docs'
HTTP/1.1 200 OK
Content-Length: 0
Access-Control-Allow-Methods: HEAD,GET,OPTIONS,POST
Allow: HEAD,GET,OPTIONS,POST
Access-Control-Allow-Headers: Content-Type
Access-Control-Allow-Origin: *
Server: LiteStore/1.1.0
```

#### OPTIONS docs/:id

Returns the allowed HTTP verbs for this resource.

##### Example

```
curl -i -X OPTIONS 'http://127.0.0.1:9500/docs/test' 
HTTP/1.1 200 OK
Content-Length: 0
Access-Control-Allow-Methods: HEAD,GET,OPTIONS
Allow: HEAD,GET,OPTIONS
Access-Control-Allow-Headers: Content-Type
Access-Control-Allow-Origin: *
Server: LiteStore/1.1.0
```

#### OPTIONS docs/:folder/

> %note%
> API v2 Required
> 
> This method has been introduced in version 2 of the LiteStore API.

Returns the allowed HTTP verbs for this resource.

##### Example

```
$ curl -i -X OPTIONS 'http://127.0.0.1:9500/docs/test/'
HTTP/1.1 200 OK
Content-Length: 0
Access-Control-Allow-Methods: HEAD,GET,OPTIONS,POST
Allow: HEAD,GET,OPTIONS
Access-Control-Allow-Headers: Content-Type
Access-Control-Allow-Origin: *
Server: LiteStore/1.1.0
```

#### POST docs

Creates a new document with a randomly-generated ID.

##### Example

```
$ curl -i -X POST -d 'A document with a randomly-generated ID.' 'http://127.0.0.1:9500/docs' -\-header "Content-Type:text/plain"
HTTP/1.1 201 Created
Content-Length: 197
Content-Type: application/json
Access-Control-Allow-Headers: Content-Type
Access-Control-Allow-Origin: *
Server: LiteStore/1.0.3

{"id": "555f93e82190e77500000000", "data": "A document with a randomly-generated ID.", "created": "2015-05-22T08:39:04Z", "modified": null, "tags": ["$type:text", "$subtype:plain", "$format:text"]}
```

#### POST docs/:folder/

Creates a new document with a randomly-generated ID under the specified folder path.

##### Example

```
$ curl -i -X POST -d 'A document with a randomly-generated ID.' 'http://127.0.0.1:9500/docs/test/' --header "Content-Type:text/plain"
HTTP/1.1 201 Created
Content-Length: 197
Content-Type: application/json
Access-Control-Allow-Headers: Content-Type
Access-Control-Allow-Origin: *
Server: LiteStore/1.0.3

{"id": "test/555f93e82230f77500000000", "data": "A document with a randomly-generated ID.", "created": "2015-05-22T08:39:04Z", "modified": null, "tags": ["$type:text", "$subtype:plain", "$format:text"]}
```

#### HEAD docs

Retrieves all headers related to the **docs** resource and no content (this is probably not that useful, but at least it should make REST purists happy).

##### Example

```
$ curl -i -X HEAD 'http://127.0.0.1:9500/docs'
HTTP/1.1 200 OK
Content-Length: 0
Content-Type: application/json
Access-Control-Allow-Headers: Content-Type
Access-Control-Allow-Origin: *
Server: LiteStore/1.0.3
```

#### HEAD docs/:folder/

Retrieves all headers related to the a folder and no content. Useful to check whether a folder exists or not.

##### Example

```
$ curl -i -X HEAD 'http://localhost:9500/docs/admin/images/'
HTTP/1.1 200 OK
Content-Length: 0
Content-Type: application/json
Access-Control-Allow-Headers: Content-Type
Access-Control-Allow-Origin: *
Server: LiteStore/1.1.0
```

#### HEAD docs/:id

Retrieves all headers related to the a document and no content. Useful to check whether a document exists or not.

##### Example

```
$ curl -i -X HEAD 'http://127.0.0.1:9500/docs/test'
HTTP/1.1 200 OK
Content-Length: 0
Content-Type: application/json
Access-Control-Allow-Headers: Content-Type
Access-Control-Allow-Origin: *
Server: LiteStore/1.0.3
```

#### GET docs

Retrieves a list of documents in JSON format. Several query string options are supported to query documents.

##### `content` option

If set to **false**, do not retrieve document data. 

Example: http://127.0.0.1:9500/docs/?contents=false

##### `limit` and `offset` options

Provide a way to implement pagination:

* **limit** causes the query to retrieve only the first _n_ results. 
* **offset** causes the query to skip the first _n_ results. 

Example: http://127.0.0.1:9500/docs/?limit=10&offset=20

##### `search` option

Search for the specified string. 

Example: http://127.0.0.1:9500/docs/?search=Something

> %tip%
> Tip
> 
> If **search** is specified, each result will contain a **highlight** property with a highlighted search snippet, and a **rank** property identified the rank of the result within the search. Results will also be automatically ordered by descending rank.

##### `like` option

If this option is specified, retrieves a single document which id matches the specified pattern. The value give to `like` option is not used so the search pattern is specified as the regular document id as a part of the path. The regular SQL wildcards `%` and `_` can be used. To escape them use `\` encoded in the URL as `%5C`.

Example: http://127.0.0.1:9500/docs/%/api%5C_%.md?like=1&raw=true&contents=false&search=API%20v7%Required

If finds the first markdown file which name starts with _api\__ and which contains string _API v7 Required_.

> %tip%
> Tip
> 
> Only the first matching document is returned even if there was more than one which id matched the pattern. To get the subsequent documents use `offset` option and increase its value from _1_ up. 


##### `tags` option

Retrieve only documents with matching tag(s). 

Example: http://127.0.0.1:9500/docs/?tags=tag1,tag2

##### `filter` option

> %note%
> API v3 Required
> 
> This query string option has been introduced in version 3 of the LiteStore API.

Retrieve only JSON documents matching the specified filter expression.

Filter expressions can be composed by one or more clauses joined together through **or** or **and** operators. Each clause must be composed exactly by:

* A path expression indicating a field or array item within the JSON document.
* One operator among the following: eq, not eq, gt, gte, lt, lte, contains, and like.
* A value that can be a number, string, **true**, **false** or **nil**

> %note%
> API v5 Required
> 
> Support for the **like** operator has been added in version 5 of the LiteStore API.

> %warning%
> Limitations
> 
> * Parenthesis are not supported.
> * Up to 10 **or** clauses and 10 **and** clauses are supported.
> * Paths can only contain keys that contain only numbers, letters and underscores.

Examples:

* http://127.0.0.1:9500/docs/?filter=$.age%20gte%2018%20or%20$.skills%20contains%20"maths"
* http://127.0.0.1:9500/docs/?filter=$.name.first&20eq%20"Jack"%20or%20$.fav\_food[0]%20eq%20"pizza"
* http://127.0.0.1:9500/docs/?filter=$.name.first&20like%20"J*"

##### `select` option

> %note%
> API v3 Required
> 
> This query string option has been introduced in version 3 of the LiteStore API.

Retrieve JSON documents containing only the specified fields. Fields must be specified by comma-separated path/alias expression.

Example: http://127.0.0.1:9500/docs/?select=$.name.first%20as%20FirstName,$.age%20as%20Age

##### `created-after` option

Retrieve only documents created after a the specified timestamp.

Example: http://127.0.0.1:9500/?created-after=1537695677

> %note%
> API v4 Required
> 
> This query string option has been introduced in version 4 of the LiteStore API.

##### `created-before` option

Retrieve only documents created before a the specified timestamp.

Example: http://127.0.0.1:9500/?created-before=1537695677

> %note%
> API v4 Required
> 
> This query string option has been introduced in version 4 of the LiteStore API.

##### `modified-after` option

Retrieve only documents modified after a the specified timestamp.

Example: http://127.0.0.1:9500/?modified-after=1537695677

> %note%
> API v4 Required
> 
> This query string option has been introduced in version 4 of the LiteStore API.

##### `modified-before` option

Retrieve only documents modified before a the specified timestamp.

Example: http://127.0.0.1:9500/?modified-before=1537695677

> %note%
> API v4 Required
> 
> This query string option has been introduced in version 4 of the LiteStore API.

##### `sort` option

Sort by **created**, **modified**, **id** or a JSON path to a field (prepend **-** for DESC and **+** for ASC). 

> %note%
> API v3 Required for JSON path support
> 
> Support for JSON paths requires version 3 of the LiteStore API.

Examples: 

* http://127.0.0.1:9500/docs/?sort=-modified,-created
* http://127.0.0.1:9500/docs/?sort=-$.age,-$.name.first

##### Query String Options


##### Example

```
$ curl -i 'http://localhost:9500/docs?search=Use%20Cases&limit=10
&offset=0&tags=$subtype:x-markdown'
HTTP/1.1 200 OK
Content-Length: 1960
Content-Type: application/json
Access-Control-Allow-Headers: Content-Type
Access-Control-Allow-Origin: *
Server: LiteStore/1.0.3

{
  "search": "Use Cases",
  "tags": [
    "$subtype:x-markdown"
  ],
  "limit": 10,
  "total": 3,
  "execution_time": 0.01843700000000001,
  "results": [
    {
      "id": "admin/md/use-cases.md",
      "created": "2015-09-19T01:37:59Z",
      "modified": null,
      "highlight": "### <strong>Use</strong> <strong>Cases</strong>\u000A\u000AWhile LiteStore may not be the best choice for large data-intensive applications, it definitely shines when <strong>used</strong> for rapid prototyping and as a backend for small/lightweight<strong>&hellip;</strong>",
      "rank": "99.5820018475243",
      "tags": [
        "$type:text",
        "$subtype:x-markdown",
        "$format:text",
        "$dir:admin"
      ]
    },
    {
      "id": "admin/md/architecture.md",
      "created": "2015-09-19T01:37:59Z",
      "modified": null,
      "highlight": "<strong>&hellip;</strong>public unique document identifier, <strong>used</strong> to access the document via the HTTP API.\u000A* **data** &ndash; The contents of the document (or their base64-encoded representation in <strong>case</strong> of binary documents<strong>&hellip;</strong>",
      "rank": "39.492608737092",
      "tags": [
        "$type:text",
        "$subtype:x-markdown",
        "$format:text",
        "$dir:admin"
      ]
    },
    {
      "id": "admin/md/overview.md",
      "created": "2015-09-19T01:37:59Z",
      "modified": null,
      "highlight": "<strong>&hellip;</strong>contained, LiteStore comes with many <strong>useful</strong> features that are essential for many <strong>use</strong> <strong>cases</strong>.\u000A\u000A#### [](class:fa-file-text-o) Multi-format Documents\u000A\u000ALiteStore can be <strong>used</strong> to store documents in<strong>&hellip;</strong>",
      "rank": "39.4926086158248",
      "tags": [
        "$type:text",
        "$subtype:x-markdown",
        "$format:text",
        "$dir:admin"
      ]
    }
  ]
}
```

#### GET docs/:folder/

> %note%
> API v2 Required
> 
> This method has been introduced in version 2 of the LiteStore API.

Retrieves a list of documents in JSON format starting with the specified folder path (it must end with '/').

> %tip%
> Supported query options
> 
> The same query options of the **docs** resource are supported.

##### Example

```
$ curl -i -X GET 'http://localhost:9500/docs/admin/images/?contents=false'
HTTP/1.1 200 OK
Content-Length: 2066
Content-Type: application/json
Access-Control-Allow-Headers: Content-Type
Access-Control-Allow-Origin: *
Server: LiteStore/1.1.0

{
  "folder": "admin/images/",
  "total": 2,
  "execution_time": 0.014684,
  "results": [
    {
      "id": "admin/images/app_document.png",
      "created": "2016-02-06T01:11:30Z",
      "modified": null,
      "tags": [
        "$type:image",
        "$subtype:png",
        "$format:binary",
        "$dir:admin"
      ]
    },
    {
      "id": "admin/images/app_guide.png",
      "created": "2016-02-06T01:11:30Z",
      "modified": null,
      "tags": [
        "$type:image",
        "$subtype:png",
        "$format:binary",
        "$dir:admin"
      ]
    }
  ]
}
```

#### GET docs/:id

Retrieves the specified document. By default the response is returned in the document's content type; however, it is possible to retrieve the raw document (including metadata) in JSON format by setting the **raw** query string option to true.

##### Example: original content type

```
$ curl -i 'http://127.0.0.1:9500/docs/test'
HTTP/1.1 200 OK
Content-Length: 24
Content-Type: text/plain
Access-Control-Allow-Headers: Content-Type
Access-Control-Allow-Origin: *
Server: LiteStore/1.0.3

This is a test document.
```

##### Example: raw format

```
$ curl -i 'http://127.0.0.1:9500/docs/test?raw=true'
HTTP/1.1 200 OK
Content-Length: 191
Content-Type: application/json
Access-Control-Allow-Headers: Content-Type
Access-Control-Allow-Origin: *
Server: LiteStore/1.0.3

{"id": "test", "data": "This is a test document.", "created": "2015-09-19T08:07:43Z", "modified": null, "tags": ["$type:text", "$subtype:plain", "$format:text"]}
```

#### PUT docs/:id

Updates an existing document or creates a new document with the specified ID.

##### Example

```
$ curl -i -X PUT -d 'This is a test document.' 'http://127.0.0.1:9500/docs/test' --header "Content-Type:text/plain"
HTTP/1.1 201 Created
Content-Length: 161
Content-Type: application/json
Access-Control-Allow-Headers: Content-Type
Access-Control-Allow-Origin: *
Server: LiteStore/1.0.3

{"id": "test", "data": "This is a test document.", "created": "2015-05-22T08:40:00Z", "modified": null, "tags": ["$type:text", "$subtype:plain", "$format:text"]}
```

#### PATCH docs/:id

Adds, removes, replaces or tests the specified document for tags or data. Operations must be specified using the [JSONPatch](http://jsonpatch.com/) format.

> %tip%
> Tip
> 
> If you plan on patching tags, always retrieve document tags first before applying a patch, to know the order tags have been added to the document.

> %warning%
> Limitations
> 
> * Only **add**, **remove**, **replace** and **test** operations are supported.
> * It is only possible to patch **data** and/or **tags** of a document.
> * It is only possible to patch the data of JSON documents.

##### Example: Patching Tags

```
$ curl -i -X PATCH 'http://localhost:9500/docs/test.json' --header "Content-Type:application/json" -d '[{"op":"add", "path":"/tags/3", "value":"test1"},{"op":"add", "path":"/tags/4", "value":"test2"},{"op":"add", "path":"/tags/5", "value":"test3"}]'
HTTP/1.1 200 OK
Content-Length: 187
Content-Type: application/json
Access-Control-Allow-Headers: Content-Type
Access-Control-Allow-Origin: *
Server: LiteStore/1.0.3

{"id": "test.json", "data": {"test": true}, "created": "2015-09-20T09:06:25Z", "modified": null, "tags": ["$type:application", "$subtype:json", "$format:text", "test1", "test2", "test3"]}
```

##### Example: Patching Data

Given the following document:

```
{
  "id": "test",
  "data": {
    "name": {
      "first": "Tom",
      "last": "Paris"
    },
    "rank": "lieutenant"
  },
  "created": "2018-02-25T14:33:14Z",
  "modified": null,
  "tags": [
    "$type:application",
    "$subtype:json",
    "$format:text"
  ]
}
```

The following PATCH operation can be applied to change its data.

```
$ curl -i -X PATCH 'http://localhost:9500/docs/test' --header "Content-Type:application/json" -d '[{"op": "replace", "path": "/data/name", "value": "Seven of Nine"}, {"op": "remove", "path": "/data/rank"}]'
HTTP/1.1 200 OK
server: LiteStore/1.3.0
access-control-allow-origin: *
content-type: application/json
access-control-allow-headers: Content-Type
Content-Length: 172

{"id":"test","data":{"name":"Seven of Nine"},"created":"2018-02-25T14:33:14Z","modified":"2018-02-25T14:35:52Z","tags":["$type:application","$subtype:json","$format:text"]}
```

#### DELETE docs/:id

Deletes the specified document.

##### Example

```
$ curl -i -X DELETE 'http://127.0.0.1:9500/docs/test'
HTTP/1.1 204 No Content
Content-Length: 0
Access-Control-Allow-Headers: Content-Type
Access-Control-Allow-Origin: *
Server: LiteStore/1.0.3
```