## Multiple Data Stores

As of version 1.9.0, it is possible to configure LiteStore to manage several different SQLite database files, or *stores*. Essentially, besides the *master* store it is possible to create, delete or access additional stores at run time though the new **/stores** resource.

Although folders already provide some partitioning for documents, in certain situations you may want to physically separate your data into multiple files, for example when:

* Managing time-dependent content (store only records of a day or month in a single file)
* Storing accessory content that is unrelated to other data, like logging/diagnostic information
* Managing data belonging to different tenants

Although all stores can be accessed by the same process using the **/stores** resource (which can essentially forward requests to be executed on a specific file), each store can have its own configuration file stored as a system document, its own authentication and its own middleware.

### Configuring additional stores

If you know the details of each store at development/configuration time, you can configure them in the **stores** section of the LiteStore configuration file, like this:

```
{
  "settings": {
    "log": "debug",
    "port": 9200
  },
  "stores": {
    "test1": {
      "file": "test1.db",
      "config": null
    },
    "test2": {
      "file": "test2.db",
      "config": null
    },
    "test3": {
      "file": "test3.db",
      "config": null
    }
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
  }
}
```
  
  When LiteStore is executed, the three additional stores will be created and initialized, their configuration (if any) will be saved as a system document and they will be immediately accessible.
  
  Alternatively, you can add or remove stores dynamically at run time by executing POST and DELETE requests to the **/stores** resource, optionally specifying configuration settings as the request body.