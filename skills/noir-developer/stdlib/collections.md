# Collections

## BoundedVec

A variable-length collection with a compile-time maximum capacity. This is the primary way to handle dynamic-length data in constrained Noir code.

`BoundedVec` is available in the prelude -- no import needed.

### Creating

```rust
// Empty with max capacity of 10
let mut v: BoundedVec<Field, 10> = BoundedVec::new();

// From an array (all elements become active)
let v = BoundedVec::from_array([1, 2, 3]);
```

### Core Methods

```rust
let mut v: BoundedVec<Field, 10> = BoundedVec::new();

// push: append an element (panics if full)
v.push(42);
v.push(99);

// pop: remove and return the last element (panics if empty)
let last = v.pop();  // 99

// get: read element at index (panics if out of bounds)
let first = v.get(0);  // 42

// set: write element at index (panics if out of bounds)
v.set(0, 100);

// len: current number of elements
let count = v.len();  // 1

// storage_len: maximum capacity (the N in BoundedVec<T, N>)
let capacity = v.storage_len();  // 10
```

### Iteration and Transformation

```rust
let v = BoundedVec::from_array([1, 2, 3, 4, 5]);

// any: check if any element satisfies a predicate
let has_even = v.any(|x: Field| x == 2);

// map: transform each element
let doubled: BoundedVec<Field, 5> = v.map(|x: Field| x * 2);
```

### In Function Parameters

```rust
fn sum_values(values: BoundedVec<Field, 100>) -> Field {
    let mut total: Field = 0;
    for i in 0..values.len() {
        total += values.get(i);
    }
    total
}
```

### Extending

```rust
let mut a: BoundedVec<Field, 10> = BoundedVec::new();
a.push(1);
a.push(2);

let b = BoundedVec::from_array([3, 4, 5]);
a.extend_from_bounded_vec(b);
// a is now [1, 2, 3, 4, 5]
```

## HashMap

A hash map with a fixed maximum capacity. Requires a hasher type.

```rust
use std::collections::map::HashMap;
use std::hash::BuildHasherDefault;
use poseidon::poseidon2::Poseidon2Hasher;
```

**Note:** `Poseidon2Hasher` comes from the external `poseidon` library, not from `std`. Add to `Nargo.toml`:

```toml
[dependencies]
poseidon = { tag = "v0.1.1", git = "https://github.com/noir-lang/poseidon" }
```

### Creating

```rust
// HashMap<KeyType, ValueType, MaxLen, Hasher>
let mut map: HashMap<Field, Field, 64, BuildHasherDefault<Poseidon2Hasher>> =
    HashMap::default();
```

### Core Methods

```rust
let mut map: HashMap<Field, Field, 64, BuildHasherDefault<Poseidon2Hasher>> = HashMap::default();

// insert
map.insert(1, 100);
map.insert(2, 200);

// get: returns Option<V>
let val = map.get(1);  // Some(100)

// contains_key
let exists = map.contains_key(2);  // true

// remove
map.remove(1);

// is_empty / len
let empty = map.is_empty();  // false
let count = map.len();  // 1
```

### Iteration

```rust
// entries: returns a BoundedVec of (key, value) pairs
let entries = map.entries();
for i in 0..entries.len() {
    let (key, value) = entries.get(i);
    // process each entry
}

// keys / values
let all_keys = map.keys();
let all_values = map.values();
```

### Key Requirements

Keys must implement `Eq` and `Hash`:

```rust
use std::hash::Hash;

#[derive(Eq, Hash)]
struct MyKey {
    id: Field,
    version: u32,
}
```

## When to Use Each

| Collection | Use Case |
|-----------|----------|
| `[T; N]` (array) | Fixed number of elements, all always used |
| `BoundedVec<T, N>` | Variable number of elements, known maximum |
| `HashMap<K, V, N, H>` | Key-value lookups, membership checks |

### Constraint Costs

- **Array**: Zero overhead beyond element costs
- **BoundedVec**: Small overhead for length tracking; iterating always costs MaxLen iterations
- **HashMap**: Significant overhead from hashing and collision handling; use only when key-value semantics are needed
