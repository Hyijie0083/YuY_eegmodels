# Hybrid Orchestration: Composing Local LLMs to Reduce Claude Token Usage

*2026-02-23*

## The Problem

Claude Code is powerful but expensive in tokens. Every task — from extracting a list of endpoints from a file to synthesizing architectural recommendations — consumes the same premium resource. Yet most tasks don't require frontier-model reasoning. Research shows that 77% of real-world LLM queries involve practical guidance, information-seeking, or writing that smaller models handle adequately. Organizations using model routing achieve 50-70% cost reduction by sending simple tasks to cheaper models while maintaining quality on complex ones.

The question is not whether to route tasks to smaller models, but how to do it well — and how to get better at it over time.

## The Approach: Claude as Conductor, Local Models as Orchestra

The `llm-conductor` skill turns Claude into an intelligent broker between its own capabilities and a fleet of local models running via Ollama, orchestrated through llm-orc's MCP interface. Claude handles what it's uniquely good at — reasoning, cross-cutting analysis, broad knowledge tasks — and delegates extraction, classification, summarization, and boilerplate work to local models composed into ensembles.

The architecture has five parts:

1. **Task triage** — Claude classifies incoming work and decides: handle directly, or delegate to llm-orc?
2. **Ensemble discovery and creation** — find an existing ensemble that fits, or build one on the fly
3. **Execution and evaluation** — invoke the ensemble, then judge the output quality
4. **Reflective learning** — log evaluations, adjust routing over time, flag LoRA training candidates
5. **Ensemble lifecycle** — promote good ensembles from local to global to community library

### What We Learned About the MCP Surface

llm-orc exposes 23 MCP tools covering the full ensemble lifecycle: discover, create, validate, invoke, and analyze. The surface is sufficient to build the conductor skill without modifying llm-orc itself, with one exception: there is no reverse-direction library contribution tool (library is read-only via MCP). The skill handles promotion through file operations and git.

Key MCP capabilities:
- `list_ensembles` + `check_ensemble_runnable` — discover what's available and whether it can run
- `create_ensemble` + `validate_ensemble` — build and verify new ensembles
- `invoke` — execute an ensemble with input data
- `analyze_execution` — inspect execution artifacts for token usage and timing
- `get_provider_status` — discover available Ollama models
- `list_profiles` — see configured model profiles and their tiers

Execution artifacts already contain per-agent token counts, costs, model names, and durations — everything needed for savings quantification without additional instrumentation.

### What We Learned About Small Model Capabilities

With a target ceiling of 7B parameters (12B acceptable but not the norm), the routing decision matrix is evidence-based:

**Route to local models (reliable at 4-7B):**
- Text extraction with fixed schemas and short documents (<8K tokens)
- Classification with enumerable label spaces
- Single-document summarization
- Simple JSON structured output with constrained schemas
- Single-function Python code generation (phi4-mini achieves 82.6% on HumanEval at 3.8B)

**Route to Claude (local models fail below 7B):**
- Multi-step reasoning (3+ steps) — the chain-of-thought threshold is ~10-13B parameters
- Knowledge-intensive Q&A — 7B models hallucinate at 58% on reference-based QA
- Complex instructions with 5+ constraints
- Cross-file code analysis, security review, architectural reasoning
- Multi-document synthesis requiring cross-reference

**The critical insight is composition over scale.** A single 7B model struggles with complex analysis. But a swarm of small models — each handling one narrow extraction or classification task — feeding into a slightly larger synthesizer can approximate frontier-model quality on structured analytical tasks. The existing `adr-swarm-review` ensemble demonstrates this: 8 tiny qwen 0.6b extractors feed 4 medium gemma 4b analyzers, which feed 1 gemma3 12b synthesizer. Each model operates within its competence.

This swarm pattern is the highest-leverage architecture for the conductor skill. Rather than reaching for larger models, we compose reasoning chains from small ones.

### The Routing Heuristic

The skill's routing decision follows a simple decision tree:

```
Can a local ensemble handle this?
 |-- Is it extraction, classification, or summarization?
 |     \-- Short document, fixed schema? --> LOCAL
 |-- Is it boilerplate code generation?
 |     \-- Single function, Python? --> LOCAL
 |-- Does it require multi-step reasoning? --> CLAUDE
 |-- Does it require broad knowledge? --> CLAUDE
 |-- Does it require >4 constraints? --> CLAUDE
 |-- Is there an existing ensemble with good evaluations? --> LOCAL
 \-- Default: CLAUDE (safe fallback)
```

This heuristic is deliberately conservative — Claude is the safe default. The skill gets more aggressive about local routing as it accumulates positive evaluations.

### The Reflective Evaluation Loop

After each llm-orc invocation, Claude evaluates the output using a 3-point rubric (poor/acceptable/good) with chain-of-thought reasoning before verdict. Research shows binary or low-precision rubrics are more reliable than fine-grained scales, and CoT-before-verdict measurably improves judge accuracy.

**Evaluation sampling strategy** (to control cost):
- Always evaluate the first 5 uses of any new ensemble (calibration)
- Sample-evaluate 10-20% of subsequent uses
- Always evaluate when the user provides negative feedback
- Skip evaluation for well-established ensembles (>20 uses, >80% acceptance)

