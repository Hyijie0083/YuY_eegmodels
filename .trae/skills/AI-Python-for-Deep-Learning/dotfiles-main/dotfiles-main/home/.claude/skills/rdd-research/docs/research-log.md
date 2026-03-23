# Research Log: Claude-LLM-Orc Hybrid Orchestration Skill

## Question 1: What is the actual MCP tool surface of llm-orc, and what can we do with it from inside a Claude Code skill?

**Method:** Spike — called every llm-orc MCP tool to map capabilities, then explored existing ensembles, profiles, and artifacts.

**Findings:**

### MCP Tool Surface (23 tools)

The llm-orc MCP exposes a comprehensive CRUD + execution surface:

| Category | Tools | Purpose |
|----------|-------|---------|
| **Context** | `set_project` | Set active project directory for operations |
| **Ensembles** | `list_ensembles`, `create_ensemble`, `update_ensemble`, `delete_ensemble`, `validate_ensemble`, `check_ensemble_runnable`, `invoke` | Full lifecycle management and execution |
| **Profiles** | `list_profiles`, `create_profile`, `update_profile`, `delete_profile` | Model configuration management |
| **Scripts** | `list_scripts`, `create_script`, `get_script`, `test_script`, `delete_script` | Script agent management |
| **Artifacts** | `analyze_execution`, `delete_artifact`, `cleanup_artifacts` | Execution result analysis and cleanup |
| **Library** | `library_browse`, `library_search`, `library_copy`, `library_info` | Community ensemble library |
| **Discovery** | `get_provider_status`, `get_help` | Provider and model discovery |

**Key insight:** The surface is sufficient for the skill. We can discover → create → validate → invoke → analyze entirely through MCP.

### Available Providers and Models

- **Ollama** (local, running): 19 models including gemma3:12b, gemma3:1b, llama3, mistral, qwen3:0.6b, phi4-mini, deepseek-r1:1.5b, nomic-embed-text
- **Anthropic** (via Claude Pro/Max OAuth): claude-sonnet-4, claude-haiku-4 available
- **Google**: Not configured
- **No API key**: Anthropic access is OAuth-only through Claude subscription

### Existing Ensemble Patterns (13 ensembles found)

Five architectural patterns observed in the wild:

1. **Simple Sequential** — independent agents process same input (qa-pipeline)
2. **Fan-in Synthesis** — N parallel analysts → 1 synthesizer (security-review, code-review, product-strategy)
3. **Fan-out** — 1 chunker → N parallel processors (fan-out-test)
4. **Swarm** — many tiny extractors → medium analyzers → large synthesizer (adr-swarm-review)
5. **Composable** — ensembles as agents within other ensembles (NEW — just implemented)

The swarm pattern is especially relevant: `adr-swarm-review` uses 8 tiny qwen 0.6b models for extraction, 4 gemma 4b models for analysis, and 1 gemma3 12b for synthesis. This demonstrates the token-efficiency principle we want.

### Profile Tiers (observed)

| Tier | Example Profile | Model | Use Case |
|------|----------------|-------|----------|
| Micro | `ollama-qwen-tiny` | qwen3:0.6b | Extraction, simple classification |
| Small | `ollama-gemma-small` | gemma3:4b | Analysis, structured output |
| Medium | `ollama-gemma3-12b` | gemma3:12b | Synthesis, complex reasoning |
| Large | `default-claude` | claude-sonnet | Cross-cutting, broad knowledge |
| Research | `research-analyst` | claude-sonnet (OAuth) | Deep research, writing |

### Artifact Analysis

Execution artifacts are stored as JSON files at `.llm-orc/artifacts/<ensemble>/<timestamp>/execution.json`. The `analyze_execution` MCP tool can inspect these — this is our reflection hook. Artifacts contain full agent inputs, outputs, timing, model used, and status.

### Directory Structure (three tiers confirmed)

- **Local**: `.llm-orc/` in project directory (project-specific ensembles)
- **Global**: `~/.config/llm-orc/` (user-wide reusable ensembles)
- **Library**: `~/.claude/llm-orchestra-library/` (community-contributed, currently empty)

### Gaps Identified

1. **No task-routing mechanism** — nothing currently classifies tasks and routes to appropriate ensembles
2. **Profile-model mismatch** — some profiles reference models not installed in Ollama (e.g., llama3.1:8b)
3. **Library empty** — the promotion workflow from local → global → library has no implementation
4. **No evaluation persistence** — `analyze_execution` reads artifacts but nothing records quality judgments for future reference
5. **Composable ensembles are new** — untested in production, but architecturally critical for our design

