# Assertion Patterns

Noir provides assertion primitives for verifying circuit behavior in tests and in production circuits.

## Core Assertions

### `assert(condition)`

Fails if the condition is false. In constrained code, this generates a constraint.

```rust
#[test]
fn test_basic_assert() {
    let x: Field = 42;
    assert(x != 0);
    assert(x == 42);
}
```

### `assert(condition, "message")`

Same as above, but with a custom error message. The message appears in test output on failure and can be matched with `should_fail_with`.

```rust
fn withdraw(amount: u64, balance: u64) -> u64 {
    assert(amount <= balance, "insufficient funds");
    assert(amount > 0, "withdrawal must be positive");
    balance - amount
}

#[test]
fn test_valid_withdrawal() {
    let remaining = withdraw(30, 100);
    assert_eq(remaining, 70, "remaining balance incorrect");
}
```

### `assert_eq(a, b)`

Asserts that two values are equal. Provides clearer failure output than `assert(a == b)`.

```rust
#[test]
fn test_equality() {
    let result = 2 + 3;
    assert_eq(result, 5);
}
```

### `assert_eq(a, b, "message")`

Equality assertion with a custom error message.

```rust
#[test]
fn test_equality_with_message() {
    let expected: Field = 100;
    let actual = compute_something();
    assert_eq(actual, expected, "computation returned wrong result");
}
```

## Testing Failure Cases

Use `#[test(should_fail_with = "...")]` to verify that your circuit rejects invalid inputs:

```rust
fn validate_age(age: u8) {
    assert(age >= 18, "must be at least 18");
    assert(age <= 150, "age unrealistic");
}

#[test(should_fail_with = "must be at least 18")]
fn test_underage_rejected() {
    validate_age(12);
}

#[test(should_fail_with = "age unrealistic")]
fn test_unrealistic_age_rejected() {
    validate_age(200);
}
```

## Common Patterns

### Boundary Testing

Test minimum and maximum values for integer types:

```rust
fn clamp_to_u8(value: u64) -> u8 {
    assert(value <= 255, "value exceeds u8 range");
    value as u8
}

#[test]
fn test_clamp_min() {
    assert_eq(clamp_to_u8(0), 0);
}

#[test]
fn test_clamp_max() {
    assert_eq(clamp_to_u8(255), 255);
}

#[test(should_fail_with = "value exceeds u8 range")]
fn test_clamp_overflow() {
    let _ = clamp_to_u8(256);
}
```

### Array and BoundedVec Verification

```rust
#[test]
fn test_array_contents() {
    let arr = [10, 20, 30];
    assert_eq(arr[0], 10);
    assert_eq(arr[1], 20);
    assert_eq(arr[2], 30);
    assert_eq(arr.len(), 3);
}

#[test]
fn test_bounded_vec() {
    let mut vec: BoundedVec<Field, 5> = BoundedVec::new();
    vec.push(42);
    vec.push(99);
    assert_eq(vec.len(), 2);
    assert_eq(vec.get(0), 42);
    assert_eq(vec.get(1), 99);
}
```

### Struct Field Verification

```rust
struct Point {
    x: Field,
    y: Field,
}

fn make_point(x: Field, y: Field) -> Point {
    Point { x, y }
}

#[test]
fn test_struct_fields() {
    let p = make_point(3, 4);
    assert_eq(p.x, 3);
    assert_eq(p.y, 4);
}
```

### Hash Output Verification

Compute an expected hash and compare against the function output:

```rust
// Requires poseidon dependency in Nargo.toml
use poseidon::poseidon2::Poseidon2;

fn commit(secret: Field, nonce: Field) -> Field {
    Poseidon2::hash([secret, nonce], 2)
}

#[test]
fn test_commitment_deterministic() {
    let hash1 = commit(42, 1);
    let hash2 = commit(42, 1);
    assert_eq(hash1, hash2, "same inputs must produce same hash");
}

#[test]
fn test_commitment_differs_with_nonce() {
    let hash1 = commit(42, 1);
    let hash2 = commit(42, 2);
    assert(hash1 != hash2, "different nonces must produce different hashes");
}
```

## Debugging with `println`

Use `println` to inspect values during test execution. Output only appears when running with `--show-output`.

```bash
nargo test --show-output
```

`println` works in both constrained and unconstrained code (it wraps in `unsafe` internally):

```rust
#[test]
unconstrained fn test_debug_output() {
    let x: Field = 42;
    let y: Field = 58;
    let sum = x + y;
    println(f"x = {x}, y = {y}, sum = {sum}");
    assert_eq(sum, 100);
}
```

You can print arrays and structs that implement the standard display formatting:

```rust
#[test]
unconstrained fn test_print_array() {
    let arr = [1, 2, 3, 4, 5];
    println(f"array: {arr}");
    assert_eq(arr.len(), 5);
}
```
