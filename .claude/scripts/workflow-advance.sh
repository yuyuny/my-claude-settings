#!/usr/bin/env bash
# workflow-advance.sh — Stop hook + state recorder for multi-agent workflow
#
# Usage:
#   ./workflow-advance.sh                                    # Stop hook mode
#   ./workflow-advance.sh record <title> <state> [key] [val] # Record state transition
#   ./workflow-advance.sh merge <title>                      # Merge worktree into main
#   ./workflow-advance.sh cleanup <title>                    # Remove worktree + branch
#
# Stop hook reads CLAUDE_WORKFLOW_TITLE env var (or falls back to most recent non-done file).

set -euo pipefail

command -v python3 &>/dev/null || { echo "[workflow] ERROR: python3 is required but not found in PATH"; exit 1; }

# Resolve main repo root (works from worktrees too)
get_main_root() {
  local git_common_dir
  git_common_dir="$(git rev-parse --git-common-dir 2>/dev/null)" || { echo "."; return; }
  (cd "$git_common_dir/.." && pwd)
}

WORKFLOW_REL=".claude-workflow/sessions"

# ── merge subcommand ─────────────────────────────────────────────────────────
if [[ "${1:-}" == "merge" ]]; then
  TITLE="$2"
  ROOT="$(get_main_root)"
  cd "$ROOT"
  CURRENT=$(git rev-parse --abbrev-ref HEAD)
  if [[ "$CURRENT" != "main" && "$CURRENT" != "master" ]]; then
    git checkout main 2>/dev/null || git checkout master
  fi
  git merge "$TITLE"
  echo "[workflow] merged $TITLE into $(git rev-parse --abbrev-ref HEAD)"
  exit 0
fi

# ── cleanup subcommand ───────────────────────────────────────────────────────
if [[ "${1:-}" == "cleanup" ]]; then
  TITLE="$2"
  ROOT="$(get_main_root)"
  cd "$ROOT"
  WORKTREE_PATH=".worktrees/$TITLE"
  if git worktree list | grep -q "$WORKTREE_PATH"; then
    git worktree remove "$WORKTREE_PATH" 2>/dev/null || git worktree remove --force "$WORKTREE_PATH"
  fi
  if git branch --list "$TITLE" | grep -q "$TITLE"; then
    git branch -d "$TITLE" 2>/dev/null || echo "[workflow] branch $TITLE has unmerged commits, skipping deletion"
  fi
  echo "[workflow] cleanup done for $TITLE"
  exit 0
fi

# ── record subcommand ────────────────────────────────────────────────────────
if [[ "${1:-}" == "record" ]]; then
  TITLE="$2"
  NEW_STATE="$3"
  ART_KEY="${4:-}"
  ART_VAL="${5:-}"

  # Resolve sessions dir relative to main repo root (handles worktree ../../ calls)
  ROOT="$(get_main_root)"
  DIR="$ROOT/$WORKFLOW_REL"
  mkdir -p "$DIR"
  FILE="$DIR/${TITLE}.json"

  python3 - "$TITLE" "$NEW_STATE" "$ART_KEY" "$ART_VAL" "$FILE" <<'PYEOF'
import json, os, datetime, sys
title, new_state, art_key, art_val, fpath = sys.argv[1:]
d = json.load(open(fpath)) if os.path.exists(fpath) else {"title": title, "history": [], "artifacts": {}}
prev = d.get("state")
if art_key:
    d.setdefault("artifacts", {})[art_key] = art_val
d.update({
    "title": title, "state": new_state,
    "updated_at": datetime.datetime.utcnow().isoformat() + "Z",
})
if prev and prev != new_state:
    d["history"] = d.get("history", []) + [{"state": prev, "at": d["updated_at"]}]
json.dump(d, open(fpath, "w"), indent=2)
PYEOF

  export CLAUDE_WORKFLOW_TITLE="$TITLE"
  exit 0
fi
# ────────────────────────────────────────────────────────────────────────────
NEXT_CMD=""
NOTIFY_MSG=""

# Resolve absolute sessions dir for stop hook mode (may run from worktree via $CLAUDE_PROJECT_DIR)
_MAIN_ROOT="$(get_main_root)"
WORKFLOW_DIR="$_MAIN_ROOT/$WORKFLOW_REL"

