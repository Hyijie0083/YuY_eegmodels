# ADR-020: Graph-Structured Memory as Target Architecture

**Status:** Proposed

## Context

Both the conductor and ensemble designer store operational data in flat files: routing-log.jsonl, evaluations.jsonl, routing-config.yaml, task-profiles.yaml (ADR-004), and the design pattern library (ADR-019). This works for append-only logging and simple lookups but fails at the queries that matter: "What led to this poor result?" "What has worked for similar tasks?" "Which ensembles are ready for promotion?" These are graph traversal problems.

AIMKG (HPE, 2024) achieved 78% relevant pipeline retrieval vs. 51% for flat alternatives. A-MEM (2025) showed ~2x improvement in multi-hop reasoning. Zep/Graphiti (2025) demonstrated +38.4% improvement on temporal reasoning. The evidence consistently favors graph-structured memory over flat storage for relational queries.

Plexus (https://github.com/nrgforge/plexus) is an existing knowledge graph project with provenance tracking that could serve as the memory layer.

## Decision

Adopt graph-structured memory as the **target architecture** for operational and design data. This is a directional decision, not an implementation commitment.

**What this means:**
- The memory layer is a named architectural layer (alongside orchestration, design, and verification)
- Both the conductor and designer read from and write to the memory layer
- Data relationships (provenance, design knowledge, evaluation chains) are first-class
- The flat file persistence (ADR-004) remains the current implementation until the graph backend is integrated

**What the memory layer stores:**
- **Provenance**: ensemble specs (Entities), calibration runs (Activities), routing decisions (Activities that use specific configurations). Maps to W3C PROV.
- **Design knowledge**: DAG shapes, profile pairings, verification technique effectiveness, anti-patterns (from ADR-019's design pattern library)
- **Operational data**: routing logs, evaluation records, task profiles, token usage

**What this does NOT decide:**
- The specific graph backend (Plexus, Neo4j, or other). This depends on Plexus's API surface and integration feasibility — unresolved.
- The migration path from flat files to graph storage. This is implementation work that depends on the backend choice.
- Whether the graph is embedded (in-process) or accessed via MCP. This is an integration architecture question.

**Uncertainty flag:** The integration with Plexus is not yet validated. A spike is needed to determine: (1) whether Plexus's API supports the query patterns described above, (2) what the performance characteristics are for the expected data volumes, (3) whether an MCP server for Plexus is the right integration point.

## Consequences

**Positive:**
- Enables provenance queries: "what led to this outcome" as a single traversal
- Enables cross-project meta-learning: the designer can query patterns across all projects
- Enables temporal reasoning: "what changed between when this ensemble worked and when it stopped working"
- Design knowledge accumulation (Inv 16) gets a native storage substrate

**Negative:**
- Additional infrastructure dependency (graph database)
- Migration from flat files requires careful data transformation
- Uncertainty: Plexus integration specifics are unresolved (flagged above)

**Neutral:**
- ADR-004 (flat file persistence) is not superseded — it remains the current implementation. This ADR describes the target, not the migration.
- The conductor and designer interact with the memory layer through an abstraction — the storage backend can change without affecting skill logic
