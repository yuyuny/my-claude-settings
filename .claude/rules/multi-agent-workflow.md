# Multi-Agent Workflow

## Model Assignment

| Task                  | Model                    |
| --------------------- | ------------------------ |
| Exploration (SCOPE)   | `sonnet` — 2~3 in parallel |
| Implementation (IMPLEMENT) | `sonnet`            |
| Review (REVIEW)       | `opus`                   |
| Brainstorming         | `opus`                   |
| Spec Writing          | `sonnet`                 |
| Evaluation            | `opus`                   |
| Reflection            | `sonnet`                 |

> Main session assumes `sonnet`. Running `/generate` with `opus` significantly increases cost across the IMPLEMENT/PLAN phases.

## Workflow

`/brainstorm` (optional) → `/spec` → `/generate` → `/evaluate` (separate session) → `/reflect`

`/gen-eva` — Chains `/generate` and `/evaluate` in one session. On FAIL, performs 1 rework cycle and re-evaluates. Escalates to user after 2 consecutive FAILs.

`/brainstorm` is optional, not the default. If requirements are already clear in the main session, skip it and start with `/spec`.

See each command file for detailed process (`.claude/commands/`)

## Core Rules

- Session identifiers use kebab-case: `auth-login`, `player-movement`
- All work from `/spec` onward happens in `.worktrees/{title}` (no direct modification of the main branch). `/brainstorm` runs on main.
- Evaluator must run in a different session from Generator
- Verification gates are enforced — gate definitions in `.claude/rules/verify-commands.md`. Default for code: TDD (RED → GREEN → REFACTOR). For areas where testing is not feasible (UI layout, assets, balance values, etc.), specify alternative verification methods in the spec's acceptance criteria and record the reason in the handoff.
- `/simplify` diff-based code review — **minimum once per session** + once every 2-3 tasks (record results in the handoff REVIEW log). Not exempt even if task count is small.
- No handoff before VERIFY passes
- Independent tasks always run in parallel
- Reference materials (specs/handoffs/evaluation, etc.) — quote only the relevant portion; never summarize or rewrite

## Sub-agent Output Contract

All sub-agents (SCOPE, REVIEW, etc.) follow these rules to protect the main session context:

- **Bullet-only returns**: Return as bullet lists only. No raw code or file content dumps. Code snippets max 3 lines.
- **15 bullet cap**: Maximum 15 bullets per agent. If exceeded, select the top 15 by priority.
- **Write to file first**: If results will be saved to a file (handoff/evaluation/reflection), the sub-agent writes directly and reports only "done Y/N + critical or not" to main.
- **No document summarization**: Quote only the relevant parts of reference materials. Never summarize or rewrite.

> For state machine, directory structure, and semi-automation (Stop hook) details, see `.claude/docs/workflow-reference.md`.