**Implications:**

The MCP surface is rich enough to build the skill. The critical missing piece is the **intelligence layer** — Claude acting as the router, evaluator, and learner. The skill needs to:

1. Accept a task description from the user
2. Query llm-orc for available ensembles and models
3. Decide: existing ensemble, new ensemble, or Claude-direct?
4. Execute and evaluate results
5. Record evaluation for future routing decisions

The composable ensemble feature is a game-changer — it means we could build a "meta-ensemble" where the routing agent is Claude and the worker agents are local model ensembles. But the skill itself might be better as a Claude Code skill that *uses* llm-orc as a tool rather than *being* an llm-orc ensemble, since the routing logic needs Claude's broad reasoning.

---

## Question 2: What task types can small local models (≤7B) handle well, and where do they fall down?

**Method:** Web research — benchmarks, community experience, technical reports for models in our range.

**Constraint:** User specified a 7B parameter ceiling for local models. Also open to LoRA fine-tuning on top of base models for task-specific improvement.

**Findings:**

### Model Tiers Within the ≤7B Range

| Tier | Models Available Locally | Practical Ceiling |
|------|------------------------|-------------------|
| Sub-1B | qwen3:0.6b | Extraction only |
| 1-3B | gemma3:1b, deepseek-r1:1.5b | Basic summarization, simple Q&A |
| 3-5B | gemma3:4b, phi4-mini (3.8B) | Classification, extraction, basic code |
| 6-8B | llama3 (8B), mistral (7B) | Best local tier, competitive on focused tasks |

**Critical threshold:** Reliable chain-of-thought reasoning emerges around 10-13B. Everything ≤7B operates below that threshold and must be routed accordingly.

### Task Routing Matrix (evidence-based)

| Task | ≤7B Reliable? | Conditions | Failure Mode |
|------|--------------|------------|--------------|
| **Text classification** | Yes (4-7B) | Enumerable labels, examples in prompt | Open-ended or domain-specific |
| **Information extraction** | Yes (4-7B) | Fixed schema, document <8K tokens | Multi-hop, ambiguous, deeply nested |
| **Summarization** | Yes (4-7B) | Single document, <8K tokens | Multi-document synthesis |
| **Code generation** | Adequate (7B specialist) | Single function, Python, boilerplate | Multi-file, architecture, security |
| **Code review** | Adequate (7B) | Style, obvious bugs, small functions | Security, logic, cross-file |
| **JSON output** | Adequate (7B) | Simple schema, constrained output | Complex/nested schemas, YAML |
| **Multi-step reasoning** | No | 1-2 steps max at 7B | 3+ steps, planning, causal inference |
| **Creative writing** | Marginal | Short snippets only | Extended form, quality-sensitive |
| **Knowledge Q&A** | No | Only with RAG (answer in context) | Open-domain, factual accuracy |
| **Complex instructions** | Marginal | ≤4 explicit constraints | 5+ constraints, conflicting goals |

### Key Numbers

- Organizations using model routing achieve **50-70% cost reduction** by sending simple tasks local
- 77% of real-world queries involve practical guidance, information-seeking, or writing — tasks small models handle adequately
- Qwen3-0.6b: MMLU ~53% (near random on many topics), but useful for pure extraction
- Phi-4-mini (3.8B): HumanEval 82.6% — anomalously strong for its size on Python code
- 7B code specialists (Qwen2.5-Coder-7B): HumanEval 84.8%
- LLaMA-7B hallucination rate on reference-based QA: **58%**
- YAML generation is notably less reliable than JSON across all small models

### Model-Specific Notes

- **phi4-mini**: Strong on Python code and reasoning for its size (synthetic training data), weak on creative tasks, 92% English training data
- **qwen3:0.6b**: Only useful for extraction/classification, known JSON output bug when thinking mode disabled
- **gemma3:4b**: Solid middle ground for classification and extraction
- **deepseek-r1:1.5b**: Reasoning-focused but tiny — limited practical utility at this size
- **mistral (7B)**: Good general-purpose, strong on JSON, weaker on YAML

### LoRA Opportunity

The user is open to LoRA fine-tuning. Key research findings on LoRA with small models:
- Fine-tuning a 4B model on as few as 60-75 samples per class can beat GPT-4 on targeted classification tasks
- LoRA is most impactful for: (a) domain-specific classification, (b) consistent structured output format, (c) task-specific code patterns
- LoRA is less impactful for: general reasoning, knowledge recall, multi-step logic (these scale with base model size, not fine-tuning)

