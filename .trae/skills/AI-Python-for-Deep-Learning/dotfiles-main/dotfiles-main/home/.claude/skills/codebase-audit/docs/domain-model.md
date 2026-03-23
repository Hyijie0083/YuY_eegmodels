# Domain Model: Codebase Architectural Analysis Skill

## Concepts (Nouns)

### Core Structural Concepts

| Term | Definition | Related Terms |
|------|-----------|---------------|
| **Analysis** | A complete run of the skill against a target codebase, proceeding through all phases and producing an Architectural Analysis Report. | Phase, Lens, Finding |
| **Phase** | A distinct stage of an Analysis. Phases execute sequentially; each phase's output informs the next. Six phases: Reconnaissance, Macro Analysis, Meso Analysis, Micro Analysis, Synthesis, Walkthrough. | Analysis, Lens |
| **Lens** | A distinct analytical perspective applied to a codebase. Each lens surfaces something the others miss. Ten lenses organized across three levels. | Level, Lens Analyst, Finding |
| **Level** | A tier of analytical zoom. Three levels: Macro (system-wide), Meso (module/component), Micro (code-level). Levels determine phase grouping and execution order. | Lens, Phase |
| **Finding** | The atomic unit of analysis output. A single observation about the codebase, structured in the five-part pedagogical format. Every finding points to at least one Code Location. | Observation, Pattern, Tradeoff, Socratic Question, Stewardship Recommendation, Code Location |
| **Code Location** | A specific, verifiable position in the codebase (file path and line range) that evidences a Finding. | Finding |
| **Codebase** | The target of an Analysis. A directory tree of source code, configuration, tests, and documentation. | Codebase Map, Component |
| **Component** | A cohesive unit within the Codebase — a module, package, service, or bounded group of files that serves a distinct purpose. Identified during Reconnaissance. | Codebase, Codebase Map |

### Orchestration Concepts

| Term | Definition | Related Terms |
|------|-----------|---------------|
| **Orchestrator** | The main skill process that manages phases, launches Lens Analysts, compiles findings, interacts with the user, and produces the final report. | Phase, Lens Analyst, Architectural Analysis Report |
| **Lens Analyst** | A subagent specialized in one Lens. Operates with independent context. Launched in parallel with other Lens Analysts within the same phase. Produces raw findings for the Orchestrator to compile. | Lens, Orchestrator, Finding |

### The Ten Lenses

| Term | Definition | Level |
|------|-----------|-------|
| **Pattern Recognition** | Identifies architectural patterns the codebase actually implements, including approximate or incomplete pattern implementations, and the gap between documented and actual architecture. | Macro |
| **Architectural Fitness** | Evaluates how well the architecture serves its Quality Attributes and identifies where attributes are in tension. Does not execute fitness tests — infers fitness from structure. | Macro |
| **Decision Archaeology** | Infers architectural decisions that shaped the codebase — decisions that may have been intentional, accidental, or emergent. Produces Inferred ADRs. | Macro |
| **Dependency & Coupling** | Maps how Components connect and whether those connections are appropriate. Identifies circular dependencies, coupling violations, missing abstractions, and dependency direction violations. | Meso |
| **Intent-Implementation Alignment** | Assesses whether code does what it appears to be trying to do — whether naming matches behavior, abstractions abstract the right thing, and interfaces deliver what they promise. | Meso |
| **Invariant Analysis** | Surfaces the rules a system enforces (often implicitly) and checks whether enforcement is consistent, whether invariants conflict with each other, and whether they serve the system's goals. | Meso |
| **Documentation Integrity** | Assesses whether documentation (README, comments, API docs, type annotations) accurately describes the system that actually exists. Detects documentation drift, comment rot, phantom docs, and aspirational docs. | Meso |
| **Structural Health** | Evaluates code smells (local, within a function/class) and architectural anti-patterns (systemic, across modules). | Micro |
| **Dead Code** | Identifies evolutionary debris: unreachable code, unused exports, vestigial abstractions, and feature ghosts. | Micro |
| **Test Quality** | Evaluates whether tests verify what matters — assertion quality, test smells, test-code correspondence, and test architecture. | Micro |

### Output Concepts

| Term | Definition | Related Terms |
|------|-----------|---------------|
| **Codebase Map** | The orientation document produced in the Reconnaissance phase. Describes directory structure, languages, frameworks, build system, test setup, and apparent purpose. The shared map before deeper analysis. | Reconnaissance, Component |
| **Architectural Profile** | The compiled output of Macro Analysis. Describes the system's actual architectural patterns, quality attribute fitness, and inferred decisions. Informs subsequent phases. | Macro Analysis, Pattern Recognition, Architectural Fitness, Decision Archaeology |
| **Inferred ADR** | An Architecture Decision Record produced by the Decision Archaeology lens. Documents a decision the skill detected in the code, framed as a hypothesis ("this appears to be...") rather than a certainty. | Decision Archaeology |
| **Architectural Analysis Report** | The primary deliverable. A narrative document integrating all lens findings, mapping tradeoffs, presenting findings in pedagogical format, and prioritizing recommendations. Produced in the Synthesis phase. | Finding, Synthesis, Tradeoff Map |
| **Stewardship Guide** | A section of the Architectural Analysis Report (or standalone document) listing what to watch for, what to protect, and what to improve — ongoing practices, not one-time fixes. | Stewardship Recommendation, Walkthrough |
| **Tradeoff Map** | The explicit mapping of which Quality Attributes the architecture optimizes for and which it sacrifices. Part of the Architectural Analysis Report. | Quality Attribute, Tradeoff, Architectural Fitness |

