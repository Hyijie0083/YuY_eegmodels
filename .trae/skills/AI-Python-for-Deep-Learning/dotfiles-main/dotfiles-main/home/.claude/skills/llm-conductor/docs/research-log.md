# Research Log: Purpose-Built vs. General-Purpose Ensemble Composition

## Question 1: Does the evidence favor task-specific purpose-built pipelines or general-purpose self-routing ensembles for SLMs under ~14B?

**Method:** Web search across routing systems, ensemble architectures, cascade designs, fine-tuning benchmarks, and surveys (2023-2025). Targeted: RouteLLM, FrugalGPT, AutoMix, SLM-MUX, DisCIPL, MixLLM, Cascade Routing, Speculative Cascades, NVIDIA SLM agents survey, SLM-LLM Collaboration Survey, RouterArena.

**Findings:**

The evidence converges strongly: **task-specific pipeline compositions outperform general-purpose self-routing ensembles for SLMs under ~14B**. But the nuance matters — the strongest systems are heterogeneous, task-aware, and structured as pipelines with escalation.

### Key evidence points

1. **General-purpose routers fail out-of-distribution.** RouteLLM (UC Berkeley/Anyscale, ICLR 2025): routers trained on 65K chatbot preference pairs performed at near-random on MMLU. Adding just ~1,500 task-specific samples fixed it. General routers generalize across model pairs but NOT across task domains.

2. **Routing collapse is real.** Lai & Ye (2025): general-purpose routers systematically default to the most expensive model. Root cause: scalar score prediction creates an "objective-decision mismatch" — small prediction errors flip orderings for closely-matched models. Rank-based routing (EquiRouter) reduces cost ~17%.

3. **Fine-tuned SLMs dramatically outperform general-purpose models on specific tasks.** Distil Labs: Qwen3-4B matched a 120B teacher on 7/8 tasks, outperformed by 19 points on SQuAD 2.0. A 0.6B model: 90.9% accuracy vs. 87.5% for the 120B teacher at 40ms latency.

4. **Optimal ensemble composition is task-dependent.** SLM-MUX (2025): optimal model count varies by benchmark — 2 for GPQA/GSM8K, 5+ for MATH. What makes models complementary (union accuracy vs. contradiction penalty) is task-specific. No single ensemble configuration works universally.

5. **Task-specific decomposition + SLM followers beats GPT-4o.** DisCIPL (MIT/Yale, 2025): a 1B model with task-specific program generation jumped from 0.07 to 0.76 on constrained generation, dramatically outperforming GPT-4o (0.32). 80.2% cost savings.

6. **Cascade architectures work best with task-specific stopping criteria.** FrugalGPT: 98% cost reduction with learned per-task quality scoring. Cascade Routing (ETH Zurich, ICLR 2025): optimal strategy is task-dependent — the framework derives different configurations for different quality/cost tradeoffs.

7. **The industry consensus is moving to heterogeneous multi-SLM systems.** Belcak & Heinrich (NVIDIA, 2025): "Lego-like composition of agentic intelligence — scaling out by adding small, specialized experts instead of scaling up." Case studies: 40-70% of agent invocations replaceable by SLMs.

8. **No single router dominates across all metrics.** RouterArena (2025): 8,400 queries across 9 domains. GPT-5 ranks 7th, NotDiamond ranks 12th. The tradeoff surface is inherently task-dependent.

### What this means for the two strategies

**Strategy A (llm-conductor SKILL.md):** Claude as orchestrator, purpose-built ensembles per task type. Each ensemble is a bespoke DAG designed for one job. The conductor is the intelligence; the ensemble is the instrument.

**Strategy B (synthesis):** General-purpose ensembles with internal routing (classifier → parallel analysts → synthesizer). The ensemble internalizes its own task awareness. Claude is one composable profile among several.

The evidence favors Strategy A's core premise: **task-specific compositions outperform general-purpose ones**. But Strategy B contributes valid patterns that A should absorb:

- **Architectural complementarity** (Qwen + Mistral on the same task) is well-supported by SLM-MUX's "union accuracy" evidence
- **Confidence-based cascade** (cheap first, escalate when confidence is low) is well-supported by FrugalGPT, AutoMix, Cascade Routing
- **Role-based profiles** (router, analyst, reasoner, synthesizer) carry more semantic information than tier-based profiles

