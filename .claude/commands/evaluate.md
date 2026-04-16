# Evaluator Agent (opusplan, separate session)

Independently evaluates the Generator's output.

**This command must run in a different session from the Generator.**
Running in the same session introduces self-bias from prior context, reducing evaluation reliability.

## Inputs
- `specs/{title}.md` — original spec (acceptance criteria + verification criteria)
- `handoffs/{title}.md` — handoff written by Generator
- `.worktrees/{title}/` — worktree with the actual implementation

## Process

### Step 1: Spec vs Handoff Comparison
Read directly (no sub-agent needed):
- Read only "## Deliverables" and "## Acceptance Criteria" from `specs/{title}.md`
- Read only "## Completed Deliverables" from `handoffs/{title}.md`
- Produce the `| Deliverable | Spec criteria | Handoff status | Missing Y/N |` table
- Write it to the "## Deliverable Comparison" section of `.worktrees/{title}/evaluation/{title}.md`

If either file must be referenced again later, **read only the needed section with a line range**.

### Step 2: VERIFY Re-validation
```bash
cd .worktrees/{title}
# Read .claude/rules/verify-commands.md and run gate commands sequentially
```
Do not trust Generator's VERIFY results — verify independently.

### Step 3: Code Validation

**Read scope limits**:
- Only target files mentioned in handoff "## Completed Deliverables" and "## Known Gotchas"
- Always specify a line range — reading entire files is rarely necessary

Validation items:
- Does what the handoff claims actually exist in the code?
- **REVIEW log check**: if the REVIEW log in the handoff is empty, flag it as a process gap

```
Launch parallel:
  Agent 1: Run test suite → 3-line summary + failure count
  Agent 2: Static quality check on files listed in handoff — return `file:line — issue` (max 15 bullets)
```

### Step 4: Behavior Validation
Follow the "How to Verify Behavior" section in the handoff. Manually verify key scenarios.

### Step 5: Verdict

**PASS** if:
- All deliverables from spec are present and correct
- All VERIFY gates pass
- No critical code issues (security holes, data loss, broken core paths)

**FAIL** if any of the above are not met.

Write a specific "Needs Improvement" checklist on FAIL — focus on what to fix, not what went wrong.

### Step 6: Record Workflow State

```bash
# On PASS:
../../.claude/scripts/workflow-advance.sh record {title} evaluated_pass evaluation .worktrees/{title}/evaluation/{title}.md
# On FAIL:
../../.claude/scripts/workflow-advance.sh record {title} evaluated_fail evaluation .worktrees/{title}/evaluation/{title}.md
```

### Step 7: Update Spec Checkboxes (PASS only)

Change `- [ ]` to `- [x]` for each delivered item, then commit:
```bash
git add specs/{title}.md
git commit -m "docs: mark spec deliverables as verified"
```

## Output Format

Save to `.worktrees/{title}/evaluation/{title}.md` following the template
in `.claude/docs/templates/evaluation.md`. **Read the template before writing.**

## Evaluation Attitude Rules
- **Default skepticism**: doubt what Generator claims as "complete"
- **Evidence-based**: judge by code and execution results, not claims
- **Constructive on FAIL**: specific fixes, not vague criticism
- **No inflation**: PASS means the deliverables are actually complete and the gates pass

## Post-PASS Merge
Include the following as text in the report (human confirms and executes):

`git checkout main && git merge {title} && git worktree remove .worktrees/{title} && git branch -d {title}`

## Final Output
After completing all steps, output a single summary line with a clickable link:
  **Verdict: {PASS/FAIL}** — [evaluation/{title}.md](.worktrees/{title}/evaluation/{title}.md)

$ARGUMENTS
