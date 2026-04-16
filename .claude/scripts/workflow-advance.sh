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
  SESSION_FILE=""
  for f in $(ls -t "$WORKFLOW_DIR"/*.json 2>/dev/null || true); do
    file_state=$(python3 -c "import json,sys; d=json.load(open('$f')); print(d.get('state',''))" 2>/dev/null || true)
    if [[ "$file_state" != "done" ]]; then
      SESSION_FILE="$f"
      break
    fi
  done
  if [[ -z "$SESSION_FILE" ]]; then
    exit 0  # No active (non-done) workflow session, nothing to do
  fi
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
    NOTIFY_MSG="$TITLE: brainstorm 완료 — /spec 을 실행하세요"
    cat <<EOF

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[workflow] $TITLE — state: spec_draft
brainstorms/$TITLE.md 커밋됨. 다음 단계:

  claude "/spec $TITLE"   ← 클립보드에 복사됨

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EOF
    ;;

  spec_ready)
    NEXT_CMD="claude \"/generate $TITLE\""
    NOTIFY_MSG="$TITLE: ⚠️  spec 검토 후 /generate 실행"
    cat <<EOF

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[workflow] $TITLE — state: spec_ready
⚠️  승인 게이트: specs/$TITLE.md 를 검토하세요.

  내용이 맞다면: claude "/generate $TITLE"   ← 클립보드에 복사됨
  수정이 필요하다면: /spec $TITLE 다시 실행

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EOF
    ;;

  generating)
    # Generator is mid-session, no action needed
    exit 0
    ;;

  handoff_ready)
    NEXT_CMD="claude \"/evaluate $TITLE\""
    NOTIFY_MSG="$TITLE: handoff 완료 — 새 세션에서 /evaluate 실행"
    cat <<EOF

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[workflow] $TITLE — state: handoff_ready
handoff 완성 + VERIFY PASS 확인됨. 다음 단계:

  claude "/evaluate $TITLE"   ← 클립보드에 복사됨
  (별도 세션 필수 — Evaluator 독립성 원칙)
  새 터미널 탭(Cmd+\\ in VSCode / Cmd+T in iTerm) 열고 Cmd+V

이후: /reflect $TITLE  (같은 세션 가능)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EOF
    ;;

  evaluated_pass)
    NOTIFY_MSG="$TITLE: ✅ PASS — /reflect 먼저, 그 다음 머지"
    cat <<EOF

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[workflow] $TITLE — state: evaluated_pass
✅ 승인 게이트: Evaluator PASS.

순서를 반드시 지키세요 (worktree 삭제 전 /reflect 필요):

  ① claude "/reflect $TITLE"   ← 클립보드에 복사됨
     (worktree 안 산출물 참조 — 머지 전에 실행)

  ② 머지 + 정리 (reflect 완료 후):
     .claude/scripts/workflow-advance.sh merge $TITLE
     .claude/scripts/workflow-advance.sh cleanup $TITLE

  또는 수동:
     git checkout main && git merge $TITLE
     git worktree remove .worktrees/$TITLE && git branch -d $TITLE

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EOF
    NEXT_CMD="claude \"/reflect $TITLE\""
    ;;

  evaluated_fail)
    NOTIFY_MSG="$TITLE: ❌ FAIL — 재작업 여부 결정 필요"
    cat <<EOF

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[workflow] $TITLE — state: evaluated_fail
❌ 승인 게이트: Evaluator FAIL. evaluation/$TITLE.md 를 읽고 결정하세요.

  재작업:       claude "/generate $TITLE"   (Generator가 evaluation 피드백 반영)
  스펙 재정의:  claude "/spec $TITLE"
  포기:         수동으로 worktree 정리

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EOF
    ;;

  reflecting)
    exit 0
    ;;

  done)
    NOTIFY_MSG="$TITLE: 🎉 사이클 완료 — worktree 정리하세요"
    cat <<EOF

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[workflow] $TITLE — state: done
🎉 전체 사이클 완료 (brainstorm → reflect).
reflections/ 에 회고가 기록되었습니다.

워크트리가 아직 남아있다면 정리하세요:
  .claude/scripts/workflow-advance.sh merge $TITLE    # (미머지 시)
  .claude/scripts/workflow-advance.sh cleanup $TITLE

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EOF
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
