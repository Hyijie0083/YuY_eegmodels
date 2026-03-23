# ADR-001: Conductor is a Claude Code Skill with its own .llm-orc Directory

**Status:** Accepted

## Context

The conductor needs Claude's broad reasoning for routing decisions — classifying task types, assessing competence boundaries, evaluating output quality. These are beyond local model competence boundaries (Invariant 10). However, the conductor also has subtasks that local models could handle: task type classification against a known taxonomy, generality assessment against a checklist, structured log formatting.

Two architectures were considered: (a) the conductor as a pure SKILL.md with all logic in Claude's prompt, or (b) the conductor as a SKILL.md that also maintains its own `.llm-orc/` directory with ensembles for its own subtasks.

## Decision

The conductor is a Claude Code skill (`SKILL.md`) that maintains a `.llm-orc/` directory within the skill folder (`~/.claude/skills/llm-conductor/.llm-orc/`). Claude handles high-level routing, evaluation, and promotion decisions. Local ensembles within the skill's own `.llm-orc/` handle subtasks that fall within local model competence boundaries.

> **Superseded by ADR-015:** Promotion execution is now the Ensemble Designer's responsibility. The conductor recommends promotion; the designer executes it.

The conductor uses `set_project` to point llm-orc at the skill's own directory when invoking its internal ensembles, and at the user's project directory when invoking task-specific ensembles.

**Context switching protocol:** The user's project directory is the default context. Before invoking an internal ensemble, the conductor switches to the skill directory. After the internal invocation completes, the conductor immediately switches back to the user's project directory. The conductor never leaves the context pointing at the skill directory between user-visible operations.

## Consequences

**Positive:**
- Dogfoods the conductor's own philosophy: composition over scale, local models for what they're good at
- Reduces Claude token usage for the conductor's own operations
- Internal ensembles serve as calibration examples for the evaluation loop

**Negative:**
- Two `set_project` contexts to manage (skill directory vs. user project directory)
- Internal ensembles need their own calibration and evaluation
- Adds complexity to the skill's directory structure

**Neutral:**
- The skill's `.llm-orc/` directory follows the same conventions as any project's
