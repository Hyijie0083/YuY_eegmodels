# ADR-017: Architectural Complementarity as Conditional Design Pattern

**Status:** Proposed

## Context

SLM-MUX (2025) demonstrated that pairing architecturally different models — e.g., Mistral Small 24B with Qwen2.5 7B — produces +4.3-4.5% accuracy gains over the best single model. Two SLMs beat a 72B model on GPQA and GSM8K. The mechanism is measurable: architecturally different models fail on different inputs, providing coverage gains.

But three research findings bound this pattern:

1. **Works for reasoning, not generation.** "Rethinking Mixture-of-Agents" (2025) showed self-MoA (same model repeated) outperforms mixed-model MoA by 6.6% on open-ended generation (AlpacaEval). When a synthesizer reads both outputs, weak model outputs contaminate the synthesis.

2. **Arbitration mechanism matters.** Confidence-based selection (pick one winner) works. Synthesis (merge both outputs) risks contamination. "Debate or Vote" (NeurIPS 2025 spotlight) showed debate is strictly worse than independent generation plus arbitration — on GSM8K with Qwen2.5-7B, voting scored 0.94 vs. debate at 0.85.

3. **Correlated errors are real.** Even across different architectures, models agree on 60% of errors vs. a 33% random baseline. The benefit is bounded.

Two metrics determine viability for a specific model pair on a specific task type:
- **Union accuracy**: the fraction of problems where at least one model is correct (must be high)
- **Contradiction penalty**: how often one model is confidently wrong while the other is right (must be low)

## Decision

Architectural complementarity is a **conditional design pattern** in the ensemble designer's toolkit, not a default.

**Apply when all conditions hold:**
1. The task involves reasoning or verification with determinable correct answers
2. Union accuracy for the candidate model pair is high (measured during calibration)
3. Contradiction penalty is low (measured during calibration)
4. The arbitration mechanism is confidence-based selection (not synthesis or debate). Verification scripts (ADR-016) are the preferred implementation for confidence computation. If a verification script is not available, sample-frequency-based voting (majority vote across multiple generations from each model) is an acceptable fallback

**Do not apply when:**
- The task is open-ended generation (summarization, creative writing, free-form explanation)
- Only one model architecture is available at the appropriate tier
- Calibration data shows the model pair has high contradiction penalty on the task type
- The additional compute cost (running two models) is not justified by accuracy gains

**Measurement protocol:** During calibration of a complementary ensemble, the designer tracks:
- Per-problem correctness for each model independently
- Union accuracy and contradiction penalty across the calibration set
- Whether confidence-based selection correctly picks the right model

If union accuracy drops below a threshold or contradiction penalty rises above a threshold during calibration, the designer recommends reverting to a single-model design.

**DAG shape for complementary ensembles:**
```
[input] → LLM-A (architecture 1) → verification-script → select-winner → [output]
        → LLM-B (architecture 2) → verification-script →
```
Both LLMs generate independently (no debate, no seeing each other's output). The verification script (ADR-016) computes confidence for each output and selects via argmax. If no verification script is available, each LLM generates N samples and the winner is selected by majority vote frequency.

## Consequences

**Positive:**
- Captures the genuine accuracy gains from architectural diversity on reasoning tasks
- Avoids the contamination trap (no synthesis, no debate)
- Measurable: union accuracy and contradiction penalty provide clear go/no-go signals
- Deterministic arbitration via verification scripts eliminates unreliable LLM judgment

**Negative:**
- Doubles compute for the LLM stage (two models instead of one)
- Requires calibration data to validate the model pair — cannot be applied speculatively
- Adds complexity to ensemble design (two profiles, verification script, selection logic)

**Neutral:**
- Does not affect single-model ensembles — this is an additional pattern, not a replacement
- The conductor's triage is unaffected — complementarity is a design-layer decision, not a routing-layer decision
