---
name: search
description: "Use when looking for existing vault documents by keywords, tags, status, or type."
argument-hint: <search-query>
---

!`cat vault-context.md 2>/dev/null || echo "vault-context.md not found in current directory. Copy the template from ${CLAUDE_PLUGIN_ROOT}/vault-context.md to your vault root and configure it."`

# Search the Vault

Find existing documents by keywords, tags, status, or type. Uses the vault root and directory map from vault context above.

## Process

### 1. Parse the query

Extract from `$ARGUMENTS`:
- **Keywords** — free text to match against filenames, titles, and content
- **Filters** (if provided with `--` prefix):
  - `--tag <tag>` — match frontmatter `tags` field
  - `--status <status>` — match frontmatter `status` field
  - `--type <type>` — match frontmatter `type` field (task, project, knowledge, writing, daily, horizon)
  - `--all` — include completed and archived items (excluded by default)
- If no `--` flags, treat the entire argument as keywords

### 2. Search

Run these in parallel using Glob and Grep:

**Filename matching:**
- Glob for `**/*keyword*.md` across all vault directories from vault context

**Frontmatter matching:**
- Grep for keywords in `tags:`, `title:`, and `project:` lines
- If `--tag` filter: Grep for the exact tag value
- If `--status` filter: Grep for `status: <value>`
- If `--type` filter: Grep for `type: <value>`

**Content matching:**
- Grep for keywords in file bodies

**Always exclude:** directories listed in the Excluded Directories section of vault context
**Exclude by default (unless `--all`):** completed/done and archived/shipped directories

### 3. Rank and present

Deduplicate results. Files matching in multiple strategies rank higher. Cap at 15 results.

For each match, read the file to extract:
- **Path** (relative to vault root)
- **Title** (from frontmatter)
- **Type** and **Status** (from frontmatter)
- **Tags** (from frontmatter)
- **Summary** (first non-empty line after frontmatter, or first heading)

Present as a table:

```
| # | Path | Title | Type | Status | Tags |
|---|------|-------|------|--------|------|
```

With one-line summaries below.

### 4. Follow-up

If the user asks for more detail on a result, read and present the full file.

## No Results

If nothing matches:
- Suggest broader keywords
- Offer `--all` to include completed/archived items
- Offer `/doc:intake` if the user wants to create something new
