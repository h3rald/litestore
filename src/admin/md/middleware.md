## Middleware

As of version 1.8.0, you can define your own custom middleware using JavaScript executed on the server side.

LiteStore embeds the [duktape](https://duktape.org/) lightweight JavaScript engine and therefore you can use all functionalities exposed by duktape in your code, plus access some LiteStore-specific properties and method through some special global object.

Although writing extremely complex logic in a JavaScript handler may not be appropriate, it can be useful for certain use cases, such as:
* validating data before it is saved
* manipulate data before it is saved
* aggregating different types of data not accessible via a single query
* perform additional operation when accessing data, such as logging who requested it

### How middleware works

Potentially, each resource could have one or more middleware functions associated to it. Association is done through the LiteStore configuration file in a similar way as authentication is configured:

```
{
  "settings": {
    "middleware": "test/middleware"
  },
  "resources": {
    "/docs/vehicles/*": {
      "GET": {
        "middleware": ["validate", "log"]
      },
      "PUT": {
        "auth": ["admin:vehicles"],
        "middleware": ["validate", "log"]
      }
    }
  }
}
```

This simple configuration file shows how to configure middleware to be executed when a resources it requested via GET or PUT. In both cases, first the *validate* middleware function is executed, and then the *log*. These functions must reside in separate files named *validate.js* and *log.js* respectively, and placed into a folder (**test/middleware** in this case) referenced via the **middleware** setting (which is also exposed as a command line option, with **-w** as shorthand option).

Middleware functions are executed sequentially until one of them explicitly stops the execution chain or the execution completes (by requesting the original resource).

Considering the previous configuration example, if a PUT request is made to an item under **/docs/vehicles**:

1. The *validate* middleware function is executed.
2. The *log* middleware function is executed.
3. The request is processed as normal.

Note that, for example, the *validate* middleware function may cause the execution to stop before it reaches the *log* middleware, thereby effectively implementing server-side validation.

### Creating a JavaScript Middleware Function

Let's say you want to keep records of Italian vehicles identified by their number plate, which is in the following format:

\[two-uppercase-letters\][three-digits\][two-uppercase-letters\]

For example: AB467DX (OK, in reality there's a space between each set of digits/letters, but spaces in identifiers are ugly, so let's remove them!)

Let's also say that Italian vehicle data will be managed within a folder called **vehicles**, therefore vehicles will be accessible at URLs similar to the following:

* http://localhost:9500/docs/vehicles/AB467DX
* http://localhost:9500/docs/vehicles/CD569BW
* http://localhost:9500/docs/vehicles/EF981DE

To make sure that valid IDs are used, we can create a file called **vehicles.js** and write the following code:

```
(function() {
  var id = $req.path.replace(/^\/docs\//, "");
  var valid = /[A-Z]{2}[0-9]{3}[A-Z]{2}/;
  if (!id.match(valid)) {
    $res.content = {
      error: "Invalid number plate"
    };
    $res.code = 400;
    return true;
  }
  $ctx.existing = !!($store.get("docs", id).code == 200);
})();
```

Note that middleware must be coded in the form of an [IIFE](https://en.wikipedia.org/wiki/Immediately_invoked_function_expression). In this case, the function:
* retrieves the ID of the vehicle.
* checks if it's valid
* if it's invalid, prepares a 400 - Bad Request response and stops the execution of additional middleware (and ultimately the request itself) by returning **true**.
* otherwise, it checks whether the vehicle already exists and stores this information on a context, so that it will be accessible to other middleware functions down the execution chain.

### Passing data to another middleware

Although you can technically add additional properties to the **$req** and **$res** objects, you should use **$ctx** instead. **$ctx** is a global objects.

In the *validate* middleware described in the previous section, the **$ctx.existing** property was set. This property can then be accessed and/or modified in additional middleware down the execution chain.

Consider for example the following, very basic *log* middleware function:

```
(function(){
    var doc = {
        user: $req.jwt.claims && $req.jwt.claims.sub || null,
        agent: $req.headers['user-agent'],
        language: $req.headers['accept-language'] && $req.headers['accept-language'].replace(/,.+$/, ''),
        path: $req.path,
        existing: !!$ctx.existing,
        method: $req.method,
        timestamp: Date.now()
    }
    $store.post('docs', 'logs', JSON.stringify(doc), 'application/json');
}())
```

This middleware function simply logs the current request to another folder within the data store, and gathers some stats and whether the request was performed on an existing object or not. In this case, **$ctx.existing** should be set by another middleware up the chain (*validate*).