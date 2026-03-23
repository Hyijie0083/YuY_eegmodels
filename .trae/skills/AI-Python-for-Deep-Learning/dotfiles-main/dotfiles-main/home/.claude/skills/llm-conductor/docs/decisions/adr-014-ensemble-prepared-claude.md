# ADR-014: Ensemble-Prepared Claude Pattern

**Status:** Accepted

## Context

ADR-012 establishes that most previously Claude-only task types **split** into an ensemble-delegable preparation phase and a Claude-only judgment phase. "Design the architecture" is Claude-only, but "gather all file structures, extract existing patterns, analyze each component" is ensemble-delegable. The self-evaluation worked example showed that ~70% of what was classified as entirely Claude-direct was actually ensemble-delegable preparation work. Claude spent ~35K+ tokens on gathering and comparison that an ensemble could handle, leaving only ~5K tokens of genuine judgment.

This means even Claude-only subtasks in a workflow plan can benefit from ensemble delegation — not of the subtask itself, but of the preparation work that precedes the judgment.

## Decision

Introduce the **ensemble-prepared Claude** pattern as a workflow step:

1. The conductor identifies that a Claude-only subtask has a separable preparation phase (data gathering, pattern extraction, per-item comparison, evidence collection)
2. The conductor runs a multi-stage ensemble (ADR-013) to produce a **structured brief** — the preparation results organized for Claude's consumption
3. Claude receives the structured brief and performs only the final judgment, reasoning, or creative synthesis
4. The routing decision record logs both the ensemble invocation (preparation) and the Claude invocation (judgment) as a single logical subtask

**When to apply.** The conductor applies ensemble-prepared Claude when:
- The subtask is classified as Claude-only (fails DAG decomposability test for the *entire* task)
- The subtask has an identifiable preparation phase that *does* pass the DAG decomposability test
- A matching multi-stage ensemble or template architecture exists or can be composed (respecting the repetition threshold from ADR-010)

**When NOT to apply.** Skip ensemble preparation when:
- The Claude-only subtask is entirely judgment with no separable preparation (e.g., "What should we name this module?")
- The preparation would be trivial (< 500 estimated tokens) — overhead exceeds savings
- No template architecture matches and the preparation pattern won't repeat (below repetition threshold)

**Token tracking.** For ensemble-prepared Claude subtasks, the routing decision record includes:
- `preparation_tokens_local` — tokens consumed by the preparation ensemble
- `judgment_tokens_claude` — tokens consumed by Claude on the brief
- `estimated_full_claude_tokens` — estimated tokens Claude would have consumed without preparation
- `preparation_savings` — the delta

**Presentation to user:**
```
Preparation: [ensemble output — structured brief]
Local: {N} tokens

Judgment: [Claude output — decision/synthesis]
Claude: {M} tokens (estimated {F} without preparation — {P}% reduction)
```

**Evaluation protocol for ensemble-prepared Claude.** The preparation ensemble and the combined pattern are evaluated separately:

1. **Preparation ensemble** — evaluated through the standard calibration/sampling loop (Invariant 4, Invariant 5). Scores assess brief quality: completeness, structure, factual accuracy of extracted data.
2. **Combined output** — during calibration of the ensemble-prepared Claude *pattern* (first 5 uses of the pattern for a given task type), the combined output (brief + judgment) is always evaluated as a unit. This catches the "correct judgment on wrong evidence" failure mode. After pattern calibration, combined evaluation follows the same sampling rate as the preparation ensemble.
3. **Failure attribution** — when the combined output scores poorly, the conductor's reflection must attribute failure to either the brief (incomplete, inaccurate) or the judgment (wrong reasoning given correct brief). This attribution informs whether to improve the preparation ensemble or adjust the judgment prompt.

## Consequences

**Positive:**
- Reduces Claude token consumption for Claude-only subtasks. Per-invocation savings estimated at 50-85% (based on the self-evaluation worked example; actual savings depend on task structure and preparation ensemble composition cost amortization). Savings accrue after the preparation ensemble exists; composition cost is a one-time investment subject to ADR-010's repetition threshold
- Claude's reasoning quality may improve — structured briefs are easier to reason about than raw files
- The preparation ensemble's quality is evaluated through the standard calibration/sampling loop; the combined pattern has its own calibration
- Compounding benefit: the same preparation ensemble reuses across similar Claude-only subtasks

**Negative:**
- Adds latency — ensemble runs first, then Claude reasons on the brief. For time-sensitive subtasks, the sequential overhead may not be worthwhile
- Preparation quality affects judgment quality — if the ensemble misses relevant context, Claude's judgment is based on incomplete information. This is a new failure mode: correct judgment on wrong evidence. Dual evaluation (brief + combined) mitigates but does not eliminate this risk, especially after the pattern transitions to sampled evaluation
- Not all Claude-only subtasks have separable preparation phases — the conductor must judge this boundary, which is itself a Claude-level task
- Over-application could reduce Claude's serendipitous insights — Claude processing raw files sometimes notices things a structured brief would filter out

**Neutral:**
- The pattern is optional per-subtask; the conductor may skip it when overhead exceeds benefit
- Preparation ensembles are promotable and reusable like any other ensemble
