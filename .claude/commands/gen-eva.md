# Gen-Eva Orchestrator (opusplan)

Runs `/generate` and `/evaluate` in sequence within a single session.
On FAIL, performs one rework cycle and re-evaluates.
After two consecutive FAILs, stops and asks the user for a decision.

This command does NOT replace `/generate` or `/evaluate`.
Those commands can still be used independently for manual control.

## Inputs
- `specs/{title}.md` — must exist (run `/spec` first)
- `evaluation/{title}.md` — (optional) previous evaluation for rework context

## Process

### Phase 1: Generate

Execute the full `/generate` process for `{title}`:
- Follow every step in `.claude/commands/generate.md` (Step 0 through Step 6)
- All rules in generate.md apply without exception (TDD, REVIEW, VERIFY, context dump, etc.)
- On completion, `handoff_ready` state must be recorded and `handoffs/{title}.md` must exist

### Phase 2: Evaluate

Launch an independent evaluator as an isolated sub-agent:

```
Agent(
  description: "Evaluate {title}",
  model: "opus",
  prompt: <read .claude/commands/evaluate.md and substitute {title}>
)
```

**Independence guarantee**: The Agent tool creates a fresh context — the sub-agent cannot see this session's generate conversation. Only `specs/{title}.md`, `handoffs/{title}.md`, and `.worktrees/{title}/` are accessible via file reads.

**Receive the result**: The sub-agent writes `evaluation/{title}.md` and records `evaluated_pass` or `evaluated_fail` state. It returns only a short summary to this session.

- **If PASS** → go to [Completion].
- **If FAIL** → go to Phase 3.

### Phase 3: Rework (1 attempt)

Read `evaluation/{title}.md` to understand FAIL feedback, then re-execute the `/generate` process:
- Follow `.claude/commands/generate.md` rework procedure (Step 0: existing worktree, Step 1: SCOPE decision tree checks evaluation feedback)
- The evaluation's "Needs Improvement" checklist is the rework scope — do not fix anything outside it
- A new HANDOFF must be written after rework

### Phase 4: Re-evaluate

Launch the evaluator sub-agent again (same method as Phase 2).

- **If PASS** → go to [Completion].
- **If FAIL** → go to [Escalation].

### Completion

On PASS (from Phase 2 or Phase 4):

1. Output a summary with clickable links:

   **✅ PASS** — [evaluation/{title}.md](.worktrees/{title}/evaluation/{title}.md) | [handoffs/{title}.md](.worktrees/{title}/handoffs/{title}.md)

2. Guide next step:
   - `evaluated_pass` is already recorded by the evaluator sub-agent
   - Output: "Next: run `/reflect {title}`, then merge + cleanup"

### Escalation

On second consecutive FAIL:

1. Output a clear alert with the evaluation link:

   **❌ FAIL ×2** — [evaluation/{title}.md](.worktrees/{title}/evaluation/{title}.md)
   Two consecutive FAILs. Automatic rework limit exceeded.

2. Present options to the user:
   - `claude "/generate {title}"` — manual rework and retry
   - `claude "/spec {title}"` — redefine spec
   - Clean up the worktree and abandon

3. Do not proceed further. Wait for user decision.

## Rules

- **Maximum 1 rework**: Phase 3→4 is the only retry. No further loops.
- **generate.md rules fully apply**: TDD, REVIEW, VERIFY, context dump — all enforced. Context dump splits the generate phase but does NOT restart the gen-eva cycle.
- **evaluate.md rules fully apply**: scoring, rubric, independent verification — all enforced.
- **No shortcutting evaluate**: Even if the rework was a 1-line fix, the full evaluate process runs.
- **State machine compliance**: All state transitions (generating, handoff_ready, evaluated_pass/fail) are recorded via `workflow-advance.sh` as usual.
- **Context dump during generate**: If generate hits a context dump condition, split the session. The user then resumes manually with `/generate {title}`, then `/evaluate {title}`. Gen-eva is for tasks small enough to complete without session splits.

## Final Output
After Phase 2 or Phase 4 PASS, output a single summary line:
  **✅ Gen-Eva PASS** — [evaluation/{title}.md](.worktrees/{title}/evaluation/{title}.md) | Next: `/reflect {title}`

$ARGUMENTS
