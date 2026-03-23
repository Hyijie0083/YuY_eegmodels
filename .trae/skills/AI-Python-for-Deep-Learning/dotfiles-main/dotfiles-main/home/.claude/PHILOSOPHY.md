# PHILOSOPHY.md — Background & Rationale

> *"Software design is an exercise in human relationships."* — Kent Beck

This document provides the philosophical foundation and detailed rationale for the directives in [CLAUDE.md](./CLAUDE.md). It synthesizes Kent Beck's Tidy First? philosophy with humanistic perspectives on AI-assisted development from Addy Osmani, Simon Willison, Martin Fowler, Steve Yegge, DHH, and Kelsey Hightower.

**For actionable directives, see [CLAUDE.md](./CLAUDE.md).**

---

## Core Philosophy

**Software design is fundamentally about relationships** — between ideas, behavior, and structure; between waiters (those who want changes) and changers (those who make them); between your present self and your future self.

**Helping yourself feel safe in the codebase is not selfish — it's foundational.** Tidying is geek self-care. Taking time to clean messy code is an act of self-value. You are worth it.

---

## The Economics of Design

### Constantine's Equivalence
```
Cost of Software ≈ Cost of Changes ≈ Cost of Coupling
```

Maintenance dominates software costs. Maintenance costs are dominated by changes that ripple through the system. Effective design minimizes change propagation.

### Two Economic Forces in Tension

| Force | Implication |
|-------|-------------|
| **Time Value of Money** | A dollar today > a dollar tomorrow. Ship features quickly. Suggests "tidy after" or "tidy later." |
| **Optionality** | Software creates value through what it does today AND what it could do tomorrow. Structure creates options. More valuable in volatile environments. |

**The question mark in "Tidy First?" exists because of this tension.** Neither "always tidy first" nor "never tidy" is correct. Context determines the answer.

### Why Development Slows: The Exhale-Inhale Rhythm

Every feature consumes options (flexibility). Without restoration, development inevitably slows:

```
Options (flexibility)
    ↑
    │ ● Start: no features, lots of options
    │  \
    │   \  ← Pure feature development: declining options
    │    \
    │     ↘ ● End: many features, no options (stuck)
    └─────────────────────────────────────────→ Features
```

**The solution:** Alternate between two activities:
- **Exhale** — Ship features (move right on the graph)
- **Inhale** — Tidy and refactor (move up, restore options)

This creates a sustainable zigzag pattern instead of a downward slide to gridlock.

**The key question:** *"What about our current mess makes the next feature harder? What can we tidy to make it easier?"*

---

## Coupling & Cohesion

**Coupling** measures the spread of a change across elements. When changing one element requires changing another, they are coupled.

**Cohesion** measures the cost of a change within an element. An element is cohesive when the entire element changes together when the system needs to change.

### The Balance
- Elements too large: Each change multiplies costs (N × C)
- Elements too small: Changes cascade across components (potentially C^N)

**Focus primarily on reducing coupling** — its exponential risk exceeds the linear costs of larger elements.

> "Put all the manure in one pile. That's what we do with cohesion — put everything that changes at the same time in one place."

---

## Structure vs. Behavior: The Fundamental Split

**There are two kinds of changes. Always be making one kind or the other, but never both at the same time.**

| Aspect | Structure Changes | Behavior Changes |
|--------|-------------------|------------------|
| **Nature** | How code is organized | What code computes |
| **Reversibility** | Usually reversible | Often irreversible |
| **Risk** | Low — can undo easily | High — effects in the world |
| **Examples** | Rename, extract, inline | New feature, bug fix |

### Practical Application
- **Separate commits/PRs** into pure structure or pure behavior
- **Label PRs** to signal reviewers what to expect
- Structure-only PRs get approved quickly (safety review only)
- Behavior PRs reviewed for correctness, side effects, test coverage

---

## The 15 Tidyings

Small structural improvements that take minutes to hours:

1. **Guard Clauses** — Exit early when conditions aren't met; reduce nesting
2. **Dead Code** — Remove it; log usage first if uncertain
3. **Normalize Symmetries** — Express identical logic consistently; pick one way
4. **New Interface, Old Implementation** — Design the interface you want, delegate to old code
5. **Reading Order** — Arrange code for human comprehension flow
6. **Cohesion Order** — Group elements that change together
7. **Move Declaration and Initialization Together** — Keep setup adjacent to usage
8. **Explaining Variables** — Extract subexpressions into meaningfully-named variables
9. **Explaining Constants** — Replace magic numbers with named constants
10. **Explicit Parameters** — Avoid implicit assumptions in function signatures
11. **Chunk Statements** — Use blank lines to separate logical blocks
12. **Extract Helper** — Create new abstractions when vocabulary expands
13. **One Pile** — Inline extensively before refactoring when unclear how to proceed
14. **Explaining Comments** — Document non-obvious intent (sparingly)
15. **Delete Redundant Comments** — Remove comments that repeat what code says

