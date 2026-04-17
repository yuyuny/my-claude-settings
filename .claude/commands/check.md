---
description: Verify a built feature against spec — automated checks + playtester observations.
argument-hint: <spec-filename-or-slug>
---

# /check — verify against spec

Run the full verification pass on a feature.

## Process

1. **Locate the spec.** As with `/build`, refuse if no spec found.

2. **Run automated checks:**
   - Detect the project's package manager: look for `pnpm-lock.yaml`, `yarn.lock`, `bun.lockb`, or `package-lock.json` in that order; fall back to `npm`.
   - Read `package.json` `scripts`. Run whichever of `typecheck`, `test:run` (or `test`), `lint`, and `lint:css` exist, using the detected package manager.
   - Collect pass/fail per check.

3. **If any automated check fails:** stop here. Append a `## Check — <date>` block with the failure details, then prompt the user: "Fix the failing gates, then re-run `/check`." Do **not** proceed to steps 4–5.

4. **Verify acceptance criteria.** (Only reached if all gates green.) For each checkbox in the spec's `Acceptance criteria`, mark the current state:
   - `[x]` if demonstrably satisfied (tests, or observable behavior in code)
   - `[ ]` if unsatisfied
   - `[?]` if cannot be determined without running the game

5. **Invoke the `playtester` subagent** with the spec's `Playtest plan` and a brief description of the built feature. If a live play report or screenshot is available, include it; otherwise the playtester will ask for one.

6. **Append results to the spec file** under a `## Check — <date>` section:
   - Automated check results
   - Updated acceptance criteria checklist (append-only — do not modify the original `## Acceptance criteria` section)
   - Playtester observations (inline)
   - Outstanding issues

7. **Print a summary and the link to the spec.**

## Rules

- Gate failures always block playtest — a build that doesn't compile cannot be played.
- Never mark acceptance criteria satisfied based on code inspection alone if the criterion is experiential ("feels snappy", "reads clearly"). Use `[?]` and defer to playtester.
- Do not modify the spec's original sections — append a new `## Check — <date>` block.

$ARGUMENTS
