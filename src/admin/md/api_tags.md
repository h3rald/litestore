### tags (LiteStore Tags)

This resource can be queried to retrieve the total of documents associated to a tag, or a list of tags matching a string.

> %note%
> API v4 Required
> 
> This resource has been introduced in version 4 of the LiteStore API.

#### OPTIONS tags

Returns the allowed HTTP verbs for this resource.

##### Example

```
$ curl -i -X OPTIONS http://127.0.0.1:9500/tags
HTTP/1.1 200 OK
server: LiteStore/1.5.0
access-control-allow-origin: http://localhost:9500
access-control-allow-headers: Content-Type
allow: GET,OPTIONS
access-control-allow-methods: GET,OPTIONS
content-length: 0
```

#### OPTIONS tags/:id

Returns the allowed HTTP verbs for this resource.

##### Example

```
$ curl -i -X OPTIONS http://127.0.0.1:9500/tags/$type:text
HTTP/1.1 200 OK
server: LiteStore/1.5.0
access-control-allow-origin: http://localhost:9500
access-control-allow-headers: Content-Type
allow: GET,OPTIONS
access-control-allow-methods: GET,OPTIONS
Content-Length: 0
```

#### GET tags

Retrieves all tags and the total of their associated documents.

##### `like` option

If this option is specified, retrieves all tags matching the specified string. 

> %tip%
> Wildcards
>
> You can use asterisks (\*) as wildcards.

##### Example

```
$ curl -i http://localhost:9500/tags/?like=%24type:%2A
HTTP/1.1 200 OK
server: LiteStore/1.5.0
access-control-allow-origin: http://localhost:9500
content-type: application/json
vary: Origin
access-control-allow-headers: Content-Type
Content-Length: 290

{
  "like": "$type:*",
  "total": 3,
  "execution_time": 0.0008190000000000003,
  "results": [
    {
      "id": "$type:application",
      "documents": 43
    },
    {
      "id": "$type:image",
      "documents": 10
    },
    {
      "id": "$type:text",
      "documents": 32
    }
  ]
}
```

#### GET tags/:id

Retrieves the specified tag and corresponding document total.

##### Example

```
$ curl -i http://localhost:9500/tags/%24type%3Atext
HTTP/1.1 200 OK
server: LiteStore/1.5.0
access-control-allow-origin: http://localhost:9500
content-type: application/json
vary: Origin
access-control-allow-headers: Content-Type
Content-Length: 34

{"id":"$type:text","documents":32}
```