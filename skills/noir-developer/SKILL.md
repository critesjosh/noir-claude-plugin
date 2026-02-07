---
name: noir-developer
description: "Patterns for Noir circuit development: data types, stdlib, workspace setup. Use when working with Noir circuits in any capacity unless otherwise specified"
allowed-tools: Read, Grep, Glob, Edit, Write, Bash
---

# Noir Circuit Development Skills

Comprehensive patterns and best practices for Noir zero-knowledge circuit development.

## Subskills

Navigate to the appropriate section based on your task:

* [Circuit Development](./circuit-dev/index.md) - Writing Noir circuits: structure, types, generics, traits, oracles
* [Standard Library](./stdlib/index.md) - Cryptographic primitives, collections, field operations
* [Workspace Setup](./workspace/index.md) - Project initialization, Nargo.toml, dependencies

## Quick Reference

### Writing Circuits
Start with [Circuit Structure](./circuit-dev/circuit-structure.md) for the basic template, then explore:
- [Data Types](./circuit-dev/data-types.md) - Field, integers, arrays, structs, BoundedVec
- [Generics](./circuit-dev/generics.md) - Generic functions, numeric generics, turbofish
- [Traits](./circuit-dev/traits.md) - Trait definitions, built-in traits, derive macros
- [Modules and Imports](./circuit-dev/modules-and-imports.md) - Code organization and visibility
- [Oracles](./circuit-dev/oracles.md) - Foreign function interface with JavaScript
- [Unconstrained Functions](./circuit-dev/unconstrained-functions.md) - Non-circuit computation and hints

### Using the Standard Library
- [Cryptographic Primitives](./stdlib/cryptographic-primitives.md) - Hashing, signatures, curves
- [Collections](./stdlib/collections.md) - BoundedVec, HashMap
- [Field Operations](./stdlib/field-operations.md) - Byte conversions, radix decomposition

### Setting Up a Project
- [Project Setup](./workspace/project-setup.md) - `nargo init`, directory structure, workflow
- [Nargo.toml](./workspace/nargo-toml.md) - Package manifest configuration
- [Dependencies](./workspace/dependencies.md) - Git, path, and workspace dependencies

## Using Noir MCP Server

For detailed API documentation and code examples beyond what is covered here, use the Noir MCP tools.

### Available MCP Tools

| Tool | Purpose |
|------|---------|
| `noir_sync_repos()` | Clone/update Noir repos locally. Run first to enable searching. |
| `noir_status()` | Check which repos are synced and their commit hashes |
| `noir_search_code({ query })` | Search Noir source code with regex patterns |
| `noir_search_docs({ query })` | Search Noir documentation |
| `noir_search_stdlib({ query })` | Search the Noir standard library |
| `noir_list_examples()` | List available Noir example circuits |
| `noir_read_example({ name })` | Read full source code of an example |
| `noir_read_file({ path })` | Read any file from cloned repos by relative path |
| `noir_list_libraries()` | List available Noir libraries |

### Workflow

```
User asks Noir question
         |
   noir_sync_repos() (if not done)
         |
   noir_search_code() / noir_search_docs() / noir_search_stdlib()
         |
   noir_read_example() if needed
         |
   Respond with VERIFIED current syntax
```

**First, sync the repos (if not already done):**
```
noir_sync_repos()
```

**Search for code patterns:**
```
noir_search_code({ query: "<pattern>", filePattern: "*.nr" })
```

**Search the standard library:**
```
noir_search_stdlib({ query: "poseidon" })
```

**List and read examples:**
```
noir_list_examples()
noir_read_example({ name: "<example-name>" })
```

**Search documentation:**
```
noir_search_docs({ query: "<question>" })
```
