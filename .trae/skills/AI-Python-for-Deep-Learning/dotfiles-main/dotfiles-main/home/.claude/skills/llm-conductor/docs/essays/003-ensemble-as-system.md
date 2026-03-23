# Ensemble as System: Expanding Delegability Through Composition

*2026-02-23*

## The Missed Bet

The prior essay on proactive task decomposition established the conductor as a workflow architect that decomposes meta-tasks into subtasks, routing each to the cheapest capable handler. It found 52% of subtasks in a "reasoning task" were delegable — extraction, template fill, mechanical transforms. The remaining 48% — cross-file analysis, debugging, multi-step reasoning, judgment — stayed with Claude. Invariant 10 drew the line, and we concluded: "The invariant was never wrong. We were applying it at the wrong altitude. No amendment needed."

That conclusion was itself operating at the wrong altitude. It treated ensembles as groups of small LLMs — multiple models doing the same kind of work a single model would do, just distributed. Under that view, an ensemble can't do cross-file analysis because no 0.6B model can do cross-file analysis, and putting three of them together doesn't change that.

But llm-orc ensembles aren't groups of models. They're **programmable systems**. A script agent can glob a directory, read 15 files, parse them with AST, and output structured JSON — no LLM reasoning required. A fan-out agent can take that array and spawn one LLM instance per file, each doing bounded single-file extraction. A synthesizer can combine the structured per-file outputs into a cross-file analysis. The *system* handles cross-file analysis. No individual model does.

This changes the entire competence boundary picture. The line between delegable and Claude-only was drawn around model capabilities, but it should have been drawn around *system* capabilities. The bet the conductor is making — that well-orchestrated ensembles can absorb most of what currently goes to Claude — is much bigger than we thought.

## What llm-orc Actually Offers

The prior research treated llm-orc as an ensemble runner with model profiles and evaluation tracking. The actual system is significantly richer:

**Three agent types**, not one:
- **LLM agents** — small models doing bounded reasoning (extraction, classification, template fill)
- **Script agents** — arbitrary Python or bash scripts taking JSON in, returning JSON out. Can run file I/O, web searches, static analysis tools, ML classifiers, test runners, parsers — anything expressible as code
- **Ensemble agents** — recursive composition, invoking entire sub-ensembles as pipeline steps

**Orchestration primitives:**
- **Fan-out/fan-in** — a script outputs an array; the next agent spawns one instance per element, processing in parallel. Results are gathered back into an ordered array.
- **Input key selection** — an agent can select a specific key from upstream JSON, enabling routing patterns where a classifier directs different data types to different downstream agents.
- **Conditional dependencies** — agent execution can be gated on upstream output values, enabling branching.
- **Parallel execution** — agents with no dependencies run simultaneously.

**Existing building blocks:**
- File read/write primitives
- JSON extraction and transformation
- User interaction (prompts, confirmations)
- Network analysis scripts (PageRank, community detection)
- Text chunking and aggregation
- Script caching (same input → cached result)

The key capability: script agents absorb the complexity that makes tasks "Claude-only." Cross-file gathering? A script globs and reads. Multi-step sequencing? The pipeline enforces order. Knowledge retrieval? A script calls a search API. Web scraping? A script fetches and parses HTML. AST analysis? A script runs Python's `ast` module. The LLM agents within the ensemble never face the hard parts — they receive bounded, pre-structured input and produce bounded, structured output.

## Redrawing the Competence Map

### What was "Claude-only" and why

The prior competence boundaries blocked these task types from local models regardless of model size:

- Multi-step reasoning (3+ sequential steps)
- Knowledge-intensive Q&A (requires broad world knowledge)
- Complex instructions (>4 constraints)
- Cross-file code analysis (relationships across files)
- Security analysis (vulnerability pattern knowledge)

Plus four "Claude-only" task types: architectural design, debugging, multi-constraint code generation, and judgment.

