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

# Skip excluded directories (match from vault root, strip trailing slash for comparison)
EXCLUDED=$(parse_section "$VAULT_CTX" "Excluded Directories" | sed 's/^- //' | sed 's|/$||')
while IFS= read -r exc; do
  [[ -n "$exc" ]] && [[ "$REL_PATH" == ${exc}/* ]] && exit 0
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

  # Location vs type — check against Directory Map from vault context
  if [[ -n "$TYPE" ]] && [[ "$TYPE" != "daily" ]] && [[ "$TYPE" != "log" ]]; then
    DIR_MAP=$(parse_section "$VAULT_CTX" "Directory Map")
    LOCATION_OK=false
    while IFS= read -r mapline; do
      [[ -z "$mapline" ]] && continue
      map_key=$(echo "$mapline" | sed 's/:.*//' | xargs)
      map_dir=$(echo "$mapline" | sed 's/[^:]*: *//' | xargs)
      TYPE_SINGULAR="${TYPE}"
      if [[ "$map_key" == *"${TYPE_SINGULAR}"* ]] || [[ "$map_key" == *"${TYPE_SINGULAR}s"* ]]; then
        if echo "$REL_PATH" | grep -q "^${map_dir}"; then
          LOCATION_OK=true
          break
        fi
      fi
    done <<< "$DIR_MAP"
    [[ "$LOCATION_OK" == "false" ]] && ISSUES+=("WARNING: type '$TYPE' doesn't match any directory in Directory Map")
  fi
fi

# --- Naming convention ---
FILENAME=$(basename "$FILE_PATH" .md)
NAMING=$(parse_section "$VAULT_CTX" "Naming Conventions")
CONVENTION=$(echo "$NAMING" | grep "^default:" | sed 's/default: *//')

# Directory-specific overrides
# Files inside a project subfolder use sentence case (project_files convention)
IN_PROJECT_FOLDER=false
DIR_MAP=$(parse_section "$VAULT_CTX" "Directory Map")
while IFS= read -r mapline; do
  [[ -z "$mapline" ]] && continue
  map_key=$(echo "$mapline" | sed 's/:.*//' | xargs)
  map_dir=$(echo "$mapline" | sed 's/[^:]*: *//' | xargs)
  if [[ "$map_key" == project* ]] && echo "$REL_PATH" | grep -qE "^${map_dir}[^/]+/"; then
    IN_PROJECT_FOLDER=true
    break
  fi
done <<< "$DIR_MAP"

if [[ "$IN_PROJECT_FOLDER" == "true" ]]; then
  PROJECT_FILES_CONV=$(echo "$NAMING" | grep "^project_files:" | sed 's/project_files: *//')
  [[ -n "$PROJECT_FILES_CONV" ]] && CONVENTION="$PROJECT_FILES_CONV"
elif echo "$REL_PATH" | grep -q "^tasks/"; then
  OVERRIDE=$(echo "$NAMING" | grep "^tasks:" | sed 's/tasks: *//')
  [[ -n "$OVERRIDE" ]] && CONVENTION="$OVERRIDE"
elif echo "$REL_PATH" | grep -q "^writing/"; then
  OVERRIDE=$(echo "$NAMING" | grep "^writing:" | sed 's/writing: *//')
  [[ -n "$OVERRIDE" ]] && CONVENTION="$OVERRIDE"
fi

if [[ "$CONVENTION" == "kebab-case" ]]; then
  echo "$FILENAME" | grep -qE '[A-Z _]' && ISSUES+=("WARNING: Filename '$FILENAME' should be kebab-case")
elif [[ "$CONVENTION" == sentence* ]]; then
  # Sentence case: must start with uppercase, spaces allowed, no hyphens between words
  echo "$FILENAME" | grep -qE '^[A-Z]' || ISSUES+=("WARNING: Filename '$FILENAME' should be sentence case (start with uppercase)")
fi

# --- Output ---
if [[ ${#ISSUES[@]} -gt 0 ]]; then
  echo "File validation — ${REL_PATH}:"
  for issue in "${ISSUES[@]}"; do
    echo "  $issue"
  done
fi

exit 0
