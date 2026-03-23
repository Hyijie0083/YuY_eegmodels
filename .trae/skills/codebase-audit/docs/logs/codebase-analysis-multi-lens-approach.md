# Research Log: Codebase Architectural Analysis Skill

## Question 1: What are the distinct analytical lenses through which a codebase should be evaluated, and what does each lens uniquely reveal?

**Method:** Web search across five threads — architecture evaluation methods, code smell taxonomies, architecture recovery, test quality assessment, architectural anti-patterns, fitness functions, architecture description models, and LLM advantages over static analysis.

### Findings

Research across these domains reveals **eight natural analytical lenses** that each surface different aspects of a codebase's health and architecture. They emerged from convergence across multiple research traditions:

#### Lens 1: Architectural Pattern Recognition (Architecture Recovery)

**What it reveals:** The *actual* architecture vs. the *intended* or *documented* architecture.

Software architecture recovery is a well-established field. Most approaches use static analysis (dependency graphs, clustering of code entities into subsystems) and increasingly dynamic analysis (runtime tracing, polymorphism resolution). Recent work (2024-2025) uses LLMs and GNNs to infer architectural components from code structure.

The key insight: most systems *have* an architecture even if nobody designed one. The "Big Ball of Mud" is itself an architectural pattern. The skill should identify:
- Named architectural patterns actually present (layered, hexagonal, event-driven, microservices, MVC, etc.)
- Patterns that are *approximated* but not fully realized (e.g., a quasi-hexagonal architecture where ports exist but adapters leak domain logic)
- The gap between any documented architecture and the reality in code

**Key source:** The C4 model (Simon Brown) and 4+1 View Model (Kruchten) provide vocabulary for *describing* architecture at multiple zoom levels — context, container, component, code. This gives the skill a structured way to report findings rather than producing an undifferentiated wall of observations.

#### Lens 2: Structural Health (Code Smells & Anti-Patterns)

**What it reveals:** Local code quality problems that indicate deeper structural issues.

The most comprehensive taxonomy is Mäntylä et al.'s seven categories: **Bloaters** (Long Method, Large Class, Long Parameter List), **Object-Oriented Abusers** (Switch Statements, Refused Bequest), **Change Preventers** (Divergent Change, Shotgun Surgery), **Dispensables** (Dead Code, Speculative Generality, Duplicated Code), **Encapsulators**, **Couplers** (Feature Envy, Inappropriate Intimacy), and **Others**.

Jerzyk (2022) extended this to 56 smells including 16 new proposals, grouped by *effect on code* rather than just category.

At the architectural level, anti-patterns include: **Big Ball of Mud**, **God Object/Blob**, **Spaghetti Code**, **Stovepipe**, **Gas Factory** (over-engineering), **Inner Platform Effect**, and **Cyclic Dependencies**.

**Key distinction the skill needs:** Code smells (local, within a function/class) vs. architectural anti-patterns (systemic, across modules). Both matter, but they have different remedies.

#### Lens 3: Intent-Implementation Alignment

**What it reveals:** Whether the code does what it *appears to be trying to do*.

This is the lens where LLMs uniquely shine over static analysis tools. Research from 2024-2025 shows LLMs can:
- Infer *intent* from naming, structure, and comments — then assess whether the implementation matches
- Detect "design-level inefficiencies even with limited contextual information"
- "Anticipate potential future risks in the code"
- Recognize patterns that are *almost* correct implementations of known patterns

Static tools can't do this — they check rules, not intent. An LLM can read a class named `UserRepository` that also handles email sending and recognize the single-responsibility violation semantically, not just structurally.

This lens also covers: naming that misleads, abstractions that don't abstract the right thing, interfaces that promise more than implementations deliver.

#### Lens 4: Test Quality

**What it reveals:** Whether the tests actually verify what matters, not just that they exist.

Research shows code coverage is a vanity metric — it measures execution, not assertion quality. The skill should evaluate tests through:

