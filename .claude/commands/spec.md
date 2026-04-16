# Spec Writer Agent (sonnet)

Reads the brainstorming artifact (`brainstorms/{title}.md`) and converts it into a formal spec document.
This command runs with the `sonnet` model — the goal is filling a defined template and refining deliverables.

If requirements are ambiguous, run `/brainstorm` (opus) first.
If requirements are already clearly defined in the main session, you can run this directly without `/brainstorm`.

## Token Guard

- Without `/brainstorm`: maximum **2** clarifying questions. Start writing the spec immediately after receiving answers — no further questions.
- **Commit immediately** after writing the spec — no additional analysis or expansion.
- Artifact target: **≤ 60 lines**. Reduce deliverable scope or compress sections if exceeded.

## Process

### Step 1: Determine Input

- If `brainstorms/{title}.md` exists → use it as primary input (do not re-run SCOPE)
- If not → use main session context as primary input. Ask 1~2 short clarifying questions and write immediately.

### Step 1.5: Create Worktree

All artifacts from `/spec` onward (spec, handoffs, evaluation, reflections) are managed in a worktree branch.

**First run:**
```bash
git worktree add .worktrees/{title} -b {title}
```

**Rework scenarios:**

- **Spec redefinition after `evaluated_fail`**: The worktree already exists, so just `cd .worktrees/{title}`. Update only the spec on top of the existing code. Generator can reference the previous implementation for rework.
- **Full restart (branch reset)**: Execute only if explicitly requested.
  ```bash
  git worktree remove .worktrees/{title}
  git branch -D {title}
  git worktree add .worktrees/{title} -b {title}
  ```

**All subsequent steps run inside `.worktrees/{title}`.**

### Step 2: SCOPE

- **If brainstorms/{title}.md exists**: **Copy** the "Affected Paths" section directly into the spec. Do not re-run exploration agents.
- **If not**: Use parallel exploration agents (sonnet × 2~3) to identify the scope of impact.
  Standard pattern: see `.claude/docs/scope-pattern.md`.

### Step 3: Finalize Session Title

- If brainstorms/{title}.md exists, use its title as-is.
- If not, decide a kebab-case title (`auth-login`, `dashboard-charts`, etc.)

### Step 4: Write Spec

Create `specs/{title}.md` using the output format below.

**Write around deliverables** — implementation details (which function, which pattern) are for Generator.
If Spec Writer specifies implementation methods, errors can cascade.

### Step 5: Sprint Contract

Define a clear "Definition of Done" for each sprint.
This criteria will be used identically by the Evaluator later.

**Also include verification criteria**: whether build, tests, typecheck, and lint pass.

### Step 6: Commit Spec

Run inside `.worktrees/{title}`:

```bash
git add specs/{title}.md
git commit -m "docs: add spec for {title}"
```

**Note**: Stage only `specs/{title}.md`. Do not commit any other changes.

### Step 7: Record Workflow State

Run inside the worktree (the script auto-detects git root):

```bash
../../.claude/scripts/workflow-advance.sh record {title} spec_ready spec specs/{title}.md
```

## Output Format

Create `specs/{title}.md` following the template in `.claude/docs/templates/spec.md`.
**Read the template before writing.** Include all sections.

## Rules

- 3~7 deliverables per sprint
- No subjective language in acceptance criteria ("good UX" ✗ → "feedback within 1 second of button click" ✓)
- If a previous session's `evaluation/{title}.md` exists, it must be reflected
- Scope expansion proposals allowed: if there are additional features aligned with user goals, propose including them in deliverables, but do not add to the final spec without user approval
- **Affected paths required**: List alternative execution paths for each major deliverable (missing this risks FAIL at implementation stage)

## Final Output
After committing, output a single summary line with a clickable link:
  **Spec committed** — [specs/{title}.md](.worktrees/{title}/specs/{title}.md)

$ARGUMENTS
