---
name: review-circuit
description: "Review Noir circuits for correctness, constraint efficiency, and proof soundness. Use proactively after writing or modifying Noir circuits."
allowed-tools: Read, Grep, Glob, Bash
---

# Review Noir Circuit

Structured review of Noir zero-knowledge circuits for correctness, constraint efficiency, and proof soundness. This is a **read-only** skill -- it analyzes code and reports findings but does not modify files.

## Usage

```
/review-circuit [file-path]
```

Examples:

```
/review-circuit                           # Review circuit in current context
/review-circuit src/main.nr               # Review specific file
/review-circuit circuits/                  # Review all circuits in directory
```

## Workflow

### Step 1: Identify Circuit(s) to Review

- If a file path is provided as an argument, use it directly
- If a directory is provided, find all `main.nr` files within it using Glob: `<directory>/**/src/main.nr`
- If no path is provided, check conversation context for recently discussed files
- As a fallback, search the workspace with Glob: `**/src/main.nr`
- If multiple circuits are found, list them and ask the user which to review, or review all if the user confirms

### Step 2: Sync Noir Version (if needed)

Check `noir_status()` to see if repos are synced. If not, run `noir_sync_repos()`.

If a `Nargo.toml` exists in the project, read it to determine the Noir version in use. If the synced version does not match, warn the user.

### Step 3: Read and Understand the Circuit

1. Read the circuit file(s) with the Read tool
2. Read any related files imported by the circuit (modules, libraries)
3. Read the `Nargo.toml` to understand dependencies
4. Identify the circuit's purpose from code structure, function names, and comments
5. If the purpose is unclear, **ask the user** what the circuit is intended to do before proceeding

### Step 4: Verify Patterns Against Current API

Before flagging issues, verify that patterns and APIs are current:

- Use `noir_search_code()` to confirm function signatures and patterns
- Use `noir_search_stdlib()` to verify standard library usage
- Do not flag something as wrong if it matches current Noir syntax

### Step 5: Review Against Checklist

Work through each category systematically. Skip categories that are not applicable to the circuit under review.

#### 5.1 Correctness

- [ ] `pub` annotations are correct -- public inputs are minimized, all necessary inputs are public
- [ ] All assertions are present and meaningful -- no assertion means no constraint means no guarantee
- [ ] Integer type sizing is appropriate -- `u8` for small values, `u64` for large, `Field` for arithmetic
- [ ] Edge cases are handled -- zero values, maximum values, empty arrays
- [ ] Return values are correct and intentional -- return values become public outputs, do not leak secrets
- [ ] No dead code that appears to add constraints but does not actually constrain anything

#### 5.2 Constraint Efficiency

- [ ] `Field` is used for arithmetic where possible -- cheapest type, 1 constraint per operation
- [ ] Integer types are only used where range checking is genuinely needed -- each adds range-check constraints
- [ ] Unconstrained hints are used for complex computation -- compute in unconstrained, verify in constrained
- [ ] Hash function choice is appropriate:
  - **Poseidon2**: ~20 constraints, use for ZK-internal hashing (commitments, nullifiers, Merkle trees)
  - **Pedersen**: moderate cost, use for commitments where Poseidon2 is not suitable
  - **SHA-256**: ~25,000 constraints, use only when EVM/external compatibility is required
  - **Keccak**: ~25,000 constraints, use only when Ethereum compatibility is required
- [ ] Loop bounds are minimized -- every iteration multiplies the constraint count
- [ ] No unnecessary intermediate variables that force extra constraints
- [ ] `BoundedVec` max sizes are realistic -- oversized maximums waste constraints on unused capacity

#### 5.3 Unconstrained Safety

- [ ] Every unconstrained function result is verified with constraints in the calling code
- [ ] `unsafe {}` blocks are followed by assertion or verification logic
- [ ] No unconstrained results are trusted without verification -- **CRITICAL: unconstrained code can return anything, an attacker controls these values**
- [ ] The hint pattern is used correctly: compute in unconstrained, then verify with constrained assertions

#### 5.4 Oracle Usage

- [ ] Oracle return values are verified with constraints (same principle as unconstrained safety)
- [ ] Oracle function signatures match the corresponding JavaScript/TypeScript implementation
- [ ] Oracle wrapper functions are properly marked `unconstrained`
- [ ] `#[oracle(name)]` functions have empty bodies

#### 5.5 Public Input Handling

- [ ] Public inputs are minimized -- each adds verifier cost
- [ ] No information leaks through public inputs -- private data must not be exposed as `pub`
- [ ] Hash commitments are used where appropriate -- commit to private data, reveal hash publicly
- [ ] Return values do not accidentally expose private witnesses

#### 5.6 Proof Soundness

