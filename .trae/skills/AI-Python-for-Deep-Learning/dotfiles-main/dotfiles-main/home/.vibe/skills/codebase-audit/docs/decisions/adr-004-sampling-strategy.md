# ADR-004: Sampling Strategy

**Status:** Accepted

## Context

The Codebase may be too large to read exhaustively. Invariant 10 states the skill samples strategically and never claims exhaustive coverage. Lens Analysts need a principled way to decide what to read. Different lenses care about different parts of the Codebase — Pattern Recognition needs entry points and module boundaries; Test Quality needs test files; Documentation Integrity needs docs and comments.

The Orchestrator's Reconnaissance phase produces the Codebase Map, which identifies Components, file distribution, and structural layout. This map should guide what Lens Analysts sample.

## Decision

Sampling is lens-directed and map-informed. The Orchestrator provides each Lens Analyst with:

1. The **Codebase Map** (always)
2. A **sampling directive** specific to the Lens's analytical needs
3. For Meso and Micro lenses: the **Architectural Profile** or prior Findings that indicate where to focus

Each Lens Analyst uses the Codebase Map to navigate and reads files using Read, Grep, and Glob tools. The Lens Analyst decides what to read based on its sampling directive — the Orchestrator does not pre-select files.

**Sampling directives by Lens:**

| Lens | Sample From | Rationale |
|------|------------|-----------|
| Pattern Recognition | Entry points, directory structure, module boundaries, config files, dependency manifests | Architecture is visible at boundaries and entry points |
| Architectural Fitness | Config, deployment files, error handling patterns, middleware, cross-cutting concerns | Quality attributes manifest in cross-cutting code |
| Decision Archaeology | Config files, README, CLAUDE.md, git history (if accessible), naming conventions, directory structure | Decisions leave traces in naming and configuration |
| Dependency & Coupling | Import/require statements, module public APIs, shared types | Coupling is visible in import graphs |
| Intent-Implementation Alignment | Public interfaces, class/module names vs. their implementations, function signatures vs. bodies | Alignment is visible where naming meets behavior |
| Invariant Analysis | Validation code, middleware, guard clauses, error handlers, constructor constraints | Invariants live in enforcement code |
| Documentation Integrity | README, inline comments, API docs, type annotations, config documentation | Documentation lives in docs and comments |
| Structural Health | Largest files, most-imported modules, areas flagged by prior phases | Smells concentrate in high-traffic code |
| Dead Code | Exports, public APIs, test utilities, feature flags, config entries | Dead code is visible at interfaces |
| Test Quality | Test files, test utilities, test configuration | Test quality lives in test code |

## Consequences

**Positive:**
- Each Lens reads what's relevant to its analysis, not everything
- The Codebase Map provides navigation without the Orchestrator pre-selecting (preserving Lens Analyst independence per Invariant 3)
- Sampling directives are specific enough to guide but flexible enough for the Lens Analyst to exercise judgment

**Negative:**
- Lens Analysts may miss important code outside their sampling directive — but this is inherent to strategic sampling
- Some overlap in what different lenses read (e.g., config files appear in multiple directives) — acceptable because each lens reads for different reasons

**Neutral:**
- Git history access depends on the environment; Decision Archaeology may have less signal in codebases without accessible git history
