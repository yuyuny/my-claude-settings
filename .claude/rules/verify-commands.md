# Verify Commands

Verification gates for Generator Step 5 and Evaluator Step 2.

> **Always invoke binaries via the project package manager** (worktrees don't share `node_modules`).
> Details and rationale: `.claude/docs/verify-commands-guide.md`

## Current Project Gates

> **Modify this section to match your project stack.**

```bash
pnpm test:run   # tests
pnpm typecheck  # type check
pnpm lint       # lint
pnpm build      # build (if applicable)
```

## Rules

- Gates run **sequentially** — if an earlier step fails, continue running all remaining steps and report the full results
- Items without a gate (e.g., build not applicable) must be noted as `# N/A`
- Adding or removing gates and committing this file automatically propagates to both Generator and Evaluator