Each boundary was drawn correctly — for individual models. A 0.6B model can't trace a bug across three modules. A 7B model can't synthesize knowledge it was never trained on. No small model has design taste.

But each boundary implicitly assumed the ensemble *is* the model. When the system can orchestrate scripts, fan-out, and synthesis, the question changes from "can a small model do this?" to "can a composed system of scripts + small models do this?"

### The systematic re-examination

We tested each Claude-only pattern against ensemble architectures that use scripts for the hard parts:

**Cross-file code analysis → Ensemble-delegable.** Script agent discovers and reads files. Fan-out LLM agents each analyze one file (bounded extraction). Synthesizer combines per-file findings. No individual agent does cross-file analysis — but the system does.

**Multi-step reasoning → Split.** Sequential steps where each step's input is fully determined by the previous step's output: ensemble-delegable as a pipeline. Steps requiring backtracking (step 3 revises step 1 in light of step 2): irreducibly Claude-only.

**Debugging → Split (~80% delegable).** Script agent runs tests, captures output, parses stack traces, identifies relevant source files. Fan-out LLM agents analyze each failure in isolation. Synthesizer groups failures by category and suggests investigation order. The evidence gathering and per-layer analysis is delegable. The "aha moment" — connecting a subtle interaction between unrelated components — remains Claude-only.

**Knowledge-intensive Q&A → Split.** Script agent performs web searches, parses results. Fan-out LLM agents extract relevant facts from each result. Synthesizer combines. Factual retrieval is delegable. Nuanced synthesis requiring reasoning about the retrieved knowledge remains Claude-only.

**Security analysis → Split.** Script agent runs bandit, semgrep, or other scanning tools. LLM agents classify and explain findings. Tool-based detection is delegable. Novel vulnerability analysis remains Claude-only.

**Architectural design → Split.** Ensemble gathers file structures, extracts existing patterns, analyzes each component. Claude receives a structured brief and makes the design choice. Information gathering: delegable. Design judgment: Claude-only.

**Judgment, taste, aesthetics → Genuinely Claude-only.** No ensemble architecture compensates for the fundamental capability gap. This is the irreducible core.

### The revised map

| Task Pattern | Old | New | What Changed |
|-------------|-----|-----|-------------|
| Cross-file code analysis | Claude-only | **Ensemble-delegable** | Scripts gather, LLMs analyze per-file |
| Multi-step reasoning (decomposable) | Claude-only | **Ensemble-delegable** | Pipeline of single-step agents |
| Multi-step reasoning (recursive) | Claude-only | Claude-only | Requires backtracking |
| Debugging (evidence + per-layer) | Claude-only | **Ensemble-delegable** | Scripts test/parse, LLMs analyze per-failure |
| Debugging (novel cross-layer) | Claude-only | Claude-only | Requires holistic view |
| Knowledge Q&A (factual) | Claude-only | **Ensemble-delegable** | Scripts search, LLMs extract |
| Knowledge Q&A (nuanced) | Claude-only | Claude-only | Requires reasoning about knowledge |
| Security (tool-based) | Claude-only | **Ensemble-delegable** | Scripts scan, LLMs classify |
| Security (novel) | Claude-only | Claude-only | Requires deep expertise |
| Architectural design (gathering) | Claude-only | **Ensemble-delegable** | Scripts + LLMs prepare brief |
| Architectural design (choice) | Claude-only | Claude-only | Requires judgment |
| Multi-constraint code gen (independent) | Claude-only | **Ensemble-delegable** | Separate agents per constraint |
| Multi-constraint code gen (interacting) | Claude-only | Claude-only | Constraints form cycle |
| Judgment / taste | Claude-only | Claude-only | Fundamental gap |

The pattern: most old "Claude-only" types **split** into an ensemble-delegable preparation phase and a Claude-only judgment phase.

## Five Concrete Architectures

