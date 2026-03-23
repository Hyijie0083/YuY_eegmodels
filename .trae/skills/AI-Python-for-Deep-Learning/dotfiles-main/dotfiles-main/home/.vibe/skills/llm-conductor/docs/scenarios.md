# Behavior Scenarios

## Feature: Pre-Flight Discovery (ADR-007)

### Scenario: Conductor discovers available ensembles and models on first invocation
**Given** the conductor is invoked for the first time in a session
**And** Ollama is running with models gemma3:4b and qwen3:0.6b available
**And** the project has a `.llm-orc/` directory with one ensemble "extract-endpoints"
**When** the conductor runs pre-flight discovery
**Then** the conductor reports: 2 Ollama models available, 1 local ensemble found
**And** the discovery results are cached for the session

### Scenario: Conductor suggests model downloads for broken ensembles
**Given** the conductor runs pre-flight discovery
**And** ensemble "code-review" references profile "ollama-llama3" which requires model "llama3.1:8b"
**And** "llama3.1:8b" is not available in Ollama
**When** the conductor checks ensemble runnability
**Then** the conductor warns: "code-review requires llama3.1:8b which is not installed"
**And** suggests: `ollama pull llama3.1:8b`

### Scenario: Conductor loads evaluation history during discovery
**Given** `.llm-orc/evaluations/routing-log.jsonl` exists with 15 routing decisions
**And** `.llm-orc/evaluations/task-profiles.yaml` maps "extraction" to ensemble "extract-endpoints"
**When** the conductor runs pre-flight discovery
**Then** the conductor loads the task profiles into its routing state
**And** subsequent triage for extraction tasks references the learned mapping

---

## Feature: Task Triage and Routing (ADR-002)

### Scenario: Conductor routes an extraction task to a local ensemble
**Given** pre-flight discovery has completed
**And** ensemble "extract-endpoints" exists and is runnable
**And** task profiles map "extraction" to "extract-endpoints" with 8 prior invocations, 6 scored good
**When** the user asks: "Extract all API endpoints from server.py"
**Then** the conductor triages this as task type "extraction"
**And** recommends: "Route to ensemble 'extract-endpoints' (6/8 good evaluations)"
**And** asks the user for confirmation before proceeding

### Scenario: Conductor falls back to Claude for irreducible Claude-only task (simple task)
**Given** pre-flight discovery has completed
**And** the user's request is a simple task, not a meta-task requiring decomposition
**When** the user asks: "This concurrency bug only appears when three specific services interact — find the root cause"
**Then** the conductor triages this as debugging requiring recursive reconsideration
**And** applies the DAG decomposability test: fails (later reasoning must revise earlier conclusions)
**And** assigns delegability category: Claude-only
**And** handles the task directly via Claude, explaining: "This requires recursive reconsideration — handling via Claude"

> **Note (ADR-008, ADR-012):** If the user frames a cross-file analysis as a meta-task (e.g., via `/llm-conductor`), the conductor would decompose it — evidence gathering subtasks are ensemble-delegable even though the final diagnosis is Claude-only. See "Updated Workflow Planning with Three Categories" scenarios.

### Scenario: Conductor falls back to Claude when no ensemble matches
**Given** pre-flight discovery has completed
**And** no ensemble exists for task type "summarization"
**And** no task profile maps "summarization" to any ensemble
**When** the user asks: "Summarize this README file"
**Then** the conductor triages this as task type "summarization"
**And** reports: "No local ensemble available for summarization — handling via Claude"
**And** offers: "Would you like me to compose a new ensemble for summarization tasks?"

### Scenario: Conductor respects standing authorization
**Given** the user has previously granted standing authorization: "Always route extraction tasks to extract-endpoints"
**And** this authorization is recorded in routing-config.yaml
**When** the user asks: "Extract the class names from models.py"
**Then** the conductor triages this as "extraction"
**And** routes directly to "extract-endpoints" without asking for confirmation
**And** logs the routing decision to routing-log.jsonl

### Scenario: Conductor respects agent-level competence boundaries regardless of evaluation history
**Given** a simple (non-multi-stage) ensemble "deep-analysis" has 10 "good" evaluations for task type "analysis"
**When** the user asks: "What are the security implications of using eval() in this codebase?"
**Then** the conductor identifies this requires knowledge of vulnerability patterns
**And** applies the DAG decomposability test: tool-based scanning is ensemble-delegable, but novel vulnerability analysis requires expertise beyond any individual agent
**And** for a simple ensemble (no script agents), handles via Claude
**And** explains: "Novel security analysis requires knowledge beyond agent-level competence boundaries — handling via Claude"

> **Note (ADR-012):** A multi-stage ensemble with security scanning scripts (bandit, semgrep) could handle the tool-based detection portion. The conductor would offer to compose one if the pattern recurs.

---

## Feature: Ensemble Invocation and Token Tracking (ADR-004, ADR-005)

### Scenario: Conductor invokes ensemble and logs token usage
**Given** the user confirms routing "Extract endpoints from server.py" to ensemble "extract-endpoints"
**When** the conductor invokes the ensemble via llm-orc MCP
**And** the invocation completes with artifact showing 340 total local tokens
**Then** the conductor estimates Claude equivalent tokens from the output length
**And** appends a routing decision record to routing-log.jsonl with fields: task_type, ensemble_used, total_tokens_local, estimated_claude_tokens, tokens_saved
**And** presents the result to the user along with: "Local: 340 tokens, estimated Claude equivalent: ~280 tokens"

### Scenario: Conductor switches project context for internal ensemble
**Given** the conductor needs to classify a task using its internal triage ensemble
**When** the conductor invokes the internal ensemble
**Then** it first calls `set_project` pointing to `~/.claude/skills/llm-conductor/`
**And** invokes the internal ensemble
**And** immediately calls `set_project` pointing back to the user's project directory
**And** the user's project context is restored before any user-visible operation

---

## Feature: Evaluation and Reflection (ADR-003)

### Scenario: Conductor evaluates during calibration period
**Given** ensemble "summarize-doc" has been invoked 3 times (within calibration period of 5)
**When** the conductor receives output from a 4th invocation
**Then** the conductor evaluates the output (calibration requires evaluating every invocation)
**And** produces a reflection: reasoning about output quality before scoring
**And** renders a score: good, acceptable, or poor
**And** appends an evaluation record to evaluations.jsonl with fields: routing_id, score, reasoning, failure_mode

