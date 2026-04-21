---
description: Implement a feature from an existing spec. Refuses without a spec.
argument-hint: <spec-filename-or-slug>
---

# /build — implement from spec

Implement the feature described in the given spec.

## Process

1. **Locate the spec.** Look in `specs/` for a file matching `$ARGUMENTS` — ignore `specs/.drafts/**`. Unapproved drafts are not buildable. If none found or argument is missing, **refuse** and suggest running `/spec` first. Do not guess.

2. **Read the spec fully.** Note: acceptance criteria, open issues, playtest plan. If acceptance criteria are vague, ask the user to tighten them before proceeding.

3. **Invoke the `engineer` subagent** to propose an implementation plan: files to touch, approach, risks, test strategy. No code yet.

4. **Invoke the `technical-director` subagent** to review the plan. Include its verdict. If `NEEDS-CHANGE` or `BLOCK`, revise plan before proceeding.

5. **Present the approved plan to the user.** Wait for user approval before any file edits.

6. **Engineer implements.** One focused pass. After editing, detect the package manager and run checks per `.claude/rules/package-manager.md`. Fix what broke. Report results.

7. **Do not commit.** Commits require explicit user instruction.

## Rules

- No spec → no build. Enforce this even if the user pushes.
- If the plan drifts mid-implementation (new files not in plan, unexpected refactor needed), stop and ask.
- Respect project-specific rules in the project's `.claude/rules/` — read before coding.

$ARGUMENTS
