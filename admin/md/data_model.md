### Data Model

LiteStore manages only two basic entities, Documents and Tags.

#### Documents

A *document* is the minimum (and only) unit of content managed by LiteStore. Unlike other data stores, LiteStore documents are not constrained to a specific content type like JSON, but can be of virtually *any* content type, both textual and binary.

When you store a document into a data store using the [import](class:cwd) command or the HTTP API, LiteStore attempts to determine whether the document is binary or not based on its content type. If the content type of a document is not known by LiteStore, the document will be considered binary.

Textual documents are also searchable, and their ID and contents are immediately indexed when they are stored into the data store and re-indexed when they are updated.

#### Tags

Tags are a way to categorize documents. Because LiteStore does not make any assumption on the content type and the structure of a document, tags can become really useful when retrieving documents.

Tags can contain letters, numbers and any of the following special characters: [_-?~:.@#^!+](class:kwd)

All system tags are prefixed by a [$](class:kwd) characters, and are used to identify the following document metadata. More specifically:

* **$dir:*directory*** &ndash; System tags starting with [$dir:](class:kwd) identify the name of a directory whose contents were imported into a data store. All files within the specified directory will be tagged with a [$dir:](class:kwd) system tag. Example: If a directory called **admin** is imported, imported files will be tagged with [$dir:admin](class:kwd).
* **$type:*type*** &ndash; System tags starting with [$type:](class:kwd) identify the type of a document (i.e. the first portion of its content type). Example: Documents whose content type is **text/plain** will be tagged with [$type:text](class:kwd).
* **$subtype:*subtype*** &ndash; System tags starting with [$subtype:](class:kwd) identify the subtype of a document (i.e. the second portion of its content type). Example: Documents whose content type is **text/plain** will be tagged with [$subtype:plain](class:kwd).