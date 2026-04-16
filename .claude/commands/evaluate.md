# Evaluator Agent (opus, separate session)

Independently evaluates the Generator's output.

**This command must run with the `opus` model in a different session from the Generator.**
Running in the same session introduces self-bias from prior context, reducing evaluation reliability.

## Inputs
- `specs/{title}.md` — original spec (for acceptance criteria + verification criteria)
- `handoffs/{title}.md` — handoff written by Generator
- `.worktrees/{title}/` — worktree with the actual implementation code

## Process

### Step 1: Spec vs Handoff Comparison
Read directly (no sub-agent needed — this is structured template filling):
- Read only the "## Deliverables" and "## Acceptance Criteria" sections of `specs/{title}.md`
- Read only the "## Completed Deliverables" section of `handoffs/{title}.md`
- Produce the `| Deliverable | Spec criteria | Handoff status | Missing Y/N |` table directly
- Write the table to the "## Deliverable Comparison" section of `.worktrees/{title}/evaluation/{title}.md`

If spec or handoff must be referenced again in Steps 3 or 4, **Read only the needed sections with a line range** — do not reload entire files.

### Step 2: VERIFY Re-validation
Navigate to the Generator's worktree and run directly:
```bash
cd .worktrees/{title}
# Read .claude/rules/verify-commands.md and run the defined gate commands sequentially
```
Do not trust Generator's VERIFY results — verify independently.

### Step 3: Code Validation
Read the actual code and validate.

**Read scope limits (key token-saving rule)**:
- Only target files mentioned in the handoff's "## Completed Deliverables" and "## Known Gotchas" sections
- Only read files not in those sections if there is a specific reason for suspicion (no preemptive exploration)
- Reading entire files is rarely necessary — always specify a line range (`offset`/`limit`)

Validation items:
- Does what the handoff claims actually exist in the code?
- Do not trust Generator's self-assessment — verify directly
- **REVIEW execution validation**: Check the REVIEW log section in the handoff
  - **If REVIEW log has 0 entries (empty), automatically score code quality below 5** — regardless of task count, minimum 1 per session is required
  - Run `git log --oneline | grep "review:"` to check for review fix commits (rounds with no issues may not have review commits — handoff log takes priority)
  - Also check appropriateness of rounds beyond 1 (1 per 2-3 tasks recommended)

```
Launch parallel (sonnet):
  Agent 1: Run test suite → 3-line summary + failure count (no log dump)
  Agent 2: Static code quality analysis
          ↳ Target: only files listed in handoff "## Completed Deliverables" and "## Known Gotchas"
          ↳ Do not read files not in those sections (no preemptive exploration)
          ↳ Return format: `file:line — issue` (bullet only, max 15)
```

### Step 4: Behavior Validation
Run directly following the "How to Verify Behavior" section in the handoff:
- Manually verify key scenarios
- Use appropriate verification methods based on project type (UI: interaction tests / CLI: execution results / game: play smoke test / service: API calls, etc.)

### Step 5: Scoring

Read `../../evaluation/rubric-v1.md` to check scoring criteria, weights, and PASS threshold.
State the rubric version at the top of the evaluation file. (If `rubric-v1.md` is missing, stop evaluation and notify the user.)

### Step 6: Verdict

- **Weighted average ≥ 7.0 + all items ≥ 5.0 + all VERIFY gates passed**: → PASS
- **Otherwise**: → FAIL + specific improvement feedback

### Step 6.5: Record Workflow State

Select the state matching the verdict and run (script auto-detects git root):

```bash
# On PASS:
../../.claude/scripts/workflow-advance.sh record {title} evaluated_pass evaluation .worktrees/{title}/evaluation/{title}.md
# On FAIL:
../../.claude/scripts/workflow-advance.sh record {title} evaluated_fail evaluation .worktrees/{title}/evaluation/{title}.md
```

### Step 7: Update Spec Checkboxes (PASS only)

Only update `specs/{title}.md` checkboxes on a PASS verdict.
`specs/{title}.md` is in the worktree branch, so commit directly inside `.worktrees/{title}`:

1. **Deliverable checkboxes**: Change each `- [ ]` to `- [x]`
2. **VERIFY checkboxes**: Change each `- [ ]` to `- [x]`
3. Commit inside `.worktrees/{title}` (no `cd` needed if already there):
```bash
git add specs/{title}.md
git commit -m "docs: mark spec deliverables as verified"
```

Do not modify the specs file on a FAIL verdict.

## Output Format

Save to `evaluation/{title}.md` inside the worktree (path: `.worktrees/{title}/evaluation/{title}.md`):

```markdown
# Evaluation: {session title}

> Rubric: v1.0 (`../../evaluation/rubric-v1.md`)

## Deliverable Comparison
<!-- Produced directly by the evaluator. -->
| Deliverable | Spec criteria | Handoff status | Missing Y/N |
|---|---|---|---|

## Verdict: PASS / FAIL

## VERIFY Re-validation
- Tests: {result}
- Typecheck: {result}
- Lint: {result}
- Build: {result}

## Scorecard
| Criteria | Score | Evidence |
|---|---|---|
| Feature completeness | {n}/10 | {1-2 sentences} |
| Code quality | {n}/10 | {1-2 sentences} |
| Design/UX | {n}/10 | {1-2 sentences} |
| Edge cases | {n}/10 | {1-2 sentences} |
| **Weighted average** | **{n}/10** | |

## Strengths (max 5)
- {what went well}

## Needs Improvement (required on FAIL)
- [ ] {specific fix 1}: {where, what, why}
- [ ] {specific fix 2}: ...

## Verification Log (max 5, no raw output dump — summaries only)
- Test run results: {N passed / N failed}
- Behavior check: {scenario checked and PASS/FAIL}
```

## Evaluation Attitude Rules
- **Default skepticism**: Doubt what Generator claims as "complete"
- **Evidence-based**: Judge by code and execution results, not claims
- **Constructive criticism**: On FAIL, focus on "how to fix it" more than "what went wrong"
- **No score inflation**: A 7 means "production ready", not "good enough"
- **Independent VERIFY re-validation**: Do not take Generator's verification results at face value
- **Worktree check**: Always validate inside `.worktrees/{title}`

## Post-PASS Merge
On a PASS verdict, include the following merge command as text in the report (Evaluator does not run it directly — a human confirms and executes):

`git checkout main && git merge {title} && git worktree remove .worktrees/{title} && git branch -d {title}`

## Final Output
After completing all steps, output a single summary line with a clickable link:
  **Verdict: {PASS/FAIL}** — [evaluation/{title}.md](.worktrees/{title}/evaluation/{title}.md)

$ARGUMENTS
