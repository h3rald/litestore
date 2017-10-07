[Package]
name          = "litestore"
version       = "1.2.0"
author        = "Fabio Cevasco"
description   = "Self-contained, lightweight, RESTful document store."
license       = "MIT"
bin           = "litestore"
skipFiles     = @["nakefile.nim"]

[Deps]
requires: "nimrod >= 0.17.2"
