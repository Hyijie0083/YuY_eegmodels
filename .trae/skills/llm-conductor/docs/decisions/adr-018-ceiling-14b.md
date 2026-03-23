# ADR-018: Ceiling Tier Raised from 12B to 14B

**Status:** Proposed — supersedes ADR-005 ceiling rule. Records the decision already reflected in Invariant 3 (amended 2026-02-23, domain model amendment #10)

## Context

ADR-005 established a 12B ceiling for ensemble synthesizers, with 12B reserved for synthesis across 4+ upstream outputs. Invariant 3 (composition over scale) constrains reaching for larger models.

Two developments motivate revisiting the specific number:

1. **Model availability.** qwen3:14b is now available via Ollama. The prior ceiling (gemma3:12b) is no longer the largest practical option. The 14B tier provides a meaningful capability bump over 12B for synthesis tasks without violating the composition-over-scale principle.

2. **Inference scaling crossover.** Research on inference scaling laws (2024) shows a crossover: on harder tasks, a single larger model eventually outperforms two smaller models at equal compute. This creates a bounded exception to Invariant 3 for high-fan-in synthesis. On tasks requiring synthesis across 4+ upstream outputs, a single 14B model provides better quality per compute than composing smaller models. The 14B ceiling applies only to this specific use case — it is a concession to the crossover effect, not a general relaxation of the composition-over-scale principle.

The principle (composition over scale) is validated by all research. The specific number needs adjustment to match available models.

## Decision

Raise the ceiling tier from 12B to 14B. Specifically:

- **Model tier "ceiling"** is now 14B (was 12B)
- **Conductor profile "conductor-medium"** ceiling option is qwen3:14b (was gemma3:12b)
- **Ceiling rule unchanged:** the ceiling tier is reserved for synthesis across 4+ upstream outputs, or tasks where composition of smaller models demonstrably underperforms. It is the exception, not the norm.
- **The ≤7B preference is unchanged:** swarms of small models remain the primary architecture. 14B is the ceiling, not the default.

## Consequences

**Positive:**
- Better synthesis quality for high-fan-in ensembles (4+ upstream outputs)
- Matches actually available models (qwen3:14b exists; gemma3:12b was the prior cap)
- Preserves Inv 3: the principle (prefer composition) is unchanged; only the exception ceiling moves

**Negative:**
- Slightly higher resource consumption when the ceiling tier is used
- ADR-005's ceiling language needs a supersession note
- ADR-013's conductor-medium profile entry ("gemma3:12b only when synthesizing 4+ upstream outputs") is superseded — the ceiling model is now qwen3:14b per this ADR

**Neutral:**
- No change to ensemble design patterns — only the synthesizer profile at the ceiling tier changes
- No change to routing logic — the conductor's triage is model-size-agnostic