**Implication:** LoRA could close the gap for specific recurring tasks — e.g., a fine-tuned 4B model for "extract PR review comments as structured JSON" could outperform a general-purpose 7B.

### The Routing Heuristic (emerging)

The skill's routing decision comes down to:

```
Can a local model handle this?
├─ Is it extraction, classification, or summarization? → Likely yes (local)
├─ Is it single-document, <8K tokens? → Likely yes (local)
├─ Does it require multi-step reasoning? → No (Claude)
├─ Does it require broad knowledge? → No (Claude)
├─ Does it require >4 constraints? → No (Claude)
├─ Is it code generation? → Single function Python: local. Otherwise: Claude
└─ Is quality-critical output? → Claude evaluates local output
```

**Implications:**

The ≤7B constraint is workable but narrows the sweet spot significantly. The skill should route **extraction, classification, summarization, and boilerplate code** to local models. Everything else goes to Claude. The swarm pattern (many tiny extractors → synthesis) is the highest-leverage architecture because it keeps each local model within its competence.

The LoRA option is a powerful escape hatch — when the skill identifies a recurring task that local models handle poorly, it could flag it as a LoRA training candidate. This becomes part of the reflective learning loop: "qwen3:0.6b failed at X three times → recommend fine-tuning a LoRA for X."

**User refinement:** 12B models are acceptable but should not be the norm. The goal is composing reasoning chains from small models — the swarm pattern — rather than reaching for larger models. Token savings should be quantified using llm-orc's built-in usage reporting.

---

## Question 3: How should the reflective evaluation and learning loop work?

**Method:** Web research (production LLM routing evaluation patterns, LLM-as-judge literature, self-improving agent architectures) + spike (llm-orc token tracking internals).

**Findings:**

### llm-orc Token Tracking (spike result)

llm-orc already stores detailed per-agent usage in execution artifacts:

```json
{
  "metadata": {
    "usage": {
      "agents": {
        "agent_name": {
          "input_tokens": 147,
          "output_tokens": 56,
          "total_tokens": 203,
          "cost_usd": 0.0,
          "duration_ms": 2070,
          "model": "qwen3:0.6b",
          "model_profile": "micro-local"
        }
      },
      "totals": {
        "total_tokens": 203,
        "total_input_tokens": 147,
        "total_output_tokens": 56,
        "total_cost_usd": 0.0
      }
    }
  }
}
```

This gives us per-agent and total token counts, costs, models, and durations — everything needed for savings quantification. Ollama tokens are estimated (~4 chars/token), not exact, but sufficient for comparison.

### Evaluation Architecture (from research)

Production routing systems use a four-phase learning loop:

1. **Route and log** — record routing decision + task metadata
2. **Evaluate** — score output quality (sample, not every request)
3. **Persist** — store evaluation linked to routing decision
4. **Adjust** — update routing thresholds based on accumulated signals

**Key metric: Performance Gap Recovered (PGR)** from RouteLLM (ICLR 2025):

```
PGR = [score(router) - score(weak_model)] / [score(strong_model) - score(weak_model)]
```

A PGR of 0.9 means routing recovers 90% of strong-model quality. This is computable from our evaluation data.

### How to Score Quality Without Ground Truth

Best approaches ranked by implementability:

1. **Binary classification** ("helpful/unhelpful") — most reliable, least sensitive to prompt wording
2. **CoT-before-verdict** — judge reasons about quality first, then scores. Measurably better than score-first
3. **QAG (claim decomposition)** — extract claims from output, verify each. Produces auditable artifact
4. **SelfCheckGPT** — generate N samples, measure consistency. Hallucinated content is non-reproducible

**Critical finding on judge bias:** Using Claude to judge local model output is actually safe — the echo chamber risk applies when the *same model family* generates AND judges. Since we're using Ollama models for generation and Claude for judgment, the model families are different. However, Claude may have a *verbosity bias* — preferring longer responses regardless of quality.

**Mitigation:** Use a 3-point rubric (poor/acceptable/good) with explicit definitions, not open-ended quality assessment. Binary is even better for automated routing.

### Cost Control on Evaluation

**The break-even formula:**

```
max_eval_rate = savings_per_request / judge_cost_per_eval
```

Since local model inference is free (Ollama) and Claude evaluation costs tokens, we need to sample judiciously. Proposed approach:

