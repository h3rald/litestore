[Package]
name          = "litestore"
appame        = "LiteStore"
version       = "1.0.0"
author        = "Fabio Cevasco"
description   = "Self-contained, lightweight, RESTful document store."
license       = "MIT"
bin           = "litestore"

[Defaults]
file          = "data.db"
address       = "127.0.0.1"
port          = 9500

[Deps]
requires: "nimrod >= 0.11.0"
