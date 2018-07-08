[Package]
name          = "litestore"
version       = "1.4.1"
author        = "Fabio Cevasco"
description   = "Self-contained, lightweight, RESTful document store."
license       = "MIT"
bin           = "litestore"
skipFiles     = @["nakefile.nim"]

[Deps]
requires: "nim >= 0.18.0"