Abstract delegability claims need concrete shapes. We designed five ensemble architectures, each targeting a previously Claude-only pattern, using available Ollama models (qwen3:0.6b, gemma3:1b, llama3, gemma3:12b) and llm-orc's proven patterns.

### 1. Document Consistency Checker

**Replaces:** Cross-file analysis (the self-evaluation pattern)

```
script: parse_documents.py → extract terms, invariant refs, cross-refs
  fan-out LLM (0.6B): compare each element pair between source and target
    LLM synthesizer (1B): group by matched/mismatched/missing, produce report
```

The script uses regex to extract structured elements from markdown files — concept tables, invariant references, section headers. Each fan-out LLM instance receives one comparison pair: "does this invariant reference in SKILL.md match the definition in the domain model?" That's a bounded string comparison. The synthesizer groups results.

### 2. Cross-File Code Analyzer

**Replaces:** Cross-file code analysis

```
script: discover_files.py → glob, return file paths
  script: read_and_chunk.py (fan-out) → read one file, chunk if large
    LLM (0.6B, fan-out): extract structure from each chunk (classes, functions, imports)
      LLM synthesizer (1B): identify cross-file patterns, conventions, dependencies
```

Double fan-out: N files × M chunks per file. Each LLM sees at most 150 lines. The synthesizer receives structured JSON from every chunk and identifies patterns across them — a summarization task, not a cross-file reasoning task.

### 3. Knowledge Researcher

**Replaces:** Knowledge-intensive Q&A

```
script: web_search.py → call search API, return URLs + snippets
  script: parse_html.py (fan-out) → fetch each URL, strip HTML, truncate
    LLM (1B, fan-out): extract relevant facts from each page
      LLM synthesizer (7B): combine sourced facts into coherent answer
```

Scripts handle the knowledge retrieval that small models can't do from training alone. Each LLM extracts from one page — bounded summarization. The synthesizer combines with source attribution.

### 4. Multi-File Test Generator

**Replaces:** Expanded test-generation starter kit

```
script: discover_test_targets.py → find test + source files
  script: extract_test_pattern.py → AST-parse example tests, extract conventions
    script: find_untested_functions.py → compare source vs test coverage, find gaps
      LLM (1B, fan-out): generate one test case per gap, following demonstrated pattern
        script: validate_python_syntax.py (fan-out) → ast.parse() each generated test
```

Four scripts, one LLM type. The scripts do all the hard work — AST parsing, pattern extraction, gap analysis, syntax validation. The LLM's job is template fill: "given this pattern and this function signature, write a test." That's bounded and well within 1B competence.

### 5. Debugging Evidence Gatherer

**Partially replaces:** Debugging (~80%)

```
script: run_tests_capture.py → run pytest, capture output
  script: parse_test_failures.py → extract structured failure data
    script: read_file.py (fan-out) → read each referenced source file
      LLM (1B, fan-out): analyze each failure in isolation, categorize
        LLM synthesizer (7B): group by root cause, suggest investigation order
```

Scripts run tests and parse output — entirely mechanical. Each LLM analyzes one failure with its traceback and relevant source code — bounded analysis. The synthesizer produces a debugging brief. Claude receives this brief instead of raw test output, spending tokens only on the hard part: connecting the dots.

### Cross-cutting observations

**Scripts matter more than LLMs.** Each architecture has 2-4 script agents and only 1-2 LLM types. The scripts do the heavy lifting; the LLMs do bounded reasoning. This inverts the assumption that ensembles are primarily about model orchestration.

**Fan-out is the scalability mechanism.** Cost scales with item count (files, comparisons, test cases), not task complexity. 100 files × 0.6B model = still cheap.

**Three conductor profiles emerge.** `conductor-micro` (qwen3:0.6b) for per-item work, `conductor-small` (gemma3:1b) for bounded analysis, `conductor-medium` (llama3 or gemma3:12b) for synthesis. These map to the gather → analyze → synthesize stages.

