# Arbeta
A simple, but not snail-slow, [Proof of Work (PoW)](https://en.wikipedia.org/wiki/Proof_of_work) worker. _Arbeta_ uses [Shaman][shaman] as SHA-256 implementation.

# Usage

```swift
let worker = HashPOWWorker<SHA256TwiceHash>(
    difficulty: 16, // Target number of leading zeros in hash
    maxDuration: 2 * 60 // Throw error after 2min
)

let pow = try await worker.pow(data: "Hello, world!".data(using: .utf8)!)
assert(pow.output.nonce == 134_940) // yes
```

## Performance

Thanks to being able to cache reused SHA256 state, a featured offered by [Shaman][shaman], we see a ~10% performance boost for nested SHA256 PoW and a ~35% performance boost for SHA256 (once).

```swift
let vector = (
    expectedResultingNonce: 2_317_142_010, 
    seed: "1e7d73d01f09ef9bd60de85b3aa7799531342dc6211f43e1a9b253725d8ee4e7", 
    difficulty: 32
)
```

Running that vector with a `HashPOWWorker<Shaman256>` worker with cache enabled (default) yields:
```sh
✅ PoW usedCache=true took 1760s.
```

And with cache disabled (really just relevant for testing):
```sh
✅ PoW usedCache=false took 2700s.
```

Which results in a 35% performance boost.

## Etymology
"Arbeta" means "Work" in Swedish 🇸🇪.

[shaman]: https://github.com/Sajjon/Shaman
