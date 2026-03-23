# Research Log: Ensemble-as-System — Expanding Delegability Through Composition

## Question 1: What "Claude-only" task patterns become delegable when ensembles use script agents, fan-out, and meta-agent orchestration?

**Method:** Analysis of llm-orc's full capability set (script agents, fan-out/fan-in, ensemble agents, input key selection, conditional dependencies, primitives) applied systematically against each current Claude-only task type and competence boundary. Used the self-evaluation meta-task as a worked example.

**Findings:**

### The capability gap was misidentified

The prior research drew competence boundaries around **individual LLM agent capabilities**: small models can't do cross-file analysis, multi-step reasoning, or complex judgment. This is true — but it conflates the agent with the ensemble.

llm-orc ensembles are not "groups of small LLMs." They are **programmable systems** with three agent types:

1. **Script agents** — arbitrary Python/bash that takes JSON in, returns JSON out. Can run any tool: file I/O, web search, static analysis, ML classifiers, test runners, parsers. No LLM reasoning needed.
2. **LLM agents** — small models doing bounded reasoning tasks (extraction, classification, summarization).
3. **Ensemble agents** — recursive composition, invoking entire sub-ensembles as pipeline steps.

Plus orchestration primitives: fan-out/fan-in over arrays, input key selection for routing, conditional dependencies for branching, parallel execution of independent agents.

The critical insight: **scripts handle the parts that make tasks "Claude-only."** Cross-file gathering? A script globs and reads files. Multi-step sequencing? The pipeline enforces step order. Knowledge retrieval? A script calls a search API. The LLM agents within the ensemble only need to handle bounded, single-concern tasks — well within small model competence.

### Systematic re-examination of Claude-only types

**1. Cross-file code analysis → DELEGABLE via ensemble**

Current boundary: "requires understanding relationships across multiple files"

Ensemble pattern:
```
script: glob files, read contents, parse structure →
  fan-out LLM: analyze ONE file each (bounded extraction) →
    LLM synthesizer: combine per-file findings
```

No individual agent does cross-file analysis. Scripts gather across files. LLMs analyze within bounded scope. The synthesizer combines structured per-file outputs — a simpler task than analyzing raw files from scratch.

**2. Multi-step reasoning (3+ steps) → CONDITIONALLY DELEGABLE**

Ensemble pattern:
```
agent-step-1: perform reasoning step 1 →
  agent-step-2: perform step 2 using step 1's output →
    agent-step-3: perform step 3 using step 2's output
```

Each agent does ONE reasoning step. The pipeline enforces sequencing. Works when steps are decomposable — each step's input is fully specified by the previous step's output.

**Remains Claude-only when:** Steps require backtracking or recursive reconsideration (step 3 needs to revise step 1 in light of step 2).

**3. Debugging → PARTIALLY DELEGABLE**

Ensemble pattern:
```
script: run tests, capture output, parse stack traces →
  script: identify relevant source files from traces →
    fan-out LLM: analyze each layer/component in isolation →
      LLM synthesizer: combine per-layer hypotheses
```

Script agents run tests, parse traces, identify files — all mechanical. Each LLM analyzes one component. The synthesizer combines hypotheses for obvious failures.

**Remains Claude-only:** Subtle cross-layer interactions (callback chains, race conditions, type mismatches across interfaces) where the insight requires seeing the whole picture simultaneously.

**4. Knowledge-intensive Q&A → DELEGABLE via web search**

Ensemble pattern:
```
script: perform web searches via API →
  script: parse results into structured data →
    fan-out LLM: extract/summarize each result →
      LLM synthesizer: combine into answer
```

Web search provides the knowledge. LLM agents extract from bounded results — that's summarization, well within competence.

**Remains Claude-only:** Nuanced synthesis across domains, or questions requiring reasoning about retrieved knowledge rather than retrieving it.

**5. Security analysis → PARTIALLY DELEGABLE**

Ensemble pattern:
```
script: run bandit/semgrep/safety tools →
  script: parse tool output into structured findings →
    fan-out LLM: classify and explain each finding →
      LLM synthesizer: prioritize and summarize
```

Security tools do detection. LLMs classify known patterns. The existing `security-review` ensemble in llm-orc already demonstrates this.