### Finding Components (The Pedagogical Format)

| Term | Definition | Related Terms |
|------|-----------|---------------|
| **Observation** | The first part of a Finding. What the skill found — concrete, specific, pointing to Code Locations. States fact, not judgment. | Finding, Code Location |
| **Pattern** | The second part of a Finding. The named architectural concept the Observation relates to (e.g., "God Object," "Shotgun Surgery," "documentation drift"). Includes a brief explanation. Not to be confused with architectural patterns detected by the Pattern Recognition lens. | Finding |
| **Tradeoff** | The third part of a Finding. What the observed pattern optimizes for and what it costs. Connects two or more Quality Attributes in tension. | Finding, Quality Attribute |
| **Socratic Question** | The fourth part of a Finding. A question that guides the user toward understanding why the Observation matters. Uses "what" framing, not "why." | Finding |
| **Stewardship Recommendation** | The fifth part of a Finding. What a good steward of this code would do — ranging from "nothing, this is a conscious tradeoff" to "prioritize for refactoring." Uses stewardship language, not judgment language. | Finding, Stewardship Guide |

### Codebase Health Concepts

| Term | Definition | Related Terms |
|------|-----------|---------------|
| **Quality Attribute** | A measurable property of a system's architecture: performance, modifiability, security, testability, operability, reliability, usability. Architectures trade these against each other. | Architectural Fitness, Tradeoff |
| **Code Smell** | A local code-level indicator of a deeper structural problem. Classified by Mäntylä's taxonomy: Bloaters, OO Abusers, Change Preventers, Dispensables, Encapsulators, Couplers. | Structural Health, Anti-Pattern |
| **Anti-Pattern** | A systemic, architecture-level structural problem: Big Ball of Mud, God Object, Spaghetti Code, Gas Factory, Inner Platform Effect, Stovepipe. Distinct from Code Smells in scope and remedy. | Structural Health, Code Smell |
| **Test Smell** | A bad design practice in test code that hurts maintainability: Assertion Roulette, Eager Test, Mystery Guest, Empty Test, Redundant Assertion, Magic Number Test. | Test Quality |
| **Invariant** | A condition the system enforces — often implicitly. Operates at class, module, or system level. Surfaced from guard clauses, validation, middleware, and error handling patterns. | Invariant Analysis |
| **Documentation Drift** | The state where documentation no longer matches the code it describes. Includes comment rot, phantom docs, aspirational docs, scope mismatch, and version drift. | Documentation Integrity |
| **Vestigial Structure** | An abstraction that has outlived its purpose: interfaces with one implementor, factories that build one type, strategies with one strategy. A specific category of Dead Code. | Dead Code |
| **Feature Ghost** | A partially-implemented feature: routes that lead nowhere, database columns written but never read, configuration for environments that don't exist. A specific category of Dead Code. | Dead Code |

### Pedagogical Concepts

| Term | Definition | Related Terms |
|------|-----------|---------------|
| **Stewardship** | The skill's framing for code maintenance. "Taking good care of that which we're entrusted with." Non-judgmental toward authors; focused on the user becoming a responsible caretaker of the code's health. | Stewardship Recommendation, Stewardship Guide |
| **Progressive Disclosure** | The principle of revealing complexity in layers. The skill presents macro findings before micro, orientation before analysis, and summaries before details. | Phase, Level |

### Avoided Synonyms

| Avoid | Use Instead | Rationale |
|-------|------------|-----------|
| Violation | Observation or Finding | "Violation" implies a rule was broken. Findings describe properties of code, not transgressions. |
| Issue / Problem / Bug | Finding | "Issue" implies something is wrong. Findings may be neutral or even positive. |
| Code Ownership | Stewardship | Ownership implies control and blame. Stewardship implies care and continuity. |
| Exhaustive / Complete | Representative / Strategic | The skill samples; it never claims completeness. |
| Wrong / Bad / Broken | "Optimizes for X at the expense of Y" | Tradeoff language, not judgment language. |

## Actions (Verbs)

