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

#### Database Schema

The database schema of LiteStore data store file is very simple, as shown in the following diagram:

![LiteStore Database](images/litestore_db.png)

##### info Table

The [info](class:kwd) table currently contains just two INT columns used to keep track of:

* The version of the database schema
* The total number of documents stored in the database

##### documents Table

The [documents](class:kwd) table is the most important table of the data store, as it contains all the documents stored in it. The following information is stored for each document:

* **docid** &ndash; The internal unique document identifier.
* **id** &ndash; The public unique document identifier, used to access the document via the HTTP API.
* **data** &ndash; The contents of the document (or their base64-encoded representation in case of binary documents).
* **binary** &ndash; Whether the document is binary (1) or textual (0).
* **searchable** &ndash; Whether the document is searchable (1) or not (0). Currently, textual documents are searchable and binary documents are not.
* **created** &ndash; When the document was created.
* **modified** &ndash; When the document was last modified.

##### tags Table

The [tags](class:kwd) table is used to store the associations between tags and documents. Tags can be added by users or add automatically by the system when a document is imported into the data store.

##### searchdata Table

This table is used as full-text index for searchable documents.
