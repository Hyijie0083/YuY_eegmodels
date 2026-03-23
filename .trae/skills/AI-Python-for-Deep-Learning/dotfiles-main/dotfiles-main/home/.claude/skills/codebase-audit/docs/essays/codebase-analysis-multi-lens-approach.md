# Codebase Architectural Analysis: A Multi-Lens Approach to Understanding Software Systems

## The Problem

Every developer who inherits a codebase faces the same questions: What is this system *actually* doing? How is it put together? Is the architecture intentional or accidental? Where are the bodies buried?

These questions are surprisingly hard to answer with existing tools. Static analysis catches rule violations — functions too long, cyclic dependencies, unused imports — but it cannot tell you whether the architecture serves the system's goals. Linters enforce style but have nothing to say about whether the tests actually test what matters. Code coverage reports tell you what runs but not what's verified. And documentation, when it exists, may describe a system that no longer resembles the code.

The gap is between *mechanical analysis* (what tools can measure) and *architectural understanding* (what a senior engineer perceives when they read the code). Static analysis tools operate on rules; architectural understanding operates on intent, patterns, tradeoffs, and history. An experienced engineer reading a codebase can recognize that a class named `UserService` that also handles email notifications is violating single responsibility — not because it breaks a metric threshold, but because its name promises one thing and its implementation delivers another. That same engineer can look at a module structure and say "this is trying to be hexagonal architecture but the ports are leaking implementation details."

This kind of analysis — recognizing the gap between what code *intends* and what it *achieves*, between the architecture that was designed and the one that emerged — is something LLMs can do and static analysis tools cannot. The question is how to structure that capability into something systematic, reliable, and educational.

## What We Learned

### Ten Analytical Lenses

Research across software architecture evaluation methods (ATAM, SAAM), code smell taxonomies (Mäntylä, Jerzyk), software architecture recovery, test quality assessment, architectural fitness functions, and documentation drift analysis revealed ten distinct analytical lenses. Each surfaces something the others miss. They organize into three levels:

**Macro lenses** examine the system as a whole:

1. **Architectural Pattern Recognition** identifies which architectural patterns the code actually implements — not what the README says, but what the dependency graph, module structure, and data flow reveal. Drawing from the field of software architecture recovery, this lens detects named patterns (layered, hexagonal, event-driven, MVC), patterns that are approximated but incomplete, and the gap between documented and actual architecture. The C4 model (context, container, component, code) provides vocabulary for reporting findings at the right zoom level.

2. **Architectural Fitness** evaluates how well the architecture serves its quality attributes — performance, modifiability, security, testability, operability. Borrowing from Neal Ford's fitness functions concept, this lens identifies which attributes the architecture optimizes for (whether intentionally or not), which it neglects, and where attributes are in tension. It doesn't run automated fitness tests, but it identifies where they should exist and don't.

3. **Decision Archaeology** infers the architectural decisions that shaped the codebase — decisions that were often made verbally, accidentally, or by accretion rather than design. By reading code, comments, naming conventions, and structural patterns, this lens produces inferred Architecture Decision Records for significant choices: "This codebase uses a monorepo with shared utilities — was that intentional?" "Authentication is handled via middleware — by design or by accident?" Research shows teams routinely lose architectural knowledge; this lens recovers it.

**Meso lenses** examine module and component relationships:

