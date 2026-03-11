#!/usr/bin/env bash
# Comprehensive vault scan — frontmatter, naming, wikilinks, stale dates.
# Standalone: ./scan-vault.sh [path-scope]
# Dynamic injection in doc:maintain: !`${CLAUDE_PLUGIN_ROOT}/scripts/scan-vault.sh`
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

SCOPE="${1:-.}"

VAULT_CTX=$(find_vault_context "$SCOPE") || { echo "ERROR: vault-context.md not found"; exit 1; }
VAULT_ROOT=$(vault_root "$VAULT_CTX")

# Build find exclusions
EXCLUDED=$(parse_section "$VAULT_CTX" "Excluded Directories" | sed 's/^- //' | sed 's|/$||')
FIND_ARGS=()
while IFS= read -r exc; do
  [[ -n "$exc" ]] && FIND_ARGS+=(-not -path "*/${exc}/*")
done <<< "$EXCLUDED"

# Determine scan root
SCAN_ROOT="$VAULT_ROOT"
[[ -d "$SCOPE" ]] && SCAN_ROOT="$SCOPE"

# Collect all markdown files
mapfile -t ALL_FILES < <(find "$SCAN_ROOT" -name "*.md" "${FIND_ARGS[@]}" -type f 2>/dev/null | sort)
TOTAL=${#ALL_FILES[@]}

[[ $TOTAL -eq 0 ]] && { echo "No markdown files found."; exit 0; }

# Build filename index for wikilink checking (lowercase basename → 1)
declare -A FILE_INDEX
for f in "${ALL_FILES[@]}"; do
  name=$(basename "$f" .md)
  lower="${name,,}"
  FILE_INDEX["$lower"]=1
done

# Read conventions
NAMING=$(parse_section "$VAULT_CTX" "Naming Conventions")
DEFAULT_NAMING=$(echo "$NAMING" | grep "^default:" | sed 's/default: *//')
TASKS_NAMING=$(echo "$NAMING" | grep "^tasks:" | sed 's/tasks: *//')
WRITING_NAMING=$(echo "$NAMING" | grep "^writing:" | sed 's/writing: *//')

ERRORS=()
WARNINGS=()
SUGGESTIONS=()
TODAY_EPOCH=$(date +%s)
NINETY_DAYS=$((90 * 86400))

for filepath in "${ALL_FILES[@]}"; do
  REL_PATH="${filepath#$VAULT_ROOT/}"
  FILENAME=$(basename "$filepath" .md)

  # --- Frontmatter ---
  if ! head -1 "$filepath" | grep -q "^---$"; then
    ERRORS+=("$REL_PATH: missing YAML frontmatter")
    continue
  fi

  FM=$(awk '/^---$/{n++;next} n==1{print} n>=2{exit}' "$filepath")
  TYPE=$(echo "$FM" | grep "^type:" | head -1 | sed 's/type: *//' | tr -d '"'"'" | xargs)
  STATUS=$(echo "$FM" | grep "^status:" | head -1 | sed 's/status: *//' | tr -d '"'"'" | xargs)
  UPDATED=$(echo "$FM" | grep "^updated:" | head -1 | sed 's/updated: *//' | tr -d '"'"'" | xargs)
  TAGS_LINE=$(echo "$FM" | grep "^tags:" | head -1)

  # Required fields
  [[ -z "$TYPE" ]] && ERRORS+=("$REL_PATH: missing 'type' field")
  echo "$FM" | grep -q "^title:" || ERRORS+=("$REL_PATH: missing 'title' field")

  # Status validity
  if [[ -n "$STATUS" ]] && [[ -n "$TYPE" ]]; then
    case "$TYPE" in
      task)    [[ "$STATUS" =~ ^(todo|doing|waiting|done)$ ]]          || ERRORS+=("$REL_PATH: invalid status '$STATUS' for type '$TYPE'") ;;
      project) [[ "$STATUS" =~ ^(active|paused|completed|archived)$ ]] || ERRORS+=("$REL_PATH: invalid status '$STATUS' for type '$TYPE'") ;;
      writing) [[ "$STATUS" =~ ^(idea|draft|review|published)$ ]]      || ERRORS+=("$REL_PATH: invalid status '$STATUS' for type '$TYPE'") ;;
    esac
  fi

  # Date checks
  if [[ "$TYPE" != "daily" ]] && [[ "$TYPE" != "log" ]]; then
    echo "$FM" | grep -q "^created:" || WARNINGS+=("$REL_PATH: missing 'created' date")
    [[ -z "$UPDATED" ]] && WARNINGS+=("$REL_PATH: missing 'updated' date")
  fi

  # Stale active items
  if [[ -n "$UPDATED" ]] && [[ "$STATUS" =~ ^(doing|active)$ ]]; then
    UPDATED_EPOCH=$(date -d "$UPDATED" +%s 2>/dev/null || echo 0)
    if (( UPDATED_EPOCH > 0 && (TODAY_EPOCH - UPDATED_EPOCH) > NINETY_DAYS )); then
      WARNINGS+=("$REL_PATH: status '$STATUS' but last updated $UPDATED (90+ days ago)")
    fi
  fi

  # Tag format
  if [[ -n "$TAGS_LINE" ]]; then
    echo "$TAGS_LINE" | grep -qE '[A-Z]' && WARNINGS+=("$REL_PATH: tags contain uppercase")
    echo "$TAGS_LINE" | grep -q '_' && WARNINGS+=("$REL_PATH: tags contain underscores")
  fi
  [[ -z "$TAGS_LINE" ]] && SUGGESTIONS+=("$REL_PATH: no tags")

  # Location vs type
  if [[ -n "$TYPE" ]]; then
    case "$TYPE" in
      task)      echo "$REL_PATH" | grep -q "^tasks/"      || ERRORS+=("$REL_PATH: type '$TYPE' doesn't match location") ;;
      project)   echo "$REL_PATH" | grep -q "^projects/"   || ERRORS+=("$REL_PATH: type '$TYPE' doesn't match location") ;;
      knowledge) echo "$REL_PATH" | grep -q "^knowledge/"  || ERRORS+=("$REL_PATH: type '$TYPE' doesn't match location") ;;
      writing)   echo "$REL_PATH" | grep -q "^writing/"    || ERRORS+=("$REL_PATH: type '$TYPE' doesn't match location") ;;
      horizon)   echo "$REL_PATH" | grep -q "^odyssey/"    || ERRORS+=("$REL_PATH: type '$TYPE' doesn't match location") ;;
    esac
  fi

  # Naming convention
  CONVENTION="$DEFAULT_NAMING"
  echo "$REL_PATH" | grep -q "^tasks/" && [[ -n "$TASKS_NAMING" ]] && CONVENTION="$TASKS_NAMING"
  echo "$REL_PATH" | grep -q "^writing/" && [[ -n "$WRITING_NAMING" ]] && CONVENTION="$WRITING_NAMING"
  if [[ "$CONVENTION" == "kebab-case" ]]; then
    echo "$FILENAME" | grep -qE '[A-Z _]' && WARNINGS+=("$REL_PATH: filename should be kebab-case")
  fi

  # Broken wikilinks
  LINKS=$(grep -oE '\[\[[^]|]+' "$filepath" 2>/dev/null | sed 's/\[\[//' | sed 's/#.*//' | sort -u || true)
  while IFS= read -r link; do
    [[ -z "$link" ]] && continue
    lower="${link,,}"
    [[ -z "${FILE_INDEX[$lower]:-}" ]] && WARNINGS+=("$REL_PATH: broken wikilink [[${link}]]")
  done <<< "$LINKS"

