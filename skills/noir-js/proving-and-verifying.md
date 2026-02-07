# Proving and Verifying

After generating a witness, use `@noir-lang/backend_barretenberg` to create and verify proofs. This package wraps Aztec's Barretenberg proving system.

## Backend Setup

```typescript
import { BarretenbergBackend } from "@noir-lang/backend_barretenberg";
import circuit from "../target/my_circuit.json";

const backend = new BarretenbergBackend(circuit);
```

For UltraHonk (faster proving, larger proofs):

```typescript
import { UltraHonkBackend } from "@noir-lang/backend_barretenberg";

const backend = new UltraHonkBackend(circuit);
```

### Thread Configuration

Control the number of WASM threads for performance:

```typescript
const backend = new BarretenbergBackend(circuit, { threads: 4 });
```

More threads speeds up proving on multi-core systems. Defaults to 1.

## Generating a Proof

```typescript
import { Noir } from "@noir-lang/noir_js";

const noir = new Noir(circuit);
const { witness } = await noir.execute(inputs);

const proof = await backend.generateProof(witness);
```

The `proof` object contains:

- `proof` -- the raw proof bytes
- `publicInputs` -- values of public inputs declared in the circuit

## Verifying a Proof

```typescript
const isValid = await backend.verifyProof(proof);
console.log("Proof valid:", isValid); // true or false
```

Verification is fast compared to proving. It checks that the proof is valid for the given public inputs.

## Verification Key

Extract the verification key for use in on-chain verification or caching:

```typescript
const vk = await backend.getVerificationKey();
```

The verification key is deterministic for a given circuit -- it only changes when the circuit changes.

## Solidity Verifier

Generate a Solidity contract that can verify proofs on-chain:

```typescript
const solidityCode = await backend.getSolidityVerifier();

// Write to a .sol file
import { writeFileSync } from "fs";
writeFileSync("./contracts/Verifier.sol", solidityCode);
```

This produces a standalone Solidity contract with a `verify` function. Deploy it and call `verify(proof, publicInputs)` from your smart contracts.

## Full Pipeline Example

```typescript
import { Noir } from "@noir-lang/noir_js";
import { BarretenbergBackend } from "@noir-lang/backend_barretenberg";
import circuit from "../target/my_circuit.json";

async function proveAndVerify() {
  const backend = new BarretenbergBackend(circuit);
  const noir = new Noir(circuit);

  // Generate witness
  const inputs = { x: "3", y: "4" };
  const { witness } = await noir.execute(inputs);

  // Generate proof
  const proof = await backend.generateProof(witness);
  console.log("Public inputs:", proof.publicInputs);

  // Verify proof
  const isValid = await backend.verifyProof(proof);
  console.log("Proof valid:", isValid);

  // Clean up
  await backend.destroy();
}
```

## Proof Serialization

Proofs can be serialized for transmission or storage:

```typescript
// Serialize proof to bytes
const proofBytes = proof.proof;

// Reconstruct proof object for verification
const reconstructed = {
  proof: proofBytes,
  publicInputs: proof.publicInputs,
};
const isValid = await backend.verifyProof(reconstructed);
```

## Recursive Proof Composition

For recursive proofs (proving that you verified another proof), use intermediate proofs:

```typescript
// Inner circuit: generate a proof
const innerBackend = new BarretenbergBackend(innerCircuit);
const innerNoir = new Noir(innerCircuit);
const { witness: innerWitness } = await innerNoir.execute(innerInputs);
const innerProof = await innerBackend.generateProof(innerWitness);

// Get artifacts needed by the outer circuit
const numPublicInputs = innerCircuit.abi.parameters.filter(
  (p) => p.visibility === "public"
).length;

// Pass inner proof artifacts as inputs to the outer circuit
const outerInputs = {
  proof: innerProof.proof,
  public_inputs: innerProof.publicInputs,
  verification_key: await innerBackend.getVerificationKey(),
};

const outerBackend = new BarretenbergBackend(outerCircuit);
const outerNoir = new Noir(outerCircuit);
const { witness: outerWitness } = await outerNoir.execute(outerInputs);
const outerProof = await outerBackend.generateProof(outerWitness);
```

## Cleanup

Always destroy the backend when done to free WASM memory:

```typescript
await backend.destroy();
```

This is especially important in long-running applications or when creating multiple backend instances.