### Scenario: Conductor classifies failure mode on poor score
**Given** ensemble "classify-issues" produces output that is missing expected JSON fields
**When** the conductor evaluates the output
**And** scores it as "poor"
**Then** the conductor classifies the failure mode as "wrong-format"
**And** records the failure mode in the evaluation record
**And** presents to the user: "Output scored poor (wrong-format) — the ensemble did not produce valid JSON"

### Scenario: Conductor samples evaluation after calibration
**Given** ensemble "extract-endpoints" has completed calibration (5 evaluations: 4 good, 1 acceptable)
**And** it has been invoked 12 times total
**When** the conductor receives output from a 13th invocation
**Then** the conductor probabilistically decides whether to evaluate (10-20% chance)
**And** if not evaluating, presents the output directly without scoring

### Scenario: Conductor skips evaluation for trusted ensembles
**Given** ensemble "extract-endpoints" has 25 invocations with 22 evaluations scored acceptable or good (88%)
**When** the conductor receives output from a 26th invocation
**Then** the conductor skips routine evaluation (trusted: >20 uses, >80% acceptable-or-good)
**And** presents the output directly

### Scenario: Conductor always evaluates on negative user feedback
**Given** ensemble "summarize-doc" is trusted (>20 uses, >80% acceptable-or-good)
**When** the user indicates the output is unsatisfactory
**Then** the conductor evaluates the output regardless of trusted status
**And** scores it and records the evaluation with the user's feedback as context

---

## Feature: Ensemble Composition (ADR-005)

### Scenario: Conductor composes a simple ensemble for a single-concern task
**Given** no ensemble exists for task type "summarization"
**And** the user requests: "Compose an ensemble for summarizing documents"
**When** the conductor designs the ensemble
**Then** it creates a single-agent ensemble (no swarm needed for single concern)
**And** assigns a medium tier profile (4-7B model)
**And** writes the ensemble YAML to `.llm-orc/ensembles/summarize-doc.yaml`
**And** validates via `validate_ensemble`
**And** asks the user to confirm the design before first invocation

### Scenario: Conductor composes a swarm for a multi-concern task
**Given** no ensemble exists for task type "code-review"
**And** the user requests: "Compose an ensemble for reviewing Python code"
**When** the conductor designs the ensemble
**Then** it decomposes into extraction concerns: style-check, bug-detection, complexity-analysis
**And** creates extractors at micro/small tier for each concern
**And** creates a synthesizer at medium tier (7B) that depends on all extractors
**And** writes the ensemble YAML with `depends_on` relationships
**And** asks the user to confirm the design

### Scenario: Conductor uses 12B synthesizer only when justified
**Given** the conductor is composing an ensemble with 5 extractors and 2 analyzers
**When** the synthesizer must combine outputs from all 7 upstream agents
**Then** the conductor assigns the ceiling tier (12B) to the synthesizer
**And** explains: "Using 12B for synthesis across 7 agent outputs — 7B may not synthesize this breadth reliably"
**And** all extractors and analyzers remain at micro/small/medium tiers

---

## Feature: Ensemble Promotion (ADR-006)

### Scenario: Conductor recommends promotion to global tier
**Given** ensemble "extract-endpoints" has 4 evaluations scored "good" (exceeds 3+ threshold)
**And** the ensemble YAML contains no hardcoded file paths or project-specific prompts
**When** the conductor assesses the ensemble for promotion
**Then** it performs a generality assessment: "This ensemble uses standard profiles and generic prompts — it appears generalizable"
**And** presents the recommendation with evidence: "4/5 evaluations scored good. Recommend promoting to global tier."
**And** asks the user for consent

### Scenario: Conductor copies profile dependencies during promotion
**Given** the user consents to promoting ensemble "extract-endpoints" to global tier
**And** the ensemble references profile "micro-extractor" which exists in local `.llm-orc/profiles/` but not in `~/.config/llm-orc/profiles/`
**When** the conductor promotes the ensemble
**Then** it copies the ensemble YAML to `~/.config/llm-orc/ensembles/`
**And** copies "micro-extractor" profile to `~/.config/llm-orc/profiles/`
**And** verifies runnability at the destination via `check_ensemble_runnable`

### Scenario: Conductor recommends library contribution
**Given** ensemble "extract-endpoints" has 6 evaluations scored "good" at the global tier
**And** it passes generality assessment
**When** the conductor assesses for library contribution
**Then** it presents: "This ensemble has excellent quality (6/7 good) and is generalizable. Contribute to llm-orchestra-library?"
**And** on user consent, clones the library repo if needed
**And** creates branch `contribute/extract-endpoints`
**And** copies ensemble and profiles
**And** commits and offers to create a PR

### Scenario: Conductor declines promotion for project-specific ensemble
**Given** ensemble "analyze-our-api" has 4 evaluations scored "good"
**But** its system prompt references "our internal REST API at /api/v2/"
**When** the conductor assesses generality
**Then** it reports: "This ensemble appears project-specific (references internal API paths)"
**And** recommends keeping it in the local tier
**And** does not offer global promotion

---

## Feature: LoRA Candidate Flagging (ADR-003, Domain Model)

### Scenario: Conductor flags a LoRA candidate after repeated failures
**Given** task type "classification" has been routed to local ensembles 8 times
**And** 4 evaluations scored "poor" with failure mode "hallucination" (3+ poor with consistent failure mode)
**When** the conductor reviews accumulated evaluations
**Then** it flags "classification" as a LoRA candidate with failure mode "hallucination"
**And** records this in `lora-candidates.yaml`
**And** presents to the user: "Local models consistently hallucinate on classification tasks. Consider LoRA fine-tuning on a 4B base model using accumulated evaluation data."

### Scenario: Conductor does not flag without consistent failure mode
**Given** task type "summarization" has 3 "poor" evaluations
**But** failure modes are: hallucination, incomplete, wrong-format (no consistency)
**When** the conductor reviews accumulated evaluations
**Then** it does not flag "summarization" as a LoRA candidate
**And** notes the mixed failure modes in the routing log for future review

---

## Feature: Routing Config Versioning (ADR-002, ADR-004)

### Scenario: Conductor versions routing config on adjustment
**Given** routing-config.yaml is at version 3
**And** accumulated evaluations indicate extraction tasks route successfully 95% of the time
**When** the conductor adjusts the routing threshold for extraction (increasing confidence)
**Then** it writes routing-config.v3.yaml as a backup
**And** writes the updated routing-config.yaml as version 4
**And** logs the adjustment reason

### Scenario: Conductor rolls back routing config on degradation
**Given** routing-config.yaml was adjusted to version 5 (more aggressive local routing)
**And** subsequent evaluations show a spike in "poor" scores
**When** the user requests rollback
**Then** the conductor restores routing-config.v4.yaml as the current config
**And** logs the rollback with reason