### What neither strategy addresses: the laboratory

Both strategies treat ensemble design as a means to an end (getting work done). But if purpose-built ensembles are systematically better, then **the process of building them is the most valuable activity** — not just as infrastructure, but as a learning loop. Every ensemble created is an experiment that generates data about what works: which profiles, which DAG shapes, which script patterns, which task decompositions.

This connects to a question the user raised: the RDD skill decomposition approach — separate skills for research, modeling, decision, and building — might apply here. The conductor currently does both ensemble *design* and workflow *orchestration*. These are different concerns with different knowledge requirements.

**Implications:**
- Strategy A is the stronger foundation, but should absorb Strategy B's complementarity and cascade patterns
- The "laboratory" framing reframes ensemble creation from overhead to learning investment
- The skill-split question (conductor vs. ensemble designer) needs its own investigation
- The model profiles in the synthesis need updating to match available models (qwen3 family, not qwen2.5)

**Sources:**
- RouteLLM: arXiv:2406.18665 (ICLR 2025)
- Routing Collapse: arXiv:2602.03478
- "Doing More with Less" Survey: arXiv:2502.00409
- Distil Labs SLM Benchmark: distillabs.ai/blog
- DisCIPL: MIT/Yale (MarkTechPost coverage)
- SLM-MUX: arXiv:2510.05077
- FrugalGPT: arXiv:2305.05176 (TMLR 2024)
- Cascade Routing: arXiv:2410.10347 (ICLR 2025)
- AutoMix: arXiv:2310.12963 (NeurIPS 2024)
- MixLLM: NAACL 2025
- Speculative Cascades: arXiv:2405.19261 (ICLR 2025)
- Belcak & Heinrich (NVIDIA): arXiv:2506.02153
- SLM-LLM Collaboration Survey: arXiv:2510.13890
- RouterArena: arXiv:2510.00202

---

## Question 2: Where should routing intelligence live — external orchestrator, internal self-routing, or hybrid?

**Method:** Web search across multi-agent frameworks (LangGraph, CrewAI, MetaGPT, AutoGen, OpenAI Swarm, Google ADK), trained routers (RouteLLM, xRouter, Router-R1, MixLLM, SCORE), self-routing systems (AutoMix, ModelSwitch, Self-REF), hybrid systems (FrugalGPT, Cascade Routing, MoA), and the Google DeepMind scaling agent systems study.

**Findings:**

### The DeepMind study settles it for our use case

Google DeepMind's "Towards a Science of Scaling Agent Systems" (2025) — 3,975 cases across 4 benchmarks — provides the most comprehensive empirical comparison:

| Architecture | Error Amplification | Token Overhead |
|---|---|---|
| Single Agent | 1x (baseline) | 1x |
| Independent Multi-Agent | 17.2x | 1.58x |
| Centralized (orchestrator) | 4.4x | 2.85x |
| Decentralized | varies | 2.63x |
| Hybrid | varies | 5.15x |

**Critical finding: "Orchestrator capability dominates overall system performance."** The quality of the routing agent matters more than the quality of the worker agents. Centralized two-stage planning achieves the best accuracy-efficiency tradeoff. A predictive model correctly identifies the optimal coordination strategy for 87% of unseen task configurations.

### Small models cannot reliably self-route

The evidence is consistent: **SLMs under ~13B are poor self-verifiers.**

- AutoMix (NeurIPS 2024) exists precisely because self-verification signals from small models are too noisy — hence the POMDP formulation to handle uncertainty.
- "Small Language Models Need Strong Verifiers to Self-Correct Reasoning" (2024): models at 13B and below cannot reliably judge their own output quality.
- ModelSwitch uses self-consistency (agreement across samples) rather than self-verification — a simpler signal that works better for small models.

### The three patterns mapped to our architecture

**External orchestrator (Claude as conductor):**
- Validated by DeepMind study, RouteLLM, xRouter, Router-R1, MixLLM, SCORE
- Lowest error amplification (4.4x vs 17.2x for independent)
- High debuggability (explicit routing decisions)
- For our system: Claude makes all triage/routing/evaluation decisions

