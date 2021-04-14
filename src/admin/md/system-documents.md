## System Documents

As of version 1.8.0, it is possible to import, export, or delete *system documents* besides ordinary documents. Such documents are different from ordinary documents, because:

* they are only intended to be used internally by LiteStore.
* they cannot be accessed via any of the public APIs except for the [import](class:kwd), [export](class:kwd) and [delete](class:kwd) commands.
* they must have a well-known name and/or folder structure.

At present, only the following system documents are recognized by LiteStore:

* **auth.json** &mdash; The LiteStore authorization configuration file.
* **config.json** &mdash; The main LiteStore configuration file.
* **middleware/\*.js** &mdash; Any [.js](class:ext) file containing the definition of a middleware function, placed within a [middleware](class:dir) folder.

### Importing, exporting and deleting System Documents

You can import, export, and delete system documents with the respective commands, but you must specify the [-\-system](class:kwd) command line flag.

For example, suppose you have a [sysdocs](class:dir) folder containing the following file hierarchy:

* sysdocs/
  * auth.jsom
  * config.json
  * middleware/
    * log.js
    * req.js
    * validate.js

To import all the documents stored within the [sysdocs](class:dir) folder, you must run the following command:

[litestore -d:sysdocs -\-system import](class:kwd)

Similarly, the [export](class:kwd) and [delete](class:kwd) commands can be used to export and delete system documents respectively, always specifying the [-\-system](class:kwd) flag.

### How LiteStore uses System Documents

While at development time you may want to be able to edit your system documents and therefore keep them outside your data store as ordinary text files (and load them using the **-\-auth**, **-\-config** and **-\s-middleware** options), in production you may want to ship them within the data store along with your application data.

At run time, LiteStore will attempt to retrieve settings/middleware/authorization configuration using the following order of precedence (first listed have higher precedence):

1. Command line options
2. Configuration files specified via command line options
3. Configuration files loaded as system documents