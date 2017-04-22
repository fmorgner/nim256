# nim256

An pure nim implementation of 256-bit hashing algorithms.

## Supported algorithms

- SHA256

## Adding new algorithms

Adding new algorithms is as simple as defining a new value for `HashAlgo` and
implementing your algorithm. See `nim256pkg/sha256.nim` for the interface.
