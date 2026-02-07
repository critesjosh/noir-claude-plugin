# Circuit Development

Skills for writing Noir zero-knowledge circuits.

## Key Concept

Noir circuits define **constraints over a witness**. The entry point is `fn main()`, which declares public and private inputs. The prover supplies all inputs; the verifier only sees public inputs and the proof.

Both branches of an `if/else` always execute -- there is no short-circuit evaluation. All loop bounds must be known at compile time. There is no dynamic allocation.

## Subskills

Traverse according to needed functionality:

* [Circuit Structure](./circuit-structure.md) - `fn main()`, public/private inputs, return values, assertions
* [Data Types](./data-types.md) - Field, integers, arrays, strings, structs, BoundedVec, cost comparison
* [Generics](./generics.md) - Generic functions, numeric generics, turbofish syntax, where clauses
* [Traits](./traits.md) - Trait definitions, built-in traits, derive macros, trait constraints
* [Modules and Imports](./modules-and-imports.md) - `mod`, `use`, `pub`, crate structure, re-exports
* [Oracles](./oracles.md) - Foreign function interface with JavaScript runtime
* [Unconstrained Functions](./unconstrained-functions.md) - Non-circuit computation, hints, unsafe blocks
