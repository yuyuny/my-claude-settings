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

  ```
  Launch parallel (sonnet):
    1. Explore related files/module structure → `path/file — reason`
    2. Check existing patterns/conventions   → `path/file — which pattern`
    3. Analyze dependencies/impact scope     → `path/file — impact direction`
  ```

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

```markdown
# Spec: {session title}

## Goal

{1-2 sentence summary}

## Deliverables

- [ ] Deliverable 1: {described from the user's perspective}
- [ ] Deliverable 2: ...

## Acceptance Criteria (shared with Evaluator)

1. {concrete, verifiable condition}
2. {e.g., "Response within 1 frame after player input"}
3. {e.g., "Error handling exists at all entry points"}

## Verification Criteria (VERIFY)

> Based on the gates defined in `.claude/rules/verify-commands.md`.

- [ ] {gate 1 — e.g., all tests pass}
- [ ] {gate 2 — e.g., build passes}
- [ ] {include only applicable gates}

## Affected Paths

- Primary path: {the standard execution path for the feature. e.g., main entry function → core handler → repository}
- Alternative paths: {non-primary paths yielding the same result — bypasses or special branches. e.g., a shortcut that skips the standard pipeline under certain conditions}
- Interconnected systems: {side systems that must also be updated. e.g., logging/analytics, i18n (if any), docs, external catalogs}

## Technical Constraints

- {stack, compatibility, performance requirements, etc.}

## Non-functional Requirements

- {accessibility, security, performance thresholds, etc.}

## Dependencies

- Preceding session: {none or previous session title}
```

## Rules

- 3~7 deliverables per sprint
- No subjective language in acceptance criteria ("good UX" ✗ → "feedback within 1 second of button click" ✓)
- If a previous session's `evaluation/{title}.md` exists, it must be reflected
- Scope expansion proposals allowed: if there are additional features aligned with user goals, propose including them in deliverables, but do not add to the final spec without user approval
- **Affected paths required**: List alternative execution paths for each major deliverable (missing this risks FAIL at implementation stage)
- Add new domain terms to `docs/GLOSSARY.md` only if existing entries are present (skip if the file is empty)

$ARGUMENTS
