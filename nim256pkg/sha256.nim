import types
import sequtils

type
  Block    = array[16, uint32]
  Schedule = array[64, uint32]
  Hash     = array[ 8, uint32]
  State    = tuple[a, b, c, d, e, f, g, h : uint32]

const
  kRounds    = 64
  kHashWords = 8
  kRoundKeys = [
    0x428a2f98'u32, 0x71374491'u32, 0xb5c0fbcf'u32, 0xe9b5dba5'u32,
    0x3956c25b'u32, 0x59f111f1'u32, 0x923f82a4'u32, 0xab1c5ed5'u32,
    0xd807aa98'u32, 0x12835b01'u32, 0x243185be'u32, 0x550c7dc3'u32,
    0x72be5d74'u32, 0x80deb1fe'u32, 0x9bdc06a7'u32, 0xc19bf174'u32,
    0xe49b69c1'u32, 0xefbe4786'u32, 0x0fc19dc6'u32, 0x240ca1cc'u32,
    0x2de92c6f'u32, 0x4a7484aa'u32, 0x5cb0a9dc'u32, 0x76f988da'u32,
    0x983e5152'u32, 0xa831c66d'u32, 0xb00327c8'u32, 0xbf597fc7'u32,
    0xc6e00bf3'u32, 0xd5a79147'u32, 0x06ca6351'u32, 0x14292967'u32,
    0x27b70a85'u32, 0x2e1b2138'u32, 0x4d2c6dfc'u32, 0x53380d13'u32,
    0x650a7354'u32, 0x766a0abb'u32, 0x81c2c92e'u32, 0x92722c85'u32,
    0xa2bfe8a1'u32, 0xa81a664b'u32, 0xc24b8b70'u32, 0xc76c51a3'u32,
    0xd192e819'u32, 0xd6990624'u32, 0xf40e3585'u32, 0x106aa070'u32,
    0x19a4c116'u32, 0x1e376c08'u32, 0x2748774c'u32, 0x34b0bcb5'u32,
    0x391c0cb3'u32, 0x4ed8aa4a'u32, 0x5b9cca4f'u32, 0x682e6ff3'u32,
    0x748f82ee'u32, 0x78a5636f'u32, 0x84c87814'u32, 0x8cc70208'u32,
    0x90befffa'u32, 0xa4506ceb'u32, 0xbef9a3f7'u32, 0xc67178f2'u32
  ].Schedule
  kInitial = [
    0x6a09e667'u32,
    0xbb67ae85'u32,
    0x3c6ef372'u32,
    0xa54ff53a'u32,
    0x510e527f'u32,
    0x9b05688c'u32,
    0x1f83d9ab'u32,
    0x5be0cd19'u32,
  ].Hash

proc rotate_right(word, amount : uint32) : uint32 {.inline.} =
  (word shr amount) or (word shl (32.uint32 - amount))

proc choose(mask, lhs, rhs : uint32) : uint32 {.inline.} =
  (mask and lhs) xor (not mask and rhs)

proc majority(fst, snd, thd : uint32) : uint32 {.inline.} =
  (fst and snd) xor (fst and thd) xor (snd and thd)

proc big_sigma_0(word: uint32) : uint32 {.inline.} =
  rotate_right(word, 2) xor rotate_right(word, 13) xor rotate_right(word, 22)

proc big_sigma_1(word: uint32) : uint32 {.inline.} =
  rotate_right(word, 6) xor rotate_right(word, 11) xor rotate_right(word, 25)

proc small_sigma_0(word: uint32) : uint32 {.inline.} =
  rotate_right(word, 7) xor rotate_right(word, 18) xor (word shr 3)

proc small_sigma_1(word: uint32) : uint32 {.inline.} =
  rotate_right(word, 17) xor rotate_right(word, 19) xor (word shr 10)

proc newState(state: array[kHashWords, uint32]) : State =
  (a: state[0], b: state[1], c: state[2], d: state[3], e: state[4], f: state[5], g: state[6], h: state[7])

proc update(this: var State, schedule: Schedule) =
  for round in 0..<kRounds:
    let
      tempWordOne:uint32 = this.h + big_sigma_1(this.e) + choose(this.e, this.f, this.g) + kRoundKeys[round] + schedule[round]
      tempWordTwo:uint32 = big_sigma_0(this.a) + majority(this.a, this.b, this.c)

    this.h = this.g
    this.g = this.f
    this.f = this.e
    this.e = this.d + tempWordOne
    this.d = this.c
    this.c = this.b
    this.b = this.a
    this.a = tempWordOne + tempWordTwo

proc update(current: var Hash, state: State) =
  current[0] += state.a
  current[1] += state.b
  current[2] += state.c
  current[3] += state.d
  current[4] += state.e
  current[5] += state.f
  current[6] += state.g
  current[7] += state.h


iterator blocks(message: string): Block =
  const blockBytes = 16 * 4

  let
    bits = message.len * 8
    missing = blockBytes - ((message.len + 9) mod blockBytes)

  var padding = sequtils.repeat(0.uint8, missing + 9)
  padding[0] = 0x80.uint8
  for i in countdown(8, 1):
    padding[padding.len - i] = (bits shr ((i - 1) * 8)).uint8

  let blockCount = ((message.len + padding.len) /% blockBytes) - 1
  for blockNumber in 0..blockCount:
    var
      blockStart = blockBytes * blockNumber
      blockEnd = blockStart + blockBytes
      blockData: Block
    if blockEnd < message.len:
      for i in countup(blockStart, blockEnd - 1, 4):
        blockData[(i - blockStart) /% 4] =
          (message[i + 0].uint32 shl 24) or
          (message[i + 1].uint32 shl 16) or
          (message[i + 2].uint32 shl  8) or
          (message[i + 3].uint32 shl  0)
    elif blockStart < message.len:
      var i = 0
      while i < message.len - blockStart:
        blockData[i /% 4] = blockData[i /% 4] or (message[blockStart + i].uint32 shl ((3 - i mod 4) * 8))
        i += 1
      while i < blockEnd - blockStart:
        blockData[i /% 4] = blockData[i /% 4] or (padding[i - (message.len - blockStart)].uint32 shl ((3 - i mod 4) * 8))
        i += 1
    else:
      for i in countup(padding.len - blockBytes, padding.len - 1, 4):
        blockData[(i - (padding.len - blockBytes)) /% 4] =
          (padding[i + 0].uint32 shl 24) or
          (padding[i + 1].uint32 shl 16) or
          (padding[i + 2].uint32 shl  8) or
          (padding[i + 3].uint32 shl  0)
    yield blockData

proc prepare(data: Block) : Schedule =
  for word in 0..<kRounds:
    if word < 16:
      result[word] = data[word]
    else:
      result[word] =
        small_sigma_1(result[word - 2]) +
        result[word - 7] +
        small_sigma_0(result[word - 15]) +
        result[word - 16]

proc hash*(message: string) : HashBytes =
  var sum : Hash = kInitial
  for b in blocks(message):
    var schedule = prepare(b)
    var state = newState(sum)
    state.update(schedule)
    sum.update(state)

  for i in 0..7:
    result[i * 4 + 0] = uint8(sum[i] shr 24) and 0xff
    result[i * 4 + 1] = uint8(sum[i] shr 16) and 0xff
    result[i * 4 + 2] = uint8(sum[i] shr  8) and 0xff
    result[i * 4 + 3] = uint8(sum[i] shr  0) and 0xff