- **Always evaluate**: first 5 uses of any new ensemble (calibration)
- **Sample evaluate**: 10-20% of subsequent uses
- **Triggered evaluate**: when user provides negative feedback
- **Never evaluate**: well-established ensembles with >20 uses and >80% acceptance rate

### Persistence Design (file-based)

```
.llm-orc/evaluations/
  routing-log.jsonl          # append-only: every routing decision
  evaluations.jsonl          # append-only: sampled quality evaluations
  routing-config.yaml        # current routing thresholds/preferences
  routing-config.v1.yaml     # versioned history for rollback
  task-profiles.yaml         # learned task-type → model mappings
  lora-candidates.yaml       # tasks flagged for fine-tuning
```

Each routing decision record:
```jsonl
{"id": "uuid", "timestamp": "ISO-8601", "task_type": "extraction|classification|summarization|code|analysis|...", "task_summary": "brief description", "ensemble_used": "name", "model_tiers_used": ["micro", "small"], "total_tokens_local": 1203, "estimated_claude_tokens": 850, "tokens_saved": 850, "duration_ms": 4200, "user_accepted": null}
```

Each evaluation record:
```jsonl
{"id": "uuid", "routing_id": "ref to decision", "judge": "claude-opus", "score": "good|acceptable|poor", "reasoning": "brief CoT", "failure_mode": null|"hallucination|incomplete|wrong_format|...", "judge_tokens_used": 312}
```

### Token Savings Quantification

To calculate "tokens saved," we need a baseline: **what would Claude have used for the same task?**

Approach: estimate Claude token cost as `input_tokens + estimated_output_tokens` where output estimate comes from the actual local model output length (assuming Claude would produce similar-length output). This is imperfect but directionally useful.

The evaluation report can then show:
```
Ensemble: adr-swarm-review
  Local tokens used: 4,800 (8 agents × ~600 tokens)
  Estimated Claude equivalent: 2,400 tokens (1 agent, same output length)
  Claude tokens actually saved: 2,400
  Quality rating: acceptable (based on 5 evaluations)
  Cost: $0.00 (local) vs ~$0.007 (Claude estimate)
```

### The Reflexive Learning Loop

Adapted from the Reflexion pattern and OpenAI's self-evolving agent cookbook:

1. **After each invocation**, Claude writes a brief verbal reflection: "The extraction was accurate but the synthesizer missed the security implications — a 7B model may not be sufficient for security analysis synthesis"
2. **Reflections accumulate** in `evaluations.jsonl` as the `reasoning` field
3. **Periodically** (every 20 evaluations or weekly), Claude reviews accumulated reflections and updates `task-profiles.yaml` — adjusting which task types route locally vs. to Claude
4. **LoRA candidates** are flagged when a task type has 3+ "poor" evaluations with a consistent failure mode
5. **Routing config is versioned** — each update creates a new version so degradation can be rolled back

### What NOT to Build

- **ML-based routing classifier** — requires 65K+ labeled samples (RouteLLM). Threshold-based is sufficient.
- **Real-time threshold adjustment** — introduces instability. Adjust in batch.
- **Universal judge on every request** — evaluation cost exceeds savings. Sample instead.
- **LLM judge for code correctness** — research shows judges are unreliable for math/logic. Use execution-based verification (run the code) instead.

**Implications:**

The reflective loop is feasible with file-based persistence. The key design decision: Claude acts as both **router** (deciding where to send tasks) and **judge** (evaluating output quality), which is appropriate because it's judging output from a *different model family* (Ollama). The token savings quantification piggybacks on llm-orc's existing per-agent usage tracking. The learning mechanism is threshold-based, not ML-based — practical for a Claude Code skill.

The biggest risk is **evaluation cost exceeding savings** on small tasks. The sampling strategy (always for new ensembles, sample for established ones) mitigates this.

**User additions (training data flywheel):**

1. **Accumulate training data as we go.** Every evaluation record `(input, output, claude_judgment)` is a natural training pair. Over time, this becomes a LoRA fine-tuning dataset for: (a) improving local model output quality on specific task types, (b) training a local judge model.
2. **Train a local judge eventually.** If Claude's evaluations are logged consistently, we can fine-tune a small Ollama model to replicate Claude's judgment — reducing evaluation cost to zero. This is the endgame: a fully local evaluation loop.

These transform the reflective loop from a cost center into a **data flywheel** — each Claude evaluation token spent today improves local model capability tomorrow.

