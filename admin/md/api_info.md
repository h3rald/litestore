### info (LiteStore Information)

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
Server: LiteStore/1.0.3
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
Server: LiteStore/1.0.3

{
  "version": "LiteStore v1.0.0",
  "datastore_version": 1,
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
