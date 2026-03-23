# ADR-013: Multi-Stage Ensemble Composition with Script Agents

**Status:** Accepted — extends ADR-005 (swarm as default pattern)

## Context

ADR-005 established the swarm as the default ensemble pattern: micro extractors → small/medium analyzers → medium/ceiling synthesizer. All agents are LLM agents. This works for agent-delegable tasks where the entire task is bounded LLM work.

ADR-012 introduces ensemble-delegable tasks — tasks that exceed individual agent competence but pass the DAG decomposability test. These tasks require a different ensemble architecture: script agents handle the non-LLM complexity (file I/O, AST parsing, web searches, tool execution), fan-out enables per-item parallel processing, and LLM agents handle only bounded per-item reasoning. The essay "Ensemble as System" designed five concrete architectures following this pattern, all sharing a gather-analyze-synthesize structure.

llm-orc supports three agent types (LLM, script, ensemble) and orchestration primitives (fan-out, input key selection, conditional dependencies) that enable these architectures. The conductor needs a composition protocol for multi-stage ensembles that leverages these capabilities.

## Decision

Extend the ensemble composition protocol (ADR-005) with **multi-stage ensemble** support:

**Multi-stage ensemble pattern:**
```
script agent(s): gather/parse/structure data → JSON array
  fan-out LLM agent(s): bounded per-item analysis → JSON per item
    LLM synthesizer: combine structured per-item outputs → final result
```

**Script authoring.** The conductor authors Python or bash scripts as part of multi-stage ensemble composition. Scripts take JSON input and return JSON output. Claude writes the scripts (a judgment task); the scripts then run locally without Claude. Script authoring includes validating JSON I/O contracts between agents.

> **Superseded by ADR-015:** Script authoring is now the Ensemble Designer's responsibility. The conductor can request scripts via evaluation feedback.

**Template architectures.** Five reusable multi-stage patterns serve as starting points:

| Template | Use Case | Structure |
|----------|----------|-----------|
| Document consistency | Cross-file comparison | parse scripts → fan-out LLM compare → synthesize |
| Cross-file analyzer | Codebase analysis | discover script → read/chunk script → fan-out LLM extract → synthesize |
| Knowledge researcher | Factual Q&A | search script → fetch/parse script → fan-out LLM extract → synthesize |
| Test generator | Test creation | discover script → pattern script → gap script → fan-out LLM generate → validate script |
| Evidence gatherer | Debugging prep | run script → parse script → read script → fan-out LLM analyze → synthesize |

The conductor selects the matching template and customizes scripts and prompts for the project, rather than designing from scratch.

**Conductor profiles.** Three standard model profiles for multi-stage ensemble agents:

| Profile | Model | Role |
|---------|-------|------|
| `conductor-micro` | qwen3:0.6b | Per-item extraction, comparison, classification |
| `conductor-small` | gemma3:1b | Bounded analysis, template fill, simple synthesis |
| `conductor-medium` | llama3 (8B default); gemma3:12b only when synthesizing 4+ upstream outputs (per ADR-005 ceiling rule) | Multi-source synthesis, report generation |

> **Superseded by ADR-018:** The ceiling model is now qwen3:14b. The ceiling rule (4+ upstream outputs) is unchanged.

These map to the gather → analyze → synthesize stages. The existing model tier assignment (ADR-005) still applies: conductor-micro for extractors, conductor-small for analyzers, conductor-medium for synthesizers.

**Extended composition protocol** (supplements ADR-005 Steps 1-7):

1. **Classify** — is this agent-delegable (use ADR-005 swarm protocol) or ensemble-delegable (use multi-stage protocol)?
2. **Select template** — match the task to a template architecture, or design a custom multi-stage DAG if no template fits
3. **Author scripts** — write the gathering/parsing scripts, defining JSON I/O contracts for each
4. **Assign profiles** — select conductor profiles for each LLM agent in the DAG
5. **Create** the ensemble via `create_ensemble` with the full agent DAG (scripts + LLMs + dependencies)
6. **Validate** via `validate_ensemble`
7. **Present** the design to the user, now including script descriptions and the DAG structure:
   ```
   Proposed ensemble: {name}
   Pattern: multi-stage (template: {template-name | custom})
   Agents:
     - {name}: script ({description})
     - {name}: LLM, fan-out, {conductor-profile} ({role})
     - {name}: LLM, synthesizer, {conductor-profile} ({role})
   DAG: {script} → fan-out {LLM} → {synthesizer}
   Scripts authored: {count}
   ```

## Consequences

**Positive:**
- Ensemble-delegable tasks (ADR-012) now have a concrete composition path
- Template architectures reduce composition cost — selecting and customizing is cheaper than designing from scratch
- Script agents absorb non-LLM complexity, keeping each LLM agent within its competence boundary
- Conductor profiles standardize model selection, reducing per-ensemble profile proliferation

**Negative:**
- Script authoring costs Claude tokens — each multi-stage ensemble requires writing 1-4 Python scripts. This front-loads cost more than simple swarm composition. ADR-010's repetition threshold of 3 was calibrated for simple ensembles (~5000 tokens); multi-stage ensembles with script authoring have higher composition costs and may need a higher break-even point
- Scripts introduce failure modes absent from LLM-only ensembles: runtime errors, JSON contract mismatches, environment dependencies (missing Python packages), and partial fan-out failures (some items succeed, others fail). Script validation before ensemble creation must include: dry-run with sample input, JSON schema validation of I/O contracts between agents, and dependency declaration. Runtime script failures are logged but excluded from the calibration/sampling evaluation loop (which evaluates LLM output quality, not infrastructure reliability). On script failure, the conductor falls back to Claude for the affected subtask and reports the error
- Templates are a starting set based on the five architectures designed in the essay. They are not proven as a minimal covering set for all ensemble-delegable tasks. Template coverage will grow through usage as the conductor encounters new patterns. Custom DAG design remains available as a fallback when no template fits, following the same composition protocol
- The conductor must maintain script quality across promotions — a promoted ensemble's scripts must work in the destination context. Invariant 11 should be extended to cover script portability alongside profile dependencies

**Neutral:**
- ADR-005 swarm pattern remains the default for agent-delegable tasks; multi-stage is for ensemble-delegable tasks
- Fan-out cost scales with item count, not task complexity — 100 files x 0.6B model is still cheap