---

## Feature: Integration — Conductor End-to-End Flow

### Scenario: Full cycle from triage through evaluation for a new task type
**Given** the conductor has completed pre-flight discovery
**And** no ensemble exists for "extraction" tasks
**When** the user asks: "Extract all TODO comments from the codebase"
**Then** the conductor triages as "extraction"
**And** reports: "No ensemble for extraction. I can compose one or handle via Claude."
**And** the user says: "Compose one"
**And** the conductor composes a single-agent extraction ensemble
**And** asks the user to confirm the design
**And** the user confirms
**And** the conductor creates the ensemble via `create_ensemble`
**And** invokes it
**And** evaluates the output (calibration: invocation 1 of 5)
**And** logs the routing decision with token savings
**And** presents the result with the evaluation score

### Scenario: Conductor reads evaluation files produced by prior sessions
**Given** a prior session wrote 10 entries to `.llm-orc/evaluations/routing-log.jsonl`
**And** wrote 5 entries to `.llm-orc/evaluations/evaluations.jsonl`
**And** wrote task-profiles.yaml mapping "extraction" → "extract-todos"
**When** the conductor starts a new session and runs pre-flight discovery
**Then** it reads all three files
**And** its routing decisions in this session are informed by the prior session's history

---

## Feature: Workflow Planning for Meta-Tasks (ADR-008)

### Scenario: Conductor decomposes a meta-task into a workflow plan
**Given** pre-flight discovery has completed
**And** universal ensemble "extract-code-patterns" exists and is runnable
**And** universal ensemble "generate-test-cases" exists and is runnable
**When** the user invokes the conductor with: "Build a new handler class following the existing handler pattern"
**Then** the conductor decomposes this into subtasks:
  - "Extract patterns from existing handlers" (task type: extraction, delegable)
  - "Design new handler class structure" (task type: architectural design, Claude-only)
  - "Generate handler skeleton from pattern" (task type: template fill, delegable)
  - "Write test cases for handler methods" (task type: template fill, delegable)
  - "Implement handler method bodies" (task type: multi-constraint code generation, Claude-only)
**And** produces a workflow plan with delegation assignments
**And** reports: "5 subtasks identified, 3 delegable (60%). Estimated savings: ~1500 tokens"
**And** presents the plan to the user for approval before execution

### Scenario: Conductor executes workflow plan with interleaved delegation
**Given** the user has approved a workflow plan with 5 subtasks
**And** subtask 1 is assigned to ensemble "extract-code-patterns"
**And** subtask 2 is assigned to Claude-direct
**When** the conductor begins execution
**Then** it invokes "extract-code-patterns" for subtask 1
**And** evaluates the ensemble output (calibration or sampling per ADR-003)
**And** passes the extraction result as context for subtask 2
**And** handles subtask 2 directly via Claude
**And** continues through the plan in order, alternating between ensemble and Claude as assigned

### Scenario: Conductor adapts workflow plan on poor ensemble output
**Given** the conductor is executing a workflow plan
**And** subtask 3 is assigned to ensemble "generate-test-cases"
**When** the ensemble output for subtask 3 scores "poor"
**Then** the conductor falls back to Claude for subtask 3
**And** reassigns remaining subtasks of the same type to Claude-direct
**And** reports: "Ensemble 'generate-test-cases' scored poor — falling back to Claude for remaining test generation subtasks"
**And** logs the adaptation in the routing decision record

### Scenario: Conductor skips workflow planning for simple tasks
**Given** pre-flight discovery has completed
**When** the user asks: "Extract all TODO comments from server.py"
**Then** the conductor identifies this as a simple task (single subtask, no decomposition needed)
**And** routes directly using the task triage mechanism (ADR-002)
**And** does not produce a workflow plan

### Scenario: Conductor applies competence boundaries at subtask level
**Given** the user invokes the conductor with: "Refactor the authentication module and write tests"
**When** the conductor decomposes this meta-task
**Then** subtask "Extract current auth module patterns" is classified as extraction (delegable)
**And** subtask "Design new auth architecture" is classified as architectural design (Claude-only, competence boundary)
**And** subtask "Generate test cases from new method signatures" is classified as template fill (delegable)
**And** the conductor does NOT reject the entire meta-task as "reasoning"
**And** competence boundaries are applied per-subtask, not to the meta-task

### Scenario: Conductor presents token savings after workflow completion
**Given** the conductor has completed executing a workflow plan
**And** 3 subtasks were delegated to ensembles (940 local tokens total)
**And** 2 subtasks were handled by Claude (1200 Claude tokens)
**When** the conductor presents the session wrap-up
**Then** it reports: "Workflow complete. 3/5 subtasks handled locally. Local: 940 tokens, estimated Claude equivalent: ~780 tokens saved"
**And** appends all routing decisions to routing-log.jsonl

---

## Feature: Universal Ensemble Starter Kit (ADR-009)

### Scenario: Conductor offers to bootstrap starter kit on first use
**Given** the conductor is invoked for the first time in a project
**And** pre-flight discovery finds 0 local ensembles
**And** Ollama has models gemma3:4b and qwen3:0.6b available
**When** the conductor completes discovery
**Then** it offers: "No local ensembles found. Create a starter kit of 5 universal ensembles? (~25K Claude tokens upfront, saves tokens from second session onward)"
**And** lists the 5 ensembles: extract-code-patterns, generate-test-cases, fix-lint-violations, write-changelog, write-commit-message
**And** waits for user consent before creating any

### Scenario: User selects a subset of starter kit ensembles
**Given** the conductor offers the starter kit
**When** the user says: "Just create extract-code-patterns and generate-test-cases"
**Then** the conductor creates only those 2 ensembles
**And** validates each via `validate_ensemble`
**And** does not create the other 3
**And** reports: "Created 2 starter kit ensembles. Both enter calibration (first 5 uses evaluated)."

### Scenario: Starter kit ensemble enters calibration on first use
**Given** universal ensemble "write-commit-message" was just created as part of the starter kit
**When** the conductor delegates a commit message subtask to it for the first time
**Then** the ensemble produces output immediately (trust-but-verify, ADR-011)
**And** the conductor evaluates the output (calibration: invocation 1 of 5)
**And** presents both the output and the evaluation to the user

