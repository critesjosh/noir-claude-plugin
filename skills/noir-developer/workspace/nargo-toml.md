# Nargo.toml

The package manifest for Noir projects. Located at the root of each crate.

## Complete Annotated Example

```toml
[package]
name = "my_circuit"            # Crate name (used in imports and --package flag)
type = "bin"                   # "bin" for circuits, "lib" for libraries, "contract" for Aztec
authors = ["alice"]            # Optional author list
compiler_version = ">=1.0.0"   # Minimum Noir compiler version
description = "A ZK circuit"   # Optional description

[dependencies]
# Git dependency with tag
my_lib = { git = "https://github.com/user/repo", tag = "v1.0.0", directory = "lib" }

# Path dependency (local)
utils = { path = "../utils" }
```

## [package] Section

### name

The crate name. Must be a valid identifier (letters, digits, underscores).

```toml
name = "merkle_verifier"
```

### type

| Type | Entry File | Purpose |
|------|-----------|---------|
| `"bin"` | `src/main.nr` | Standalone circuit with `fn main()` |
| `"lib"` | `src/lib.nr` | Reusable library (no `main`) |
| `"contract"` | `src/main.nr` | Aztec smart contract |

### compiler_version

Specifies the minimum compiler version required. Uses semver ranges.

```toml
compiler_version = ">=1.0.0"     # any 1.x or higher
compiler_version = ">=0.38.0"    # specific minimum
```

### authors

Optional list of authors.

```toml
authors = ["alice", "bob"]
```

## [dependencies] Section

Declares external crate dependencies. See [Dependencies](./dependencies.md) for full details.

```toml
[dependencies]
# Empty if no external dependencies
```

## [workspace] Section

Only used in the root `Nargo.toml` of a multi-crate project. Lists all member crates.

```toml
[workspace]
members = [
    "circuits/prover",
    "circuits/verifier",
    "libs/crypto",
    "libs/merkle",
]
```

### Workspace Rules

- The root `Nargo.toml` with `[workspace]` should not have a `[package]` section
- Each member directory must have its own `Nargo.toml` with a `[package]` section
- Workspace members can depend on each other via path dependencies

## Examples

### Minimal Binary

```toml
[package]
name = "simple_proof"
type = "bin"
compiler_version = ">=1.0.0"

[dependencies]
```

### Library with Dependencies

```toml
[package]
name = "zk_merkle"
type = "lib"
authors = ["alice"]
compiler_version = ">=1.0.0"

[dependencies]
```

### Workspace Root

```toml
[workspace]
members = [
    "crates/circuit",
    "crates/lib",
]
```

### Binary Using a Local Library

```toml
[package]
name = "my_app"
type = "bin"
compiler_version = ">=1.0.0"

[dependencies]
my_lib = { path = "../my_lib" }
```
