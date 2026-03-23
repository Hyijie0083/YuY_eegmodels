# Research Log: Proactive Task Decomposition and Ensemble Creation

## Question 1: How should the conductor decompose tasks into ensemble-able subtasks, and what does this look like in practice?

**Method:** Web research (task decomposition patterns in agentic LLM systems, Route-and-Reason framework, small model delegation literature) + worked example (manual decomposition of the PromotionHandler implementation session).

**Findings:**

### What the literature says

**Route-and-Reason (R2-Reasoner, arXiv 2506.05901)** is the closest existing framework to what we need. A router decomposes complex queries into subtask sequences, then assigns each subtask to the optimal model from a pool spanning sub-1B to hundreds of billions of parameters. The decomposer evaluates candidates across three dimensions:

1. **Conciseness** — avoid excessive fragmentation (fewer subtasks is better)
2. **Practicality** — estimated token cost using a baseline model
3. **Coherence** — logical continuity between adjacent subtasks

The subtask allocator classifies each subtask as easy/medium/hard based on model confidence (token probability thresholds), then maps difficulty levels to model capability tiers. Results: **84% average API cost reduction** with competitive or improved accuracy across six benchmarks.

**Key insight from R2-Reasoner:** Collaboration at the level of intermediate reasoning steps enables efficient coordination, but places immense demands on the quality of decomposition and the precision of routing. Bad decomposition compounds errors — the "17x error trap" where naive multi-agent architectures amplify errors multiplicatively.

**Amazon Science** confirms that switching to smaller specialized models yields 70-90% cost savings per subtask, but warns about **lost novelty** — "breaking tasks into subtasks and relying on specialized models may fail to capture serendipitous connections." The conductor should decompose for delegable subtasks, not decompose the entire task.

**ACONIC framework (arXiv 2510.07772)** provides a formal approach: model the task as a constraint satisfaction problem, apply tree decomposition to partition into minimal locally-consistent subtasks. Key finding: decomposition helps significantly when tasks exceed natural LLM complexity thresholds — 9-15% improvement on SAT-Bench, 30-40% on NL2SQL.

**The Intelligent AI Delegation paper (arXiv 2602.11865)** identifies a **complexity floor** below which delegation overhead exceeds value. Task characteristics that determine delegability: complexity, verifiability, reversibility, and contextuality. The framework establishes that the level of trust must align with true underlying capabilities — which maps directly to our calibration requirement.

**Small Language Models paper (arXiv 2506.02153)** confirms SLMs excel at function calling, structured output, and tool-use workflows. They struggle with complex reasoning, ambiguous tasks, and extended context. The sweet spot: "agentic workflows involving sequential tool invocations and multi-step reasoning within constrained domains."

### Subtask taxonomy (emerging from research)

The literature converges on these delegable subtask types:

| Subtask Type | Description | Model Tier | Ensemble Pattern |
|-------------|-------------|------------|-----------------|
| **Extraction** | Pull structured data from text using a fixed schema | Micro (≤1B) | Single agent or parallel extractors |
| **Classification** | Categorize input into enumerable labels | Small (1-4B) | Single agent |
| **Template fill** | Generate output following an established pattern | Small (4-7B) | Single agent |
| **Summarization** | Condense text preserving key points | Small (4-7B) | Single agent |
| **Mechanical transform** | Apply deterministic rules (line wrapping, formatting) | Micro (≤1B) | Single agent |
| **Boilerplate generation** | Produce repetitive code following a demonstrated pattern | Small/Medium (4-7B) | Single agent |

Non-delegable subtask types (remain with Claude):
- **Architectural design** — choosing between approaches, cross-file understanding
- **Debugging** — tracing failures across layers
- **Multi-constraint code generation** — 4+ interacting requirements
- **Judgment calls** — design taste, naming, API shape

### Worked example: the PromotionHandler session