### Scenario: Starter kit ensemble is promoted to global after calibration
**Given** universal ensemble "extract-code-patterns" has completed calibration
**And** 4 of 5 calibration evaluations scored "good"
**And** the ensemble uses standard profiles and generic prompts
**When** the conductor assesses the ensemble for promotion
**Then** it recommends promotion to global tier: "extract-code-patterns has 4/5 good evaluations and is generalizable"
**And** on user consent, promotes to `~/.config/llm-orc/ensembles/`

---

## Feature: Repetition Threshold for Ensemble Creation (ADR-010)

### Scenario: Conductor creates ensemble after predictive threshold during planning
**Given** the conductor is planning a workflow for: "Write tests for all 12 handler methods"
**And** no ensemble exists for task type "template fill" (test generation)
**When** the conductor decomposes the meta-task
**Then** it identifies 12 subtasks of type "template fill" (test generation)
**And** 12 exceeds the repetition threshold (3+)
**And** the workflow plan includes: "Create ensemble 'generate-test-cases' before test generation phase"
**And** reports: "12 test cases follow the same pattern — creating an ensemble saves ~5600 tokens vs. Claude handling all 12"

### Scenario: Conductor creates ensemble after adaptive threshold during execution
**Given** the conductor is executing a workflow plan
**And** Claude has handled 3 subtasks of type "extraction" (extracting patterns from 3 files)
**And** 4 more files remain to extract from
**When** the conductor reaches the 3rd completed extraction subtask
**Then** it proposes: "I've extracted patterns from 3 files using Claude. 4 more remain. Create an ensemble for the rest?"
**And** on user consent, creates the ensemble and uses it for the remaining 4 files

### Scenario: Conductor notes cost-benefit for ensemble creation below threshold
**Given** the conductor is planning a workflow
**And** the workflow has 2 subtasks of type "summarization"
**And** no ensemble exists for "summarization"
**When** the conductor evaluates whether to create a summarization ensemble
**Then** 2 is below the repetition threshold (3+)
**And** the workflow plan marks both subtasks for ensemble creation with a cost-benefit note: "This pattern may not recur — ensemble costs ~{N} tokens to compose but builds reusable infrastructure"
**And** the user decides whether to create the ensemble or handle via Claude

### Scenario: Conductor accounts for cross-session reuse in threshold decision
**Given** the conductor is planning a workflow
**And** the workflow has 2 subtasks of type "extraction"
**And** task-profiles.yaml shows "extraction" was routed 8 times in prior sessions
**When** the conductor evaluates whether to create an extraction ensemble
**Then** it considers cross-session frequency (8 prior + 2 current = 10 total uses)
**And** proposes ensemble creation despite in-session count being below threshold
**And** explains: "Only 2 extraction subtasks this session, but extraction appears in 80% of prior sessions — ensemble will pay off across sessions"

---

## Feature: Trust-but-Verify Calibration (ADR-011)

### Scenario: New ensemble is usable during calibration
**Given** ensemble "extract-code-patterns" was just created (0 prior invocations)
**When** the conductor delegates an extraction subtask to it
**Then** the ensemble produces output
**And** the output is presented to the user immediately
**And** the conductor evaluates the output (calibration: invocation 1 of 5)
**And** the evaluation score is recorded
**And** execution continues regardless of calibration status

### Scenario: Conductor falls back to Claude after poor calibration score
**Given** ensemble "generate-test-cases" is in calibration (2 prior invocations, both "good")
**When** the conductor delegates a test generation subtask and the output scores "poor"
**Then** the conductor reports: "Ensemble scored poor — falling back to Claude for remaining test generation in this session"
**And** reassigns all remaining test generation subtasks in the workflow to Claude-direct
**And** records the evaluation with failure mode

### Scenario: Pattern-as-calibration increases early confidence
**Given** Claude has handled 3 extraction subtasks producing correct output
**And** the conductor creates ensemble "extract-code-patterns" encoding Claude's demonstrated pattern
**When** the ensemble handles its first subtask
**Then** the evaluation record includes `calibration_context: "pattern-from-observation"`
**And** the conductor notes: "Ensemble created from 3 observed Claude outputs — higher confidence for calibration"

### Scenario: Ensemble transitions from calibration to established after 5 evaluations
**Given** ensemble "fix-lint-violations" has 4 calibration evaluations (3 good, 1 acceptable)
**When** the 5th invocation is evaluated and scores "good"
**Then** the ensemble transitions from calibration phase to established phase
**And** subsequent invocations are evaluated at 10-20% sampling rate (ADR-003)
**And** the conductor reports: "fix-lint-violations completed calibration (4/5 good). Now in established phase."

---

## Feature: Three-Category Delegability (ADR-012)

### Scenario: Conductor classifies a task as ensemble-delegable via DAG decomposability test
**Given** pre-flight discovery has completed
**And** the user asks: "Check all my markdown files for inconsistent terminology"
**When** the conductor triages this subtask
**Then** it classifies the task type as cross-file analysis
**And** applies the DAG decomposability test:
  - DAG-decomposable: yes (glob files → parse → compare per-pair → synthesize)
  - Script-absorbable: yes (file reading and term extraction are script work)
  - Fan-out-parallelizable: yes (each pair comparison is independent)
  - Structured-synthesizable: yes (match/mismatch per pair → report)
**And** assigns delegability category: ensemble-delegable
**And** recommends routing to a multi-stage ensemble

### Scenario: Conductor classifies a task as Claude-only when DAG test fails
**Given** pre-flight discovery has completed
**When** the user asks: "This function has a subtle race condition — find and fix it"
**Then** the conductor triages this as debugging
**And** applies the DAG decomposability test:
  - DAG-decomposable: no (fixing attempt A may reveal the real bug is B — recursive reconsideration)
**And** assigns delegability category: Claude-only
**And** handles via Claude, explaining: "This requires recursive reconsideration — handling via Claude"

### Scenario: Conductor defaults to Claude-only when uncertain about decomposability
**Given** pre-flight discovery has completed
**When** the user asks: "Analyze the error handling patterns across the API layer"
**And** the conductor is uncertain whether the analysis requires holistic judgment or is decomposable per-file
**Then** the conductor defaults to Claude-only (Invariant 2)
**And** explains: "Uncertain whether this decomposes into per-file analysis — defaulting to Claude"
**And** logs the triage decision for future reference

### Scenario: Conductor splits a previously Claude-only task into preparation and judgment
**Given** pre-flight discovery has completed
**When** the user asks via a workflow plan: "Design the API for the new auth module"
**Then** the conductor identifies the task type as architectural design
**And** recognizes it splits: preparation (ensemble-delegable) + judgment (Claude-only)
  - Preparation: "gather existing API patterns, extract module structures, analyze each component" → ensemble-delegable
  - Judgment: "choose the API shape given gathered context" → Claude-only
