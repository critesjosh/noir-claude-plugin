# Test Attributes

Noir provides test attributes that control how tests execute and what outcomes are expected.

## `#[test]` -- Basic Test

Runs as a constrained function, generating real constraints. This is the most thorough way to test circuit logic.

```rust
#[test]
fn test_hash_output() {
    let input = [1, 2, 3];
    let hash = std::hash::poseidon2::Poseidon2::hash(input, input.len());
    assert(hash != 0);
}
```

## `#[test(should_fail)]` -- Expected Failure

The test passes if **any** assertion fails or a runtime error occurs. Use this when you don't need to match a specific error message.

```rust
fn divide(a: Field, b: Field) -> Field {
    a / b
}

#[test(should_fail)]
fn test_cannot_divide_by_zero() {
    let _ = divide(10, 0);
}
```

## `#[test(should_fail_with = "message")]` -- Expected Failure with Message

The test passes only if it fails **and** the error message contains the specified string. This is more precise and prevents tests from passing for the wrong reason.

```rust
fn transfer(amount: u64, balance: u64) {
    assert(amount <= balance, "insufficient balance");
    assert(amount > 0, "amount must be positive");
}

#[test(should_fail_with = "insufficient balance")]
fn test_overdraft_fails() {
    transfer(100, 50);
}

#[test(should_fail_with = "amount must be positive")]
fn test_zero_transfer_fails() {
    transfer(0, 100);
}
```

## Unconstrained Tests

Add the `unconstrained` keyword after the test attribute to run without generating constraints. These tests execute faster but will not catch constraint-related bugs.

```rust
#[test]
unconstrained fn test_array_sorting() {
    let mut arr = [3, 1, 2];
    arr = arr.sort();
    assert_eq(arr, [1, 2, 3]);
}
```

## Constrained vs Unconstrained: When to Use Each

| Aspect | Constrained (`#[test]`) | Unconstrained (`#[test] unconstrained`) |
|--------|------------------------|----------------------------------------|
| Constraint generation | Yes | No |
| Speed | Slower | Faster |
| Catches constraint bugs | Yes | No |
| Use for | Security-critical logic, final validation | Fast iteration, helper logic, data manipulation |

**Rule of thumb:** Use constrained tests for any logic that directly affects the circuit's soundness. Use unconstrained tests for rapid development and testing helper functions.

```rust
// Constrained: verifies the circuit will actually enforce this check
#[test]
fn test_range_check_constrained() {
    let x: u8 = 255;
    assert(x <= 255);
}

// Unconstrained: faster, good for testing pure logic
#[test]
unconstrained fn test_string_formatting() {
    let name: str<5> = "hello";
    assert_eq(name.as_bytes()[0], 104); // 'h'
}
```

## Combining Attributes

The `should_fail` variants work with both constrained and unconstrained tests:

```rust
#[test(should_fail_with = "index out of bounds")]
unconstrained fn test_out_of_bounds_access() {
    let arr = [1, 2, 3];
    let _ = arr[5];
}
```
