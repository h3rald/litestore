## HTTP API Reference

LiteStore provide a simply and fairly RESTful HTTP API. At present, the only two resources exposed are the following:

* info &ndash; information about the data store (read-only)
* docs &ndash; LiteStore documents (read-write)

### Accessing LiteStore Resources

To access a LiteStore resource, use URLs composed in the following way:

`http:<hostname>:<port>/<resource>/<id>`

Example: <http://localhost:9500/docs/admin/index.html>

> %note%
> A note on document IDs...
>
> In a somewhat non-standard way, IDs of LiteStore documents can contain slashes. The main reason behind this is that this makes it possible to implement a virtual file system with LiteStore easily, and serve up web pages as you would from an ordinary filesystem.