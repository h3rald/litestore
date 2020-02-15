## LiteStore Global Object

When creating JavaScript handlers for custom resources, you can use a special **LiteStore** global object to access the HTTP request to the resource, modify the HTTP response, and also access other LiteStore resources.

### LiteStore.request

The current HTTP request sent to access the current resource.

#### Properties

<dl>
<dt>method: string</dt>
<dd>The HTTP method used by the request, all uppercase (GET, POST, DELETE, PUT, PATCH, OPTIOONS, or HEAD).</dd>
<dt>url: object</dt>
<dd>An object containing the requested URL, split into the following String properties: <b>hostname</b>, <b>port</b>, <b>search</b>, <b>path</b>.</dd>
<dt>headers: object</dt>
<dd>An object containing the request headers, as keys and values.</dd>
</dl>

### LiteStore.response

The HTTP response to return to the client.

<dl>
<dt>code: number</dt>
<dd>The HTTP return code, by default set to `200`.</dd>
<dt>content: string</dt>
<dd>The response content, by default set to `""`.</dd>
<dt>headers: object</dt>
<dd>The response headers, by default set to:
<pre><code>
{
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "Authorization, Content-Type",
  "Server": "LiteStore/&lt;version&gt;",
  "Content-Type": "application/json",
  "Content-Length": "&lt;Automatically set to the length of the <b>content</b> property.&gt;"
}
</code></pre></dd>
</dl>

### LiteStore.api

Simple synchronous API to access LiteStore resources in a RESTful way, mimicking HTTP methods. 

All methods return a response object containing two String properties, **code** and **content**.

<dl>
<dt>function get(resource: string, id: string, parameters: string): object</dt>
<dd>Retrieves the specified resource(s.). 
<p>
Examples:
<ul>
<li><code>LiteStore.api.get('docs', 'test-folder/test.json')</code></li>
<li><code>LiteStore.api.get('docs', '', 'search=test&limit=20&offset=0')</code></li>
</ul>
</p>
</dd>
<dt>function post(resource: string, folder: string, body: string, contentType: string): object</dt>
<dd>Creates a new resource. 
<p>
Examples:
<ul>
<li><code>LiteStore.api.post('docs', 'test-folder', 'test!', 'text/plain')</code></li>
<li><code>LiteStore.api.post('docs', '', '{"a": 1}', ?application/json')</code></li>
</ul>
</p>
</dd>
<dt>function put(resource: string, id: string, body: string, contentType: string): object</dt>
<dd>Creates or updates a specific resource. 
<p>
Examples:
<ul>
<li><code>LiteStore.api.put('docs', 'test-folder/test1.txt', 'Another Test.', 'text/plain')</code></li>
<li><code>LiteStore.api.put('docs', 'test.json', '{"a": 2}', 'application/json')</code></li>
</ul>
</p>
</dd>
<dt>function patch(resource: string, id: string, body: string): object</dt>
<dd>Patches one or more fields of an existing resource.
<p>
Examples:
<ul>
<li><code>LiteStore.api.patch('docs', 'test-folder/test1.txt', '{"op":"add", "path":"/tags/3", "value":"test1"}')</code></li>
</ul>
</p>
</dd>
<dt>function delete(resource: string, id: string): object</dt>
<dd>Deletes a specific resource. 
<p>
Examples:
<ul>
<li><code>LiteStore.api.delete('docs', 'test-folder/test1.txt')</code></li>
<li><code>LiteStore.api.delete('docs', 'test.json')</code></li>
</ul>
</p>
</dd>
<dt>function head(resource: string, id: string): object</dt>
<dd>Retrieves the metadata of  one or more resources, without retrieving their contents.
<p>
Examples:
<ul>
<li><code>LiteStore.api.head('docs', 'test-folder/test1.txt')</code></li>
<li><code>LiteStore.api.head('docs')</code></li>
</ul>
</p>
</dd>
</dl>