# Verify Commands

Defines the verification gates to run in Generator Step 5 and Evaluator Step 2.
Replacing only this file makes the same workflow work for any stack or domain.

## Execution Rules (applies to all sub-agents)

- Build/test/lint/typecheck and other language runtime binaries must **always be invoked via the project package manager**.
- **Node/pnpm stack**: Use `pnpm <script>` or `pnpm exec <bin>`. Direct invocation of `npx`, `node <binary>`, or binaries like `vitest`, `tsc`, `eslint`, `prettier`, `stylelint`, `oxlint`, `tsx` is **prohibited**.
- Reason: git worktrees do not share the main repository's `node_modules`. Direct invocation fails to find `.bin` PATH, resulting in `command not found` or `MODULE_NOT_FOUND`.
- Exception: Inline snippets like `node -e "..."` are allowed (not invoking a file binary).
- The same principle applies to other stacks: route through the package manager (e.g., `poetry run`, `go run`).

## Current Project Gates

> **Modify this section to match your project stack.**
> Default is Node/pnpm.

```bash
pnpm test:run   # tests
pnpm typecheck  # type check
pnpm lint       # lint
pnpm build      # build (if applicable)
```

## Stack Reference Examples

> See `.claude/docs/verify-commands-examples.md` for other stack examples.
> Open it only during project setup; keep only the current project gates in this file.

## Rules

- Gates run **sequentially** — if an earlier step fails, continue running all remaining steps and report the full results
- Items without a gate (e.g., build not applicable) must be noted as `# N/A`
- Adding or removing gates and committing this file automatically propagates to both Generator and Evaluator
