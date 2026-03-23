# CLAUDE.md — Agent Directives

Actionable guidance for AI-assisted development. For philosophy and rationale, see [PHILOSOPHY.md](./PHILOSOPHY.md).

---

## Prime Directives

1. **Read before writing.** Never modify code you haven't read. Understand existing structure first.
2. **One change type at a time.** Structure OR behavior, never both in the same commit.
3. **Small, reversible steps.** Each change should be obviously correct in isolation.
4. **Preserve existing patterns.** Match the codebase's conventions; don't introduce new ones.
5. **Verify before moving on.** Test that changes work. "If you haven't seen it run, it's not working."

---

## Boundaries

### ✅ Always Do
- Read relevant files before modifying them
- Run tests after changes: `npm test`, `pytest`, `go test ./...`
- Separate structure changes from behavior changes in commits
- Match existing code style exactly
- Keep changes minimal and focused on the request

### ⚠️ Ask First
- Adding new dependencies
- Changing database schemas or migrations
- Modifying CI/CD configuration
- Architectural changes affecting multiple modules
- Deleting files or significant code blocks

### 🚫 Never Do
- Modify code you haven't read
- Mix refactoring with behavior changes in one commit
- Add features beyond what's requested
- Create abstractions for one-time operations
- Commit secrets, credentials, or API keys
- Push to main/master without explicit permission

---

## Decision Framework

```
Before any change, ask:
├─ Have I read the relevant code?
│   └─ No → Read it first
├─ Is this structure or behavior?
│   └─ Both → Split into separate changes
├─ Should I tidy first?
│   ├─ Will it reduce total time? → Yes
│   ├─ Is code too tangled to understand? → Yes
│   └─ Is the mess not worth cleaning? → No, proceed
├─ Can I make this change smaller?
│   └─ Yes → Do that
└─ Is the change easy now?
    └─ Yes → Stop tidying, make the change
```

**The key question:** *"What about our current mess makes the next feature harder? What can we tidy to make it easier?"*

---

## Documents & Plans

**No Big Design Up Front.** LLMs naturally produce exhaustive, comprehensive documents. Resist this.

- **Write the thinnest document that supports the next decision.** A 3-line sketch that gets validated beats a 3-page spec that doesn't.
- **Stop planning at the first point of uncertainty.** Build a spike to resolve it instead of speculating past it.
- **Plans go to the next learning point, not to completion.** If step 4 depends on what you learn in step 2, don't detail steps 4–10.
- **Documents describe what *is*, not what *will be*.** Update docs after changes, not before.
- **Prefer conversation over documentation.** If the user is present, ask — don't write a requirements doc.

```
Before generating a document, ask:
├─ What decision does this enable?
│   └─ None specific → Don't write it
├─ Can I learn the answer faster by building?
│   └─ Yes → Build instead
├─ Am I speculating past known facts?
│   └─ Yes → Stop here, mark unknowns
└─ Is this longer than it needs to be?
    └─ Probably → Cut it in half
```

---

## Model Selection

Not all work requires the most capable model. Match the model to the task:

| Model | Use for | Examples |
|-------|---------|----------|
| **Opus** | Architecture, research, writing, complex reasoning, multi-file design | `/rdd-research`, `/rdd-decide`, `/argument-audit`, `/peer-review`, tricky bugs |
| **Sonnet** | Implementation, refactoring, test writing, code changes | `/rdd-build`, feature work, test suites, straightforward debugging |
| **Haiku** | Simple file operations, formatting, lookups, mechanical tasks | Renaming, simple edits, grep-and-replace, boilerplate generation |

**Opus is the writer and architect, not the bricklayer.** Use Sonnet for implementation once the design is clear. Use Haiku for tasks that don't require judgment.

When spawning subagents via the Task tool, set the `model` parameter to match the work: `model: "haiku"` for file lookups, `model: "sonnet"` for implementation tasks, and reserve Opus (default) for research and design.

---

## Code Style

**Follow existing patterns.** If the codebase uses:
- Tabs → use tabs
- Single quotes → use single quotes
- `snake_case` → use `snake_case`
- Trailing commas → use trailing commas

**When in doubt, match the surrounding code exactly.**

---

## Git Workflow

```bash
# Structure change (safe, reviewable quickly)
git commit -m "refactor: extract validation into helper"

# Behavior change (needs careful review)
git commit -m "feat: add email validation to signup"

# Always verify before committing
git diff --staged
```

**Commit message prefixes:** `feat:`, `fix:`, `refactor:`, `test:`, `docs:`, `chore:`

**Never mix structure and behavior in one commit.**

---

## The 70% Rule

AI gets ~70% of a solution quickly. The critical 30% — edge cases, security, error handling, production concerns — requires careful human-grade review.

**Treat your own output like a junior developer's PR.** Review it critically.

---

## Tidying Checklist

When structure blocks progress, apply these (minutes, not hours):

- [ ] **Guard clauses** — Exit early, reduce nesting
- [ ] **Normalize symmetries** — Same logic, same expression
- [ ] **Explaining variables** — Name complex subexpressions
- [ ] **Chunk statements** — Blank lines between logical blocks
- [ ] **Reading order** — Arrange for human comprehension
- [ ] **Dead code** — Remove it

**Stop when the change becomes easy.**

---

## Testing Principles

**Compose tests, don't duplicate.** For N × M combinations, write N + M + 1 tests:
- N tests for one dimension (holding other constant)
- M tests for other dimension (holding first constant)
- 1 integration test proving correct wiring

**Prune redundant tests.** If test2 can't pass when test1 fails, simplify test2 — remove shared setup and assertions. Optimize the suite, not individual tests.

---

## Common Commands

```bash
# Testing
npm test                    # JavaScript/TypeScript
pytest -v                   # Python
go test ./...              # Go
cargo test                  # Rust

# Linting
npm run lint               # ESLint
ruff check .               # Python
go vet ./...               # Go

# Type checking
npx tsc --noEmit           # TypeScript
mypy .                     # Python
```

---

## Sources

Distilled from Kent Beck (Tidy First?), Addy Osmani (Beyond Vibe Coding), Simon Willison (Vibe Engineering), Martin Fowler, Steve Yegge, DHH, and Kelsey Hightower.

Full philosophy and rationale: [PHILOSOPHY.md](./PHILOSOPHY.md)