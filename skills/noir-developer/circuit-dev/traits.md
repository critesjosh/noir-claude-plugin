# Traits

Traits define shared behavior across types in Noir.

## Defining a Trait

```rust
trait Hashable {
    fn hash(self) -> Field;
}
```

## Implementing a Trait

```rust
struct Point {
    x: Field,
    y: Field,
}

impl Hashable for Point {
    fn hash(self) -> Field {
        self.x + self.y  // simplified; use a real hash in practice
    }
}
```

## Trait with Default Methods

```rust
trait Describable {
    fn name(self) -> str<10>;

    // Default implementation -- can be overridden
    fn is_valid(self) -> bool {
        true
    }
}
```

## Built-in Traits

### Default

Provides a zero/empty value for a type.

```rust
#[derive(Default)]
struct Config {
    threshold: u64,
    enabled: bool,
}

fn main() {
    let c = Config::default();
    assert_eq(c.threshold, 0);
    assert_eq(c.enabled, false);
}
```

### Eq

Equality comparison (`==` and `!=`).

```rust
#[derive(Eq)]
struct Token {
    id: Field,
    amount: u64,
}

fn main() {
    let a = Token { id: 1, amount: 100 };
    let b = Token { id: 1, amount: 100 };
    assert(a == b);
}
```

### Ord

Ordering comparison (`<`, `>`, `<=`, `>=`). Available for integer types and types that implement it.

```rust
fn main() {
    let a: u64 = 10;
    let b: u64 = 20;
    assert(a < b);
}
```

### Hash

Allows a type to be hashed. Required for use as a `HashMap` key.

```rust
use std::hash::Hash;

#[derive(Hash, Eq)]
struct Key {
    a: Field,
    b: Field,
}
```

### Serialize and Deserialize

**Note:** The `Serialize` and `Deserialize` traits are available as comptime concepts in `std::meta` for metaprogramming. They are not general-purpose derive macros in the current stdlib. If you need to convert structs to/from `[Field; N]` arrays, implement the conversion manually or use a library that provides this functionality.

## Trait Constraints in Generics

```rust
fn hash_pair<T>(a: T, b: T) -> Field where T: Hashable {
    a.hash() + b.hash()
}
```

### Multiple Trait Bounds

```rust
fn compare_and_hash<T>(a: T, b: T) -> Field
where
    T: Eq,
    T: Hashable,
{
    assert(a == b);
    a.hash()
}
```

## The `#[derive]` Attribute

Automatically generate trait implementations for structs.

```rust
#[derive(Eq, Default, Hash)]
struct Credential {
    id: Field,
    level: u32,
}
```

### Derivable Traits

| Trait | What it generates |
|-------|-------------------|
| `Eq` | Field-by-field equality |
| `Default` | All fields set to their default (0, false, etc.) |
| `Hash` | Hash all fields |

## Implementing Traits for External Types

You can implement your own traits for any type, but you cannot implement external traits for external types (the orphan rule).

```rust
// This works: your trait, external type
trait Summable {
    fn sum(self) -> Field;
}

impl Summable for [Field; 3] {
    fn sum(self) -> Field {
        self[0] + self[1] + self[2]
    }
}
```
