# ADR-015: Conductor/Designer Skill Separation

**Status:** Proposed

## Context

The essay "Purpose-Built Ensembles and the Design Laboratory" identifies two distinct concerns within the current conductor skill: **orchestration** (decomposing tasks, routing, invoking, evaluating, adapting) and **ensemble design** (selecting DAG architectures, choosing profiles, authoring scripts, interpreting calibration data, managing promotion). These have different knowledge requirements, cadences, and optimal model selections.

The RDD skill decomposition provides the structural template. RDD separates research, modeling, decision, and building into separate skills — not because they are sequential, but because each requires a different cognitive mode. Each skill owns one concern, coordinates via artifacts, and can trigger backward jumps when later phases reveal flaws.

The conductor's two concerns map similarly. Orchestration is operational and evaluative — it benefits from speed (Sonnet-class reasoning). Ensemble design is creative and architectural — it benefits from depth (Opus-class reasoning). The MCP tool distribution supports this: the conductor uses 7 tools (set_project, invoke, analyze_execution, list_ensembles, get_provider_status, list_profiles, check_ensemble_runnable), while the designer uses 15 (create_ensemble, validate_ensemble, create_profile, update_ensemble, promote_ensemble, check_promotion_readiness, list_dependencies, demote_ensemble, library_browse, library_copy, create_script, list_scripts, get_script, test_script, delete_script).

The DeepMind finding that orchestrator capability dominates system performance underscores the importance of optimizing the conductor for its core routing function, which the separation enables — the conductor can be tuned for speed while the designer is tuned for depth.

## Decision

Split the conductor into two skills with artifact-based coordination:

**Conductor skill** owns the orchestration layer:
- Decompose meta-tasks into subtasks
- Triage (classify task type, apply DAG decomposability test)
- Route subtasks to ensembles or Claude-direct
- Invoke ensembles, evaluate output, track tokens
- Adapt workflow plans during execution
- Discover available ensembles and models (pre-flight)
- Request new or improved ensembles from the designer

**Ensemble Designer skill** owns the design layer:
- Select DAG architectures from the design pattern library
- Choose profiles (including complementarity measurement)
- Author script agents and verification scripts
- Compose and validate ensembles
- Interpret calibration data to improve designs
- Manage promotion (local → global → library)
- Flag LoRA candidates
- Maintain the design pattern library

**Coordination protocol:**
- Conductor → Designer: routing needs ("I need an ensemble for task type X") and evaluation data ("ensemble Y scored poor on 3/5 calibration runs; failure mode: incomplete")
- Designer → Conductor: validated ensembles (ready for invocation and calibration) and design knowledge ("confidence-based selection works better than synthesis for extraction on this model pair")
- The user gates transitions between conductor and designer, just as in RDD

**Model selection:**
- Conductor runs on Sonnet (speed for operational decisions)
- Designer runs on Opus (depth for architectural judgment and script authoring)

## Consequences

**Positive:**
- Each skill can be optimized for its cognitive mode (speed vs. depth)
- Ensemble design becomes a first-class research activity, not subordinate overhead
- The "laboratory" framing is enabled — the designer systematically accumulates what works
- Token cost reduced: Sonnet handles the high-volume orchestration work

**Negative:**
- Two skills to maintain instead of one
- Artifact-based handoff adds coordination overhead
- Cold-start is more complex (both skills must be invoked for first-use setup)
- Prior ADRs (001, 005, 006, 009, 010, 013) need supersession notes for conductor-as-composer language. ADR-013's assignment of script authoring to the conductor is superseded — script authoring (step 3 of the extended composition protocol) moves to the Ensemble Designer, whose Opus-class reasoning is better suited to this judgment task. The conductor retains the ability to request new scripts via evaluation feedback artifacts

**Neutral:**
- The conductor's SKILL.md shrinks (orchestration only); a new SKILL.md is created for the designer
- Existing ensembles are unaffected — the split is in skill logic, not in ensemble structure
