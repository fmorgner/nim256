import sha256
import types
import strutils

type
  HashAlgo* = enum
    SHA256

proc byteHash*(algo: HashAlgo, input: string) : HashBytes =
  case algo:
    of SHA256:
      sha256.hash(input)

proc hexHash*(algo: HashAlgo, input: string) : string =
  let bytes = byteHash(algo, input)
  result = ""
  for byte in bytes.items:
    result.add(byte.toHex.toLower)
