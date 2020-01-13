### indexes (LiteStore Indexes)

> %note%
> API v5 Required
> 
> This resource has been introduced in version 5 of the LiteStore API.

LiteStore Indexes are special indexes used to optimize the performance of queries on JSON documents.

> %warning%
> JSON-only Documents Required!
>
> Indexes can be created *only* if the entire database is composed by JSON documents. If not, LiteStore will return an error when attempting to create the first index.

#### OPTIONS indexes

Returns the allowed HTTP verbs for this resource.

##### Example

```
$ curl -i -X OPTIONS http://127.0.0.1:9500/indexes
HTTP/1.1 200 OK
server: LiteStore/1.7.0
access-control-allow-origin: http://localhost:9500
access-control-allow-headers: Content-Type
allow: GET,OPTIONS
access-control-allow-methods: GET,OPTIONS
content-length: 0
```

#### OPTIONS indexes/:id

Returns the allowed HTTP verbs for this resource.

##### Example

```
$ curl -i -X OPTIONS http://127.0.0.1:9500/indexes/name
HTTP/1.1 200 OK
server: LiteStore/1.7.0
access-control-allow-origin: http://localhost:9500
access-control-allow-headers: Content-Type
allow: GET,OPTIONS,PUT,DELETE
access-control-allow-methods: GET,OPTIONS,PUT,DELETE
Content-Length: 0
```

#### GET indexes

Retrieves all indexes and their respective JSON fields.

##### `like` option

If this option is specified, retrieves all indexes matching the specified string. 

> %tip%
> Wildcards
>
> You can use asterisks (\*) as wildcards.

##### `limit` and `offset` options

Provide a way to implement pagination:

* **limit** causes the query to retrieve only the first _n_ results. 
* **offset** causes the query to skip the first _n_ results. 

##### Example

```
$ curl -i http://localhost:9500/indexes/?like=%2Aname%2A
HTTP/1.1 200 OK
server: LiteStore/1.7.0
access-control-allow-origin: http://localhost:9500
content-type: application/json
vary: Origin
access-control-allow-headers: Content-Type
Content-Length: 244

{
  "like": "*name*",
  "total": 2,
  "execution_time": 0.0006140000000000001,
  "results": [
    {
      "id": "name",
      "field": "$.name"
    },
    {
      "id": "document.name",
      "field": "$.document.name"
    }
  ]
}
```

#### GET indexes/:id

Retrieves the specified index and corresponding JSON field.

##### Example

```
$ curl -i http://localhost:9500/indexes/name
HTTP/1.1 200 OK
server: LiteStore/1.7.0
access-control-allow-origin: http://localhost:9500
content-type: application/json
vary: Origin
access-control-allow-headers: Content-Type
Content-Length: 30

{"id":"name","field":"$.name"}
```

#### PUT indexes/:id

Creates a new index with the specified ID.

Note that:
* Index IDs can only contain letters, numbers, and underscores.
* Index fields must be valid paths to JSON fields.

> %warning%
> No updates
>
> It is not possible to update an existing index. Delete it and re-create it instead.


##### Example

```
$ curl -i -X PUT -d '{"field": "$.name"}' 'http://127.0.0.1:9500/indexes/name' --header "Content-Type:application/json"
HTTP/1.1 201 Created
Content-Length: 31
Content-Type: application/json
Access-Control-Allow-Headers: Content-Type
Access-Control-Allow-Origin: http://localhost:9500
Server: LiteStore/1.7.0

{"id":"name", "field":"$.name"}
```

#### DELETE indexes/:id

Deletes the specified index.

##### Example

```
$ curl -i -X DELETE 'http://127.0.0.1:9500/indexes/name'
HTTP/1.1 204 No Content
Content-Length: 0
Access-Control-Allow-Headers: Content-Type
Access-Control-Allow-Origin: http://localhost:9500
Server: LiteStore/1.7.0
```