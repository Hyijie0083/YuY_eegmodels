# ADR-002: Subagent Model Selection

**Status:** Accepted

## Context

The skill launches up to ten Lens Analysts as parallel subagents via the Task tool. Each subagent performs a distinct kind of analysis. The Task tool supports a `model` parameter: `"opus"`, `"sonnet"`, `"haiku"`. Per the project's CLAUDE.md, Opus is for architecture and research, Sonnet for implementation and refactoring, Haiku for mechanical tasks.

The Orchestrator itself runs in whatever model the user invoked. Lens Analysts need enough capability to understand architectural patterns, infer intent, and produce pedagogical Findings — but launching ten Opus subagents is expensive.

## Decision

Assign models by Level:

| Level | Lenses | Model | Rationale |
|-------|--------|-------|-----------|
| Macro | Pattern Recognition, Architectural Fitness, Decision Archaeology | Sonnet | These require architectural reasoning but within a focused scope. Sonnet handles this well and is more cost-efficient than Opus. |
| Meso | Dependency & Coupling, Intent-Implementation Alignment, Invariant Analysis, Documentation Integrity | Sonnet | Semantic understanding of component relationships and intent. Sonnet is capable here. |
| Micro | Structural Health, Dead Code, Test Quality | Sonnet | Code-level pattern recognition from established taxonomies. Sonnet handles this reliably. |

The Orchestrator (Reconnaissance, Compilation, Synthesis, Walkthrough) runs at whatever model the user invoked the skill with — typically Opus for architectural work.

## Consequences

**Positive:**
- Cost-effective: Sonnet subagents are significantly cheaper than Opus while remaining capable for focused analytical tasks
- The Orchestrator retains full Opus capability for synthesis and the interactive Walkthrough
- Consistent model across all Lens Analysts simplifies the implementation

**Negative:**
- If any Lens requires deeper reasoning than Sonnet provides, findings quality may suffer — but this can be revised per-lens later if needed

**Neutral:**
- Users invoking the skill with Sonnet will get Sonnet for both Orchestrator and Lens Analysts