I manually decomposed the session where we built the PromotionHandler (662 lines of code, 36 tests, 6 files modified) into individual subtasks and classified each:

**Phase 1: Research (pattern extraction)**

| # | Subtask | Type | Delegable? |
|---|---------|------|-----------|
| 1 | Read library_handler.py, extract: constructor signature, public method signatures, decorator patterns | Extraction | Yes — micro extractor |
| 2 | Read ensemble_crud_handler.py, extract same pattern | Extraction | Yes — micro extractor |
| 3 | Read profile_handler.py, extract same pattern | Extraction | Yes — micro extractor |
| 4 | Read provider_handler.py, extract same pattern | Extraction | Yes — micro extractor |
| 5 | Read server.py, extract: tool registration pattern, dispatch table structure, delegation stub format | Extraction | Yes — micro extractor |
| 6 | Read test_server.py, extract: fixture patterns, mock setup, assertion style | Extraction | Yes — micro extractor |
| 7 | Synthesize all patterns into a design brief for the new handler | Reasoning | No — requires cross-file judgment |

**Phase 2: Design (architecture)**

| # | Subtask | Type | Delegable? |
|---|---------|------|-----------|
| 8 | Design PromotionHandler class with 4 public methods | Architecture | No — multi-constraint design |
| 9 | Design helper methods (_get_tier_dirs, etc.) | Architecture | No — requires design judgment |
| 10 | Design wiring into server.py (import, init, setup, dispatch) | Architecture | No — cross-file integration |

**Phase 3: Implementation**

| # | Subtask | Type | Delegable? |
|---|---------|------|-----------|
| 11 | Write PromotionHandler class skeleton (constructor, method stubs) | Template fill | Borderline — follows established handler pattern |
| 12 | Write promote_ensemble method body | Code gen (5+ constraints) | No — complex business logic |
| 13 | Write list_dependencies method body | Code gen (3+ constraints) | No — complex business logic |
| 14 | Write check_promotion_readiness method body | Code gen (4+ constraints) | No — complex business logic |
| 15 | Write demote_ensemble method body | Code gen (simpler) | Borderline — fewer constraints |
| 16 | Write helper methods (_get_tier_dirs, etc.) | Template fill | Yes — follows established patterns |
| 17 | Write import statement in server.py | Mechanical | Yes — trivial |
| 18 | Write __init__ initialization | Template fill | Yes — follows existing handler init pattern |
| 19 | Write _setup_promotion_tools with @self._mcp.tool() decorators | Template fill | Yes — follows existing _setup_* methods |
| 20 | Write dispatch table entries | Template fill | Yes — mechanical pattern |
| 21 | Write delegation stubs | Template fill | Yes — mechanical pattern |

**Phase 4: Testing**

| # | Subtask | Type | Delegable? |
|---|---------|------|-----------|
| 22 | Design test class structure and fixture approach | Design | No — requires understanding test patterns |
| 23 | Write test fixtures and helper functions | Template fill | Borderline — after seeing test_server.py |
| 24 | Write first 3-4 tests establishing the pattern | Code gen | No — establishes the template |
| 25 | Write remaining ~30 tests following the established pattern | Template fill / boilerplate | Yes — strongly delegable |
| 26 | Debug 2 test failures (orphaned profile tests) | Debugging | No — required tracing callback chain |

**Phase 5: Lint fixes**

| # | Subtask | Type | Delegable? |
|---|---------|------|-----------|
| 27 | Fix mypy error (wrap with bool()) | Mechanical transform | Yes — deterministic |
| 28 | Fix E501 line-length violations (wrap docstrings) | Mechanical transform | Yes — deterministic |
| 29 | Fix C901 complexity violations (extract helpers) | Refactoring (design) | No — requires judgment about decomposition |

**Phase 6: Release**

