## Usage

### Command Line Syntax

[litestore](class:kwd) **[** _command_ **]** **[** _option1_, _option2_, ... **]**

#### Commands

* **run** &mdash; Start LiteStore server (default if no command specified).
* **delete** &mdash; Delete a previously-imported specified directory (requires -d).
* **import** &mdash; Import the specified directory into the datastore (requires -d).
* **export** &mdash; Export the previously-imported specified directory to the current directory (requires -d).
* **optimize** &mdash; Optimize search indexes.
* **vacuum** &mdash; Vacuum datastore.

#### Options

* **-a**, **-\-address** &mdash; Specify server address (default: 127.0.0.1).
* **-d**, **-\-directory** &mdash; Specify a directory to serve, import, export, delete, or mount.
* **-h**, **-\-help** &mdash; Display program usage.
* **-l**, **-\-log** &mdash; Specify the log level: debug, info, warn, error, none (default: info)
* **-m**, **-\-mount** &mdash; Mirror database changes to the specified directory on the filesystem.
* **-p**, **-\-port** &mdash;Specify server port number (default: 9500).
* **-r**, **-\-readonly** &mdash; Allow only data retrieval operations.
* **-s**, **-\-store** &mdash; Specify a datastore file (default: data.db)
* **-v**, **-\-version** &mdash; Display the program version.

### Examples

#### Starting the HTTP Server

* with default settings:
  
  [litestore](class:cmd)
* with custom port (**9700**) and address (**0.0.0.0**):
 
  [litestore -p:9700 -a:0.0.0.0](class:cmd)

* in read-only mode with logging level set to **debug**:

  [litestore -r -l:debug](class:cmd)
  
* serving the contents of a directory called **admin**:

  [litestore -d:admin](class:cmd)

* mouting a directory called **admin** (changes will be mirrored to filesystem, directory contents will be served):

  [litestore -d:admin -m](class:cmd)

#### Importing a directory

Import a directory called **admin**:

[litestore import -d:admin](class:cmd)

#### Exporting a directory

Export all documents tagged with **$dir:admin** to a local directory called **admin**:

[litestore export -d:admin](class:cmd)

#### Deleting documents within a directory

Delete all documents tagged with **$dir:admin**:

[litestore delete -d:admin](class:cmd)

#### Performing maintenance operations

* vacuum SQlite database:

  [litestore vacuum](class:cmd)

* optimize search index:

  [litestore optimize](class:cmd)