### The "One Pile" Strategy
When code is scattered and confusing, **inline it all into one place first**. This interim design lets you see everything together, understand the actual flow, then separate concerns cleanly. Sometimes insight takes years — better to wait for the right abstraction than force a bad one.

---

## Timing: When to Tidy

### Make the Change Easy, Then Make the Easy Change

> "For each desired change, make the change easy (warning: this may be hard), then make the easy change."

This is preparatory refactoring. Like driving 20 miles north to reach a highway, then traveling 100 miles east at 3x the speed you could through the woods.

### The Four Options

| Timing | When to Use |
|--------|-------------|
| **Tidy First** | When tidying cost < behavior change cost reduction. When structure blocks understanding. |
| **Tidy After** | When code is tangled and you need to understand it through change. Keep proportionate (30-min behavior change → max 30-min tidy). |
| **Tidy Later** | When tidying now doesn't serve immediate work but pays off eventually. Add to backlog. |
| **Tidy Never** | When cost of tidying exceeds lifetime benefit. Some messes aren't worth cleaning. |

### Time Limit
More than one hour of tidying before behavioral changes likely means lost focus. Tidy enough to enable the change, no more.

---

## Small, Safe Steps

**Most software design decisions are easily reversible.** Therefore:
- Don't over-invest in avoiding mistakes
- Start moving structure toward where you think it should be
- If wrong direction, reverse easily
- Make no sudden moves — one element at a time

> "Part of what makes an expert is breaking big problems into smaller problems, where the interaction of the smaller problems also tends to be simple(-ish)."

### The Expert Pattern
Less experienced programmers try to solve too many problems at once. Experts decompose into smaller, safer steps, preserving energy for genuinely hard problems.

---

## Composable Tests

Tests can be **isolated** (each sets up its own fixture) or **composable** (multiple tests work together for confidence). These are different properties, not synonyms.

### The N × M Problem

For orthogonal dimensions — say 4 computation methods × 5 output formats — naive testing creates 20 tests with massive redundancy. Each test repeats setup and assertions from others.

**The composable solution:** N + M + 1 tests instead of N × M:
- 4 tests for computation variants (one format)
- 5 tests for format variants (one computation)
- 1 integration test proving correct wiring

### Test Pruning

When test2 cannot pass if test1 fails, they share redundant coverage. Rather than keeping both or deleting the foundational one, **simplify test2** by removing redundant setup and assertions.

The composed suite maintains:
- **Predictive power** — Same coverage
- **Specificity** — Pinpoints failures precisely
- **Readability** — Cleaner, less repetitive
- **Changeability** — Less brittle coupling

### The Principle

Optimize the **entire test suite**, not individual tests. A test that looks "incomplete" in isolation may be perfectly sufficient when composed with others.

---

## The 3X Lifecycle

Different phases demand different practices. Recognize where you are.

### Explore
**Goal:** Discover what users want
**Constraint:** Product not yet successful
**Strategy:** Many small, low-cost experiments
**Speed metric:** Time from idea to measured feedback
**Quality stance:** Quick and dirty acceptable; long-term sustainability not the goal yet

### Expand
**Goal:** Scale to meet explosive demand
**Constraint:** Bottlenecks killing growth
**Strategy:** Find the next thing that can kill you and fix it
**Nature:** Short, intense, transitional
**Quality stance:** Whatever removes the bottleneck fastest

### Extract
**Goal:** Sustain growth through efficiency
**Constraint:** Need profitability while finishing growth
**Strategy:** Refinement, optimization, sustainability
**Approach:** Detailed analysis, playbooks, incremental improvement
**Quality stance:** Rigorous testing, structured releases, systematic processes

**The mistake of XP was trying to be a set of tools for all three phases.** Adapt your practices to your phase.

---

## Self, Team, Product

Three concentric circles of care:

### Self (This Guide's Primary Focus)
How do you treat yourself as a programmer? Tidying is geek self-care. Don't power through messy code like walking in tight shoes.

### Team
How do programmers treat each other? Design decisions carry relational weight. Changing an API causes pain to colleagues. Acknowledge and address relationship effects of technical choices.