**The conductor needs to write scripts.** Composing multi-stage ensembles requires authoring Python scripts for the gathering/parsing phases. Claude writes the scripts (a judgment task); the scripts then run locally without Claude. This is a new ensemble composition capability.

## The Two-Level Competence Model

### Why Invariant 10 needs amendment

The prior essay concluded "Invariant 10: No Tension After All — no amendment needed." That conclusion was correct at the time: the invariant correctly constrains individual subtask routing, and the conductor decomposes meta-tasks above the invariant's level.

But the current wording — "The conductor does not route multi-step reasoning, knowledge-intensive Q&A, or complex instructions **to local models**" — blocks ensemble-level delegation. A subtask classified as "cross-file analysis" would be blocked from routing to any local handler, including an ensemble that decomposes it into script-gather → fan-out-extract → synthesize. The invariant says "to local models" when it should say "to individual local model agents."

This is not a matter of altitude. It's a matter of what "local models" means when the local handler is a system, not a model.

### The two levels

**Level 1: Agent-level competence (preserved).** No individual LLM agent within an ensemble handles multi-step reasoning (3+ steps), complex instructions (>4 constraints), or tasks requiring world knowledge or holistic judgment. These boundaries are correct, empirically grounded, and unchanged. Every LLM node in every architecture above respects them — each fan-out agent sees one file, one comparison, one item.

**Level 2: Ensemble-level capability (new).** A composed system of script agents, fan-out LLM agents, and synthesizers can handle tasks that exceed any individual agent's competence, provided four conditions hold:

1. **DAG-decomposable** — the task decomposes into a directed acyclic graph of agents. No cycles, no backtracking required.
2. **Script-absorbable** — the non-LLM complexity (file I/O, parsing, searching, tool execution) can be handled by script agents without LLM reasoning.
3. **Fan-out-parallelizable** — the LLM work divides into bounded per-item tasks.
4. **Structured-synthesizable** — the synthesis step combines structured per-item outputs, not raw unstructured data.

When all four hold: ensemble-delegable. When any fails: Claude-only.

The **DAG decomposability test** is the practical discriminator. Can I draw the task as a flow where scripts gather, LLMs analyze per-item, and a synthesizer combines? If yes, it's ensemble-delegable regardless of how complex the overall task appears. If any step needs to see the whole picture or revise prior steps, it's Claude-only.

### What's genuinely, irreducibly Claude-only

After removing everything that ensemble architectures can handle, the irreducible core is:

| Criterion | Why ensembles can't help | Example |
|-----------|--------------------------|---------|
| **Recursive reconsideration** | Later reasoning must revise earlier conclusions — not a DAG | Debugging where fixing attempt A reveals the real bug is B |
| **Interacting constraints** | Constraints form cycles, not decomposable into independent agents | Code where requirement 3 changes how requirement 1 should work |
| **Holistic judgment** | Answer depends on seeing everything simultaneously | "What's the best API shape for this module?" |
| **Novel insight** | The connection isn't in any per-item analysis | Noticing two unrelated modules have a race condition |
| **Aesthetic judgment** | Fundamental model capability gap | Design taste, naming quality, code elegance |

This is a much smaller set than the current Claude-only classification. It represents perhaps 15-30% of total work in a typical session, down from the prior estimate of 48%.

## Three Categories, Not Two

The binary task type taxonomy — delegable or Claude-only — served the first two essays. It no longer captures the space.

| Category | Definition | Routing |
|----------|-----------|---------|
| **Agent-delegable** | A single small model handles it. Bounded, single-concern. Extraction, classification, template fill, summarization, mechanical transform, boilerplate. | Simple ensemble |
| **Ensemble-delegable** | Exceeds individual agent competence but passes the four-condition test. Scripts handle gathering, fan-out LLMs handle per-item analysis, synthesizer combines. | Multi-stage ensemble |
| **Claude-only** | Fails the DAG decomposability test. Recursive reasoning, interacting constraints, holistic judgment, novel insight. | Claude-direct |

