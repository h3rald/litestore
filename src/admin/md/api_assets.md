### assets (LiteStore Assets)

> %note%
> API v8 Required
> 
> This resource has been introduced in version 5 of the LiteStore API.

Assets represents another way to query LiteStore Documents. All documents can also be retrieved via `/assets/` instead of docs, but when doing so:
* a non-raw version of the document will always be returned
* when querying a folder without specifying a document ID, LiteStore will attempt to retrieve an `index.html` or `index.htm` file within that folder

This is particularly useful when your documents have been imported from the filesystem and you need to effectively serve files.

#### OPTIONS assets

Returns the allowed HTTP verbs for this resource.

##### Example

```
$ curl -i -X OPTIONS 'http://127.0.0.1:9500/assets'
HTTP/1.1 200 OK
Content-Length: 0
Access-Control-Allow-Methods: GET,OPTIONS
Allow: GET,OPTIONS
Access-Control-Allow-Headers: Content-Type
Access-Control-Allow-Origin: *
Server: LiteStore/1.12.0
```

#### OPTIONS assets/:id

Returns the allowed HTTP verbs for this resource.

##### Example

```
curl -i -X OPTIONS 'http://127.0.0.1:9500/assets/test.json' 
HTTP/1.1 200 OK
Content-Length: 0
Access-Control-Allow-Methods: GET,OPTIONS
Allow: GET,OPTIONS
Access-Control-Allow-Headers: Content-Type
Access-Control-Allow-Origin: *
Server: LiteStore/1.12.0
```

#### OPTIONS assets/:folder/

Returns the allowed HTTP verbs for this resource.

##### Example

```
$ curl -i -X OPTIONS 'http://127.0.0.1:9500/assets/test/'
HTTP/1.1 200 OK
Content-Length: 0
Access-Control-Allow-Methods: GET,OPTIONS
Allow: GET,OPTIONS
Access-Control-Allow-Headers: Content-Type
Access-Control-Allow-Origin: *
Server: LiteStore/1.12.0
```

#### GET assets

Retrieves the file `assets/index.html` or `assets/index.htm` if not found.


#### GET assets/:folder/


Retrieves the file `assets/:folder/index.html` or `assets/:folder/index.htm` if not found.

#### GET assets/:id

Retrieves the specified document. The response is returned in the document's content type (even for JSON files).

##### Example

```
$ curl -i 'http://127.0.0.1:9500/docs/test.txt'
HTTP/1.1 200 OK
Content-Length: 24
Content-Type: text/plain
Access-Control-Allow-Headers: Content-Type
Access-Control-Allow-Origin: *
Server: LiteStore/1.12.0

This is a test document.
```
