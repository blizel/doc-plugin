---
name: search
description: "find vault docs by keyword/tag/status/type"
argument-hint: <search-query>
---

!`${CLAUDE_PLUGIN_ROOT}/scripts/find-vaults.sh`

# Search the Vault

Find documents by keywords, tags, status, or type using vault root and directory map from vault context above.

## Process

### 1. Parse the query

Extract from `$ARGUMENTS`:
- **Keywords** — free text to match against filenames, titles, content
- **Filters** (`--tag`, `--status`, `--type`, `--all` to include completed/archived)
- No `--` flags → treat entire argument as keywords

### 2. Search (run in parallel)

- **Glob** `**/*keyword*.md` across vault directories
- **Grep** keywords in `tags:`, `title:`, `project:` frontmatter lines
- **Grep** keywords in file bodies
- Apply filters if provided
- Skip Excluded Directories from vault context
- Exclude completed/done/archived/shipped by default unless `--all`

### 3. Present

Deduplicate, rank by match count, cap at 15. Read each match to extract title, type, status, tags, first content line.

| # | Path | Title | Type | Status | Tags |
|---|------|-------|------|--------|------|

### 4. Follow-up

- Detail on a result → read and present full file
- No results → suggest broader keywords, `--all`, or `/doc:intake`
