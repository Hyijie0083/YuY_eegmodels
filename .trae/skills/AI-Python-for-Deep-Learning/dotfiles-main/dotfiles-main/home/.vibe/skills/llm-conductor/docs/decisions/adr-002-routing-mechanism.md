# ADR-002: Threshold-Based Routing with Conservative Default

**Status:** Accepted — extended by ADR-008 (workflow architect framing applies routing at subtask level within meta-task workflow plans; this ADR still governs simple task routing and per-subtask routing decisions). Amended by ADR-012 (Steps 1-2 replaced: binary delegable/Claude-only taxonomy replaced with three-category delegability; competence boundaries now operate at two levels per amended Invariant 10)

## Context

The conductor must triage each task and route it to a local ensemble or keep it with Claude. Research (RouteLLM, ICLR 2025) shows ML-based routing classifiers require 65K+ labeled samples to train effectively. The conductor will not have that volume of data, especially early on. Threshold-based routing — a decision tree over task type and competence boundaries — is practical for a Claude Code skill.

Invariant 2 requires Claude as the safe default. Invariant 10 defines hard competence boundaries that local models cannot cross regardless of evaluation history.

## Decision

The conductor uses a threshold-based decision tree to route tasks:

1. **Classify** the task by type (extraction, classification, summarization, code-generation, analysis, reasoning)
2. **Check competence boundaries** — multi-step reasoning, knowledge-intensive Q&A, complex instructions (>4 constraints), cross-file code analysis → always Claude (Invariant 10)
3. **Check task profiles** — if this task type has evaluation history with a specific ensemble, use the learned routing
4. **Check available ensembles** — discover matching ensembles via `list_ensembles`, verify runnable via `check_ensemble_runnable`
5. **Default to Claude** if no confident local route exists (Invariant 2)

The routing config is versioned (Invariant 9). Thresholds are adjusted in batch from accumulated evaluations, never in real-time.

The user is always asked before delegation (Invariant 1). The conductor presents its routing recommendation and the user confirms or overrides.

For trusted ensembles (those the user has repeatedly approved for a given task type), the conductor may offer a **standing authorization**: "Always route extraction tasks to this ensemble without asking?" The user explicitly grants this per-ensemble, per-task-type. Standing authorizations are recorded in the routing config and revocable at any time. This preserves Invariant 1 — the user decides to delegate the decision itself.

## Consequences

**Positive:**
- No training data requirement — works from the first invocation
- Conservative default protects quality while the system learns
- Transparent decision tree is explainable to the user
- Versioned config enables rollback if routing quality degrades

**Negative:**
- Less optimal routing than a trained ML classifier would achieve at scale
- Requires Claude tokens for every triage decision (though triage is lightweight)
- Competence boundaries may be overly conservative for some task instances
- **Assumption:** task type classification from natural language descriptions is reliable — this is untested and misclassification would route tasks incorrectly

**Neutral:**
- The decision tree is encoded in the SKILL.md prompt, not in code
