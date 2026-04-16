#!/usr/bin/env bash
# workflow-advance.sh — Stop hook + state recorder for multi-agent workflow
#
# Usage:
#   ./workflow-advance.sh                      # Stop hook mode (reads state, prints guidance)
#   ./workflow-advance.sh record <title> <state> [artifact_key] [artifact_val]
#                                              # Record state transition
#
# Stop hook reads CLAUDE_WORKFLOW_TITLE env var (or falls back to most recent file).

set -euo pipefail

WORKFLOW_DIR=".claude-workflow/sessions"

# ── record subcommand ────────────────────────────────────────────────────────
if [[ "${1:-}" == "record" ]]; then
  TITLE="$2"
  NEW_STATE="$3"
  ART_KEY="${4:-}"
  ART_VAL="${5:-}"

  # Resolve sessions dir relative to project root (handles worktree ../../ calls)
  ROOT="$(git rev-parse --show-toplevel 2>/dev/null || echo ".")"
  DIR="$ROOT/$WORKFLOW_DIR"
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

# --- Find current session ---
if [[ -n "${CLAUDE_WORKFLOW_TITLE:-}" ]]; then
  TITLE="$CLAUDE_WORKFLOW_TITLE"
  SESSION_FILE="$WORKFLOW_DIR/${TITLE}.json"
else
  # Fallback: most recently modified session file
  SESSION_FILE=$(ls -t "$WORKFLOW_DIR"/*.json 2>/dev/null | head -1 || true)
  if [[ -z "$SESSION_FILE" ]]; then
    exit 0  # No active workflow session, nothing to do
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
    NOTIFY_MSG="$TITLE: ✅ PASS — 머지 명령을 확인하세요"
    cat <<EOF

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[workflow] $TITLE — state: evaluated_pass
✅ 승인 게이트: Evaluator PASS. 머지 전 evaluation/$TITLE.md 확인하세요.

  머지 명령 (확인 후 직접 실행):
  git checkout main && git merge $TITLE && git worktree remove .worktrees/$TITLE && git branch -d $TITLE

이후: claude "/reflect $TITLE"   ← 클립보드에 복사됨

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
    NOTIFY_MSG="$TITLE: 🎉 사이클 완료"
    cat <<EOF

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[workflow] $TITLE — state: done
🎉 전체 사이클 완료 (brainstorm → reflect).
reflections/ 에 회고가 기록되었습니다.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EOF
    ;;

  *)
    exit 0
    ;;
esac

# --- Clipboard copy (next command) ---
if [[ -n "$NEXT_CMD" ]] && command -v pbcopy &>/dev/null; then
  echo -n "$NEXT_CMD" | pbcopy
fi

# --- Desktop notification ---
if [[ -n "$NOTIFY_MSG" ]] && command -v osascript &>/dev/null; then
  osascript -e "display notification \"$NOTIFY_MSG\" with title \"Claude Workflow\"" 2>/dev/null || true
fi
