#!/usr/bin/env bash
# Comprehensive vault scan — frontmatter, naming, wikilinks, stale dates.
# Standalone: ./scan-vault.sh [path-scope]
# Dynamic injection in doc:maintain: !`${CLAUDE_PLUGIN_ROOT}/scripts/scan-vault.sh`
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
if ! source "$SCRIPT_DIR/lib.sh" 2>/dev/null; then
  echo "ERROR: Failed to source lib.sh from $SCRIPT_DIR" >&2
  exit 1
fi

SCOPE="${1:-.}"

VAULT_CTX=$(find_vault_context "$SCOPE") || { echo "ERROR: vault-context.md not found — searched upward from '$SCOPE'" >&2; exit 1; }
VAULT_ROOT=$(vault_root "$VAULT_CTX")

if [[ ! -d "$VAULT_ROOT" ]]; then
  echo "ERROR: Vault root directory does not exist: $VAULT_ROOT" >&2
  exit 1
fi

# Build find exclusions — anchor to vault root, not substring
EXCLUDED=$(parse_section "$VAULT_CTX" "Excluded Directories" | sed 's/^- //' | sed 's|/$||')
FIND_ARGS=()
while IFS= read -r exc; do
  [[ -n "$exc" ]] && FIND_ARGS+=(-not -path "${VAULT_ROOT}/${exc}/*")
done <<< "$EXCLUDED"

# Determine scan root
SCAN_ROOT="$VAULT_ROOT"
if [[ -n "$SCOPE" ]] && [[ "$SCOPE" != "." ]]; then
  if [[ -d "$SCOPE" ]]; then
    SCAN_ROOT="$SCOPE"
  elif [[ -d "${VAULT_ROOT}/${SCOPE}" ]]; then
    SCAN_ROOT="${VAULT_ROOT}/${SCOPE}"
  else
    echo "ERROR: Scope path not found: '$SCOPE' (tried absolute and relative to vault root)" >&2
    exit 1
  fi
fi

# Collect all markdown files (portable — no mapfile)
ALL_FILES=()
while IFS= read -r f; do
  ALL_FILES+=("$f")
done < <(find "$SCAN_ROOT" -name "*.md" "${FIND_ARGS[@]}" -type f 2>/dev/null | sort)
TOTAL=${#ALL_FILES[@]}

if [[ $TOTAL -eq 0 ]]; then
  echo "ERROR: No markdown files found in $SCAN_ROOT" >&2
  echo "  Vault root: $VAULT_ROOT" >&2
  echo "  Excluded: $(echo "$EXCLUDED" | tr '\n' ', ')" >&2
  exit 1
fi

# Build filename index for wikilink checking (temp file, one lowercase name per line)
FILE_INDEX_TMP=$(mktemp)
trap 'rm -f "$FILE_INDEX_TMP"' EXIT
for f in "${ALL_FILES[@]}"; do
  basename "$f" .md | tr '[:upper:]' '[:lower:]'
done | sort -u > "$FILE_INDEX_TMP"

# Portable lowercase helper
to_lower() { echo "$1" | tr '[:upper:]' '[:lower:]'; }

# Portable date-to-epoch (works on both GNU and BSD/macOS)
date_to_epoch() {
  local d="$1"
  # GNU date
  date -d "$d" +%s 2>/dev/null && return
  # BSD/macOS date
  date -j -f "%Y-%m-%d" "$d" +%s 2>/dev/null && return
  echo 0
}

# Read directory map for location-type checking
DIR_MAP=$(parse_section "$VAULT_CTX" "Directory Map")

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
    UPDATED_EPOCH=$(date_to_epoch "$UPDATED")
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

  # Location vs type — check against Directory Map from vault context
  if [[ -n "$TYPE" ]]; then
    LOCATION_MATCH=false
    while IFS= read -r mapline; do
      [[ -z "$mapline" ]] && continue
      map_key=$(echo "$mapline" | sed 's/:.*//' | xargs)
      map_dir=$(echo "$mapline" | sed 's/[^:]*: *//' | xargs)
      # Check if this map entry's key contains the type name (e.g., tasks→task, projects→project)
      TYPE_SINGULAR="${TYPE}"
      if [[ "$map_key" == *"${TYPE_SINGULAR}"* ]] || [[ "$map_key" == *"${TYPE_SINGULAR}s"* ]]; then
        if echo "$REL_PATH" | grep -q "^${map_dir}"; then
          LOCATION_MATCH=true
          break
        fi
      fi
    done <<< "$DIR_MAP"
    if [[ "$LOCATION_MATCH" == "false" ]] && [[ "$TYPE" != "daily" ]] && [[ "$TYPE" != "log" ]]; then
      ERRORS+=("$REL_PATH: type '$TYPE' doesn't match any directory in Directory Map")
    fi
  fi

  # Naming convention — check overrides from Naming Conventions section
  CONVENTION="$DEFAULT_NAMING"
  while IFS= read -r nameline; do
    [[ -z "$nameline" ]] && continue
    [[ "$nameline" == default:* ]] && continue
    name_key=$(echo "$nameline" | sed 's/:.*//' | xargs)
    name_val=$(echo "$nameline" | sed 's/[^:]*: *//' | xargs)
    # Match if the rel path starts with a directory that matches this naming key
    if echo "$REL_PATH" | grep -q "^${name_key}"; then
      CONVENTION="$name_val"
    fi
  done <<< "$NAMING"
  if [[ "$CONVENTION" == "kebab-case" ]]; then
    echo "$FILENAME" | grep -qE '[A-Z _]' && WARNINGS+=("$REL_PATH: filename should be kebab-case")
  fi

  # Broken wikilinks
  LINKS=$(grep -oE '\[\[[^]|]+' "$filepath" 2>/dev/null | sed 's/\[\[//' | sed 's/#.*//' | sort -u || true)
  while IFS= read -r link; do
    [[ -z "$link" ]] && continue
    lower=$(to_lower "$link")
    grep -qx "$lower" "$FILE_INDEX_TMP" || WARNINGS+=("$REL_PATH: broken wikilink [[${link}]]")
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