### Product
Cross-functional relationships between developers and non-developers. Establish boundaries while showing mutual care despite disagreements.

**Start with self-care as the foundation** for healthy team dynamics and eventual product stewardship.

---

## Waiters & Changers

- **Waiters**: Those requesting features; can't implement themselves; want speed
- **Changers**: Those modifying code; must live with consequences; need sustainability

Their incentives inherently conflict. Good design skills maintain productive relationships between them.

**The first step is acknowledging that relationships are more important than system design.** With a productive working relationship, you can move design in any direction. When relationships break down, nothing gets anywhere.

---

## Decision Framework Summary

When facing a change:

1. **Is this structure or behavior?** Do one at a time, never both.
2. **What phase am I in?** Explore/Expand/Extract demand different approaches.
3. **Should I tidy first?**
   - Will tidying reduce total time? → Tidy first
   - Is code too tangled to understand? → Tidy first
   - Would I not feel complete without it? → Tidy first
   - Would coming back later be too expensive? → Tidy now
   - Is the mess not worth cleaning? → Tidy never
4. **How do I tidy?** Small, safe, reversible steps. One element at a time.
5. **When do I stop?** When the change becomes easy. No more.

---

## AI-Assisted Development

> *"AI tools amplify existing expertise. The more skills and experience you have, the faster and better the results."* — Simon Willison

This section synthesizes insights from Addy Osmani, Simon Willison, Martin Fowler, Steve Yegge, DHH, and Kelsey Hightower on human-AI collaboration in software development.

### The 70% Problem

AI can rapidly produce 70% of a solution, but the final 30% — edge cases, security, production integration, error handling — still requires real engineering knowledge. This explains a paradox: developers report dramatic productivity gains, yet software quality hasn't noticeably improved.

**Why this happens:**
- AI excels at happy-path demos but misses craft elements
- Non-engineers hit a wall of cascading failures without mental models to debug
- Software quality was never primarily limited by coding speed

**The implication:** AI tools help experienced developers more than beginners. They accelerate what you already understand.

### Vibe Coding vs. Vibe Engineering

| Vibe Coding | Vibe Engineering |
|-------------|------------------|
| Fast, loose, exploratory | Structured, accountable |
| Accept AI suggestions without review | Review everything before execution |
| "Empty calories" of learning | Skills amplified by AI tools |
| Appropriate for throwaway prototypes | Required for production systems |

**Vibe Engineering** means seasoned professionals accelerating their work with AI while staying "proudly and confidently accountable for the software they produce."

### Avoiding Big Design Up Front (BDUF)

LLMs have a structural bias toward exhaustive, comprehensive output. Generating a 20-section design doc costs the same effort as generating a 3-section one, so the default is to produce everything. This is the opposite of what good engineering practice calls for.

**Why BDUF is especially dangerous with AI:**
- It *feels* productive — you get a polished artifact quickly
- It front-loads decisions that should be deferred until you have real information
- It creates false confidence: a detailed spec looks authoritative whether or not its assumptions are correct
- It discourages experimentation by implying the design is settled

**What to do instead:**
- Treat documents like code: start minimal, iterate based on feedback
- A plan is a hypothesis. Validate it by building, not by adding more detail.
- When you reach uncertainty in a plan, stop and note it — don't speculate past it
- The right length for a design doc is the shortest one that lets you start building

This connects to Beck's insight that most software design decisions are easily reversible. If reversing is cheap, specifying exhaustively upfront is waste. Invest in specification proportionally to the cost of being wrong.

> *"Plans are useless, but planning is indispensable."* — Eisenhower

The value is in the thinking, not the document. A conversation that surfaces the hard tradeoff is worth more than a polished spec that buries it in section 12.

### The AI-First Draft Workflow

```
Generate → Review → Refactor → Test → Document
```

1. **Generate**: Let AI produce initial code from clear specifications
2. **Review**: Treat output like code from a junior developer requiring mentorship
3. **Refactor**: Apply tidyings; AI-generated code often needs structural improvement
4. **Test**: Mandatory — "If you haven't seen it run, it's not a working system"
5. **Document**: Capture intent and decisions for future maintainers

### Context Is Everything

The quality of AI output is directly proportional to context quality. Effective context includes:

- **Code files**: Relevant source, schemas, types
- **Error messages**: Exact stack traces, not vague descriptions
- **Examples**: Concrete input/output demonstrating desired patterns
- **Constraints**: Version numbers, performance targets, compatibility requirements
- **Documentation**: Framework docs, especially for post-training-cutoff libraries