| # | Subtask | Type | Delegable? |
|---|---------|------|-----------|
| 30 | Bump version in pyproject.toml | Mechanical | Yes — trivial |
| 31 | Write CHANGELOG entry | Summarization | Yes — summarize changes |
| 32 | Write commit message from staged diff | Summarization | Yes — summarize changes |
| 33 | Stage specific files | Mechanical | Yes (but risky action) |

### Analysis: what percentage was delegable?

| Category | Count | % |
|----------|-------|---|
| **Strongly delegable** (extraction, template fill, mechanical, summarization) | 17 | 52% |
| **Borderline** (pattern-following code gen after template established) | 4 | 12% |
| **Claude-only** (architecture, debugging, multi-constraint code, judgment) | 12 | 36% |

**Over half the subtasks** in what appeared to be a "Claude-only reasoning task" could have been handled by local models. The delegable subtasks cluster in three phases:

1. **Research phase** — all 6 pattern extraction subtasks
2. **Implementation phase** — the 5 server.py wiring subtasks (template fill)
3. **Testing phase** — the ~30 boilerplate test cases (after pattern established)

These aren't scattered randomly — they form **coherent blocks** where the same ensemble could handle multiple consecutive subtasks.

### What ensembles would have been useful?

1. **Handler Pattern Extractor** — "Read a Python file and extract: class name, constructor parameters and types, public method signatures with type hints, decorator patterns used, key imports." Swarm: 4 micro extractors (one per concern) → 1 small synthesizer. Reusable across any codebase with a handler pattern.

2. **Server Wiring Generator** — "Given a handler class with method signatures and the existing server.py patterns, generate: import statement, __init__ initialization, setup method with tool decorators, dispatch table entries, delegation stubs." Single agent, small/medium tier. Reusable for any new handler.

3. **Test Case Generator** — "Given a test pattern (fixtures, mocks, assertion style) and a method signature with expected behavior, generate a test case." Single agent, 4-7B. After calibration on 3-4 examples, generates the boilerplate for remaining tests.

4. **Lint Fixer** — "Given a Python file and a specific lint rule violation (E501, line/column), produce the minimal fix." Single agent, micro/small tier. Reusable across any Python project.

5. **Changelog Writer** — "Given a git diff, write a CHANGELOG entry matching the project's existing format." Single agent, summarization. Reusable.

### Critical observation: the decomposition IS the architecture

The conductor doesn't need to decompose the full task upfront. It needs to **observe Claude working and identify delegable subtask patterns as they emerge**. The PromotionHandler session had a natural structure:

```
Claude designs → local extracts patterns
Claude architects → local fills templates
Claude writes first tests → local generates remaining tests
Claude debugs → local applies mechanical fixes
```

This is an **interleaved** pattern, not a batch delegation. Claude and local models alternate, with Claude handling the judgment-heavy steps and local models handling the repetitive/mechanical steps in between.

### Implications

1. **The competence boundary (Invariant 10) is correct at the subtask level, wrong at the task level.** A "reasoning task" like "build a PromotionHandler" contains 52% delegable subtasks when decomposed. The invariant should be reframed: "Apply competence boundaries to individual subtasks, not to the overall task."

2. **The conductor should be an observer, not just a router.** Rather than receiving a task and deciding where to send it, the conductor should watch Claude's workflow and propose ensemble creation when it spots a delegable pattern repeating.

3. **Ensemble creation should be triggered by pattern recognition, not task classification.** The question isn't "is this an extraction task?" but "I see Claude about to do the same extraction 6 times — should I create an ensemble for it?"

