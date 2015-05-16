## HTTP API Reference

### info - LiteStore Information

This resource can be queried to obtain basic information and statistics on the LiteStore server.

#### OPTIONS info

Returns the allowed HTTP verbs for this resource.

##### Example

```
$ curl -i -X OPTIONS http://127.0.0.1:9500/v1/info
HTTP/1.1 200 OK
Content-Length: 0
Access-Control-Allow-Methods: GET,OPTIONS
Allow: GET,OPTIONS
Access-Control-Allow-Headers: Content-Type
Access-Control-Allow-Origin: *
Server: LiteStore/1.0.0
```

#### GET info

Returns the following server statistics:

* Version
* Size of the database on disk (in MB)
* Whether the database is read-only or not
* Log level (debug, info, warning, error, none)
* Mounted directory (if any)
* Total documents
* Total Tags
* Number of documents per tag

##### Example

```
$ curl -i http://127.0.0.1:9500/v1/info
HTTP/1.1 200 OK
Content-Length: 965
Content-Type: application/json
Access-Control-Allow-Headers: Content-Type
Access-Control-Allow-Origin: *
Server: LiteStore/1.0.0

{
  "version": "LiteStore v1.0.0",
  "size": "5.76 MB",
  "read_only": false,
  "log_level": "info",
  "directory": "admin",
  "mount": true,
  "total_documents": 68,
  "total_tags": 18,
  "tags": [
    {
      "$dir:admin": 68
    },
    {
      "$format:binary": 8
    },
    {
      "$format:text": 60
    },
    {
      "$subtype:css": 3
    },
    {
      "$subtype:html": 2
    }
  ]
}
```

### docs - LiteStore Documents

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
    "modified": "",
    "tags": ["$type:text", "$subtype:plain", "$format:text", "another_tag"]
}
```

#### OPTIONS docs

Returns the allowed HTTP verbs for this resource.

##### Example

```
curl -i -X OPTIONS http://0.0.0.0:9500/v1/docs  
HTTP/1.1 200 OK   
Content-Length: 0  
Allow: HEAD,GET,POST,OPTIONS
```

#### OPTIONS docs/:id

Returns the allowed HTTP verbs for this resource.

##### Example

```
curl -i -X OPTIONS http://0.0.0.0:9500/v1/docs/test  
HTTP/1.1 200 OK   
Content-Length: 0  
Allow: HEAD,GET,PUT,PATCH,DELETE,OPTIONS
```

#### POST docs

#### HEAD docs

#### HEAD docs/:id

#### GET docs

#### GET docs/:id

#### PUT docs/:id

#### PATCH docs/:id

#### DELETE docs/:id