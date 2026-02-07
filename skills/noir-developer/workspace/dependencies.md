# Dependencies

Noir supports git and path dependencies declared in `Nargo.toml`.

## Git Dependencies

Pull a crate from a git repository.

### Basic (default branch)

```toml
[dependencies]
my_lib = { git = "https://github.com/user/my_lib" }
```

### Pinned to a Tag

```toml
[dependencies]
my_lib = { git = "https://github.com/user/my_lib", tag = "v1.0.0" }
```

### Pinned to a Branch

```toml
[dependencies]
my_lib = { git = "https://github.com/user/my_lib", branch = "main" }
```

### Subdirectory of a Monorepo

When the library is not at the repository root:

```toml
[dependencies]
crypto_utils = { git = "https://github.com/user/monorepo", tag = "v2.0.0", directory = "libs/crypto" }
```

## Path Dependencies

Reference a local crate on disk. Paths are relative to the `Nargo.toml` file.

```toml
[dependencies]
shared = { path = "../shared" }
merkle = { path = "../../libs/merkle" }
```

### When to Use Path Dependencies

- Workspace members that depend on each other
- Local development of a library before publishing
- Monorepo setups

## Workspace Dependencies

In a workspace, members reference each other via path dependencies.

```
workspace-root/
  Nargo.toml               # [workspace] members = ["app", "lib"]
  app/
    Nargo.toml              # depends on lib
    src/main.nr
  lib/
    Nargo.toml              # type = "lib"
    src/lib.nr
```

**app/Nargo.toml:**

```toml
[package]
name = "app"
type = "bin"
compiler_version = ">=1.0.0"

[dependencies]
lib = { path = "../lib" }
```

**lib/Nargo.toml:**

```toml
[package]
name = "lib"
type = "lib"
compiler_version = ">=1.0.0"

[dependencies]
```

### Using the Dependency

```rust
// app/src/main.nr
use lib::some_function;

fn main(x: Field) -> pub Field {
    some_function(x)
}
```

## Version Resolution

- **Tags** pin to an exact commit (recommended for reproducible builds)
- **Branches** resolve to the latest commit on that branch at fetch time
- **No version field**: If neither tag nor branch is specified, Nargo uses the default branch
- Dependencies are cached locally; run `nargo check` to re-fetch if needed

## Common Dependency Patterns

### Multiple Crates from Same Repo

```toml
[dependencies]
crypto = { git = "https://github.com/org/noir-libs", tag = "v1.0.0", directory = "crypto" }
merkle = { git = "https://github.com/org/noir-libs", tag = "v1.0.0", directory = "merkle" }
utils  = { git = "https://github.com/org/noir-libs", tag = "v1.0.0", directory = "utils" }
```

### Overriding a Dependency for Local Development

Replace a git dependency with a local path temporarily:

```toml
[dependencies]
# Production:
# my_lib = { git = "https://github.com/user/my_lib", tag = "v1.0.0" }

# Local development:
my_lib = { path = "../../my_lib" }
```
