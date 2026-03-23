# ADR-019: Design Pattern Library

**Status:** Proposed

## Context

The essay frames each purpose-built ensemble as an experiment generating design knowledge. The calibration loop (ADR-003, ADR-011) already captures quality data per ensemble. But this knowledge is currently implicit — stored in evaluation logs and ensemble YAML files, not organized for retrieval.

The ensemble designer (ADR-015) needs to answer: "For tasks with characteristics similar to this one, which DAG shapes, profile combinations, and script patterns produced the best calibration results?" AIMKG (HPE, 2024) demonstrated that a metadata knowledge graph answers such questions 53% more accurately than flat schema approaches. Design knowledge is inherently relational.

Invariant 16 establishes: "Every ensemble is an experiment. The ensemble designer treats each ensemble as an experiment generating design knowledge."

## Decision

The ensemble designer maintains a **design pattern library** — a structured collection of reusable design knowledge accumulated from ensemble experiments.

**What the library contains:**
- **DAG shape patterns**: which topologies (single-agent, fan-out swarm, complementary pair, multi-stage gather-analyze-synthesize) suit which task type characteristics
- **Profile pairing data**: which model pairs are complementary on which task types, with union accuracy and contradiction penalty measurements
- **Script pattern templates**: reusable script agent patterns (file discovery, JSON transform, embedding-based verification, NLI consistency check)
- **Verification technique effectiveness**: which verification techniques (entropy, embedding, NLI) work best for which output types
- **Anti-patterns**: designs that consistently produce poor calibration results, with failure mode analysis

**How the library is populated:**
- After each ensemble's calibration period completes, the designer records: DAG shape, profiles used, verification techniques, calibration scores, failure modes
- On promotion (ADR-006), the designer records that the design was good enough to generalize
- On poor calibration (3+ poor scores), the designer records the anti-pattern

**How the library is consulted:**
- When the designer receives a request for a new ensemble, it queries the library for similar task types. Similarity is determined by: (1) delegability category (agent-delegable, ensemble-delegable), (2) template architecture category (from ADR-013's five templates or custom), and (3) output type (structured extraction, analysis report, code generation, etc.)
- If a matching pattern exists, the designer proposes it (with customization for the specific task)
- If no match exists, the designer composes from first principles and records the result
- As the library grows, the similarity model may be refined based on empirical data about which dimensions best predict design success

**Storage format:** Initially a YAML file (`design-patterns.yaml`) in the designer skill's directory. This may migrate to the memory layer (graph-structured storage) when available, but the library's value does not depend on the storage backend.

## Consequences

**Positive:**
- Ensemble design improves over time — the system learns what works
- New ensemble composition starts from accumulated evidence, not from scratch
- Anti-patterns are recorded and avoided
- Cross-project knowledge: patterns promoted to global tier carry their design context

**Negative:**
- Additional persistence to maintain (design-patterns.yaml)
- Library curation is a new responsibility for the designer
- Risk of pattern ossification — the designer should not blindly reuse patterns when task characteristics differ

**Neutral:**
- Does not change the conductor's orchestration — the library is internal to the designer
- Does not change the evaluation protocol — calibration data feeds the library, but evaluation itself is unchanged
