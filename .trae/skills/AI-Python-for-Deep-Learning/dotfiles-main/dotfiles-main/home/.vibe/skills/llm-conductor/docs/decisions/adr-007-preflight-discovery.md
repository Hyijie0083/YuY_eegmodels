# ADR-007: Pre-Flight Discovery Before First Routing Decision

**Status:** Accepted

## Context

The conductor's routing depends on what's available: which ensembles exist, which Ollama models are pulled, which profiles are configured. Without a discovery step, the conductor would attempt to route to ensembles that can't run or suggest models that aren't installed.

The essay's open question 3 asked whether the skill should pre-check Ollama model availability and suggest downloads.

## Decision

On first invocation in a session (or when explicitly requested), the conductor runs a pre-flight discovery:

1. **`set_project`** — point llm-orc at the current project directory
2. **`list_ensembles`** — discover available ensembles across all tiers
3. **`get_provider_status`** — discover available Ollama models and their sizes
4. **`list_profiles`** — discover configured model profiles
5. **Check ensemble runnability** — for each relevant ensemble, verify models are available
6. **Read evaluation history** — load routing log and task profiles from `.llm-orc/evaluations/`

If the discovery reveals:
- **Missing models** that existing ensembles need → suggest `ollama pull` commands
- **No ensembles** matching common task types → note the gap for future composition
- **Profile-model mismatches** → warn the user

Discovery results are cached for the session and refreshed only on explicit request or after ensemble creation.

## Consequences

**Positive:**
- Prevents routing failures from missing models or broken ensembles
- Suggests actionable fixes (model downloads) rather than opaque errors
- Builds the conductor's situational awareness before any routing decision

**Negative:**
- Adds latency to the first invocation (multiple MCP calls)
- Discovery results can become stale within a long session

**Neutral:**
- Discovery is lightweight — these are read-only MCP calls, not invocations