4. **Dependency & Coupling Analysis** maps how components connect and whether those connections are appropriate. It identifies circular dependencies, coupling violations (UI code importing database utilities), missing abstractions (modules that should communicate through an interface but talk directly), and dependency direction violations (inner layers depending on outer layers). This is partially structural (import graphs) and partially semantic (does this dependency make sense given the components' responsibilities?).

5. **Intent-Implementation Alignment** is the lens where LLMs most distinctly outperform static tools. It assesses whether code does what it *appears to be trying to do* — whether naming matches behavior, whether abstractions abstract the right thing, whether interfaces deliver what they promise. Research from 2024-2025 confirms LLMs can detect "design-level inefficiencies even with limited contextual information" and recognize patterns that are *almost* correct implementations of known patterns.

6. **Invariant Analysis** surfaces the rules a system enforces — often implicitly — and checks whether they're consistently maintained. Drawing from Bertrand Meyer's Design by Contract, this lens identifies invariants from guard clauses, validation patterns, middleware, and error handling. It then checks for gaps (paths that skip enforcement), tensions (invariants that conflict with each other), and alignment (do the invariants serve the system's goals?). A system that requires authentication on every endpoint but has three unauthenticated routes has an invariant violation that's invisible to any tool that isn't tracking the invariant.

7. **Documentation Integrity** assesses whether documentation describes the system that actually exists. Research shows documentation drift correlates with bug introduction, and that LLMs outperform traditional approaches at detecting code-comment inconsistencies. This lens checks README accuracy, comment rot (comments describing deleted behavior), phantom documentation (docs for removed features), aspirational documentation (docs for unimplemented features), API doc drift, and scope mismatch.

**Micro lenses** examine code-level quality:

8. **Structural Health** evaluates code smells and anti-patterns using established taxonomies. Mäntylä et al.'s seven categories (Bloaters, Object-Oriented Abusers, Change Preventers, Dispensables, Encapsulators, Couplers) provide the local view, while architectural anti-patterns (Big Ball of Mud, God Object, Spaghetti Code, Gas Factory, Inner Platform Effect) provide the systemic view. The key distinction: code smells are local symptoms; architectural anti-patterns are systemic diseases. The macro lenses provide context — a God Object might exist because the architecture never established proper bounded contexts.

9. **Dead Code & Vestigial Structures** identifies evolutionary debris: unreachable code paths, unused exports, vestigial abstractions (interfaces with one implementor, factories that create one type), and feature ghosts (partially-implemented features — routes that lead nowhere, database columns written but never read). This lens reveals the codebase's history and the cost of carrying abandoned work.

10. **Test Quality** evaluates whether tests actually verify what matters. Drawing from the test smell catalog (19+ documented smells including Assertion Roulette, Eager Test, Mystery Guest, Empty Test), mutation testing research, and test-code correspondence analysis, this lens assesses assertion quality, test-production code alignment, and test architecture. Research shows Assertion Roulette is the most damaging test smell — it significantly increases troubleshooting time.

### The Power of Top-Down Analysis

These lenses are ordered deliberately. The skill works top-down — macro lenses first, then meso, then micro — because systemic issues provide context for local findings. When the structural health lens finds a God Object, the architectural pattern lens has already identified that the system lacks bounded contexts. When the test quality lens finds Eager Tests, the intent-alignment lens has already noted that the module's responsibilities are unclear. Top-down analysis turns isolated observations into a coherent narrative.

### Where LLMs Uniquely Contribute

Static analysis tools are better at exhaustive, rule-based checking. They can scan every line, enforce every rule, and produce zero false negatives for defined violations. LLMs cannot match this.

But LLMs can do what static tools cannot:

- **Understand intent** from naming, structure, and comments — then assess whether implementation matches
- **Recognize approximate patterns** — code that is *trying* to be hexagonal architecture but isn't quite there
- **Infer undocumented decisions** — architectural choices that were made but never recorded
- **Contextualize local problems** within architectural context — explaining *why* a code smell exists, not just *that* it exists
- **Produce narrative explanations** rather than rule violation lists
- **Detect documentation inaccuracy** by comparing prose descriptions to code behavior
- **Surface implicit invariants** from enforcement patterns

The skill should lean into these strengths and not try to replicate what linters already do well.

### LLM Limitations to Design Around

- **False positives scale with codebase size.** The skill must sample strategically rather than analyze exhaustively.
- **No runtime analysis.** The skill cannot execute code, measure performance, or observe behavior under load. Findings about performance or reliability are inferences from structure, not measurements.
- **Context window limits.** Large codebases cannot fit in a single context. The skill uses parallel subagents, each with focused scope.
- **Findings must be verifiable.** Every observation must point to specific code locations so the user can verify independently.

## The Pedagogical Dimension

The research revealed something important: the most effective technical learning happens through code review, not through documentation or lectures. When a senior developer walks a junior developer through code, explaining not just *what* they see but *why* it matters and *what tradeoffs* it represents, the junior developer builds architectural intuition that transfers to every future codebase.

This skill should be that senior colleague. Not a fault-finding tool that dumps a list of violations, but an architectural mentor that walks the user through the codebase, building understanding progressively.

### Teaching Through Tradeoffs

The single most important pedagogical insight from the architecture evaluation literature: *you cannot optimize all quality attributes*. Every architectural decision trades one attribute for another — performance for testability, flexibility for simplicity, security for usability. The key question is not "is this architecture good?" but "what is this architecture good *at*, and what does it sacrifice?"

When the skill identifies that a codebase uses direct database queries throughout (rather than a repository pattern), it should not just flag this as a coupling problem. It should explain: "This architecture prioritizes development speed — adding a new query is fast because there's no abstraction layer. The tradeoff is testability — mocking data access for unit tests requires database fixtures. If your priority is rapid prototyping, this tradeoff may be deliberate. If your priority is test-driven development, this architecture is working against you."

This framing transforms every finding into a learning moment about architectural tradeoffs.

### The Finding Format

Each finding follows a five-part structure that teaches while it reports:

1. **Observation** — What the skill found (concrete, pointing to specific code)
2. **Pattern** — What architectural concept this relates to (named, briefly explained)
3. **Tradeoff** — What this pattern optimizes for and what it costs
4. **Question** — A Socratic question that builds the user's understanding ("What happens to this system when the database schema needs to change?")
5. **Stewardship** — What a good steward of this code would do (ranging from "nothing — this is a conscious tradeoff" to "prioritize this for refactoring — it's actively harming development velocity")

The Socratic question is the critical piece. It doesn't tell the user what to think — it gives them the question that, once they answer it for themselves, teaches the underlying principle.

### Code Stewardship, Not Code Judgment

The skill's framing should be stewardship, not ownership. Stewardship means "taking good care of that which we're entrusted with" — the code existed before the user arrived and will exist after they move on. The skill helps the user understand what they're stewarding: its strengths, its weaknesses, its history, its invariants, its conscious and unconscious tradeoffs.

This reframing matters because it's non-judgmental toward the code's authors (who may include the user) while still being honest about the code's state. "This module has accumulated responsibilities over time" is stewardship language. "This module violates SRP" is judgment language. Both describe the same situation, but the first invites improvement while the second invites defensiveness.

## The Approach: Phased Analysis with Progressive Disclosure

### Phase 1: Reconnaissance & Orientation

The skill begins by mapping the codebase — scanning directory structure, build configuration, README, framework choices, language distribution, test setup. It produces an orientation document: what's here, how big is it, what does it appear to do. This gives both the skill and the user a shared map before diving deeper.

The user confirms scope at this point — whole codebase, specific modules, or specific concerns.

### Phase 2: Macro Analysis

Parallel subagents analyze the three macro lenses: Architectural Pattern Recognition, Architectural Fitness, and Decision Archaeology. Each subagent samples strategically — entry points, core modules, configuration, boundaries, public APIs — rather than reading every file. Findings are compiled into an Architectural Profile.

### Phase 3: Meso Analysis

Parallel subagents analyze the four meso lenses: Dependency & Coupling, Intent-Implementation Alignment, Invariant Analysis, and Documentation Integrity. These are informed by Phase 2 findings — if the architecture is layered, the coupling analysis focuses on layer boundaries; if the architecture is event-driven, the invariant analysis focuses on event contracts.

### Phase 4: Micro Analysis

Parallel subagents analyze the three micro lenses: Structural Health, Dead Code, and Test Quality. These are targeted by Phase 2-3 findings — if architectural analysis identified unclear module boundaries, structural health focuses on God Objects and Feature Envy in those areas. If invariant analysis found enforcement gaps, test quality checks whether tests cover those paths.

### Phase 5: Synthesis & Education

The orchestrator integrates all lens findings into a unified Architectural Analysis Report. This is the primary deliverable — a narrative document that:

- Describes the system's actual architecture (patterns, fitness, decisions)
- Maps its tradeoffs ("optimizes for X at the expense of Y")
- Presents findings using the five-part pedagogical format
- Prioritizes recommendations by impact
- Produces a stewardship guide — what to watch for, what to protect, what to improve

### Phase 6: Interactive Walkthrough

The final phase is interactive. The skill walks the user through the findings, answering questions, explaining tradeoffs, and helping them develop a prioritized improvement plan. This is where the pedagogical approach reaches its fullest expression — the user can ask "why does this matter?" and "what would you do about this?" and receive contextualized, educational answers.

## Key Design Principles

1. **Top-down, not bottom-up.** Start with architecture, end with code. Systemic context makes local findings meaningful.

2. **Tradeoffs, not verdicts.** "This architecture prioritizes X at the expense of Y" teaches more than "this architecture is wrong."

3. **Stewardship, not judgment.** Frame findings as properties of the code that the user can steward, not mistakes that someone made.

4. **Evidence-based.** Every finding points to specific code. The user can verify independently.

5. **Progressive disclosure.** Reveal complexity in layers. Don't dump everything at once.

6. **Parallel subagents.** Each lens gets its own clean context. The orchestrator compiles findings.

7. **Teach, don't just diagnose.** The five-part finding format (observation, pattern, tradeoff, question, stewardship) ensures every finding is a learning moment.

8. **Language-agnostic.** The analytical lenses are universal architectural concepts. The skill adapts to whatever language and framework it encounters.

## What This Skill Is Not

- **Not a linter.** It won't catch every unused import or formatting inconsistency. Use ESLint, Ruff, or go vet for that.
- **Not exhaustive.** It samples strategically. Large codebases get representative analysis, not line-by-line review.
- **Not a replacement for running tests.** It evaluates test quality but doesn't execute them.
- **Not a code generator.** It produces analysis and recommendations, not refactored code.
- **Not opinionated about architecture.** It doesn't say "you should use hexagonal architecture." It says "here's what your architecture is, here's what it's good at, and here's what it costs you."