**Internal self-routing (ensemble routes itself):**
- Fails for SLMs under ~13B due to self-verification limitations
- AutoMix's POMDP is a workaround, not a validation of the pattern
- For our system: ensembles should NOT contain their own routing logic

**Hybrid (FrugalGPT pattern):**
- External router for model selection order + internal quality judgment for stopping
- Cascade Routing (ETH Zurich): combining routing + cascading improves performance 8-14% over either alone
- For our system: the conductor routes externally; within an ensemble, simple confidence signals (self-consistency, not self-verification) can trigger escalation

### Router overhead for small models

| System | Router Type | Overhead | Cost Reduction |
|---|---|---|---|
| RouteLLM (BERT) | Classifier | 1-10ms | 85% |
| xRouter | 7B LLM | Full inference pass | 60-80% |
| AutoMix | Self-verification | ~0 latency | 50% |
| MixLLM | Lightweight predictor | Low ms | 76% |
| SCORE | Prediction layer | Low ms | 63% |

For SLMs specifically, router overhead is a meaningful fraction of total inference cost. A BERT-class classifier (1-10ms) is negligible. A 7B router is expensive but justified for expensive downstream calls. Self-verification is essentially free but unreliable under 13B.

### Implications for the conductor

1. **Claude as external orchestrator is empirically validated.** The DeepMind study's finding that orchestrator capability dominates system performance directly supports the SKILL.md's architecture.

2. **Ensembles should be stateless executors, not self-routing systems.** The synthesis's "classifier → analysts → synthesizer" pattern puts routing inside the ensemble. The evidence says this is wrong for SLMs — the classifier agent would need to be a capable self-verifier, which small models aren't.

3. **Within-ensemble confidence signals should be simple.** Self-consistency (do multiple samples agree?) works. Self-verification (is my output correct?) doesn't, under 13B. If an ensemble needs escalation logic, it should use agreement-based signals, not quality-assessment signals.

4. **The conductor's routing intelligence is a feature, not overhead.** Claude's ability to triage, evaluate, and adapt is the system's competitive advantage. Pushing routing into the ensemble would degrade it.

**Sources:**
- Google DeepMind Scaling Agent Systems: arXiv:2512.08296
- AutoMix: arXiv:2310.12963 (NeurIPS 2024)
- Small LMs Need Strong Verifiers: arXiv:2404.17140
- Self-Verification Limitations: arXiv:2402.08115
- ModelSwitch: arXiv:2504.00762
- RouteLLM: arXiv:2406.18665
- xRouter (Salesforce): arXiv:2510.08439
- Router-R1 (UIUC, NeurIPS 2025): arXiv:2506.09033
- MixLLM: NAACL 2025
- SCORE: ICLR 2025
- FrugalGPT: arXiv:2305.05176
- Cascade Routing (ETH Zurich): arXiv:2410.10347
- LangGraph, CrewAI, MetaGPT, AutoGen, OpenAI Swarm, Google ADK (framework documentation)

---

## Question 3: Is architectural complementarity (running two different model architectures on the same task) validated for SLMs under ~14B?

**Method:** Web search targeting SLM-MUX follow-ups, model diversity in ensembles, agreement-based confidence, voting vs. synthesis, correlated errors, and inference scaling laws.

**Findings:**

### Direct validation: SLM-MUX

SLM-MUX (Wang et al., Oct 2025) is the strongest direct evidence. Tested on Llama 3.1 8B, Qwen2.5 7B, Mixtral 8x7B, Mistral Small 24B, Gemma 2 27B:

