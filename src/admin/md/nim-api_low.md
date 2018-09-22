### Low-Level Nim API

The following [proc](class:kwd)s implement low-level operations on the LiteStore data store. Unlike the high-level API, the [proc](class:kwd)s exposed by this API do not perform the same validation checks as the corresponding HTTP operations, and they are meant to be used with caution in more advanced use cases.

#### getInfo

     proc getInfo*(): LSResponse 

Retrieves information about the currently-loaded data store file.

#### getRawDocuments

     proc getRawDocuments*(options = newQueryOptions()): LSResponse 

Retrieves multiple documents in JSON format based on the specified options.

##### Parameters

<dl>
<dt>options</dt>
<dd>A [QueryOptions](#QueryOptions) object representing a query to execute on a document.</dd>
</dl>

#### getDocument

     proc getDocument*(id: string, options = newQueryOptions()): LSResponse 

Retrieves a single document.

##### Parameters

<dl>
<dt>id</dt> 
<dd>The identifier of the resource (set to an empty string if not needed).</dd>
<dt>options</dt>
<dd>A [QueryOptions](#QueryOptions) object representing a query to execute on a document.</dd>
</dl>

#### getRawDocument

     proc getRawDocument*(id: string, options = newQueryOptions()): LSResponse 

Retrieves a single document in JSON format.

##### Parameters

<dl>
<dt>id</dt> 
<dd>The identifier of the resource (set to an empty string if not needed).</dd>
<dt>options</dt>
<dd>A [QueryOptions](#QueryOptions) object representing a query to execute on a document.</dd>
</dl>

#### deleteDocument

     proc deleteDocument*(id: string): LSResponse 

Deletes the specified document.

##### Parameters

<dl>
<dt>id</dt> 
<dd>The identifier of the resource (set to an empty string if not needed).</dd>
</dl>

#### postDocument

     proc postDocument*(body, ct: string, folder=""): LSResponse 

Creates a new document in the specified folder.

##### Parameters

<dl>
<dt>body</dt>
<dd>The request body.</dd>
<dt>ct</dt>
<dd>Determines the content type of the [body](class:kwd) parameter.</dd>
<dt>folder</dt>
<dd>A logical folder where the document will be saved.</dd>
</dl>

#### putDocument

     proc putDocument*(id, body, ct: string): LSResponse 

Modifies an existing document.

##### Parameters

<dl>
<dt>id</dt> 
<dd>The identifier of the resource (set to an empty string if not needed).</dd>
<dt>body</dt>
<dd>The request body.</dd>
<dt>ct</dt>
<dd>Determines the content type of the [body](class:kwd) parameter.</dd>
</dl>

#### patchDocument

     proc patchDocument*(id, body: string): LSResponse 

Modifies the tags of an existing document (or the body of a JSON document).

##### Parameters

<dl>
<dt>id</dt> 
<dd>The identifier of the resource (set to an empty string if not needed).</dd>
<dt>body</dt>
<dd>The request body.</dd>
</dl>
