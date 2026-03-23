# Purpose-Built Ensembles and the Design Laboratory

*2026-02-23*

How task-specific SLM pipelines, external orchestration, and lightweight verification compose into a system that learns to build its own instruments.

---

## The Two Strategies

A frontier model orchestrating local small language models can organize the work in two ways.

**Strategy A** builds a purpose-built ensemble for each task type. The frontier model (Claude) decomposes work, decides what goes where, invokes the right ensemble, and evaluates the result. Each ensemble is a bespoke DAG — a specific arrangement of script agents, LLM agents, and synthesis — designed for one job. The ensembles are stateless instruments; Claude is the musician.

**Strategy B** builds general-purpose ensembles with internal routing. A classifier agent inside the ensemble determines how to process the input. Parallel analysts of different architectures handle the work. A synthesizer arbitrates. Claude is one composable profile among several — slotted in when the ensemble's confidence scorer flags an input as too hard. The ensemble is closer to an autonomous system.

These aren't implementation variants. They differ in where task specificity lives (in the ensemble topology vs. in the orchestrator's reasoning) and where routing intelligence lives (external vs. internal). The question is which approach produces better results for small language models under ~14B parameters, and whether a hybrid exists that captures both strategies' strengths.

---

## What the Evidence Says

### Purpose-built pipelines outperform general-purpose ones

The evidence from 2023-2025 converges across independent research lines.

General-purpose routers trained on generic data fail on domain-specific tasks. RouteLLM (UC Berkeley/Anyscale, ICLR 2025) demonstrated this concretely: routers trained on 65,000 chatbot preference pairs performed at near-random on MMLU. Adding just 1,500 task-specific samples — less than 2% of training data — fixed the problem. General routers generalize across model pairs but not across task domains. This was replicated conceptually by the "Doing More with Less" survey's analysis of the bias-variance tradeoff in routing, by routing collapse research showing general routers systematically default to the most expensive model, and by RouterArena's finding that no single router dominates across all metrics.

On the positive side, task-specific compositions produce dramatic results. DisCIPL (MIT/Yale, 2025) showed a 1B model with task-specific program generation jumping from 0.07 to 0.76 on constrained generation — outperforming GPT-4o at 0.32. SLM-MUX (2025) demonstrated that two task-specifically paired SLMs outperform Qwen 2.5 72B on GPQA and GSM8K. FrugalGPT achieved 98% cost reduction with task-specific quality scoring. Fine-tuned Qwen3-4B matched a 120B teacher on 7 of 8 tasks and outperformed it by 19 points on SQuAD 2.0.

The critical SLM-MUX finding: the optimal number of models varies by task. Two models peak on GPQA, two on GSM8K, five-plus on MATH. No single ensemble configuration works universally. This directly undermines general-purpose ensemble design — you cannot pick one topology for all tasks.

### External orchestration beats internal self-routing for SLMs

Google DeepMind's "Towards a Science of Scaling Agent Systems" (2025) — 3,975 cases across 4 benchmarks — provides the most comprehensive comparison of coordination architectures. Centralized orchestration produces 4.4x error amplification versus 17.2x for independent multi-agent systems. The study's most consequential finding: "Orchestrator capability dominates overall system performance." The quality of the routing agent matters more than the quality of the workers.

This finding has a specific mechanistic explanation for small models. SLMs under ~13B parameters cannot reliably self-verify. AutoMix (NeurIPS 2024) formulates routing as a POMDP precisely because self-verification signals from small models are too noisy to use directly. "Small Language Models Need Strong Verifiers to Self-Correct Reasoning" (2024) explicitly demonstrates that models at 13B and below lack the capacity to assess their own output quality. The synthesis's pattern of embedding a classifier agent inside the ensemble — making the ensemble self-routing — places a critical function (routing) on models that cannot reliably perform it.

Claude as external orchestrator is not overhead. It is the system's competitive advantage.

### Architectural complementarity is real but conditional

Running two architecturally different models on the same task and arbitrating produces genuine gains — on the right task types, with the right arbitration mechanism.