4. **The R2-Reasoner decomposition quality metrics apply.** Conciseness (don't over-decompose), practicality (is the ensemble worth the setup cost?), and coherence (subtasks should form logical units).

5. **The 17x error trap is real.** Over-decomposition + unreliable small models = compounding errors. The conductor should err toward fewer, higher-confidence delegations rather than trying to delegate everything possible.

6. **Break-even matters.** Creating an ensemble has fixed costs (YAML authoring, validation, calibration). If a subtask pattern only appears once, Claude should just do it. The conductor should look for patterns that repeat 3+ times within a session or across sessions.

**Sources:**
- [Route-and-Reason (R2-Reasoner)](https://arxiv.org/html/2506.05901v2) — subtask decomposition and allocation across heterogeneous models
- [Amazon Science: Task Decomposition with Smaller LLMs](https://www.amazon.science/blog/how-task-decomposition-and-smaller-llms-can-make-ai-more-affordable) — cost optimization through decomposition
- [ACONIC: Systematic Decomposition of Complex LLM Tasks](https://arxiv.org/html/2510.07772v1) — formal decomposition via constraint satisfaction
- [Intelligent AI Delegation](https://arxiv.org/html/2602.11865) — delegation trust models and complexity floors
- [Small Language Models for Agentic AI](https://arxiv.org/pdf/2506.02153) — SLM capabilities in agentic workflows
- [17x Error Trap in Multi-Agent Systems](https://towardsdatascience.com/why-your-multi-agent-system-is-failing-escaping-the-17x-error-trap-of-the-bag-of-agents/) — coordination topology over agent quantity

---

## Question 2: Which ensemble patterns are worth the upfront investment, and how does break-even work?

**Method:** Analysis of worked example from Q1 + reasoning about software development workflow recurrence patterns + literature on automation ROI.

**Findings:**

### The investment model

Creating an ensemble has fixed costs paid in Claude tokens:

| Step | Estimated Claude Tokens |
|------|------------------------|
| Analyze subtask pattern | ~500 |
| Design ensemble (agents, system prompts, profiles) | ~1000 |
| Create + validate via MCP | ~150 |
| Calibration: 5 uses × evaluate each | ~2500 |
| **Total creation investment** | **~4000-5000** |

Variable cost per use after creation:
- Local inference: **0** (Ollama is free)
- Claude evaluation (15% sampling): ~200 tokens × 0.15 = **~30 tokens amortized**

If Claude would normally spend ~500 tokens on each subtask instance directly:
- Savings per delegated use: 500 - 30 = **~470 tokens**
- **Break-even: ~11 uses**

But this is the pessimistic single-session case. The real power is persistence:

### Amortization across sessions and projects

| Tier | Scope | Uses to break even | Realistic timeline |
|------|-------|-------------------|-------------------|
| **Local** | One project, one session | ~11 uses | One session with 11+ repetitions of the pattern |
| **Local, cross-session** | One project, many sessions | ~11 uses total | A few sessions |
| **Global** | All projects | ~11 uses across all projects | Days to weeks |
| **Library** | All users | Investment shared | Immediate for consumers |

An ensemble like "test case generator" used 30 times in a single test-writing session breaks even in that session alone (30 × 470 = 14,100 tokens saved vs. 5,000 invested). Promoted to global, it pays dividends across every future project.

A "changelog writer" used once per release across all projects breaks even in ~11 releases. Modest — but it persists forever once promoted.

### The universal ensemble catalog

Some subtask patterns recur so frequently in software development that ensembles for them should be created proactively — not as a response to a specific task, but as infrastructure. These are candidates for the conductor's "starter kit":

| Ensemble | Pattern | Recurrence | Creation Trigger |
|----------|---------|-----------|-----------------|
| **extract-code-patterns** | Read code files, extract structural patterns (class signatures, method shapes, decorator usage, import structure) into a structured summary | Every implementation task that starts with reading existing code | Proactive — create on first use of conductor |
| **generate-test-cases** | Given a demonstrated test pattern + method signature + expected behavior, generate a test case following the pattern | Every test-writing session with 5+ tests | Triggered when conductor sees Claude writing a 3rd test following the same pattern |
| **fix-lint-violations** | Given a file path, line number, rule name, and violation description, produce the minimal fix | Every commit that triggers pre-commit hooks | Proactive — always useful |
| **write-changelog** | Given a git diff or list of changes, produce a CHANGELOG entry in the project's format | Every release | Proactive — always useful |
| **write-commit-message** | Given a staged diff, produce a commit message following the project's convention | Every commit | Proactive — always useful |
| **generate-docstrings** | Given a function/method signature and body, produce an appropriate docstring | When writing 3+ functions in a session | Triggered by pattern recognition |
| **fill-boilerplate** | Given a code pattern template and parameters, generate code following the pattern | Most implementation tasks with repetitive structure | Triggered by pattern recognition |

The first five are **universal** — they apply to virtually all software projects. The conductor should offer to create them during its first session. The last two are **triggered** — they emerge when the conductor spots a pattern.

### Calibration for immediate use

The current design requires 5 calibrated uses before an ensemble is "established." This creates a chicken-and-egg problem for on-the-fly ensembles. Three mechanisms resolve this:

**1. Pattern-as-calibration.** When the conductor creates an ensemble from an observed pattern (e.g., "Claude just wrote 3 tests — create an ensemble for the rest"), the pattern examples serve as implicit calibration data. The conductor has already seen 3 examples of correct output. The ensemble's system prompt encodes that pattern.

**2. Trust-but-verify.** Use the ensemble immediately but evaluate every result during calibration. If the first use scores "good," confidence increases. If "poor," fall back to Claude for the rest of the session and flag the ensemble for adjustment.

**3. Soft calibration.** For universal ensembles (changelog writer, commit message), the task is well-defined enough that failure is obvious. Calibration still runs but the conductor can use output immediately — the user will see the result and can reject it.

The key insight: calibration isn't a gate that blocks use. It's a learning period where every use is evaluated. The ensemble is usable from invocation 1; it's just not trusted enough to skip evaluation until invocation 6+.

### When NOT to create an ensemble

The Intelligent AI Delegation paper's "complexity floor" applies — some subtasks cost more to delegate than to do directly:

- **One-off subtasks** — if a pattern won't repeat, Claude should just do it
- **Subtasks requiring context Claude already holds** — if Claude has 10K tokens of context about the codebase in its window, passing that context to a local model is expensive and lossy
- **Subtasks where correctness is hard to verify** — if the conductor can't tell whether the ensemble output is correct, delegation is risky
- **Subtasks faster for Claude than for ensemble setup** — typing `bool()` around an expression is faster than creating an ensemble for it

The threshold: **3+ expected repetitions within a session, or cross-session reusability.** Below 3, Claude should just do it. At 3+, the conductor should propose an ensemble.

### The conductor's proactive creation protocol

Based on this analysis, the conductor should:

1. **Maintain a catalog of universal ensembles** — create them during first session, calibrate over first few uses
2. **Watch for pattern emergence** — when Claude performs the same type of subtask 3 times, propose creating an ensemble
3. **Predict patterns from task analysis** — before Claude starts working, analyze the task and predict which subtask patterns will emerge based on task type + project context
4. **Always ask the user** — "I notice you're about to write 30 more tests following the same pattern. Want me to create an ensemble for this?" (Invariant 1)
5. **Track pattern frequency** — log which subtask patterns appear, how often, and in which projects. This informs which ensembles to promote to global.

### Implications

1. **The conductor should bootstrap a starter kit of universal ensembles.** Five ensembles (extract patterns, generate tests, fix lint, write changelog, write commit message) cover the most common recurring subtasks in software development. Create them proactively.

2. **The 3-repetition threshold is the creation trigger.** Below 3 expected repetitions, delegation overhead exceeds savings. At 3+, the ensemble is worth creating.

3. **Calibration doesn't block immediate use.** It just means every result is evaluated during the learning period. The conductor can use ensemble output from invocation 1.

4. **The three-tier promotion system IS the investment vehicle.** Create locally, promote to global if quality holds, contribute to library if universal. Each promotion expands the ROI.

5. **Pattern frequency tracking is essential.** The conductor needs to log which subtask patterns it sees, how often, and in which contexts. This drives both ensemble creation decisions and promotion decisions.

**Sources:**
- [20 Agentic AI Workflow Patterns](https://skywork.ai/blog/agentic-ai-examples-workflow-patterns-2025/) — reusable workflow patterns
- [AI-Driven Boilerplate Code Automation](https://www.gravitee.io/blog/boilerplate-code-automation) — recurring boilerplate patterns in software development
- [Intelligent AI Delegation](https://arxiv.org/html/2602.11865) — complexity floor for delegation decisions

---

## Question 3: How does proactive observation work mechanically in a Claude Code skill?

**Method:** Web research (Claude Code skill activation mechanics, official documentation) + analysis of existing skill architecture.

**Findings:**

### What a Claude Code skill actually is

A Claude Code skill is **instructions to Claude**, not an external process. The SKILL.md file is injected into Claude's system prompt when the skill is activated. There is no separate runtime, no background observer, no hooks — Claude itself is the only execution engine. Everything the conductor does, it does as Claude following the instructions in SKILL.md.

This has profound implications for "proactive observation":

- **There is no persistent observer.** Each Claude invocation starts fresh (modulo persisted files). The conductor can't "watch" Claude across turns — it IS Claude.
- **Auto-activation is unreliable.** Claude Code's skill auto-activation (matching user requests to skill descriptions) works roughly 50% of the time. The reliable path is explicit invocation via `/llm-conductor`.
- **The "observation" is self-monitoring.** When SKILL.md says "observe Claude's workflow," it means Claude follows embedded instructions to pause and assess whether delegation is appropriate at key decision points.

### Two-phase observation model

Given these constraints, the conductor's proactive observation operates in two phases:

**Phase 1: Upfront task analysis (on invocation)**

When the user invokes `/llm-conductor` or the skill auto-activates, the conductor performs task analysis immediately:

1. Run pre-flight discovery (ensembles, models, evaluation history)
2. Analyze the user's request for subtask patterns
3. Check the universal ensemble catalog for matches
4. Predict which subtask types will emerge based on task structure
5. Propose a delegation plan before Claude starts working

This is the reliable phase — it happens at the start of every conductor session and doesn't depend on mid-stream awareness.

**Phase 2: Mid-task pattern recognition (self-monitoring)**

The SKILL.md includes instructions like: "After performing the same type of subtask 3 times, pause and consider whether an ensemble should be created." This works because:

- Claude can count its own actions within a conversation
- Claude can recognize when it's repeating a pattern
- The instructions create a checkpoint: "before writing the 4th test case, consider delegation"

But this phase is inherently fragile. If the instructions are too aggressive, Claude pauses constantly. If too passive, it never triggers. The key design constraint: **Phase 2 triggers should be specific and rare**, not general and frequent.

### Mechanical implementation

The conductor's observation mechanism is embedded in SKILL.md as conditional instructions:

```
When you are about to perform one of these actions for the 3rd+ time in a session:
- Extract patterns from a code file
- Write a test case following an established pattern
- Apply a mechanical code fix
- Generate boilerplate following a template

PAUSE and consider:
1. Is there an existing ensemble for this subtask type?
2. If not, should one be created? (expected 3+ more repetitions?)
3. Is the pattern concrete enough to encode in a system prompt?

If yes to all three, propose ensemble creation to the user.
```

This is not a hook or callback — it's a behavioral instruction that Claude follows (or doesn't, depending on context pressure and prompt adherence). The reliability comes from making the triggers concrete and countable rather than abstract.

### Persisted state as the real observation layer

The conductor compensates for lack of persistent observation through **file-based state**:

| File | Purpose | Observation it enables |
|------|---------|----------------------|
| `routing-log.jsonl` | Records every routing decision | Cross-session pattern tracking: "extraction tasks appear in 80% of sessions" |
| `evaluations.jsonl` | Records quality scores | Quality trending: "this ensemble's scores are degrading" |
| `task-profiles.yaml` | Maps task types to ensembles | Learned routing: "we've seen this task type before, here's what worked" |
| `routing-config.yaml` | Standing authorizations and thresholds | User preferences: "always route extraction to this ensemble" |

On each invocation, the conductor reads these files during pre-flight discovery. This means the conductor **does** have cross-session memory — it just lives in files, not in a persistent process. The observation happens in aggregate: not "I saw Claude extract patterns 6 times in the last session" but "routing-log shows extraction subtasks in 8 of the last 10 sessions."

### What this means for the SKILL.md design

The conductor's SKILL.md must be designed around these constraints:

1. **Front-load analysis.** Phase 1 (upfront task analysis) is reliable. Put the heavy thinking there: analyze the task, check for existing ensembles, predict subtask patterns, propose a delegation plan.

2. **Use specific mid-task triggers.** Phase 2 (self-monitoring) works only with concrete triggers: "3rd test case," "3rd file extraction," not "when delegation seems appropriate." Encode these as explicit checkpoints in the workflow.

3. **Persist everything.** Every routing decision, evaluation, and pattern observation goes to disk. The conductor's cross-session intelligence comes entirely from reading these files at startup.

4. **Don't fight auto-activation.** The conductor should work well when explicitly invoked (`/llm-conductor`) and provide modest value when auto-activated. Don't design around guaranteed auto-activation — it won't happen consistently.

5. **Make Phase 1 the primary value driver.** If the conductor only does upfront task analysis + delegation planning (Phase 1), it's already useful. Phase 2 (mid-task triggers) is bonus value when it fires.

### The activation decision

Given unreliable auto-activation, the conductor faces a bootstrap problem: users must remember to invoke it. Three approaches:

1. **Explicit invocation only.** The user types `/llm-conductor` when they want delegation. Simple, reliable, user-driven. Matches Invariant 1 ("user decides").

2. **Auto-activation with graceful degradation.** The conductor skill description is written to match common task patterns. When it auto-activates, it adds value. When it doesn't, nothing is lost — Claude handles the task normally.

3. **Hybrid: always-on light mode.** SKILL.md includes a minimal preamble that fires on auto-activation: "Check if universal ensembles exist. If not, mention `/llm-conductor` as an option." Full conductor behavior only on explicit invocation. This serves as a gentle reminder without being intrusive.

Option 3 (hybrid) is the most robust. The light-mode preamble costs almost nothing when it fires and serves as a discovery mechanism for users who've forgotten about the conductor.

### Implications

1. **The conductor is Claude wearing a different hat**, not a separate system. All observation and delegation happens through Claude's own reasoning, guided by SKILL.md instructions.

2. **Upfront task analysis (Phase 1) is the reliable mechanism.** Design the conductor to front-load delegation decisions at invocation time, not to depend on mid-stream self-monitoring.

3. **Mid-task triggers (Phase 2) must be concrete and countable.** "After the 3rd test case" works. "When delegation seems appropriate" doesn't. Limit Phase 2 to 3-4 specific, well-defined triggers.

4. **File-based persistence is the cross-session memory.** The conductor's intelligence accumulates in routing logs, evaluations, and task profiles. Pre-flight discovery loads this history into each new session.

5. **The hybrid activation model resolves the bootstrap problem.** Light-mode auto-activation reminds users the conductor exists. Full behavior on explicit invocation.

**Sources:**
- [Claude Code Skills Documentation](https://docs.claude.dev/en/latest/skills) — official skill system mechanics
- [Claude Code Custom Slash Commands](https://docs.anthropic.com/en/docs/claude-code/slash-commands) — skill invocation and auto-activation behavior
- [Claude Code MCP Integration](https://docs.anthropic.com/en/docs/claude-code/mcp-servers) — how skills interact with MCP servers