The practical consequence: **even Claude-only tasks often have an ensemble-delegable preparation phase.** "Design the architecture" is Claude-only, but "gather all file structures, extract existing patterns, analyze each component" is ensemble-delegable. The ensemble prepares a structured brief; Claude makes the decision on dramatically reduced context.

This **ensemble-prepared Claude** pattern is the key innovation. Claude receives a structured analysis instead of raw files. In the self-evaluation, four parallel Claude agents used ~35K+ tokens for gathering and comparison. An ensemble doing the same work would use zero Claude tokens. Claude would only spend ~5K tokens on the final judgment synthesis — an ~85% reduction.

## The Self-Evaluation as Proof

We tested this framework against itself. The conductor evaluated its own skill definition — reviewing SKILL.md, domain model, ADRs, scenarios, and essays for consistency, completeness, and readiness. I classified the entire evaluation as "Claude-direct — every subtask required cross-file judgment and multi-step reasoning."

Revisiting with ensemble capabilities:

| Subtask | Original | With Ensembles | Savings |
|---------|----------|---------------|---------|
| SKILL.md consistency | Claude-only | Script parse refs → fan-out compare → synthesize | ~70% delegable |
| Vocabulary cross-check | Claude-only | Script extract terms → script find occurrences → fan-out compare → synthesize | ~80% delegable |
| ADR verification | Claude-only | Script extract decisions → fan-out check each → synthesize | ~75% delegable |
| Scenario coverage | Claude-only | Script parse scenarios → script parse behaviors → fan-out match → synthesize | ~70% delegable |
| Readiness assessment | Claude-only | Requires judgment synthesis | Claude-only |

What I called "entirely Claude-direct" was **~70% delegable.** The final judgment synthesis — severity assessment, prioritization, recommendations — is genuinely Claude-only. Everything else is script-gather → fan-out-compare → synthesize.

## Invariant Tensions

This essay's findings create tensions with two existing positions:

### Invariant 10 requires amendment

**Current wording:** "The conductor does not route multi-step reasoning (3+ steps), knowledge-intensive Q&A, or complex instructions (>4 constraints) to local models regardless of available model size."

**Tension:** "To local models" blocks ensemble-level delegation. The five architectures above route cross-file analysis and knowledge Q&A to local ensembles — systems where no individual model exceeds its competence, but the composed system handles what no single model could.

**Proposed amendment:** "Competence boundaries operate at two levels. **Agent level:** no individual LLM agent within an ensemble handles multi-step reasoning (3+ steps), complex instructions (>4 constraints), or tasks requiring world knowledge or holistic judgment — regardless of model size. **Ensemble level:** a composed system of script agents, fan-out LLM agents, and synthesizers can handle tasks that exceed any individual agent's competence, provided the task decomposes into a DAG where each LLM node stays within agent-level boundaries. Tasks are genuinely Claude-only only when they require recursive reconsideration, interacting constraints, holistic judgment, or novel insight that no decomposition can produce."

### Prior essay's "No Tension After All" is superseded

The proactive task decomposition essay concluded that Invariant 10 needed no amendment because the conductor operates above it — decomposing meta-tasks into subtasks, then applying competence boundaries correctly at the subtask level.

This was correct for the model-as-ensemble view. It's insufficient for the system-as-ensemble view. Even at the subtask level, a subtask classified as "cross-file analysis" would be blocked from ensemble routing under the current wording. The amendment doesn't change the altitude — it changes what "local models" means when the local handler is a composed system with scripts, fan-out, and synthesis.

### Invariant 3 is reinforced, not violated

"Composition over scale. Prefer swarms of small models over reaching for larger models." The ensemble-as-system approach is composition over scale taken to its logical conclusion. Composition now means not just "many small LLMs instead of one big LLM" but "scripts + small LLMs compose into systems that handle what no model alone could." The invariant's spirit was always right. We're extending its application.

