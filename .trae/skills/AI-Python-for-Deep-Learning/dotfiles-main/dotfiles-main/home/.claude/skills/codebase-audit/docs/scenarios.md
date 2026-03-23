# Behavior Scenarios: Codebase Audit Skill

## Feature: Reconnaissance & Orientation

### Scenario: Orchestrator reconnoiters a Codebase and produces a Codebase Map
**Given** the user invokes `/codebase-audit` on a directory containing source code, configuration, and a README
**When** the Orchestrator completes the Reconnaissance phase
**Then** a Codebase Map is presented to the user containing:
  - Directory structure overview
  - Language(s) and framework(s) identified
  - Build system and dependency manifest identified
  - Test framework and test file locations identified
  - Apparent purpose (inferred from README, entry points, and structure)
  - Estimated scale (file count, approximate line count)
  - Components identified (major modules/packages/services)

### Scenario: User scopes the Analysis after Reconnaissance
**Given** the Orchestrator has presented the Codebase Map
**When** the user confirms the scope (whole Codebase, specific Components, or specific concerns)
**Then** the Analysis proceeds to Macro Analysis with the confirmed scope
**And** the Codebase Map records the user's scope decision

### Scenario: Codebase Map provides sufficient navigation for Lens Analysts
**Given** a Codebase Map produced from Reconnaissance of a multi-module project
**When** a Lens Analyst receives the Codebase Map as context
**Then** the Lens Analyst can identify which directories to examine for its sampling directive without additional guidance from the Orchestrator

---

## Feature: Macro Analysis (Parallel Lens Analysts)

### Scenario: Pattern Recognition Lens Analyst identifies architectural patterns
**Given** a Lens Analyst launched for Pattern Recognition with the Codebase Map
**When** the Lens Analyst samples entry points, directory structure, module boundaries, and dependency manifests
**Then** the Lens Analyst produces Findings that:
  - Name each identified architectural pattern with a confidence qualifier
  - Identify patterns that are approximated but incomplete
  - Note the gap between any documented architecture and the actual architecture
  - Each Finding references at least one Code Location

### Scenario: Architectural Fitness Lens Analyst identifies Quality Attribute tensions
**Given** a Lens Analyst launched for Architectural Fitness with the Codebase Map
**When** the Lens Analyst samples configuration, cross-cutting concerns, and error handling
**Then** the Lens Analyst produces Findings that:
  - Name Quality Attributes the architecture appears to optimize for
  - Name Quality Attributes that appear neglected
  - Identify tensions between Quality Attributes as Tradeoffs

### Scenario: Decision Archaeology Lens Analyst produces Inferred ADRs
**Given** a Lens Analyst launched for Decision Archaeology with the Codebase Map
**When** the Lens Analyst samples configuration, naming conventions, and structural patterns
**Then** the Lens Analyst produces Inferred ADRs that:
  - Are framed as hypotheses ("This codebase appears to...")
  - Describe the decision, its apparent context, and its observed consequences
  - Each references Code Locations that evidence the decision

### Scenario: Macro Lens Analysts operate independently within the phase
**Given** Pattern Recognition, Architectural Fitness, and Decision Archaeology Lens Analysts are launched in parallel
**When** all three complete their analysis
**Then** no Lens Analyst's Findings reference or depend on another Lens Analyst's output from the same phase

### Scenario: Orchestrator compiles Macro Findings into an Architectural Profile
**Given** all three Macro Lens Analysts have returned their Findings
**When** the Orchestrator compiles the results
**Then** an Architectural Profile is produced containing:
  - Identified patterns (from Pattern Recognition)
  - Quality Attribute fitness assessment (from Architectural Fitness)
  - Inferred decisions (from Decision Archaeology)
  - Areas flagged for deeper investigation in subsequent phases

---

## Feature: Meso Analysis (Informed by Architectural Profile)

### Scenario: Meso Lens Analysts receive Architectural Profile as context
**Given** the Macro Analysis phase has completed and the Orchestrator has compiled the Architectural Profile
**When** Meso Lens Analysts (Dependency & Coupling, Intent-Implementation Alignment, Invariant Analysis, Documentation Integrity) are launched
**Then** each Meso Lens Analyst receives:
  - The Codebase Map
  - The Architectural Profile
  - Its lens-specific sampling directive

