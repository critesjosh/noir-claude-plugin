# React Integration

Patterns for integrating Noir proving into React applications. The core principle: the React component manages state and user interaction while a Web Worker handles all proving.

## Custom Hook: `useProof`

Encapsulate all proving logic in a reusable hook:

```typescript
import { useState, useRef, useEffect, useCallback } from "react";
import type { CompiledCircuit } from "@noir-lang/types";

type ProofStatus = "idle" | "proving" | "verified" | "error";

interface ProofResult {
  proof: Uint8Array;
  publicInputs: string[];
}

function useProof(circuit: CompiledCircuit) {
  const [status, setStatus] = useState<ProofStatus>("idle");
  const [proof, setProof] = useState<ProofResult | null>(null);
  const [error, setError] = useState<string | null>(null);
  const workerRef = useRef<Worker | null>(null);

  // Initialize worker on mount
  useEffect(() => {
    const worker = new Worker(
      new URL("./proof-worker.ts", import.meta.url)
    );

    worker.onmessage = (e) => {
      const { type, proof, publicInputs, error } = e.data;
      switch (type) {
        case "proof-generated":
          setProof({ proof, publicInputs });
          setStatus("verified");
          setError(null);
          break;
        case "error":
          setError(error);
          setStatus("error");
          break;
      }
    };

    worker.onerror = (e) => {
      setError(e.message || "Worker crashed unexpectedly");
      setStatus("error");
    };

    workerRef.current = worker;

    // Terminate worker on unmount
    return () => {
      worker.terminate();
      workerRef.current = null;
    };
  }, []);

  const prove = useCallback(
    (inputs: Record<string, string | string[]>) => {
      if (!workerRef.current) return;
      setStatus("proving");
      setError(null);
      setProof(null);
      workerRef.current.postMessage({ type: "prove", circuit, inputs });
    },
    [circuit]
  );

  const reset = useCallback(() => {
    setStatus("idle");
    setProof(null);
    setError(null);
  }, []);

  return { status, proof, error, prove, reset };
}
```

## Using the Hook in a Component

```typescript
import circuit from "../target/my_circuit.json";

function AgeProof() {
  const { status, proof, error, prove, reset } = useProof(circuit);
  const [age, setAge] = useState("");

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    prove({ age });
  };

  return (
    <form onSubmit={handleSubmit}>
      <label>
        Age:
        <input
          type="number"
          value={age}
          onChange={(e) => setAge(e.target.value)}
          disabled={status === "proving"}
        />
      </label>

      <button type="submit" disabled={status === "proving"}>
        {status === "proving" ? "Generating proof..." : "Prove"}
      </button>

      {status === "verified" && (
        <div className="success">
          Proof generated. {proof!.proof.length} bytes.
        </div>
      )}

      {status === "error" && (
        <div className="error">
          {error}
          <button type="button" onClick={reset}>Try again</button>
        </div>
      )}
    </form>
  );
}
```

## State Machine

The proving flow follows a strict state machine:

```
idle --> proving --> verified
  ^         |           |
  |         v           |
  +------ error <-------+
         (reset)
```

- **idle** -- Waiting for user input
- **proving** -- Worker is generating proof (disable inputs, show progress)
- **verified** -- Proof is ready (show result, allow copy/download)
- **error** -- Something went wrong (show message, allow retry)

## Component Lifecycle

### Worker Initialization

Create the worker once when the component mounts. Do not create a new worker for each proof:

```typescript
// GOOD: one worker, reused
useEffect(() => {
  const worker = new Worker(new URL("./proof-worker.ts", import.meta.url));
  workerRef.current = worker;
  return () => worker.terminate();
}, []);

// BAD: new worker per proof
const prove = () => {
  const worker = new Worker(new URL("./proof-worker.ts", import.meta.url));
  worker.postMessage({ type: "prove", circuit, inputs });
};
```

### Cleanup

Always terminate the worker when the component unmounts. Unterminated workers continue consuming memory and CPU.

## SSR Considerations

Web Workers and WASM are browser-only APIs. If you use Next.js or any SSR framework, you must guard against server-side execution.

### Next.js Dynamic Import

```typescript
import dynamic from "next/dynamic";

const ProofComponent = dynamic(() => import("./ProofComponent"), {
  ssr: false,
  loading: () => <p>Loading prover...</p>,
});

export default function Page() {
  return <ProofComponent />;
}
```

### Window Guard

```typescript
function useProof(circuit: CompiledCircuit) {
  const workerRef = useRef<Worker | null>(null);

  useEffect(() => {
    if (typeof window === "undefined") return;

    const worker = new Worker(
      new URL("./proof-worker.ts", import.meta.url)
    );
    workerRef.current = worker;
    return () => worker.terminate();
  }, []);

  // ...
}
```

### Lazy Circuit Loading

Circuit JSON files can be large. Load them lazily to avoid bloating the initial bundle:

```typescript
function ProofComponent() {
  const [circuit, setCircuit] = useState(null);

  useEffect(() => {
    import("../target/my_circuit.json").then((mod) => {
      setCircuit(mod.default);
    });
  }, []);

  if (!circuit) return <p>Loading circuit...</p>;

  return <ProofForm circuit={circuit} />;
}
```

## Error Handling

### Worker Crash

If the worker crashes (e.g., out of memory), the `onerror` handler fires but the worker is dead. Recreate it:

```typescript
worker.onerror = (e) => {
  setError("Worker crashed. Reinitializing...");
  setStatus("error");

  // Replace the dead worker
  const newWorker = new Worker(
    new URL("./proof-worker.ts", import.meta.url)
  );
  // Re-attach handlers...
  workerRef.current = newWorker;
};
```

### Proof Timeout

Add a timeout to catch stalled proofs:

```typescript
const prove = (inputs: Record<string, string | string[]>) => {
  setStatus("proving");
  workerRef.current?.postMessage({ type: "prove", circuit, inputs });

  const timeout = setTimeout(() => {
    if (status === "proving") {
      setError("Proof generation timed out. The circuit may be too large.");
      setStatus("error");
    }
  }, 120_000); // 2 minutes

  // Clear timeout when proof completes (in the onmessage handler)
};
```

### Input Validation

Validate inputs before sending them to the worker. Witness generation errors from bad inputs produce cryptic WASM error messages:

```typescript
const handleSubmit = () => {
  const ageNum = parseInt(age, 10);
  if (isNaN(ageNum) || ageNum < 0 || ageNum > 255) {
    setError("Age must be a number between 0 and 255");
    setStatus("error");
    return;
  }
  prove({ age });
};
```
