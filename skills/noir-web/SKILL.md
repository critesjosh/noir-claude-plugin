---
name: noir-web
description: "Web integration for Noir circuits. Covers React integration, Web Worker proving, WASM setup, and UX patterns for browser-based ZK applications."
allowed-tools: Read, Grep, Glob, Edit, Write, Bash
---

# Noir Web Integration

Build browser-based ZK applications with Noir circuits using React, Web Workers, and WASM.

## Architecture Overview

```
React Component (main thread)
    |
    |  postMessage({ type: 'prove', circuit, inputs })
    v
Web Worker (background thread)
    |
    |  noir.execute(inputs) --> backend.generateProof(witness)
    v
WASM (barretenberg, running inside worker)
    |
    |  postMessage({ type: 'proof-generated', proof })
    v
React Component (updates UI with proof)
```

- **React/UI component** handles user interaction and state
- **Web Worker** runs proving in a background thread
- **WASM modules** (barretenberg) run inside the Web Worker
- **Message passing** connects the main thread and worker

## Critical Rule: Always Prove in a Web Worker

Proving is CPU-intensive and **will freeze the browser** if run on the main thread. A medium-sized circuit can block the UI for 5-30 seconds. Large circuits can take minutes.

Never do this:

```typescript
// BAD: blocks the main thread
const { proof, publicInputs } = await backend.generateProof(witness);
```

Always delegate to a Web Worker:

```typescript
// GOOD: runs in background thread
worker.postMessage({ type: 'prove', circuit, inputs });
```

## WASM Requirements

SharedArrayBuffer is required by barretenberg and needs Cross-Origin-Isolation HTTP headers:

```
Cross-Origin-Opener-Policy: same-origin
Cross-Origin-Embedder-Policy: require-corp
```

Without these headers, `SharedArrayBuffer` is undefined and WASM initialization will fail. See [WASM Setup](./wasm-setup.md) for framework-specific configuration.

## Quick Start

```typescript
// App.tsx
import { useState, useRef, useEffect } from "react";
import circuit from "../target/my_circuit.json";

function ProveButton() {
  const [status, setStatus] = useState<"idle" | "proving" | "done" | "error">("idle");
  const workerRef = useRef<Worker | null>(null);

  useEffect(() => {
    const worker = new Worker(new URL("./proof-worker.ts", import.meta.url));
    worker.onmessage = (e) => {
      if (e.data.type === "proof-generated") setStatus("done");
      if (e.data.type === "error") setStatus("error");
    };
    workerRef.current = worker;
    return () => worker.terminate();
  }, []);

  const prove = () => {
    setStatus("proving");
    workerRef.current?.postMessage({
      type: "prove",
      circuit,
      inputs: { x: "3", y: "4" },
    });
  };

  return (
    <div>
      <button onClick={prove} disabled={status === "proving"}>
        {status === "proving" ? "Proving..." : "Generate Proof"}
      </button>
      {status === "done" && <p>Proof generated successfully.</p>}
      {status === "error" && <p>Proving failed. Try refreshing the page.</p>}
    </div>
  );
}
```

## Detailed Guides

- **[React Integration](./react-integration.md)** -- Custom hooks, component lifecycle, SSR considerations
- **[Web Worker Proving](./web-worker-proving.md)** -- Worker setup, message passing, Comlink, error handling
- **[WASM Setup](./wasm-setup.md)** -- Cross-Origin-Isolation headers for Vite, Webpack, Next.js
- **[UX Patterns](./ux-patterns.md)** -- Progress indicators, error design, mobile, input forms
