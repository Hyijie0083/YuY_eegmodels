# ADR-003: 3-Point Rubric with CoT-Before-Verdict, Sampled After Calibration

**Status:** Accepted — clarified by ADR-011 (calibration gates evaluation-skipping, not usage; ensembles are usable from invocation 1 with trust-but-verify)

## Context

The conductor must evaluate ensemble output quality to inform routing adjustments, promotion decisions, and LoRA candidate flagging. Research shows binary or low-precision rubrics are more consistent than fine-grained scales, and chain-of-thought reasoning before verdict measurably improves judge accuracy.

Using Claude to judge local model output avoids the echo chamber bias (different model families for generation and judgment). However, every evaluation costs Claude tokens. Invariant 5 requires sampled evaluation after calibration. Invariant 4 requires the first 5 invocations always be evaluated.

## Decision

Evaluations use a 3-point rubric:
- **good** — output is correct, complete, and usable as-is
- **acceptable** — output is directionally correct but may need minor refinement
- **poor** — output is incorrect, incomplete, or unusable

The conductor produces a reflection (verbal CoT reasoning about quality) before rendering the score. Both the reflection and score are persisted.

When scoring "poor," the conductor also classifies the failure mode: hallucination, incomplete, wrong-format, or off-topic.

Sampling strategy:
- **Calibration** (first 5 uses of any ensemble): evaluate every invocation
- **Established** (6-20 uses): evaluate 10-20% of invocations
- **Trusted** (>20 uses, >80% of evaluations scored acceptable or good): skip routine evaluation
- **Triggered**: always evaluate when the user provides negative feedback

## Consequences

**Positive:**
- Low-precision rubric is more reliable than numeric scales
- CoT-before-verdict improves accuracy over score-first approaches
- Sampling controls evaluation cost after calibration
- Failure mode classification enables LoRA candidate flagging (Invariant 8)

**Negative:**
- 3 categories may be too coarse for some routing adjustments
- Sampling means some poor outputs go unevaluated after calibration
- Evaluation itself consumes Claude tokens

**Neutral:**
- The rubric definitions may need refinement after initial use — the skill's reflective loop applies to its own evaluation approach too
