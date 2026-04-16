#!/usr/bin/env python3
"""workflow-status.py — Display active session status"""

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
    "brainstorming":  "🧠 Brainstorming in progress",
    "spec_draft":     "📝 Spec writing needed",
    "spec_ready":     "⚠️  [Approval gate] Review spec, then /generate",
    "generating":     "🔨 Implementation in progress",
    "handoff_ready":  "📦 [Next] Run /evaluate in a separate session",
    "evaluating":     "🔍 Evaluation in progress",
    "evaluated_pass": "✅ [Approval gate] PASS — /reflect then merge",
    "evaluated_fail": "❌ [Approval gate] FAIL — decide: rework / redefine spec / abandon",
    "reflecting":     "💭 Reflection in progress",
    "done":           "🎉 Done",
}

if not os.path.exists(SESSIONS_DIR):
    print("No active sessions — .claude-workflow/sessions/ directory not found.")
    raise SystemExit(0)

files = sorted(glob.glob(f"{SESSIONS_DIR}/*.json"), key=os.path.getmtime, reverse=True)
if not files:
    print("No active sessions")
    raise SystemExit(0)

print()
print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
print("[workflow-status] Active Sessions")
print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

for f in files:
    try:
        d = json.load(open(f))
        title = d.get("title", os.path.basename(f).replace(".json", ""))
        state = d.get("state", "unknown")
        label = STATE_LABELS.get(state, state)
        updated = d.get("updated_at", "")[:16].replace("T", " ")
        print(f"  {title}")
        print(f"    State: {label}")
        print(f"    Last updated: {updated} UTC")
        arts = d.get("artifacts", {})
        existing = [k for k, v in arts.items() if v and os.path.exists(v)]
        if existing:
            print(f"    Artifacts: {' / '.join(existing)}")
        next_a = d.get("next_action")
        if next_a:
            print(f"    Next action: {next_a}")
        print()
    except Exception as e:
        print(f"  {f}: read error ({e})")

print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
