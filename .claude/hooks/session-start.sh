#!/usr/bin/env bash
# SessionStart hook — restore context for the new session.
# Shows: current branch, last reflection title, open specs (unchecked acceptance criteria).

set -u

cd "${CLAUDE_PROJECT_DIR:-$(pwd)}" || exit 0

say() { printf '%s\n' "$*" >&2; }

say "== Session start =="

branch=$(git branch --show-current 2>/dev/null || true)
[ -n "$branch" ] && say "Branch: $branch"

if [ -d reflections ]; then
  latest=$(ls -1t reflections/*.md 2>/dev/null | head -n 1 || true)
  if [ -n "$latest" ]; then
    summary=$(awk '/^## Session Summary/{getline; while($0 ~ /^[[:space:]]*$/) getline; print; exit}' "$latest")
    say "Last reflection: $(basename "$latest")"
    [ -n "$summary" ] && say "  → $summary"
  fi
fi

if [ -d specs ]; then
  # A spec is "open" if it has never had a /check run (no "## Check —" block).
  open=$(grep -rL '^## Check' specs/*.md 2>/dev/null | head -n 5 || true)
  if [ -n "$open" ]; then
    say "Open specs (no /check run yet):"
    while IFS= read -r f; do
      [ -z "$f" ] && continue
      title=$(grep -m1 '^# ' "$f" | sed 's/^# //')
      say "  - $(basename "$f") — $title"
    done <<< "$open"
  fi
fi

exit 0
