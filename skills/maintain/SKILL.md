---
name: maintain
description: "vault hygiene, debug critique, connect links, or restructure layout"
argument-hint: <path|debug|connect|restructure>
allowed-tools: Bash(${CLAUDE_PLUGIN_ROOT}/scripts/*)
---

!`${CLAUDE_PLUGIN_ROOT}/scripts/find-vaults.sh`

# Vault Maintenance

Scan for quality issues and fix them. Non-destructive — always previews before writing.

## Mode Selection

From `$ARGUMENTS`:
- Contains "restructure" → read `${CLAUDE_SKILL_DIR}/references/restructure-mode.md` and follow it
- Contains "connect" → read `${CLAUDE_SKILL_DIR}/references/connect-mode.md` and follow it
- Contains "debug" → run hygiene first, then read `${CLAUDE_SKILL_DIR}/references/debug-mode.md`
- File path → single file check
- Directory path → scope to that directory
- Empty → full vault scan

Always skip Excluded Directories from vault context.

## Hygiene Process

### 1. Run the scanner

Extract a **path scope** from `$ARGUMENTS` if one was provided (a file or directory path only — NOT the full user message). If `$ARGUMENTS` is natural language or a mode keyword (debug, restructure), do not pass it to the scanner.

Run via Bash as a standalone command (no `||`, `&&`, or compound operators):

```
# Full vault scan (no args or natural language input):
${CLAUDE_PLUGIN_ROOT}/scripts/scan-vault.sh

# Scoped to a specific path:
${CLAUDE_PLUGIN_ROOT}/scripts/scan-vault.sh <extracted-path>
```

Never pass raw user input as shell arguments. If scanner fails: do NOT stop. Report the error, proceed to step 2.

### 2. Manual fallback (if scanner failed)

Read schemas from schemas directory and scan manually with Grep/Glob: frontmatter, naming, wikilinks, stale dates, location/type mismatches. The skill must produce a report regardless of scanner status.

### 3. Present and offer fixes

Scanner output is grouped by severity (Errors, Warnings, Suggestions). Present it, then offer:
- "Fix all errors"
- "Fix errors and warnings"
- "Review each change"
- "Just the report"

### 4. Apply on approval

For date/status frontmatter fixes, run the batch fixer first (handles all date stamps and status sync in one pass):

```
$VAULT_ROOT/_system/scripts/fix-frontmatter.sh --batch $VAULT_ROOT
```

For remaining fixes (missing fields, naming, structural issues), edit each file individually. Show summary when done.

Note: A systemd watcher (`vault-frontmatter.service` on Pi) runs `fix-frontmatter.sh` on every file write in real time. The batch run here is a backup for anything the watcher missed.

## Rules

- ALWAYS preview changes before writing
- NEVER delete files without explicit approval
- NEVER soften debug mode findings
- In restructure mode, show full plan and wait for approval before moving files
