---
name: noir-testing
description: "Test Noir circuits using nargo test. Covers test attributes, assertions, and organization patterns."
allowed-tools: Read, Grep, Glob, Edit, Write, Bash
---

# Noir Testing

Noir has a built-in test framework that runs alongside your circuit code using `nargo test`. Tests are constrained by default, meaning they generate real constraints and verify circuit behavior under proving conditions.

## Key Facts

- Tests live in the same `.nr` files as circuit code, or in separate test modules
- Tests are **constrained by default** -- they generate real constraints just like proving
- Add `unconstrained` to run tests without constraint generation (faster, but less thorough)
- No external test framework needed -- everything is built into `nargo`

## Running Tests

```bash
# Run all tests in the project
nargo test

# Run a specific test by exact name
nargo test --exact test_addition

# Run tests matching a prefix
nargo test test_transfer

# Show println output during tests
nargo test --show-output
```

## Quick Start

```rust
fn add(x: Field, y: Field) -> Field {
    x + y
}

#[test]
fn test_add() {
    assert_eq(add(2, 3), 5);
}

#[test(should_fail_with = "attempt to divide by zero")]
fn test_divide_by_zero() {
    let _ = 1 / 0;
}

#[test]
unconstrained fn test_add_unconstrained() {
    // Runs faster without constraint generation
    assert_eq(add(2, 3), 5);
}
```

## Detailed Guides

- **[Test Attributes](./test-attributes.md)** -- `#[test]`, `should_fail`, constrained vs unconstrained
- **[Assertion Patterns](./assertion-patterns.md)** -- `assert`, `assert_eq`, debugging with `println`
- **[Test Organization](./test-organization.md)** -- Modules, file structure, helpers, best practices
