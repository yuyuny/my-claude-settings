---
description: Draft a feature spec. Invokes the designer and gates with creative-director.
argument-hint: <feature-name>
---

# /spec — draft a feature spec

Draft a spec for a feature, saved under `specs/YYYY-MM-DD-<slug>.md`.

## Process

1. **Ask clarifying questions only if load-bearing.** Don't interrogate over small details — those go in `Open issues`.

2. **Confirm slug.** Extract a kebab-case slug from `$ARGUMENTS`. Draft path: `specs/.drafts/<slug>.md`. Create `specs/.drafts/` if it doesn't exist.

3. **Invoke the `designer` subagent** with the slug and draft path. Designer saves the draft directly to `specs/.drafts/<slug>.md` and returns a ≤10-line summary only (feature name, one-line decision, AC count, open issues count, draft link). Do not re-output the draft body.

4. **Invoke the `creative-director` subagent** passing the draft file path. Creative-director returns verdict text only (no write access).

5. **Prepend the verdict block** to the draft file using the Edit tool:
   - `ALIGNED` or `AMPLIFY` → wrap in HTML comment (`<!-- verdict ... -->`).
   - `TENSION` or `OFF-PILLAR` → prepend as a visible callout block.
   - Always include any aesthetic proposals the creative-director offers, regardless of verdict.

6. **Print the summary and the link to the draft file.** Do not output the full draft body.

7. **On user approval**:
   - Run `date +%Y-%m-%d` for the date prefix.
   - Final path: `specs/YYYY-MM-DD-<slug>.md`. Create `specs/` if missing.
   - Run `mv specs/.drafts/<slug>.md specs/YYYY-MM-DD-<slug>.md`.
   - Print only the link to the final file.

8. **On revision request**: re-invoke the `designer` subagent with the draft file path and the user's feedback. Designer edits the draft file and returns a ≤5-line change summary. Print the summary only. Repeat until approved or abandoned.

9. **On abandon**: delete `specs/.drafts/<slug>.md` and stop.

## Rules

- Never move a draft from `specs/.drafts/` to `specs/` without explicit user approval.
- Never re-output the full draft body in the main session — the user reads the file directly.
- If `docs/pillars.md` does not exist, the creative-director will flag this — surface that flag and offer to draft pillars first.
- One spec = one decision. If the draft grows multi-headed, propose splitting.

$ARGUMENTS
