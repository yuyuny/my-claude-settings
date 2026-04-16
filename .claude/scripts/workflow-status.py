#!/usr/bin/env python3
"""workflow-status.py — 진행 중인 세션 상태 출력"""

import json
import os
import glob
import subprocess


def get_main_root():
    """Resolve main repo root (works from worktrees too)."""
    try:
        git_common_dir = subprocess.check_output(
            ["git", "rev-parse", "--git-common-dir"],
            stderr=subprocess.DEVNULL,
            text=True,
        ).strip()
        return os.path.dirname(os.path.abspath(git_common_dir))
    except (subprocess.CalledProcessError, FileNotFoundError):
        return "."


SESSIONS_DIR = os.path.join(get_main_root(), ".claude-workflow", "sessions")

STATE_LABELS = {
    "brainstorming":  "🧠 브레인스토밍 진행 중",
    "spec_draft":     "📝 spec 작성 필요",
    "spec_ready":     "⚠️  [승인 게이트] spec 검토 후 /generate",
    "generating":     "🔨 구현 진행 중",
    "handoff_ready":  "📦 [다음] 별도 세션에서 /evaluate",
    "evaluating":     "🔍 평가 진행 중",
    "evaluated_pass": "✅ [승인 게이트] PASS — /reflect 후 머지",
    "evaluated_fail": "❌ [승인 게이트] FAIL — 재작업/스펙재정의/포기 결정",
    "reflecting":     "💭 회고 진행 중",
    "done":           "🎉 완료",
}

if not os.path.exists(SESSIONS_DIR):
    print("활성 세션 없음 — .claude-workflow/sessions/ 디렉토리가 없습니다.")
    raise SystemExit(0)

files = sorted(glob.glob(f"{SESSIONS_DIR}/*.json"), key=os.path.getmtime, reverse=True)
if not files:
    print("활성 세션 없음")
    raise SystemExit(0)

print()
print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
print("[workflow-status] 진행 중인 세션")
print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

for f in files:
    try:
        d = json.load(open(f))
        title = d.get("title", os.path.basename(f).replace(".json", ""))
        state = d.get("state", "unknown")
        label = STATE_LABELS.get(state, state)
        updated = d.get("updated_at", "")[:16].replace("T", " ")
        print(f"  {title}")
        print(f"    상태: {label}")
        print(f"    마지막 업데이트: {updated} UTC")
        arts = d.get("artifacts", {})
        existing = [k for k, v in arts.items() if v and os.path.exists(v)]
        if existing:
            print(f"    산출물: {' / '.join(existing)}")
        next_a = d.get("next_action")
        if next_a:
            print(f"    다음 액션: {next_a}")
        print()
    except Exception as e:
        print(f"  {f}: 읽기 실패 ({e})")

print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
