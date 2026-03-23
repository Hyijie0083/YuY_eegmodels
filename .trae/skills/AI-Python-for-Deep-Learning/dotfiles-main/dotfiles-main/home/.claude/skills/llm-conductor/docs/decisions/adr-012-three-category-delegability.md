# ADR-012: Three-Category Delegability with DAG Decomposability Test

**Status:** Accepted — amends ADR-002 (routing mechanism) and supersedes the binary delegable/Claude-only taxonomy

## Context

ADR-002 established a binary task type taxonomy: delegable types (extraction, classification, summarization, template fill, mechanical transform, boilerplate generation) and Claude-only types (architectural design, debugging, multi-constraint code generation, judgment). Competence boundaries (Invariant 10) blocked multi-step reasoning, knowledge-intensive Q&A, complex instructions, cross-file analysis, and security analysis from local routing regardless of model size.

The essay "Ensemble as System" found that this taxonomy treats ensembles as groups of models, not as programmable systems. When an ensemble includes script agents (for file I/O, AST parsing, web search, tool execution), fan-out (parallel per-item processing), and LLM synthesizers, the *system* can handle tasks that no individual model could. Cross-file analysis becomes: script gathers files → fan-out LLMs analyze per-file → synthesizer combines. No individual agent does cross-file reasoning, but the ensemble does.

Systematic re-examination found most "Claude-only" types **split** into an ensemble-delegable preparation phase and a Claude-only judgment phase. Only tasks requiring recursive reconsideration, interacting constraints, holistic judgment, or novel insight are irreducibly Claude-only.

## Decision

Replace the binary delegable/Claude-only taxonomy with **three delegability categories**:

| Category | Definition | Routing |
|----------|-----------|---------|
| **Agent-delegable** | A single small model handles it. Bounded, single-concern. | Simple ensemble (existing swarm or single-agent) |
| **Ensemble-delegable** | Exceeds agent competence but passes the DAG decomposability test. | Multi-stage ensemble |
| **Claude-only** | Fails the DAG decomposability test. | Claude-direct |

**The DAG decomposability test** is the discriminator for ensemble-delegable. A task passes if all four conditions hold:

1. **DAG-decomposable** — the task breaks into a directed acyclic graph of agents. No cycles, no backtracking.
2. **Script-absorbable** — non-LLM complexity (file I/O, parsing, searching, tool execution) can be handled by script agents.
3. **Fan-out-parallelizable** — LLM work divides into bounded per-item tasks.
4. **Structured-synthesizable** — the synthesis step combines structured per-item outputs, not raw unstructured data.

**Agent-level competence boundaries are preserved.** No individual LLM agent within an ensemble handles multi-step reasoning (3+ steps), complex instructions (>4 constraints), or tasks requiring world knowledge or holistic judgment. These boundaries apply to every LLM node in the ensemble DAG.

**Irreducible Claude-only criteria** (tasks that fail the DAG decomposability test):

- Recursive reconsideration — later reasoning must revise earlier conclusions
- Interacting constraints — constraints form cycles, not decomposable into independent agents
- Holistic judgment — answer depends on seeing everything simultaneously
- Novel insight — the connection isn't in any per-item analysis
- Aesthetic judgment — fundamental model capability gap

**Triage decision tree update** (replaces ADR-002 Steps 1-2):

1. Classify task type
2. Test delegability category:
   - If task type is agent-delegable (extraction, classification, summarization, template fill, mechanical transform, boilerplate) → route to simple ensemble
   - If task type might be ensemble-delegable → apply DAG decomposability test → if passes, route to multi-stage ensemble
   - If task fails the DAG decomposability test → Claude-only
3. Continue with ADR-002 Steps 3-6 (standing auth, task profiles, available ensembles, default to Claude)

## Consequences

**Positive:**
- Previously Claude-only task types (cross-file analysis, evidence gathering, knowledge retrieval, tool-based scanning) become ensemble-delegable
- Claude's irreducible share drops from ~48% to an estimated ~15-30% of subtasks (per-invocation, after ensembles exist; see amortization caveat below)
- Agent-level competence boundaries are unchanged — individual model safety is preserved
- The DAG decomposability test replaces ad-hoc binary judgment with four named, testable conditions — a structured heuristic, not a mechanical procedure, but more rigorous than the prior binary classification

**Negative:**
- Three categories add triage complexity vs. two. The conductor must now run a four-condition test for borderline tasks
- Triage itself is a Claude-only task — the conductor must exercise judgment to determine whether constraints are independent or interacting, whether preparation is separable, etc. Triage cost (estimated few hundred tokens per subtask) should be subtracted from savings estimates. For recurring task patterns, triage decisions should be cached in task profiles to avoid re-paying this cost
- Ensemble-delegable tasks require multi-stage ensembles with script agents — more complex to compose than simple swarms
- DAG decomposability is a necessary but possibly not sufficient condition — a task may pass all four conditions yet produce poor results because the decomposition was wrong. The conductor's ability to prospectively classify decomposability from natural language descriptions is untested (same risk as ADR-002's task type classification assumption, now amplified). When uncertain about decomposability, the conductor defaults to Claude-only (Invariant 2)
- The savings estimate of ~15-30% Claude-only is per-invocation after ensembles exist. It does not include composition costs (script authoring, ensemble creation) or triage overhead. Break-even depends on reuse frequency (see ADR-010)

**Neutral:**
- The binary taxonomy remains valid as a subset: agent-delegable maps to the old "delegable" and Claude-only is narrower than the old "Claude-only"
- Triage outcomes (delegability classification + actual result quality) should be logged to build evidence about classification accuracy over time, extending the data flywheel to cover triage quality
