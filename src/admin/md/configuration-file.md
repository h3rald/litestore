## Configuration File

As of version 1.8.0, you can specify a configuration file containing settings, middleware and authorization configuration using the  **--config** or **-c** command  line option:

[litestore -c:config.json](class:cmd)

A typical configuration file looks like this:

```
{
  "settings": {
    "log": "debug",
    "port": 9200
  },
  "resources": {
    "/docs/vehicles/*": {
      "GET": {
        "middleware": ["validate", "log"]
      },
      "HEAD": {
        "middleware": ["validate", "log"]
      },
      "POST": {
        "allowed": false
      },
      "PATCH": {
        "auth": ["admin:vehicles"],
        "middleware": ["validate", "log"]
      },
      "PUT": {
        "auth": ["admin:vehicles"],
        "middleware": ["validate", "log"]
      },
      "DELETE": {
        "auth": ["admin:vehicles"],
        "middleware": ["validate", "log"]
      }
    },
    "/docs/logs/*": {
      "GET": {
        "auth": ["admin:server"]
      },
      "POST": {
        "allowed": false
      },
      "PUT": {
        "allowed": false
      },
      "PATCH": {
        "allowed": false
      },
      "DELETE": {
        "allowed": false
      }
    }
  },
  "signature": "\n-----BEGIN CERTIFICATE-----\n<certificate text goes here>\n-----END CERTIFICATE-----\n"
}
```

At present, it contains a [settings](class:kwd), a [resources](class:kwd), and a [signature](class:kwd) section.

### settings

This section contains some of the most common command-line options, i.e.:

* address
* port
* store
* directory
* mount
* readonly
* middleware
* log

If a configuration file is specified and some of these settings are configured, they will be recognized as if they were specified via command line. However, if you also specify the same settings via command line, the command line settings will take precedence over the settings defined in the configuration file.

### resources

This section can contain any number of resource paths, like [/docs/](class:kwd), [/info/](class:kwd), [/docs/vehicles/AA456CC](class:kwd) or [/docs/logs/*](class:kwd). If a wildcard is specified after a resource or folder path, the rules defined within that section will match any document within the specified path. So for examople [/docs/vehicles/*](class:kwd) will match both [/docs/vehicles/AB547QV](class:kwd) and [/docs/vehicles/BB326CZ](class:kwd), but *not* [/docs/vehicles/](class:kwd).

Within each resource path, you can specify different HTTP methods (all uppercase) and  within each method any of the following properties:

* **auth** &mdash; A list of JWT scopes necessary to access the specified resource with the specified method.
* **middleware** &mdash; A list of middleware function definitions that will be executed in sequence when the resource is accessed with the specified method.
* **allowed** &mdash; If set to **false**, LiteStore will return a [405 - Method not allowed](class:kwd) error code when accessing  the resource with the specified method.

### signature

This section must be  set to a valid certificate used validate JWT tokens. Note that the certificate must follow a specific format and start with the appropriate begin/end  blocks.