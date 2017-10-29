### Low-Level Nim API

The following [proc](class:kwd)s implement low-level operations on the LiteStore data store. Unlike the high-level API, the [proc](class:kwd)s exposed by this API do not perform the same validation checks as the corresponding HTTP operations, and they are meant to be used with caution in more advanced use cases.

{{p-ct => ct
: Determines the content type of the [body](class:kwd) parameter.}}
{{p-options => options
: A [QueryOptions](#QueryOptions) object representing a query to execute on a document.}}
{{p-folder => folder
: A logical folder where the document will be saved.}}

#### getInfo

     proc getInfo*(): LSResponse 

Retrieves information about the currently-loaded data store file.

#### getRawDocuments

     proc getRawDocuments*(options = newQueryOptions()): LSResponse 

Retrieves multiple documents in JSON format based on the specified options.

##### Parameters

{{p-options}}

#### getDocument

     proc getDocument*(id: string, options = newQueryOptions()): LSResponse 

Retrieves a single document.

##### Parameters

{{p-id}}
{{p-options}}

#### getRawDocument

     proc getRawDocument*(id: string, options = newQueryOptions()): LSResponse 

Retrieves a single document in JSON format.

##### Parameters

{{p-id}}
{{p-options}}

#### deleteDocument

     proc deleteDocument*(id: string): LSResponse 

Deletes the specified document.

##### Parameters

{{p-id}}

#### postDocument

     proc postDocument*(body, ct: string, folder=""): LSResponse 

Creates a new document in the specified folder.

##### Parameters

{{p-body}}
{{p-ct}}
{{p-folder}}

#### putDocument

     proc putDocument*(id, body, ct: string): LSResponse 

Modifies an existing document.

##### Parameters

{{p-id}}
{{p-body}}
{{p-ct}}

#### patchDocument

     proc patchDocument*(id, body: string): LSResponse 

Modifies the tags of an existing document.

##### Parameters

{{p-id}}
{{p-body}}