done

# --- Report ---
echo "# Vault Scan Report"
echo "Scanned $TOTAL files in ${SCAN_ROOT#$VAULT_ROOT/}"
echo ""

if [[ ${#ERRORS[@]} -gt 0 ]]; then
  echo "## Errors (${#ERRORS[@]})"
  for e in "${ERRORS[@]}"; do echo "- $e"; done
  echo ""
fi

if [[ ${#WARNINGS[@]} -gt 0 ]]; then
  echo "## Warnings (${#WARNINGS[@]})"
  COUNT=0
  for w in "${WARNINGS[@]}"; do
    echo "- $w"
    ((COUNT++))
    (( COUNT >= 50 )) && { echo "- ... and $((${#WARNINGS[@]} - 50)) more"; break; }
  done
  echo ""
fi

if [[ ${#SUGGESTIONS[@]} -gt 0 ]]; then
  echo "## Suggestions (${#SUGGESTIONS[@]})"
  COUNT=0
  for s in "${SUGGESTIONS[@]}"; do
    echo "- $s"
    ((COUNT++))
    (( COUNT >= 25 )) && { echo "- ... and $((${#SUGGESTIONS[@]} - 25)) more"; break; }
  done
  echo ""
fi

if [[ ${#ERRORS[@]} -eq 0 ]] && [[ ${#WARNINGS[@]} -eq 0 ]] && [[ ${#SUGGESTIONS[@]} -eq 0 ]]; then
  echo "No issues found."
fi
