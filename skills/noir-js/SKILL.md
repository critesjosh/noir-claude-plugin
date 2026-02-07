---
name: noir-js
description: "JavaScript/TypeScript integration with Noir circuits. Covers compilation, witness generation, proving, and verification using noir_js and bb.js."
allowed-tools: Read, Grep, Glob, Edit, Write, Bash
---

# Noir JavaScript/TypeScript Integration

Use `@noir-lang/noir_js` and `@noir-lang/backend_barretenberg` to compile, prove, and verify Noir circuits from JavaScript or TypeScript.

## Pipeline Overview

1. **Compile** circuit with `nargo compile` -- produces a JSON artifact in `target/`
2. **Load** the artifact in JavaScript
3. **Generate witness** with `noir_js` (`Noir` class)
4. **Create proof** with `bb.js` (`BarretenbergBackend` or `UltraHonkBackend`)
5. **Verify proof** on the client or on-chain

## Key Packages

| Package | Purpose |
|---------|---------|
| `@noir-lang/noir_js` | Witness generation, oracle callbacks |
| `@noir-lang/backend_barretenberg` | Proof generation and verification (wraps bb.js) |
| `@noir-lang/types` | TypeScript types for compiled artifacts |

All `@noir-lang/*` packages must match the version of `nargo` used to compile the circuit.

## Quick Start

```typescript
import { Noir } from "@noir-lang/noir_js";
import { BarretenbergBackend } from "@noir-lang/backend_barretenberg";
import circuit from "../target/my_circuit.json";

// 1. Set up backend and noir instance
const backend = new BarretenbergBackend(circuit);
const noir = new Noir(circuit);

// 2. Generate witness
const inputs = { x: "3", y: "4" };
const { witness } = await noir.execute(inputs);

// 3. Generate proof
const proof = await backend.generateProof(witness);

// 4. Verify proof
const isValid = await backend.verifyProof(proof);
console.log("Proof valid:", isValid);

// 5. Clean up WASM memory
await backend.destroy();
```

## Input Encoding Rules

All inputs are passed as strings or arrays/objects of strings:

| Noir Type | JS Encoding | Example |
|-----------|------------|---------|
| `Field` | Hex string or decimal string | `"0x1a"` or `"42"` |
| `u32`, `i8`, etc. | Same as Field | `"255"` |
| `bool` | `"0"` or `"1"` | `"1"` |
| `[Field; N]` | JS array of encoded values | `["1", "2", "3"]` |
| `struct` | JS object with matching field names | `{ x: "1", y: "2" }` |

## Oracle Callbacks

Oracles let the circuit call JavaScript functions during witness generation. Define callbacks matching `#[oracle(name)]` declarations in Noir:

```typescript
const oracleCallbacks = {
  async get_secret(key: string[]): Promise<string[]> {
    const secret = await fetchSecretFromDB(key[0]);
    return [secret];
  },
};

const { witness } = await noir.execute(inputs, oracleCallbacks);
```

Oracle callbacks receive and return **string arrays** where each string is a field element.

## Detailed Guides

- **[Compilation](./compilation.md)** -- Building circuits and producing JSON artifacts
- **[Witness Generation](./witness-generation.md)** -- Executing circuits, input encoding, oracles
- **[Proving and Verifying](./proving-and-verifying.md)** -- Proof creation, verification, Solidity verifiers
- **[Artifact Loading](./artifact-loading.md)** -- Loading artifacts in Node.js and browsers, version compatibility
