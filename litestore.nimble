[Package]
name          = "litestore"
version       = "1.3.0"
author        = "Fabio Cevasco"
description   = "Self-contained, lightweight, RESTful document store."
license       = "MIT"
bin           = "litestore"
skipFiles     = @["nakefile.nim"]

[Deps]
requires: "nim >= 0.17.2"
