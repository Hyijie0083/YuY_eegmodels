# ADR-010: Repetition Threshold Gates On-the-Fly Ensemble Creation

**Status:** Accepted

## Context

The conductor as workflow architect (ADR-008) decomposes meta-tasks into subtasks and identifies delegable patterns. Some patterns have no existing ensemble. The conductor can create ensembles on the fly — but ensemble creation has a fixed cost (~5000 Claude tokens for design + calibration). Below a certain reuse frequency, Claude handling the subtask directly is cheaper.

The break-even analysis shows ~11 uses to recoup creation cost. But within a single session, the threshold for proposing creation is lower because the user's time (waiting for ensemble creation) also matters. Research (Intelligent AI Delegation, arXiv 2602.11865) identifies a complexity floor below which delegation overhead exceeds value.

## Decision

The **repetition threshold** for proposing on-the-fly ensemble creation is **3+ expected repetitions** of a subtask pattern. Below 3, the conductor handles the subtask via Claude directly.

> **Superseded by ADR-015:** Ensemble creation is the Ensemble Designer's responsibility. The conductor identifies the need and proposes creation; the designer composes.

The threshold operates in two modes:

**Predictive (during workflow planning):** The conductor analyzes the meta-task and predicts repetition counts. "The testing phase has 30 test cases following the same pattern — that exceeds the threshold." The ensemble is planned as part of the workflow and created before execution of that phase.

**Adaptive (during workflow execution):** The conductor observes it has performed the same subtask type 3 times via Claude. "I've extracted patterns from 3 files. 4 more remain." It proposes creating an ensemble for the remaining subtasks.

The threshold of 3 is a tunable parameter stored in routing-config.yaml (Invariant 9). It balances:
- Below 3: Claude is cheaper (2 subtasks × 500 tokens < 5000 token creation cost)
- At 3+: ensemble investment begins to pay off within the session
- For patterns with cross-session reuse potential, even 3 uses justifies creation because future sessions benefit

The user always confirms ensemble creation (Invariant 1).

## Consequences

**Positive:**
- Prevents ensemble creation for one-off subtasks (waste of tokens)
- Both predictive and adaptive modes catch delegation opportunities
- Tunable threshold allows users to adjust the cost/savings tradeoff
- Adaptive mode catches patterns the workflow plan didn't predict

**Negative:**
- Predictive mode depends on accurate repetition estimation — the conductor may over- or under-estimate
- The threshold of 3 is a heuristic, not a proven optimum
- Adaptive mode means the first 3 repetitions are always done by Claude (sunk cost if ensemble is then created)

**Neutral:**
- The threshold applies to within-session decisions; cross-session ensemble reuse (via persistence) bypasses it entirely