### Scenario: Invariant Analysis Lens Analyst surfaces implicit system invariants
**Given** a Lens Analyst launched for Invariant Analysis
**When** the Lens Analyst samples validation code, middleware, guard clauses, and error handlers
**Then** the Lens Analyst produces Findings that:
  - Name each identified Invariant (class, module, or system level)
  - Note which Invariants are explicitly stated vs. implicitly enforced
  - Identify enforcement gaps (paths that skip the Invariant)
  - Identify tensions between Invariants
  - Each Finding references the Code Locations where enforcement occurs (and where it's missing)

### Scenario: Documentation Integrity Lens Analyst detects Documentation Drift
**Given** a Lens Analyst launched for Documentation Integrity
**When** the Lens Analyst samples README, inline comments, API docs, and type annotations
**Then** the Lens Analyst produces Findings for each discrepancy found, categorized as:
  - Comment rot (describes deleted/moved behavior)
  - Phantom documentation (describes removed features)
  - Aspirational documentation (describes unimplemented features)
  - Scope mismatch (comment describes broader/narrower scope than the code)
  - Version drift (references deprecated APIs or old library versions)

---

## Feature: Micro Analysis (Targeted by Prior Findings)

### Scenario: Micro Lens Analysts receive targeting from prior phases
**Given** Macro and Meso Analysis phases have completed
**When** Micro Lens Analysts (Structural Health, Dead Code, Test Quality) are launched
**Then** each Micro Lens Analyst receives:
  - The Codebase Map
  - The Architectural Profile
  - The Meso Summary
  - Areas of concern flagged by prior phases for focused investigation

### Scenario: Test Quality Lens Analyst identifies test smells
**Given** a Lens Analyst launched for Test Quality
**When** the Lens Analyst samples test files and test configuration
**Then** the Lens Analyst produces Findings that:
  - Identify specific Test Smells by name (Assertion Roulette, Eager Test, Mystery Guest, etc.)
  - Assess test-production code correspondence (are critical paths tested?)
  - Note areas where tests exist but don't verify meaningful behavior
  - Each Finding references specific test file Code Locations

### Scenario: Structural Health Lens Analyst distinguishes Code Smells from Anti-Patterns
**Given** a Lens Analyst launched for Structural Health
**When** the Lens Analyst produces Findings
**Then** each Finding clearly categorizes the observation as either:
  - A Code Smell (local, within a function/class) with its Mäntylä taxonomy category
  - An Anti-Pattern (systemic, across modules) with its named type
  - Never conflates the two categories

---

## Feature: Finding Pedagogical Format

### Scenario: Every Finding contains all five pedagogical components
**Given** a Lens Analyst has identified an observation in the Codebase
**When** the Lens Analyst produces a Finding
**Then** the Finding contains exactly:
  1. An Observation (concrete, specific, referencing Code Locations)
  2. A Pattern (named architectural concept with brief explanation)
  3. A Tradeoff (what this optimizes for and what it costs, connecting Quality Attributes)
  4. A Socratic Question (using "what" framing, not "why")
  5. A Stewardship Recommendation (using stewardship language, not judgment language)

### Scenario: Finding uses stewardship language
**Given** a Lens Analyst has identified a Component with accumulated responsibilities
**When** the Finding's Stewardship Recommendation is written
**Then** it uses language like "This module has accumulated responsibilities over time"
**And** it does not use language like "This module violates SRP" or "This is a bad design"

### Scenario: Socratic Question uses "what" framing
**Given** a Lens Analyst has identified a Dependency & Coupling concern
**When** the Finding's Socratic Question is written
**Then** the question begins with "What" (e.g., "What happens to this system when...")
**And** the question does not begin with "Why" (e.g., not "Why is this coupled to...")

### Scenario: Tradeoff connects Quality Attributes in tension
**Given** a Lens Analyst has identified a pattern that affects multiple Quality Attributes
**When** the Finding's Tradeoff is written
**Then** it names at least two Quality Attributes and describes the tension between them
**And** it frames the tension as "optimizes for X at the expense of Y" rather than "fails at Y"

---

## Feature: Synthesis & Report

### Scenario: Orchestrator synthesizes all Findings into an Architectural Analysis Report
**Given** all Lens Analysts across all phases have returned their Findings
**When** the Orchestrator performs the Synthesis phase
**Then** an Architectural Analysis Report is written to `./docs/codebase-audit.md` containing:
  - Executive Summary (derived from Codebase Map + key takeaways)
  - Architectural Profile section
  - Tradeoff Map section
  - Findings organized by Level (Macro, Meso, Micro)
  - Stewardship Guide section (What to Protect, What to Improve, Ongoing Practices)

### Scenario: Orchestrator merges complementary Findings at the same Code Location
**Given** two Lens Analysts from different phases have produced Findings referencing the same Code Location but with different Patterns and Tradeoffs
**When** the Orchestrator compiles Findings
**Then** both Findings appear in the report as a "multi-lens observation" at that Code Location
**And** the report notes which lenses converged on this area

### Scenario: Orchestrator deduplicates redundant Findings
**Given** two Lens Analysts have produced Findings referencing the same Code Location with substantially the same Observation, Pattern, and Tradeoff
**When** the Orchestrator compiles Findings
**Then** only one Finding appears in the report
**And** the report notes which lenses independently converged on this observation (strengthening confidence)

### Scenario: Report states sampling coverage
**Given** the Orchestrator has completed Synthesis
**When** the Architectural Analysis Report is written
**Then** the report includes a "Scope & Coverage" section stating:
  - What scope the user confirmed
  - What was sampled by each Level
  - An explicit disclaimer that the analysis is representative, not exhaustive

---

## Feature: Interactive Walkthrough

### Scenario: User walks through Findings with the Orchestrator
**Given** the Architectural Analysis Report has been written and the user has reviewed it at the Synthesis gate
**When** the Walkthrough phase begins
**Then** the Orchestrator offers to walk through Findings by:
  - Level (Macro → Meso → Micro)
  - Priority (highest-impact Findings first)
  - Component (user picks which areas to explore)
  - Or freely, responding to user questions

### Scenario: User asks about a specific Finding during Walkthrough
**Given** the Walkthrough phase is active and the user asks about a specific Finding
**When** the Orchestrator responds
**Then** the response contextualizes the Finding within the Architectural Profile
**And** explains the Tradeoff in terms the user can relate to their goals
**And** offers concrete next steps from the Stewardship Recommendation

---

## Feature: Mandatory Gates

### Scenario: Reconnaissance gate blocks until user scopes
**Given** the Orchestrator has completed Reconnaissance and presented the Codebase Map
**When** the user has not yet confirmed the scope
**Then** the Analysis does not proceed to Macro Analysis

### Scenario: Synthesis gate presents report before Walkthrough
**Given** the Orchestrator has completed Synthesis and produced the Architectural Analysis Report
**When** the report is presented to the user
**Then** the Orchestrator waits for user acknowledgment before proceeding to the Walkthrough phase

---

## Feature: Invariant Enforcement

### Scenario: Lens Analyst Finding without Code Location is rejected
**Given** a Lens Analyst produces output that includes a claim about the Codebase
**When** the claim is not anchored to at least one specific Code Location (file path and line range)
**Then** the Orchestrator does not include it in the Architectural Analysis Report

### Scenario: Skill does not execute code
**Given** the user invokes `/codebase-audit` on any Codebase
**When** any phase of the Analysis runs
**Then** no test suites are executed, no servers are started, and no build commands are run
**And** all Findings about performance or reliability are explicitly framed as structural inferences

### Scenario: Inferred ADRs use hypothesis framing
**Given** the Decision Archaeology Lens Analyst has identified an apparent architectural decision
**When** the Inferred ADR is written
**Then** it uses language like "This codebase appears to..." or "The evidence suggests..."
**And** it does not use language like "This codebase uses..." or "The developers decided to..."
