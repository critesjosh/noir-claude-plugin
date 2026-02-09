# Cryptographic Primitives

## Hash Functions

### Poseidon2 (ZK-Friendly -- Cheapest) -- External Library

The recommended hash for in-circuit use. Operates natively over `Field` elements with minimal constraints.

**Requires a dependency in `Nargo.toml`:**

```toml
[dependencies]
poseidon = { tag = "v0.1.1", git = "https://github.com/noir-lang/poseidon" }
```

```rust
use poseidon::poseidon2::Poseidon2;

fn main(inputs: [Field; 4], pub expected: Field) {
    let h = Poseidon2::hash(inputs, inputs.len());
    assert_eq(h, expected);
}
```

**When to use:** Default choice for any in-circuit hashing (Merkle trees, commitments, nullifiers).

### SHA-256 -- External Library

Full SHA-256 hashing has been moved out of the standard library.

**Requires a dependency in `Nargo.toml`:**

```toml
[dependencies]
sha256 = { tag = "v0.1.0", git = "https://github.com/noir-lang/sha256" }
```

```rust
use sha256::sha256;

fn main(input: [u8; 32]) -> pub [u8; 32] {
    sha256(input)
}
```

**When to use:** EVM compatibility, interoperability with Ethereum contracts, verifying external data.

**Note:** The stdlib still provides `std::hash::sha256_compression` for low-level access to the SHA-256 compression function, but not the full hash.

### Blake2s

```rust
fn main(input: [u8; 32]) -> pub [u8; 32] {
    std::hash::blake2s(input)
}
```

### Blake3

```rust
fn main(input: [u8; 32]) -> pub [u8; 32] {
    std::hash::blake3(input)
}
```

**Note:** Barretenberg limits blake3 inputs to 1024 bytes.

### Keccak256 -- External Library

Full Keccak256 hashing has been moved out of the standard library.

Check [awesome-noir](https://github.com/noir-lang/awesome-noir) for the current Keccak256 library.

**Note:** The stdlib still provides `std::hash::keccakf1600` for the raw Keccak-f[1600] permutation on `[u64; 25]`, but not the full hash.

**When to use:** EVM compatibility when matching Solidity's `keccak256`.

### Pedersen Hash

```rust
use std::hash::pedersen_hash;

fn main(inputs: [Field; 2]) -> pub Field {
    pedersen_hash(inputs)
}
```

### Pedersen Commitment

Returns an `EmbeddedCurvePoint` with `x`, `y`, and `is_infinite` fields.

```rust
use std::hash::pedersen_commitment;

fn main(inputs: [Field; 2]) -> pub Field {
    let commitment = pedersen_commitment(inputs);
    commitment.x  // or commitment.y
}
```

### Hash Cost Comparison

| Hash | Input Type | Output | Relative Cost | Location |
|------|-----------|--------|---------------|----------|
| Poseidon2 | `[Field; N]` | `Field` | Lowest | External: `poseidon` |
| Pedersen | `[Field; N]` | `Field` / `EmbeddedCurvePoint` | Low | `std::hash` |
| Blake2s | `[u8; N]` | `[u8; 32]` | High | `std::hash` |
| Blake3 | `[u8; N]` | `[u8; 32]` | High | `std::hash` |
| SHA-256 | `[u8; N]` | `[u8; 32]` | High | External: `sha256` |
| Keccak256 | `[u8; N]` | `[u8; 32]` | Highest | External library |

## Signature Verification

### ECDSA secp256k1 (Bitcoin/Ethereum)

```rust
use std::ecdsa_secp256k1::verify_signature;

fn main(
    public_key_x: [u8; 32],
    public_key_y: [u8; 32],
    signature: [u8; 64],
    hashed_message: [u8; 32],
) {
    let valid = verify_signature(public_key_x, public_key_y, signature, hashed_message);
    assert(valid, "invalid secp256k1 signature");
}
```

**When to use:** Verifying Ethereum or Bitcoin signatures.

### ECDSA secp256r1 (WebAuthn/Passkeys)

```rust
use std::ecdsa_secp256r1::verify_signature;

fn main(
    public_key_x: [u8; 32],
    public_key_y: [u8; 32],
    signature: [u8; 64],
    hashed_message: [u8; 32],
) {
    let valid = verify_signature(public_key_x, public_key_y, signature, hashed_message);
    assert(valid, "invalid secp256r1 signature");
}
```

**When to use:** WebAuthn, passkeys, hardware security modules.

### Schnorr and EdDSA -- Removed from Stdlib

Schnorr signature verification (`std::schnorr`) and EdDSA verification (`std::eddsa`) have been **removed from the standard library**. Check [awesome-noir](https://github.com/noir-lang/awesome-noir) for community-maintained alternatives or use the embedded curve operations directly.

## Choosing the Right Primitive

| Need | Recommended |
|------|-------------|
| In-circuit hashing (Merkle, commitments) | Poseidon2 (external `poseidon` lib) |
| EVM/Solidity interop | SHA-256 (external `sha256` lib) or Keccak256 (external) |
| General-purpose hash | Blake2s or Blake3 (stdlib) |
| Ethereum/Bitcoin signatures | ECDSA secp256k1 (stdlib) |
| Passkey/WebAuthn signatures | ECDSA secp256r1 (stdlib) |
