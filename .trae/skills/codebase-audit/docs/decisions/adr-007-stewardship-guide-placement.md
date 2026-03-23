# ADR-007: Stewardship Guide Placement

**Status:** Accepted

## Context

The domain model flagged ambiguity about whether the Stewardship Guide is a section of the Architectural Analysis Report or a standalone document. The Stewardship Guide lists what to protect, what to improve, and ongoing practices — it's the actionable output the user refers to after the Analysis session ends.

## Decision

The Stewardship Guide is an **embedded section** of the Architectural Analysis Report, not a standalone document. It appears as the final major section of the report, after all Findings.

Rationale: the Guide draws directly from the Findings and Tradeoff Map. Separating it would force the reader to cross-reference two documents. Embedding it means a single document tells the complete story — from orientation through analysis to action.

## Consequences

**Positive:**
- Single document for the complete analysis-to-action narrative
- No cross-referencing between files
- The Guide can back-reference specific Findings by section anchor

**Negative:**
- The report file is longer — but the Guide is typically the section users bookmark and return to

**Neutral:**
- During the Walkthrough phase, the Orchestrator may focus on the Guide section specifically
