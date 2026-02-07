# Standard Library

Overview of the Noir standard library (`std`). These modules are available in every Noir project without adding dependencies.

Use the `noir_search_stdlib` MCP tool to search the full standard library source code:
```
noir_search_stdlib({ query: "poseidon" })
```

## Subskills

* [Cryptographic Primitives](./cryptographic-primitives.md) - Hash functions, signature verification, curve operations
* [Collections](./collections.md) - BoundedVec, HashMap
* [Field Operations](./field-operations.md) - Byte conversions, radix decomposition, bit-size assertions

## Quick Reference

| Module | Key Items |
|--------|-----------|
| `std::hash` | poseidon2, sha256, blake2s, blake3, keccak256, pedersen |
| `std::ecdsa_secp256k1` | `verify_signature` |
| `std::ecdsa_secp256r1` | `verify_signature` |
| `std::schnorr` | `verify_signature` |
| `std::eddsa` | `eddsa_poseidon_verify` |
| `std::collections::bounded_vec` | `BoundedVec` |
| `std::collections::map` | `HashMap` |
| `std::field` | byte conversions, radix decomposition |
