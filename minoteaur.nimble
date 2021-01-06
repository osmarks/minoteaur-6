# Package

version       = "0.1.0"
author        = "osmarks"
description   = "A notes thing™."
license       = "MIT"
srcDir        = "src"
bin           = @["minoteaur"]

# Dependencies

requires "nim >= 1.4.2"
requires "prologue >= 0.4"
requires "karax >= 1.2.1"
requires "https://github.com/GULPF/tiny_sqlite#2944bc7"
requires "zstd >= 0.5.0"
requires "https://github.com/osmarks/nim-cmark-gfm"
#requires "cmark >= 0.1.0"
requires "regex >= 0.18.0"
# seemingly much faster than standard library Levenshtein distance module
requires "nimlevenshtein >= 0.1.0"
#requires "gara >= 0.2.0"