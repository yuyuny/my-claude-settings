# CLAUDE.md

Personal Claude Code settings for 1–3 person indie game development on JS/TS engines (Phaser, PixiJS, Three.js, Canvas 2D, Electron+React+PixiJS).

For a human-readable overview, see [README.md](../README.md).

## Workflow

```
/spec → /build → /check → /reflect
                     ↑
                     /prototype (uncertainty) → promote to /spec when clear
```

1. Every non-trivial change starts with a spec. `/build` refuses to run without one.
2. Uncertainty goes through `/prototype`. Spikes live in `prototypes/**`, exempt from standard rules.
3. `/check` closes the loop: automated gates + playtester.
4. `/reflect` closes the session: honest diary, not status report.

## User-driven collaboration

- **Question → Options → Decision → Draft → Approval.** Never write files or run destructive commands without explicit approval.
- **Plan first.** Show the implementation plan before editing code.
- **No commits without instruction.** Even if the change is obviously done.
- **Respect `defaultMode: plan`.** You start in plan mode for a reason.

## Agent hierarchy

Two directors guard long-term coherence. Three workers execute. Playtester evaluates.

- `creative-director` (Opus) — identity, tone, pillars. Read-only.
- `technical-director` (Opus) — architecture, performance, ADRs. Read-only.
- `designer` (Sonnet) — spec authorship, playtest plans.
- `engineer` (Sonnet) — implementation, code review.
- `playtester` (Haiku) — fresh-eyes evaluator; no code output.

Agents are invoked automatically by commands. Call them by name only for one-off questions.

## Rules

- `prototypes/**` is exempt from formal rules — see `.claude/rules/prototypes.md`.
- All agents share a voice contract — see `.claude/rules/agent-voice.md`.
- Project-specific rules live in the project's own `.claude/rules/project/*.md`. Read those before writing code; the common rules here do not override them.
