---
description: Verify a built feature against spec — automated checks + playtester observations.
argument-hint: <spec-filename-or-slug>
---

# /check — verify against spec

Run the full verification pass on a feature.

## Process

1. **Locate the spec.** Look in `specs/` only — ignore `specs/.drafts/**`. Refuse if no approved spec is found.

2. **Run automated checks** per `.claude/rules/package-manager.md` (also check `lint:css` if present). Collect pass/fail per check.

3. **If any automated check fails:** stop here. Append a `## Check — <date>` block with the failure details, then prompt the user: "Fix the failing gates, then re-run `/check`." Do **not** proceed to steps 4–5.

4. **Verify acceptance criteria in place.** (Only reached if all gates green.) For each checkbox in the spec's `## Acceptance criteria` section, update it directly:
   - `[x]` if demonstrably satisfied (tests, or observable behavior in code)
   - `[ ]` if unsatisfied
   - `[?]` if cannot be determined without running the game

   History is tracked by git — the commit diff records what changed and when.

5. **Invoke the `playtester` subagent** with the spec's `Playtest plan` and a brief description of the built feature. If a live play report or screenshot is available, include it; otherwise the playtester will ask for one.

6. **Append results to the spec file** under a `## Check — <date>` section:
   - Automated check results
   - Playtester observations (inline)
   - Outstanding issues

   Do **not** copy the acceptance criteria checklist into this block — the original section is already up to date.

7. **Print a summary and the link to the spec.**

## Rules

- Gate failures always block playtest — a build that doesn't compile cannot be played.
- Never mark acceptance criteria satisfied based on code inspection alone if the criterion is experiential ("feels snappy", "reads clearly"). Use `[?]` and defer to playtester.
- AC checkboxes are updated in the original `## Acceptance criteria` section. The `## Check — <date>` block contains automated gate results, playtester observations, and outstanding issues only.
- `specs/.drafts/**` is not a valid check target. Only approved specs in `specs/` are checked.

$ARGUMENTS
