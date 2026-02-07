# Oracles

Oracles are Noir's foreign function interface. They allow circuits to call out to JavaScript during witness generation.

## How Oracles Work

1. Noir declares an oracle function with an empty body
2. During witness generation, the JavaScript runtime provides the implementation
3. The oracle runs outside the circuit -- it produces no constraints
4. Results must be verified with constraints if they affect soundness

## Declaring an Oracle

```rust
// The #[oracle] attribute marks a foreign function
// The body MUST be empty -- implementation is in JavaScript
#[oracle(get_secret_value)]
unconstrained fn oracle_get_secret_value(key: Field) -> Field {}
```

### Rules

- Oracles **must** be `unconstrained`
- The body **must** be empty `{}`
- The string in `#[oracle(name)]` is the name JavaScript uses to register the callback

## Wrapper Function Pattern

Always wrap oracles in an unconstrained function to provide a clean interface:

```rust
#[oracle(get_secret_value)]
unconstrained fn oracle_get_secret_value(key: Field) -> Field {}

// Clean wrapper
unconstrained fn get_secret_value(key: Field) -> Field {
    oracle_get_secret_value(key)
}
```

## Using Oracles in Constrained Code

Since oracles are unconstrained, you must use `unsafe {}` to call them from constrained code. Always verify the result.

```rust
#[oracle(get_square_root)]
unconstrained fn oracle_get_square_root(x: Field) -> Field {}

unconstrained fn hint_sqrt(x: Field) -> Field {
    oracle_get_square_root(x)
}

fn verified_sqrt(x: Field) -> Field {
    // Get the hint from the oracle
    let root = unsafe { hint_sqrt(x) };
    // Constrain the result -- this is what the proof actually checks
    assert(root * root == x, "invalid square root");
    root
}

fn main(x: Field) -> pub Field {
    verified_sqrt(x)
}
```

## JavaScript Implementation

Register oracle callbacks in your JavaScript/TypeScript code:

```typescript
import { Noir } from "@noir-lang/noir_js";
import { UltraPlonkBackend } from "@aztec/bb.js";
import circuit from "./target/my_circuit.json";

const backend = new UltraPlonkBackend(circuit.bytecode);
const noir = new Noir(circuit);

// Register the oracle callback
const oracleCallbacks = {
  get_square_root: async (inputs: string[]) => {
    // inputs[0] is the Field value as a string
    const x = BigInt(inputs[0]);
    // Compute square root (off-chain, no constraints)
    const root = sqrt(x);
    return root.toString();
  },
};

// Generate witness with oracle support
const { witness } = await noir.execute(inputMap, oracleCallbacks);
const proof = await backend.generateProof(witness);
```

## Oracle with Multiple Parameters

```rust
#[oracle(fetch_data)]
unconstrained fn oracle_fetch_data(id: Field, index: u32) -> [Field; 4] {}

unconstrained fn fetch_data(id: Field, index: u32) -> [Field; 4] {
    oracle_fetch_data(id, index)
}
```

## Common Use Cases

| Use Case | Description |
|----------|-------------|
| External data | Fetch values from APIs or databases |
| Random values | Get randomness from a secure source |
| Complex math | Compute hints for expensive operations |
| Merkle proofs | Fetch sibling nodes for path verification |
| Signatures | Retrieve signature data for verification |

## Important Constraints

- Oracles only run during **witness generation** (proving), not during verification
- Oracle return values are untrusted -- always add assertions to constrain results
- Oracles cannot be called during `nargo test` unless you use a custom test runner
- Oracle names must match exactly between Noir and JavaScript
