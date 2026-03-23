# ADR-006: Report Output Format

**Status:** Accepted

## Context

The Synthesis phase produces the Architectural Analysis Report — the primary deliverable. The report needs a location and format. Options include: a single markdown file, multiple files organized by section, or an interactive HTML document.

The skill is invoked within Claude Code, where the user interacts via terminal. The report must be readable in this context and also useful as a reference document that persists after the session. The Walkthrough phase references the report interactively.

## Decision

Write the Architectural Analysis Report as a single markdown file at `./docs/codebase-audit.md` in the target Codebase's directory. If a `docs/` directory doesn't exist, create it.

The report follows this structure:

```
# Codebase Audit: [Codebase Name]
## Date / Scope / Sample Coverage
## Executive Summary (Codebase Map + key takeaways)
## Architectural Profile
### Patterns Identified
### Quality Attribute Fitness
### Inferred Decisions
## Tradeoff Map
## Findings by Level
### Macro Findings
### Meso Findings
### Micro Findings
## Stewardship Guide
### What to Protect
### What to Improve (Prioritized)
### Ongoing Practices
```

Each Finding within the report uses the five-part pedagogical format: Observation, Pattern, Tradeoff, Socratic Question, Stewardship Recommendation.

## Consequences

**Positive:**
- Single file is easy to share, version, and reference
- Markdown renders well in terminals, editors, and GitHub
- Writing to the target Codebase's `docs/` directory keeps the analysis with the code it describes
- Structure supports both linear reading and section-jumping

**Negative:**
- A single file may be long for large Codebases with many Findings — but the executive summary and Stewardship Guide provide entry points
- Writing to the target Codebase means the user must decide whether to commit it — the skill should not commit it

**Neutral:**
- The Walkthrough phase references this file during the interactive session
