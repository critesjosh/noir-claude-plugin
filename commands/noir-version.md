---
description: Switch the Noir version used by the MCP server. Autodetects version from Nargo.toml if no version specified.
---

# Noir Version

Switch the Noir version used by the local MCP server repositories.

**Version argument:** $ARGUMENTS

## Workflow

### Step 1: Determine Version

**If version argument provided:**
- Use the provided version directly (e.g., `v1.0.0`, `nightly-2024-01-01`)

**If no version argument (autodetect):**

1. Search for Nargo.toml files in the project using Glob: `**/Nargo.toml`

2. Read the Nargo.toml and extract the compiler version:
```toml
[package]
compiler_version = ">=1.0.0"
```

3. If a dependency uses a git tag, extract that version instead:
```toml
some_lib = { git = "...", tag = "v1.0.0" }
```

4. If no Nargo.toml found or no version detected, ask the user to specify a version explicitly.

### Step 2: Confirm with User

Before syncing, show the detected/provided version and ask for confirmation.

### Step 3: Sync Repositories

Call `noir_sync_repos` with the version:
```
noir_sync_repos({ version: "<detected-or-provided-version>", force: true })
```

### Step 4: Verify and Report

1. Call `noir_status()` to verify the sync
2. Report which version was synced and any errors
