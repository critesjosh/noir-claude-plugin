# Modules and Imports

Noir uses a module system for organizing code across files.

## Module Declarations

Declare a module in the parent file with `mod`. The compiler looks for a corresponding file or directory.

```rust
// src/main.nr
mod utils;      // loads src/utils.nr or src/utils/mod.nr
mod crypto;     // loads src/crypto.nr or src/crypto/mod.nr

fn main(x: Field) {
    let h = crypto::hash(x);
    utils::validate(h);
}
```

### File-Based Modules

```
src/
  main.nr       # declares: mod utils; mod crypto;
  utils.nr      # module content
  crypto.nr     # module content
```

### Directory-Based Modules

For modules with sub-modules, use a directory with `mod.nr`:

```
src/
  main.nr             # declares: mod crypto;
  crypto/
    mod.nr             # declares: mod hash; mod signature;
    hash.nr
    signature.nr
```

```rust
// src/crypto/mod.nr
mod hash;
mod signature;

pub use hash::poseidon_hash;
pub use signature::verify;
```

## Imports with `use`

```rust
// Import a specific item
use utils::validate;

// Import multiple items from the same module
use crypto::{hash, verify};

// Aliased import
use crypto::hash as compute_hash;
```

## Visibility with `pub`

By default, all items are private to their module. Use `pub` to make them accessible from outside.

```rust
// src/utils.nr

// Public: accessible from other modules
pub fn validate(x: Field) -> bool {
    check_range(x)
}

// Private: only accessible within this module
fn check_range(x: Field) -> bool {
    // ...
    true
}
```

### Struct Field Visibility

```rust
pub struct Config {
    pub threshold: u64,     // accessible from outside
    secret_key: Field,      // private to this module
}

impl Config {
    // Public constructor since fields might be private
    pub fn new(threshold: u64, key: Field) -> Self {
        Config { threshold, secret_key: key }
    }
}
```

## Crate Structure

The crate root is determined by the package type in `Nargo.toml`:

| Package Type | Root File |
|-------------|-----------|
| `type = "bin"` | `src/main.nr` |
| `type = "lib"` | `src/lib.nr` |

All `mod` declarations form a tree rooted at this file.

### Example Crate Layout

```
my_circuit/
  Nargo.toml            # type = "bin"
  src/
    main.nr             # crate root, declares mod merkle; mod types;
    types.nr            # struct definitions
    merkle/
      mod.nr            # declares mod tree; mod proof;
      tree.nr
      proof.nr
```

```rust
// src/main.nr
mod types;
mod merkle;

use types::Leaf;
use merkle::proof::verify_proof;

fn main(leaf: Leaf, pub root: Field, path: [Field; 32], indices: [u1; 32]) {
    assert(verify_proof(leaf.hash(), root, path, indices));
}
```

## Re-exports

Expose items from sub-modules at a higher level using `pub use`.

```rust
// src/merkle/mod.nr
mod tree;
mod proof;

// Re-export so users can write `merkle::verify` instead of `merkle::proof::verify`
pub use proof::verify;
pub use tree::MerkleTree;
```

## Importing from Dependencies

Items from external crates (declared in `Nargo.toml`) are accessed by crate name.

```rust
// Nargo.toml has: my_lib = { path = "../my_lib" }

use my_lib::some_function;
use my_lib::types::MyStruct;
```

## Using `super` and `crate`

```rust
// src/merkle/proof.nr

// Reference the parent module
use super::tree::MerkleTree;

// Reference the crate root
use crate::types::Leaf;
```
