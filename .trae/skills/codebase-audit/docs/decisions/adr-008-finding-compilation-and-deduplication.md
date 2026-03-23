# ADR-008: Finding Compilation and Deduplication

**Status:** Accepted

## Context

Multiple Lens Analysts may observe the same phenomenon from different angles. A God Object may appear in both the Structural Health lens (as a Code Smell) and the Intent-Implementation Alignment lens (as naming that doesn't match behavior). These are not duplicates — they're complementary perspectives on the same code.

However, truly redundant observations (two lenses noting the same thing with the same framing) should be merged to avoid a bloated report.

## Decision

The Orchestrator compiles Findings using a **merge-complementary, deduplicate-redundant** strategy:

1. **Group** Findings by Code Location. Findings that reference the same or overlapping Code Locations are candidates for grouping.

2. **Merge complementary** Findings: if two Findings reference the same Code Location but from different lenses with different Patterns, Tradeoffs, or Socratic Questions — keep both. Present them together as a "multi-lens observation" showing how the same code looks through different analytical perspectives. This reinforces the pedagogical goal: the same code teaches different lessons depending on the lens.

3. **Deduplicate redundant** Findings: if two Findings reference the same Code Location with substantially the same Observation, Pattern, and Tradeoff — keep the one with the stronger evidence and more specific Code Location references. Note which lenses converged on the observation (convergence strengthens confidence).

4. **Prioritize** Findings that multiple lenses converge on — convergence across independent Lens Analysts (per Invariant 3) is strong signal.

## Consequences

**Positive:**
- Multi-lens observations are a pedagogical feature, not a bug — they show the user that the same code has multiple dimensions
- Convergence across independent lenses strengthens finding confidence
- Redundant noise is removed without losing complementary perspectives

**Negative:**
- Grouping by Code Location requires the Orchestrator to parse and compare locations — some judgment involved
- "Substantially the same" is a fuzzy criterion — but the Orchestrator (running at Opus) can make this judgment

**Neutral:**
- The final report may contain fewer Findings than the sum of all Lens Analyst outputs — this is by design
