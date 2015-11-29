### info (LiteStore Information)

This resource can be queried to retrieve files within the served directory (specied via **-d**).

#### OPTIONS info

Returns the allowed HTTP verbs for this resource.

##### Example

```
$ curl -i -X OPTIONS http://127.0.0.1:9500/v1/dir
HTTP/1.1 200 OK
Content-Length: 0
Access-Control-Allow-Methods: GET,OPTIONS
Allow: GET,OPTIONS
Access-Control-Allow-Headers: Content-Type
Access-Control-Allow-Origin: *
Server: LiteStore/1.0.0
```

#### GET dir/:id

Returns the content of a file within the served directory (if it exists).

##### Example

```
$ curl -i http://127.0.0.1:9500/v1/dir/test.txt
HTTP/1.1 200 OK
Content-Length: 25
Content-Type: text/plain
Access-Control-Allow-Headers: Content-Type
Access-Control-Allow-Origin: *
Server: LiteStore/1.0.3

This is a test text file.
```
