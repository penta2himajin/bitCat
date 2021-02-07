# Package

packageName   = "bitCat"
version       = "0.1.0"
author        = "penta2himajin"
description   = "An awesome full-auto trader for cryptcurrency exchange written by Nim programming language."
license       = "MIT"
srcDir        = "src"
binDir        = "bin"
bin           = @[packageName]

# Dependencies

requires "nim >= 1.2.0"
requires "jwt >= 0.2"
requires "hmac >= 0.2.0"
requires "gnuplot >= 0.6"


# Tasks

task build_project, "build project":
  exec "nim c -d:ssl -o:" & $binDir & "/" & $packageName & " " & $srcDir & "/" & $packageName & ".nim"

task run_project, "build and run project":
  exec "nim c -d:ssl -o:" & $binDir & "/" & $packageName & " -r " & $srcDir & "/" & $packageName & ".nim"

task build_backtest, "build backtest":
  exec "nim c -d:ssl -o:" & $binDir & "/backtest " & $srcDir & "/backtest.nim"

task run_backtest, "build and run backtest":
  exec "nim c -d:ssl -o:" & $binDir & "/backtest -r " & $srcDir & "/backtest.nim"