SLM-MUX validated this at the 7B-27B scale: pairing Mistral Small 24B with Qwen2.5 7B produced +4.3-4.5% accuracy gains over the best single model. Two SLMs beat a 72B model. The mechanism is measurable: "union accuracy" (the fraction of problems where at least one model is correct) must be high while "contradiction penalty" (one model confidently wrong while the other is right) must be low. Architecturally different models fail on different inputs — that is the source of coverage gains.

But three caveats bound this pattern.

First, it works for reasoning and verification tasks (MATH, GPQA, GSM8K) where there is a correct answer to select. "Rethinking Mixture-of-Agents" (2025) showed that for open-ended generation tasks (AlpacaEval), self-MoA (the same model repeated) outperforms mixed-model MoA by 6.6%. When a synthesizer reads both outputs, weak model outputs contaminate the synthesis. Quality dominates diversity for generation.

Second, the arbitration mechanism matters. Confidence-based selection (pick one winner based on sample frequency) works. Synthesis (merge both outputs) risks contamination. Multiple independent confirmations show that debate — where models see each other's output — is strictly worse than independent generation plus arbitration. "Debate or Vote" (NeurIPS 2025 spotlight) demonstrated that multi-agent debate induces a martingale over belief trajectories: it does not systematically improve accuracy. On GSM8K with Qwen2.5-7B, voting scored 0.94 while debate scored 0.85.

Third, correlated errors are real. Even across different architectures, models agree on 60% of errors versus a 33% random baseline. Architectural diversity helps but does not eliminate error correlation. The benefit is bounded.

Complementarity is a valid design pattern, not a universal default. It belongs in the ensemble designer's toolkit, applied when task characteristics warrant it and measured through calibration.

---

## The Verification Layer

