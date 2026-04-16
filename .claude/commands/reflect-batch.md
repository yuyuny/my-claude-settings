# Reflect-Batch Agent (opusplan)

Aggregates accumulated `reflections/` files to identify recurring patterns and improve workflow rules.

## When to Run

- When **5 or more** new reflection files have accumulated (since the last batch aggregation)
- After a project milestone (stage completion, release, etc.)
- When a person directly invokes `/reflect-batch`

## Inputs

- `reflections/index.md` — check the last batch aggregation date
- `reflections/*.md` — new files since the last aggregation
- `.claude/rules/*.md` — current workflow rules
- `docs/GLOSSARY.md` — current glossary

## Process

### Step 1: Identify Unprocessed Files

Check the "Last batch aggregation" date in `reflections/index.md`.
Collect the list of reflection files after that date.

```bash
ls reflections/ | grep -v index.md | sort
```

### Step 2: Extract Patterns (parallel)

Read unprocessed files and extract the following sections from each.

**Output contract**: Follow the sub-agent output contract in `.claude/rules/multi-agent-workflow.md`.

```
Launch parallel (sonnet × 2):
  Agent 1: Aggregate "difficulties" sections
           → Return: | Topic | Count | Source file | table
  Agent 2: Aggregate "process observations" + "for the next Claude" sections
           → Return: | Topic | Count | Source file | table
```

These tables must be returned in this format so Step 3 can directly use them for pattern detection without further processing by main.

### Step 3: Identify Recurring Patterns

Find topics that appear **3 or more times** in the aggregation results.

Example recurring patterns:
- "Missing alternative code path" → strengthen `generate.md` SCOPE (already applied)
- "API signature not documented in handoff" → add item to handoff template
- "Lint rule X frequently violated" → document in `rules/coding-style.md`

### Step 4: Propose and Apply Rule Updates

For each recurring pattern:

1. **Identify the relevant rules/ file**: Which rule file needs modification?
2. **Write the change**: What specific lines to add/modify?
3. **Apply**: Directly modify the rule file
4. **If a new rule is needed**: Create `.claude/rules/{topic}.md`

Patterns appearing fewer than 3 times are only recorded in the "Recurring Pattern Notes" section of `reflections/index.md`.

### Step 5: Update Index

Update the "Last batch aggregation" date in `reflections/index.md` to today.
Add a summary of this aggregation to the "Recurring Pattern Notes" section:

```markdown
### YYYY-MM-DD Batch Aggregation

Processed files: N (YYYY-MM-DD ~ YYYY-MM-DD)

**Recurring patterns (3+ occurrences → rule applied)**
- {pattern}: {rules/ file applied}

**Weak signals (under 3 occurrences → monitoring)**
- {pattern}: {N occurrences}
```

### Step 6: Commit

```bash
git add reflections/index.md .claude/rules/ docs/GLOSSARY.md
git commit -m "docs: reflect-batch — {key pattern summary}"
```

## Rules

- No speculative rule additions — must have evidence from at least 3 reflection files before applying
- No full rewrites of existing rules/ files — only add/modify specific items
- **Before modifying rule files**: Show the change (in diff form) to the user and get approval
- Approval not required for: adding clearly missing items (e.g., frequently omitted SCOPE checklist items)
- Approval required for: changes that conflict with existing rules or alter the workflow structure

$ARGUMENTS
