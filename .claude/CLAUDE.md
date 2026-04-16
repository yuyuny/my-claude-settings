# CLAUDE.md

This repository is a Claude Code multi-agent workflow template.

## Workflow Overview

`/brainstorm` (optional) → `/spec` → `/generate` → `/evaluate` (separate session) → `/reflect`

Core rules: `.claude/rules/multi-agent-workflow.md`

## Files to Modify When Applying to a New Project

1. `.claude/rules/verify-commands.md` — Replace the current project gate section to match your stack
2. `evaluation/rubric-v1.md` — Check the weight profile for your project type (UI/CLI/infrastructure)
3. `.claude/settings.local.json` — Add CLI permissions used by your project
4. `.claude/settings.json` — Verify the `"model"` setting (default: `opusplan`)

## Default Behavior

- **Default mode**: `plan` (settings.json) — switch to ask/auto mode when implementing
- **Stop hook**: Automatically guides the next step after each command completes (clipboard copy + notification)

## Check Session Status

```
/workflow-status
```

## Gate Examples by Stack

See `.claude/docs/verify-commands-examples.md`