# --- Find current session ---
if [[ -n "${CLAUDE_WORKFLOW_TITLE:-}" ]]; then
  TITLE="$CLAUDE_WORKFLOW_TITLE"
  SESSION_FILE="$WORKFLOW_DIR/${TITLE}.json"
else
  # Fallback: most recently modified session file that is NOT in 'done' state
  ACTIVE_COUNT=0
  FIRST_ACTIVE=""
  for f in $(ls -t "$WORKFLOW_DIR"/*.json 2>/dev/null || true); do
    file_state=$(python3 -c "import json,sys; d=json.load(open('$f')); print(d.get('state',''))" 2>/dev/null || true)
    if [[ "$file_state" != "done" ]]; then
      ACTIVE_COUNT=$((ACTIVE_COUNT + 1))
      if [[ -z "$FIRST_ACTIVE" ]]; then
        FIRST_ACTIVE="$f"
      fi
    fi
  done

  if [[ "$ACTIVE_COUNT" -eq 0 ]]; then
    exit 0  # No active (non-done) workflow session, nothing to do
  fi

  if [[ "$ACTIVE_COUNT" -ge 2 ]]; then
    cat <<WARNEOF

⚠️  $ACTIVE_COUNT active sessions detected but CLAUDE_WORKFLOW_TITLE is not set.
   Showing guidance for the most recent session. To target a specific session:
     export CLAUDE_WORKFLOW_TITLE="{title}"

WARNEOF
  fi

  SESSION_FILE="$FIRST_ACTIVE"
  TITLE=$(basename "$SESSION_FILE" .json)
fi

if [[ ! -f "$SESSION_FILE" ]]; then
  exit 0
fi

# --- Read state ---
STATE=$(python3 -c "import json,sys; d=json.load(open('$SESSION_FILE')); print(d.get('state',''))" 2>/dev/null || true)

if [[ -z "$STATE" ]]; then
  exit 0
fi

# --- State-based guidance ---
case "$STATE" in
  spec_draft)
    NEXT_CMD="claude \"/spec $TITLE\""
    NOTIFY_MSG="$TITLE: brainstorm complete — run /spec"
    cat <<EOF

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[workflow] $TITLE — state: spec_draft
brainstorms/$TITLE.md committed. Next step:

  claude "/spec $TITLE"   ← copied to clipboard

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EOF
    ;;

  spec_ready)
    NEXT_CMD="claude \"/generate $TITLE\""
    NOTIFY_MSG="$TITLE: ⚠️  review spec then run /generate"
    cat <<EOF

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[workflow] $TITLE — state: spec_ready
⚠️  Approval gate: review specs/$TITLE.md.

  If content looks good: claude "/generate $TITLE"   ← copied to clipboard
  If changes needed: re-run /spec $TITLE

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EOF
    ;;

  generating)
    # Generator is mid-session, no action needed
    exit 0
    ;;

  handoff_ready)
    NEXT_CMD="claude \"/evaluate $TITLE\""
    NOTIFY_MSG="$TITLE: handoff complete — run /evaluate in a new session"
    cat <<EOF

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[workflow] $TITLE — state: handoff_ready
Handoff complete + VERIFY PASS confirmed. Next step:

  claude "/evaluate $TITLE"   ← copied to clipboard
  (separate session required — Evaluator independence principle)
  Open a new terminal tab (Cmd+\\ in VSCode / Cmd+T in iTerm) and Cmd+V

After: /reflect $TITLE  (same session is fine)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EOF
    ;;

  evaluated_pass)
    NOTIFY_MSG="$TITLE: ✅ PASS — /reflect first, then merge"
    cat <<EOF

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[workflow] $TITLE — state: evaluated_pass
✅ Approval gate: Evaluator PASS.

Follow this order (worktree needed for /reflect before deleting):

  ① claude "/reflect $TITLE"   ← copied to clipboard
     (references worktree artifacts — run before merging)

  ② Merge + cleanup (after reflect completes):
     .claude/scripts/workflow-advance.sh merge $TITLE
     .claude/scripts/workflow-advance.sh cleanup $TITLE

  Or manually:
     git checkout main && git merge $TITLE
     git worktree remove .worktrees/$TITLE && git branch -d $TITLE

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EOF
    NEXT_CMD="claude \"/reflect $TITLE\""
    ;;

  evaluated_fail)
    NEXT_CMD="claude \"/generate $TITLE\""
    NOTIFY_MSG="$TITLE: ❌ FAIL — decision required on rework"
    cat <<EOF

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[workflow] $TITLE — state: evaluated_fail
❌ Approval gate: Evaluator FAIL. Read evaluation/$TITLE.md and decide.

  Rework:          claude "/generate $TITLE"   ← copied to clipboard
  Redefine spec:   claude "/spec $TITLE"
  Abandon:         manually clean up worktree

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EOF
    ;;

  reflecting)
    exit 0
    ;;

  done)
    NOTIFY_MSG="$TITLE: 🎉 cycle complete — clean up worktree"

    # Count unprocessed reflections since last reflect-batch
    UNPROCESSED=$(python3 - "$_MAIN_ROOT" <<'PYEOF'
import os, sys, re
from datetime import datetime

root = sys.argv[1]
index_path = os.path.join(root, "reflections", "index.md")
reflections_dir = os.path.join(root, "reflections")

# Find last batch date from index.md
last_batch = None
if os.path.exists(index_path):
    with open(index_path) as f:
        content = f.read()
    # Match "### YYYY-MM-DD Batch Aggregation" headers
    matches = re.findall(r'###\s+(\d{4}-\d{2}-\d{2})\s+Batch Aggregation', content)
    if matches:
        last_batch = max(matches)

# Count reflection files newer than last batch
if not os.path.exists(reflections_dir):
    print(0)
    sys.exit(0)

count = 0
for fname in os.listdir(reflections_dir):
    if fname == "index.md" or not fname.endswith(".md"):
        continue
    # Filename format: YYYY-MM-DD-HHmm-{title}.md
    m = re.match(r'^(\d{4}-\d{2}-\d{2})', fname)
    if not m:
        continue
    file_date = m.group(1)
    if last_batch is None or file_date > last_batch:
        count += 1

print(count)
PYEOF
    )

    if [[ "$UNPROCESSED" -ge 5 ]]; then
      NEXT_CMD="claude \"/reflect-batch\""
      NOTIFY_MSG="$TITLE: 🎉 done — ⚡ $UNPROCESSED reflections ready for /reflect-batch"
      cat <<EOF

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[workflow] $TITLE — state: done
🎉 Full cycle complete (brainstorm → reflect).

⚡ $UNPROCESSED unprocessed reflections accumulated — run:
  claude "/reflect-batch"   ← copied to clipboard

After reflect-batch, clean up the worktree:
  .claude/scripts/workflow-advance.sh merge $TITLE
  .claude/scripts/workflow-advance.sh cleanup $TITLE

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EOF
    else
      NEXT_CMD=".claude/scripts/workflow-advance.sh merge $TITLE && .claude/scripts/workflow-advance.sh cleanup $TITLE"
      cat <<EOF

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[workflow] $TITLE — state: done
🎉 Full cycle complete (brainstorm → reflect).
Reflection has been recorded in reflections/. ($UNPROCESSED unprocessed total)

If the worktree is still around, clean it up:
  .claude/scripts/workflow-advance.sh merge $TITLE    # (if not yet merged)   ← copied to clipboard
  .claude/scripts/workflow-advance.sh cleanup $TITLE

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EOF
    fi
    ;;

  *)
    exit 0
    ;;
esac

# --- Clipboard copy (next command) ---
if [[ -n "$NEXT_CMD" ]]; then
  if command -v pbcopy &>/dev/null; then
    echo -n "$NEXT_CMD" | pbcopy          # macOS
  elif command -v xclip &>/dev/null; then
    echo -n "$NEXT_CMD" | xclip -selection clipboard  # Linux (xclip)
  elif command -v xsel &>/dev/null; then
    echo -n "$NEXT_CMD" | xsel --clipboard --input     # Linux (xsel)
  fi
fi

# --- Desktop notification ---
if [[ -n "$NOTIFY_MSG" ]]; then
  if command -v osascript &>/dev/null; then
    osascript -e "display notification \"$NOTIFY_MSG\" with title \"Claude Workflow\"" 2>/dev/null || true  # macOS
  elif command -v notify-send &>/dev/null; then
    notify-send "Claude Workflow" "$NOTIFY_MSG" 2>/dev/null || true  # Linux
  fi
fi