**Token savings quantification** piggybacks on llm-orc's existing per-agent usage tracking. Each routing decision logs: local tokens consumed (from execution artifacts), estimated Claude tokens for the same task (based on output length), and the delta. Over time, the skill reports cumulative savings.

**The data flywheel** is the most important long-term property. Every evaluation record is a training triple: `(input, local_model_output, claude_judgment)`. These accumulate into:
1. A LoRA fine-tuning dataset for improving local models on specific task types
2. Training data for a local judge model that could eventually replace Claude's evaluation role
3. A routing history that informs threshold adjustments

When a task type accumulates 3+ "poor" evaluations with a consistent failure mode, the skill flags it as a LoRA training candidate and suggests fine-tuning. The user is always consulted.

### Ensemble Lifecycle: Local to Global to Library

Ensembles follow a three-tier promotion path based on quality and generality:

**Local** (`.llm-orc/` in project directory) — where all ensembles are born. Project-specific, ephemeral, experimental.

**Global** (`~/.config/llm-orc/`) — promoted when an ensemble has 3+ "good" evaluations and Claude assesses it as generalizable (no hardcoded paths, no project-specific prompts, works without project context). The skill copies the YAML and any referenced profiles.

**Library** (`llm-orchestra-library` git repo) — promoted when an ensemble has 5+ "good" evaluations, is generalizable, and the user agrees it's worth sharing. The skill handles the git workflow: branch, copy, commit, push, and optionally create a PR.

Generality assessment is a natural fit for Claude's reasoning: read the ensemble YAML and evaluate whether the system prompts, task descriptions, and model requirements are portable across projects.

**The user always decides.** The skill recommends promotion but never acts without explicit consent.

## Key Tradeoffs

**Composition vs. latency.** A swarm of 8 tiny models takes longer than a single Claude call, even though each individual inference is fast. The skill trades latency for token savings. For interactive use, this means the user waits longer for delegated tasks. The skill should be transparent about this: "Delegating to local models — this may take 30-60 seconds."

**Conservative routing vs. savings.** The safe default is Claude. More aggressive local routing saves more tokens but risks quality degradation. The reflective loop's purpose is to gradually shift this boundary based on evidence, not speculation.

**Evaluation cost vs. learning speed.** Every Claude evaluation costs tokens. Evaluating every invocation maximizes learning speed but may cost more than the savings. The sampling strategy is the compromise — calibrate new ensembles thoroughly, then trust established ones.

**LoRA investment vs. generality.** Fine-tuning a model for a specific task type improves that task but creates a specialized artifact that may not transfer. The skill should recommend LoRA only for recurring, well-defined task types where the base model consistently underperforms.

## What This Does NOT Do

- **Replace Claude for complex reasoning.** The conductor routes tasks; it doesn't pretend local models can do everything.
- **Use ML-based routing.** Research (RouteLLM, ICLR 2025) shows ML routing needs 65K+ labeled samples. Threshold-based routing with reflective adjustment is practical for a Claude Code skill.
- **Evaluate every invocation.** Sampling controls evaluation cost. Well-established ensembles are trusted.
- **Auto-promote ensembles.** The user always confirms promotion decisions.

## The Endgame

The fully mature conductor skill operates a data flywheel:

1. Claude routes tasks to local models, evaluating a sample of outputs
2. Evaluations accumulate as training data
3. LoRA fine-tuning improves local models on specific task types
4. A locally-trained judge model replaces Claude for routine evaluation
5. Claude's role narrows to: routing novel task types, evaluating edge cases, and strategic decisions

Each Claude token spent on evaluation today buys local model capability tomorrow. The system converges toward minimal Claude token usage while maintaining output quality through empirical feedback, not optimistic assumptions.

## Open Questions

1. **How should the skill handle ensemble composition for novel task types?** When no existing ensemble matches, what heuristics should guide creating a new swarm vs. falling back to Claude?
2. **What's the right granularity for task-type classification?** Too coarse (e.g., "code") and the routing is imprecise. Too fine (e.g., "Python async generator function") and there's insufficient evaluation data per category.
3. **Should the skill pre-check Ollama model availability and suggest downloads?** This adds a setup/onboarding dimension — ensuring the user has the right models pulled before ensembles can run.
4. **Can composable ensembles (ensembles-as-agents) enable a meta-routing architecture?** A "router ensemble" where Claude is the routing agent and local model ensembles are the worker agents could formalize the conductor pattern within llm-orc itself.
5. **What llm-orc features would make this easier?** A `library_contribute` MCP tool and a `promote_ensemble` tool (local → global) are obvious candidates.

## Sources

Research findings are documented in the research log. Key references:

- RouteLLM (lm-sys, ICLR 2025) — Performance Gap Recovered metric, routing cost-quality tradeoffs
- StructEval benchmark — small model structured output capabilities and failure modes
- Reflexion pattern / OpenAI Self-Evolving Agents cookbook — self-improving agent architectures
- LLM-as-Judge literature (Evidently AI, Cameron Wolfe, arXiv 2602.15481) — evaluation reliability, bias mitigation, cost budgeting
- Qwen3, Phi-4-mini, Gemma3 technical reports — model-specific capability boundaries
- LogRocket / OpenRouter State of AI 2025 — production routing patterns and empirical cost data
