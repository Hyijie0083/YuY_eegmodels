# ADR-011: Trust-but-Verify Calibration for On-the-Fly Ensembles

**Status:** Accepted

## Context

ADR-003 establishes that the first 5 invocations of any new ensemble are always evaluated (Invariant 4). The original design implied ensembles must complete calibration before being trusted. But the workflow architect framing (ADR-008) creates ensembles on the fly to handle subtasks within a running workflow. If calibration blocks usage, on-the-fly ensembles can't contribute until 5 invocations later — by which point the workflow may be complete.

Additionally, when the conductor creates an ensemble after observing Claude perform the same subtask 3 times (ADR-010, adaptive mode), Claude's 3 prior outputs serve as implicit quality examples. The ensemble's system prompt encodes the pattern Claude demonstrated. This is not the same as zero prior evidence.

## Decision

**Ensembles are usable from invocation 1.** Calibration gates evaluation-skipping, not usage.

During calibration (first 5 invocations):
- Every invocation is evaluated (Invariant 4 — unchanged)
- Ensemble output is presented to the user immediately
- If an invocation scores "poor," the conductor falls back to Claude for subsequent subtasks of that type in the current session
- If an invocation scores "good" or "acceptable," the conductor continues using the ensemble

**Pattern-as-calibration:** When an ensemble is created after observing Claude perform the subtask (ADR-010, adaptive mode), Claude's prior outputs inform the ensemble's system prompt. The conductor notes this in the evaluation record: `calibration_context: "pattern-from-observation"`. This does not reduce the calibration period (still 5 evaluated invocations) but increases confidence in early invocations.

After 5 evaluated invocations, the ensemble transitions to the established phase (ADR-003 sampling rates apply).

## Consequences

**Positive:**
- On-the-fly ensembles contribute immediately within the workflow that created them
- Poor output is caught by mandatory calibration evaluation and triggers fallback
- Pattern-as-calibration provides higher confidence for adaptively-created ensembles
- No change to the calibration period length (5 invocations) — the safety guarantee is preserved

**Negative:**
- The user sees unvetted output from a brand-new ensemble. If the ensemble produces poor output, the user experiences a failure before the conductor catches it
- Fallback after a poor score means some subtask work is wasted (ensemble output discarded, Claude redo)
- Pattern-as-calibration confidence may be misplaced if the ensemble doesn't replicate Claude's pattern faithfully

**Neutral:**
- The user can always reject ensemble output (Invariant 1) — trust-but-verify is bilateral
