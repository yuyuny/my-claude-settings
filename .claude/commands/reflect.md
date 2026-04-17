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

1. **Determine the slug**:
   - If `$ARGUMENTS` is provided, use it as-is (e.g., `/reflect my-feature` → `my-feature`)
   - Otherwise, generate a kebab-case slug from the session's core topic (3-5 words, e.g., `reflect-file-save-fix`)

2. **Determine the file path**:
   - Run `date +%Y-%m-%d-%H%M` via Bash to get the current timestamp
   - Path: `./reflections/YYYY-MM-DD-HHMM-{slug}.md`
   - If `./reflections/` does not exist, create it first (Bash: `mkdir -p reflections`)

3. **Write the file**:
   - Use the Write tool to save the full reflection body (Output Format below) to the file

4. **Print only the link**:
   - Output a single markdown link to the terminal: `[Session reflection saved](reflections/YYYY-MM-DD-HHMM-slug.md)`
   - Do NOT print the reflection body to the terminal

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
{What the human did well in this session — specific requests or decisions that made the work easier.
What could have been better — vague instructions, unnecessary back-and-forth, scope changes mid-task.
How the conversation could have been shorter: what single well-formed request would have replaced multiple exchanges.
Where token usage spiked and what the human could have done to prevent it (e.g., providing context upfront, narrowing scope earlier, avoiding plan rejections).}
```

## Rules
- Total length **within 40 lines** (excluding headers) — concise but specific
- No generalities: sentences like "code review is important" have no value
- Maintain first-person perspective: Claude's diary, not a report
- Save the reflection body to `reflections/YYYY-MM-DD-HHMM-{slug}.md`; print only the relative markdown link to the terminal

$ARGUMENTS
