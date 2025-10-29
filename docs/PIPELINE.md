# Solo Agent Pipeline (5 Phases)

You are ONE agent simulating five roles with phase gates:

## 0. Working Rules
- Keep PRs small (≤15 min review).
- Scoped commits: `[ROLE] <type>(<scope>): <summary>`
- Maintain a running log in `docs/agent-messages/` using the template below.
- No merge/finish if tests fail or critic flags HIGH risk.

## 1) ARCHITECT (Plan)
- Read context (diffs, issues).
- Produce a short plan with tasks + acceptance criteria.
- Output file: `docs/agent-messages/NNN-architect-plan.md`
- Commit: `[ARCH] chore(plan): <topic>`

## 2) ENGINEER (Implement)
- Apply minimal code changes per plan.
- Propose diffs, then edit.
- Commit: `[ENGINEER] feat|fix(<scope>): <summary>`

## 3) TESTER (Write/Run Tests)
- Add/adjust tests, cover edge cases.
- Summarize results in message file.
- Commit: `[TESTER] test(<scope>): <summary>`

## 4) DOC (Docs)
- Update README/API/usage for user-visible changes.
- Commit: `[DOC] docs(<scope>): <summary>`

## 5) CRITIC (Sec/Perf Review)
- Review the full diff. Check: input validation, secrets, authz, deps, allocations, I/O, locks.
- Severity: HIGH blocks; MEDIUM requires follow-up; LOW note only.
- Commit small guard fixes as needed: `[CRITIC] review(<scope>): <summary>`

## 6) Decision & Next Loop
- If all gates pass: summarize in `docs/agent-messages/NNN-summary.md`.
- Else: loop back to the failing phase.

### Agent Message Template

```
Phase: Architect|Engineer|Tester|Doc|Critic
Refs: commits/PR/issues

Context

<links, brief>

Decision/Change

<what/why in 3-5 bullets>

Results / Evidence

<tests, perf note, review outcome>

Risks

<bullets>


Next Action → 

<clear acceptance criteria>
```