**Remains Claude-only:** Novel vulnerability analysis (finding what tools don't detect).

**6. Architectural design → GATHERING DELEGABLE, JUDGMENT CLAUDE-ONLY**

An ensemble can prepare a comprehensive structured brief (file structure, dependency graph, existing patterns, per-component analysis). But the design *choice* — which approach, which pattern — requires judgment small models lack.

**Value:** Reduces Claude's work from "read 15 files and design" to "review this structured analysis and decide."

**7. Multi-constraint code generation → CLAUDE-ONLY when constraints interact**

Truly interacting constraints can't be decomposed. If constraint 3 affects how constraint 1 should be implemented, a single reasoning context is needed.

**Exception:** If constraints are independent (affect different parts of the code), they can be handled by separate agents.

**8. Judgment (design taste, naming, API shape) → GENUINELY CLAUDE-ONLY**

No ensemble architecture compensates for the fundamental capability gap. Aesthetic and design judgment requires broad training and nuanced reasoning.

### Summary: the revised competence boundary map

| Task Pattern | Old Classification | New Classification | Enabling Pattern |
|-------------|-------------------|-------------------|-----------------|
| Cross-file code analysis | Claude-only | **Delegable** | Script gather → fan-out LLM → synthesize |
| Multi-step reasoning (decomposable) | Claude-only | **Delegable** | Pipeline of single-step agents |
| Multi-step reasoning (recursive) | Claude-only | Claude-only | Steps interdependent |
| Debugging (evidence gathering + per-layer) | Claude-only | **Delegable** | Script test/parse → fan-out LLM → synthesize |
| Debugging (novel cross-layer insight) | Claude-only | Claude-only | Requires holistic view |
| Knowledge-intensive Q&A (factual) | Claude-only | **Delegable** | Script search → LLM extract → synthesize |
| Knowledge-intensive Q&A (nuanced) | Claude-only | Claude-only | Requires reasoning about knowledge |
| Security analysis (tool-based) | Claude-only | **Delegable** | Script scan → LLM classify → synthesize |
| Security analysis (novel) | Claude-only | Claude-only | Requires deep expertise |
| Architectural design (information gathering) | Claude-only | **Delegable** | Script gather → fan-out LLM analyze |
| Architectural design (choice) | Claude-only | Claude-only | Requires judgment |
| Multi-constraint code gen (interacting) | Claude-only | Claude-only | Constraints can't be decomposed |
| Multi-constraint code gen (independent) | Claude-only | **Delegable** | Separate agents per constraint |
| Judgment (taste, naming, API shape) | Claude-only | Claude-only | Fundamental capability gap |

### Worked example: the self-evaluation meta-task

I classified the entire self-evaluation as "Claude-direct — every subtask required cross-file judgment and multi-step reasoning." Revisiting with ensemble capabilities:

| Subtask | Original | Ensemble Architecture | Revised |
|---------|----------|----------------------|---------|
| SKILL.md consistency | Claude-only | Script: parse invariant refs, section refs, MCP table → fan-out LLM: check each ref → synthesizer | ~70% delegable |
| Vocabulary cross-check | Claude-only | Script: extract concepts from domain model → script: find occurrences in SKILL.md → fan-out LLM: compare each → synthesizer | ~80% delegable |
| ADR verification | Claude-only | Script: extract ADR decisions → fan-out LLM: check each against SKILL.md section → synthesizer | ~75% delegable |
| Scenario coverage | Claude-only | Script: parse scenarios → script: parse SKILL.md behaviors → fan-out LLM: check each pairing → synthesizer | ~70% delegable |
| Readiness assessment | Claude-only | Requires judgment synthesis across all findings | Claude-only |

What I called "entirely Claude-direct" was **~70% delegable.** Scripts handle cross-file gathering and parsing. Fan-out LLMs each do one bounded comparison. Only the final judgment synthesis is genuinely Claude-only.

### The recurring ensemble architecture

A dominant pattern emerges across all these re-examinations:

```
script: gather/parse/structure (mechanical, no LLM needed) →
  fan-out LLM: bounded analysis of each item (extraction/comparison) →
    LLM synthesizer: combine structured findings (summarization)
```

This is the **gather → analyze → synthesize** pattern. Each stage operates within clear competence boundaries:
- **Gather:** Script agents — unlimited capability (any Python/bash)
- **Analyze:** Small LLM agents — bounded, single-item, single-concern
- **Synthesize:** Medium LLM agent — combining structured outputs (easier than raw analysis)

The pattern works because scripts absorb the complexity that makes tasks "Claude-only." The LLM agents never see the full cross-file picture — they see one file, one comparison, one item at a time.

### Implications

1. **Invariant 10 needs amendment.** The competence boundaries should apply to individual *agent tasks within an ensemble*, not to the overall task the ensemble handles. An ensemble can handle cross-file analysis even though no individual agent can.

2. **The task type taxonomy needs a third category.** Not just "delegable" and "Claude-only" but also "ensemble-delegable" — tasks that exceed individual agent competence but become delegable through script + fan-out + synthesis composition.

3. **The conductor's delegation potential is much larger than estimated.** The prior analysis found 52% of subtasks delegable in the PromotionHandler session. With ensemble-as-system patterns, many of the remaining 48% become partially delegable (the gathering/analysis portion, with Claude handling only the judgment portion).

4. **Script agents are the key enabler.** Without scripts, ensembles are limited to what LLM agents can do alone. With scripts, ensembles can gather, parse, search, run tools, invoke APIs — making the LLM agents' jobs simpler and more bounded.

5. **The self-evaluation demonstrates this concretely.** A task I classified as 100% Claude-direct was ~70% delegable once I designed ensemble architectures using scripts and fan-out.

**Sources:**
- llm-orc source code analysis (script agents, fan-out, ensemble agents, input key selection)
- llm-orc ensemble YAML examples (routing-demo, semantic-extraction, security-review, fan-out-test)
- llm-orc ADRs: ADR-001 (Pydantic schemas), ADR-013 (ensemble agents), ADR-014 (input key selection)
- Self-evaluation worked example from this session

---

## Question 2: What are the concrete ensemble architectures for these expanded patterns?

**Method:** Design-from-capabilities — applying llm-orc's full feature set (script agents, fan-out/fan-in, ensemble agents, input key selection, conditional dependencies, existing primitives) to design specific ensemble architectures for real use cases. Grounded in available Ollama models (qwen3:0.6b, gemma3:1b, gemma3:12b, llama3, mistral) and existing primitives (file_ops, data_transform, control_flow, user_interaction).

**Findings:**

### The gather → analyze → synthesize meta-pattern

Q1 identified a dominant architecture across all expanded delegability patterns. Q2 makes it concrete with five ensemble designs, each targeting a previously Claude-only task pattern. All five share the same three-stage structure:

| Stage | Agent Type | Role | Competence Level |
|-------|-----------|------|-----------------|
| **Gather** | Script agent(s) | File I/O, parsing, searching, tool execution | Unlimited (any Python/bash) |
| **Analyze** | Fan-out LLM agents | Bounded, single-item reasoning | Micro/small (0.6B-1B) |
| **Synthesize** | LLM agent | Combine structured per-item outputs | Small/medium (1B-7B) |

The key insight: **scripts absorb task complexity so LLM agents never exceed their competence.** A cross-file analysis task becomes N single-file extraction tasks plus one structured-output synthesis task.

### Architecture 1: Document Consistency Checker

**Replaces:** Cross-file analysis (self-evaluation pattern)
**Use cases:** Vocabulary audits, invariant cross-referencing, ADR-to-implementation verification, scenario coverage checks

```yaml
name: document-consistency-check
description: >
  Compare structured elements across multiple documents for consistency.
  Script parses documents into element pairs, LLM checks each pair,
  synthesizer produces a consistency report.

agents:
  - name: document-parser
    script: scripts/conductor/parse_documents.py
    parameters:
      extract: [terms, invariant_refs, cross_refs, schemas]
      # Returns array of {element_type, element_name, source_doc,
      # source_text, target_doc, target_text} — one per comparison

  - name: element-checker
    model_profile: conductor-micro   # qwen3:0.6b
    depends_on: [document-parser]
    fan_out: true
    output_format: json
    system_prompt: |
      Compare a single element between source and target documents.
      Return JSON:
      {
        "element": "name",
        "status": "matched | mismatched | missing",
        "source_text": "...",
        "target_text": "... | null",
        "issue": "description if mismatched/missing, null if matched"
      }

  - name: report-synthesizer
    model_profile: conductor-small   # gemma3:1b
    depends_on: [element-checker]
    system_prompt: |
      Group comparison results by status (matched, mismatched, missing).
      Produce a structured consistency report with:
      - Summary counts
      - Mismatched items with details
      - Missing items
      Keep it concise.
```

**Script requirements:** `parse_documents.py` — reads multiple markdown files, uses regex to extract terms from tables, invariant references (`Invariant \d+`), section cross-references, JSON schema fields. Returns a fan-out array of comparison pairs.

**Per-agent task complexity:** Each element-checker sees one comparison pair — a bounded string comparison with context. Well within 0.6B competence. The synthesizer combines structured JSON outputs — a summarization task for a 1B model.

**Estimated savings vs. Claude-direct:** The self-evaluation used ~35K Claude tokens across 4 parallel agents. This ensemble would use ~0 Claude tokens for the gathering/comparison work, reserving Claude only for the final severity assessment and recommendations.

### Architecture 2: Cross-File Code Analyzer

**Replaces:** Cross-file code analysis
**Use cases:** Pattern extraction across codebases, dependency mapping, convention checking, pre-design briefs

```yaml
name: cross-file-analyzer
description: >
  Analyze structural patterns and conventions across multiple code files.
  Script discovers and reads files, LLM extracts structure per-file,
  synthesizer identifies cross-file patterns.

agents:
  - name: file-discoverer
    script: scripts/conductor/discover_files.py
    parameters:
      patterns: ["**/*.py"]
      exclude: ["**/test_*", "**/__pycache__/**"]
      # Returns {data: [{path, size, modified}]}

  - name: file-reader
    script: scripts/conductor/read_and_chunk.py
    depends_on: [file-discoverer]
    fan_out: true
    parameters:
      max_chunk_lines: 150
      # Reads one file, chunks if large
      # Returns {data: [{path, chunk_index, content, lines}]}

  - name: structure-extractor
    model_profile: conductor-micro   # qwen3:0.6b
    depends_on: [file-reader]
    fan_out: true
    output_format: json
    system_prompt: |
      Extract structural elements from this code chunk:
      {
        "file": "path",
        "classes": [{"name": "...", "bases": [...], "methods": [...]}],
        "functions": [{"name": "...", "params": [...], "returns": "..."}],
        "imports": ["..."],
        "decorators": ["..."],
        "constants": ["..."]
      }

  - name: pattern-synthesizer
    model_profile: conductor-small   # gemma3:1b
    depends_on: [structure-extractor]
    system_prompt: |
      You receive structural extractions from multiple code files.
      Identify:
      1. Common patterns (repeated class shapes, shared bases)
      2. Import dependencies between files
      3. Convention violations (inconsistent naming)
      4. Structural summary
      Return structured analysis, not file-by-file listing.
```

**Double fan-out:** file-discoverer → N files → file-reader fans out per file → M chunks → structure-extractor fans out per chunk. Handles arbitrarily large codebases without any single agent seeing more than 150 lines.

**Script requirements:**
- `discover_files.py` — wraps glob, returns file paths array
- `read_and_chunk.py` — reads one file (from fan-out), chunks by line count, returns chunks array for secondary fan-out

**What Claude still does:** With the structured brief from this ensemble, Claude can make design decisions in a fraction of the tokens — reviewing a structured analysis instead of reading 15 raw files.

### Architecture 3: Knowledge-Augmented Research

**Replaces:** Knowledge-intensive Q&A
**Use cases:** Technology comparison, library capability research, "what does X support?", factual questions beyond model training data

```yaml
name: knowledge-researcher
description: >
  Answer knowledge-intensive questions by searching the web,
  extracting relevant facts, and synthesizing an answer.

agents:
  - name: web-searcher
    script: scripts/conductor/web_search.py
    parameters:
      max_results: 10
      # Calls search API, returns {data: [{url, title, snippet}]}

  - name: content-parser
    script: scripts/conductor/parse_html.py
    depends_on: [web-searcher]
    fan_out: true
    parameters:
      max_chars: 3000
      # Fetches URL, strips HTML, returns {url, title, clean_text}

  - name: result-extractor
    model_profile: conductor-small   # gemma3:1b
    depends_on: [content-parser]
    fan_out: true
    output_format: json
    system_prompt: |
      Extract ONLY information relevant to the research question.
      Return JSON:
      {
        "source_url": "...",
        "relevant_facts": ["fact 1", "fact 2"],
        "confidence": 0.0-1.0,
        "contradicts_other_sources": false
      }

  - name: answer-synthesizer
    model_profile: conductor-medium   # llama3
    depends_on: [result-extractor]
    system_prompt: |
      Synthesize extracted facts from multiple web sources.
      Note contradictions between sources. Cite source URLs.
      Produce a concise, sourced answer.
```

**Script requirements:**
- `web_search.py` — calls DuckDuckGo/SearXNG API, returns results array
- `parse_html.py` — fetches URL, strips HTML with BeautifulSoup, truncates to max_chars

**Per-agent complexity:** Each result-extractor sees one web page's clean text + a question — bounded extraction. The synthesizer combines 10 structured extraction results — a summarization task.

**What remains Claude-only:** Questions requiring nuanced synthesis across domains, interpreting ambiguous or conflicting information, or reasoning about implications of retrieved knowledge.

### Architecture 4: Multi-File Test Generator

**Replaces/expands:** generate-test-cases starter kit ensemble
**Use cases:** Generate test cases across a codebase following established patterns, test gap analysis

```yaml
name: test-generator
description: >
  Discover test patterns, identify untested functions, and generate
  test cases following established conventions.

agents:
  - name: test-discoverer
    script: scripts/conductor/discover_test_targets.py
    parameters:
      test_patterns: ["**/test_*.py", "**/*_test.py"]
      source_patterns: ["**/*.py"]

  - name: pattern-extractor
    script: scripts/conductor/extract_test_pattern.py
    depends_on: [test-discoverer]
    parameters:
      max_example_tests: 3
      # Uses AST to extract fixture style, assertion patterns,
      # mock setup, import conventions from existing tests

  - name: gap-finder
    script: scripts/conductor/find_untested_functions.py
    depends_on: [test-discoverer, pattern-extractor]
    # Compares source function signatures against test names
    # Returns array of {function_name, signature, file, source_code,
    #   test_pattern, fixture_setup}

  - name: test-writer
    model_profile: conductor-small   # gemma3:1b
    depends_on: [gap-finder]
    fan_out: true
    system_prompt: |
      Generate one test case following the demonstrated pattern.
      Match import style, fixture naming, assertion style, mock patterns.
      Return ONLY the test function code, no imports or class wrapper.

  - name: syntax-validator
    script: scripts/conductor/validate_python_syntax.py
    depends_on: [test-writer]
    fan_out: true
    # Runs ast.parse() on each test, returns pass/fail + error
```

**The power here:** Four script agents do all the hard work — AST parsing, pattern extraction, gap analysis, syntax validation. The LLM's job is reduced to template-fill: "given this demonstrated pattern and this function signature, produce a test." That's exactly the task type small models handle well.

**Script requirements:**
- `discover_test_targets.py` — glob for test + source files, pair them
- `extract_test_pattern.py` — AST-parse example tests, extract patterns as structured data
- `find_untested_functions.py` — compare source function names vs test names, return gaps
- `validate_python_syntax.py` — `ast.parse()` on generated code, return pass/fail

### Architecture 5: Debugging Evidence Gatherer

**Partially replaces:** Debugging
**Use cases:** Test failure analysis, error categorization, debugging prioritization

```yaml
name: debug-evidence-gatherer
description: >
  Run tests, parse failures, analyze each failure in isolation,
  and produce a structured debugging brief.

agents:
  - name: test-runner
    script: scripts/conductor/run_tests_capture.py
    parameters:
      command: "pytest -v --tb=long"
      timeout: 120
      # Returns {stdout, stderr, exit_code, duration}

  - name: failure-parser
    script: scripts/conductor/parse_test_failures.py
    depends_on: [test-runner]
    # Extracts: test name, error type, traceback,
    # referenced source files + line numbers
    # Returns {data: [{test, error, traceback, source_files}]}

  - name: source-reader
    script: primitives/file_ops/read_file.py
    depends_on: [failure-parser]
    fan_out: true
    # Reads each file referenced in tracebacks

  - name: failure-analyst
    model_profile: conductor-small   # gemma3:1b
    depends_on: [source-reader, failure-parser]
    fan_out: true
    output_format: json
    system_prompt: |
      Analyze one test failure in isolation. Return JSON:
      {
        "test_name": "...",
        "error_type": "...",
        "likely_cause": "description",
        "affected_lines": [{"file": "...", "line": N}],
        "category": "type_error | logic_error | missing_mock |
                      import_error | assertion_error | other",
        "fix_complexity": "trivial | moderate | complex"
      }

  - name: debug-synthesizer
    model_profile: conductor-medium   # llama3
    depends_on: [failure-analyst]
    system_prompt: |
      Group test failures by category and likely root cause.
      Identify failures sharing a common cause.
      Produce a debugging brief:
      1. Summary (N failures, categories)
      2. Likely root causes (grouped)
      3. Investigation order (most impactful first)
```

**What it handles:** ~80% of debugging — evidence gathering, per-failure analysis, categorization, prioritization. Claude receives a structured debugging brief instead of raw test output.

**What remains Claude-only:** Connecting subtle cross-component interactions, understanding why a specific test *should* have passed, novel failure modes not covered by the category taxonomy.

### Cross-cutting observations

**1. Script agent count matters more than LLM agent count.**

Each architecture has 2-4 script agents and only 1-2 LLM agent types (with fan-out creating N instances). The scripts do the heavy lifting; the LLMs do bounded reasoning. This inverts the assumption that ensembles are primarily about LLM agents.

**2. The conductor needs a script authoring protocol.**

None of these scripts exist yet. The conductor must be able to create scripts as part of ensemble composition — write the Python, validate it produces correct JSON I/O, and place it in `.llm-orc/scripts/conductor/`. Claude writes the scripts (a judgment task), but the scripts then run locally without Claude.

**3. Fan-out is the scalability mechanism.**

Every architecture uses fan-out to parallelize work across items. This means the ensemble's cost is proportional to the number of items (files, comparisons, test cases), not to the total size of the task. N files × micro-model = still cheap.

**4. The synthesizer is the quality bottleneck.**

In every architecture, the synthesizer must combine N structured outputs into a coherent whole. This is the hardest LLM task in the pipeline. For simple synthesis (grouping, counting), a 1B model suffices. For synthesis requiring judgment about relative importance or subtle patterns, a 7B model or even 12B may be needed.

**5. Three new profile tiers emerge.**

| Profile | Model | Role |
|---------|-------|------|
| `conductor-micro` | qwen3:0.6b | Per-item extraction, comparison, classification |
| `conductor-small` | gemma3:1b | Bounded analysis, template fill, simple synthesis |
| `conductor-medium` | llama3 or gemma3:12b | Multi-source synthesis, report generation |

These map to the gather→analyze→synthesize stages. The `conductor-micro` profile handles the fan-out items. The `conductor-small` handles moderate analysis. The `conductor-medium` handles synthesis.

**6. Existing primitives cover ~30% of script needs.**

`file_ops/read_file` and `data_transform/json_extract` are directly usable. But most architectures need custom scripts for domain-specific parsing (markdown tables, AST extraction, test output parsing, web search). The conductor should build a library of conductor-specific scripts over time.

### Model availability gap

The current Ollama install has qwen3:0.6b, gemma3:1b, gemma3:12b, llama3, and mistral. However, the existing profiles reference models not installed:
- `micro-local` references `qwen2:0.5b` (not installed — qwen3:0.6b is)
- `default-local` and `high-context-local` reference `llama3.1:8b` (not installed — llama3:latest is)

The conductor should reconcile profiles with available models during pre-flight discovery and suggest updates.

### Implications

1. **The conductor needs a script authoring capability.** Ensemble composition now includes writing Python scripts, not just configuring LLM agents and system prompts. Claude writes the scripts; the scripts then run locally.

2. **The starter kit should include these architectures as templates.** Rather than just 5 single-agent ensembles, the starter kit could include template architectures (document consistency, cross-file analysis, test generation) that the conductor customizes per-project.

3. **The delegation potential is dramatically higher than the 52% estimate.** With ensemble-as-system patterns, the conductor can delegate the gathering + per-item analysis portions of even "Claude-only" tasks. Claude's role shrinks to judgment and novel insight — perhaps 20-30% of total work, not 48%.

4. **Competence boundaries need a two-level rewrite.** Level 1: agent-level boundaries (what a single model can do). Level 2: ensemble-level capabilities (what a composed system can do). The conductor routes at Level 2, composes at Level 1.

5. **The self-evaluation benchmarks the savings.** The 4-agent Claude evaluation used ~35K+ tokens. An ensemble doing the same gathering + comparison work would use 0 Claude tokens. Claude would only be needed for the final ~5K tokens of judgment synthesis — a ~85% reduction.

**Sources:**
- llm-orc source: script agent runner, fan-out coordinator, ensemble agent runner, dependency resolver, input key selection
- llm-orc ensemble examples: semantic-extraction (script→fan-out→synthesize), routing-demo (classify→route→fan-out), fan-out-test (chunker→parallel)
- llm-orc primitives: file_ops, data_transform, control_flow, user_interaction
- Available Ollama models: qwen3:0.6b, gemma3:1b, gemma3:12b, llama3, mistral

---

## Question 3: How should Invariant 10 and the competence boundary model change?

**Method:** Analysis — applying the findings from Q1 (revised competence map) and Q2 (concrete ensemble architectures) to redesign the competence boundary framework. Cross-referenced against existing invariants, the self-evaluation findings, and the task type taxonomy.

**Findings:**

### The conflation in current Invariant 10

Current wording: "The conductor does not route multi-step reasoning (3+ steps), knowledge-intensive Q&A, or complex instructions (>4 constraints) **to local models** regardless of available model size."

The phrase "to local models" conflates two levels of operation:
- Routing a task to an individual LLM agent (Level 1)
- Routing a task to an ensemble system of scripts + LLMs + fan-out (Level 2)

Q1 and Q2 demonstrated that tasks blocked by this invariant — cross-file analysis, knowledge Q&A, decomposable multi-step reasoning — become delegable when the ensemble handles the complexity that exceeds any individual model. The invariant correctly protects individual agents but incorrectly blocks ensemble-level delegation.

### The two-level competence model

**Level 1: Agent-level competence (unchanged)**

What a single LLM agent within an ensemble can handle. These boundaries are correct and empirically grounded:

- No multi-step reasoning (3+ sequential steps) per agent
- No tasks requiring world knowledge the model lacks
- No handling of 4+ interacting constraints simultaneously
- No cross-document relationship understanding per agent
- No aesthetic or design judgment

Every LLM node in every Q2 architecture respects these boundaries. A fan-out agent sees one file, one comparison, one item. The boundaries constrain ensemble *composition*, not ensemble *routing*.

**Level 2: Ensemble-level capability (new)**

What a composed system can handle, provided each individual agent stays within Level 1. An ensemble can handle a task that exceeds any individual agent's competence when four conditions hold:

1. **DAG-decomposable** — the task decomposes into a directed acyclic graph of agents. No cycles, no backtracking.
2. **Script-absorbable** — the non-LLM complexity (file I/O, parsing, searching, tool execution) can be handled by script agents.
3. **Fan-out-parallelizable** — the LLM work can be divided into bounded per-item tasks via fan-out.
4. **Structured-synthesizable** — the synthesis step combines structured per-item outputs, not raw unstructured data.

When all four hold: **ensemble-delegable.** When any fails: Claude-only.

**Level 3: Irreducibly Claude-only**

Tasks that fail the four-condition test. Five irreducible criteria:

| Criterion | Why it can't be ensembled | Example |
|-----------|--------------------------|---------|
| **Recursive reconsideration** | Later reasoning must revise earlier conclusions — not a DAG | Debugging where fixing attempt A reveals the real bug is B |
| **Interacting constraints** | Constraints form a cycle, not decomposable | Code where requirement 3 changes how requirement 1 should work |
| **Holistic judgment** | Answer depends on seeing everything simultaneously | "What's the best API shape for this module?" |
| **Novel insight** | The connection isn't in any per-item analysis | Noticing that two unrelated modules have a race condition |
| **Aesthetic judgment** | Fundamental model capability gap | Design taste, naming quality, code elegance |

The **DAG decomposability test** is the practical discriminator: if you can draw the task as a flow where scripts gather, LLMs analyze per-item, and a synthesizer combines — it's ensemble-delegable. If any step needs to see the whole picture or revise prior steps, it's Claude-only.

### The three-category task type taxonomy

The binary "delegable / Claude-only" taxonomy becomes three categories:

| Category | Definition | How Routed |
|----------|-----------|------------|
| **Agent-delegable** | A single small model handles it. Bounded, single-concern, fits extraction/classification/template-fill/summarization/mechanical-transform/boilerplate-gen. | Simple ensemble (single agent or basic swarm) |
| **Ensemble-delegable** | Exceeds individual agent competence but passes the four-condition test. Scripts handle gathering, fan-out LLMs handle per-item analysis, synthesizer combines. | Multi-stage ensemble (script → fan-out → synthesize) |
| **Claude-only** | Fails the DAG decomposability test. Requires recursive reasoning, interacting constraints, holistic judgment, or novel insight. | Claude-direct (possibly with ensemble-prepared input) |

### How existing "Claude-only" types reclassify

| Old Type | New Classification | Key Insight |
|----------|-------------------|-------------|
| Cross-file code analysis | **Ensemble-delegable** | Scripts gather across files; LLMs analyze per-file |
| Architectural design | **Split:** gathering = ensemble-delegable, choice = Claude-only | Ensemble prepares brief; Claude decides |
| Debugging | **Split:** evidence = ensemble-delegable (~80%), insight = Claude-only | Scripts run tests/parse; Claude connects dots |
| Multi-step reasoning (sequential) | **Ensemble-delegable** | Pipeline of single-step agents |
| Multi-step reasoning (recursive) | **Claude-only** | Backtracking requires single context |
| Multi-constraint code gen (independent) | **Ensemble-delegable** | Separate agents per constraint |
| Multi-constraint code gen (interacting) | **Claude-only** | Constraints form cycle |
| Knowledge-intensive Q&A (factual) | **Ensemble-delegable** | Script search + LLM extract |
| Knowledge-intensive Q&A (nuanced) | **Claude-only** | Requires reasoning about knowledge |
| Security analysis (tool-based) | **Ensemble-delegable** | Script scan + LLM classify |
| Security analysis (novel) | **Claude-only** | Requires deep expertise |
| Judgment / taste | **Claude-only** | Fundamental capability gap |

The pattern: most old "Claude-only" types **split** into an ensemble-delegable preparation phase and a Claude-only judgment phase. This is the key practical consequence — even when a task is ultimately Claude-only, the ensemble handles the preparation.

### The "ensemble-prepared Claude" pattern

A new workflow emerges for split tasks:

```
ensemble: gather evidence, analyze per-item, synthesize structured brief →
  Claude: make judgment decision on the brief
```

Claude receives a structured analysis instead of raw files. This dramatically reduces Claude's token consumption — from "read 15 files and design" to "review this structured brief and decide."

This pattern applies to:
- Architectural design (ensemble prepares component analysis → Claude chooses approach)
- Debugging (ensemble gathers evidence + per-layer analysis → Claude identifies root cause)
- Complex code gen (ensemble generates per-constraint drafts → Claude integrates)
- Nuanced Q&A (ensemble retrieves + extracts facts → Claude synthesizes nuanced answer)

**Token savings:** In the self-evaluation, 4 parallel Claude agents used ~35K+ tokens for gathering + analysis. An ensemble doing the same work uses 0 Claude tokens. Claude would only spend ~5K tokens on the final judgment synthesis — an ~85% reduction.

### Proposed Invariant 10 amendment

**Current:**
> "Local models operate within competence boundaries. The conductor does not route multi-step reasoning (3+ steps), knowledge-intensive Q&A, or complex instructions (>4 constraints) to local models regardless of available model size. These boundaries are evidence-based and adjustable only through the reflective loop. Competence boundaries constrain individual subtask routing decisions; the conductor may decompose any meta-task regardless of its overall complexity."

**Proposed:**
> "Competence boundaries operate at two levels. **Agent level:** no individual LLM agent within an ensemble handles multi-step reasoning (3+ steps), complex instructions (>4 constraints), or tasks requiring world knowledge or holistic judgment — regardless of model size. **Ensemble level:** a composed system of script agents, fan-out LLM agents, and synthesizers can handle tasks that exceed any individual agent's competence, provided the task decomposes into a DAG where each LLM node stays within agent-level boundaries. Tasks are genuinely Claude-only only when they require recursive reconsideration, interacting constraints, holistic judgment, or novel insight that no decomposition can produce. These boundaries are evidence-based and adjustable through the reflective loop."

Key changes:
1. "Local models" → "individual LLM agent within an ensemble" (Level 1)
2. New sentence establishing ensemble-level capability (Level 2)
3. Specific irreducible criteria replace the blanket exclusion list
4. The DAG decomposability test is the practical discriminator
5. Evidence-based adjustability preserved

### How the triage decision tree changes

The current tree's critical gap (Claude-only types classified but not enforced) resolves differently under the three-category model. The binary classification that caused the gap is replaced.

**Proposed triage flow:**

1. **Classify into three categories** using the DAG decomposability test:
   - Can a single small model handle it as-is? → **Agent-delegable**
   - Can it be decomposed into a script-gather → fan-out-analyze → synthesize DAG? → **Ensemble-delegable**
   - Does it require recursive reasoning, interacting constraints, holistic judgment, or novel insight? → **Claude-only**

2. **For agent-delegable:** Follow the existing routing steps (standing auth → task profiles → available ensembles → compose simple ensemble or default to Claude)

3. **For ensemble-delegable:** Check if a matching multi-stage ensemble exists. If yes, invoke it. If no, compose one using template architectures from Q2 (including script authoring). This is the new capability.

4. **For Claude-only:** Handle via Claude-direct. But first ask: **is there an ensemble-delegable preparation phase?** If the task splits into gathering + judgment, run the preparation ensemble first, feed its structured output to Claude.

Step 4 is the key innovation. The conductor doesn't just classify and route — for Claude-only tasks, it actively looks for ways to reduce Claude's workload through ensemble-prepared input.

### How this interacts with other invariants

**Invariant 3 (Composition over scale):** Already philosophically aligned. "Prefer swarms of small models over reaching for larger models" now means composition at the system level — scripts + small LLMs compose into systems that handle complex tasks. The invariant's spirit was always right; we're extending what "composition" means.

**Invariant 12 (Workflow architect):** Strengthened. The conductor's delegation potential grows significantly. When planning a workflow, the conductor now has three routing options per subtask instead of two, and can compose multi-stage ensembles that handle previously "Claude-only" preparation work.

**Invariant 4 (Calibration):** Unchanged. Multi-stage ensembles enter calibration like any ensemble — first 5 invocations evaluated. The ensemble is evaluated as a system (its final output), not per-agent.

**Invariant 5 (Sampled evaluation):** Unchanged. Evaluation samples the ensemble's output, not individual agent outputs within it.

### What genuinely remains Claude-only: the irreducible core

After this analysis, the irreducible Claude-only work is:

1. **The design decision itself** — not gathering information about options, but choosing between them
2. **The debugging "aha moment"** — not collecting evidence, but connecting unrelated observations
3. **Code generation with tightly interacting requirements** — where changing one part cascades through all others
4. **Novel pattern recognition** — seeing what no per-item analysis would reveal
5. **Aesthetic judgment** — quality of names, APIs, architecture elegance

This is a much smaller set than the current Claude-only classification. It represents perhaps 15-30% of total work in a typical session, down from the current ~48%.

### What the conductor needs to implement this

1. **Script authoring capability.** Composing multi-stage ensembles requires writing Python scripts for the gather/parse/structure phases. Claude writes the scripts (a judgment task), validates JSON I/O, places them in `.llm-orc/scripts/conductor/`.

2. **Template architecture library.** The five architectures from Q2 become templates. The conductor doesn't design multi-stage ensembles from scratch each time — it selects and customizes a template.

3. **Conductor-specific profiles.** Three tiers for internal ensemble composition:
   - `conductor-micro` (qwen3:0.6b) — per-item extraction, comparison, classification
   - `conductor-small` (gemma3:1b) — bounded analysis, template fill, simple synthesis
   - `conductor-medium` (llama3 or gemma3:12b) — multi-source synthesis, report generation

4. **The DAG decomposability test as a concrete procedure.** Heuristics for the conductor to determine whether a task is ensemble-delegable:
   - Can I list the items to process? (files, comparisons, search results) → fan-out candidate
   - Can I write a script that gathers the data without LLM reasoning? → script-absorbable
   - Does each item's analysis stand alone (no cross-item dependencies)? → parallelizable
   - Can the final step combine per-item JSONs? → synthesizable
   - If all yes → ensemble-delegable

### Self-evaluation findings integration

The self-evaluation found 8 issues to fix. Under the revised model:

1. **Critical: Claude-only type enforcement gap** → **Resolved differently.** The binary classification is replaced by three categories. The "gap" disappears because ensemble-delegable types are actively routed to multi-stage ensembles, not blocked and not falling through.

2. **MCP promotion tools not used** → Still valid. Unchanged by this research.

3. **User-decline fall-through** → Still valid. Unchanged.

4. **Vocabulary alignment** → Needs expansion. New terms: "agent-delegable," "ensemble-delegable," "DAG decomposability test," "ensemble-prepared Claude," "template architecture," "script authoring."

5. **`routing-config.yaml` missing fields** → Needs additional fields for three-category routing thresholds.

6. **Invariant wording mismatches** → Invariant 10 needs full rewrite; domain model needs amendment.

### Implications

1. **Invariant 10 needs a significant amendment**, not a minor tweak. The two-level competence model is a conceptual shift: boundaries apply at the agent level, capabilities emerge at the ensemble level.

2. **The task type taxonomy expands from 2 to 3 categories.** "Ensemble-delegable" is the new middle ground where scripts + fan-out + synthesis handle what individual models cannot.

3. **Most old "Claude-only" types split** into ensemble-delegable preparation and Claude-only judgment. This is the biggest practical consequence — the conductor actively reduces Claude's workload for every task, even genuinely Claude-only ones.

4. **The "ensemble-prepared Claude" pattern** is the key innovation. Claude receives structured briefs instead of raw files. Token savings of ~85% on preparation work.

5. **The conductor needs new capabilities**: script authoring, template architectures, conductor-specific profiles, and a concrete DAG decomposability test.

6. **The delegation potential rises from ~52% to ~70-85%.** With ensemble-as-system patterns, the conductor delegates not just simple extraction/classification but cross-file analysis, knowledge retrieval, test generation, and debugging evidence — reserving Claude for irreducible judgment.

**Sources:**
- Q1 findings: revised competence boundary map
- Q2 findings: five concrete ensemble architectures demonstrating the pattern
- Self-evaluation findings: triage gap resolution under three-category model
- Existing invariants: cross-referencing against Invariants 3, 4, 5, 10, 12
- Domain model: amendment implications for Invariant 10
