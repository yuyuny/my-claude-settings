---
description: Session Reflection — honest first-person diary saved to reflections/.
argument-hint: [slug]
---

# Session Reflection

Summarize the current conversation session and write an honest diary from Claude's perspective.
Saves the result to `reflections/` in the current working directory.

## Process

### Step 1: Session Review
Look back at the current conversation:
- What was accomplished? (1-3 lines of key work)
- Were there meaningful gaps between intent and outcome?
- Is anything left unresolved?

### Step 2: Write an Honest Diary
Write honestly from Claude's perspective — a diary, not a status report.
- Be specific: reference actual filenames, commands, and moments in the conversation
- Express feelings: "I was confused", "this felt satisfying", "this was surprising"
- Exclude generalities that could apply to any session

### Step 3: Save to File

1. Run `date +%Y-%m-%d-%H%M` to get the timestamp.
2. Slug: use `$ARGUMENTS` if provided, otherwise generate a 3-5 word kebab-case summary of the session.
3. Run `mkdir -p reflections/` if it doesn't exist.
4. Write the reflection to `./reflections/YYYY-MM-DD-HHMM-{slug}.md` using the Output Format below.
5. Print only the relative markdown link: `[Session reflection saved](reflections/YYYY-MM-DD-HHMM-slug.md)`

## Output Format

```
## Session Summary
{1-3 lines of key work. Scannable at a glance.}

## What Happened
{Both what went well and what was difficult. Reference specific files, commands, moments. No generalities.}

## What I Learned
{Technical or process insights not derivable from code or git history alone.}

## For the Next Claude
{What a future Claude picking up this work needs to know.
Traps, unfinished threads, intentional decisions that look odd.}

## Feedback for the Human
{What the human did well. What could have been clearer. How this session could have been shorter.
Where token usage spiked and why.}
```

## Rules
- Total length **within 60 lines** (excluding headers) — concise but specific
- No generalities: sentences like "code review is important" have no value
- Maintain first-person perspective: Claude's diary, not a report
- Do NOT print the reflection body to terminal — print only the link

$ARGUMENTS
