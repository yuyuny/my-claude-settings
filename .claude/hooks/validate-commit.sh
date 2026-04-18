#!/usr/bin/env bash
# PreToolUse hook for Bash — block unsafe git flags.
# Reads JSON from stdin; checks tool_input.command.
# Exit 2 + message on stderr = block tool call.

set -u

input=$(cat)
cmd=$(printf '%s' "$input" | python3 -c 'import json,sys; d=json.load(sys.stdin); print(d.get("tool_input",{}).get("command",""))' 2>/dev/null || true)

[ -z "$cmd" ] && exit 0

block() {
  printf 'Blocked by validate-commit.sh: %s\n' "$1" >&2
  exit 2
}

case "$cmd" in
  *"git commit"*"--no-verify"*)  block "git commit --no-verify bypasses hooks. Fix the hook failure instead." ;;
  *"git commit"*"--no-gpg-sign"*) block "git commit --no-gpg-sign bypasses signing." ;;
  *"git push"*"--force"*" main"*|*"git push"*"--force"*":main"*|*"git push"*"--force"*" master"*|*"git push"*"--force"*":master"*) block "git push --force to main/master is destructive." ;;
  *"git push"*"-f"*" main"*|*"git push"*"-f"*":main"*|*"git push"*"-f"*" master"*|*"git push"*"-f"*":master"*) block "git push -f to main/master is destructive." ;;
  *"rm -rf"*"/"*)
    # Allow rm -rf under project paths; block obvious root-scale deletes.
    case "$cmd" in
      *"rm -rf /"[!a-zA-Z_.]*|*"rm -rf /"|*"rm -rf --no-preserve-root"*) block "rm -rf at root is never intended." ;;
    esac
    ;;
esac

exit 0
