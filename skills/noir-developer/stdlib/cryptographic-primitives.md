# Cryptographic Primitives

## Hash Functions

### Poseidon2 (ZK-Friendly -- Cheapest)

The recommended hash for in-circuit use. Operates natively over `Field` elements with minimal constraints.

```rust
use std::hash::poseidon2::Poseidon2::hash;

fn main(inputs: [Field; 4], pub expected: Field) {
    let h = hash(inputs, inputs.len());
    assert_eq(h, expected);
}
```

**When to use:** Default choice for any in-circuit hashing (Merkle trees, commitments, nullifiers).

### SHA-256

```rust
use std::hash::sha256;

fn main(input: [u8; 32]) -> pub [u8; 32] {
    sha256(input)
}
```

**When to use:** EVM compatibility, interoperability with Ethereum contracts, verifying external data.

### Blake2s

```rust
use std::hash::blake2s;

fn main(input: [u8; 32]) -> pub [u8; 32] {
    blake2s(input)
}
```

### Blake3

```rust
use std::hash::blake3;

fn main(input: [u8; 32]) -> pub [u8; 32] {
    blake3(input)
}
```

### Keccak256

```rust
use std::hash::keccak256;

fn main(input: [u8; 32]) -> pub [u8; 32] {
    keccak256(input, input.len() as u32)
}
```

**When to use:** EVM compatibility when matching Solidity's `keccak256`.

### Pedersen Hash

```rust
use std::hash::pedersen_hash;

fn main(inputs: [Field; 2]) -> pub Field {
    pedersen_hash(inputs)
}
```

### Pedersen Commitment

Returns a point (x, y) rather than a single field element.

```rust
use std::hash::pedersen_commitment;

fn main(inputs: [Field; 2]) -> pub Field {
    let commitment = pedersen_commitment(inputs);
    commitment.x  // or commitment.y
}
```

### Hash Cost Comparison

| Hash | Input Type | Output | Relative Cost | Use Case |
|------|-----------|--------|---------------|----------|
| Poseidon2 | `[Field; N]` | `Field` | Lowest | In-circuit default |
| Pedersen | `[Field; N]` | `Field` | Low | Legacy, commitments |
| SHA-256 | `[u8; N]` | `[u8; 32]` | High | EVM compatibility |
| Blake2s | `[u8; N]` | `[u8; 32]` | High | General-purpose |
| Blake3 | `[u8; N]` | `[u8; 32]` | High | General-purpose |
| Keccak256 | `[u8; N]` | `[u8; 32]` | Highest | Solidity compat |

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

### Schnorr (Embedded Curve)

Schnorr signatures over Noir's embedded curve (Grumpkin).

```rust
use std::schnorr::verify_signature;
use std::embedded_curve_ops::EmbeddedCurvePoint;

fn main(
    public_key: EmbeddedCurvePoint,
    signature: [u8; 64],
    message: [u8; 32],
) {
    let valid = verify_signature(public_key.x, public_key.y, signature, message);
    assert(valid, "invalid schnorr signature");
}
```

**When to use:** Native in-circuit signatures with minimal constraint cost.

### EdDSA

EdDSA verification using Poseidon hash on the embedded curve.

```rust
use std::eddsa::eddsa_poseidon_verify;
use std::embedded_curve_ops::EmbeddedCurvePoint;

fn main(pub_key: EmbeddedCurvePoint, signature_s: Field, signature_r8: EmbeddedCurvePoint, message: Field) {
    let valid = eddsa_poseidon_verify(pub_key.x, pub_key.y, signature_s, signature_r8.x, signature_r8.y, message);
    assert(valid, "invalid eddsa signature");
}
```

## Choosing the Right Primitive

| Need | Recommended |
|------|-------------|
| In-circuit hashing (Merkle, commitments) | Poseidon2 |
| EVM/Solidity interop | SHA-256 or Keccak256 |
| General-purpose hash | Blake2s or Blake3 |
| Ethereum/Bitcoin signatures | ECDSA secp256k1 |
| Passkey/WebAuthn signatures | ECDSA secp256r1 |
| Cheapest in-circuit signatures | Schnorr on embedded curve |
| EdDSA-based protocols | EdDSA with Poseidon |
