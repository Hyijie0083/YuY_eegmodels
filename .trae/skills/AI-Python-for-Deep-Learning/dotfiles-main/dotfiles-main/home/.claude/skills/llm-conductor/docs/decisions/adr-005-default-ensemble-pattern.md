# ADR-005: Swarm as Default Ensemble Pattern for New Compositions

**Status:** Accepted — extended by ADR-009 (universal ensemble starter kit uses these sizing guidelines; most starter kit ensembles are single-agent since they handle single-concern subtasks). Extended by ADR-013 (multi-stage ensemble composition adds script agents, fan-out, and template architectures for ensemble-delegable tasks; this ADR's swarm pattern remains the default for agent-delegable tasks)

## Context

When the conductor composes a new ensemble for a task type, it must choose an ensemble pattern. Research identified five patterns: simple sequential, fan-in synthesis, fan-out, swarm, and composable. Invariant 3 requires composition over scale — preferring many small models over fewer large ones.

The swarm pattern (many micro/small extractors → fewer medium analyzers → one larger synthesizer) is the most granular decomposition pattern, keeping every agent within its competence boundary. On structured analytical tasks with decomposable concerns, swarms can approach larger-model quality through composition.

## Decision

When the conductor composes a new ensemble, the default pattern is a swarm:

> **Superseded by ADR-015:** Ensemble composition is now the Ensemble Designer's responsibility.

1. **Extractors** (micro tier, ≤1B) — one per distinct extraction concern, operating on the same input in parallel
2. **Analyzers** (small/medium tier, 4-7B) — one per analytical dimension, receiving extractor outputs
3. **Synthesizer** (medium tier, 7B; ceiling tier 12B only if justified) — one agent combining analyzer outputs into final result

The conductor sizes the swarm based on the task's structure:
- Simple tasks (single extraction): skip to a single agent, no swarm needed
- Moderate tasks (2-3 concerns): 2-3 extractors → 1 synthesizer
- Complex tasks (4+ concerns): full swarm with extractors → analyzers → synthesizer

The 12B ceiling tier is used only for the synthesizer role, and only when the task requires synthesis across 4+ analyzer outputs. This preserves Invariant 3.

> **Superseded by ADR-018:** The ceiling tier is now 14B (qwen3:14b), not 12B. The ceiling rule (reserved for 4+ upstream outputs) is unchanged.

## Consequences

**Positive:**
- Each agent operates within its competence boundary
- Parallelism across extractors reduces latency compared to sequential processing
- The pattern naturally decomposes complex tasks into narrow subtasks
- Smaller models per agent means lower memory pressure on the host machine

**Negative:**
- More agents means more total tokens (even if each is small)
- Swarm design requires Claude to decompose the task into extraction concerns — itself a token cost. The first invocation of a novel task type may cost more tokens than Claude handling it directly; savings accrue on subsequent reuse
- Latency is bounded by the slowest agent in each tier, plus synthesis time

**Neutral:**
- The swarm pattern maps directly to llm-orc's `depends_on` mechanism for expressing agent dependencies
