# Artifact Loading

The compiled circuit artifact (JSON file produced by `nargo compile`) must be loaded before you can generate witnesses or proofs. Loading strategies differ between Node.js and browser environments.

## Node.js

### Direct JSON Import

The simplest approach -- works with TypeScript and bundlers that support JSON modules:

```typescript
import circuit from "../target/my_circuit.json";
```

For TypeScript, enable `resolveJsonModule` in `tsconfig.json`:

```json
{
  "compilerOptions": {
    "resolveJsonModule": true,
    "esModuleInterop": true
  }
}
```

### Using fs

For dynamic or runtime loading:

```typescript
import { readFileSync } from "fs";
import { CompiledCircuit } from "@noir-lang/types";

const circuit: CompiledCircuit = JSON.parse(
  readFileSync("./target/my_circuit.json", "utf-8")
);
```

### Dynamic Loading for Multiple Circuits

```typescript
import { readFileSync } from "fs";
import { CompiledCircuit } from "@noir-lang/types";

function loadCircuit(name: string): CompiledCircuit {
  return JSON.parse(
    readFileSync(`./target/${name}.json`, "utf-8")
  );
}

const transferCircuit = loadCircuit("transfer");
const mintCircuit = loadCircuit("mint");
```

## Browser

### Fetch from URL

Serve artifacts as static files and fetch them at runtime:

```typescript
import { CompiledCircuit } from "@noir-lang/types";

async function loadCircuit(name: string): Promise<CompiledCircuit> {
  const response = await fetch(`/artifacts/${name}.json`);
  return await response.json();
}

const circuit = await loadCircuit("my_circuit");
```

### Bundled Import

Most bundlers (Vite, webpack, esbuild) support JSON imports out of the box:

```typescript
import circuit from "../target/my_circuit.json";
```

For large circuits, consider lazy loading to avoid blocking the initial bundle:

```typescript
const circuit = await import("../target/my_circuit.json");
```

## TypeScript Typing

Use `CompiledCircuit` from `@noir-lang/types` for type safety:

```typescript
import { CompiledCircuit } from "@noir-lang/types";

const circuit: CompiledCircuit = /* loaded artifact */;
```

The `CompiledCircuit` type ensures the artifact has the required `abi` and `bytecode` fields.

## Version Compatibility

The artifact format changes between Noir versions. All `@noir-lang/*` packages must match the `nargo` version used to compile.

Check versions:

```bash
# Compiler version
nargo --version

# JS package versions
npm ls @noir-lang/noir_js @noir-lang/backend_barretenberg @noir-lang/types
```

Version mismatch symptoms:

- `Error: Failed to deserialize circuit` -- artifact format does not match JS package version
- `Error: Unknown opcode` -- bytecode version mismatch
- Unexpected ABI parsing errors

Fix by aligning versions:

```bash
npm install @noir-lang/noir_js@<version> @noir-lang/backend_barretenberg@<version> @noir-lang/types@<version>
```

## Artifact Structure Reference

A compiled artifact contains:

```typescript
interface CompiledCircuit {
  abi: {
    parameters: Array<{
      name: string;
      type: ABIType;
      visibility: "private" | "public";
    }>;
    return_type: ABIType | null;
  };
  bytecode: string; // Base64-encoded ACIR
}
```

The `abi` describes inputs and outputs. The `bytecode` is the compiled constraint system.

## Caching Strategies

For applications that load circuits repeatedly:

```typescript
const circuitCache = new Map<string, CompiledCircuit>();

async function getCircuit(name: string): Promise<CompiledCircuit> {
  if (!circuitCache.has(name)) {
    const response = await fetch(`/artifacts/${name}.json`);
    circuitCache.set(name, await response.json());
  }
  return circuitCache.get(name)!;
}
```

Artifacts are immutable for a given compilation -- cache aggressively. Invalidate the cache only when the circuit is recompiled.
