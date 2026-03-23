# Proactive Task Decomposition: The Conductor as Workflow Architect

*2026-02-23*

## The Missing Half

The first essay on hybrid orchestration established how the conductor routes whole tasks to local models: extract this, classify that, summarize the other. But most real work isn't a single task — it's a meta-task like "build a PromotionHandler" or "run an RDD research cycle" that weaves together reasoning, extraction, generation, and mechanical steps over hours. When the conductor sees "build a PromotionHandler" and classifies it as "reasoning," it falls back to Claude for the entire job. The local models sit idle.

This is wrong — not because the classification is incorrect, but because the conductor is operating at the wrong altitude. It's classifying the meta-task when it should be *owning* it. The conductor shouldn't watch Claude work and occasionally suggest delegation. It should plan the workflow with a first-class objective: maximize local model leverage toward the user's goal, reserving Claude for the subtasks that genuinely require frontier reasoning.

Under this framing, invoking `/llm-conductor` isn't adding an efficiency overlay to Claude's normal workflow. It's choosing a fundamentally different mode of operation — one where the conductor architects the work plan, decomposes it into subtasks, routes each subtask to the cheapest model that can handle it, and uses Claude surgically for the 36% that truly needs it.

## What We Learned

### Most "reasoning tasks" are majority-delegable when decomposed

We manually decomposed a real session — building a 662-line PromotionHandler with 36 tests across 6 files — into 33 individual subtasks. The result was surprising:

| Category | Count | % |
|----------|-------|---|
| Strongly delegable (extraction, template fill, mechanical, summarization) | 17 | 52% |
| Borderline (pattern-following code gen after template established) | 4 | 12% |
| Claude-only (architecture, debugging, multi-constraint code, judgment) | 12 | 36% |

Over half the subtasks in what appeared to be a "Claude-only reasoning task" were delegable. The delegable work wasn't scattered randomly — it clustered into coherent blocks:

1. **Research phase** — 6 pattern extraction subtasks (reading existing handlers, extracting signatures and patterns)
2. **Implementation phase** — 5 server wiring subtasks (filling in imports, setup methods, dispatch tables following established patterns)
3. **Testing phase** — ~30 boilerplate test cases (following a pattern established by the first 3-4 tests)
4. **Release phase** — changelog, commit message, version bump

This structure is typical of software engineering work. The creative/judgment work (designing the handler, writing the first few tests, debugging failures) is followed by a long tail of mechanical work that follows the patterns already established. A workflow architect sees this structure before work begins and plans accordingly.

### The literature confirms: decompose subtasks, not whole tasks

