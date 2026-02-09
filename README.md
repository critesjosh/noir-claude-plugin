# Noir Plugin for Claude Code

A Claude Code plugin for Noir zero-knowledge circuit development. Provides skills and commands for writing, testing, proving, and verifying Noir circuits.

## Installation

### Option 1: Install from Marketplace (Recommended)

```
/plugin marketplace add critesjosh/noir-claude-plugin
/plugin install noir@noir-plugins
```

### Option 2: Load from Directory (Development)

Clone the repository and load directly:

```bash
git clone https://github.com/critesjosh/noir-claude-plugin
claude --plugin-dir /path/to/noir-plugin
```

## Updating

### Marketplace installs

```
/plugin marketplace update
```

### Local installs

```bash
cd /path/to/noir-plugin
git pull
```

Changes take effect on the next Claude Code session.

## Noir MCP Server

This plugin includes the [noir-mcp-server](https://www.npmjs.com/package/noir-mcp-server) which provides local access to Noir documentation, examples, standard library, and source code.

### Features

- **Repository Cloning** — Clones noir compiler, standard library, and examples locally
- **Code Search** — Regex-based search across Noir source files
- **Documentation Search** — Search Noir docs by section
- **Standard Library Search** — Search stdlib functions and types
- **Example Discovery** — List and read example circuits

### Switching Versions

The MCP server defaults to the latest stable Noir version. To switch:

**Option 1: Use the `/noir-version` command**

```
/noir-version                    # Autodetect from project's Nargo.toml
/noir-version v1.0.0             # Use specific version
```

**Option 2: Call `noir_sync_repos` directly**

```
noir_sync_repos({ version: "v1.0.0", force: true })
```

**Check current version:**

```
noir_status()
```

## Skills

### Circuit Development

**Noir Developer** (`noir-developer`)

- Circuit structure, data types, generics, traits
- Standard library: cryptographic primitives, collections, field operations
- Workspace setup: project initialization, Nargo.toml, dependencies
- MCP tool reference for all 9 server tools

### Testing

**Noir Testing** (`noir-testing`)

- Test attributes: `#[test]`, `should_fail`, `should_fail_with`
- Constrained vs unconstrained tests
- Assertion patterns and debugging with `println`
- Test organization and best practices

### JavaScript Integration

**Noir JS** (`noir-js`)

- Full pipeline: compile, load artifact, generate witness, prove, verify
- `@noir-lang/noir_js` for witness generation and oracle callbacks
- `@aztec/bb.js` for proof generation
- Input encoding, artifact loading, version compatibility

### Web Integration

**Noir Web** (`noir-web`)

- React integration with `useProof()` hook pattern
- Web Worker proving (never block the main thread)
- WASM setup with Cross-Origin-Isolation headers
- Bundler configs: Vite, Webpack, Next.js
- UX patterns: progress indicators, error design, mobile considerations

### Circuit Review

**Review Circuit** (`review-circuit`)

- Correctness: pub annotations, assertions, edge cases
- Constraint efficiency: Field preference, hash choice, loop bounds
- Unconstrained safety: verify all hints with constraints
- Proof soundness: both-branch execution, under-constrained witnesses
- Structured output with severity levels (Critical/High/Medium/Low)

## Slash Commands

| Command | Description |
|---------|-------------|
| `/noir:noir-developer` | Circuit development patterns and stdlib reference |
| `/noir:noir-testing` | Test framework usage and patterns |
| `/noir:noir-js` | JavaScript proving pipeline |
| `/noir:noir-web` | Browser integration with Web Workers |
| `/noir:review-circuit [path]` | Review a circuit for correctness and efficiency |
| `/noir-version [version]` | Switch Noir version for MCP server |

## Noir LSP Integration

The plugin includes LSP (Language Server Protocol) configuration for Noir, providing:

- Real-time diagnostics and error checking
- Code intelligence for `.nr` files
- Integration with the Nargo toolchain

**Requirement:** Nargo must be installed. Install via [noirup](https://noir-lang.org/docs/getting_started/installation/).

## What's Included

```
noir-plugin/
├── .claude-plugin/
│   ├── plugin.json            # Plugin manifest + MCP server config
│   └── marketplace.json       # Marketplace registry
├── .lsp.json                  # Noir LSP configuration
├── .mcp.json                  # Local MCP server config
├── commands/
│   └── noir-version.md        # Version switching command
├── skills/
│   ├── noir-developer/        # Circuit development (hub skill)
│   │   ├── SKILL.md
│   │   ├── circuit-dev/       # Structure, types, generics, traits, oracles
│   │   ├── stdlib/            # Crypto primitives, collections, field ops
│   │   └── workspace/         # Project setup, Nargo.toml, dependencies
│   ├── noir-testing/          # Test framework
│   │   ├── SKILL.md
│   │   ├── test-attributes.md
│   │   ├── assertion-patterns.md
│   │   └── test-organization.md
│   ├── noir-js/               # JavaScript proving
│   │   ├── SKILL.md
│   │   ├── compilation.md
│   │   ├── witness-generation.md
│   │   ├── proving-and-verifying.md
│   │   └── artifact-loading.md
│   ├── noir-web/              # Web integration
│   │   ├── SKILL.md
│   │   ├── react-integration.md
│   │   ├── web-worker-proving.md
│   │   ├── wasm-setup.md
│   │   └── ux-patterns.md
│   └── review-circuit/        # Circuit review
│       └── SKILL.md
├── CLAUDE.md                  # Development guidelines (always loaded)
└── README.md                  # This file
```

## Resources

- [Noir Documentation](https://noir-lang.org/docs)
- [Noir GitHub](https://github.com/noir-lang/noir)
- [Noir Standard Library](https://noir-lang.org/docs/standard_library)
- [Barretenberg](https://github.com/AztecProtocol/barretenberg)
- [noir_js on npm](https://www.npmjs.com/package/@noir-lang/noir_js)

## License

MIT
