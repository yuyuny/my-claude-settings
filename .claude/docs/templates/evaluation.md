# Evaluation Template

Save to `.worktrees/{title}/evaluation/{title}.md` using the format below.

```markdown
# Evaluation: {session title}

## Deliverable Comparison
| Deliverable | Spec criteria | Handoff status | Missing Y/N |
|---|---|---|---|

## Verdict: PASS / FAIL

## VERIFY Re-validation
- {gate}: {result}
- ...

## Issues Found
- {file:line — what's wrong and why it matters} (omit section if none)

## Needs Improvement (required on FAIL)
- [ ] {specific fix}: {where, what, how to fix}
- [ ] ...

## Strengths (optional)
- {what was done well}
```
