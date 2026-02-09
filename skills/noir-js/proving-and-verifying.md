# Proving and Verifying

After generating a witness, use `@aztec/bb.js` to create and verify proofs. This package provides the `UltraHonkBackend` which wraps Aztec's Barretenberg proving system.

## Backend Setup

```typescript
import { Barretenberg, UltraHonkBackend } from "@aztec/bb.js";
import circuit from "../target/my_circuit.json" with { type: "json" };

const api = await Barretenberg.new({ threads: 8 });
const backend = new UltraHonkBackend(circuit.bytecode, api);
```

### Thread Configuration

Control the number of WASM threads for performance:

```typescript
const api = await Barretenberg.new({ threads: 4 });
```

More threads speeds up proving on multi-core systems.

## Generating a Proof

```typescript
import { Noir } from "@noir-lang/noir_js";

const noir = new Noir(circuit as any);
const { witness } = await noir.execute(inputs);

const { proof, publicInputs } = await backend.generateProof(witness);
```

The result contains:

- `proof` -- the raw proof bytes (`Uint8Array`)
- `publicInputs` -- values of public inputs declared in the circuit

## Verifying a Proof

```typescript
const isValid = await backend.verifyProof({ proof, publicInputs });
console.log("Proof valid:", isValid); // true or false
```

Verification is fast compared to proving. It checks that the proof is valid for the given public inputs.

## Verifier Targets

The `verifierTarget` option controls the hash function and zero-knowledge settings for proof generation and verification:

| `verifierTarget` | Hash | ZK | IPA | Use Case |
|---|---|---|---|---|
| *(omitted)* | poseidon2 | no | no | Default native verification |
| `"evm"` | keccak | yes | no | Solidity on-chain verification |
| `"evm-no-zk"` | keccak | no | no | EVM verification without zero-knowledge |
| `"noir-recursive"` | poseidon2 | yes | no | Recursive verification in Noir circuits |
| `"noir-recursive-no-zk"` | poseidon2 | no | no | Recursive verification without ZK |
| `"noir-rollup"` | poseidon2 | yes | yes | Rollup circuits with IPA accumulation |
| `"noir-rollup-no-zk"` | poseidon2 | no | yes | Rollup circuits without ZK |
| `"starknet"` | starknet | yes | no | Starknet verification via Garaga |
| `"starknet-no-zk"` | starknet | no | no | Starknet without zero-knowledge |

Pass the target to `generateProof` and `verifyProof`:

```typescript
// For EVM/Solidity verification
const { proof, publicInputs } = await backend.generateProof(witness, {
  verifierTarget: "evm",
});

const isValid = await backend.verifyProof({ proof, publicInputs }, {
  verifierTarget: "evm",
});
```

## Full Pipeline Example

```typescript
import { Noir } from "@noir-lang/noir_js";
import { Barretenberg, UltraHonkBackend } from "@aztec/bb.js";
import circuit from "../target/my_circuit.json" with { type: "json" };

async function proveAndVerify() {
  const api = await Barretenberg.new({ threads: 8 });
  const noir = new Noir(circuit as any);
  const backend = new UltraHonkBackend(circuit.bytecode, api);

  // Generate witness
  const inputs = { x: 3, y: 4 };
  const { witness } = await noir.execute(inputs);

  // Generate proof
  const { proof, publicInputs } = await backend.generateProof(witness);
  console.log("Public inputs:", publicInputs);

  // Verify proof
  const isValid = await backend.verifyProof({ proof, publicInputs });
  console.log("Proof valid:", isValid);
}
```

## Proof Serialization

Proofs can be serialized for transmission or storage:

```typescript
// Serialize proof to bytes
const proofBytes = proof;

// Reconstruct proof object for verification
const reconstructed = { proof: proofBytes, publicInputs };
const isValid = await backend.verifyProof(reconstructed);
```

## Recursive Proof Composition

For recursive proofs (proving that you verified another proof):

```typescript
import { Barretenberg, UltraHonkBackend } from "@aztec/bb.js";
import { Noir, CompiledCircuit } from "@noir-lang/noir_js";

const api = await Barretenberg.new({ threads: 8 });

// Inner circuit: generate a proof with recursive verification target
const innerNoir = new Noir(innerCircuit as CompiledCircuit);
const innerBackend = new UltraHonkBackend(innerCircuit.bytecode, api);
const { witness: innerWitness } = await innerNoir.execute(innerInputs);
const { proof: innerProof, publicInputs: innerPublicInputs } =
  await innerBackend.generateProof(innerWitness, {
    verifierTarget: "noir-recursive-no-zk",
  });

// Get recursive proof artifacts (VK fields, VK hash)
const artifacts = await innerBackend.generateRecursiveProofArtifacts(
  innerProof,
  innerPublicInputs.length,
  { verifierTarget: "noir-recursive-no-zk" }
);

// Convert proof bytes to field elements for the outer circuit
function proofToFields(proof: Uint8Array): string[] {
  const fields: string[] = [];
  for (let i = 0; i < proof.length; i += 32) {
    const chunk = proof.slice(i, i + 32);
    fields.push("0x" + Buffer.from(chunk).toString("hex"));
  }
  return fields;
}

// Pass inner proof artifacts as inputs to the outer circuit
const outerInputs = {
  verification_key: artifacts.vkAsFields,
  proof: proofToFields(innerProof),
  public_inputs: innerPublicInputs,
  key_hash: artifacts.vkHash,
};

const outerNoir = new Noir(outerCircuit as CompiledCircuit);
const outerBackend = new UltraHonkBackend(outerCircuit.bytecode, api);
const { witness: outerWitness } = await outerNoir.execute(outerInputs);
const outerProof = await outerBackend.generateProof(outerWitness);
```
