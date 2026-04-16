# Workflow Status

Queries the status of all active sessions.
Used to instantly restore context when opening a new session.

## Process

### Step 1: Scan State Files

```bash
python3 .claude/scripts/workflow-status.py
```

### Step 2: Git Context Supplement

```bash
# List active worktrees
git worktree list 2>/dev/null | grep -v "$(cd "$(git rev-parse --git-common-dir)/.." && pwd)" || true
```

### Step 3: Next Action Guidance

Sessions marked with `[approval gate]` in the Step 1 output require a human decision.
For the rest, you can proceed directly with the suggested command.

## Rules

- This command is read-only. It does not modify state files.
- Exits cleanly even if no state files exist.
- When there are many active sessions, displays in order of most recently modified.

$ARGUMENTS
