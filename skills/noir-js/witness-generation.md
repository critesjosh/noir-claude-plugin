# Witness Generation

Witness generation executes the Noir circuit with concrete inputs, producing a witness that the backend uses to create a proof. The `Noir` class from `@noir-lang/noir_js` handles this step.

## Basic Usage

```typescript
import { Noir } from "@noir-lang/noir_js";
import circuit from "../target/my_circuit.json";

const noir = new Noir(circuit);
const inputs = { x: "3", y: "4" };
const { witness } = await noir.execute(inputs);
```

The `witness` is an opaque object passed directly to the backend for proving.

## Input Encoding

All values are encoded as strings. The input object must match the circuit's `main` function parameters by name.

### Primitive Types

```noir
// Circuit: fn main(x: Field, y: u32, flag: bool)
```

```typescript
const inputs = {
  x: "42",        // Field: decimal string
  y: "255",       // Integer: decimal string
  flag: "1",      // bool: "0" or "1"
};
```

Hex strings work for Field and integer types:

```typescript
const inputs = {
  x: "0x2a",      // Field: hex string (= 42)
  y: "0xff",      // Integer: hex string (= 255)
  flag: "1",
};
```

### Arrays

```noir
// Circuit: fn main(values: [Field; 3])
```

```typescript
const inputs = {
  values: ["10", "20", "30"],
};
```

### Structs

```noir
// Circuit:
// struct Point { x: Field, y: Field }
// fn main(p: Point)
```

```typescript
const inputs = {
  p: { x: "1", y: "2" },
};
```

### Nested Types

```noir
// Circuit:
// struct Tx { sender: Field, amounts: [Field; 2] }
// fn main(transactions: [Tx; 2])
```

```typescript
const inputs = {
  transactions: [
    { sender: "0xabc", amounts: ["100", "200"] },
    { sender: "0xdef", amounts: ["300", "400"] },
  ],
};
```

## Oracle Callbacks

Oracles let a Noir circuit call out to JavaScript during witness generation. They are declared in Noir with `#[oracle(name)]` and implemented as async JS functions.

### Noir Side

```noir
#[oracle(get_price)]
unconstrained fn get_price_oracle(asset_id: Field) -> Field {}

unconstrained fn get_price(asset_id: Field) -> Field {
    get_price_oracle(asset_id)
}

fn main(asset_id: Field, expected_price: Field) {
    let price = unsafe { get_price(asset_id) };
    assert(price == expected_price);
}
```

### JavaScript Side

```typescript
const oracleCallbacks = {
  async get_price(args: string[]): Promise<string[]> {
    // args[0] is the asset_id as a string
    const price = await fetchPriceFromAPI(args[0]);
    return [price.toString()];
  },
};

const { witness } = await noir.execute(inputs, oracleCallbacks);
```

Key rules for oracle callbacks:

- The callback name must match the oracle name in Noir (e.g., `get_price`)
- Parameters arrive as a **flat array of strings** (field elements)
- Return value must be a **string array**
- Callbacks can be `async`
- Multiple oracles can be defined in the same callbacks object

### Multiple Return Values

If the oracle returns multiple fields:

```noir
#[oracle(get_pair)]
unconstrained fn get_pair_oracle() -> (Field, Field) {}
```

```typescript
const oracleCallbacks = {
  async get_pair(): Promise<string[]> {
    return ["42", "99"]; // Two field elements
  },
};
```

## Error Handling

Witness generation fails if any assertion in the circuit fails:

```typescript
try {
  const { witness } = await noir.execute(inputs);
} catch (error) {
  // error.message contains the failing assertion info
  console.error("Circuit assertion failed:", error.message);
}
```

Common failure causes:

- Assertion failure (`assert` or `assert_eq` in the circuit)
- Input type mismatch (e.g., passing a value larger than `u8` max)
- Missing or extra input fields
- Oracle callback throwing an error

## Return Values

If the circuit has a return value, `execute` provides it:

```typescript
const { witness, returnValue } = await noir.execute(inputs);
console.log("Circuit returned:", returnValue);
```

The return value is decoded according to the circuit's ABI.