**Plan first, code second.** Request architectural options and specifications before implementation. Writing detailed specs clarifies requirements and prevents overcomplicated approaches.

### Trust Calibration

Trust in AI builds through three pillars:

| Pillar | Description |
|--------|-------------|
| **Familiarity** | Knowledge of the tools and tasks |
| **Trust** | Earned through reliable, verified delivery |
| **Control** | Desired oversight varies by task complexity |

Adjust trust levels based on:
- Task criticality (prototype vs. production)
- Your expertise in the domain
- How well you can verify correctness

### Refactoring Becomes More Important

Martin Fowler observes that AI-generated code volumes increase the importance of refactoring. LLMs produce varying quality — refactoring maintains code health. The rise of AI makes Beck's tidyings more relevant, not less.

**Warning:** "Vibe coding" without comprehension eliminates the learning loop. Use AI to accelerate, not to skip understanding.

### The Humanity Skills Shift

> *"The next skills developers will need are humanities skills — communication, coordination, all the things you don't learn in engineering degrees."* — Steve Yegge

As AI handles more mechanical coding:
- **Architecture and design** become more valuable
- **Empathy and user understanding** differentiate developers
- **Communication skills** matter more when orchestrating AI agents
- **Judgment and taste** determine what to build and how

Kelsey Hightower: "The new software developer would be doing way more prototyping and customer research... studying the art, not just the craft."

### The Joy of Programming

DHH's caution: "If I promote myself out of programming, I turn myself into a project manager of AI crows."

Keep code in a separate window. Maintain competence. "You're not going to get fit by watching fitness videos — you have to do the sit-ups."

The joy is in understanding. Use AI as a brilliant pair programmer, not a replacement for thinking.

### Production-Ready Checklist

Before shipping AI-assisted code:

- [ ] Security review (input sanitization, auth, injection prevention)
- [ ] Comprehensive tests (unit, integration, edge cases)
- [ ] Code review for logic, performance, maintainability
- [ ] Error handling and logging verified
- [ ] Documentation updated
- [ ] Dependencies reviewed and pinned

---

## Principles for AI Assistance

When working on code:

1. **Read before writing.** Understand existing structure and patterns.
2. **One kind of change at a time.** Structure OR behavior, not both.
3. **Small steps.** Each change should be obviously correct in isolation.
4. **Preserve reversibility.** Prefer changes that can be undone.
5. **Respect existing patterns.** Normalize symmetries rather than introduce new conventions.
6. **Minimize coupling.** Changes should stay local when possible.
7. **Maximize cohesion.** Keep related things together.
8. **Make the change easy first.** Preparatory tidying before difficult behavior changes.
9. **Know when to stop.** Tidy enough to enable the work, no more.
10. **Acknowledge relationships.** Design affects people, not just code.

---

## Further Reading

### Kent Beck — Software Design
- [Software Design: Tidy First?](https://tidyfirst.substack.com/) — Kent Beck's Substack
- [Why Does Development Slow?](https://tidyfirst.substack.com/p/why-does-development-slow) — The exhale-inhale rhythm
- [Composable Tests](https://tidyfirst.substack.com/p/composable-tests) — N + M + 1 instead of N × M
- *Tidy First?: A Personal Exercise in Empirical Software Design* — Book (Part 1 of 3)
- *Tidy Together* — Upcoming book on team dynamics
- Yourdon & Constantine's *Structured Design* — The foundational text on coupling and cohesion

### AI-Assisted Development
- [Beyond Vibe Coding](https://beyond.addy.ie/) — Addy Osmani's comprehensive guide
- [The 70% Problem](https://addyo.substack.com/p/the-70-problem-hard-truths-about) — Addy Osmani on hard truths about AI coding
- [Vibe Engineering](https://simonw.substack.com/p/vibe-engineering) — Simon Willison on accountability with AI
- [How I Use LLMs to Write Code](https://simonw.substack.com/p/how-i-use-llms-to-help-me-write-code) — Simon Willison's practical guide
- *Vibe Coding* — Gene Kim & Steve Yegge (IT Revolution, 2025)
- [Martin Fowler on AI and Software Engineering](https://www.deciphr.ai/podcast/how-ai-will-change-software-engineering--with-martin-fowler)
- [Engineering with Empathy](https://www.infoq.com/podcasts/engineering-empathy/) — Kelsey Hightower

---

*"Tidy first? Likely yes. Just enough. You are worth it."*

*"AI tools amplify existing expertise. You are the engineer; the AI is an assistant."*