The Route-and-Reason framework (R2-Reasoner) achieves 84% cost reduction by decomposing complex queries into subtask sequences and allocating each subtask to the smallest model that can handle it. Their decomposition evaluates three dimensions: conciseness (don't over-fragment), practicality (estimated cost), and coherence (logical continuity between subtasks).

Amazon Science's work on task decomposition with smaller LLMs reports 70-90% cost savings per delegated subtask, but warns about "lost novelty" — over-decomposition sacrifices the cross-cutting insights that emerge when a capable model sees the whole picture. This is precisely why the conductor must remain the architect: it holds the big picture while delegating the mechanical parts.

The Intelligent AI Delegation paper identifies a "complexity floor" below which delegation overhead exceeds value. The determining factors: complexity, verifiability, reversibility, and contextuality. A lint fix is low on all four — highly delegable. An architectural decision is high on all four — keep it with Claude.

Small Language Models research confirms that models under 7B excel at function calling, structured output, and constrained-domain tool use. They fail at complex reasoning, ambiguous tasks, and extended context. The sweet spot is "agentic workflows involving sequential tool invocations and multi-step reasoning within constrained domains" — precisely what our ensembles provide.

### Five universal ensembles as infrastructure

Some subtask patterns recur so frequently across all software projects that ensembles for them should exist as infrastructure — prerequisites the conductor depends on, not nice-to-haves it might create:

| Ensemble | What it does | Why it's infrastructure |
|----------|--------------|--------------------|
| **extract-code-patterns** | Read code files, extract structural patterns (signatures, decorators, imports) into structured summaries | The conductor's own research phase depends on pattern extraction |
| **generate-test-cases** | Given a test pattern + method signature + expected behavior, generate a test case | Every implementation meta-task includes a testing phase |
| **fix-lint-violations** | Given file, line, rule, and violation, produce the minimal fix | Every commit that triggers pre-commit hooks |
| **write-changelog** | Given a diff, produce a CHANGELOG entry in the project's format | Every release |
| **write-commit-message** | Given a staged diff, produce a commit message following project conventions | Every commit |

These five form the conductor's "starter kit" — created during its first session and promoted to global tier as soon as quality evidence supports it. Without them, the conductor can still plan workflows, but it has fewer tools to delegate to. With them, the conductor can immediately route the mechanical phases of most software engineering meta-tasks.

### Break-even analysis favors investment

Creating an ensemble costs approximately 4000-5000 Claude tokens (analysis, design, creation, and 5 calibration evaluations). After creation, each delegated use saves approximately 470 Claude tokens (500 tokens Claude would have spent minus 30 tokens amortized evaluation cost at 15% sampling).

Break-even: ~11 uses.

A test-case generator used 30 times in a single session breaks even immediately (14,100 tokens saved vs. 5,000 invested). Promoted to global tier, it pays dividends across every future project. Even a changelog writer used once per release breaks even after 11 releases — and it persists forever once promoted.

The three-tier promotion system is the investment vehicle. Create locally (project cost), promote to global (user-wide returns), contribute to library (community-wide returns). Each promotion widens the amortization base.

Under the workflow-architect framing, the investment case is stronger: the conductor doesn't create ensembles speculatively — it creates them because the work plan demands them. The ensemble is a tool the conductor needs to execute its plan.

### The conductor is Claude wearing a different hat

A Claude Code skill is instructions injected into Claude's system prompt. There is no background observer, no hooks, no persistent process. The conductor IS Claude, following different instructions. This constrains how the conductor operates — but the workflow-architect framing turns this constraint into a strength.

When the conductor owns the meta-task, there's no need for a separate "observer." The conductor doesn't watch Claude work and intervene — it *is* the worker, following a plan it designed. The plan front-loads all the decomposition and routing intelligence:

1. Analyze the meta-task and decompose into subtask phases
2. For each phase, identify which subtasks are delegable
3. Check which ensembles exist, which need creation
4. Present the workflow plan to the user
5. Execute the plan: Claude handles judgment subtasks, ensembles handle mechanical subtasks

Mid-task adjustments happen naturally — the conductor notices its plan needs updating as it works, just as any architect adjusts during construction. But the primary intelligence is in the plan, not in mid-stream observation.

Cross-session memory lives in files: `routing-log.jsonl`, `evaluations.jsonl`, `task-profiles.yaml`. Pre-flight discovery loads this history into each new session. The conductor's intelligence accumulates on disk, not in a persistent process. Over time, the conductor's plans get better because it knows which ensembles exist, which have good evaluations, and which subtask patterns recur.

## The Approach: Workflow Architect with Local-First Objective

The conductor's role is **workflow architect**. When invoked with a meta-task, its objective is to design and execute a workflow that maximizes local model leverage while achieving the user's goal. Claude is the expensive resource, used surgically for subtasks that genuinely require frontier reasoning.

### How it works

```
User invokes /llm-conductor with a meta-task
  |
  +-- Workflow planning
  |     +-- Pre-flight discovery (models, ensembles, evaluation history)
  |     +-- Decompose meta-task into phases and subtasks
  |     +-- Classify each subtask: delegable or Claude-only
  |     +-- Match delegable subtasks to existing ensembles
  |     +-- Identify gaps: delegable subtasks with no ensemble
  |     +-- Propose workflow plan with delegation map
  |     +-- Report: "X% of subtasks delegable, Y ensembles needed,
  |     |    Z need creation. Estimated savings: N tokens."
  |     +-- User approves (or adjusts) the plan
  |
  +-- Ensemble preparation
  |     +-- Create missing ensembles for planned delegations
  |     +-- Validate all ensembles are runnable
  |
  +-- Workflow execution
  |     +-- Execute subtasks in planned order
  |     +-- Claude handles judgment/reasoning subtasks directly
  |     +-- Conductor invokes ensembles for delegable subtasks
  |     +-- Evaluate ensemble outputs (always during calibration,
  |     |    sampled after)
  |     +-- Adapt plan if ensemble output is poor (fall back to Claude)
  |     +-- Adapt plan if new patterns emerge mid-execution
  |
  +-- Session wrap-up
        +-- Log all routing decisions with token savings
        +-- Report: "Used X local tokens, saved Y Claude tokens"
        +-- Update task profiles with new pattern mappings
        +-- Assess ensembles for promotion readiness
```

### Concrete example: an RDD cycle

Consider invoking `/llm-conductor` for an RDD research-to-build cycle. The conductor plans:

| Phase | Subtask | Handler | Rationale |
|-------|---------|---------|-----------|
| Research | Extract key concepts from web search results | Ensemble: extract-code-patterns | Structured extraction from text |
| Research | Classify concepts into categories | Ensemble: classify-concepts | Enumerable label space |
| Research | Synthesize findings into coherent narrative | Claude | Cross-source reasoning, judgment |
| Model | Extract nouns/verbs/relationships from research notes | Ensemble: extract-code-patterns | Pattern extraction |
| Model | Draft invariant candidates from extracted patterns | Claude | Requires design judgment |
| Model | Write domain model table structure | Ensemble: fill-boilerplate | Template fill from established format |
| Decide | Generate scenario templates from domain model | Ensemble: generate-from-template | Established Gherkin format |
| Decide | Fill scenario Given/When/Then with judgment | Claude | Requires reasoning about behavior |
| Decide | Write ADR structure (status, context, decision) | Ensemble: fill-boilerplate | Template fill |
| Decide | Write ADR rationale and consequences | Claude | Requires architectural reasoning |
| Build | Extract test patterns from existing test files | Ensemble: extract-code-patterns | Structured extraction |
| Build | Generate BDD test cases from scenarios | Ensemble: generate-test-cases | Pattern following |
| Build | Implement code to pass tests | Claude | Multi-constraint code generation |
| Build | Fix lint violations | Ensemble: fix-lint-violations | Mechanical transform |
| Build | Write commit messages | Ensemble: write-commit-message | Summarization |

Out of 15 subtask types, 9 are ensemble-delegable (60%). The conductor presents this plan upfront: "I can handle 60% of this RDD cycle with local models. Shall I proceed?"

### The interleaved execution pattern

The workflow isn't "Claude does a batch, then ensembles do a batch." It's interleaved:

```
Conductor plans → Claude designs → ensemble extracts →
Claude synthesizes → ensemble templates → Claude judges →
ensemble generates → Claude debugs → ensemble fixes
```

Claude and local models alternate, with Claude handling the judgment-heavy steps and ensembles handling the mechanical steps in between. The conductor orchestrates this alternation — it knows which subtask comes next and which handler owns it.

This interleaving is the natural structure of software engineering work. Creative decisions produce patterns; patterns get repeated mechanically; the next creative decision produces new patterns. The conductor's job is to recognize where each transition happens and route accordingly.

### The 3-repetition threshold for on-the-fly creation

When the plan identifies delegable subtasks with no existing ensemble, the conductor uses a 3-repetition threshold:

**Predictive (at planning time):** "The testing phase has 30 test cases following the same pattern. That's well above the threshold — I'll create a test-case generator ensemble."

**Adaptive (during execution):** "I've now extracted patterns from 3 files using Claude. There are 4 more files. Want me to create an extraction ensemble for the rest?"

Below 3 expected repetitions, the conductor uses Claude directly. The overhead of ensemble creation isn't worth it for 1-2 uses.

### Calibration without blocking

Current design requires 5 calibrated uses before an ensemble is "established." For ensembles created mid-workflow, three mechanisms prevent this from blocking progress:

**Pattern-as-calibration.** When the conductor creates an ensemble after seeing Claude do a subtask 3 times, those 3 examples are implicit calibration data. The ensemble's system prompt encodes the observed pattern.

**Trust-but-verify.** The ensemble is usable from invocation 1. Every result is evaluated during calibration. If the first use scores "poor," the conductor falls back to Claude for the rest of the session.

**Immediate feedback loop.** The user sees ensemble output immediately. Poor output is obvious (a malformed test case, a wrong lint fix). Calibration doesn't gate usage — it gates the decision to skip future evaluation.

### When NOT to delegate

The complexity floor applies. Some subtasks cost more to delegate than to do directly:

- **One-off subtasks** — a pattern that won't repeat isn't worth an ensemble
- **Context-heavy subtasks** — if the conductor already holds 10K tokens of relevant context, passing it to a local model is expensive and lossy
- **Unverifiable subtasks** — if the conductor can't tell whether the output is correct, delegation is risky
- **Trivial subtasks** — wrapping an expression with `bool()` is faster than setting up an ensemble

The conductor's plan explicitly marks these as "Claude-direct" and doesn't attempt to delegate them.

## Invariant 10: No Tension After All

> **Superseded:** The conclusion below ("No amendment needed") is contradicted by the amended Invariant 10 as established in ADR-012. The "ensemble as system" essay found that ensembles are programmable systems (scripts + LLMs + fan-out), not groups of models, and that competence boundaries must operate at two levels: agent-level (preserved) and ensemble-level (new). See `docs/essays/ensemble-as-system.md` and `docs/decisions/adr-012-three-category-delegability.md`.

The current Invariant 10 reads:

> "Local models operate within competence boundaries. The conductor does not route multi-step reasoning (3+ steps), knowledge-intensive Q&A, or complex instructions (>4 constraints) to local models regardless of available model size."

Under the workflow-architect framing, this invariant is correct as written. It applies to individual routing decisions — and the conductor makes individual routing decisions for individual subtasks. The conductor never routes "build a PromotionHandler" to a local model. It routes "extract method signatures from this file" to a local model and "design the handler's public API" to Claude.

The invariant was never wrong. We were applying it at the wrong altitude. The conductor operates above the invariant: it decomposes meta-tasks into subtasks, then applies competence boundaries correctly to each subtask. A subtask that requires multi-step reasoning stays with Claude. A subtask that requires mechanical extraction goes to an ensemble. The invariant constrains each routing decision; the conductor makes many routing decisions per meta-task.

No amendment needed.

## Key Tradeoffs

**Workflow planning cost vs. delegation savings.** Planning the workflow costs Claude tokens — decomposing the meta-task, classifying subtasks, designing the delegation map. For small tasks, this overhead may exceed the savings from delegation. The conductor should recognize when a task is too small to benefit from workflow planning and handle it directly. The threshold: if the meta-task has fewer than ~5 subtasks, or fewer than 3 delegable ones, skip workflow planning.

**Decomposition quality vs. over-fragmentation.** Good decomposition identifies coherent delegable blocks. Bad decomposition fragments work into tiny pieces that cost more to coordinate than to do directly. The R2-Reasoner literature warns that decomposition errors compound multiplicatively (the "17x error trap"). The conductor should err toward fewer, larger delegations — "extract patterns from all 6 files" is one ensemble invocation, not six.

**Upfront investment vs. immediate savings.** Creating universal ensembles before they're needed costs tokens now. The break-even analysis shows this pays off after ~11 uses — reasonable for universal patterns, but the user may not see returns in the first session. The conductor must be transparent: "Creating these 5 ensembles costs ~25K tokens now. They'll save tokens from the second session onward."

**Token savings vs. lost novelty.** When Claude handles an entire meta-task, it sometimes makes serendipitous connections between subtasks — noticing during test-writing that the API design has a flaw, or spotting a pattern during extraction that suggests a better architecture. Delegating subtasks to local models eliminates these cross-cutting insights for the delegated portions. The conductor mitigates this by reviewing ensemble outputs before proceeding to the next subtask, maintaining the big picture even when individual subtasks are delegated.

**Ownership vs. flexibility.** When the conductor owns the meta-task, it commits to a workflow plan. But real work is messy — requirements change, bugs emerge, the user pivots. The conductor must hold its plan loosely, adapting when circumstances change. The plan is a starting point, not a contract.

## What This Changes from the First Essay

The first essay described the conductor as a **router** — it receives a task, classifies it, and either delegates it to an ensemble or handles it via Claude. The routing heuristic is a decision tree applied to individual tasks.

This essay reframes the conductor as a **workflow architect** — it receives a meta-task, decomposes it into a workflow of subtasks, and designs a plan that maximizes local model leverage across the entire workflow. Routing still happens, but at the subtask level within a planned workflow.

The key differences:

| Aspect | First Essay (Router) | This Essay (Workflow Architect) |
|--------|---------------------|-------------------------------|
| Unit of work | Single task | Meta-task decomposed into subtasks |
| Conductor's role | Classify and route | Plan, decompose, orchestrate |
| When ensembles are created | When a task type has no ensemble | When the workflow plan needs one |
| Local-first objective | Implicit (route when possible) | Explicit (maximize local leverage) |
| Claude's role | Default handler | Surgical tool for judgment subtasks |
| Invocation scope | One task at a time | Entire workflows (RDD cycles, feature builds) |

Everything else from the first essay — the reflective evaluation loop, the data flywheel, the three-tier promotion system, calibration, sampling, token savings quantification — remains intact. These are mechanisms the workflow architect uses to execute its plans.

## The Endgame

The fully mature conductor operates as the default way complex work gets done:

1. User invokes `/llm-conductor` with a goal
2. The conductor plans a workflow, leveraging its catalog of calibrated ensembles
3. Claude handles the 36% that requires frontier reasoning
4. Local ensembles handle the 52% that's mechanical/extractive/template-based
5. The borderline 12% gets attempted locally with trust-but-verify
6. Ensemble quality improves through the evaluation flywheel
7. New ensembles get promoted to global tier, available across all projects
8. The conductor's plans get smarter as routing history accumulates

Each session makes the next session cheaper. Each project makes the next project cheaper. The conductor's value compounds.

## Sources

- Route-and-Reason (R2-Reasoner, arXiv 2506.05901) — subtask decomposition and allocation across heterogeneous models
- Amazon Science: Task Decomposition with Smaller LLMs — cost optimization through decomposition, lost novelty warning
- ACONIC (arXiv 2510.07772) — formal decomposition via constraint satisfaction
- Intelligent AI Delegation (arXiv 2602.11865) — delegation trust models and complexity floors
- Small Language Models for Agentic AI (arXiv 2506.02153) — SLM capabilities in agentic workflows
- 17x Error Trap in Multi-Agent Systems (Towards Data Science) — coordination topology over agent quantity
- Claude Code Skills Documentation (docs.claude.dev) — skill activation mechanics
