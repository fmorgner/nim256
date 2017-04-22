import ospaths
template thisModuleFile: string = instantiationInfo(fullPaths = true).filename
import nim256pkg/lib

# Package

version       = "0.1.0"
author        = "Felix Morgner"
description   = "Hash stuff"
license       = "MIT"

#backend       = "cpp"
bin           = @["nim256"]

# Dependencies

requires "nim >= 0.16.1"
requires "docopt >= 0.1.0"
