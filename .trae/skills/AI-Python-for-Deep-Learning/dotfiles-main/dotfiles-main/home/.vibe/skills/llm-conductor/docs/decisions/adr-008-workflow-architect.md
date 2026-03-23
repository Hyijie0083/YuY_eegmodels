# ADR-008: Conductor as Workflow Architect for Meta-Tasks

**Status:** Accepted

## Context

The conductor (ADR-001 through ADR-007) routes individual tasks to local ensembles or Claude. But most real work is a meta-task — a complex, multi-phase goal like "build a PromotionHandler" or "run an RDD research cycle." When the conductor classifies a meta-task as "reasoning" and falls back to Claude for the entire job, it misses that 52% of the subtasks within that meta-task are delegable (extraction, template fill, mechanical transform, boilerplate generation).

Research (R2-Reasoner, arXiv 2506.05901) shows 84% cost reduction by decomposing complex queries into subtask sequences and routing each to the smallest capable model. The worked example from the PromotionHandler session confirmed this: 17 of 33 subtasks were strongly delegable, clustering into coherent blocks (research phase extractions, implementation phase template fills, testing phase boilerplate).

Invariant 10 (competence boundaries) is correct for individual subtask routing but was being applied at the wrong altitude — to meta-tasks rather than subtasks. Invariant 12 establishes the conductor as workflow architect. Invariant 13 requires workflow plans before execution.

## Decision

When the conductor is invoked with a meta-task, it operates as a **workflow architect** rather than a task router:

1. **Decompose** the meta-task into an ordered sequence of subtasks, classifying each by task type
2. **Plan** a workflow with delegation assignments — each subtask mapped to an existing ensemble, a new ensemble to be created, or Claude-direct
3. **Present** the workflow plan to the user with estimated token savings and ensemble creation needs
4. **Execute** the plan, handling Claude-only subtasks directly and invoking ensembles for delegable subtasks
5. **Adapt** the plan during execution if ensemble output is poor (fall back to Claude) or new patterns emerge

The conductor's objective when planning is to **maximize local model leverage** — route as much work as possible to ensembles, reserving Claude for subtasks that genuinely require frontier reasoning. Claude becomes the surgical tool, not the default handler.

Competence boundaries (Invariant 10) apply at the subtask level within the workflow plan. The meta-task's overall complexity does not prevent decomposition.

For simple tasks that don't warrant decomposition (fewer than ~5 subtasks or fewer than 3 delegable ones), the conductor routes directly using the existing task triage mechanism (ADR-002).

## Consequences

**Positive:**
- Captures the 52% of subtasks that are delegable within "reasoning" meta-tasks
- Front-loads decomposition intelligence into a plan the user can review
- Maximizes local model leverage across entire workflows
- Competence boundaries still protect individual subtask quality

**Negative:**
- Workflow planning costs Claude tokens — decomposing the meta-task, classifying subtasks, designing the delegation map. For small tasks, this overhead may exceed savings
- Plan quality depends on the conductor's ability to predict subtask patterns from the meta-task description
- Interleaved execution (Claude ↔ ensembles alternating) adds coordination complexity
- The conductor must hold the big picture while delegating parts — lost novelty risk for delegated subtasks
- **Assumption:** The conductor can reliably decompose a meta-task into subtasks from its natural language description. This is the same prediction risk flagged in ADR-002 for task classification, now applied at the decomposition level. Misdecomposition wastes tokens on ensembles that don't match the actual work

**Neutral:**
- Existing ADR-002 routing still applies for simple tasks and for individual subtask routing within a workflow plan
- The workflow plan is a new artifact type persisted alongside routing decisions