**And** the workflow plan reflects both phases

### Scenario: Conductor routes agent-delegable task through existing simple triage
**Given** pre-flight discovery has completed
**And** ensemble "extract-endpoints" exists and is runnable
**When** the user asks: "Extract all API endpoints from server.py"
**Then** the conductor classifies this as task type "extraction"
**And** assigns delegability category: agent-delegable
**And** follows the existing ADR-002 triage path (standing auth → task profiles → available ensembles)
**And** does NOT run the DAG decomposability test (unnecessary for agent-delegable types)

### Scenario: Conductor logs delegability category in routing decision record
**Given** the conductor routes a subtask
**When** it appends the routing decision to routing-log.jsonl
**Then** the record includes field `delegability_category` with value "agent-delegable", "ensemble-delegable", or "claude-only"
**And** for ensemble-delegable tasks, the record includes `dag_test_result` with the four condition outcomes

---

## Feature: Multi-Stage Ensemble Composition (ADR-013)

### Scenario: Conductor composes a multi-stage ensemble from a template architecture
**Given** the user requests: "Create an ensemble to check document consistency across my markdown files"
**And** template architecture "document consistency checker" is available
**When** the conductor composes the ensemble
**Then** it selects the "document consistency checker" template
**And** authors a script agent `parse_documents.py` that extracts terms, references, and cross-references from markdown
**And** creates a fan-out LLM agent using conductor-micro (qwen3:0.6b) for per-pair comparison
**And** creates a synthesizer agent using conductor-small (gemma3:1b) for grouping results
**And** the ensemble YAML includes script agents, LLM agents, fan-out, and `depends_on` relationships
**And** validates via `validate_ensemble`
**And** presents the design:
  ```
  Proposed ensemble: doc-consistency-checker
  Pattern: multi-stage (template: document-consistency)
  Agents:
    - parse-docs: script (extract terms and cross-refs from markdown)
    - compare-pairs: LLM, fan-out, conductor-micro (compare each term pair)
    - synthesize: LLM, synthesizer, conductor-small (group matches/mismatches)
  DAG: parse-docs → fan-out compare-pairs → synthesize
  Scripts authored: 1
  ```

### Scenario: Conductor authors script with validated JSON I/O
**Given** the conductor is composing a multi-stage ensemble
**When** it authors a script agent for file discovery
**Then** the script takes JSON input (e.g., `{"directory": ".", "pattern": "*.md"}`)
**And** returns JSON output (e.g., `{"files": ["README.md", "CHANGELOG.md"]}`)
**And** the conductor validates that the script's output JSON schema matches the downstream agent's expected input schema
**And** the script is saved to the ensemble's script directory

### Scenario: Conductor uses conductor-medium only when synthesizing 4+ upstream outputs
**Given** the conductor is composing a multi-stage ensemble with 5 fan-out LLM agents
**When** the synthesizer must combine outputs from all 5 upstream agents
**Then** the conductor assigns conductor-medium (gemma3:12b) to the synthesizer
**And** explains: "Using 12B for synthesis across 5 agent outputs — 8B may not synthesize this breadth reliably"

### Scenario: Conductor uses conductor-medium (8B) as default for fewer upstream outputs
**Given** the conductor is composing a multi-stage ensemble with 3 fan-out LLM agents
**When** the synthesizer must combine outputs from 3 upstream agents
**Then** the conductor assigns conductor-medium with llama3 (8B), not gemma3:12b
**And** does not invoke the ceiling exception

### Scenario: Script agent failure triggers Claude fallback, not poor evaluation
**Given** a multi-stage ensemble "cross-file-analyzer" is invoked
**And** the script agent `discover_files.py` throws a `FileNotFoundError`
**When** the conductor receives the error
**Then** it does NOT record a "poor" evaluation (script failures are infrastructure, not LLM quality)
**And** falls back to Claude for this subtask
**And** reports: "Script agent failed (FileNotFoundError) — falling back to Claude"
**And** logs the script failure separately from the evaluation log

### Scenario: Conductor composes a custom multi-stage ensemble when no template matches
**Given** the user requests: "Create an ensemble to analyze database query performance"
**And** no template architecture matches this task
**When** the conductor composes the ensemble
**Then** it designs a custom DAG:
  - Script: extract SQL queries from code
  - Script: run EXPLAIN on each query
  - Fan-out LLM: analyze each EXPLAIN output
  - Synthesizer: rank queries by performance concern
**And** presents the custom design for user approval
**And** does not claim template coverage

---

## Feature: Ensemble-Prepared Claude (ADR-014)

### Scenario: Conductor prepares a structured brief for a Claude-only judgment
**Given** the workflow plan includes subtask "Design the auth module API" (Claude-only)
**And** a multi-stage ensemble "cross-file-analyzer" exists and is runnable
**When** the conductor reaches this subtask
**Then** it identifies a separable preparation phase: gather existing API patterns, extract module structures
**And** invokes "cross-file-analyzer" to produce a structured brief
**And** presents the brief to Claude for the final judgment
**And** reports:
  ```
  Preparation: [structured brief — 12 API patterns found across 8 files]
  Local: 1200 tokens

  Judgment: [Claude's API design recommendation]
  Claude: 800 tokens (estimated 5000 without preparation — 84% reduction)
  ```

### Scenario: Conductor skips ensemble preparation when subtask is pure judgment
**Given** the workflow plan includes subtask "What should we name this module?" (Claude-only)
**When** the conductor reaches this subtask
**Then** it identifies no separable preparation phase (naming is entirely judgment)
**And** handles via Claude directly without ensemble preparation
**And** does not invoke any ensemble

### Scenario: Conductor skips ensemble preparation when preparation is trivial
**Given** the workflow plan includes subtask "Review this 20-line function for correctness" (Claude-only)
**When** the conductor estimates the preparation phase would consume < 500 tokens
**Then** it skips ensemble preparation (overhead exceeds savings)
**And** handles via Claude directly

### Scenario: Ensemble-prepared Claude pattern enters its own calibration
**Given** the conductor uses the ensemble-prepared Claude pattern for the first time with task type "architectural design"
**When** the combined output (brief + judgment) is produced
**Then** the conductor evaluates the combined output as a unit (pattern calibration: invocation 1 of 5)
**And** the evaluation assesses both brief completeness and judgment quality
**And** the evaluation record notes `pattern: "ensemble-prepared-claude"` and `pattern_invocation: 1`

