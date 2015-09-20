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

Returns the allowed HTTP verbs for the this resource.

##### Example

```
$ curl -i -X OPTIONS 'http://127.0.0.1:9500/docs'
HTTP/1.1 200 OK
Content-Length: 0
Access-Control-Allow-Methods: HEAD,GET,OPTIONS,POST
Allow: HEAD,GET,OPTIONS,POST
Access-Control-Allow-Headers: Content-Type
Access-Control-Allow-Origin: *
Server: LiteStore/1.0.0
```

#### OPTIONS docs/:id

Returns the allowed HTTP verbs for this resource.

##### Example

```
curl -i -X OPTIONS 'http://127.0.0.1:9500/docs/test' 
HTTP/1.1 200 OK   
Content-Length: 0  
Allow: HEAD,GET,PUT,PATCH,DELETE,OPTIONS
```

#### POST docs

Creates a new document with a randomly-generated ID.

##### Example

```
$ curl -i -X POST -d 'A document with a randomly-generated ID.' 'http://127.0.0.1:9500/docs' --header "Content-Type:text/plain"
HTTP/1.1 201 Created
Content-Length: 197
Content-Type: application/json
Access-Control-Allow-Headers: Content-Type
Access-Control-Allow-Origin: *
Server: LiteStore/1.0.0

{"id": "555f93e82190e77500000000", "data": "A document with a randomly-generated ID.", "created": "2015-05-22T08:39:04Z", "modified": null, "tags": ["$type:text", "$subtype:plain", "$format:text"]}
```

#### HEAD docs

Retrieves all headers related to the docs resource and no content (this is probably not that useful, but at least it should make REST purists happy).

```
$ curl -i -X HEAD 'http://127.0.0.1:9500/docs'
HTTP/1.1 200 OK
Content-Length: 0
Content-Type: application/json
Access-Control-Allow-Headers: Content-Type
Access-Control-Allow-Origin: *
Server: LiteStore/1.0.0
```

#### HEAD docs/:id

Retrieves all headers related to the a document and no content. Useful to check whether a document exists or not.

```
$ curl -i -X HEAD 'http://127.0.0.1:9500/docs/test'
HTTP/1.1 200 OK
Content-Length: 0
Content-Type: application/json
Access-Control-Allow-Headers: Content-Type
Access-Control-Allow-Origin: *
Server: LiteStore/1.0.0
```

#### GET docs

Retrieves a list of documents in JSON format.

##### Query String Options

The following query string options are supported:

* **search** &ndash; Search for the specified string. Example: `http://127.0.0.1:9500/docs/?search=Something`.
* **tags** &ndash; Retrieve only documents with matching tag(s). Example: `http://127.0.0.1:9500/docs/?tags=tag1,tag2`
* **limit** &ndash; Retrieve only the first _n_ results. Example: `http://127.0.0.1:9500/docs/?limit=5`
* **offset** &ndash; Skip the first _n_ results. Example: `http://127.0.0.1:9500/docs/?offset=5`
* **sort** &ndash; Sort by **created**, **modified**, or **id**. Example: `http://127.0.0.1:9500/docs/?sort=id`
* **contents** &ndash; If set to **false**, do not retrieve document data. Example: `http://127.0.0.1:9500/docs/?contents=false`

##### Example

```
$ curl -i 'http://localhost:9500/docs?contents=false&tags=$subtype:css'
HTTP/1.1 200 OK
Content-Length: 855
Content-Type: application/json
Access-Control-Allow-Headers: Content-Type
Access-Control-Allow-Origin: *
Server: LiteStore/1.0.0

{
  "tags": [
    "$subtype:css"
  ],
  "total": 3,
  "execution_time": 0.001190000000000024,
  "results": [
    {
      "id": "admin/styles/bootstrap-theme.min.css",
      "created": "2015-09-19T01:37:59Z",
      "modified": null,
      "tags": [
        "$type:text",
        "$subtype:css",
        "$format:text",
        "$dir:admin"
      ]
    },
    {
      "id": "admin/styles/bootstrap.min.css",
      "created": "2015-09-19T01:37:59Z",
      "modified": null,
      "tags": [
        "$type:text",
        "$subtype:css",
        "$format:text",
        "$dir:admin"
      ]
    },
    {
      "id": "admin/styles/litestore.css",
      "created": "2015-09-19T01:37:59Z",
      "modified": null,
      "tags": [
        "$type:text",
        "$subtype:css",
        "$format:text",
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
Server: LiteStore/1.0.0

This is a test document.
```

###### Example: raw format

```
$ curl -i 'http://127.0.0.1:9500/docs/test?raw=true'
HTTP/1.1 200 OK
Content-Length: 191
Content-Type: application/json
Access-Control-Allow-Headers: Content-Type
Access-Control-Allow-Origin: *
Server: LiteStore/1.0.0

{"id": "test", "data": "This is a test document.", "created": "2015-09-19T08:07:43Z", "modified": null, "tags": ["$type:text", "$subtype:plain", "$format:text"]}
```

#### PUT docs/:id

```
$ curl -i -X PUT -d 'This is a test document.' 'http://127.0.0.1:9500/docs/test' --header "Content-Type:text/plain"
HTTP/1.1 201 Created
Content-Length: 161
Content-Type: application/json
Access-Control-Allow-Headers: Content-Type
Access-Control-Allow-Origin: *
Server: LiteStore/1.0.0

{"id": "test", "data": "This is a test document.", "created": "2015-05-22T08:40:00Z", "modified": null, "tags": ["$type:text", "$subtype:plain", "$format:text"]}
```

#### PATCH docs/:id

```
...
```

#### DELETE docs/:id

##### Example

```
$ curl -i -X DELETE 'http://127.0.0.1:9500/docs/test'
HTTP/1.1 204 No Content
Content-Length: 0
Access-Control-Allow-Headers: Content-Type
Access-Control-Allow-Origin: *
Server: LiteStore/1.0.0
```