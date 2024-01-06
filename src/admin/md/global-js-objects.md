## Global JavaScript Objects

When creating JavaScript handlers for middleware, you can use some special $-prefixed global objects to access the HTTP request to the resource, the HTTP response, and also access other LiteStore resources.

### $ctx

An empty object that can be used to temporarily store data to pass across different middleware handlers.

### $req

The current HTTP request sent to access the current resource.

<dl>
<dt>method: string</dt>
<dd>The HTTP method used by the request, all uppercase (GET, POST, DELETE, PUT, PATCH, OPTIOONS, or HEAD).</dd>
<dt>jwt: object</dt>
<dd>An object containing a parsed JWT token, if present. It exposes two properties:
<ul>
<li><strong>headers</strong>, an object typically containing the <strong>alg</strong> (algorithm) and <strong>typ</strong> (type) keys.</li>
<li><strong>claims</strong>, an object containing the claims included in the token (see the <a href="https://www.iana.org/assignments/jwt/jwt.xhtml#claims">IANA JSON Web Token Claims Registry</a> for a list of possible claims).</li>
</ul></dd>
<dt>headers: object</dt>
<dd>An object containing the request headers, as keys and values.</dd>
<dt>protocol: string</dt>
<dd>The request protocol and version.</dd>
<dt>hostname: string</dt>
<dd>The hostname target of the request.</dd>
<dt>port: number</dt>
<dd>The port used for the request.</dd>
<dt>path: string</dt>
<dd>The path to the resource requested.</dd>
<dt>query: string</dt>
<dd>The contents of the request query string.</dd>
<dt>content: string</dt>
<dd>When applicable, the content that was sent as body of the request.</dd>
</dl>

### $res

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

### $store

Simple synchronous API to access LiteStore resources in a RESTful way, mimicking HTTP methods. 

All methods return a response object containing two String properties, **code** and **content**.

<dl>
<dt>function get(resource: string, id: string, parameters: string): object</dt>
<dd>Retrieves the specified resource(s).
<p>
Examples:
<ul>
<li><code>$store.get('docs', 'test-folder/test.json')</code></li>
<li><code>$store.get('docs', '', 'search=test&limit=20&offset=0')</code></li>
</ul>
</p>
</dd>
<dt>function post(resource: string, folder: string, body: string, contentType: string): object</dt>
<dd>Creates a new resource. 
<p>
Examples:
<ul>
<li><code>$store.post('docs', 'test-folder', 'test!', 'text/plain')</code></li>
<li><code>$store.post('docs', '', '{"a": 1}', ?application/json')</code></li>
</ul>
</p>
</dd>
<dt>function put(resource: string, id: string, body: string, contentType: string): object</dt>
<dd>Creates or updates a specific resource. 
<p>
Examples:
<ul>
<li><code>$store.put('docs', 'test-folder/test1.txt', 'Another Test.', 'text/plain')</code></li>
<li><code>$store.put('docs', 'test.json', '{"a": 2}', 'application/json')</code></li>
</ul>
</p>
</dd>
<dt>function patch(resource: string, id: string, body: string): object</dt>
<dd>Patches one or more fields of an existing resource.
<p>
Examples:
<ul>
<li><code>$store.patch('docs', 'test-folder/test1.txt', '{"op":"add", "path":"/tags/3", "value":"test1"}')</code></li>
</ul>
</p>
</dd>
<dt>function delete(resource: string, id: string): object</dt>
<dd>Deletes a specific resource. 
<p>
Examples:
<ul>
<li><code>$store.delete('docs', 'test-folder/test1.txt')</code></li>
<li><code>$store.delete('docs', 'test.json')</code></li>
</ul>
</p>
</dd>
<dt>function head(resource: string, id: string): object</dt>
<dd>Retrieves the metadata of  one or more resources, without retrieving their contents.
<p>
Examples:
<ul>
<li><code>$store.head('docs', 'test-folder/test1.txt')</code></li>
<li><code>$store.head('docs')</code></li>
</ul>
</p>
</dd>
</dl>

### $http

Simple synchronous API to perform HTTP requests. 

All methods return a response object containing the following properties:
* **code** (string)
* **content** (string)
* **headers** (object)

<dl>
<dt>function get(url: string, headers: object): object</dt>
<dd>Executes a GET request.
<p>
Example:
<ul>
<li><code>$http.get('https://reqres.in/api/users', {})</code></li>
</ul>
</p>
</dd>
<dt>function post(url: string, headers: object body: string): object</dt>
<dd>Executes a POST request.
<p>
Example:
<ul>
<li><code>$http.post(https://reqres.in/api/users', {'Content-Type': 'application/json'}, '{"name": "Test", "job": "Tester"}')</code></li>
</ul>
</p>
</dd>
<dt>function put(url: string, headers: object body: string): object</dt>
<dd>Executes a PUT request.
<p>
Example:
<ul>
<li><code>$http.put(https://reqres.in/api/users/2', {'Content-Type': 'application/json'}, '{"name": "Test", "job": "Tester"}')</code></li>
</ul>
</p>
</dd>
<dt>function patch(url: string, headers: object body: string): object</dt>
<dd>Executes a PATCH request.
<p>
Example:
<ul>
<li><code>$http.patch(https://reqres.in/api/users/2', {'Content-Type': 'application/json'}, '{"name": "Test", "job": "Tester"}')</code></li>
</ul>
</p>
</dd>
<dt>function delete(url: string, headers: object): object</dt>
<dd>Executes a DELETE request.
<p>
Example:
<ul>
<li><code>$http.delete('https://reqres.in/api/users/2', {})</code></li>
</ul>
</p>
</dd>
<dt>function head(url: string, headers: object): object</dt>
<dd>Executes a HEAD request.
<p>
Example:
<ul>
<li><code>$http.head('https://reqres.in/api/users', {})</code></li>
</ul>
</p>
</dd>
</dl>
