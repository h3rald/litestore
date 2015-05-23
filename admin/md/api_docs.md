### docs (LiteStore Documents)

A document is the main resource type managed by LiteStore. Any LiteStore document can be represented as a JSON object exposing the following properties:

* id: The unique identifier of the document.
* data: The document contents (base64-encoded if binary).
* created: The document creation date expressed as combined date and time in UTC ([ISO 8601](http://en.wikipedia.org/wiki/ISO_8601) compliant).
* modified: The document modification date (if applicable) expressed as combined date and time in UTC ([ISO 8601](http://en.wikipedia.org/wiki/ISO_8601) compliant).
* tags: A list of tags associated to the document.

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
$ curl -i -X OPTIONS http://127.0.0.1:9500/docs
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
curl -i -X OPTIONS http://0.0.0.0:9500/docs/test  
HTTP/1.1 200 OK   
Content-Length: 0  
Allow: HEAD,GET,PUT,PATCH,DELETE,OPTIONS
```

#### POST docs

```
$ curl -i -X POST -d 'A document with a randomly-generated ID.' http://127.0.0.1:9500/docs --header "Content-Type:text/plain"
HTTP/1.1 201 Created
Content-Length: 197
Content-Type: application/json
Access-Control-Allow-Headers: Content-Type
Access-Control-Allow-Origin: *
Server: LiteStore/1.0.0

{"id": "555f93e82190e77500000000", "data": "A document with a randomly-generated ID.", "created": "2015-05-22T08:39:04Z", "modified": null, "tags": ["$type:text", "$subtype:plain", "$format:text"]}
```

#### HEAD docs

```
$ curl -i -X HEAD http://127.0.0.1:9500/docs
HTTP/1.1 200 OK
Content-Length: 0
Content-Type: application/json
Access-Control-Allow-Headers: Content-Type
Access-Control-Allow-Origin: *
Server: LiteStore/1.0.0
```

#### HEAD docs/:id

```
$ curl -i -X HEAD http://127.0.0.1:9500/docs/test
HTTP/1.1 200 OK
Content-Length: 0
Content-Type: application/json
Access-Control-Allow-Headers: Content-Type
Access-Control-Allow-Origin: *
Server: LiteStore/1.0.0
```

#### GET docs

```
...
```

##### Query String Options

The following query string options are supported:

* **search**
* **tags**
* **limit**
* **offset**
* **sort**
* **contents**
* **raw**


#### GET docs/:id

```
$ curl -i http://127.0.0.1:9500/docs/test
HTTP/1.1 200 OK
Content-Length: 24
Content-Type: text/plain
Access-Control-Allow-Headers: Content-Type
Access-Control-Allow-Origin: *
Server: LiteStore/1.0.0

This is a test document.
```

#### PUT docs/:id

```
$ curl -i -X PUT -d 'This is a test document.' http://127.0.0.1:9500/docs/test --header "Content-Type:text/plain"
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

```
...
```