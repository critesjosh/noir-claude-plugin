# Test Organization

Strategies for structuring tests in Noir projects, from simple inline tests to multi-file test suites.

## Inline Tests

The simplest approach. Place `#[test]` functions directly in the same file as the circuit code.

```rust
// src/main.nr

fn add(a: Field, b: Field) -> Field {
    a + b
}

fn mul(a: Field, b: Field) -> Field {
    a * b
}

fn main(x: Field, y: pub Field) -> pub Field {
    add(mul(x, x), y)
}

#[test]
fn test_add() {
    assert_eq(add(2, 3), 5);
}

#[test]
fn test_mul() {
    assert_eq(mul(3, 4), 12);
}

#[test]
fn test_main() {
    assert_eq(main(3, 1), 10); // 3*3 + 1 = 10
}
```

This works well for small circuits. As the file grows, consider extracting tests into a module.

## Test Modules

Group tests in a `mod tests` block at the bottom of the file. This keeps test code visually separated from circuit logic.

```rust
// src/main.nr

fn validate_transfer(sender_balance: u64, amount: u64) -> u64 {
    assert(amount > 0, "amount must be positive");
    assert(amount <= sender_balance, "insufficient balance");
    sender_balance - amount
}

fn main(balance: Field, amount: pub Field) -> pub Field {
    let remaining = validate_transfer(balance as u64, amount as u64);
    remaining as Field
}

mod tests {
    use super::validate_transfer;

    #[test]
    fn test_valid_transfer() {
        let remaining = validate_transfer(100, 30);
        assert_eq(remaining, 70);
    }

    #[test]
    fn test_full_balance_transfer() {
        let remaining = validate_transfer(100, 100);
        assert_eq(remaining, 0);
    }

    #[test(should_fail_with = "amount must be positive")]
    fn test_zero_amount_rejected() {
        let _ = validate_transfer(100, 0);
    }

    #[test(should_fail_with = "insufficient balance")]
    fn test_overdraft_rejected() {
        let _ = validate_transfer(50, 100);
    }
}
```

## Separate Test Files

For larger projects, put tests in dedicated files under a `tests` directory or alongside source modules.

```
src/
  main.nr
  utils.nr
  tests/
    mod.nr
    test_utils.nr
    test_main.nr
```

**`src/main.nr`:**

```rust
mod utils;
mod tests;

fn main(x: Field, y: pub Field) -> pub Field {
    utils::compute(x, y)
}
```

**`src/utils.nr`:**

```rust
pub fn compute(a: Field, b: Field) -> Field {
    let sum = a + b;
    assert(sum != 0, "result must be non-zero");
    sum
}

pub fn square(x: Field) -> Field {
    x * x
}
```

**`src/tests/mod.nr`:**

```rust
mod test_utils;
mod test_main;
```

**`src/tests/test_utils.nr`:**

```rust
use crate::utils;

#[test]
fn test_compute() {
    assert_eq(utils::compute(3, 4), 7);
}

#[test]
fn test_square() {
    assert_eq(utils::square(5), 25);
}

#[test(should_fail_with = "result must be non-zero")]
fn test_compute_rejects_zero_sum() {
    let _ = utils::compute(0, 0);
}
```

**`src/tests/test_main.nr`:**

```rust
use crate::main;

#[test]
fn test_main_basic() {
    assert_eq(main(2, 3), 5);
}
```

## Test Helper Functions

Extract common setup logic into helper functions. Mark helpers as `unconstrained` to avoid unnecessary constraint costs.

```rust
mod tests {
    use super::process_transfer;

    // Helper: build a test transfer struct without constraint overhead
    unconstrained fn make_test_transfer(
        sender_balance: u64,
        amount: u64,
    ) -> (u64, u64) {
        // Complex setup logic here
        (sender_balance, amount)
    }

    #[test]
    unconstrained fn test_large_transfer() {
        let (balance, amount) = make_test_transfer(1_000_000, 500_000);
        let result = process_transfer(balance, amount);
        assert_eq(result, 500_000);
    }

    #[test]
    unconstrained fn test_small_transfer() {
        let (balance, amount) = make_test_transfer(1_000_000, 1);
        let result = process_transfer(balance, amount);
        assert_eq(result, 999_999);
    }
}
```

## Running Subsets of Tests

```bash
# Run all tests
nargo test

# Run a single test by exact name
nargo test --exact test_valid_transfer

# Run all tests matching a prefix
nargo test test_transfer

# Run tests in a specific package (workspace)
nargo test --package my_circuit
```

## Best Practices

**Naming:** Use descriptive names that explain the scenario and expected outcome.

```rust
// Good -- describes the scenario and expectation
#[test]
fn test_transfer_with_zero_amount_fails() { ... }

#[test]
fn test_hash_is_deterministic_for_same_inputs() { ... }

// Avoid -- vague, says nothing about what's being tested
#[test]
fn test1() { ... }

#[test]
fn test_it() { ... }
```

**Test both paths:** Every `assert` in your circuit should have a corresponding success test and a `should_fail_with` test.

```rust
fn check_age(age: u8) {
    assert(age >= 18, "too young");
}

#[test]
fn test_valid_age_accepted() {
    check_age(18);
    check_age(65);
}

#[test(should_fail_with = "too young")]
fn test_underage_rejected() {
    check_age(17);
}
```

**Constrained for security:** Use constrained tests for logic that affects soundness -- range checks, nullifier computation, access control. The constraint system may behave differently than unconstrained execution.

**Unconstrained for speed:** Use unconstrained tests for pure helper logic, data formatting, and rapid iteration during development. Promote to constrained once the logic is stable.

**Keep helpers unconstrained:** Test setup functions that build data structures, compute expected values, or format inputs should be `unconstrained` to avoid inflating constraint counts in test runs.
