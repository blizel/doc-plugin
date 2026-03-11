#!/usr/bin/env bash
# Auto-syncs frontmatter status to match directory location.
# Hook mode:  called as PostToolUse on Write/Edit (reads JSON from stdin)
# CLI mode:   ./sync-status.sh /path/to/file.md
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

FILE_PATH=$(resolve_file_path "$@")
[[ -z "$FILE_PATH" ]] && exit 0
[[ "$FILE_PATH" != *.md ]] && exit 0
[[ ! -f "$FILE_PATH" ]] && exit 0

VAULT_CTX=$(find_vault_context "$FILE_PATH") || exit 0
VAULT_ROOT=$(vault_root "$VAULT_CTX")
REL_PATH="${FILE_PATH#$VAULT_ROOT/}"

# Read status map
STATUS_MAP=$(parse_section "$VAULT_CTX" "Status Map")
[[ -z "$STATUS_MAP" ]] && exit 0

# Find which mapped directory this file is in (longest match wins)
EXPECTED_STATUS=""
BEST_MATCH_LEN=0
while IFS= read -r line; do
  [[ -z "$line" ]] && continue
  dir=$(echo "$line" | sed 's/:.*//' | xargs)
  status=$(echo "$line" | sed 's/[^:]*: *//' | xargs)
  if [[ "$REL_PATH" == ${dir}* ]]; then
    if (( ${#dir} > BEST_MATCH_LEN )); then
      BEST_MATCH_LEN=${#dir}
      EXPECTED_STATUS="$status"
    fi
  fi
done <<< "$STATUS_MAP"

[[ -z "$EXPECTED_STATUS" ]] && exit 0

# Check frontmatter exists
head -1 "$FILE_PATH" | grep -q "^---$" || exit 0

# Read current status
CURRENT_STATUS=$(awk '/^---$/{n++;next} n==1{print} n>=2{exit}' "$FILE_PATH" \
  | grep "^status:" | head -1 | sed 's/status: *//' | tr -d '"'"'" | xargs)

[[ "$CURRENT_STATUS" == "$EXPECTED_STATUS" ]] && exit 0

# Update status
if [[ -n "$CURRENT_STATUS" ]]; then
  sed -i "0,/^status: .*/{s/^status: .*/status: $EXPECTED_STATUS/}" "$FILE_PATH"
else
  sed -i "/^type: /a status: $EXPECTED_STATUS" "$FILE_PATH"
fi

# Update the updated date
TODAY=$(date +%Y-%m-%d)
grep -q "^updated:" "$FILE_PATH" && \
  sed -i "0,/^updated: .*/{s/^updated: .*/updated: $TODAY/}" "$FILE_PATH"

echo "Status synced: ${REL_PATH} → status: $EXPECTED_STATUS (was: ${CURRENT_STATUS:-unset})"
