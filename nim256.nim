import docopt
import strutils
import nim256pkg/lib as nim256

const doc = """
nim256 - 256-bit hashing

Usage:
  nim256 [-a ALGO | --algorithm=ALGO] [INPUT]
  nim256 (-h | --help)
  nim256 (-v | --version)

Options:
  -h --help                  Show the command help
  -a ALGO, --algorithm=ALGO  The hashing algorithm to use [default: sha256]
  -v --version               Show version
"""

let arguments = docopt(doc, version="nim256 0.1.0")
var hashAlgo:HashAlgo
var algo = $arguments["--algorithm"]
case algo:
  of "sha256": hashAlgo = SHA256
  else:
    echo "Unsupported algorithm", algo
    quit 1

let input = if arguments["INPUT"]: $arguments["INPUT"] else: ""

echo algo , ':', nim256.hexHash(SHA256, input)
