# Handoff Template

`handoffs/{title}.md` must include all sections below.

```markdown
# Handoff: {session title}

## Task Breakdown
<!-- Pre-written in Step 2 PLAN. Record directly here. -->
- Task 1: {description}
- Task 2: {description}
- ...

## Completed Deliverables
- [x] Deliverable 1: {completion status summary}
- [x] Deliverable 2: ...
- [ ] Deliverable 3: {reason if incomplete}

## Design Notes (if applicable)
- Key decisions: {decision — rationale}
- Constraints: {trade-offs or technical debt}

## Known Gotchas (omit section if none)
- {Traps the next agent might miss — implicit side effects, duplicate paths, ordering dependencies}
- e.g., "Feature X bypasses the standard pipeline and calls a separate storage path — that path also needs updating"

## REVIEW Log
<!-- Minimum 1 entry per session required. Handoff is incomplete if empty. -->
- Round 1 (required, after tasks 1-3 or before session end): {issue in 80 chars or "none"} / {fix commit hash + 1 line or "-"}
- Round 2 (optional, after tasks 4-6): ...
<!-- Round 4+: omit rounds with no issues. /simplify sub-agent appends directly. -->

## VERIFY Results
- Tests: {n passed / 0 failed}
- Typecheck: PASS
- Lint: PASS
- Build: PASS
- How to run: `{test command}`

## How to Verify Behavior
- `{run command}`
- {key scenarios to check}
```
