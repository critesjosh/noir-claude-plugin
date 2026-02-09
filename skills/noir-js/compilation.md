# Compilation

Noir circuits must be compiled before they can be used from JavaScript. The `nargo compile` command produces a JSON artifact that contains everything needed for witness generation and proving.

## Compiling a Circuit

```bash
# From the circuit's directory (where Nargo.toml lives)
nargo compile
```

This produces `target/<package_name>.json`, where `<package_name>` comes from the `name` field in `Nargo.toml`.

For a workspace with multiple circuits:

```bash
# Compile all packages in the workspace
nargo compile

# Compile a specific package
nargo compile --package my_circuit
```

## Artifact Contents

The JSON artifact contains:

| Field | Description |
|-------|-------------|
| `abi` | Input/output parameter definitions (names, types, visibility) |
| `bytecode` | Compiled circuit as base64-encoded ACIR |

Example artifact structure (simplified):

```json
{
  "abi": {
    "parameters": [
      { "name": "x", "type": { "kind": "field" }, "visibility": "private" },
      { "name": "y", "type": { "kind": "field" }, "visibility": "public" }
    ],
    "return_type": null
  },
  "bytecode": "H4sIAAAAAAAA..."
}
```

## Loading in Node.js

Direct JSON import (recommended for simplicity):

```typescript
import circuit from "../target/my_circuit.json";
```

If using TypeScript with `resolveJsonModule` disabled, or for dynamic loading:

```typescript
import { readFileSync } from "fs";

const circuit = JSON.parse(
  readFileSync("./target/my_circuit.json", "utf-8")
);
```

## Loading in the Browser

Use `fetch` to load the artifact at runtime:

```typescript
const response = await fetch("/artifacts/my_circuit.json");
const circuit = await response.json();
```

Or bundle it with your application using a bundler that supports JSON imports.

## Version Compatibility

The compiled artifact version **must match** the `@noir-lang/*` package versions. If they diverge, you will get runtime errors.

```bash
# Check nargo version
nargo --version

# Check JS package versions
npm ls @noir-lang/noir_js @aztec/bb.js
```

Keep them in sync:

```bash
# If nargo is v1.0.0-beta.18, install matching noir_js package
npm install @noir-lang/noir_js@1.0.0-beta.18 @aztec/bb.js
```

## Recompilation

Recompile whenever:

- Circuit source (`.nr` files) changes
- Dependencies in `Nargo.toml` change
- You update `nargo` to a new version

The `target/` directory can be safely deleted and regenerated with `nargo compile`.
