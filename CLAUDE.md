# Noir Development Guidelines

This project uses Noir for zero-knowledge circuit development.

## Technology Stack

- **Noir**: Domain-specific language for writing zero-knowledge circuits
- **Nargo**: Noir's package manager and build tool
- **Barretenberg (bb)**: Backend proving system for generating and verifying proofs
- **noir_js**: JavaScript/TypeScript library for witness generation and oracle callbacks
- **bb.js**: JavaScript/TypeScript library for proof generation and verification

## Key Concepts: Circuits are NOT Programs

### Both Branches Execute

In Noir, `if/else` is not control flow — **both branches produce constraints**. The prover evaluates both sides; the condition selects which result to use. This means:
- You cannot short-circuit computation
- Both branches must be valid (no out-of-bounds access in "unreachable" branches)
- Cost = sum of both branches, not just the taken path

### Compile-Time Loop Bounds

All loops must have bounds known at compile time. You cannot write `for i in 0..n` where `n` is a runtime value. Use `BoundedVec` or fixed-size arrays with sentinel values for variable-length data.

### No Dynamic Allocation

Arrays have fixed sizes. There is no heap, no `Vec`, no dynamic resizing. Use:
- `[T; N]` for fixed arrays
- `BoundedVec<T, N>` for variable-length data with a compile-time maximum

### Field is the Native Type

`Field` is the base type — a ~254-bit prime field element. Arithmetic on `Field` is cheap (1 constraint). Integer types (`u8`, `u32`, `u64`) require range-check constraints and are more expensive.

## Public vs Private Inputs

```rust
fn main(
    x: Field,           // Private input (witness) — not revealed to verifier
    pub y: Field,       // Public input — visible to verifier
) -> pub Field {        // Return values are always public
    x + y
}
```

- **Private inputs** (no `pub`): Known only to the prover. These are the "secret" witness values.
- **Public inputs** (`pub`): Visible to both prover and verifier. Minimize these — each adds verification cost.
- **Return values**: Always public. Equivalent to `pub` output parameters.

## Unconstrained Functions

```rust
unconstrained fn hint_sqrt(x: Field) -> Field {
    // No constraints generated — runs outside the circuit
    // Used for computing hints that are then verified
}

fn verified_sqrt(x: Field) -> Field {
    let result = unsafe { hint_sqrt(x) };
    assert(result * result == x);  // Constrained verification
    result
}
```

- Prefixed with `unconstrained` keyword
- Run outside the circuit — no constraints, no proving cost
- **Never trust unconstrained output** — always verify with constraints
- Use `unsafe {}` blocks to call unconstrained functions from constrained code
- Common pattern: compute in unconstrained, verify in constrained

## Oracles

```rust
#[oracle(get_secret)]
unconstrained fn oracle_get_secret(key: Field) -> Field {}

unconstrained fn get_secret(key: Field) -> Field {
    oracle_get_secret(key)
}
```

- `#[oracle(name)]` attribute marks a foreign function implemented in JavaScript
- Body must be empty in Noir — implementation lives in the JS runtime
- Always unconstrained (oracles can't produce constraints)
- Wrapper function provides a clean interface

## Quick Reference

### Basic Circuit Template

```rust
fn main(x: Field, y: pub Field) -> pub Field {
    assert(x != 0, "x must be non-zero");
    let result = x * y;
    assert(result as u64 < 1000000);
    result
}
```

### Test Template

```rust
#[test]
fn test_basic() {
    let result = main(5, 10);
    assert_eq(result, 50);
}

#[test(should_fail_with = "x must be non-zero")]
fn test_zero_fails() {
    let _ = main(0, 10);
}
```

### Common Types

| Type | Description | Cost |
|------|-------------|------|
| `Field` | ~254-bit prime field element | Cheapest (native) |
| `bool` | Boolean (0 or 1) | 1 constraint |
| `u8`..`u64` | Unsigned integers | Range check constraints |
| `i8`..`i64` | Signed integers | Range check constraints |
| `[T; N]` | Fixed-size array | N * cost(T) |
| `BoundedVec<T, N>` | Variable-length, max N | Up to N * cost(T) |
| `str<N>` | Fixed-length string | N bytes |
| `(T1, T2)` | Tuple | cost(T1) + cost(T2) |

### Project Structure

```
project/
├── Nargo.toml          # Package manifest
├── src/
│   └── main.nr         # Entry point (contains `main` function)
├── Prover.toml          # Default prover inputs
└── Verifier.toml        # Default verifier inputs (public only)
```

### Nargo.toml Template

```toml
[package]
name = "my_circuit"
type = "bin"
authors = [""]
compiler_version = ">=1.0.0"

[dependencies]
```

## Version Detection

**IMPORTANT: Detect the user's Noir version before writing code.**

Extract from `Nargo.toml`:

```toml
[package]
compiler_version = ">=1.0.0"
```

Or check installed version:
```bash
nargo --version
```

If version differs from what the MCP server has synced, re-sync:
```
noir_sync_repos({ version: "<detected-version>", force: true })
```

## MANDATORY: Always Use Noir MCP Server First

**The Noir API evolves across versions. Query the noir-mcp-server BEFORE writing any Noir code.**

### Workflow

```
User asks Noir question
         ↓
   noir_sync_repos() (if not done)
         ↓
   noir_search_code() / noir_search_docs() / noir_search_stdlib()
         ↓
   noir_read_example() if needed
         ↓
   Respond with VERIFIED current syntax
```

### Available MCP Tools

| Tool | Purpose |
|------|---------|
| `noir_sync_repos()` | Clone/update Noir repos locally |
| `noir_status()` | Check which repos are synced |
| `noir_search_code()` | Search Noir source code (regex) |
| `noir_search_docs()` | Search Noir documentation |
| `noir_search_stdlib()` | Search standard library |
| `noir_list_examples()` | List available examples |
| `noir_read_example()` | Read example source code |
| `noir_read_file()` | Read any file from cloned repos |
| `noir_list_libraries()` | List available libraries |

### When to Use

- Library/API documentation
- Code generation
- Setup or configuration
- Syntax or patterns
- Error troubleshooting
- Standard library functions

## Detailed Documentation

For comprehensive patterns, see the skills:

- **[Circuit Development](./skills/noir-developer/SKILL.md)** — Data types, generics, traits, modules, oracles
- **[Testing](./skills/noir-testing/SKILL.md)** — Test attributes, assertions, organization
- **[JavaScript Integration](./skills/noir-js/SKILL.md)** — Compilation, witness generation, proving
- **[Web Integration](./skills/noir-web/SKILL.md)** — React, Web Workers, WASM setup
- **[Circuit Review](./skills/review-circuit/SKILL.md)** — Correctness, constraint efficiency, soundness

## Useful Resources

- Noir Documentation: https://noir-lang.org/docs
- Noir GitHub: https://github.com/noir-lang/noir
- Noir Standard Library: https://noir-lang.org/docs/standard_library
- Barretenberg: https://github.com/AztecProtocol/barretenberg