- **Test smells** (from testsmells.org catalog of 19+ smells): Assertion Roulette (multiple assertions without messages), Eager Test (testing too many things), Mystery Guest (hidden external dependencies), Empty Test, Redundant Assertion, Magic Number Test, etc.
- **Mutation testing readiness** — would the tests catch intentional code mutations? This is the gold standard for test quality.
- **Test-code correspondence** — do tests cover the right things? Are critical paths tested? Are trivial getters tested while complex business logic isn't?
- **Test architecture** — are tests organized to be maintainable? Is there excessive setup duplication? Are test utilities well-factored?

**Key finding:** Assertion Roulette causes the most damage — students take significantly longer to troubleshoot when this smell is present. The skill should weight test smells by their measured impact on maintainability.

#### Lens 5: Dead Code & Vestigial Structures

**What it reveals:** Evolutionary debris — features that were started and abandoned, code that is no longer reachable, abstractions that outlived their purpose.

This overlaps with the "Dispensables" category in Mäntylä's taxonomy (Dead Code, Speculative Generality, Lazy Class) but deserves its own lens because it reveals *history*. Dead code tells a story about the codebase's evolution — abandoned features, deprecated APIs kept "just in case," configuration for environments that no longer exist.

The skill should distinguish:
- **Unreachable code** — code paths that can never execute
- **Unused exports/APIs** — public interfaces nothing calls
- **Vestigial abstractions** — interfaces with one implementor, factories that create one type, strategies with one strategy
- **Feature ghosts** — partially-implemented features (routes that exist but lead nowhere, database columns that are written but never read)

#### Lens 6: Architectural Fitness

**What it reveals:** How well the architecture serves its quality attributes (performance, modifiability, security, operability).

From Neal Ford et al.'s "Building Evolutionary Architectures": fitness functions are objective, automated assessments of architectural characteristics. They can be:
- **Atomic** — evaluating one part on one attribute (method length, node health)
- **Holistic** — evaluating the whole system (response times under load, deployment frequency)

The skill won't run automated fitness functions, but it can *identify* which quality attributes the architecture appears to optimize for, which it neglects, and where fitness functions *should* exist but don't. It can also identify architectural decisions that create tension between quality attributes (the "tradeoff" part of ATAM).

#### Lens 7: Dependency & Coupling Analysis

**What it reveals:** How components are connected, and whether those connections are appropriate.

