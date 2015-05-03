### Use Cases

While LiteStore may not be the best choice for large data-intensive applications, it definitely shines when used for rapid prototyping and as a backend for small/lightweight applications.

#### Lightweight Document Store

LiteStore is, first and foremost a _document store_. Although it uses a relational database ([SQlite](http://www.sqlite.org)) as a storage medium, it is NoSQL document store accessible via a rest API.

As a document store, LiteStore provides the following features

* You can save and retrieve data as arbitrary JSON documents but also as arbitrary documents of virtually any content type.
* You can query data using user-specified and system tags and/or via the native full-text search functionality (available only for textual documents).
* You can access data by the means of a RESTful API.

#### SPA Prototyping Backend and Lightweight File Server

LiteStore can be used as a backend for prototyping single-page application. You can use it as a simple RESTful service layer to manage your SPA data, but also as a web-server to serve your application files: all you have to do is import a phisical directory using the [litestore import](class:cmd) command and LiteStore will loads all the directory contents recursively as documents.

Together with LiteStore's ability to mirror changes to the filesystem, you could even develop your single-page application live using LiteStore REST API to save and retrieve files. The LiteStore Admin SPA is an example of single-page application developed almost entirely with LiteStore. 

#### Lightweight RESTFul Virtual Filesystem

By using the [import](class:cmd), [export](class:cmd) and [delete](class:cmd) commands, you can easily load and unload data to and from a physical directory.

You could even use datastore files as file containers, with the advantage that (when served by LiteStore) you can also:

* add arbitrary metadata using tags
* perform fast full-text searches

> %warning%
> A note on datastore file size...
> 
> Do not expect datastore files to occupy the same physical space as the original files on disk! Binary files are stored in datastore files as base64-encoded strings. This greatly simplifies storage and portability, but also makes stored binary contents roughly 33% larger than the original files. 
>
> Additionally, extra space is used to store tag information and the full-text index, so... basically a datastore file is always larger than the total sizes of all the original files combined. 

#### Personal Wiki/CMS/App Backend

LiteStore is the ideal backend for personal apps. You could create a wiki app or a simple CMS as a Javascript single-page application, and distribute it as a single datastore file.

Your app could then be served on any desktop system able to run LiteStore (e.g. OSX, Windows, Linux, ...even on a [Raspberry Pi](https://www.raspberrypi.org)).

#### Static Site Backend

LiteStore can be configured to run in read-only mode, so that only GET, HEAD, or OPTIONS request are accepted by the server. This makes it ideal as a backend for static web site generated with something like [nanoc](http://nanoc.ws) or [Jekyll](http://jekyllrb.com).