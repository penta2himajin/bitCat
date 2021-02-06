# Package

version       = "0.1.0"
author        = "penta2himajin"
description   = "An awesome full-auto trader for cryptcurrency exchange written by Nim programming language."
license       = "MIT"
srcDir        = "src"
binDir        = "bin"
bin           = @["bitCat"]


# Dependencies

requires "nim >= 1.2.0"
requires "jwt >= 0.2"
requires "hmac >= 0.2.0"


# Tasks

task build2, "build project":
  exec "nim c -d:ssl -o:bin/bitCat src/bitCat.nim"

task run2, "build and run project":
  exec "nim c -d:ssl -o:bin/bitCat -r src/bitCat.nim"