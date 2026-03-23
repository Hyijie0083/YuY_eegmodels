# ADR-004: File-Based Persistence in .llm-orc/evaluations/

**Status:** Accepted

## Context

The conductor needs to persist routing decisions, evaluations, routing config, task profiles, and LoRA candidates. It operates within a Claude Code skill — no database is available. Invariant 7 requires every routing decision to log token savings. Invariant 8 requires evaluations to be persisted as training data. Invariant 9 requires routing config to be versioned.

The persistence location must be discoverable by the conductor across sessions and projects.

## Decision

All conductor state lives in the project's `.llm-orc/evaluations/` directory (alongside llm-orc's own `.llm-orc/` structure). Global state (cross-project) lives in `~/.config/llm-orc/evaluations/`.

```
.llm-orc/evaluations/
  routing-log.jsonl          # append-only: every routing decision
  evaluations.jsonl          # append-only: sampled quality evaluations
  routing-config.yaml        # current routing thresholds
  routing-config.v{N}.yaml   # versioned history for rollback
  task-profiles.yaml         # learned task-type → ensemble mappings
  lora-candidates.yaml       # task types flagged for fine-tuning
```

- **JSONL** for append-only logs (routing decisions, evaluations) — simple, greppable, one record per line
- **YAML** for human-readable config (routing config, task profiles, LoRA candidates) — editable by the user
- **Token savings** are computed per routing decision from llm-orc artifact token usage vs. estimated Claude equivalent (estimated from output length)

The conductor reads these files at the start of each session to inform routing. Global evaluations inform cross-project routing; local evaluations inform project-specific routing.

## Consequences

**Positive:**
- No external dependencies — file-based, works anywhere
- JSONL is append-only, safe for concurrent access within a session
- YAML config is human-readable and user-editable
- Training data (evaluations.jsonl) is directly usable for LoRA fine-tuning

**Negative:**
- No indexing — querying evaluation history requires scanning the file
- Token savings estimation (from output length) is approximate
- Two locations (local and global) add lookup complexity

**Neutral:**
- File sizes will be small for typical usage (hundreds to low thousands of records)
