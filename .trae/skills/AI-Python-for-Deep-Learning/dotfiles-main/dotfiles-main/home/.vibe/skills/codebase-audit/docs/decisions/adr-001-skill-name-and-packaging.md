# ADR-001: Skill Name and Packaging

**Status:** Accepted

## Context

The skill needs a name for invocation (e.g., `/name`) and a packaging strategy. Existing skills follow a pattern: single SKILL.md file in `~/.claude/skills/<name>/SKILL.md` with YAML frontmatter. Complex orchestration skills like `peer-review` embed all phase instructions and subagent prompts in a single file and use the Task tool to launch subagents at runtime.

The skill's purpose is comprehensive, multi-lens Codebase analysis with a pedagogical and stewardship framing. The name should communicate "architectural understanding" rather than "code review" or "linting" — those are existing concepts with different connotations.

## Decision

Name the skill **`codebase-audit`**. Package as a single `~/.claude/skills/codebase-audit/SKILL.md` file. The Orchestrator logic, all Phase instructions, and all ten Lens Analyst prompts are embedded in this one file. Lens Analysts are launched at runtime via the Task tool with prompts sourced from the SKILL.md sections.

Allowed tools: `Read, Grep, Glob, WebSearch, WebFetch, Write, Edit, Task, Bash`.

## Consequences

**Positive:**
- "Audit" communicates systematic evaluation without implying fault-finding or code generation
- Single file keeps all skill logic co-located and versionable
- Matches the established packaging pattern (peer-review, rdd-research, etc.)
- `/codebase-audit` is concise to invoke

**Negative:**
- The SKILL.md file will be large — ten Lens Analyst prompt sections plus orchestration logic
- "Audit" may carry a slight connotation of judgment, though less than "review" or "critique"

**Neutral:**
- The name doesn't communicate the pedagogical/stewardship dimension — that's conveyed by the skill's behavior, not its name
