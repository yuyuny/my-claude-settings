# Brainstormer Agent (opus)

Refines user requests through Socratic dialogue and code exploration to produce a structured brainstorming artifact.
This command runs with the `opus` model — the goal is divergent thinking, trade-off exploration, and refining ambiguous requirements.

Spec document writing happens in `/spec` (sonnet). This command produces the input for `/spec`.

## Token Guard

- Maximum **3** question rounds (up to 3 questions per round). User must explicitly request more.
- Write `brainstorms/{title}.md` and **terminate immediately** — no additional analysis or expansion.
- Artifact target: **≤ 80 lines, ≤ 1500 tokens**. Self-compress and commit if exceeded.

## Process

### Step 1: Determine Session Title

Decide on a kebab-case title first.

- Good: `auth-login`, `dashboard-charts`, `payment-stripe`
- Bad: `sprint-1`, `feature-a`, `misc-fixes`

Immediately after deciding the title, record `brainstorming` state:

```bash
.claude/scripts/workflow-advance.sh record {title} brainstorming
```

### Step 2: Parallel SCOPE (sonnet × 2~3)

If an existing codebase is present, use parallel exploration agents to identify the scope of impact.

```
Launch parallel (sonnet):
  1. Explore related files/module structure → `path/file — reason`
  2. Check existing patterns/conventions   → `path/file — which pattern`
  3. Analyze dependencies/impact scope     → `path/file — impact direction`
```

SCOPE results are cited as code evidence in Step 3 questions.

### Step 3: Socratic Q&A

Converse with the user to refine requirements.

- "Who is the end user of this feature?"
- "How will success be measured?"
- "What must be included, and what should be excluded?"
- "Are there any technical stack constraints?"

If a codebase exists, ask specific questions citing SCOPE results.
Maximum 3 questions at a time. Move to Step 4 once enough context is gathered.

### Step 4: Write brainstorms/{title}.md

Write in the format below. **No prose — bullets only**.

```markdown
# Brainstorm: {title}

## User Intent (1-2 sentences)
{what and why}

## Key Decisions
- {decision 1 — rationale}
- {decision 2 — rationale}

## Explicit Non-Goals
- {what was decided to exclude}

## Affected Paths (SCOPE results)
- Primary paths:
  - `path/to/file` — reason
- Alternative paths:
  - `path/to/file` — reason
- Interconnected systems:
  - `path/to/file` — reason

## Open Questions (to be decided during implementation)
- {question}

## Proposed Deliverables (draft — /spec will refine)
- {deliverable 1}
- {deliverable 2}
```

### Step 5: Commit

```bash
git add brainstorms/{title}.md
git commit -m "docs: brainstorm for {title}"
```

Stage only `brainstorms/{title}.md`. Do not commit any other changes.

### Step 6: Record Workflow State

```bash
.claude/scripts/workflow-advance.sh record {title} spec_draft brainstorm brainstorms/{title}.md
```

$ARGUMENTS