## What the Conductor Needs Next

1. **Script authoring as part of ensemble composition.** Creating multi-stage ensembles requires writing Python scripts for the gather/parse/structure phases. The conductor must be able to compose scripts, validate their JSON I/O, and include them in ensemble configurations. Claude writes the scripts; the scripts then run without Claude.

2. **Template architectures.** The five architectures should become templates the conductor draws from when composing ensembles. "I need a cross-file analysis ensemble" → select the cross-file-analyzer template → customize scripts and prompts for this project. Not designing from scratch each time.

3. **Conductor-specific profiles.** Three tiers for internal use:
   - `conductor-micro` (qwen3:0.6b) — per-item extraction, comparison, classification
   - `conductor-small` (gemma3:1b) — bounded analysis, template fill, simple synthesis
   - `conductor-medium` (llama3 or gemma3:12b) — multi-source synthesis, report generation

4. **The DAG decomposability test as a concrete procedure.** Heuristics for the conductor to classify tasks into three categories:
   - Can I list the items to process? → fan-out candidate
   - Can a script gather the data without LLM reasoning? → script-absorbable
   - Does each item's analysis stand alone? → parallelizable
   - Can the final step combine per-item JSONs? → synthesizable
   - If all yes → ensemble-delegable

5. **A revised starter kit.** The current five single-agent ensembles remain valuable for agent-delegable tasks. But the conductor should also offer template architectures for ensemble-delegable tasks — document consistency, cross-file analysis, test generation — that it customizes per-project.

## The Revised Endgame

The prior essay estimated 52% of subtasks delegable, with Claude handling 48%. With ensemble-as-system patterns, the picture changes:

- **Agent-delegable** (simple extraction, classification, template fill): ~40% of subtasks
- **Ensemble-delegable** (cross-file analysis, evidence gathering, knowledge retrieval, test generation): ~30% of subtasks
- **Ensemble-prepared Claude** (gathering delegable, judgment Claude-only): ~15% of subtasks
- **Genuinely Claude-only** (recursive reasoning, interacting constraints, novel insight, taste): ~15% of subtasks

Claude's irreducible share drops from ~48% to ~15-30%, depending on the task. Even in the "ensemble-prepared Claude" category, the ensemble handles the majority of token-consuming work (reading files, extracting patterns, comparing documents) and Claude handles only the final judgment on a pre-digested brief.

The bet: that well-orchestrated systems of scripts and small models can absorb 70-85% of the token budget that currently goes to Claude, with quality maintained through the same evaluation loop that governs simple ensembles. The conductor's role evolves from routing individual tasks to composing systems — writing scripts, designing pipelines, selecting templates — that expand what "local" can handle.

Each session produces scripts and ensembles that persist. Each ensemble that passes calibration becomes a reusable system component. Each promoted ensemble reduces the conductor's future composition work. The compounding effect is no longer just "more ensembles for more task types" — it's "more capable systems for more complex tasks."

## Sources

- llm-orc source code: script agent runner, fan-out coordinator, ensemble agent runner, dependency resolver, input key selection (ADR-013, ADR-014)
- llm-orc ensemble examples: semantic-extraction, routing-demo, fan-out-test, security-review, graph-analysis
- llm-orc primitives: file_ops, data_transform, control_flow, user_interaction
- Route-and-Reason (R2-Reasoner, arXiv 2506.05901) — subtask decomposition across heterogeneous models
- Amazon Science: Task Decomposition with Smaller LLMs — cost optimization, lost novelty warning
- Intelligent AI Delegation (arXiv 2602.11865) — delegation trust models, complexity floors
- Small Language Models for Agentic AI (arXiv 2506.02153) — SLM capabilities in agentic workflows
- Self-evaluation worked example — concrete delegability analysis of a real meta-task
