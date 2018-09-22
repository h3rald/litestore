## HTTP API Reference

LiteStore provides a RESTful HTTP API. At present, the only two resources exposed are the following:

* info &ndash; information about the data store (read-only)
* docs &ndash; LiteStore documents (read-write)

### Accessing LiteStore Resources

To access a LiteStore resource, use URLs composed in the following way:

`http:<hostname>:<port>/v<version>/<resource>/<id>`

Example: [localhost:9500/v2/docs/admin/index.html](http://localhost:9500/v2/docs/admin/index.html)

> %note%
> Remarks
>
> * If the version is omitted, the latest version of the LiteStore API will be used by default. The previous URL can be therefore written as <http://localhost:9500/docs/admin/index.html>.
> * In a somewhat non-standard way, IDs of LiteStore documents can contain slashes. The main reason behind this is that this makes it possible to implement a virtual file system with LiteStore easily, and serve up web pages as you would from an ordinary filesystem.
