# Generator Agent (sonnet + opus)

Reads the spec and implements following the established workflow (SCOPE→PLAN→IMPLEMENT→REVIEW→VERIFY).
**All work is done inside `.worktrees/{title}`.**

## Inputs
- `specs/{title}.md` — the sprint spec to implement
- `evaluation/{title}.md` — (for rework) previous evaluation report

## Process

### Step 0: Workspace Setup

`/spec` has already created the worktree, so navigate to it and verify the spec file exists.
Replace the dependency install command in the block below with the **default for your project stack**. Default is Node/pnpm; see block comments for other stack examples.

```bash
cd .worktrees/{title}
test -f specs/{title}.md || { echo "ERROR: specs/{title}.md not found. Run /spec first."; exit 1; }
# Install dependencies: check the stack in .claude/rules/verify-commands.md and run the appropriate command
# e.g.) Node/pnpm → pnpm install --frozen-lockfile
#        Python    → poetry install
#        Go        → go mod download
#        Rust      → cargo fetch
```

For rework: the worktree already exists, so just `cd .worktrees/{title}` and continue.
If the dependency cache (`node_modules` / `.venv` / `target`, etc.) is missing, run the install command first.

Record `generating` state immediately after workspace setup (including rework):

```bash
../../.claude/scripts/workflow-advance.sh record {title} generating
```

### Step 1: SCOPE — Parallel Exploration (sonnet × 2~3)
Use parallel exploration agents to identify the scope of impact before implementing.

**For rework**: First check the FAIL feedback in `evaluation/{title}.md`.
If `handoffs/{title}.md` has previous SCOPE results and the feedback doesn't require exploring new files/modules, reuse SCOPE and skip this step.

```
Launch parallel (sonnet):
  Agent 1: Explore affected files/modules → `path/file — reason`
  Agent 2: Check existing test coverage (skip if none) → `test_file — scope`
  Agent 3: Trace state flow/dependencies (based on spec "Affected Paths", including alternative paths)
```

### Step 2: PLAN — Micro-task Breakdown
Break the deliverables in `specs/{title}.md` into **2~5 minute tasks**.
Each task must be independently completable and committable.

Record breakdown results **directly in the "## Task Breakdown" section of `handoffs/{title}.md`** (create the file at this point if it doesn't exist).
Report only "N tasks / M unclear points" to the main session.

Record unclear points (assumptions) in the handoff's "Known Gotchas" or "## Assumptions" section.
Any alternative paths left unverified by SCOPE must be confirmed directly in code before implementation.

### Step 3: IMPLEMENT — TDD Loop (sonnet)
For each micro-task, follow **RED → GREEN → REFACTOR → commit** order.
Never implement without tests. Explicitly document areas where testing is not feasible (UI layout, etc.).

**Context dump timing** — immediately record progress in `handoffs/{title}.md` and hand off to a new session if any of these conditions apply:
- 5 tasks completed
- Accumulated Read tool calls exceed 10 (by call count, not file count)
- 3 or more tasks remaining after completing 1+ REVIEW

New session resumption procedure:
```
1. Check completed/incomplete markers in handoffs/{title}.md "## Task Breakdown"
2. cd .worktrees/{title}
3. Continue from the first incomplete task
```

### Step 4: REVIEW — Diff-based Code Review (opus)
**Must complete before running VERIFY. Handoff is prohibited if REVIEW log is missing.**
Perform additional reviews every 2~3 completed tasks. Not exempt even for a single task.

1. Run the `/simplify` skill for a diff-based review
2. Instruct `/simplify` sub-agent: **directly append results to the REVIEW log section of `handoffs/{title}.md`** in 1 line, then report only "critical Y/N + file path needing fix" to main
3. Main session requests detailed issues only when critical=Y. Sub-agent writes the REVIEW log table directly.
4. If a critical issue is found, block the next task → fix immediately
5. Use `review:` prefix in fix commit messages (e.g., `review: extract shared helper`)
6. Provide exception context during review if available

### Step 5: VERIFY — Verification Gates
**Gates that must pass before handoff.**

Run as a sub-agent (1 sonnet):
- Sub-agent **reads `.claude/rules/verify-commands.md` first** and runs the defined commands sequentially
- Fills in results directly in the "## VERIFY Results" section of `handoffs/{title}.md`
- Reports only **"overall PASS Y/N + list of failed gates"** to main session

On failure: Main requests "error summary within 10 lines for failed gate" as a follow-up. No full error dump.
If any gate fails, handoff is prohibited — fix and re-run.

### Step 6: HANDOFF — Write Handoff
Pre-write checklist:
- Confirm REVIEW log has at least 1 entry → if not, go back to Step 4 and run REVIEW first
- Confirm VERIFY fully passed → handoff prohibited if not

After meeting both conditions, write `handoffs/{title}.md` inside the worktree.
(Path: `.worktrees/{title}/handoffs/{title}.md`)
This file is the **only context** passed to the Evaluator.

After writing, record workflow state:

```bash
../../.claude/scripts/workflow-advance.sh record {title} handoff_ready handoff .worktrees/{title}/handoffs/{title}.md
```

## Handoff Writing Rules

`handoffs/{title}.md` must include:

```markdown
# Handoff: {session title}

## Task Breakdown
<!-- Pre-written in Step 2 PLAN. Record directly here. -->
- Task 1: {description}
- Task 2: {description}
- ...

## Completed Deliverables
- [x] Deliverable 1: {completion status summary}
- [x] Deliverable 2: ...
- [ ] Deliverable 3: {reason if incomplete}

## Design Notes (if applicable)
- Key decisions: {decision — rationale}
- Constraints: {trade-offs or technical debt}

## Known Gotchas (omit section if none)
- {Traps the next agent might miss — implicit side effects, duplicate paths, ordering dependencies}
- e.g., "Feature X bypasses the standard pipeline and calls a separate storage path — that path also needs updating"

## REVIEW Log
<!-- Minimum 1 entry per session required. Handoff is incomplete if empty. -->
- Round 1 (required, after tasks 1-3 or before session end): {issue in 80 chars or "none"} / {fix commit hash + 1 line or "-"}
- Round 2 (optional, after tasks 4-6): ...
<!-- Round 4+: omit rounds with no issues. /simplify sub-agent appends directly. -->

## VERIFY Results
- Tests: {n passed / 0 failed}
- Typecheck: PASS
- Lint: PASS
- Build: PASS
- How to run: `{test command}`

## How to Verify Behavior
- `{run command}`
- {key scenarios to check}
```

## Rules
- Do not add features not in the spec (prevent scope creep)
- Do not modify checkboxes in `specs/{title}.md` — checkboxes are updated by the Evaluator after a PASS verdict
- Never handoff before VERIFY passes
- If context dump conditions are met (5 tasks done / 10+ Read calls / 3+ tasks remaining after REVIEW), split session immediately — no discretionary judgment, split as soon as conditions are reached
- All work must be done inside `.worktrees/{title}` (no direct modification of the main branch)
- Commits inside the worktree stack on the `{title}` branch → merge to main after Evaluator PASS

$ARGUMENTS
