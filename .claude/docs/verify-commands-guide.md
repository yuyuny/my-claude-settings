# Verify Commands — Guide

> This file is reference material. The actual gates are defined in `.claude/rules/verify-commands.md`.

## Package Manager Execution Rules (applies to all sub-agents)

- Build/test/lint/typecheck and other language runtime binaries must **always be invoked via the project package manager**.
- **Node/pnpm stack**: Use `pnpm <script>` or `pnpm exec <bin>`. Direct invocation of `npx`, `node <binary>`, or binaries like `vitest`, `tsc`, `eslint`, `prettier`, `stylelint`, `oxlint`, `tsx` is **prohibited**.
- Reason: git worktrees do not share the main repository's `node_modules`. Direct invocation fails to find `.bin` PATH, resulting in `command not found` or `MODULE_NOT_FOUND`.
- Exception: Inline snippets like `node -e "..."` are allowed (not invoking a file binary).
- The same principle applies to other stacks: route through the package manager (e.g., `poetry run`, `go run`).

## Stack Reference Examples

See `.claude/docs/verify-commands-examples.md` for other stack examples.
Open it only during project setup; keep only the current project gates in `verify-commands.md`.
