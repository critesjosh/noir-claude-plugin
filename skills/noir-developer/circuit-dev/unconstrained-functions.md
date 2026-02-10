# Unconstrained Functions

Unconstrained functions execute outside the circuit. They generate no constraints and have no proving cost.

## Basic Syntax

```rust
unconstrained fn compute_hint(x: Field) -> Field {
    // This code runs during witness generation only
    // No constraints are produced
    let bytes = x.to_be_bytes::<32>();
    let mut sum: Field = 0;
    for i in 0..32 {
        sum += bytes[i] as Field;
    }
    sum
}
```

## Calling from Constrained Code

Use `unsafe {}` blocks to call unconstrained functions from constrained code:

```rust
unconstrained fn hint_inverse(x: Field) -> Field {
    1 / x
}

fn main(x: Field) -> pub Field {
    // Safety: x * inv == 1 is checked below, so a dishonest prover cannot
    // substitute an arbitrary value for the inverse
    let inv = unsafe { hint_inverse(x) };
    assert(x * inv == 1, "not a valid inverse");
    inv
}
```

## The Hint Pattern

The most important pattern for unconstrained functions: **compute unconstrained, verify constrained**.

```rust
unconstrained fn hint_sort(arr: [u64; 5]) -> [u64; 5] {
    // Expensive sorting done without constraints
    let mut sorted = arr;
    for i in 0..5 {
        for j in 0..(4 - i) {
            if sorted[j] > sorted[j + 1] {
                let tmp = sorted[j];
                sorted[j] = sorted[j + 1];
                sorted[j + 1] = tmp;
            }
        }
    }
    sorted
}

fn main(arr: [u64; 5]) -> pub [u64; 5] {
    // Safety: sorted order and element-sum equality are verified below,
    // so a dishonest prover cannot reorder or substitute values
    let sorted = unsafe { hint_sort(arr) };

    // Verify the result is sorted (cheap: N-1 comparisons)
    for i in 0..4 {
        assert(sorted[i] <= sorted[i + 1], "not sorted");
    }

    // Verify it is a permutation of the original (same elements)
    // (simplified -- a real check would verify multiset equality)
    let mut sum_orig: u64 = 0;
    let mut sum_sorted: u64 = 0;
    for i in 0..5 {
        sum_orig += arr[i];
        sum_sorted += sorted[i];
    }
    assert_eq(sum_orig, sum_sorted, "elements changed");

    sorted
}
```

### Why This Matters

- Sorting in-circuit: O(N^2) constraints
- Sorting unconstrained + verifying sorted: O(N) constraints
- Same security guarantee, far fewer constraints

## Use Cases

### Debugging with println

`println` works in both constrained and unconstrained code (it wraps in `unsafe` internally). Format strings (`f"..."`) also work in both contexts:

```rust
fn main(x: Field) {
    // println works directly in constrained code
    println(f"input x: {x}");
    assert(x != 0);
}
```

### Complex Computation Hints

```rust
unconstrained fn hint_division(a: u64, b: u64) -> (u64, u64) {
    (a / b, a % b)
}

fn checked_division(a: u64, b: u64) -> (u64, u64) {
    // Safety: a == b * quotient + remainder and remainder < b are checked below,
    // which uniquely determines the correct quotient and remainder
    let (quotient, remainder) = unsafe { hint_division(a, b) };
    // Verify: a == b * quotient + remainder
    assert(a == b * quotient + remainder, "bad division");
    assert(remainder < b, "remainder too large");
    (quotient, remainder)
}
```

### Oracle Wrappers

Unconstrained functions are the required wrapper layer for oracles:

```rust
#[oracle(fetch_merkle_path)]
unconstrained fn oracle_fetch_path(leaf_index: u32) -> [Field; 32] {}

unconstrained fn get_merkle_path(leaf_index: u32) -> [Field; 32] {
    oracle_fetch_path(leaf_index)
}
```

## Capabilities in Unconstrained Code

Unconstrained functions have access to operations not available in constrained code:

| Feature | Constrained | Unconstrained |
|---------|------------|---------------|
| Slices (dynamic arrays) | No | Yes |
| `println` | Yes (wraps unsafe internally) | Yes |
| `f""` format strings | Yes | Yes |
| Unbounded loops | No | Yes |
| Integer division hints | Expensive | Free |
| Oracle calls | No (use `unsafe`) | Yes |
| Recursive calls | Limited | Yes |

## Safety Rules

1. **Never trust unconstrained output** -- always add assertions in constrained code
2. An unconstrained function returning `true` proves nothing; the prover can make it return anything
3. The `unsafe` keyword is a reminder: you must verify the result
4. Unconstrained code can use runtime-determined loop bounds; constrained code cannot
