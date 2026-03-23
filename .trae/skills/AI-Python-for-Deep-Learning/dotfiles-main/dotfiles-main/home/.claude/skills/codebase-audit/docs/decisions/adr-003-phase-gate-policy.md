# ADR-003: Phase Gate Policy

**Status:** Accepted

## Context

The Analysis has six Phases. The domain model states "Orchestrator presents results to User at phase gates" but doesn't specify which gates require explicit confirmation before proceeding. Too many gates slow the Analysis and create friction. Too few gates risk the skill spending effort on analysis the user didn't want.

The critical decision point is after Reconnaissance, where the user Scopes the Analysis. Other phases produce intermediate artifacts that inform subsequent phases — requiring approval at every gate would fragment the flow.

## Decision

Two mandatory gates. Four informational presentations.

| Phase | Gate Type | What Happens |
|-------|-----------|-------------|
| **Reconnaissance** | **Mandatory gate** | Present the Codebase Map. User confirms scope (whole Codebase, specific Components, specific concerns). Analysis does not proceed until the user Scopes. |
| Macro Analysis | Informational | Present the Architectural Profile summary. Proceed unless the user intervenes. |
| Meso Analysis | Informational | Present meso Findings summary. Proceed unless the user intervenes. |
| Micro Analysis | Informational | Present micro Findings summary. Proceed unless the user intervenes. |
| **Synthesis** | **Mandatory gate** | Present the complete Architectural Analysis Report. User reviews and may request changes before the Walkthrough. |
| Walkthrough | Interactive (no gate needed) | This phase is inherently interactive — the user drives it. |

## Consequences

**Positive:**
- Only two mandatory gates — the skill flows efficiently for users who trust the process
- The Reconnaissance gate catches scope problems early (most impactful decision point)
- The Synthesis gate lets the user review the full report before the interactive session
- Informational presentations keep the user aware without blocking progress

**Negative:**
- A user who wants fine-grained control must intervene at informational gates manually
- If macro analysis goes in an unexpected direction, the user doesn't get a mandatory checkpoint until Synthesis

**Neutral:**
- The user can always interrupt — informational gates are "present and proceed unless stopped," not "silently skip"
