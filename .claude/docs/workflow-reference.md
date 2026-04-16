# Workflow Reference

Core rules in `.claude/rules/multi-agent-workflow.md`.
This file contains detailed information on model assignments, workflow flow, state machine, directory structure, and semi-automation.

---

## Model Assignment

All commands run with the session's active model (`opusplan` by default).
Sub-agents launched via the Agent tool also inherit the active model unless overridden.

| Task | Notes |
|------|-------|
| SCOPE (parallel exploration) | Sub-agents — 2~3 in parallel |
| Implementation | Main session |
| REVIEW (`/simplify`) | Sub-agent |
| Spec writing | Main session |
| Evaluation | Separate session (independence requirement) |
| Reflection | Main session |

> Using a cheaper model (e.g., sonnet) for the main session significantly reduces cost across long IMPLEMENT phases. Change `"model"` in `settings.json` to adjust.

---

## Workflow Flow

`/spec` → `/generate` → `/evaluate` (separate session) → `/reflect`

`/gen-eva` — Chains `/generate` + `/evaluate` in one session. On FAIL, performs 1 rework cycle and re-evaluates. Escalates to user after 2 consecutive FAILs.

See each command file for detailed process (`.claude/commands/`)

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
idle → spec_ready → generating → handoff_ready → evaluated_pass → reflecting → done
                                               → evaluated_fail  (human decides: rework / redefine spec / abandon)

# /gen-eva shortcut (generate + evaluate + 1 rework in one session):
# spec_ready → generating → handoff_ready → [evaluator sub-agent] → evaluated_pass → (human: /reflect)
#                                                                  → evaluated_fail → generating (rework) → handoff_ready → [evaluator sub-agent] → evaluated_pass / evaluated_fail (escalate to human)
```

- `spec_ready`: recorded after `/spec` completes

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

The following directories are created inside **worktree branches** (`.worktrees/{title}/`):
- `specs/` — written by `/spec`. Generator must not modify. Evaluator only updates checkboxes after PASS.
- `handoffs/` — Generator → Evaluator context
- `evaluation/` — Evaluator reports
- `reflections/` — session reflection records

Merging (`git merge {title}`) brings all artifacts into the main branch.
