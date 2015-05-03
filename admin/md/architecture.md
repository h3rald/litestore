### Architecture

LiteStore is entirely developed using the [Nim](http://nim-lang.org) programming language. It also embeds the [SQLite](http://www.sqlite.org) C library (statically linked), compiled with the [FTS4](http://www.sqlite.org/fts3.html) extension and a custom ranking function to provide full-text search support.

The [litestore](class:file) executable file is entirely self-contained and is used to start/stop the LiteStore server, as well as perform maintenance and bulk operations via dedicated CLI commands.

#### System Decomposition

The following diagram illustrates the main LiteStore components.

![LiteStore Architecture](images/litestore_arch.png)

At the lowest level, the SQLite Library is used to manage data access and storage. The functionality provided by the SQLite Library is used by the main Core module, which exposes the main high-level procedures to manage LiteStore-specific artifacts (documents and tags).

The Core module is then used by the two main interfaces exposed to users:

* the Command-Line Interface, which can be used to run the server, import/export/delete data in bulk, and perform maintenance operations on the underlying datastore file (vacuum, optimize).
* the RESTful HTTP API, which can be used as the primary way to perform CRUD operation on documents, and manage document tags.