### Scenario: Conductor attributes failure to brief vs judgment on poor combined score
**Given** an ensemble-prepared Claude subtask scores "poor"
**When** the conductor produces its reflection
**Then** it explicitly attributes the failure:
  - "Brief was incomplete — missing 3 of 8 source files" → preparation ensemble problem
  - OR "Brief was comprehensive but judgment drew wrong conclusion" → Claude reasoning problem
**And** if the brief was the problem, flags the preparation ensemble for review
**And** if the judgment was the problem, notes this is not an ensemble quality issue

### Scenario: Token tracking records both preparation and judgment for ensemble-prepared Claude
**Given** the conductor completes an ensemble-prepared Claude subtask
**When** it appends the routing decision to routing-log.jsonl
**Then** the record includes:
  - `preparation_tokens_local: 1200`
  - `judgment_tokens_claude: 800`
  - `estimated_full_claude_tokens: 5000`
  - `preparation_savings: 3000`
**And** the total savings are computed as: estimated_full_claude_tokens - (preparation_tokens_local + judgment_tokens_claude)

---

## Feature: Updated Workflow Planning with Three Categories (ADR-008, ADR-012)

### Scenario: Conductor decomposes meta-task using three-category taxonomy
**Given** pre-flight discovery has completed
**And** multi-stage ensemble "cross-file-analyzer" exists and is runnable
**When** the user invokes the conductor with: "Review the codebase for inconsistent error handling"
**Then** the conductor decomposes into subtasks:
  - "Discover all source files" → agent-delegable (script agent work, trivial)
  - "Extract error handling patterns from each file" → agent-delegable (per-file extraction)
  - "Compare patterns across files for inconsistencies" → ensemble-delegable (cross-file analysis, passes DAG test)
  - "Recommend a consistent error handling strategy" → Claude-only (holistic judgment)
**And** the workflow plan assigns delegability categories to each subtask
**And** reports: "4 subtasks: 2 agent-delegable, 1 ensemble-delegable, 1 Claude-only (ensemble-prepared)"

### Scenario: Conductor creates multi-stage ensemble during workflow preparation
**Given** the workflow plan identifies an ensemble-delegable subtask "compare patterns across files"
**And** no matching multi-stage ensemble exists
**And** the subtask pattern exceeds the repetition threshold (cross-file comparison will recur)
**When** the conductor prepares ensembles before execution (Step 4)
**Then** it selects the "cross-file analyzer" template architecture
**And** authors scripts and creates the multi-stage ensemble
**And** validates and presents the design to the user
**And** on user approval, the ensemble is ready for the execution phase

---

## Feature: Multi-Stage Ensemble Promotion (ADR-013, Invariant 11)

### Scenario: Conductor checks script portability during promotion
**Given** ensemble "doc-consistency-checker" has 4 evaluations scored "good"
**And** the ensemble contains script agent `parse_documents.py`
**When** the conductor assesses the ensemble for global promotion
**Then** it checks script portability:
  - No hardcoded project paths in scripts
  - Python dependencies are standard library only (or declared)
  - Script I/O contracts are generic (not project-specific field names)
**And** includes script portability in the generality assessment alongside profile dependencies

### Scenario: Conductor blocks promotion for non-portable scripts
**Given** ensemble "analyze-our-schema" has 4 evaluations scored "good"
**But** script agent `parse_schema.py` hardcodes path `/Users/dev/our-project/schema.sql`
**When** the conductor assesses generality
**Then** it reports: "Script parse_schema.py contains hardcoded project path — not portable"
**And** recommends keeping in local tier
**And** does not offer global promotion

---

> **Note:** Scenarios below are for ADRs 015–020. Several scenarios in the sections above (Ensemble Composition, Ensemble Promotion, LoRA Candidate Flagging, Multi-Stage Ensemble Composition) assign composition/authoring/promotion actions to the conductor. Per ADR-015, these actions move to the Ensemble Designer. The scenarios above remain valid as behavioral descriptions but the actor changes from conductor to designer for composition, script authoring, promotion execution, and LoRA flagging.

---

## Feature: Conductor/Designer Skill Separation (ADR-015)

### Scenario: Conductor requests a new ensemble from the designer
**Given** the conductor is executing a workflow plan
**And** the workflow plan identifies a gap: no ensemble exists for task type "semantic-extraction"
**And** the subtask pattern exceeds the repetition threshold (4 expected repetitions)
**When** the conductor reaches the preparation step
**Then** the conductor emits an ensemble-request artifact containing: task type ("semantic-extraction"), delegability category ("ensemble-delegable"), DAG test results, sample inputs from the workflow, and any prior evaluation data for similar tasks
**And** presents to the user: "No ensemble for semantic-extraction. Request one from the Ensemble Designer?"
**And** on user consent, the request is handed off to the designer
**And** the conductor falls back to Claude-direct for the current invocation while awaiting the designer's ensemble

### Scenario: Designer returns a validated ensemble to the conductor
**Given** the Ensemble Designer has received an ensemble-request artifact for task type "semantic-extraction"
**And** the designer has composed and validated ensemble "extract-semantics"
**When** the designer completes the ensemble
**Then** the designer produces a handoff artifact containing: ensemble name, DAG shape description, profiles used, any verification scripts included, and a readiness status
**And** the conductor can now invoke "extract-semantics" for subsequent routing decisions
**And** the ensemble enters calibration (Invariant 4: first 5 invocations evaluated)

### Scenario: Conductor provides evaluation feedback to the designer
**Given** ensemble "extract-semantics" has completed calibration
**And** 3 of 5 calibration evaluations scored "poor" with failure mode "incomplete"
**When** the conductor summarizes the evaluation data
**Then** the conductor produces a feedback artifact containing: ensemble name, scores (2 good, 3 poor), dominant failure mode ("incomplete"), sample inputs/outputs for poor evaluations
**And** presents to the user: "extract-semantics scored poor on 3/5 calibration. Send feedback to the designer for revision?"
**And** on user consent, the feedback artifact is handed off to the designer

### Scenario: User gates the transition between conductor and designer
**Given** the conductor identifies a need for a new ensemble
**When** the conductor proposes handing off to the designer
**Then** the user must explicitly consent before the transition occurs
**And** if the user declines, the conductor continues with Claude-direct for the subtask
**And** the conductor does not invoke the designer autonomously (Invariant 1)

### Scenario: Designer does not intervene during active orchestration
**Given** the conductor is mid-execution of a workflow plan
**And** ensemble "cross-file-analyzer" scores "poor" on an invocation
**When** the conductor adapts the workflow
**Then** the conductor falls back to Claude-direct for the current subtask (Invariant 2)
**And** records the evaluation with failure mode
**And** accumulates the feedback for a potential designer handoff after workflow completion
**And** does NOT pause execution to invoke the designer

