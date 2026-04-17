# Prototypes path rule

Files under `prototypes/**` are exempt from the normal workflow and quality rules.

## What's exempt

- **No spec required.** `/build` gates only apply to `src/` and similar production paths.
- **No lint/typecheck gates.** The engineer does not run `pnpm lint` or `pnpm typecheck` on prototype code.
- **No formal tests.** Ad-hoc scripts are fine; Vitest suites are not expected.
- **No director review.** Creative-director and technical-director do not evaluate prototype code.
- **No immutability discipline.** Mutate freely, hardcode freely, copy-paste freely.

## What's required

- A `README.md` at the root of each `prototypes/<name>/` directory with:
  - **What I'm exploring** — one sentence.
  - **Hypothesis** — what I expect to learn.
  - **How to run** — exact command or instruction.
  - **Status** — `exploring`, `promoted-to-spec`, or `abandoned`.

## What's forbidden

- `src/` must never import from `prototypes/`. Prototypes are off-map.
- Do not merge prototype code into `src/` directly. Promote by writing a `/spec` and re-implementing cleanly.
- Do not invest in prototype quality. If you find yourself refactoring a prototype, you've exited prototype mode — stop and spec it.

## Lifecycle

1. `/prototype <name>` scaffolds the directory.
2. Engineer implements the spike.
3. User decides:
   - **Promote** → write a `/spec` for real implementation. Leave the prototype as a reference or delete it.
   - **Abandon** → set README status to `abandoned`. Keep in tree as a record of what was tried.
   - **Delete** → remove the directory.
