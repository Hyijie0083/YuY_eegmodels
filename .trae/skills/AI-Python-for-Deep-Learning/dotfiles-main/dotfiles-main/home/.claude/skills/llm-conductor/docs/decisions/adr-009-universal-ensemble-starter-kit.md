# ADR-009: Universal Ensemble Starter Kit

**Status:** Accepted

## Context

The conductor's value depends on having ensembles to delegate to. In a cold-start state — no ensembles exist, no evaluation history, no task profiles — the conductor falls back to Claude for everything (Invariant 2). The break-even analysis shows ensemble creation costs ~5000 Claude tokens, with break-even at ~11 uses.

Research identified subtask patterns that recur across virtually all software projects: code pattern extraction, test case generation, lint fixing, changelog writing, and commit message writing. These patterns appear regardless of language, framework, or project structure. Creating ensembles for them proactively is infrastructure investment, not speculative overhead.

Invariant 12 establishes the conductor as workflow architect with a local-first objective. Without ensembles to delegate to, the workflow architect has nothing to work with.

## Decision

The conductor maintains a catalog of five **universal ensembles** that form its **starter kit**:

| Ensemble | Task Type | Pattern |
|----------|-----------|---------|
| `extract-code-patterns` | extraction | Read code files, extract structural patterns (signatures, decorators, imports) into structured summaries |
| `generate-test-cases` | template fill | Given a test pattern + method signature + expected behavior, generate a test case |
| `fix-lint-violations` | mechanical transform | Given file, line, rule, and violation, produce the minimal fix |
| `write-changelog` | summarization | Given a diff, produce a CHANGELOG entry in the project's format |
| `write-commit-message` | summarization | Given a staged diff, produce a commit message following project conventions |

During the conductor's first session in a project, it offers to **bootstrap** the starter kit:

```
No local ensembles found. I can create a starter kit of 5 universal ensembles
for common subtasks (extraction, test generation, lint fixes, changelogs,
commit messages). This costs ~25K Claude tokens upfront but saves tokens
from the second session onward. Create starter kit?
```

The user decides (Invariant 1). Starter kit ensembles enter calibration like any new ensemble (Invariant 4). Once calibrated with good evaluations, they are candidates for promotion to global tier (Invariant 6).

> **Superseded by ADR-015:** Ensemble creation is now the Ensemble Designer's responsibility. The conductor proposes the starter kit; the designer composes the ensembles.

Starter kit ensemble designs follow ADR-005 (swarm as default pattern), sized appropriately — most are single-agent since they handle single-concern subtasks.

## Consequences

**Positive:**
- Eliminates cold-start problem — the conductor has ensembles to delegate to from the first session
- Universal patterns amortize across every future session and project
- Promotion to global tier multiplies the return on investment
- Starter kit serves as calibration examples for the evaluation loop

**Negative:**
- ~25K Claude tokens upfront investment before any savings are realized
- Some users may not benefit from all 5 ensembles (e.g., no test suite, no changelog)
- Starter kit designs are generic — they may need project-specific tuning
- User must have appropriate Ollama models installed

**Neutral:**
- Individual starter kit ensembles can be declined — the user can choose a subset
- Starter kit designs will evolve as the conductor's pattern library grows
