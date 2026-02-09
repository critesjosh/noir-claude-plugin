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
| `std::hash` | blake2s, blake3, pedersen_hash, pedersen_commitment, sha256_compression, keccakf1600 |
| `std::ecdsa_secp256k1` | `verify_signature` |
| `std::ecdsa_secp256r1` | `verify_signature` |
| `std::embedded_curve_ops` | `EmbeddedCurvePoint`, `EmbeddedCurveScalar`, `multi_scalar_mul` |
| `std::collections::bounded_vec` | `BoundedVec` (also in prelude) |
| `std::collections::map` | `HashMap` |
| `std::field` | byte conversions, radix decomposition |

**Moved to external libraries:** Poseidon2 (`poseidon`), SHA-256 (`sha256`), Keccak256, Schnorr, EdDSA. See [Cryptographic Primitives](./cryptographic-primitives.md) for details.