| Action | Actor | Subject | Description |
|--------|-------|---------|-------------|
| **Reconnoiter** | Orchestrator | Codebase | Phase 1. Scan directory structure, config, README. Produce the Codebase Map. |
| **Scope** | User + Orchestrator | Analysis | User confirms whether to analyze the whole Codebase or specific Components. Happens after Reconnaissance. |
| **Launch** | Orchestrator | Lens Analysts | Start parallel subagents for a given Phase's lenses. Each gets independent context. |
| **Sample** | Lens Analyst | Codebase | Read selected files strategically — entry points, core modules, boundaries, configuration — rather than exhaustively. |
| **Surface** | Lens Analyst | Invariants, Patterns, Decisions | Detect implicit properties of the code that are not explicitly stated anywhere. |
| **Infer** | Lens Analyst | Intent, Decisions, Invariants | Form a hypothesis about the code's purpose, history, or rules from structural and naming evidence. |
| **Produce** | Lens Analyst | Findings | Generate Findings in the five-part pedagogical format, each anchored to Code Locations. |
| **Compile** | Orchestrator | Findings | Gather raw Findings from Lens Analysts, deduplicate, cross-reference, and organize by Level. |
| **Synthesize** | Orchestrator | Architectural Analysis Report | Phase 5. Integrate all compiled Findings into a unified narrative with Tradeoff Map and prioritized recommendations. |
| **Walk Through** | Orchestrator + User | Findings | Phase 6. Interactive session: explain findings, answer questions, help develop a Stewardship Guide. |
| **Inform** | Earlier Phase | Later Phase | Findings from macro phases shape what meso/micro phases investigate. Phase outputs flow downstream. |
| **Target** | Macro/Meso Findings | Micro Analysis | Micro lens analysts focus on areas flagged by earlier phases rather than analyzing everything equally. |

## Relationships

### Structural

- Analysis **proceeds through** six Phases (sequentially)
- Phase **contains** one or more Lenses
- Lens **belongs to** one Level (Macro, Meso, or Micro)
- Lens **is operated by** one Lens Analyst (subagent)
- Lens Analyst **produces** Findings
- Finding **references** one or more Code Locations
- Finding **contains** exactly one each: Observation, Pattern, Tradeoff, Socratic Question, Stewardship Recommendation

### Data Flow

- Reconnaissance **produces** Codebase Map
- Macro Analysis **produces** Architectural Profile
- Architectural Profile **informs** Meso Analysis
- Macro + Meso Findings **target** Micro Analysis
- Synthesis **consumes** all Findings and **produces** Architectural Analysis Report
- Architectural Analysis Report **contains** Tradeoff Map and Stewardship Guide

### Compositional

- Codebase **is composed of** Components
- Architectural Analysis Report **is composed of** Findings, Tradeoff Map, Stewardship Guide
- Tradeoff Map **connects** Quality Attributes in tension
- Tradeoff **relates** two or more Quality Attributes

### Operational

- Orchestrator **launches** Lens Analysts in parallel (within a Phase)
- Orchestrator **compiles** Lens Analyst outputs
- Orchestrator **presents** results to User at phase gates
- User **scopes** the Analysis after Reconnaissance
- User **walks through** findings with Orchestrator in the final Phase

## Invariants

### Analysis Integrity

1. **Every Finding must reference at least one Code Location.** A finding without evidence is an opinion, not an observation. The user must be able to navigate to the code and verify independently.

2. **Analysis proceeds top-down: Macro before Meso before Micro.** Later phases are informed by earlier phases. Reversing the order loses the contextual framing that makes local findings meaningful.

3. **Each Lens Analyst operates with independent context.** No Lens Analyst receives another Lens Analyst's findings. Cross-referencing happens only at the Orchestrator level during compilation. This prevents confirmation bias between lenses.

4. **The skill does not execute code.** It reads, infers, and reports. It never runs tests, starts servers, or measures runtime behavior. Findings about performance or reliability are structural inferences, not measurements.

5. **The skill does not generate or refactor code.** Its output is analysis and recommendations, not patches or pull requests.

### Pedagogical Integrity

6. **Every Finding includes all five pedagogical components.** Observation, Pattern, Tradeoff, Socratic Question, and Stewardship Recommendation are all mandatory. Omitting any one breaks the teaching structure.

7. **Findings use stewardship language, not judgment language.** "This module has accumulated responsibilities over time" — never "This module violates SRP." Properties of the code, not verdicts on its authors.

8. **Tradeoffs are presented as tensions between Quality Attributes, not as deficiencies.** "Optimizes for X at the expense of Y" — never "fails to achieve Y." The question for the user is whether the tradeoff is conscious and acceptable.

9. **Socratic Questions use "what" framing, not "why" framing.** "What happens when the schema changes?" — not "Why is this coupled to the database?" "What" invites exploration; "why" invites defensiveness.

### Coverage Integrity

10. **The skill samples strategically; it never claims exhaustive coverage.** The Architectural Analysis Report must state what was sampled and what was not. The user must understand the analysis is representative, not complete.

11. **Inferred ADRs are framed as hypotheses, not assertions.** "This codebase appears to use..." — never "This codebase uses..." The user confirms or corrects inferences.

## Amendment Log

| # | Date | Invariant | Change | Propagation |
|---|------|-----------|--------|-------------|
| — | — | — | Initial model | — |
