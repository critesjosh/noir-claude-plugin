# Data Types

Comprehensive guide to data types in Noir circuits.

## Field

The native type of the proof system -- a ~254-bit prime field element. Arithmetic on `Field` is the cheapest operation (1 constraint per multiplication/addition).

```rust
fn main(x: Field, y: Field) -> pub Field {
    let sum = x + y;
    let product = x * y;
    product
}
```

### Field Limitations

- No ordering: `<`, `>`, `<=`, `>=` are not available on `Field` directly
- Arithmetic wraps around the field prime (no overflow in the traditional sense)
- For ordering comparisons, cast to an integer type first

## Bool

Boolean values. Cost: 1 constraint for the range check (0 or 1).

```rust
fn main(flag: bool, x: Field) -> pub Field {
    if flag { x } else { 0 }
}
```

## Integer Types

Unsigned and signed integers with explicit bit widths. Each requires range-check constraints, making them more expensive than `Field`.

### Unsigned: u1, u8, u16, u32, u64

```rust
fn main(a: u64, b: u64) -> pub u64 {
    let sum = a + b;       // Overflow check is automatic
    assert(sum > a);
    sum
}
```

### Signed: i8, i16, i32, i64

```rust
fn main(a: i32, b: i32) -> pub i32 {
    a - b   // Can be negative
}
```

## Arrays

Fixed-size arrays. The size `N` must be known at compile time.

```rust
fn main(values: [Field; 5]) -> pub Field {
    let mut sum: Field = 0;
    for i in 0..5 {
        sum += values[i];
    }
    sum
}
```

### Nested Arrays

```rust
fn main(matrix: [[Field; 3]; 3]) -> pub Field {
    matrix[0][0] + matrix[1][1] + matrix[2][2]
}
```

## Slices

Dynamic-length sequences. **Only available in unconstrained functions.** Cannot be used in constrained code.

```rust
unconstrained fn process() {
    let mut s: [Field] = &[];
    s = s.push_back(1);
    s = s.push_back(2);
    assert(s.len() == 2);
}
```

## Strings

Fixed-length strings of type `str<N>`.

```rust
fn main(name: str<5>) {
    assert_eq(name, "hello");
}
```

Strings are arrays of bytes under the hood. The length `N` is the exact byte count.

## Tuples

Group heterogeneous values. Accessed by index.

```rust
fn main(x: Field) -> pub (Field, Field) {
    let pair = (x, x * x);
    let first = pair.0;
    let second = pair.1;
    (first, second)
}
```

## BoundedVec

Variable-length collection with a compile-time maximum capacity. Use when you need dynamic length in constrained code.

```rust
use std::collections::bounded_vec::BoundedVec;

fn main(pub count: u32) {
    let mut items: BoundedVec<Field, 10> = BoundedVec::new();
    items.push(1);
    items.push(2);
    items.push(3);

    assert(items.len() == 3);
    assert_eq(items.get(0), 1);
}
```

## Structs

Custom composite types. Use `#[derive]` to auto-implement common traits.

```rust
struct Point {
    x: Field,
    y: Field,
}

fn main(p: Point, pub target: Field) {
    let distance_sq = p.x * p.x + p.y * p.y;
    assert(distance_sq == target);
}
```

### Deriving Traits

```rust
#[derive(Eq, Default)]
struct Credential {
    id: Field,
    score: u64,
    active: bool,
}

fn main() {
    let default_cred = Credential::default();
    assert_eq(default_cred.score, 0);
}
```

## Type Aliases

Create shorter names for complex types.

```rust
type Hash = Field;
type Matrix = [[Field; 4]; 4];

fn transform(m: Matrix) -> Hash {
    // ...
    0
}
```

## Cost Comparison

| Type | Constraint Cost | Notes |
|------|----------------|-------|
| `Field` | Cheapest (native) | Use for most computation |
| `bool` | ~1 constraint | Range check for 0/1 |
| `u8` | ~8 constraints | 8-bit range check |
| `u16` | ~16 constraints | 16-bit range check |
| `u32` | ~32 constraints | 32-bit range check |
| `u64` | ~64 constraints | 64-bit range check |
| `i8`..`i64` | Same as unsigned + sign | Signed range checks |
| `[T; N]` | N * cost(T) | Fixed array |
| `BoundedVec<T, N>` | Up to N * cost(T) | Variable length, max N |
| `str<N>` | N bytes | Fixed-length string |
| Struct | Sum of field costs | Composite |
| Tuple | Sum of element costs | Composite |

### Optimization Guidance

- Prefer `Field` over integers when you do not need range checks or ordering
- Use `u8`/`u16` only when bit width matters (e.g., byte manipulation)
- Use `u64` for values that need comparison operators
- Avoid unnecessary casts between `Field` and integer types
