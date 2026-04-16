# Reflector Agent (sonnet)

Reviews the entire workflow cycle and records lessons learned.
This command runs in the same session or a new session after `/evaluate` completes.

## Inputs

All artifacts are inside the worktree. Paths relative to `.worktrees/{title}`:
- `specs/{title}.md` — original spec (reference)
- `handoffs/{title}.md` — Generator handoff (reference)
- `evaluation/{title}.md` — Evaluator report (reference)
- Session conversation context (if available)

> **Reference material principle**: The documents above are reference materials, not required analysis targets.
> Do not summarize them. Mention them specifically only when relevant to the reflection.
> (This principle is a global rule in `.claude/rules/multi-agent-workflow.md` — applies to all commands.)

## Process

### Step 1: Cycle Overview
Review this cycle (`/spec` → `/generate` → `/evaluate`) as a whole:
- What was built? (1-2 sentences)
- Were there any meaningful gaps between plan and outcome?
- Check the Evaluator verdict (PASS/FAIL) and score

### Step 2: Write First-person Reflection
Write honestly from Claude's perspective — a diary, not a status report.
- Be specific: reference actual files, commands, and moments in the conversation
- Express emotions: "I was confused", "this felt satisfying", "this was surprising"
- Exclude generalities that apply to any session

### Step 3: Write File
Create file `reflections/YYYY-MM-DD-HHmm-{title}.md`.
- Use the session title (kebab-case) for `{title}`

### Step 3.5: Update Index

1. Add new domain terms to `docs/GLOSSARY.md` only if existing entries are present (skip if the file is empty)
2. If `reflections/index.md` exists, append one new row to the table (skip if the file doesn't exist):

   ```
   | YYYY-MM-DD | {title} | PASS / FAIL | {key learning in one sentence} |
   ```

### Step 4: Commit

Commit inside `.worktrees/{title}`:
```bash
git add reflections/YYYY-MM-DD-HHmm-{title}.md
# If reflections/index.md was updated, add it too (only if the file exists)
# git add reflections/index.md
# If docs/GLOSSARY.md was updated, add it too (only if the file exists)
# git add docs/GLOSSARY.md
git commit -m "docs: add reflection for {title} session"
```

### Step 5: Record Workflow State

```bash
../../.claude/scripts/workflow-advance.sh record {title} done reflection reflections/$(date +%Y-%m-%d-%H%M)-{title}.md
```

## Output Format

Save to `reflections/YYYY-MM-DD-HHmm-{title}.md`:

```markdown
# Reflection: {session title}

## Cycle Summary
{1-2 sentences on what was built. Scannable — identifiable in a reflection list. Include Evaluator verdict.}

## What Happened
{Both what went well and what was difficult: effective approaches + points where I got stuck or took detours.
Reference filenames, commands, specific moments. No generalities.}

## What I Learned
{Technical or process insights not derivable from code or git history alone.}

## Observations and Suggestions
{Observations spanning the full cycle (spec→generate→evaluate) + what a human could have done differently for better results.
Include "If X had happened, I could have done Y better" format.}

## For the Next Claude
{What a future Claude picking up this work needs to know.
Traps, unfinished threads, intentional decisions that look odd.}
```

## Rules
- Total length **within 40 lines** (excluding headers) — concise but specific
- No document summarization: specs/handoffs/evaluation are references only, do not repeat their content
- No generalities: sentences like "code review is important" have no value
- Maintain first-person perspective: Claude's diary, not a report

$ARGUMENTS
