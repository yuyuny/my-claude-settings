# Evaluation Template

Save to `.worktrees/{title}/evaluation/{title}.md` using the format below.

```markdown
# Evaluation: {session title}

> Rubric: v1.0 (`../../evaluation/rubric-v1.md`)

## Deliverable Comparison
<!-- Produced directly by the evaluator. -->
| Deliverable | Spec criteria | Handoff status | Missing Y/N |
|---|---|---|---|

## Verdict: PASS / FAIL

## VERIFY Re-validation
- Tests: {result}
- Typecheck: {result}
- Lint: {result}
- Build: {result}

## Scorecard
| Criteria | Score | Evidence |
|---|---|---|
| Feature completeness | {n}/10 | {1-2 sentences} |
| Code quality | {n}/10 | {1-2 sentences} |
| Design/UX | {n}/10 | {1-2 sentences} |
| Edge cases | {n}/10 | {1-2 sentences} |
| **Weighted average** | **{n}/10** | |

## Strengths (max 5)
- {what went well}

## Needs Improvement (required on FAIL)
- [ ] {specific fix 1}: {where, what, why}
- [ ] {specific fix 2}: ...

## Verification Log (max 5, no raw output dump — summaries only)
- Test run results: {N passed / N failed}
- Behavior check: {scenario checked and PASS/FAIL}
```