---

## Feature: Verification Scripts (ADR-016)

### Scenario: Verification script computes embedding-based confidence within an ensemble DAG
**Given** a multi-stage ensemble "analyze-docs" contains:
  - LLM agent "analyzer" (qwen3:8b) producing analysis output
  - Verification script "embed-confidence" hosting MiniLM (22M params)
  - "embed-confidence" depends on "analyzer"
**When** the ensemble is invoked
**Then** "analyzer" produces its output
**And** "embed-confidence" computes cosine similarity between the output and the input
**And** the similarity score is included in the ensemble's artifact as a quality signal
**And** downstream agents can use the confidence score for routing or filtering

### Scenario: Verification script selects winner from complementary model outputs
**Given** a complementary ensemble "dual-extract" contains:
  - LLM agent "extractor-qwen" (qwen3:8b)
  - LLM agent "extractor-mistral" (mistral:7b)
  - Verification script "select-winner" hosting MiniLM
  - "select-winner" depends on both "extractor-qwen" and "extractor-mistral"
**When** the ensemble is invoked with an extraction task
**Then** both extractors produce output independently (no debate, no shared context)
**And** "select-winner" computes embedding-based confidence for each output
**And** "select-winner" selects the output with higher confidence via argmax
**And** the ensemble's final output is the selected winner, not a synthesis of both

### Scenario: Log-probability entropy provides zero-cost quality signal
**Given** a multi-stage ensemble contains LLM agent "classifier" (qwen3:4b) with logprobs enabled
**And** a verification script "entropy-check" that computes per-token Shannon entropy via numpy
**When** the classifier produces output with logprobs
**Then** "entropy-check" computes mean entropy across output tokens
**And** high entropy (above a designer-configured threshold) signals low confidence
**And** the entropy value is passed downstream for conditional routing (e.g., escalate to a larger model if entropy exceeds threshold)

### Scenario: Verification script expands what is ensemble-delegable
**Given** the conductor is triaging subtask "verify extracted facts against source documents"
**And** this task would normally require Claude-only (LLM quality judgment)
**When** the conductor applies the DAG decomposability test
**Then** condition 2 (script-absorbable) passes because NLI-based consistency checking via DeBERTa in a verification script can handle factual verification
**And** the task is classified as ensemble-delegable (not Claude-only)
**And** the conductor routes to an ensemble with a verification script for NLI-based checking

### Integration Scenario: Designer composes ensemble with verification script
**Given** the Ensemble Designer receives an ensemble-request for task type "fact-extraction"
**And** the design pattern library suggests a complementary pair with embedding-based verification
**When** the designer composes the ensemble
**Then** the designer authors a verification script hosting MiniLM with ONNX runtime
**And** the script takes JSON input: `{"candidates": [{"output": "...", "source": "qwen"}, {"output": "...", "source": "mistral"}]}`
**And** the script returns JSON output: `{"selected": "qwen", "confidence": 0.87, "method": "cosine_similarity"}`
**And** the designer validates the verification script's JSON I/O contract against the upstream LLM agents' output schema
**And** the ensemble is validated via `validate_ensemble` before handoff

---

## Feature: Architectural Complementarity (ADR-017)

### Scenario: Designer applies complementarity for a reasoning task
**Given** the Ensemble Designer receives an ensemble-request for task type "code-correctness-check"
**And** the task involves reasoning with determinable correct answers (code is correct or not)
**And** the design pattern library shows no prior data for this model pair on this task type
**When** the designer evaluates the complementarity pattern
**Then** the designer proposes a complementary ensemble: qwen3:8b + mistral:7b with a MiniLM verification script
**And** notes: "Complementarity applied — reasoning task with determinable answers. Union accuracy and contradiction penalty will be measured during calibration."
**And** the ensemble includes both LLM agents generating independently and a verification script selecting via argmax

### Scenario: Designer rejects complementarity for a generation task
**Given** the Ensemble Designer receives an ensemble-request for task type "summarization"
**And** summarization is open-ended generation (no single correct answer)
**When** the designer evaluates the complementarity pattern
**Then** the designer rejects complementarity: "Summarization is open-ended generation — self-MoA outperforms mixed-model MoA by 6.6% on generation tasks (Inv 15)"
**And** proposes a single-model ensemble instead

### Scenario: Designer measures union accuracy and contradiction penalty during calibration
**Given** complementary ensemble "dual-check" is in calibration (invocations 1–5)
**And** the conductor evaluates each invocation, recording per-model correctness
**When** calibration completes with 5 evaluations
**Then** the designer computes:
  - Union accuracy: fraction of inputs where at least one model was correct
  - Contradiction penalty: fraction where one model was confidently wrong while the other was right
**And** records both metrics in the design pattern library
**And** if union accuracy ≥ 0.80 and contradiction penalty ≤ 0.20, the design is confirmed
**And** if either threshold fails, the designer recommends reverting to single-model

### Scenario: Designer reverts to single-model after high contradiction penalty
**Given** complementary ensemble "dual-extract" completes calibration
**And** union accuracy is 0.85 (above threshold)
**But** contradiction penalty is 0.35 (above 0.20 threshold)
**When** the designer reviews calibration data
**Then** the designer reports: "High contradiction penalty (0.35) — the verification script is selecting the wrong model too often"
**And** recommends reverting to single-model (the model with higher individual accuracy)
**And** records the anti-pattern in the design pattern library: "qwen3:8b + mistral:7b pair has high contradiction penalty on extraction tasks"

### Integration Scenario: Complementary ensemble uses verification script for arbitration
**Given** complementary ensemble "dual-reason" contains:
  - LLM agent "reason-qwen" (qwen3:8b) with system prompt for reasoning
  - LLM agent "reason-mistral" (mistral:7b) with system prompt for reasoning
  - Verification script "select-best" hosting MiniLM
**When** invoked with a reasoning problem
**Then** "reason-qwen" and "reason-mistral" generate independently (no debate)
**And** neither agent sees the other's output
**And** "select-best" receives both outputs and computes confidence scores
**And** "select-best" returns the higher-confidence output as the ensemble result
**And** the conductor evaluates this result via the standard evaluation protocol (ADR-003)

---

## Feature: 14B Ceiling (ADR-018)