The self-verification problem — SLMs cannot reliably assess their own output quality — appears throughout the research as the central limitation of small model systems. It explains why external orchestration works (Claude can verify), why internal routing fails (the classifier agent cannot), and why complementarity requires careful arbitration (the synthesizer's judgment may also be unreliable).

But the problem has a solution that neither Strategy A nor Strategy B addresses: classical ML techniques running in script agents.

Script agents in an ensemble DAG can host lightweight specialized models — not LLMs, but embedding models, NLI classifiers, and statistical methods — that provide quality signals at a fraction of LLM inference cost.

**Embedding-based confidence.** `all-MiniLM-L6-v2` (22M parameters, ~80MB, 4,000 sentences per second on CPU, native ONNX support) computes cosine similarity between candidate outputs, between output and reference, or between output and input. BERTScore achieves 0.76-0.90 system-level correlation with human judgment. Semantic Self-Consistency extends this: embed multiple reasoning paths, compute the centroid, weight votes by centroid proximity. This consistently outperforms naive majority voting on reasoning benchmarks.

**NLI-based consistency validation.** DeBERTa-v3-base (86M parameters, ~170MB quantized, 10-50ms on CPU) performs natural language inference without task-specific training. The SelfCheckGPT pattern: sample multiple outputs, use NLI to check whether each sentence in the primary output is contradicted by alternatives. This achieves 92.50 AUC-PR for non-factual detection. It directly replaces the LLM self-verification that fails under 13B.

**Log-probability entropy.** The simplest approach — compute per-token entropy from logprobs with numpy. High entropy signals low confidence. No model, no training, no latency. Available from any local model that exposes logprobs.

These techniques solve the Q3 arbitration problem concretely. Instead of asking a synthesizer LLM to judge which analyst output is better (which is self-verification, which fails for SLMs), a script agent with MiniLM computes embedding-based confidence and selects the winner deterministically:

```
LLM-A (qwen3) ──> script: embed + confidence ──> script: select winner
LLM-B (mistral) > script: embed + confidence ──>   (deterministic)
```

No LLM judgment required. No contamination from the weaker model's output entering a synthesis prompt. The verification layer is classical ML hosted in script agents — fast, cheap, and more reliable than any SLM's self-assessment.

This reframes what script agents are for. They are not just file I/O and JSON validation. They are the deterministic anchor in a probabilistic system — the place where verifiable computation replaces unreliable self-assessment.

---

## The Knowledge Graph as Shared Memory

Both strategies store their operational data — routing logs, evaluation records, ensemble specs, calibration results — in flat JSONL and YAML files. This works for append-only logging but fails at the queries that matter: "What led to this poor result?" "What has worked for similar tasks?" "Which profile combinations are complementary on extraction tasks?" These are graph traversal problems, and flat storage requires manual reconstruction every time.

The evidence for graph-structured memory over flat storage is quantitative. AIMKG (HPE, 2024) — a metadata knowledge graph of 1.6 million AI pipelines — achieves 78% relevant pipeline retrieval versus 51% for flat schema alternatives. A-MEM (2025) showed ~2x improvement in multi-hop reasoning and 85-93% token reduction through graph-structured retrieval. Zep/Graphiti (2025) demonstrated +38.4% improvement on temporal reasoning tasks. SkewRoute (EMNLP 2025) reduced expensive model calls by 40% through KG-informed routing.

For the conductor and ensemble designer, a knowledge graph with provenance tracking serves three roles.

**Provenance.** W3C PROV entities map naturally: ensemble specs are Entities, calibration runs are Activities, routing decisions are Activities that `used` specific configurations. A bi-temporal model (Zep/Graphiti) tracks both when an ensemble configuration was valid and when we learned about its performance. When a routing decision produces a poor result, tracing the causal chain — which spec, which profiles, what calibration data informed the design, what changed since the last good result — is a single graph traversal, not a manual log correlation exercise.

**Design knowledge accumulation.** The ensemble designer needs to answer: "For tasks with characteristics similar to this one, which DAG shapes, profile combinations, and script patterns produced the best calibration results?" AIMKG demonstrated that a metadata KG answers such questions 53% more accurately than flat schema approaches. Design knowledge is inherently relational — "this DAG shape works for this task type with these profiles" — and graphs represent relations natively.

**Cross-project meta-learning.** MetaKG (IEEE TKDE, 2022) showed that knowledge graphs enable informed decisions in cold-start scenarios through structured knowledge about related tasks. When the designer encounters a task type with no calibration history, the graph can surface related tasks and their successful configurations. Trainable Graph Memory (2025) showed this specifically benefits less capable systems — a 25.8% improvement. This is the laboratory operating at scale: not just learning within one project, but across all projects. Each ensemble is an experiment; the KG captures the full provenance chain from task to outcome.

---

## The Skill Decomposition

The conductor currently owns both workflow orchestration and ensemble design. These are different modes of thinking with different knowledge requirements, different cadences, and different optimal model selections.

The RDD skill decomposition provides the structural template. RDD separates research (divergent exploration), modeling (naming and bounding), decision (committing to choices), and building (executing to spec) into separate skills — not because they are sequential steps, but because each requires a different cognitive mode. Each skill owns one concern, coordinates via artifacts, and can trigger backward jumps when later phases reveal flaws in earlier ones.

The conductor's two concerns map similarly.

**Orchestration** is operational and evaluative. It decomposes tasks, routes to ensembles, invokes, tracks tokens, evaluates quality, adapts during execution. It runs on every invocation and benefits from speed — Sonnet-class reasoning is sufficient for routing decisions.

**Ensemble design** is creative and architectural. It chooses DAG shapes, selects profiles for complementarity, authors scripts, interprets calibration data, manages promotion. It runs when building or improving ensembles and benefits from depth — Opus-class reasoning is warranted for architectural judgment and script authoring.

The handoff between them is artifact-based. The conductor produces routing needs ("I need an ensemble for this task type") and evaluation data ("this ensemble scored poor on 3 of 5 calibration runs; failure mode: incomplete"). The designer produces validated ensembles ("here is a multi-stage ensemble with these profiles and scripts, validated and ready for calibration") and design knowledge ("confidence-based selection works better than synthesis for extraction tasks on this model pair").

The separation enables the laboratory. Without it, ensemble creation is subordinate overhead within workflow execution — something the conductor does reluctantly when no ensemble exists. With the separation, ensemble design becomes a first-class research activity. The designer maintains its own knowledge base of what works: which DAG shapes suit which task types, which model pairs are complementary, which script patterns are reusable across projects. Every ensemble built is an experiment; the designer accumulates the results.

The MCP tool distribution supports this. The conductor uses 7 tools (set_project, invoke, analyze_execution, list_ensembles, get_provider_status, list_profiles, check_ensemble_runnable). The designer uses 15 (create_ensemble, validate_ensemble, create_profile, update_ensemble, promote_ensemble, check_promotion_readiness, list_dependencies, demote_ensemble, library_browse, library_copy, create_script, list_scripts, get_script, test_script, delete_script). The current SKILL.md is approximately 70% orchestration by section count, but the design sections carry greater conceptual density — DAG patterns, complementarity decisions, script authoring protocols, promotion gates, LoRA flagging.

---

## The Architecture That Emerged

Four layers, each with a distinct concern:

**Orchestration (conductor skill).** Claude decomposes tasks, classifies delegability, routes to ensembles or handles directly, invokes, evaluates, tracks tokens, adapts during execution. Owns the workflow lifecycle. Runs on Sonnet for speed. The existing SKILL.md's triage, routing, invocation, evaluation, and workflow planning sections remain here, tightened to focus exclusively on orchestration.

**Design (ensemble designer skill).** Claude selects DAG architectures, chooses profiles (including complementarity measurement), authors scripts, composes and validates ensembles, interprets calibration data, manages promotion. Owns ensemble quality and the design pattern library. Runs on Opus for architectural judgment. Absorbs the SKILL.md's Ensemble Composition, Ensemble Promotion, and LoRA Candidate Flagging sections.

**Verification (script agents with classical ML).** Lightweight embedded models — MiniLM for embeddings, DeBERTa for NLI, numpy for log-prob entropy — provide deterministic quality signals within ensemble DAGs. Replaces LLM self-verification. Enables confidence-based selection for complementary model arbitration. These are building blocks in the designer's pattern library, instantiated as script agents in ensemble DAGs.

**Memory (Plexus knowledge graph).** Provenance tracking, design knowledge accumulation, cross-project meta-learning. Both the conductor and designer read and write to the graph. The conductor logs routing decisions and evaluation results. The designer logs ensemble specifications and calibration interpretations. The graph enables traversal queries that flat storage cannot: "what led to this outcome," "what has worked for similar tasks," "which ensembles are ready for promotion."

The layers interact through defined interfaces. The conductor requests ensembles from the designer and provides evaluation feedback. The designer builds ensembles using verification-layer building blocks and publishes them for the conductor to invoke. Both read from and write to the memory layer. The user gates transitions between conductor and designer, just as in RDD.

---

## Tensions with Existing Invariants

The research findings create several tensions with the current domain model that require decisions.

**Invariant 3 (Composition over scale, 12B ceiling).** The research supports the spirit of this invariant — composition of many small models beats reaching for larger ones. But inference scaling laws show a crossover: on harder tasks, a single 14B model eventually outperforms two 7B models at equal compute. The practical question is whether the 12B ceiling should be 14B, given that qwen3:14b is available and synthesis across 4+ upstream outputs may genuinely benefit from the additional capacity. The invariant's principle (composition over scale) is validated; the specific number may need adjustment.

**Invariant 10 (Two-level competence boundaries).** The research validates and extends this invariant. The three-category taxonomy (agent-delegable, ensemble-delegable, Claude-only) is well-supported. But Q6's verification layer adds a dimension: script agents with classical ML can provide quality signals that change what is practically ensemble-delegable. The DAG decomposability test might account for ML-equipped script agents as a capability that expands ensemble-level competence.

**Invariant 12 (The conductor is the workflow architect).** If ensemble design moves to a separate skill, this invariant narrows: the conductor remains the workflow architect for orchestration, but is no longer the sole architect for ensemble composition. The designer would own ensemble architecture. This is a scope change, not a contradiction — the invariant's intent (the conductor owns the workflow) is preserved.

**New concepts not in the domain model.** The research introduces several concepts that would need to be added: verification layer, confidence-based selection, architectural complementarity, design pattern library, knowledge graph memory, provenance, meta-learning. These are extensions, not contradictions, but they significantly expand the model's surface area.

These tensions are not blockers — they are design decisions that the modeling and decision phases should address.

---

## What This Means

The evidence does not choose between Strategy A and Strategy B. It dissolves the binary.

Strategy A's core insight is correct: purpose-built ensembles orchestrated by a capable external model outperform general-purpose self-routing ensembles for SLMs. The evidence for this is strong and convergent across multiple independent research lines. Strategy B's core insight is also correct: architectural complementarity, confidence-based arbitration, and cascade patterns are valuable design techniques. The error in Strategy B is not in the patterns it proposes but in where it places them — inside the ensemble's routing logic, where small models cannot reliably execute them, rather than in the design process that produces the ensemble and the verification layer that assesses its outputs.

The synthesis is: Claude orchestrates (Strategy A's architecture), ensembles are purpose-built (Strategy A's specificity), complementarity and cascades are design patterns applied by the ensemble designer (Strategy B's techniques), and classical ML in script agents provides the verification that small models cannot provide for themselves (neither strategy's contribution — a new layer entirely).

The laboratory framing ties it together. Every purpose-built ensemble is an experiment. The calibration loop already captures quality data. A separate ensemble designer skill, backed by a knowledge graph, systematically accumulates what works — which DAG shapes, which model pairs, which script patterns, which verification techniques — across tasks and projects. This is not just infrastructure for getting work done. It is a learning system that gets better at building instruments with each instrument it builds.

---

## Sources

### Task-Specific vs. General-Purpose Pipelines
- RouteLLM: Ong et al., ICLR 2025 (arXiv:2406.18665)
- Routing Collapse: Lai & Ye, 2025 (arXiv:2602.03478)
- DisCIPL: MIT/Yale, 2025
- SLM-MUX: Wang et al., 2025 (arXiv:2510.05077)
- FrugalGPT: Chen & Zaharia, TMLR 2024 (arXiv:2305.05176)
- Cascade Routing: Dekoninck et al., ETH Zurich, ICLR 2025 (arXiv:2410.10347)
- Distil Labs SLM Benchmark, 2025
- Belcak & Heinrich, NVIDIA, 2025 (arXiv:2506.02153)
- RouterArena, 2025 (arXiv:2510.00202)

### External vs. Internal Routing
- Google DeepMind Scaling Agent Systems, 2025 (arXiv:2512.08296)
- AutoMix: Aggarwal & Madaan, NeurIPS 2024 (arXiv:2310.12963)
- Small LMs Need Strong Verifiers, 2024 (arXiv:2404.17140)
- ModelSwitch, 2025 (arXiv:2504.00762)
- SCORE, Harvard, ICLR 2025

### Architectural Complementarity
- Rethinking Mixture-of-Agents, 2025 (arXiv:2502.00674)
- Debate or Vote, NeurIPS 2025 (arXiv:2508.17536)
- Correlated Errors in LLMs, 2025 (arXiv:2506.07962)
- Inference Scaling Laws, 2024 (arXiv:2408.00724)
- Wisdom and Delusion of LLM Ensembles for Code, 2025 (arXiv:2510.21513)

### Classical ML in Script Agents
- BERTScore: WMT 2025; ExPerT, ACL 2025
- Semantic Self-Consistency, 2024 (arXiv:2410.07839)
- SelfCheckGPT, 2023 (arXiv:2303.08896)
- LiLaVe, 2025 (arXiv:2504.16760)
- ELHSR, 2025 (arXiv:2505.12225)
- Semantic Entropy Probes, ICLR 2025 (arXiv:2406.15927)

### Knowledge Graph Memory
- Zep/Graphiti, 2025 (arXiv:2501.13956)
- A-MEM, 2025 (arXiv:2502.12110)
- AIMKG, HPE, Frontiers in Big Data 2024
- SkewRoute, EMNLP 2025
- MetaKG, IEEE TKDE 2022 (arXiv:2202.03851)
- yProv4ML, 2025 (arXiv:2507.01075)

### Surveys
- "Doing More with Less" LLM Routing Survey, 2025 (arXiv:2502.00409)
- SLM-LLM Collaboration Survey, 2025 (arXiv:2510.13890)
- Memory in the Age of AI Agents, 2025 (arXiv:2512.13564)
