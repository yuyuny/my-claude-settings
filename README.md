# my-claude-settings

A Claude Code project template implementing a multi-agent workflow (Brainstormer → Spec Writer → Generator → Evaluator → Reflector).

## Project Structure

```
.claude/
  commands/
    brainstorm.md      ← /brainstorm (Brainstormer, opus, optional)
    spec.md            ← /spec (Spec Writer, sonnet)
    generate.md        ← /generate (Generator, sonnet)
    evaluate.md        ← /evaluate (Evaluator, opus, separate session)
    reflect.md         ← /reflect (Reflector, sonnet)
    reflect-batch.md   ← /reflect-batch (pattern aggregation, sonnet)
    workflow-status.md ← /workflow-status (status query, read-only)
  rules/
    multi-agent-workflow.md  ← core workflow rules (model assignment, core rules, output contract)
    verify-commands.md       ← verification gate definitions (modify per project)
  docs/
    workflow-reference.md    ← state machine, directory, semi-automation details
  scripts/
    workflow-advance.sh      ← Stop hook + state recorder + merge/cleanup
    workflow-status.py       ← /workflow-status script
.worktrees/            ← per-session git worktrees (.gitignore)
  {title}/             ← e.g., .worktrees/auth-login/
    specs/             ← Spec Writer artifacts
    handoffs/          ← Generator → Evaluator context
    evaluation/        ← Evaluator reports
    reflections/       ← session reflections
brainstorms/           ← /brainstorm artifacts (main branch)
docs/
  GLOSSARY.md          ← domain glossary (used only when entries exist)
evaluation/
  rubric-v1.md         ← evaluation rubric
reflections/
  index.md             ← reflection index + batch aggregation records
```

## Model Assignment

| Agent / Task           | Model  |
|------------------------|--------|
| Brainstormer           | opus   |
| Spec Writer            | sonnet |
| Generator — SCOPE      | sonnet |
| Generator — IMPLEMENT  | sonnet |
| Evaluator              | opus   |
| Reflector              | sonnet |
| Reflect-Batch          | sonnet |

## Usage

### Step 0: (Optional) Brainstorming (opus)

Run this first when requirements are ambiguous.

```bash
claude "/brainstorm {title}"
```

### Step 1: Write Spec (sonnet)

```bash
claude "/spec {title}"
```

### Step 2: Implement (sonnet)

```bash
claude "/generate {title}"
```

Generator works inside `.worktrees/{title}`:

```
SCOPE(sonnet×parallel) → PLAN → IMPLEMENT(TDD) → REVIEW(/simplify) → VERIFY → HANDOFF
```

### Step 3: Evaluate (opus, **must be in a new session**)

```bash
# Run in a new terminal/session — Evaluator independence principle
claude "/evaluate {title}"
```

### Step 4: Reflect + Merge

After a PASS verdict, follow this order:

```bash
# ① Reflect first (needs access to worktree artifacts)
claude "/reflect {title}"

# ② Merge after reflection completes (run from project root)
git checkout main && git merge {title}
git worktree remove .worktrees/{title} && git branch -d {title}
```

> **Warning**: Deleting the worktree before `/reflect` makes artifacts inaccessible.

### Rework (on FAIL)

```bash
# Apply evaluation/{title}.md feedback and rework
claude "/generate {title}"
```

Continues work in the existing `.worktrees/{title}`.

### Check Status

```bash
claude "/workflow-status"
```

---

## Workflow Diagram

```
User request
    │
    ▼
┌─────────────────────┐
│ /brainstorm (opus)  │  brainstorms/{title}.md  [optional]
│ Socratic dialogue   │─────────────────────────────┐
└─────────────────────┘                             │
    │ (or go directly to /spec)                     │
    ▼                                              ▼
┌─────────────────────────────────────────────────────┐
│ /spec (sonnet)                                      │
│ Create worktree: .worktrees/{title}                 │
│ SCOPE → write specs/{title}.md → commit             │
└─────────────────────────────────────────────────────┘
    │
    ▼  [approval gate: spec review]
┌─────────────────────────────────────────────────────┐
│ /generate (sonnet)                                  │
│ Workspace: .worktrees/{title}                       │
│                                                     │
│  SCOPE(sonnet×2~3) → PLAN → IMPLEMENT(TDD)         │
│                              │                      │
│                           REVIEW(/simplify, opus)   │
│                              │                      │
│                           VERIFY ──✗──→ fix         │
│                              │                      │
│                           HANDOFF                   │
└──────────────────────┬──────────────────────────────┘
                       │ handoffs/{title}.md
                       ▼
            ┌──────────────────────────────┐
            │ /evaluate (opus, new session!)│
            │ Validate at: .worktrees/{title}│
            │                              │
            │ VERIFY re-validation         │
            │ Code validation              │
            │ Behavior validation          │
            │ Scoring + verdict            │
            └──────────┬───────────────────┘
                       │
             ┌─────────┴─────────┐
             │                   │
           PASS               FAIL
             │                   │
    [approval gate]       evaluation/{title}.md
             │                   │
      ① /reflect            /generate rework
      ② git merge           (existing worktree preserved)
      ③ worktree cleanup
             │
      /reflect-batch
      (when 5+ accumulated)
```

---

## Semi-automation (Stop Hook)

After each command completes, the Stop hook automatically:
- **Copies the next command to clipboard** (macOS)
- **Sends a desktop notification** (macOS)
- **Injects a guidance message into the Claude session**

**3 approval gates** requiring human intervention:

| State | Reason |
|------|------|
| `spec_ready` | Review before finalizing spec |
| `evaluated_pass` | Confirm merge |
| `evaluated_fail` | Decide: rework / redefine spec / abandon |

---

## Integration Summary with Existing Rules

| Existing rule | Location in harness |
|-----------|----------------|
| SCOPE (parallel exploration) | /brainstorm Step 2 + /spec Step 2 + /generate Step 1 |
| PLAN | specs/{title}.md + handoffs/{title}.md |
| IMPLEMENT (TDD) | /generate Step 3 |
| REVIEW (/simplify) | /generate Step 4 |
| VERIFY (test+typecheck+lint) | /generate Step 5 + /evaluate Step 2 (re-validation) |
| HANDOFF | /generate Step 6 |
| REFLECT | /reflect command (after cycle ends) |

---

## Quick Setup

1. Copy this repository into your project
2. Modify the **Current Project Gates** section in `.claude/rules/verify-commands.md` to match your stack
3. Add required permissions (pnpm, python3, etc.) in `.claude/settings.local.json`
4. Review `evaluation/rubric-v1.md` for your project type (UI/CLI/library)
5. Verify the `"model"` setting in `.claude/settings.json` (default: `opusplan`)
