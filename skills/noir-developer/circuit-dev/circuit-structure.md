# Circuit Structure

## Entry Point: `fn main()`

Every Noir binary crate has a `main` function as its entry point. This defines the circuit's inputs and outputs.

```rust
fn main(
    secret: Field,          // Private input (witness) -- only the prover knows this
    pub threshold: u64,     // Public input -- visible to the verifier
) -> pub Field {            // Return value -- always public
    assert(secret as u64 > threshold, "secret must exceed threshold");
    secret
}
```

### Input Visibility

- **Private inputs** (no `pub` keyword): Known only to the prover. These are the secret witness values.
- **Public inputs** (`pub` keyword): Visible to both prover and verifier. Minimize these -- each adds verification cost.
- **Return values**: Always public. Equivalent to `pub` output parameters.

## Assertions

Assertions are the primary way to define constraints. If an assertion fails, proof generation fails.

```rust
fn main(x: Field, y: Field) {
    // Basic assertion
    assert(x != 0);

    // Assertion with error message
    assert(x != y, "x and y must differ");

    // Equality assertion
    assert_eq(x * x, y, "y must be x squared");
}
```

## Complete Circuit Example

```rust
// Prove knowledge of a preimage that hashes to a known digest
// Requires poseidon dependency in Nargo.toml
use poseidon::poseidon2::Poseidon2;

fn main(preimage: [Field; 4], pub expected_hash: Field) {
    let computed = Poseidon2::hash(preimage, preimage.len());
    assert_eq(computed, expected_hash, "hash mismatch");
}
```

## Module Organization

For larger projects, split logic across modules:

```
src/
  main.nr          # Entry point with fn main()
  utils.nr         # Helper functions
  types.nr         # Custom structs and type definitions
```

```rust
// src/main.nr
mod utils;
mod types;

use utils::validate;
use types::Claim;

fn main(claim: Claim, pub root: Field) {
    assert(validate(claim, root));
}
```

## Library Crates

A library crate uses `lib.nr` instead of `main.nr` and has `type = "lib"` in `Nargo.toml`. Libraries expose functions for other crates to use but have no `main` entry point.

```rust
// src/lib.nr
pub fn compute_root(leaves: [Field; 4]) -> Field {
    // Merkle root computation
    // ...
}
```

## Binary vs Library

| Aspect | Binary (`type = "bin"`) | Library (`type = "lib"`) |
|--------|------------------------|-------------------------|
| Entry file | `src/main.nr` | `src/lib.nr` |
| Has `fn main()` | Yes | No |
| Generates proofs | Yes | No (consumed by binaries) |
| Use case | Standalone circuit | Reusable logic |

## Prover and Verifier Inputs

After compilation, provide inputs via TOML files:

**Prover.toml** (all inputs):
```toml
secret = "42"
threshold = "10"
```

**Verifier.toml** (public inputs and return values only):
```toml
threshold = "10"
return = "42"
```
