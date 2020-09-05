### stores (LiteStore Stores)

> %note%
> API v7 Required
> 
> This resource has been introduced in version 7 of the LiteStore API.

As of version 1.9.0, it is possible for a single LiteStore process to manage multiple data store files. These additional stores can be accessed but also added or removed at run time using this resource.

#### OPTIONS stores

Returns the allowed HTTP verbs for this resource.

##### Example

```
$ curl -i -X OPTIONS http://127.0.0.1:9500/stores
HTTP/1.1 200 OK
server: LiteStore/1.9.0
access-control-allow-origin: http://localhost:9500
access-control-allow-headers: Content-Type
allow: GET,OPTIONS
access-control-allow-methods: GET,OPTIONS
content-length: 0
```

#### OPTIONS stores/:id

Returns the allowed HTTP verbs for this resource.

##### Example

```
$ curl -i -X OPTIONS http://127.0.0.1:9500/stores/test1
HTTP/1.1 200 OK
server: LiteStore/1.9.0
access-control-allow-origin: http://localhost:9500
access-control-allow-headers: Content-Type
allow: GET,OPTIONS,PUT,DELETE
access-control-allow-methods: GET,OPTIONS,PUT,DELETE
Content-Length: 0
```

#### GET stores

Retrieves information on all available stores (file name and configuration).

##### Example

```
$ curl -i http://localhost:9500/stores
HTTP/1.1 200 OK
content-type: application/json
access-control-allow-origin: http://127.0.0.1:9500
access-control-allow-headers: Authorization, Content-Type
vary: Origin
server: LiteStore/1.9.0
Content-Length: 2346

{
  "total": 4,
  "execution_time": 0.0,
  "results": [
    {
      "id": "test1",
      "file": "test1.db",
      "config": null
    },
    {
      "id": "test2",
      "file": "test2.db",
      "config": null
    },
    {
      "id": "test3",
      "file": "test3.db",
      "config": null
    },
    {
      "id": "master",
      "file": "data.db",
      "config": {
        "settings": {
          "log": "debug",
          "port": 9200
        },
        "stores": {
          "test1": {
            "file": "test1.db",
            "config": null
          },
          "test2": {
            "file": "test2.db",
            "config": null
          },
          "test3": {
            "file": "test3.db",
            "config": null
          }
        },
        "resources": {
          "/docs/vehicles/*": {
            "GET": {
              "middleware": [
                "validate",
                "log"
              ]
            },
            "HEAD": {
              "middleware": [
                "validate",
                "log"
              ]
            },
            "POST": {
              "allowed": false
            },
            "PATCH": {
              "auth": [
                "admin:vehicles"
              ],
              "middleware": [
                "validate",
                "log"
              ]
            },
            "PUT": {
              "auth": [
                "admin:vehicles"
              ],
              "middleware": [
                "validate",
                "log"
              ]
            },
            "DELETE": {
              "auth": [
                "admin:vehicles"
              ],
              "middleware": [
                "validate",
                "log"
              ]
            }
          },
          "/docs/logs/*": {
            "GET": {
              "auth": [
                "admin:server"
              ]
            },
            "POST": {
              "allowed": false
            },
            "PUT": {
              "allowed": false
            },
            "PATCH": {
              "allowed": false
            },
            "DELETE": {
              "allowed": false
            }
          }
        },
        "signature": "\n-----BEGIN CERTIFICATE-----\n<certificate text goes here>\n-----END CERTIFICATE-----\n"
      }
    }
  ]
}
```

#### GET stores/:id

Retrieves information on the specified store.

##### Example

```
HTTP/1.1 200 OK
content-type: application/json
access-control-allow-origin: http://127.0.0.1:9500
access-control-allow-headers: Authorization, Content-Type
vary: Origin
server: LiteStore/1.9.0
Content-Length: 46

{"id":"test1","file":"test1.db","config":null}
```

#### PUT stores/:id

Adds a new stores with the specified ID. If a file called **\<id\>.db** does not exist already, it will be created in the current working directory and initialized as a LiteStore store.

Note that:
* Index IDs can only contain letters, numbers, and underscores.
* The body must be present and contain the store configuration (or **null**).

> %warning%
> No updates
>
> It is not possible to update an existing store. Remove it and re-add it instead.


##### Example

```
curl -i -X PUT -d "null" "http://127.0.0.1:9500/stores/test3" --header "Content-Type:application/json"
HTTP/1.1 201 Created
content-type: application/json
access-control-allow-origin: http://127.0.0.1:9500
access-control-allow-headers: Authorization, Content-Type
vary: Origin
server: LiteStore/1.9.0
Content-Length: 46

{"id":"test3","file":"test3.db","config":null}
```

#### DELETE stores/:id

Removes the specified store. Although it will no longer be accessible via LiteStore, the corresponding file will *not* be deleted from the filesystem.

##### Example

```
$ curl -i -X DELETE "http://127.0.0.1:9200/stores/test3"
HTTP/1.1 204 No Content
vary: Origin
access-control-allow-origin: http://127.0.0.1:9200
access-control-allow-headers: Authorization, Content-Type
content-length: 0
server: LiteStore/1.9.0
Content-Length: 0
```

#### \* stores/:id/\*

Forward the request to the specified store. Essentially, the path fragment after the store ID will be forwarded as a standard request to the specified store.

##### Examples

Retrieve all tags from store **vehicles**:
```
$ curl -i http://localhost:9500/stores/vehicles/tags/
```


Delete the document with ID **AA457DB** from store **vehicles**:

```
$ curl -i -X DELETE "http://127.0.0.1:9200/stores/vehicles/docs/AA457DB"
```