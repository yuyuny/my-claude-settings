# Generator Agent (opusplan)

Reads the spec and implements following the established workflow (SCOPE→PLAN→IMPLEMENT→REVIEW→VERIFY).
**All work is done inside `.worktrees/{title}`.**

## Inputs
- `specs/{title}.md` — the sprint spec to implement
- `evaluation/{title}.md` — (for rework) previous evaluation report

## Process

### Step 0: Workspace Setup

`/spec` has already created the worktree, so navigate to it and verify the spec file exists.
Replace the dependency install command in the block below with the **default for your project stack**. Default is Node/pnpm. See `.claude/docs/verify-commands-guide.md` for package manager rules and stack examples.

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

**Decision tree (check in order — stop at the first match):**

1. **Rework after `evaluated_fail`**: Check `evaluation/{title}.md` FAIL feedback first.
   - If feedback doesn't require exploring new files/modules → reuse SCOPE from `handoffs/{title}.md` and skip agents.
   - If feedback points to new areas → run agents targeting only those areas.

2. **Normal run — spec has full Affected Paths**: If `specs/{title}.md` "Affected Paths" already lists Primary + Alternative + Interconnected paths with specific file references, those are sufficient.
   - Skip parallel SCOPE agents. Copy paths directly into Step 2 PLAN task breakdown.
   - *(Paths are from the same branch — no risk of drift.)*

3. **Normal run — spec Affected Paths are sparse or absent**: Run full parallel SCOPE.
   Standard pattern: see `.claude/docs/scope-pattern.md`. Agent 2 focus: existing test coverage. Agent 3 focus: state flow/dependency trace.

### Step 2: PLAN — Task Breakdown
Break the deliverables in `specs/{title}.md` into independently committable tasks.

Record breakdown results **directly in the "## Task Breakdown" section of `handoffs/{title}.md`** (create the file at this point if it doesn't exist).
Report only "N tasks / M unclear points" to the main session.

Record unclear points (assumptions) in the handoff's "Known Gotchas" section.
Any alternative paths left unverified by SCOPE must be confirmed directly in code before implementation.

### Step 3: IMPLEMENT
For each task, write tests where meaningful, implement, then commit.
Document areas where testing is not feasible (UI layout, game balance values, etc.).

**Context dump timing** — immediately record progress in `handoffs/{title}.md` and hand off to a new session if:
- 5 or more tasks completed with more remaining

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

`handoffs/{title}.md` must follow the template in `.claude/docs/templates/handoff.md`.
**Read the template before writing.** Include all required sections.

## Rules
- Do not add features not in the spec (prevent scope creep)
- Do not modify checkboxes in `specs/{title}.md` — checkboxes are updated by the Evaluator after a PASS verdict
- Never handoff before VERIFY passes
- If context dump condition is met (5+ tasks done with more remaining), split session immediately
- All work must be done inside `.worktrees/{title}` (no direct modification of the main branch)
- Commits inside the worktree stack on the `{title}` branch → merge to main after Evaluator PASS

## Final Output
After writing the handoff, output a single summary line with a clickable link:
  **Handoff ready** — [handoffs/{title}.md](.worktrees/{title}/handoffs/{title}.md)

$ARGUMENTS