- **Mechanism:** Independent generation (models never see each other's output). Each SLM generates k samples at temperature > 0. Confidence = frequency of most common answer per model. Downstream selector picks the most confident model's answer.
- **Results:** Two SLMs outperform Qwen 2.5 72B on GPQA and GSM8K. Best pairs: Mistral Small 24B + Qwen2.5 7B on MATH (+4.5%), GPQA (+4.4%), GSM8K (+4.3%).
- **Key metric:** Union accuracy (at least one model is right) minus contradiction penalty (one model confidently wrong while another is right).
- **Critical finding:** Model selection matters more than model count. Bad pairs actively hurt.

### The mechanism matters: selection vs. synthesis

**Confidence-based selection works.** SLM-MUX picks ONE winner based on confidence. The weak model's output is simply not chosen. This avoids contamination.

**Synthesis (merging outputs) is riskier.** "Rethinking Mixture-of-Agents" (Feb 2025): Self-MoA (same model repeated) outperforms mixed-model MoA by 6.6% on AlpacaEval 2.0. Why? When a synthesizer reads both outputs, weak model outputs contaminate the synthesis. Quality coefficient (alpha=2.558) significantly exceeds diversity coefficient (beta=1.841).

**This is a task-type distinction:**
- For **reasoning/verification tasks** (MATH, GPQA, GSM8K): complementarity + confidence selection → strong gains
- For **open-ended generation tasks** (AlpacaEval): quality > diversity → self-MoA beats mixed-MoA

### Independent + arbitrate beats debate

Multiple independent confirmations:
- "Debate or Vote" (NeurIPS 2025 spotlight): multi-agent debate induces a martingale — it doesn't systematically improve beliefs. On GSM8K with Qwen2.5-7B: voting = 0.9400, debate = 0.8533. **Voting beat debate.**
- "Can LLM Agents Really Debate?" (Nov 2025): "Current MAD methods fail to consistently outperform simpler single-agent strategies." Eloquent but incorrect agents sway correct ones.

This validates the SKILL.md's existing approach: agents never see each other's output, only the synthesizer does.

### Correlated errors bound the benefit

"Correlated Errors in Large Language Models" (Jun 2025): On leaderboard datasets, models agree 60% of the time when both err (vs 33% random baseline). Cross-family correlation is substantial (0.9987 agreement between unrelated models on some metrics). **Architectural diversity helps but doesn't guarantee decorrelated errors.** The benefit is real but bounded.

### Cost: 2x7B vs. 1x14B

Inference Scaling Laws (Aug 2024): "Llemma-7B achieves competitive accuracy to Llemma-34B while using approximately 2x fewer FLOPs." Smaller models dominate at constrained compute budgets. **Crossover exists:** on harder tasks, the larger model eventually wins. The practical sweet spot depends on task difficulty distribution.

### Implications for ensemble design

1. **Complementarity is a validated pattern for SLMs** on reasoning/verification tasks, with confidence-based selection as the arbitration mechanism.

2. **It should NOT be the default for all ensembles.** For generation/synthesis tasks, running one better model beats running two different ones. The task type determines whether complementarity helps.

3. **The ensemble designer (not the conductor) should decide when to apply complementarity.** It's a design-time decision about DAG shape, not a runtime routing decision.

4. **When applied, use confidence-based selection, not synthesis.** Pick the winner; don't try to merge. This avoids the contamination problem from "Rethinking MoA."

5. **Measuring complementarity requires experimentation.** You can't know a priori whether Qwen3 + Mistral will be complementary on YOUR task. This is another argument for the "laboratory" framing — you need to build, calibrate, and learn which pairs work for which tasks.

**Sources:**
- SLM-MUX: arXiv:2510.05077
- Rethinking Mixture-of-Agents: arXiv:2502.00674
- Debate or Vote (NeurIPS 2025): arXiv:2508.17536
- Correlated Errors in LLMs: arXiv:2506.07962
- Scaling Laws for Compound Inference: arXiv:2403.02419
- Wisdom and Delusion of LLM Ensembles for Code: arXiv:2510.21513
- LLM-TOPLA (EMNLP 2024): arXiv:2410.03953
- Complementary-MoA (NeurIPS 2025)
- Inference Scaling Laws: arXiv:2408.00724
- Zero-Shot SLM Ensembles for Sentiment Analysis (2025)
- Can LLM Agents Really Debate? arXiv:2511.07784

---

## Question 4: What's the right decomposition boundary between an ensemble designer skill and the conductor?

**Method:** Analysis — applying the RDD skill decomposition pattern to the conductor's two concerns (orchestration vs. ensemble design), informed by MCP tool categorization, Q1-Q3 evidence, and the "laboratory" framing.

**Findings:**

### The RDD pattern as structural template

The RDD skills decompose by **mode of thinking**, not by step count:

| Skill | Mode | Produces | Consumes |
|---|---|---|---|
| `/rdd-research` | Divergent exploration | Essay (forcing function for understanding) | User questions |
| `/rdd-model` | Naming and bounding | Domain model (constitutional authority) | Essay |
| `/rdd-decide` | Committing to choices | ADRs + scenarios | Domain model + essay |
| `/rdd-build` | Executing to spec | Working code + tests | Scenarios + ADRs + domain model |
| `/rdd` (parent) | Orchestrating gates | Flow control | Phase artifacts |

Key structural properties:
- Each skill owns ONE concern, coordinates via artifacts
- Artifacts are forcing functions (you don't understand it until you can explain it)
- Three authority layers: invariants > ADRs > scenarios
- The parent skill is lightweight — gates and flow, not execution
- Backward jumps are first-class (building reveals flaws → rewind)

### The conductor's two concerns mapped

The current SKILL.md contains 15 MCP tools for ensemble design vs. 7 for orchestration. By section, it's ~70% orchestration, ~30% design. But those percentages are misleading — the design sections carry more conceptual density (DAG patterns, complementarity, script authoring, calibration interpretation, promotion gates, LoRA flagging).

**Orchestration mode** (operational/evaluative):
- Decompose meta-tasks into subtasks
- Classify delegability (agent-delegable, ensemble-delegable, Claude-only)
- Route to existing ensembles or Claude
- Invoke ensembles, track tokens
- Sample and evaluate quality
- Adapt during execution (fallback on poor scores)
- Learn across sessions (task profiles, routing config)

**Design mode** (creative/architectural):
- Choose DAG shapes and template architectures
- Select profiles for complementarity (Q3 evidence: this requires task-specific measurement)
- Author scripts for multi-stage ensembles
- Validate ensembles, verify runnability
- Interpret calibration data, recommend improvements
- Assess promotion readiness, manage cross-tier dependencies
- Accumulate design knowledge (what works for which task types)

These are genuinely different modes of thinking. Orchestration is about *dispatching work efficiently*. Design is about *building instruments well*.

### The handoff pattern

Applying the RDD artifact-based handoff model:

```
Conductor → Designer: "I need an ensemble for {task type}.
  Constraints: {available models, task examples, output format}."

Designer → Conductor: "Here is ensemble '{name}', validated and ready.
  Pattern: {swarm | multi-stage}. Profiles: {list}. Scripts: {list}."

Conductor → Designer (feedback loop): "Calibration data: {N} invocations,
  {scores}. Failure modes: {list}."

Designer → Conductor: "Revised ensemble '{name}'. Changes: {list}."
```

The conductor produces **routing needs and evaluation data**. The designer produces **validated ensembles and design knowledge**. Neither needs the other's internals — they coordinate via artifacts.

### What each skill would own

**llm-conductor** (the orchestrator):
- Task decomposition and workflow planning
- Delegability triage (three-category taxonomy)
- Routing decisions (standing auth, task profiles, available ensembles)
- Ensemble invocation and token tracking
- Quality evaluation and calibration management
- Workflow execution, adaptation, session wrap-up
- Routing config management and versioning
- MCP tools: `set_project`, `invoke`, `analyze_execution`, `list_ensembles`, `get_provider_status`, `list_profiles`, `check_ensemble_runnable`

**llm-ensemble-designer** (the instrument builder):
- DAG architecture selection (swarm, multi-stage, template matching)
- Profile selection and complementarity measurement
- Script authoring for multi-stage ensembles
- Ensemble validation and runnability verification
- Calibration interpretation and ensemble improvement
- Promotion assessment and cross-tier management
- Pattern library accumulation (design knowledge)
- MCP tools: `create_ensemble`, `validate_ensemble`, `create_profile`, `update_ensemble`, `promote_ensemble`, `check_promotion_readiness`, `list_dependencies`, `demote_ensemble`, `library_browse`, `library_copy`, `create_script`, `list_scripts`, `get_script`, `test_script`, `delete_script`

### The laboratory framing: what separation enables

With a separate designer skill, ensemble creation becomes a **first-class research activity**, not a subordinate task within orchestration. The designer can:

1. **Maintain its own knowledge base** — which DAG shapes work for which task types, which model pairs are complementary, which script patterns are reusable. This is analogous to `/rdd-model`'s domain model.

2. **Run its own evaluation loop** — not just "did the ensemble produce good output?" (the conductor's question) but "why did this design work and that one didn't?" (a design question). The conductor collects calibration data; the designer interprets it.

3. **Evolve design heuristics independently** — the evidence from Q3 (complementarity is task-dependent, confidence selection beats synthesis for reasoning tasks) becomes design knowledge that persists across projects. Each ensemble built is an experiment.

4. **Separate creation cadence from execution cadence** — the conductor needs to be fast (every invocation). The designer can be thoughtful (when building or improving ensembles). These different time pressures map to different model selections: conductor work can use Sonnet for speed, designer work benefits from Opus for architectural judgment.

### The tension: on-demand creation during workflow execution

The main argument against splitting is **tight coupling during workflow planning.** When the conductor identifies a gap (Step 2: "no ensemble for this task type"), it currently composes one on the spot. Splitting means a skill handoff mid-workflow.

But the RDD pattern handles this. `/rdd-build` can trigger a backward jump to `/rdd-decide` when implementation reveals a flaw. Similarly:

- The conductor identifies a gap during workflow planning
- The conductor invokes the designer: "I need an ensemble for {task type}"
- The designer composes, validates, returns to the conductor
- The conductor continues the workflow

This is not fundamentally different from how `/rdd` coordinates its phases. The overhead is a skill invocation, not a context switch — the conductor retains its workflow state.

### The split also clarifies the synthesis's contribution

The synthesis's general-purpose ensembles (general-analysis, document-research, code-review) are **designer artifacts** — they represent design decisions about DAG shape, profile selection, and complementarity. The evidence says these should be purpose-built per task type, not general-purpose. But the *design patterns* they encode (parallel complementary analysts, script anchoring, cascade escalation) are valuable as **templates in the designer's pattern library**.

The synthesis was right about *how to design ensembles*. It was wrong about *how broadly to scope them*. A separate designer skill is the right place to capture that design knowledge without conflating it with the conductor's routing logic.

### Proposed skill structure

| Skill | Analogy | Mode | Invoked by |
|---|---|---|---|
| `llm-conductor` | `/rdd` parent + `/rdd-build` | Orchestrate + execute | User directly |
| `llm-ensemble-designer` | `/rdd-research` + `/rdd-decide` | Understand + architect | Conductor (on-demand) or user directly |

The conductor is both the parent orchestrator AND the executor (unlike RDD where `/rdd` and `/rdd-build` are separate). This makes sense — the conductor's execution is lightweight (invoke and evaluate), not heavy like code implementation.

The designer combines understanding (what DAG shape fits?) with architecture (how should this ensemble be structured?). This also makes sense — ensemble design is a compact enough activity that it doesn't need further decomposition.

### What doesn't need to split

- **Pre-flight discovery** stays in the conductor — it's operational information gathering for routing decisions
- **Evaluation and reflection** stays in the conductor — it's quality assessment during execution
- **Token tracking** stays in the conductor — it's an execution concern
- **Persistence** is shared — both skills read/write to `.llm-orc/evaluations/`, with the conductor owning routing logs and the designer owning design knowledge

### Implications

1. **The conductor SKILL.md shrinks by ~30%** — the Ensemble Composition and Ensemble Promotion sections move to the designer, along with LoRA candidate flagging.

2. **The designer skill inherits the synthesis's best patterns** — template architectures, complementarity measurement, confidence-based vs. synthesis-based arbitration selection — as part of its design knowledge base.

3. **The "laboratory" is the designer's evaluation loop** — every ensemble built generates data about what works. The designer accumulates this across projects (via promotion to global tier and library).

4. **The conductor becomes more focused** — its invariants can be tighter because they only cover orchestration. Design invariants (like the 12B ceiling, composition over scale) move to the designer.

5. **Model selection maps naturally** — the conductor can run on Sonnet (fast routing and evaluation). The designer should run on Opus (architectural judgment, script authoring). This matches the CLAUDE.md guidance: "Opus is the writer and architect, not the bricklayer."

**Sources:**
- RDD skill decomposition analysis (rdd.md, rdd-research.md, rdd-model.md, rdd-decide.md, rdd-build.md)
- Conductor MCP tool categorization (SKILL.md section-by-section analysis)
- Q1-Q3 findings from this research cycle

---

## Question 5: Can a knowledge graph with provenance (Plexus) serve as shared memory between the conductor and ensemble designer?

**Method:** Web search across KG-based agent memory, ML experiment provenance, pipeline optimization metadata, meta-learning with KGs, and AI ontologies.

**Findings:**

### Graph structure provides capabilities flat storage cannot

| Capability | Flat JSONL/YAML | Knowledge Graph | Evidence |
|---|---|---|---|
| Pipeline recommendation accuracy | 51% | 78% | AIMKG, Frontiers in Big Data 2024 |
| Multi-hop reasoning | Baseline | ~2x improvement | A-MEM, 2025 |
| Token efficiency for retrieval | Baseline | 85-93% reduction | A-MEM |
| Temporal reasoning | Timestamp sort | +38.4% | Zep/Graphiti, 2025 |
| Expensive model call reduction | N/A | 40% via KG-informed routing | SkewRoute, EMNLP 2025 |
| Fine-grained lineage reuse | Manual | 12.4x speedup | LIMA, SIGMOD 2021 |

### Three roles for the KG

**1. Provenance layer.** W3C PROV maps to our entities: ensemble specs = Entities, calibration runs = Activities, routing decisions = Activities that `used` specific configurations. Zep/Graphiti's bi-temporal model tracks both when an ensemble was valid and when we learned about its performance. When the conductor gets a poor result, tracing back (which spec, which profiles, what changed?) is a graph traversal — flat logs require manual reconstruction every time.

**2. Design knowledge accumulation.** AIMKG (HPE, 2024) — 1.6M pipeline metadata KG — achieves 76.3% retrieval accuracy for recommending pipeline configurations. For the designer: "For tasks similar to X, which DAG shapes, profile combinations, and script patterns produced best calibration results?" is a similarity + graph traversal query.

**3. Cross-project meta-learning.** MetaKG (IEEE TKDE, 2022) shows KGs enable cold-start decisions via structured knowledge about related tasks. Trainable Graph Memory (2025) showed 25.8% improvement specifically for smaller/less-capable systems. This is the "laboratory at scale."

### Implementation path with Plexus

- **Node types:** Task, Ensemble, Profile, Script, CalibrationRun, RoutingDecision, EvaluationResult, TaskProfile
- **Edge types:** `usedEnsemble`, `producedResult`, `calibratedBy`, `promotedFrom`, `designedFor`, `complementaryWith`, `replacedBy`
- **Provenance edges:** W3C PROV (`wasGeneratedBy`, `used`, `wasDerivedFrom`, `wasInformedBy`)
- **Temporal model:** Bi-temporal (validity time + knowledge time)
- Flat JSONL becomes the write-ahead log; KG becomes the queryable memory

### Implications

1. **53% improvement in pipeline recommendation** is not marginal — Plexus is a structurally better substrate than flat files.
2. **Design knowledge is inherently relational** (this DAG shape works for this task type with these profiles). Graphs represent relations natively.
3. **Cross-project learning becomes native** rather than manual file promotion.
4. **The laboratory gets its infrastructure** — full provenance chain from task → design → ensemble → calibration → evaluation → promotion.
5. **Incremental adoption is viable** — provenance first, then recommendation, then meta-learning.

**Sources:**
- Zep/Graphiti: arXiv:2501.13956
- A-MEM: arXiv:2502.12110
- Trainable Graph Memory: arXiv:2511.07800
- yProv4ML: arXiv:2507.01075
- AIMKG (HPE): Frontiers in Big Data 2024
- SkewRoute: EMNLP 2025
- MetaKG: IEEE TKDE 2022
- AI Ontology: 2024

---

## Question 6: What classical ML techniques can script agents employ to improve ensemble results?

**Method:** Web search across embedding evaluation, trained classifiers, NLI validation, hallucination detection, clustering, process reward models, and statistical methods.

**Findings:**

### Script agents can host lightweight ML that solves the self-verification problem

Q2 established SLMs under ~13B can't self-verify. Script agents with embedded ML models (~80-170MB) provide quality signals that are cheaper, faster, and more reliable than additional LLM inference.

### Priority-ordered techniques

**Tier 1: Zero additional cost**

| Technique | How | Evidence |
|---|---|---|
| Log-prob entropy | Compute per-token entropy from logprobs with numpy | Available from any local model exposing logprobs |
| Exact-match voting | Regex + Counter on extracted answers | Self-Consistency (Wang et al., ICLR 2023) |

**Tier 2: Small embedding model (~80MB, ~4k/sec CPU)**

| Technique | Model | Evidence |
|---|---|---|
| BERTScore/cosine similarity | all-MiniLM-L6-v2, 22M params, ONNX native | 0.759-0.904 correlation with human judgment (WMT 2025) |
| Semantic Self-Consistency | MiniLM embeddings + centroid proximity weighting | Outperforms naive majority voting (arXiv:2410.07839) |
| Semantic clustering | MiniLM + scikit-learn KMeans/DBSCAN | Outlier detection, consensus identification |

**Tier 3: Small NLI model (~170MB quantized, ~10-50ms CPU)**

| Technique | Model | Evidence |
|---|---|---|
| NLI consistency validation | DeBERTa-v3-base, 86M params, ONNX | SelfCheckGPT: 92.50 AUC-PR for non-factual detection |
| Zero-shot classification | Same DeBERTa, no training needed | 9.4% improvement over prior zero-shot (HuggingFace) |

**Tier 4: Hidden state access (high impact, medium effort)**

| Technique | Method | Evidence |
|---|---|---|
| XGBoost on hidden states | LiLaVe pattern | Outperforms neural alternatives (arXiv:2504.16760) |
| Linear probes | PCA + LDA (ELHSR) | <0.005% of reward model parameters (arXiv:2505.12225) |
| Hallucination detection | EigenScore (eigenvalue decomposition) | Pure linear algebra, no model needed |

### How this integrates with ensemble design

These techniques become script agent building blocks in the ensemble DAG:

**Complementary model arbitration (solves Q3's mechanism question):**
```
LLM-A (qwen3) ──→ script: embed + confidence ──→ script: select winner
LLM-B (mistral) → script: embed + confidence ──↗   (deterministic)
```

Instead of a synthesizer LLM judging which output is better (self-verification, which fails for SLMs), a script agent with MiniLM computes embedding-based confidence and selects — deterministically.

**Quality gate pattern:**
```
LLM agent → script: NLI consistency check → pass/fail gate → next stage
                                              ↓ (fail)
                                         escalation to conductor
```

**Escalation trigger:**
```
LLM agent → script: log-prob entropy → below threshold → continue
                                        above threshold → route to Claude
```

### Implications

1. **Script agents are dramatically underutilized.** With ~80-170MB embedded models, they solve the self-verification gap from Q2.
2. **Complementarity arbitration becomes deterministic.** No LLM judgment needed for output selection — embedding-based confidence replaces synthesizer-as-judge.
3. **The ensemble designer's toolkit expands.** Confidence scripts, NLI scripts, similarity scripts join the pattern library alongside LLM agent profiles.
4. **Hidden state access is the high-value architectural investment** for llm-orc — enables Tier 4 techniques.

**Sources:**
- BERTScore: WMT 2025; ExPerT (ACL 2025)
- Semantic Self-Consistency: arXiv:2410.07839
- SelfCheckGPT: arXiv:2303.08896
- DeBERTa zero-shot NLI: HuggingFace MoritzLaurer
- LiLaVe: arXiv:2504.16760
- ELHSR: arXiv:2505.12225
- EigenScore: arXiv:2510.08389
- Semantic Entropy Probes: arXiv:2406.15927
- all-MiniLM-L6-v2: HuggingFace ONNX
