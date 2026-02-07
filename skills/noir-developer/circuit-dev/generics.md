# Generics

Noir supports generics for writing reusable, type-parameterized code.

## Generic Functions

```rust
fn identity<T>(x: T) -> T {
    x
}

fn first<A, B>(a: A, _b: B) -> A {
    a
}

fn main() {
    let x: Field = identity(42);
    let y: u64 = identity(100);
    let z = first(true, 42);
}
```

## Generic Structs

```rust
struct Pair<A, B> {
    first: A,
    second: B,
}

impl<A, B> Pair<A, B> {
    fn new(first: A, second: B) -> Self {
        Pair { first, second }
    }
}

fn main() {
    let p = Pair::new(1, true);
    assert_eq(p.first, 1);
}
```

## Numeric Generics

Use `let N: u32` (or other integer type) to parameterize over array sizes and constants.

```rust
fn sum_array<let N: u32>(arr: [Field; N]) -> Field {
    let mut total: Field = 0;
    for i in 0..N {
        total += arr[i];
    }
    total
}

fn main() {
    let a = [1, 2, 3];
    let b = [10, 20, 30, 40, 50];
    assert_eq(sum_array(a), 6);
    assert_eq(sum_array(b), 150);
}
```

### Multiple Numeric Generics

```rust
fn concat<let M: u32, let N: u32>(
    a: [Field; M],
    b: [Field; N],
) -> [Field; M + N] {
    let mut result = [0; M + N];
    for i in 0..M {
        result[i] = a[i];
    }
    for i in 0..N {
        result[M + i] = b[i];
    }
    result
}
```

## Turbofish Syntax

Explicitly specify type parameters when the compiler cannot infer them.

```rust
fn zero<T>() -> T where T: Default {
    T::default()
}

fn main() {
    // Turbofish needed because return type alone is ambiguous
    let f: Field = zero::<Field>();
    let b: bool = zero::<bool>();
}
```

## Where Clauses

Constrain generic types to those that implement specific traits.

```rust
fn are_equal<T>(a: T, b: T) -> bool where T: Eq {
    a == b
}

fn print_if_debug<T>(x: T) where T: std::fmt::Display {
    println(x);
}
```

### Multiple Constraints

```rust
fn process<T>(a: T, b: T) -> bool
where
    T: Eq,
    T: Default,
{
    let default_val = T::default();
    a == b
}
```

## Combining Type and Numeric Generics

```rust
fn fill<T, let N: u32>(value: T) -> [T; N] where T: Copy {
    [value; N]
}

fn contains<T, let N: u32>(arr: [Field; N], target: Field) -> bool {
    let mut found = false;
    for i in 0..N {
        if arr[i] == target {
            found = true;
        }
    }
    found
}
```
