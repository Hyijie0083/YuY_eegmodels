# ADR-005: Inter-Phase Data Flow

**Status:** Accepted

## Context

The domain model establishes that earlier phases Inform later phases and that macro/meso Findings Target micro Analysis. But Invariant 3 states each Lens Analyst operates with independent context — no Lens Analyst receives another's findings. This creates a tension: how do later phases benefit from earlier work without breaking Lens Analyst independence?

The resolution: independence applies *within* a phase (Lens Analysts in the same phase don't see each other's work). *Between* phases, the Orchestrator compiles and passes forward a summary — this is the Orchestrator's job, not a Lens-to-Lens channel.

## Decision

The Orchestrator compiles phase outputs into structured summaries that subsequent Lens Analysts receive alongside the Codebase Map. Lens Analysts within the same phase never see each other's Findings.

**Phase output flow:**

| Phase | Produces | Passed Forward To |
|-------|----------|-------------------|
| Reconnaissance | Codebase Map | All subsequent Lens Analysts |
| Macro Analysis | Architectural Profile (compiled by Orchestrator from Pattern Recognition, Architectural Fitness, and Decision Archaeology findings) | Meso Lens Analysts |
| Meso Analysis | Meso Summary (compiled by Orchestrator from Dependency & Coupling, Intent-Implementation Alignment, Invariant Analysis, Documentation Integrity findings) | Micro Lens Analysts |
| Micro Analysis | Micro Findings | Orchestrator only (for Synthesis) |

**The Architectural Profile** is a structured summary containing:
- Identified architectural patterns (named, with confidence)
- Quality Attributes the architecture appears to optimize for
- Quality Attributes in tension
- Inferred ADRs (hypotheses about decisions)
- Areas of concern flagged for deeper investigation

**The Meso Summary** is a structured summary containing:
- Coupling hotspots and dependency direction issues
- Components where intent and implementation diverge
- Invariants identified and their enforcement gaps
- Documentation discrepancies

Both summaries are written by the Orchestrator after compiling Lens Analyst outputs. They are concise overviews, not the full Findings — Lens Analysts in later phases receive enough context to focus their sampling without being biased by specific observations.

## Consequences

**Positive:**
- Preserves Invariant 3 (Lens Analyst independence) within phases
- Later phases benefit from earlier context without direct Lens-to-Lens contamination
- The Orchestrator acts as an editorial filter, passing focus areas rather than raw conclusions

**Negative:**
- The Orchestrator's compilation introduces a bottleneck between phases — though this is inherently sequential by Invariant 2
- Summary quality depends on the Orchestrator's ability to distill — but the Orchestrator runs at the user's invoked model (typically Opus)

**Neutral:**
- This matches the peer-review skill's pattern where the orchestrator compiles independent reviewer outputs