---

## Question 4: What's the ensemble creation and promotion workflow?

**Method:** Spike — explored llm-orc library handler, ensemble CRUD handler, config manager, and directory resolution code.

**Findings:**

### Three-Tier Directory Hierarchy (confirmed from code)

| Tier | Path | Discovery | Write Access |
|------|------|-----------|-------------|
| Local | `{project}/.llm-orc/ensembles/` | `set_project()` or cwd walk-up | Yes (default target for `create_ensemble`) |
| Library | `$LLM_ORC_LIBRARY_PATH` or `{cwd}/llm-orchestra-library/` | Env var or convention | Read-only via MCP |
| Global | `~/.config/llm-orc/ensembles/` | Always present as fallback | Yes (manual or via skill) |

**Resolution order:** local → library → global. First match wins. `create_ensemble` always writes to local `.llm-orc/`.

### Current Flow: One-Way (Library → Local)

```
Library (read-only)
   ↓ library_browse, library_search
   ↓ library_copy
Local (.llm-orc/)
   ↓ create_ensemble, update_ensemble
Modified Ensemble
   ✗ No path back
```

**Critical gap:** No `library_contribute`, `library_promote`, or any reverse-direction tool exists. The library is consumption-only.

### What the Skill Needs to Implement

The promotion workflow is not in llm-orc — the skill must build it:

**1. Local → Global promotion:**
- Copy ensemble YAML from `{project}/.llm-orc/ensembles/{name}.yaml` to `~/.config/llm-orc/ensembles/{name}.yaml`
- Also copy any referenced profiles that don't exist globally
- Simple file operation — the skill can do this directly

**2. Global → Library contribution:**
- The library is a git repo at `~/.claude/llm-orchestra-library/` (or wherever `LLM_ORC_LIBRARY_PATH` points)
- Contributing means: copy YAML into the repo, git add, commit, push (and potentially create a PR)
- The skill can use Bash tool for git operations
- Requires the library repo to be cloned and writable

**3. The skill also needs to handle profile dependencies:**
- An ensemble references `model_profile: micro-local`, but what if that profile doesn't exist at the target tier?
- Promotion should check that all referenced profiles are available at the destination, and offer to copy them too

### Generality Assessment

The skill needs to evaluate whether an ensemble is project-specific or generalizable. Criteria:

| Signal | Project-Specific | Generalizable |
|--------|-----------------|---------------|
| Hardcoded file paths | Yes | No |
| Project-specific system prompts | Yes | No |
| Generic task description | No | Yes |
| Uses standard model profiles | No | Yes |
| Works without project context | No | Yes |
| Has been evaluated as "good" 3+ times | No | Yes |

Claude can assess these by reading the ensemble YAML and reasoning about the content. The user confirms.

### Proposed Promotion Flow

```
1. Ensemble created locally (via create_ensemble or skill)
2. Skill evaluates output quality over multiple uses
3. When quality is consistently "good" (3+ evaluations):
   a. Claude assesses generality
   b. Asks user: "This ensemble performs well. It appears [project-specific/generalizable]."
   c. If generalizable → offer to promote to global (~/.config/llm-orc/)
   d. If excellent (5+ "good" ratings, generalizable) → offer to contribute to library
4. User decides at each step
```

### Library Contribution Mechanics

Since the library is a git repo:
```bash
# Clone if not present
git clone https://github.com/mrilikecoding/llm-orchestra-library.git ~/.claude/llm-orchestra-library

# Copy ensemble
cp ~/.config/llm-orc/ensembles/my-ensemble.yaml ~/.claude/llm-orchestra-library/ensembles/category/

# Copy any required profiles
cp ~/.config/llm-orc/profiles/custom-profile.yaml ~/.claude/llm-orchestra-library/profiles/

# Commit and push (or create PR)
cd ~/.claude/llm-orchestra-library
git checkout -b contribute/my-ensemble
git add .
git commit -m "feat: add my-ensemble"
git push origin contribute/my-ensemble
# gh pr create ...
```

The skill can orchestrate this via Bash tool, with user confirmation at each step.

**Implications:**

The promotion workflow is the skill's responsibility, not llm-orc's. The three tiers already exist as directory structure — the skill just needs to move files between them and handle profile dependencies. The generality assessment is a natural fit for Claude's reasoning ability. The library contribution path uses standard git workflow — no new infrastructure needed.

The key invariant: **the user always decides.** The skill recommends but never promotes without explicit consent.
