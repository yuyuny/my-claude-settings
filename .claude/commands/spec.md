---
description: Draft a feature spec. Invokes the designer and gates with creative-director.
argument-hint: <feature-name>
---

# /spec — draft a feature spec

Draft a spec for a feature, saved under `specs/YYYY-MM-DD-<slug>.md`.

## Process

1. **Ask clarifying questions only if load-bearing.** Don't interrogate over small details — those go in `Open issues`.

2. **Invoke the `designer` subagent** to draft the spec using the skeleton in its definition. The draft covers Problem, Options, Decision, Acceptance criteria, Playtest plan, Open issues.

3. **Invoke the `creative-director` subagent** on the draft for pillar-alignment review. Include its verdict block at the top of the spec (commented out if ALIGNED, visible if TENSION).

4. **Present the full draft to the user.** Do not save yet.

5. **On user approval**:
   - Run `date +%Y-%m-%d` for the date prefix.
   - Slug: kebab-case from `$ARGUMENTS`, or inferred from the draft title.
   - Save to `specs/YYYY-MM-DD-<slug>.md`. Create `specs/` if missing.
   - Print only the link to the saved file.

6. **If the user requests changes**: revise the draft, re-present. Loop until approved or abandoned.

## Rules

- Never save without explicit user approval.
- If `docs/pillars.md` does not exist, the creative-director will flag this — surface that flag and offer to draft pillars first.
- One spec = one decision. If the draft grows multi-headed, propose splitting.

$ARGUMENTS
