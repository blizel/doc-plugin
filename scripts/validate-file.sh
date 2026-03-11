#!/usr/bin/env bash
# Validates a markdown file against vault conventions.
# Hook mode:  called as PostToolUse on Write/Edit (reads JSON from stdin)
# CLI mode:   ./validate-file.sh /path/to/file.md
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

# Skip excluded directories
EXCLUDED=$(parse_section "$VAULT_CTX" "Excluded Directories" | sed 's/^- //')
while IFS= read -r exc; do
  [[ -n "$exc" ]] && [[ "$REL_PATH" == ${exc}* ]] && exit 0
done <<< "$EXCLUDED"

ISSUES=()

# --- Frontmatter ---
if ! head -1 "$FILE_PATH" | grep -q "^---$"; then
  ISSUES+=("ERROR: Missing YAML frontmatter")
else
  FM=$(awk '/^---$/{n++;next} n==1{print} n>=2{exit}' "$FILE_PATH")

  # Required fields
  for field in type title; do
    echo "$FM" | grep -q "^${field}:" || ISSUES+=("ERROR: Missing required field '$field'")
  done

  TYPE=$(echo "$FM" | grep "^type:" | head -1 | sed 's/type: *//' | tr -d '"'"'" | xargs)
  STATUS=$(echo "$FM" | grep "^status:" | head -1 | sed 's/status: *//' | tr -d '"'"'" | xargs)

  # Date fields (skip for daily notes and logs)
  if [[ "$TYPE" != "daily" ]] && [[ "$TYPE" != "log" ]]; then
    echo "$FM" | grep -q "^created:" || ISSUES+=("WARNING: Missing 'created' date")
    echo "$FM" | grep -q "^updated:" || ISSUES+=("WARNING: Missing 'updated' date")
  fi

  # Status validity
  if [[ -n "$STATUS" ]] && [[ -n "$TYPE" ]]; then
    case "$TYPE" in
      task)    [[ "$STATUS" =~ ^(todo|doing|waiting|done)$ ]]          || ISSUES+=("ERROR: Invalid status '$STATUS' for type '$TYPE'") ;;
      project) [[ "$STATUS" =~ ^(active|paused|completed|archived)$ ]] || ISSUES+=("ERROR: Invalid status '$STATUS' for type '$TYPE'") ;;
      writing) [[ "$STATUS" =~ ^(idea|draft|review|published)$ ]]      || ISSUES+=("ERROR: Invalid status '$STATUS' for type '$TYPE'") ;;
    esac
  fi

  # Tag format
  TAGS_LINE=$(echo "$FM" | grep "^tags:" | head -1)
  if [[ -n "$TAGS_LINE" ]]; then
    echo "$TAGS_LINE" | grep -qE '[A-Z]' && ISSUES+=("WARNING: Tags contain uppercase — use lowercase")
    echo "$TAGS_LINE" | grep -q '_' && ISSUES+=("WARNING: Tags contain underscores — use hyphens")
  fi

  # Location vs type
  if [[ -n "$TYPE" ]]; then
    LOCATION_OK=true
    case "$TYPE" in
      task)      echo "$REL_PATH" | grep -q "^tasks/"      || LOCATION_OK=false ;;
      project)   echo "$REL_PATH" | grep -q "^projects/"   || LOCATION_OK=false ;;
      knowledge) echo "$REL_PATH" | grep -q "^knowledge/"  || LOCATION_OK=false ;;
      writing)   echo "$REL_PATH" | grep -q "^writing/"    || LOCATION_OK=false ;;
      horizon)   echo "$REL_PATH" | grep -q "^odyssey/"    || LOCATION_OK=false ;;
      log|daily) ;; # flexible location
    esac
    [[ "$LOCATION_OK" == "false" ]] && ISSUES+=("WARNING: type '$TYPE' doesn't match directory location")
  fi
fi

# --- Naming convention ---
FILENAME=$(basename "$FILE_PATH" .md)
NAMING=$(parse_section "$VAULT_CTX" "Naming Conventions")
CONVENTION=$(echo "$NAMING" | grep "^default:" | sed 's/default: *//')

# Directory-specific overrides
if echo "$REL_PATH" | grep -q "^tasks/"; then
  OVERRIDE=$(echo "$NAMING" | grep "^tasks:" | sed 's/tasks: *//')
  [[ -n "$OVERRIDE" ]] && CONVENTION="$OVERRIDE"
elif echo "$REL_PATH" | grep -q "^writing/"; then
  OVERRIDE=$(echo "$NAMING" | grep "^writing:" | sed 's/writing: *//')
  [[ -n "$OVERRIDE" ]] && CONVENTION="$OVERRIDE"
fi

if [[ "$CONVENTION" == "kebab-case" ]]; then
  echo "$FILENAME" | grep -qE '[A-Z _]' && ISSUES+=("WARNING: Filename '$FILENAME' should be kebab-case")
fi

# --- Output ---
if [[ ${#ISSUES[@]} -gt 0 ]]; then
  echo "File validation — ${REL_PATH}:"
  for issue in "${ISSUES[@]}"; do
    echo "  $issue"
  done
fi

exit 0
