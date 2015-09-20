## Getting Started


### Downloading Pre-built Binaries

The easiest way to get LiteStore is by downloading one of the prebuilt binaries from the [Github Release Page][release]:

  * [LiteStore for Mac OS X (x64)](https://github.com/h3rald/litestore/releases/download/v1.0.0litestore_v1.0.0_macosx_x64.zip) -- Compiled on OS X Yosemite (LLVM CLANG 6.0)
  * [LiteStore for Windows (x64)](https://github.com/h3rald/litestore/releases/download/v1.0.0/litestore_v1.0.0_windows_x64.zip) -- Cross-compiled on OS X Yosemite (MinGW-w64 GCC 4.8.2)
  * [LiteStore for Windows (x86)](https://github.com/h3rald/litestore/releases/download/v1.0.0/litestore_v1.0.0_windows_x86.zip) -- Cross-compiled on OS X Yosemite (MinGW-w64 GCC 4.8.2)
  * [LiteStore for Linux (x86)](https://github.com/h3rald/litestore/releases/download/v1.0.0/litestore_v1.0.0_linux_x86.zip) -- Cross-compiled on OS X Yosemite (GNU GCC 4.8.1)
  * [LiteStore for Linux (ARM)](https://github.com/h3rald/litestore/releases/download/v1.0.0/litestore_v1.0.0_linux_arm.zip) -- Cross-compiled on OS X Yosemite (GNU GCC 4.8.2)

### Installing using Nimble

If you already have [Nim](http://nim-lang.org/) installed on your computer, you can simply run

[nimble install litestore](class:cmd)

### Building from Source

You can also build LiteStore from source, if there is no pre-built binary for your platform. All you have to do is the following:

1. Download and install [Nim](http://nim-lang.org/).
2. Clone the LiteStore [repository](https://github.com/h3rald/litestore).
4. Run [nim c litestore.nim](class:cmd) within the respository folder.