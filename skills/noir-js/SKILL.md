---
name: noir-js
description: "JavaScript/TypeScript integration with Noir circuits. Covers compilation, witness generation, proving, and verification using noir_js and bb.js."
allowed-tools: Read, Grep, Glob, Edit, Write, Bash
---

# Noir JavaScript/TypeScript Integration

Use `@noir-lang/noir_js` and `@aztec/bb.js` to compile, prove, and verify Noir circuits from JavaScript or TypeScript.

## Pipeline Overview

1. **Compile** circuit with `nargo compile` -- produces a JSON artifact in `target/`
2. **Load** the artifact in JavaScript
3. **Generate witness** with `noir_js` (`Noir` class)
4. **Create proof** with `bb.js` (`UltraHonkBackend`)
5. **Verify proof** on the client or on-chain

## Key Packages

| Package | Purpose |
|---------|---------|
| `@noir-lang/noir_js` | Witness generation, oracle callbacks, `CompiledCircuit` type |
| `@aztec/bb.js` | Proof generation and verification (`UltraHonkBackend`, `Barretenberg`) |

The `@noir-lang/noir_js` package version must match the version of `nargo` used to compile the circuit.

## Quick Start

```typescript
import { Noir } from "@noir-lang/noir_js";
import { Barretenberg, UltraHonkBackend } from "@aztec/bb.js";
import circuit from "../target/my_circuit.json" with { type: "json" };

// 1. Initialize backend
const api = await Barretenberg.new({ threads: 8 });
const noir = new Noir(circuit as any);
const backend = new UltraHonkBackend(circuit.bytecode, api);

// 2. Generate witness
const inputs = { x: 3, y: 4 };
const { witness } = await noir.execute(inputs);

// 3. Generate proof
const { proof, publicInputs } = await backend.generateProof(witness);

// 4. Verify proof
const isValid = await backend.verifyProof({ proof, publicInputs });
console.log("Proof valid:", isValid);
```

## Input Encoding Rules

All inputs are passed as values matching their Noir types:

| Noir Type | JS Encoding | Example |
|-----------|------------|---------|
| `Field` | Number or hex string | `3` or `"0x1a"` |
| `u32`, `i8`, etc. | Number or string | `255` |
| `bool` | Boolean or `"0"`/`"1"` | `true` |
| `[Field; N]` | JS array of encoded values | `[1, 2, 3]` |
| `struct` | JS object with matching field names | `{ x: 1, y: 2 }` |

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
