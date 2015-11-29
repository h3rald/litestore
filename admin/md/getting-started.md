## Getting Started


### Downloading Pre-built Binaries

The easiest way to get LiteStore is by downloading one of the prebuilt binaries from the [Github Release Page][release]:

  * [LiteStore for Mac OS X (x64)](https://github.com/h3rald/litestore/releases/download/v1.0.3litestore_v1.0.3_macosx_x64.zip) -- Compiled on OS X El Capitan (LLVM CLANG 7.0.0)
  * [LiteStore for Windows (x64)](https://github.com/h3rald/litestore/releases/download/v1.0.3/litestore_v1.0.3_windows_x64.zip) -- Cross-compiled on OS X El Capitan (MinGW-w64 GCC 4.8.2)
  * [LiteStore for Windows (x86)](https://github.com/h3rald/litestore/releases/download/v1.0.3/litestore_v1.0.3_windows_x86.zip) -- Cross-compiled on OS X El Capitan (MinGW-w64 GCC 4.8.2)
  * [LiteStore for Linux (x64)](https://github.com/h3rald/litestore/releases/download/v1.0.3/litestore_v1.0.3_linux_x64.zip) -- Cross-compiled on OS X El Capitan (GNU GCC 4.8.1)
  * [LiteStore for Linux (x86)](https://github.com/h3rald/litestore/releases/download/v1.0.3/litestore_v1.0.3_linux_x86.zip) -- Cross-compiled on OS X El Capitan (GNU GCC 4.8.1)
  * [LiteStore for Linux (ARM)](https://github.com/h3rald/litestore/releases/download/v1.0.3/litestore_v1.0.3_linux_arm.zip) -- Cross-compiled on OS X El Capitan (GNU GCC 4.8.2)

### Installing using Nimble

If you already have [Nim](http://nim-lang.org/) installed on your computer, you can simply run

[nimble install litestore](class:cmd)

### Building from Source

You can also build LiteStore from source, if there is no pre-built binary for your platform. All you have to do is the following:

1. Download and install [Nim](http://nim-lang.org/).
2. Clone the LiteStore [repository](https://github.com/h3rald/litestore).
4. Run [nim c litestore.nim](class:cmd) within the respository folder.

### Running the Administration App

A simple but functional Administration App is available to manage LiteStore, create documents interactively, view and search content, etc. 

To get the app up and running (assuming that you have the [litestore](class:cmd) executable in your path):

1. Download the default [data.db](https://github.com/h3rald/litestore/releases/download/v1.0.3/data.db) file. This file is a LiteStore data store file containing the sample app.
2. Go to the local directory in which you downloaded the [data.db](class:cmd) file.
3. Run [litestore -s:data.db](class:cmd)
4. Go to <http://localhost:9500/docs/admin/index.html>.
