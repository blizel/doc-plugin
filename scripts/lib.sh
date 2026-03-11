#!/usr/bin/env bash
# Shared utilities for doc plugin scripts

# Find vault-context.md by searching up from a given path or cwd
find_vault_context() {
  local start="${1:-.}"
  local dir
  dir=$(cd "$start" 2>/dev/null && pwd || echo "$start")
  [[ -f "$dir" ]] && dir=$(dirname "$dir")

  while [[ "$dir" != "/" ]]; do
    if [[ -f "$dir/vault-context.md" ]]; then
      echo "$dir/vault-context.md"
      return 0
    fi
    dir=$(dirname "$dir")
  done
  return 1
}

# Get vault root from vault-context.md location
vault_root() {
  dirname "$1"
}

# Parse a code block from a named section in vault-context.md
# Usage: parse_section "vault-context.md" "Directory Map"
parse_section() {
  local file="$1"
  local section="$2"
  awk -v section="## $section" '
    $0 == section { found=1; next }
    found && /^```/ { if (in_code) exit; in_code=1; next }
    found && in_code { print }
    found && /^## / { exit }
  ' "$file"
}

# Get file path from hook stdin JSON or CLI argument
resolve_file_path() {
  if [[ $# -gt 0 ]]; then
    echo "$1"
  else
    jq -r '.tool_input.file_path // empty' 2>/dev/null
  fi
}