- [ ] Both branches of `if/else` are valid -- both branches execute in ZK, invalid branches cause circuit failures
- [ ] All inputs participate in constraints -- unconstrained inputs can be set to anything by a malicious prover
- [ ] No reliance on "unreachable" code for safety -- both branches always execute
- [ ] Assertions are sufficient to prevent a malicious prover from creating valid proofs with incorrect values
- [ ] No under-constrained witnesses that allow multiple valid solutions where only one is intended

### Step 6: Flag Issues by Severity

Classify every finding into one of these severity levels:

**Critical** -- Proof unsoundness or information leaks:
- Missing constraints that allow fake proofs
- Private data leaked through public inputs or return values
- Unconstrained results trusted without verification
- Both-branch-execution bugs that cause unexpected failures or bypass security
- Under-constrained witnesses allowing a malicious prover to forge proofs

**High** -- Significant correctness or efficiency issues:
- Missing assertions on critical values
- Grossly oversized integer types wasting thousands of constraints
- SHA-256 or Keccak used where Poseidon2 would suffice (~1000x constraint difference)
- Edge cases that could cause assertion failures in production

**Medium** -- Best practice violations:
- Suboptimal hash function choice with moderate constraint cost difference
- Unnecessary public inputs that increase verifier cost
- Oversized `BoundedVec` maximums
- Missing error messages on assertions (makes debugging harder)
- Unused function parameters that should be constrained or removed

**Low** -- Code style or minor improvements:
- Naming conventions
- Code organization and module structure
- Documentation and comment gaps
- Unused imports

### Step 7: Provide Recommendations

For each issue found:
1. Explain **why** it is a problem in the context of zero-knowledge proofs
2. Show the **current code** with file path and line reference
3. Provide **corrected code** showing the fix
4. Reference MCP examples or stdlib patterns if relevant

## Output Format

Structure every review report as follows:

```markdown
## Circuit Review: [CircuitName]

### Summary
Brief overview of the circuit's purpose and overall assessment of quality.

### Constraint Analysis
Estimated constraint breakdown by section (if discernible from the code).
Note which hash functions, integer types, and loop bounds dominate the constraint cost.

### Issues Found

#### Critical
- **[Issue Title]**: Description of the problem and its security impact.
  - Location: `file:line`
  - Current: `code snippet`
  - Suggested: `fixed code`
  - Why: Explanation of the ZK-specific risk.

#### High
...

#### Medium
...

#### Low
...

### Recommendations
Specific actionable suggestions for improving the circuit beyond fixing flagged issues.

### What's Done Well
Highlight good practices observed in the circuit. Positive reinforcement for correct patterns.
```

If no issues are found at a given severity level, omit that section rather than printing an empty list.

## Interactive Review

During review, ask clarifying questions when intent is ambiguous. Examples:

- "This function returns a private witness value. Is it intentional that this becomes a public output?"
- "This unconstrained hint computes X but I see no constraint verifying the result. Is verification handled in a different function?"
- "This loop bound of 1000 generates significant constraints. Could the maximum be reduced for your use case?"
- "This `pub` input exposes a value that appears to be private. Is this needed by the verifier?"

Do not assume -- ask. Incorrect assumptions lead to false positives that erode trust in the review.

## Common Noir Pitfalls to Check

These are the most frequently encountered issues in Noir circuits. Pay special attention to each:

1. **Trusting unconstrained output** -- `unsafe { hint() }` without a corresponding `assert()` means the prover can return any value. This is the single most common soundness bug.

2. **Both branches execute** -- In a ZK circuit, `if secret { valid_path } else { invalid_path }` will execute both branches. If the invalid path triggers an out-of-bounds access or assertion failure, the circuit fails regardless of the condition.

3. **Field overflow** -- Field arithmetic wraps at the prime modulus. The expression `x + 1 == 0` is satisfiable when `x = p - 1`. Range checks are required if overflow behavior matters.

4. **Missing `pub` on inputs** -- Forgetting `pub` on a function parameter means the verifier cannot check that input value. The prover can set it to anything.

5. **SHA-256 for internal hashing** -- Using SHA-256 or Keccak for ZK-internal operations (Merkle trees, nullifiers, commitments) is roughly 1000x more expensive in constraints than Poseidon2. Only use SHA-256/Keccak when external compatibility with EVM or other systems is required.

6. **Oversized integer types** -- Using `u64` when `u8` suffices wastes range-check constraints. Each integer operation adds range-check gates proportional to the bit width.

7. **Under-constrained witnesses** -- If a witness variable does not participate in any assertion or constraint, the prover can set it to any value. This may allow forging proofs that the verifier accepts.

8. **Leaking private data through returns** -- Noir function return values become public circuit outputs. Returning a private witness exposes it to the verifier and anyone who sees the proof.
