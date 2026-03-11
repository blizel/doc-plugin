#!/usr/bin/env bash
# Auto-stamps `updated` date on any markdown file that has frontmatter.
# Hook mode:  called as PostToolUse on Write/Edit (reads JSON from stdin)
# CLI mode:   ./auto-date.sh /path/to/file.md
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

FILE_PATH=$(resolve_file_path "$@")
[[ -z "$FILE_PATH" ]] && exit 0
[[ "$FILE_PATH" != *.md ]] && exit 0
[[ ! -f "$FILE_PATH" ]] && exit 0

# Must have frontmatter
head -1 "$FILE_PATH" | grep -q "^---$" || exit 0

TODAY=$(date +%Y-%m-%d)

# Check current updated value — skip if already today
CURRENT=$(awk '/^---$/{n++;next} n==1{print} n>=2{exit}' "$FILE_PATH" \
  | grep "^updated:" | head -1 | sed 's/updated: *//' | xargs)

[[ "$CURRENT" == "$TODAY" ]] && exit 0

if grep -q "^updated:" "$FILE_PATH"; then
  sed -i "0,/^updated: .*/{s/^updated: .*/updated: $TODAY/}" "$FILE_PATH"
else
  # Add updated after created if it exists, otherwise after title
  if grep -q "^created:" "$FILE_PATH"; then
    sed -i "/^created: .*/a updated: $TODAY" "$FILE_PATH"
  elif grep -q "^title:" "$FILE_PATH"; then
    sed -i "/^title: .*/a updated: $TODAY" "$FILE_PATH"
  fi
fi