This is partially structural (import graphs, call graphs) and partially semantic (does this dependency make sense given the components' responsibilities?). The skill should identify:
- **Circular dependencies** — A depends on B depends on A
- **Inappropriate coupling** — UI code importing database utilities
- **Missing abstractions** — two modules that should communicate through an interface but talk directly
- **Dependency direction violations** — inner layers depending on outer layers (violating dependency inversion)
- **Afferent/efferent coupling** — which modules are heavily depended upon (stable abstractions) vs. heavily depending on others (volatile implementations)

#### Lens 8: Decision Archaeology

**What it reveals:** The *why* behind the code's current state — what architectural decisions were made (intentionally or accidentally) and their consequences.

This lens is unique to LLM-based analysis. By reading code, comments, commit patterns, and naming conventions, the skill can *infer* architectural decisions that were never documented. Research shows teams lose architectural knowledge when decisions are made verbally in meetings and never recorded.

The skill should produce inferred ADRs (Architecture Decision Records) for significant decisions it detects:
- "This codebase uses a monorepo with shared utilities" — was that intentional or accidental?
- "Authentication is handled via middleware" — by design or by accretion?
- "The database schema has no foreign keys" — performance optimization or oversight?

### Implications

The eight lenses organize into a natural hierarchy:

1. **Macro** (system-level): Architectural Pattern Recognition, Architectural Fitness, Decision Archaeology
2. **Meso** (module/component-level): Dependency & Coupling Analysis, Intent-Implementation Alignment
3. **Micro** (code-level): Structural Health, Dead Code & Vestigial Structures, Test Quality

The skill should work top-down (macro → micro) so that systemic issues provide context for local findings. A God Object is a code smell, but it might exist *because* the architecture never established proper bounded contexts — the macro lens explains the micro observation.

**LLM-specific advantages** over static tools:
- Understanding intent from naming and structure
- Recognizing *approximate* pattern implementations
- Inferring undocumented decisions
- Contextualizing local smells within architectural context
- Producing narrative explanations, not just rule violations

**LLM-specific limitations** to design around:
- False positives increase with codebase size
- Can't execute code or measure runtime behavior
- Context window limits mean sampling, not exhaustive analysis
- Findings need to be verifiable by pointing to specific code locations

---

## Question 2: How should the skill be structured as an interactive process?

**Method:** Web search on skill structure patterns, progressive disclosure, and review of existing multi-phase skills (peer-review, cw-critique).

### Findings

#### The Multi-Phase Model

The peer-review skill provides the strongest structural precedent: it runs through distinct phases with user gate-checks between them. For a codebase analysis skill, a similar phased approach works but with important differences:

1. **The codebase is the input, not a document.** Papers can be read linearly; codebases can't. The skill needs a strategy for what to read and in what order.
2. **Scale matters.** A 500-line project and a 500,000-line project need different approaches. The skill must adapt.
3. **The user may not know what they don't know.** Unlike peer review (where the author knows what feedback they want), a user approaching a new codebase may need the skill to *tell them* what to pay attention to.

#### Progressive Disclosure

Research on codebase onboarding and progressive disclosure suggests: start with the big picture, then zoom in based on what the user needs. High cognitive complexity slows comprehension and increases errors. The skill should reveal complexity in layers:

- **Layer 1: Orientation** — What is this system? What are its major components? What does it appear to do?
- **Layer 2: Architecture** — What patterns are at work? What are the key architectural decisions?
- **Layer 3: Health Assessment** — Where are the problems? What's the severity?
- **Layer 4: Deep Dives** — User-directed exploration of specific concerns

#### Subagent Architecture

Research on Claude Code multi-step agents shows the L1/L2/L3 orchestration pattern works well:
- **L1 (Orchestrator):** The main skill, managing phases and user interaction
- **L2 (Lens Analysts):** Subagents specialized in each analytical lens — launched in parallel
- **L3 (Targeted Investigation):** Deeper dives triggered by L2 findings

This mirrors the peer-review skill's independent reviewer subagents. Each lens analyst can work independently with its own context window, preventing the "context window overload" problem of trying to analyze everything at once.

#### Proposed Skill Workflow

**Phase 1: Reconnaissance & Orientation**
- Scan directory structure, file types, build configuration, README, CLAUDE.md
- Identify language(s), framework(s), build system, test framework
- Produce a "map" of the codebase — what's here, how big is it, what does it appear to do
- Present to user, confirm scope (whole codebase or specific areas?)

**Phase 2: Architectural Analysis (Macro Lenses)**
- Launch parallel subagents for: Pattern Recognition, Architectural Fitness, Decision Archaeology
- Each subagent samples strategically (entry points, core modules, configuration, boundaries)
- Compile findings into an Architectural Profile

**Phase 3: Component Analysis (Meso Lenses)**
- Launch parallel subagents for: Dependency & Coupling Analysis, Intent-Implementation Alignment
- Focused on module boundaries, interfaces, data flow
- Compile findings, cross-reference with architectural profile

**Phase 4: Code-Level Analysis (Micro Lenses)**
- Launch parallel subagents for: Structural Health, Dead Code, Test Quality
- Targeted by Phase 2-3 findings (focus on areas where architectural issues suggest code-level problems)
- Compile findings

**Phase 5: Synthesis & Education**
- Integrate all lens findings into a unified report
- Map tradeoffs: "The architecture optimizes for X at the expense of Y"
- Produce actionable recommendations prioritized by impact
- **Educate:** Explain *why* each finding matters and what the user can learn from it

**Phase 6: Stewardship Guide**
- Interactive: walk the user through findings
- Answer questions, explain tradeoffs
- Help the user develop a prioritized improvement plan
- Produce a "stewardship guide" — what to watch for, what to protect, what to improve

### Implications

The skill should be phased with progressive disclosure, use parallel subagents for each lens, and include a distinct educational/stewardship phase. The structure mirrors the peer-review skill but adapts for codebases rather than documents.

---

## Question 3: How should the skill educate the user — what does effective technical pedagogy look like when teaching through a codebase?

**Method:** Web search on code review pedagogy, Socratic method in software engineering, code stewardship, and architectural tradeoff education.

### Findings

#### Code Review as Mentoring

Research shows that the most effective learning in software engineering happens through code review — not through lectures or documentation. The key principles:

- **Natural mentoring:** Learning happens as part of daily workflow, not in special sessions. The skill should teach *through* its analysis, not in a separate "lesson" section.
- **Small, focused feedback:** Small reviews that people can absorb, rather than giant dumps of everything wrong. The skill should present findings progressively, not all at once.
- **Comment on the code, not the person:** Frame findings as properties of the code, not judgments of the developer. "This module has characteristics of a God Object" not "Someone made this a God Object."
- **"What" questions over "why" questions:** "What makes this function handle both validation and persistence?" rather than "Why did you put both responsibilities in one function?"

#### Socratic Approach

The Socratic method applied to code understanding involves:
- Asking questions that guide the user toward discovering insights rather than just stating them
- Building problem-solving intuition that transfers beyond this specific codebase
- Replacing "why" with "what" to reduce defensiveness

For the skill, this means: alongside each finding, pose the question it answers. "What happens to this system when the database schema needs to change?" → then show how Shotgun Surgery makes that painful. The question teaches the principle; the finding demonstrates it.

#### Architecture Tradeoffs as Teaching Moments

From the ATAM and quality attributes literature: "You can't optimize all quality attributes" (Stack Overflow, 2022). Every architectural decision has tradeoffs. The skill should:

- Identify which quality attributes the architecture *actually* optimizes for (whether intentionally or not)
- Show where attributes are in tension: "This architecture prioritizes development speed (many direct database queries) at the expense of testability (hard to mock data access)"
- Explain that tradeoffs aren't inherently bad — they're inherently *present*. The question is whether they're *conscious*

This transforms the skill from "here's what's wrong" into "here's what this architecture is good at and what it sacrifices — is that the tradeoff you want?"

#### Code Stewardship

The stewardship model (vs. ownership) frames code maintenance as "taking good care of that which we're entrusted with." This reframes the skill's educational output:

- Not "here's how to fix your mistakes" but "here's how to be a good steward of this code"
- Stewardship implies continuity — the code existed before you and will exist after you
- Good stewardship means understanding the system's constraints, affordances, and history
- The skill should help users develop *ongoing practices* for maintaining code health, not just fix the current issues

#### Pedagogical Structure

The educational thread should be woven throughout, not bolted on at the end. For each finding:

1. **Observation:** What the skill found (concrete, specific, pointing to code)
2. **Pattern:** What architectural concept or principle this relates to (named, explained)
3. **Tradeoff:** What this pattern optimizes for and what it costs
4. **Question:** A Socratic question that helps the user understand *why* this matters
5. **Stewardship:** What a good steward of this code would do about it (ranging from "nothing — this is fine" to "prioritize this for refactoring")

### Implications

The pedagogical dimension should be integral to the skill's output format, not a separate phase. Each finding should teach, and the overall report should help the user develop architectural intuition that transfers beyond this specific codebase. The skill's tone should be that of a senior colleague walking a new team member through the codebase — knowledgeable, patient, direct, and focused on developing the user's own judgment rather than just delivering verdicts.

---

## Question 4: What are system invariants, how do you identify them from code, and how do you detect when they're in conflict?

**Method:** Web search on Design by Contract, software invariants, conflicting constraints, and quality attribute tensions.

### Findings

#### What Are System Invariants?

From Bertrand Meyer's Design by Contract: invariants are conditions that should always hold true before and after a component's execution — properties that remain unchanged throughout the execution of a component. They operate at multiple levels:

- **Class invariants** — properties a class must maintain (e.g., "balance is never negative," "list is always sorted")
- **Module invariants** — properties a module guarantees (e.g., "all database access goes through the repository layer")
- **System invariants** — properties the entire system maintains (e.g., "every request is authenticated," "data is eventually consistent across replicas")

Most invariants in real codebases are **implicit** — they're enforced by code patterns but never stated. The skill's job is to surface these:
- Guard clauses that prevent invalid states → imply invariants about valid states
- Validation at boundaries → implies data format invariants
- Consistent error handling patterns → implies reliability invariants
- Authentication/authorization middleware → implies security invariants

#### Conflicting Invariants

Research shows quality attributes are "highly interdependent" and "interdependencies between some of these characteristics lead to conflicts." Key tensions:

- **Security vs. Usability** — stronger authentication makes the system harder to use
- **Performance vs. Consistency** — caching improves speed but risks stale data
- **Flexibility vs. Simplicity** — configuration options increase complexity
- **Write model vs. Read model** — the write side wants to be "small and defensive, focused on invariants and rules" while the read side "wants flexible, UI-friendly, denormalized views"

The skill should identify invariants the system *appears* to maintain, then check:
1. Are they consistently enforced? (Does every path enforce the same invariant, or are there gaps?)
2. Are any in tension with each other? (Does enforcing invariant A make invariant B harder to maintain?)
3. Are any in tension with the system's stated goals? (Does an invariant constraint work against what the system is trying to do?)

This is distinct from the architectural fitness lens — fitness is about quality attributes being served; invariant analysis is about consistency of enforcement and internal coherence.

### Implications

This adds a ninth lens: **Invariant Analysis**. It sits at the meso level (between macro architecture and micro code) because invariants are properties of components and their contracts, not individual functions or the whole system. It uniquely answers: "What rules does this system enforce, and does it enforce them consistently?"

---

## Question 5: How do you assess whether documentation is accurate and aligned with the actual code?

**Method:** Web search on documentation drift, misleading comments, documentation rot, and automated detection.

### Findings

#### The Documentation Drift Problem

Documentation drift occurs when code changes without accompanying documentation updates. Research shows:

- "Developers forget to update comments, and it is better not to have a comment than have one that is incorrect"
- "Outdated comments may lead to a fatal flaw sometime in the future"
- Code-comment inconsistency has been shown to correlate with bug introduction (arxiv.org, 2024)
- In Agile environments, "developers often deprioritize documentation due to tight deadlines"

#### Types of Documentation to Assess

The skill should evaluate multiple documentation layers:

1. **README / Project-level docs** — Do they describe what the project actually does and how to run it?
2. **API documentation** — Do endpoint descriptions, parameter types, and return types match the implementation?
3. **Inline comments** — Do they describe what the code *actually* does, or what it *used to* do?
4. **Architecture diagrams** — If they exist, do they match the actual structure?
5. **Configuration docs** — Do documented config options actually exist and work as described?
6. **Type annotations** — In typed languages, do the types accurately represent runtime behavior?

#### What LLMs Can Uniquely Do Here

Research shows LLMs outperform traditional approaches at detecting code-comment inconsistencies. The skill can:
- Read a function and its comment, assess whether the comment accurately describes the function
- Read a README and the actual codebase, assess whether setup instructions work
- Read API docs and the actual endpoints, flag discrepancies
- Identify "comment rot" — comments that describe deleted or moved behavior

#### What to Look For

- **Phantom documentation** — docs describing features that no longer exist
- **Aspirational documentation** — docs describing features that were never implemented
- **Misleading comments** — comments that describe the opposite of what the code does (often from copy-paste or refactoring without updating)
- **Scope mismatch** — a function comment describing a broader or narrower scope than the function actually handles
- **Version drift** — docs referencing deprecated APIs, old library versions, or removed configuration options

### Implications

This adds a tenth lens: **Documentation Integrity**. It sits at the meso level alongside Intent-Implementation Alignment — in fact, it's a specific case of alignment: does the documentation's intent match the code's implementation? But it deserves its own lens because documentation is often the first thing a new developer encounters, and misleading documentation actively harms onboarding — the exact scenario this skill is designed for.

The ten lenses now organize as:

**Macro (system-level):**
1. Architectural Pattern Recognition
2. Architectural Fitness
3. Decision Archaeology

**Meso (module/component-level):**
4. Dependency & Coupling Analysis
5. Intent-Implementation Alignment
6. Invariant Analysis
7. Documentation Integrity

**Micro (code-level):**
8. Structural Health (Code Smells)
9. Dead Code & Vestigial Structures
10. Test Quality
