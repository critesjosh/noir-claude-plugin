# Web Worker Proving

All Noir proving must happen in a Web Worker to avoid freezing the browser. This guide covers worker setup, communication, and advanced patterns.

## Basic Worker File

```typescript
// proof-worker.ts
import { Noir } from "@noir-lang/noir_js";
import { UltraHonkBackend } from "@noir-lang/backend_barretenberg";

self.onmessage = async (e: MessageEvent) => {
  const { type, circuit, inputs } = e.data;

  if (type === "prove") {
    try {
      const noir = new Noir(circuit);
      const backend = new UltraHonkBackend(circuit.bytecode);

      // Step 1: Generate witness
      self.postMessage({ type: "status", phase: "witness" });
      const { witness } = await noir.execute(inputs);

      // Step 2: Generate proof
      self.postMessage({ type: "status", phase: "proving" });
      const proof = await backend.generateProof(witness);

      // Step 3: Return result
      self.postMessage({
        type: "proof-generated",
        proof: proof.proof,
        publicInputs: proof.publicInputs,
      });

      // Clean up WASM memory
      await backend.destroy();
    } catch (err) {
      self.postMessage({
        type: "error",
        error: err instanceof Error ? err.message : String(err),
      });
    }
  }

  if (type === "verify") {
    try {
      const backend = new UltraHonkBackend(circuit.bytecode);
      const isValid = await backend.verifyProof({
        proof: e.data.proof,
        publicInputs: e.data.publicInputs,
      });
      self.postMessage({ type: "verification-result", isValid });
      await backend.destroy();
    } catch (err) {
      self.postMessage({
        type: "error",
        error: err instanceof Error ? err.message : String(err),
      });
    }
  }
};
```

## Main Thread Communication

### Creating the Worker

Use the `new URL()` pattern so bundlers (Vite, Webpack) can resolve the worker file:

```typescript
const worker = new Worker(
  new URL("./proof-worker.ts", import.meta.url)
);
```

### Sending Messages

```typescript
// Request a proof
worker.postMessage({
  type: "prove",
  circuit,
  inputs: { x: "3", y: "4" },
});

// Request verification
worker.postMessage({
  type: "verify",
  circuit,
  proof: proofBytes,
  publicInputs: ["42"],
});
```

### Receiving Messages

```typescript
worker.onmessage = (e: MessageEvent) => {
  switch (e.data.type) {
    case "status":
      console.log(`Phase: ${e.data.phase}`);
      break;
    case "proof-generated":
      console.log("Proof:", e.data.proof);
      console.log("Public inputs:", e.data.publicInputs);
      break;
    case "verification-result":
      console.log("Valid:", e.data.isValid);
      break;
    case "error":
      console.error("Worker error:", e.data.error);
      break;
  }
};
```

### Error Handling

The `onerror` handler catches errors that are not caught inside the worker (e.g., import failures, syntax errors):

```typescript
worker.onerror = (event) => {
  console.error("Worker error:", event.message);
  // The worker may be dead after this -- recreate if needed
};
```

## Worker Lifecycle

### Create Once, Reuse

WASM initialization inside the worker takes time. Create the worker once and reuse it for multiple proofs:

```typescript
// Initialize once
const worker = new Worker(new URL("./proof-worker.ts", import.meta.url));

// Prove multiple times
worker.postMessage({ type: "prove", circuit, inputs: firstInputs });
// ... wait for result ...
worker.postMessage({ type: "prove", circuit, inputs: secondInputs });
```

### Terminate on Cleanup

Always terminate the worker when you are done. This frees the background thread and WASM memory:

```typescript
worker.terminate();
```

In React, do this in the `useEffect` cleanup:

```typescript
useEffect(() => {
  const worker = new Worker(new URL("./proof-worker.ts", import.meta.url));
  workerRef.current = worker;
  return () => worker.terminate();
}, []);
```

## Comlink Alternative