### Scenario: Designer uses 14B synthesizer for high-fan-in ensemble
**Given** the Ensemble Designer is composing a multi-stage ensemble with 6 fan-out LLM agents
**When** the synthesizer must combine outputs from all 6 upstream agents
**Then** the designer assigns the ceiling tier model (qwen3:14b) to the synthesizer
**And** explains: "Using 14B for synthesis across 6 agent outputs — this exceeds the 4+ upstream threshold"
**And** all extractors and analyzers remain at micro/small/medium tiers (≤7B)

### Scenario: Designer uses 8B default for low-fan-in ensemble
**Given** the Ensemble Designer is composing a multi-stage ensemble with 3 fan-out LLM agents
**When** the synthesizer must combine outputs from 3 upstream agents
**Then** the designer assigns conductor-medium (llama3.1:8b) to the synthesizer
**And** does not invoke the ceiling exception (3 < 4 upstream outputs)
**And** the ceiling tier (qwen3:14b) is not used

---

## Feature: Design Pattern Library (ADR-019)

### Scenario: Designer consults library for a new ensemble request
**Given** the design pattern library contains a successful pattern: "fan-out swarm with MiniLM verification works well for extraction tasks (union accuracy 0.88, 4/5 good calibration)"
**And** the Ensemble Designer receives an ensemble-request for task type "data-extraction"
**When** the designer queries the library by: delegability category (ensemble-delegable), template architecture (multi-stage), output type (structured extraction)
**Then** the designer finds the matching pattern
**And** proposes: "Found a successful extraction pattern — fan-out swarm with MiniLM verification. Adapting for data-extraction."
**And** customizes the pattern (specific system prompts, input schema) while reusing the DAG shape and verification approach

### Scenario: Designer records a pattern after successful calibration
**Given** ensemble "extract-semantics" completes calibration with 4/5 good scores
**And** the ensemble uses a fan-out swarm with MiniLM verification
**When** the designer records the calibration results
**Then** the designer writes to the design pattern library:
  - DAG shape: fan-out swarm → verification script → synthesizer
  - Profiles: qwen3:0.6b (extractors), qwen3:8b (synthesizer)
  - Verification technique: MiniLM embedding confidence
  - Task type characteristics: delegability (ensemble-delegable), template (multi-stage), output type (structured extraction)
  - Calibration results: 4/5 good
**And** future ensemble requests for similar task types will find this pattern

### Scenario: Designer investigates before recording an anti-pattern
**Given** ensemble "classify-bugs" completes calibration with 3/5 poor scores
**And** all 3 poor scores have failure mode "hallucination"
**When** the designer reviews the failure modes
**Then** the designer investigates: is the failure due to fixable configuration (bad prompt, wrong profile tier) or fundamental design flaw (wrong DAG shape for the task)?
**And** if fixable: records the investigation, proposes a revision, does not record as anti-pattern
**And** if fundamental: records in the design pattern library as anti-pattern with failure analysis: "Single-agent classification with qwen3:4b hallucinated on complex bug categories — task may require either a larger model or multi-stage decomposition"

### Scenario: Designer composes from first principles when no library match exists
**Given** the design pattern library has no entries for task type "dependency-graph-analysis"
**When** the Ensemble Designer receives an ensemble-request for this task type
**Then** the designer reports: "No matching pattern in the library — composing from first principles"
**And** designs a custom DAG based on the task's DAG decomposability test results
**And** after calibration, records the result (whether successful or anti-pattern) in the library

---

## Feature: Graph-Structured Memory Target (ADR-020)

### Scenario: System operates in degraded mode without graph backend
**Given** the graph memory backend (Plexus) is not yet integrated
**And** the conductor and designer use flat file persistence (ADR-004)
**When** the conductor needs to answer "what led to this poor evaluation result?"
**Then** the conductor reads routing-log.jsonl and evaluations.jsonl
**And** manually correlates entries by routing_id
**And** can identify the ensemble and profile used, but cannot traverse design decisions or calibration history without reading multiple files
**And** this is accepted technical debt — full provenance traversal is deferred to the graph backend

### Scenario: Conductor records provenance metadata in routing log
**Given** the conductor logs a routing decision to routing-log.jsonl
**When** the entry is written
**Then** the record includes provenance fields: `ensemble_spec_version` (which ensemble YAML was used), `profile_versions` (which profiles were active), `routing_config_version` (which routing config version informed the decision)
**And** these fields enable future migration to the graph memory layer without data loss
**And** the flat file format captures the provenance relationships that the graph will natively represent

### Scenario: Designer records design knowledge in pattern library YAML
**Given** the design pattern library is stored as `design-patterns.yaml` (flat file)
**When** the designer records a new pattern
**Then** the entry includes: task type characteristics, DAG shape, profiles, verification techniques, calibration results, and a cross-reference to the ensemble YAML
**And** the designer can read through the YAML to find similar patterns by manual inspection
**And** the YAML format supports recording but not structured similarity queries — this limitation is accepted until the graph backend is integrated

---

## Feature: Integration — Conductor/Designer End-to-End Flow (ADR-015, ADR-016, ADR-017)

### Scenario: Full cycle from conductor gap detection through designer composition to invocation
**Given** the conductor is executing a workflow plan with 6 extraction subtasks
**And** no ensemble exists for task type "extraction"
**And** the repetition threshold (3+) is met
**When** the conductor completes pre-flight discovery
**Then** the conductor emits an ensemble-request artifact: task type "extraction", 6 repetitions expected, sample input from the workflow
**And** the user approves the transition to the designer
**And** the Ensemble Designer queries the design pattern library — finds no match
**And** the designer composes a complementary ensemble: qwen3:8b + mistral:7b with MiniLM verification (reasoning task with determinable answers)
**And** validates via `validate_ensemble`
**And** hands off the validated ensemble to the conductor
**And** the conductor invokes the ensemble for the first extraction subtask
**And** evaluates the output (calibration: invocation 1 of 5)
**And** the ensemble enters calibration with both per-model correctness tracking and union accuracy measurement

### Scenario: Conductor evaluation feedback triggers designer revision
**Given** ensemble "dual-extract" completes calibration
**And** 3 of 5 scores are "poor" with failure mode "incomplete" and contradiction penalty 0.30
**When** the conductor summarizes feedback
**Then** the feedback artifact includes: scores, failure modes, per-model correctness, union accuracy (0.82), contradiction penalty (0.30)
**And** the user approves transition to the designer
**And** the designer reviews the feedback
**And** the designer identifies: contradiction penalty too high for complementary pattern
**And** proposes a single-model revision using the better-performing model
**And** records the anti-pattern in the design pattern library
**And** hands off the revised ensemble to the conductor for re-calibration
