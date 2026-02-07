# Project Setup

## Creating a New Project

### Basic Initialization

```bash
nargo init
```

Creates a project in the current directory with default name matching the directory.

### Named Project

```bash
nargo init --name my_circuit
```

Creates a project with the specified name.

### In a New Directory

```bash
mkdir my_circuit && cd my_circuit && nargo init
```

## Directory Structure Created

```
my_circuit/
  Nargo.toml          # Package manifest
  src/
    main.nr           # Entry point (contains fn main)
```

After compilation, additional files appear:

```
my_circuit/
  Nargo.toml
  src/
    main.nr
  target/
    my_circuit.json   # Compiled circuit artifact
  Prover.toml         # Prover inputs (create manually)
  Verifier.toml       # Verifier inputs (create manually)
```

## Input Files

Create `Prover.toml` with all inputs (public and private):

```toml
# Prover.toml
x = "3"
y = "5"
```

Create `Verifier.toml` with only public inputs and return values:

```toml
# Verifier.toml
y = "5"
return = "15"
```

## Build Workflow

### Check (type-check without compiling)

```bash
nargo check
```

Validates the circuit without producing artifacts. Useful for catching errors quickly.

### Compile

```bash
nargo compile
```

Compiles the circuit and produces the JSON artifact in `target/`.

### Run Tests

```bash
# Run all tests
nargo test

# Run tests matching a name
nargo test test_add

# Show print output
nargo test --show-output
```

### Execute (Generate Witness)

```bash
nargo execute
```

Runs the circuit with inputs from `Prover.toml` and generates a witness.

### Prove

```bash
nargo prove
```

Generates a proof using the witness. Requires a backend (Barretenberg installed).

### Verify

```bash
nargo verify
```

Verifies the proof against the circuit and public inputs.

### Full Workflow

```bash
nargo check          # 1. Type-check
nargo compile        # 2. Compile to artifact
nargo execute        # 3. Generate witness from Prover.toml
nargo prove          # 4. Generate proof
nargo verify         # 5. Verify proof
```

## Workspace Setup (Multi-Crate Projects)

For projects with multiple circuits or shared libraries:

```
workspace-root/
  Nargo.toml              # Workspace manifest
  circuits/
    circuit_a/
      Nargo.toml          # type = "bin"
      src/main.nr
    circuit_b/
      Nargo.toml          # type = "bin"
      src/main.nr
  libs/
    shared_utils/
      Nargo.toml          # type = "lib"
      src/lib.nr
```

**Root Nargo.toml:**

```toml
[workspace]
members = [
    "circuits/circuit_a",
    "circuits/circuit_b",
    "libs/shared_utils",
]
```

### Workspace Commands

```bash
# Compile all members
nargo compile

# Test all members
nargo test

# Compile a specific member
nargo compile --package circuit_a

# Test a specific member
nargo test --package shared_utils
```

### Adding a New Crate to a Workspace

1. Create the directory and initialize:
   ```bash
   mkdir -p circuits/circuit_c && cd circuits/circuit_c && nargo init --name circuit_c
   ```
2. Add it to the root `Nargo.toml` workspace members
3. If it depends on shared libraries, add them to its `Nargo.toml` `[dependencies]`
