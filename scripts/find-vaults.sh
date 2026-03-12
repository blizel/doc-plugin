#!/usr/bin/env bash
# Find and output all vault-context.md files reachable from cwd.
# Used as dynamic injection in skills: !`${CLAUDE_PLUGIN_ROOT}/scripts/find-vaults.sh`
#
# Discovery order:
#   1. $DOC_VAULT env var (explicit override — single path)
#   2. ~/.config/doc-plugin/vaults  (registered vault paths, one per line)
#   3. Search upward from cwd       (finds the vault you're inside)
#   4. Check child directories       (finds sibling vaults from a parent)
#
# If nothing is found, outputs a prompt for Claude to ask the user.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/lib.sh" 2>/dev/null || { echo "ERROR: Failed to source lib.sh" >&2; exit 1; }

VAULTS_CONFIG="${HOME}/.config/doc-plugin/vaults"
VAULTS=()
SEEN_PATHS=""  # newline-delimited dedup list

add_vault() {
  local ctx="$1"
  [[ -f "$ctx" ]] || return 1
  local real
  real=$(realpath "$ctx" 2>/dev/null || echo "$ctx")
  case "$SEEN_PATHS" in
    *"$real"*) return 0 ;;  # already seen
  esac
  SEEN_PATHS="${SEEN_PATHS}${real}"$'\n'
  VAULTS+=("$ctx")
}

# 1. Explicit override via env var
if [[ -n "${DOC_VAULT:-}" ]]; then
  if [[ -f "$DOC_VAULT/vault-context.md" ]]; then
    add_vault "$DOC_VAULT/vault-context.md"
  elif [[ -f "$DOC_VAULT" ]] && [[ "$(basename "$DOC_VAULT")" == "vault-context.md" ]]; then
    add_vault "$DOC_VAULT"
  fi
fi

# 2. Registered vaults from config file
if [[ -f "$VAULTS_CONFIG" ]]; then
  while IFS= read -r line; do
    line="${line%%#*}"        # strip comments
    line="$(echo "$line" | xargs)"  # trim whitespace
    [[ -z "$line" ]] && continue
    expanded=$(eval echo "$line" 2>/dev/null || echo "$line")  # expand ~
    [[ -f "$expanded/vault-context.md" ]] && add_vault "$expanded/vault-context.md"
  done < "$VAULTS_CONFIG"
fi

# 3. Search upward from cwd
if ctx=$(find_vault_context "."); then
  add_vault "$ctx"
fi

# 4. Check immediate child directories
for child in */vault-context.md; do
  [[ -f "$child" ]] || continue
  add_vault "$child"
done

# --- No vaults found: tell Claude to ask the user ---
if [[ ${#VAULTS[@]} -eq 0 ]]; then
  cat <<'PROMPT'
⚠ **No vault found.** Auto-discovery searched upward from the working directory and checked child directories but found no `vault-context.md`.

**Ask the user where their vault is.** Once they provide a path, verify that `vault-context.md` exists there. If it doesn't, offer to copy the template:

```
cp "${CLAUDE_PLUGIN_ROOT}/vault-context.md" /path/to/their/vault/
```

Then tell them they can register it permanently so the plugin always finds it:

```
mkdir -p ~/.config/doc-plugin
echo "/path/to/their/vault" >> ~/.config/doc-plugin/vaults
```

Or set `DOC_VAULT=/path/to/their/vault` in their shell profile for a single default vault.

**Do not proceed with the skill until a vault is resolved.**
PROMPT
  exit 0
fi

# --- Output vault context(s) ---
if [[ ${#VAULTS[@]} -eq 1 ]]; then
  cat "${VAULTS[0]}"
else
  echo "**${#VAULTS[@]} vaults detected.** Ask the user which vault to work in if the skill target is ambiguous."
  echo ""
  for i in "${!VAULTS[@]}"; do
    ctx="${VAULTS[$i]}"
    root=$(dirname "$ctx")
    echo "---"
    echo "## Vault $((i+1)): $root"
    echo "---"
    cat "$ctx"
    echo ""
  done
fi
