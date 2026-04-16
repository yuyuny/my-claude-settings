# Workflow Reference

Core rules in `.claude/rules/multi-agent-workflow.md`.
This file contains detailed information on the state machine, directory structure, and semi-automation.

---

## Semi-automation (Stop Hook)

After each command completes, the Stop hook (`.claude/scripts/workflow-advance.sh`) automatically:
- **Copies the next command to clipboard**
- **Sends a desktop notification** (macOS)
- **Injects a guidance message into the Claude session**

**3 approval gates** requiring human intervention:

| State | Gate reason |
|---|---|
| `spec_ready` | Review before finalizing spec content (block wrong assumptions) |
| `evaluated_pass/fail` | Confirm merge or decide on rework/abandon |
| Evaluator launch point | Manual start in a separate session (independence principle) |
| `/gen-eva` 2nd FAIL | Automatic rework exhausted — human decides next step |

The remaining transitions (brainstorm→spec, spec→generate, reflect→done) are automatically recommended by the hook.

---

## State Machine

```
# With /brainstorm:
idle → brainstorming → spec_draft → spec_ready → generating
                                              → handoff_ready → evaluating → evaluated_pass → reflecting → done
                                                                           → evaluated_fail  (human decides: rework / redefine spec / abandon)

# Without /brainstorm (run /spec directly): idle → spec_ready (brainstorming/spec_draft skipped)

# /gen-eva shortcut (generate + evaluate + 1 rework in one session):
# spec_ready → generating → handoff_ready → [evaluator sub-agent] → evaluated_pass → (human: /reflect)
#                                                                  → evaluated_fail → generating (rework) → handoff_ready → [evaluator sub-agent] → evaluated_pass / evaluated_fail (escalate to human)
```

- `brainstorming`: recorded immediately after `/brainstorm` Step 1 (title decided)
- `spec_draft`: recorded after `/brainstorm` completes — intermediate state before `/spec` is run
- `spec_ready`: recorded after `/spec` completes (regardless of whether brainstorm ran)

State is recorded in `.claude-workflow/sessions/{title}.json` (gitignored, local only).
Check current state: `/workflow-status`

---

## Concurrent Sessions

Multiple `{title}` sessions can run in parallel without conflicts:
- State files are separate per session (`.claude-workflow/sessions/{title}.json`)
- Generator worktrees are physically isolated at `.worktrees/{title}`
- Stop hook identifies the current session via `CLAUDE_WORKFLOW_TITLE` env var (falls back to most recent file if unset)

---

## Directory Structure

- `.worktrees/` — git worktree workspace (.gitignore added)
- `.claude-workflow/` — workflow execution state (gitignored, local only)
- `brainstorms/` — Brainstormer artifacts. Committed to **main branch**. (absent if `/brainstorm` was skipped)

The following directories are created inside **worktree branches** (`.worktrees/{title}/`):
- `specs/` — written by `/spec`. Generator must not modify. Evaluator only updates checkboxes after PASS.
- `handoffs/` — Generator → Evaluator context
- `evaluation/` — Evaluator reports
- `reflections/` — session reflection records

Merging (`git merge {title}`) brings all artifacts into the main branch.
