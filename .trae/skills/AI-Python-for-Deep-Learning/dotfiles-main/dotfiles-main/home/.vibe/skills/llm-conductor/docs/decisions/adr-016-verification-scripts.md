# ADR-016: Verification Scripts as Ensemble Building Blocks

**Status:** Proposed

## Context

SLMs under ~13B cannot reliably assess their own output quality. "Small Language Models Need Strong Verifiers to Self-Correct Reasoning" (2024) explicitly demonstrates this. AutoMix (NeurIPS 2024) formulates routing as a POMDP precisely because self-verification signals from small models are too noisy to use directly. This limitation explains why internal self-routing fails (the classifier agent cannot verify), why synthesis-based arbitration risks contamination, and why the conductor's external evaluation (Claude as judge) is necessary.

But Claude-as-judge operates *outside* the ensemble. Within the ensemble DAG, there is currently no mechanism for quality assessment between pipeline stages. Script agents can host classical ML models that provide deterministic quality signals at a fraction of LLM inference cost, solving this gap.

Three techniques are supported by evidence:
1. **Embedding-based confidence** — MiniLM (22M params, ~80MB, 4,000 sentences/sec on CPU). BERTScore achieves 0.76-0.90 system-level correlation with human judgment. Semantic Self-Consistency extends this: embed multiple paths, compute centroid, weight votes by proximity.
2. **NLI-based consistency** — DeBERTa-v3-base (86M params, ~170MB quantized, 10-50ms on CPU). SelfCheckGPT achieves 92.50 AUC-PR for non-factual detection. No task-specific training needed.
3. **Log-probability entropy** — Per-token entropy from logprobs via numpy. No model, no training, zero latency beyond the original generation. Available from any Ollama model exposing logprobs.

## Decision

Introduce **verification scripts** as a first-class building block for ensemble DAGs. A verification script is a script agent that hosts classical ML models to provide reliable, low-cost quality signals via classical computation rather than LLM self-assessment.

**Priority order** for verification techniques within an ensemble:
1. Log-probability entropy (zero cost — use whenever logprobs are available)
2. Embedding-based confidence via MiniLM (low cost, high utility for similarity/coherence)
3. NLI-based consistency via DeBERTa (moderate cost, high utility for factual verification)

**Integration pattern:** Verification scripts sit between LLM agents and downstream consumers in the ensemble DAG:
```
LLM-A → verification-script → downstream-agent
```
Or for complementary model arbitration:
```
LLM-A ──→ verification-script → select-winner
LLM-B ──→    (confidence)    →   (argmax selection)
```

**Log-probability entropy** uses the model's own output distribution processed through classical computation (Shannon entropy via numpy). This differs from LLM self-verification — where a model generates a textual assessment of its own quality — in that no generative judgment is involved. The computation is purely statistical, consistent with Invariant 14's intent to replace generated self-assessments with classical computation.

**The ensemble designer** authors verification scripts as part of ensemble composition. The designer chooses which techniques to include based on task characteristics and available models.

**Verification scripts do not replace conductor-level evaluation.** Claude-as-judge (ADR-003) operates at the orchestration layer on final ensemble output. Verification scripts operate *within* the ensemble DAG on intermediate outputs. These are complementary, not competing.

## Consequences

**Positive:**
- Ensemble-internal quality signals without relying on LLM self-verification
- Classical-ML-based arbitration with deterministic selection (argmax) for complementary model patterns (no synthesis contamination)
- Expands what is practically ensemble-delegable (Inv 10) — tasks previously Claude-only due to quality concerns become ensemble-delegable with verification
- Cheap: MiniLM is 80MB, DeBERTa is 170MB, entropy is free

**Negative:**
- Additional dependencies: ONNX runtime, sentence-transformers, or equivalent for MiniLM/DeBERTa
- Script agents become more complex (ML model loading, inference)
- Portability concern for promotion (Inv 11): verification scripts must declare their ML model dependencies

**Neutral:**
- Does not change the evaluation protocol (ADR-003) — that remains Claude-as-judge at the orchestration layer
- DAG decomposability test (ADR-012) condition 2 (script-absorbable) should be amended to explicitly include classical ML inference: "Script-absorbable — non-LLM complexity can be handled by script agents, including file I/O, parsing, tool execution, and classical ML inference (embedding models, NLI classifiers, statistical computations). Classical ML models in script agents are not LLM agents and do not count toward agent-level competence boundaries"
