# Multi-Agent Project Guidelines

This repo is developed by five specialized agents running in parallel via Crush:

- **Architect** – system design, boundaries, trade-offs, refactor direction
- **Engineer** – implements code changes, keeps code idiomatic, small PRs
- **Tester** – writes/maintains tests, ensures coverage & reproducibility
- **Documenter** – updates READMEs, API docs, examples, diagrams
- **Critic (Security & Performance)** – reviews diffs for vulns, perf issues

All agents MUST read and follow this document.

---

## 1. Coordination & Hand-offs

- **Source of truth**: this file.
- **Shared “radio channel”**: Markdown notes in `docs/agent-messages/` (see §2).
- **One iteration = one loop**:
  1. Architect posts/updates plan
  2. Engineer implements
  3. Tester adds/updates tests, runs locally
  4. Documenter updates docs
  5. Critic reviews security/perf; files issues or comments
  6. Architect resolves conflicts, decides next step

**Handoff protocol** (always write a note):
- Each role writes a short note in `docs/agent-messages/NNN-<role>-<topic>.md`
- Include: `Context`, `Decision/Change`, `Open Questions`, `Next Action → <role>`

---

## 2. Shared Notes (Agent “radio channel”)

Directory: `docs/agent-messages/`

File pattern: `NNN-<role>-<slug>.md` (increment `NNN`)

Template:

```md
# <Title>
**Role**: <Architect|Engineer|Tester|Documenter|Critic>  
**Refs**: PR #, commits, issues

## Context
<summary, links to code/diffs>

## Decision / Change
<what you did or propose, why>

## Open Questions
<bullets>

## Next Action → <role>
<clear ask with acceptance criteria>
```

---

## 3. Branching & PRs
- Branches: `feat/<topic>`, `fix/<topic>`, `chore/<topic>`, `docs/<topic>`
- PR size: Prefer PRs that a human can review in ≤15 min
- PR flow: Engineer opens PR → Tester pushes tests to same PR → Documenter adds docs → Critic reviews → Architect approves

---

## 4. Commit Policy

Use scoped, role-tagged commits:

```
[ROLE] <type>(<scope>): <short summary>
```

Examples:
- `[ENGINEER] feat(api): add /healthz with probe`
- `[TESTER] test(api): add regression tests for /healthz`
- `[DOC] docs(api): document /healthz and liveness`
- `[CRITIC] review(api): flag allocation in hot path`
- `[ARCH] chore: split package layout per RFC-001`

Body (recommended sections):

```
Context:
Changes:
Tests:
Risks:
Follow-ups:
```

Keep commits atomic and narrative (tell the story of the change).

---

## 5. Test, Docs, and Quality Gates
- Tester owns failing tests; collaborates with Engineer to fix
- Documenter updates docs in the same PR as code/tests
- Critic checks:
  - Security: input validation, authz, secret handling, dependencies
  - Performance: allocations, hotspots, I/O, locks, regressions (baseline vs. new)
- Architect blocks merges if architecture or boundaries drift

---

## 6. Decision Records

For significant decisions, add `docs/adr/ADR-YYYYMMDD-<slug>.md` with:
- Context, Options, Decision, Consequences, Links (PRs, issues)

---

## 7. Tooling Etiquette (Crush)
- Request minimal context (respect `.crushignore`)
- Propose diffs before large edits; prefer small, reviewable chunks
- Never bypass tests/docs phases in the loop
- Annotate notes with `Next Action → <role>` to keep momentum

---

## 8. SLAs (lightweight)
- Architect responds to open questions within one iteration
- Engineer keeps CI green; no PR merges with red tests
- Tester keeps changed packages ≥ baseline coverage
- Documenter updates user-facing changes before merge
- Critic reviews within the same iteration; must propose concrete mitigations

---

## 9. Directory Layout (suggested)

```
docs/
  agent-messages/          # shared notes (the “radio”)
  adr/                     # decision records
.github/
  PULL_REQUEST_TEMPLATE.md
```

Create `docs/agent-messages/.keep` (empty file) to keep the folder in Git.

Create `.github/PULL_REQUEST_TEMPLATE.md`:

```md
## Summary
<what/why>

## Checklist
- [ ] Code implemented (Engineer)
- [ ] Tests added/updated & passing (Tester)
- [ ] Docs updated (Documenter)
- [ ] Security/Perf review addressed (Critic)
- [ ] Architectural consistency (Architect)

## Notes
- Context / risks / follow-ups
```

Optionally, add a commit message template `.gitmessage.txt` and set:

```
git config commit.template .gitmessage.txt
```

---

## 10. First Iteration Recipe

1. Architect pane
   - Create `docs/agent-messages/001-architect-plan.md` with a small refactor/feature plan.
   - End with `Next Action → Engineer`.
2. Engineer pane
   - Implement minimal slice, commit with `[ENGINEER] feat(<scope>): ...`
   - Leave `docs/agent-messages/002-engineer-impl.md` with context + `Next Action → Tester`.
3. Tester pane
   - Add tests; commit `[TESTER] test(<scope>): ...`
   - Note results; `Next Action → Documenter` (if user-facing) and `→ Critic`.
4. Documenter pane
   - Update docs; commit `[DOC] docs(<scope>): ...`
   - Note; `Next Action → Critic`.
5. Critic pane
   - Review git diff (or PR); commit `[CRITIC] review(<scope>): ...` if making tiny guard changes or open issues.
   - Note; `Next Action → Architect` for sign-off.
6. Architect pane
   - Approve/redirect next loop.

---

## 11. Practical Habits & Tips
- Keep `docs/agent-messages/` terse but continuous—this becomes your “auditable chat log.”
- Prefer small PRs that include tests & docs; avoid “doc-later.”
- When the Critic flags a risk, ask for a minimal diff not just a description.
- Use ADR only for decisions that change boundaries/constraints.
