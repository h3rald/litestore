## Custom Resources

As of version 1.8.0, you can define your own custom resources using handlers coded in JavaScript.

LiteStore embeds the [duktape](https://duktape.org/) lightweight JavaScript engine and therefore you can use all functionalities exposed by duktape in your code, plus access some LiteStore-specific properties and method through the special **LiteStore** global object.

Although writing extremely complex logic in a JavaScript handler may not be appropriate, it can be useful for certain use cases, such as:
* validating data before it is saved
* manipulate data before it is saved
* aggregating different types of data not accessible via a single query
* perform additional operation when accessing data, such as logging who requested it

### Creating a JavaScript Handler

Let's say you want to keep records of Italian vehicles identified by their number plate, which is in the following format:

\[two-uppercase-letters\][three-digits\][two-uppercase-letters\]

For example: AB467DX (OK, in reality there's a space between each set of digits/letters, but spaces in identifiers are ugly, so let's remove them!)

Let's also say that Italian vehicle data will be managed by a custom resource called **vehicles**, therefore vehicles will be accessible at URLs similar to the following:

* http://localhost:9500/docs/vehicles/AB467DX
* http://localhost:9500/docs/vehicles/CD569BW
* http://localhost:9500/docs/vehicles/EF981DE

To make sure that valid IDs are used, we can create a file called **vehicles.js** and write the following handler code that intercepts all requests to that specific folder and:

* denies POST requests
* returns an error in case of an invalid ID specified on a PUT request
* allows the request through otherwise

```
if (LiteStore.request.method === 'POST') {
  LiteStore.response.code = 405;
  LiteStore.response.content = JSON.stringify({error: 'No number plate specified.'});
  return;
}
if (LiteStore.request.method === 'PUT' && !LiteStore.request.path.match(/[A-Z]{2}[0-9]{3}[A-Z]{2}$/) {
  LiteStore.response.code = 400;
  LiteStore.response.content = JSON.stringify({error: 'Invalid number plate.'});
  return;
}

LiteStore.passthrough();
```


### Mounting a Handler as a Custom Resource