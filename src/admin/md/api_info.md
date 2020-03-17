### info (LiteStore Information)

This resource can be queried to obtain basic information and statistics on the LiteStore server.

#### OPTIONS info

Returns the allowed HTTP verbs for this resource.

##### Example

```
$ curl -i -X OPTIONS http://127.0.0.1:9500/info
HTTP/1.1 200 OK
Content-Length: 0
Access-Control-Allow-Methods: GET,OPTIONS
Allow: GET,OPTIONS
Access-Control-Allow-Headers: Content-Type
Access-Control-Allow-Origin: *
Server: LiteStore/1.0.3
```

#### GET info

Returns the following server statistics:

* Version
* Datastore version
* API version
* Size of the database on disk (in MB)
* Whether the database is read-only or not
* Log level (debug, info, warning, error, none)
* Mounted directory (if any)
* Additional stores (if any)
* Whether authorization is enabled or not
* Total documents
* Total tags
* Number of documents per tag

##### Example

```
$ curl -i http://127.0.0.1:9500/info
HTTP/1.1 200 OK
Content-Length: 965
Content-Type: application/json
Access-Control-Allow-Headers: Authorization, Content-Type
Access-Control-Allow-Origin: http://127.0.0.1:9500
Server: LiteStore/1.9.0

{
  "version": "LiteStore v1.9.0",
  "datastore_version": 2,
  "api_version": 7,
  "size": "6.98 MB",
  "read_only": false,
  "log_level": "warn",
  "directory": "admin",
  "mount": true,
  "additional_stores": [],
  "auth": false,
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