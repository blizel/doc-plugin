---
name: maintain
description: "vault hygiene, debug critique, or restructure layout"
argument-hint: <path|debug|restructure>
---

!`cat vault-context.md`

# Vault Maintenance

Scan for quality issues and fix them. Non-destructive — always previews before writing.

## Mode Selection

From `$ARGUMENTS`:
- Contains "restructure" → read `${CLAUDE_SKILL_DIR}/references/restructure-mode.md` and follow it
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

Edit each file, update `updated` dates, show summary.

## Rules

- ALWAYS preview changes before writing
- NEVER delete files without explicit approval
- NEVER soften debug mode findings
- In restructure mode, show full plan and wait for approval before moving files
