# Field Operations

Operations on Noir's native `Field` type.

## Byte Conversions

### Field to Bytes

Convert a field element to a fixed-size byte array.

```rust
fn main(x: Field) {
    // Big-endian: most significant byte first
    let be_bytes: [u8; 32] = x.to_be_bytes();

    // Little-endian: least significant byte first
    let le_bytes: [u8; 32] = x.to_le_bytes();

    // Specify a smaller size (truncates high bytes)
    let small: [u8; 8] = x.to_be_bytes();
}
```

### Bytes to Field

Convert a byte array back to a field element.

```rust
fn main(bytes: [u8; 32]) -> pub Field {
    // From big-endian bytes
    let value = Field::from_be_bytes(bytes);
    value
}

fn from_le(bytes: [u8; 32]) -> Field {
    Field::from_le_bytes(bytes)
}
```

## Radix Decomposition

Decompose a field element into digits in a given radix (base).

```rust
fn main(x: Field) {
    // Big-endian binary decomposition (base 2)
    let bits_be: [u8; 254] = x.to_be_radix(2);

    // Little-endian binary decomposition
    let bits_le: [u8; 254] = x.to_le_radix(2);

    // Hexadecimal decomposition (base 16)
    let hex_digits: [u8; 64] = x.to_be_radix(16);

    // Decimal decomposition (base 10)
    let decimal_digits: [u8; 77] = x.to_le_radix(10);
}
```

The output array size must be large enough to hold all digits. Each element is in range `[0, radix)`.

## Bit-Size Assertions

Constrain a field element to fit within a specific number of bits.

```rust
fn main(x: Field) {
    // Assert x fits in 64 bits (i.e., x < 2^64)
    x.assert_max_bit_size::<64>();

    // Assert x fits in 8 bits (i.e., x < 256)
    x.assert_max_bit_size::<8>();
}
```

This is useful for safe casting or range-limiting field values without converting to an integer type.

## Modular Arithmetic Notes

`Field` arithmetic wraps around the field prime `p`. Important implications:

```rust
fn main() {
    // Addition and multiplication wrap modulo p
    let a: Field = 0 - 1;  // This is p - 1, not -1 in the integer sense

    // Division is modular inverse, not integer division
    let b: Field = 1 / 2;  // This is the modular inverse of 2, not 0

    // There is no "overflow" -- all operations are valid in the field
    let c: Field = a + 1;  // This wraps back to 0
}
```

### Converting Between Field and Integers

```rust
fn main(x: Field) {
    // Field -> integer: use `as` (truncates if value is too large)
    let n = x as u64;

    // Integer -> Field: use `as`
    let y: u64 = 42;
    let f = y as Field;
}
```

### Checking Field Value Range

```rust
fn main(x: Field) {
    // Ensure x is small enough to safely cast
    x.assert_max_bit_size::<64>();
    let safe_value = x as u64;
}
```

## Common Patterns

### Packing Multiple Values into a Field

```rust
fn pack_two_u32(a: u32, b: u32) -> Field {
    (a as Field) * 0x100000000 + (b as Field)
}

fn unpack_two_u32(packed: Field) -> (u32, u32) {
    let bytes: [u8; 8] = packed.to_be_bytes();
    let a = (bytes[0] as u32) * 0x1000000
        + (bytes[1] as u32) * 0x10000
        + (bytes[2] as u32) * 0x100
        + (bytes[3] as u32);
    let b = (bytes[4] as u32) * 0x1000000
        + (bytes[5] as u32) * 0x10000
        + (bytes[6] as u32) * 0x100
        + (bytes[7] as u32);
    (a, b)
}
```

### Extracting Individual Bits

```rust
fn get_bit(x: Field, bit_index: u32) -> u1 {
    let bits: [u8; 254] = x.to_le_radix(2);
    bits[bit_index] as u1
}
```
