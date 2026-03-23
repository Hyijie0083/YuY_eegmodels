# ADR-006: Three-Tier Promotion via File Copy and Git

**Status:** Accepted

## Context

Ensembles are born in the local tier (`.llm-orc/`). Invariant 6 requires evidence-based quality gates for promotion. Invariant 11 requires profile dependencies to travel with the ensemble. Invariant 1 requires user consent at every step.

llm-orc's MCP surface has no promotion or contribution tools — library access is read-only. The conductor must implement promotion through file operations and git.

## Decision

**Local → Global** promotion:
1. Ensemble has 3+ "good" evaluations
2. Conductor assesses generality (no hardcoded paths, no project-specific prompts, uses standard profiles)
3. Conductor presents recommendation to user with evidence (evaluation history, generality assessment)
4. On user consent: copy ensemble YAML to `~/.config/llm-orc/ensembles/`, copy any missing profiles to `~/.config/llm-orc/profiles/`
5. Verify the ensemble is runnable at the destination via `check_ensemble_runnable`

> **Superseded by ADR-015:** Promotion execution (file copying, verification) is now the Ensemble Designer's responsibility. The conductor recommends promotion based on evaluation evidence.

**Global → Library** contribution:
1. Ensemble has 5+ "good" evaluations and passes generality assessment
2. Conductor presents recommendation with evidence
3. On user consent:
   - Clone `llm-orchestra-library` repo if not present
   - Create branch `contribute/{ensemble-name}`
   - Copy ensemble YAML and required profiles
   - Commit and push
   - Optionally create a PR via `gh pr create`

The user decides at every gate. The conductor never promotes silently.

## Consequences

**Positive:**
- Quality gates prevent premature promotion (Invariant 6)
- Profile dependency check prevents broken ensembles at destination (Invariant 11)
- Git workflow for library contribution uses standard tooling
- User has full control (Invariant 1)

**Negative:**
- No MCP tool for promotion — file copy is outside llm-orc's managed surface
- Library contribution requires the user to have git push access to the repo
- Generality assessment is heuristic, not formal — Claude's judgment may miss project-specific assumptions

**Neutral:**
- A `promote_ensemble` MCP tool in llm-orc would simplify local → global; flagged as a desirable future feature