[Comlink](https://github.com/GoogleChromeLabs/comlink) wraps `postMessage` in a cleaner async function call API:

### Worker File with Comlink

```typescript
// proof-worker.ts
import * as Comlink from "comlink";
import { Noir } from "@noir-lang/noir_js";
import { UltraHonkBackend } from "@noir-lang/backend_barretenberg";

const prover = {
  async generateProof(
    circuit: any,
    inputs: Record<string, string | string[]>
  ) {
    const noir = new Noir(circuit);
    const backend = new UltraHonkBackend(circuit.bytecode);
    const { witness } = await noir.execute(inputs);
    const proof = await backend.generateProof(witness);
    await backend.destroy();
    return { proof: proof.proof, publicInputs: proof.publicInputs };
  },

  async verifyProof(circuit: any, proof: Uint8Array, publicInputs: string[]) {
    const backend = new UltraHonkBackend(circuit.bytecode);
    const isValid = await backend.verifyProof({ proof, publicInputs });
    await backend.destroy();
    return isValid;
  },
};

Comlink.expose(prover);
```

### Main Thread with Comlink

```typescript
import * as Comlink from "comlink";

const worker = new Worker(new URL("./proof-worker.ts", import.meta.url));
const prover = Comlink.wrap<{
  generateProof(circuit: any, inputs: Record<string, string | string[]>): Promise<{
    proof: Uint8Array;
    publicInputs: string[];
  }>;
  verifyProof(circuit: any, proof: Uint8Array, publicInputs: string[]): Promise<boolean>;
}>(worker);

// Clean async calls instead of postMessage
const result = await prover.generateProof(circuit, { x: "3", y: "4" });
const isValid = await prover.verifyProof(circuit, result.proof, result.publicInputs);
```

Comlink simplifies the code significantly but adds a dependency. Choose based on your project's complexity.

## Transferable Objects

When passing proof bytes back from the worker, use transferable objects for zero-copy transfer:

```typescript
// Inside the worker -- transfer the proof buffer instead of copying it
const proofBuffer = proof.proof.buffer;
self.postMessage(
  {
    type: "proof-generated",
    proof: proof.proof,
    publicInputs: proof.publicInputs,
  },
  [proofBuffer] // Transfer ownership, zero-copy
);
```

After transfer, the buffer is no longer accessible in the worker. This is fine because the worker is done with it.

## Multiple Workers for Parallel Proving

For applications that need to generate multiple proofs simultaneously, spawn multiple workers:

```typescript
function createProverPool(size: number) {
  const workers: Worker[] = [];
  const queue: Array<{
    circuit: any;
    inputs: any;
    resolve: (proof: any) => void;
    reject: (err: any) => void;
  }> = [];
  const busy = new Set<number>();

  for (let i = 0; i < size; i++) {
    const worker = new Worker(
      new URL("./proof-worker.ts", import.meta.url)
    );
    workers.push(worker);

    worker.onmessage = (e) => {
      busy.delete(i);
      if (e.data.type === "proof-generated") {
        // Resolve the promise for this job
      }
      // Process next item in queue
      processQueue();
    };
  }

  function processQueue() {
    if (queue.length === 0) return;
    const freeWorker = workers.findIndex((_, idx) => !busy.has(idx));
    if (freeWorker === -1) return;

    busy.add(freeWorker);
    const job = queue.shift()!;
    workers[freeWorker].postMessage({
      type: "prove",
      circuit: job.circuit,
      inputs: job.inputs,
    });
  }

  return {
    prove(circuit: any, inputs: any): Promise<any> {
      return new Promise((resolve, reject) => {
        queue.push({ circuit, inputs, resolve, reject });
        processQueue();
      });
    },
    terminate() {
      workers.forEach((w) => w.terminate());
    },
  };
}
```

Use this sparingly. Each worker loads its own WASM instance, consuming significant memory. Two workers is usually the practical limit on most devices.
