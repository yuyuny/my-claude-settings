# Multi-Agent Workflow

> Model assignments, workflow diagram, and state machine details: `.claude/docs/workflow-reference.md`

## Core Rules

- Session identifiers use kebab-case: `auth-login`, `player-movement`
- All work from `/spec` onward happens in `.worktrees/{title}` (no direct modification of the main branch).
- Evaluator must run in a different session from Generator
- Verification gates are enforced — gate definitions in `.claude/rules/verify-commands.md`. Default for code: TDD (RED → GREEN → REFACTOR). For areas where testing is not feasible (UI layout, assets, balance values, etc.), specify alternative verification methods in the spec's acceptance criteria and record the reason in the handoff.
- `/simplify` diff-based code review — **minimum once per session** + once every 2-3 tasks (record results in the handoff REVIEW log). Not exempt even if task count is small.
- No handoff before VERIFY passes
- Independent tasks always run in parallel
- Reference materials (specs/handoffs/evaluation, etc.) — quote only the relevant portion; never summarize or rewrite
- Glossary: add new domain terms to `docs/GLOSSARY.md` only if existing entries are present (skip if empty)

## Sub-agent Output Contract

- **Bullet-only returns**: No raw code or file content dumps. Code snippets max 3 lines.
- **15 bullet cap**: Maximum 15 bullets per agent. Select top 15 by priority if exceeded.
- **Write to file first**: Sub-agent writes directly, reports only "done Y/N + critical or not" to main.
- **No document summarization**: Quote only relevant parts. Never summarize or rewrite.
