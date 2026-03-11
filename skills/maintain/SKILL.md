---
name: maintain
description: "Use when vault quality may have drifted — after bulk edits, periodic hygiene checks, or when frontmatter, tag, or formatting issues are suspected. Use 'doc:maintain debug' for aggressive self-critique mode."
argument-hint: <optional-path-scope>
---

!`cat vault-context.md 2>/dev/null || echo "vault-context.md not found in current directory. Copy the template from ${CLAUDE_PLUGIN_ROOT}/vault-context.md to your vault root and configure it."`

# Vault Maintenance

Scan the vault for quality issues and fix them. Non-destructive — always previews changes before writing.

Two modes:
- **Hygiene mode** (default) — scan for structural and frontmatter issues
- **Debug mode** (`$ARGUMENTS` contains "debug") — aggressive self-critical pass for when the vault feels off

## Process

### 1. Determine mode and scope

- If `$ARGUMENTS` contains "debug": enter Debug Mode (step 7)
- If `$ARGUMENTS` is a file path: single file mode (check just that file)
- If `$ARGUMENTS` is a directory path: scope to that directory
- If no arguments: scan the full vault
- Always skip directories listed in vault context's Excluded Directories

### 2. Run the scanner

The vault scanner handles all mechanical checks (frontmatter, naming, wikilinks, stale dates, location/type mismatches). Its output is pre-loaded below — skip to step 4 if results are present.

If not pre-loaded, run it manually:

!`${CLAUDE_PLUGIN_ROOT}/scripts/scan-vault.sh $ARGUMENTS 2>/dev/null || echo "Scanner not available — fall back to manual Grep/Glob scanning."`

### 3. Load schemas (if scanner unavailable)

Only needed if the scanner didn't run. Read ALL schemas from the schemas directory in vault context and manually scan with Grep/Glob for the same checks the scanner covers: frontmatter, naming, wikilinks, stale dates, location/type mismatches.

### 4. Present the report

The scanner output is already grouped by severity (Errors, Warnings, Suggestions). Present it to the user. If you have additional findings from schema validation that the scanner can't do (e.g., frontmatter fields not in the schema, possible typos), append those.

### 5. Offer fix options

- "Fix all errors" — apply error fixes
- "Fix errors and warnings" — apply both
- "Review each change" — approve individually
- "Just the report" — informational only

### 6. Apply on approval

- Edit each file
- Update `updated` date on modified files
- Show summary of what changed

---

## 7. Debug Mode

Triggered by `/doc:maintain debug` or when the user says the vault "feels off." This is an aggressive self-critical pass that goes beyond hygiene.

### 7a. Deep scan

Everything from hygiene mode, plus:

- **Contradictions** — docs that describe the same thing differently, outdated procedures that no longer match reality
- **Unrealistic projects** — active/backlog projects with no progress in 90+ days, projects with no clear goal or finish condition
- **Orphaned docs** — files that nothing links to and that link to nothing
- **Stale knowledge** — tech docs describing tools/services/configs that may have changed
- **Scope creep** — projects that have grown beyond their original design without being restructured

### 7b. Present findings

Be direct and critical. Don't soften the message:

```
## Kill candidates
- projects/backlog/old-idea.md — no activity in 6 months, vague goal, no tasks. Archive or delete?
- knowledge/tech/old-setup.md — describes a service that was decommissioned

## Contradictions
- knowledge/tech/dns.md says X, but knowledge/tech/infra.md says Y

## Stale
- projects/active/big-project.md — last log entry 4 months ago, 2/12 tasks done

## Vault context drift
- vault-context.md says schemas are at _system/schemas/ but that directory has new files not reflected in the context
```

### 7c. Suggest actions

For each finding, suggest one of:
- **Archive** — move to a completed/shipped/archive directory
- **Delete** — remove entirely (only for truly worthless docs)
- **Merge** — combine with another doc
- **Update** — bring content current
- **Refine** — hand off to `/doc:refine` for redesign
- **Split** — break into smaller, focused docs

### 7d. Update vault context

If debug mode reveals that vault-context.md doesn't match vault reality (new directories, changed schemas, outdated conventions), update vault-context.md to match.

## What This Skill Does NOT Do

- Auto-delete or auto-move files without approval
- Change `status` fields without asking (stale items are reported, not auto-updated)
- Modify note content — only frontmatter, wikilinks, and tag formatting (hygiene mode)
- Touch excluded directories

## Rules

- ALWAYS preview changes before writing
- NEVER delete files without explicit approval
- NEVER soften debug mode findings — be direct about what's wrong
- In debug mode, vault-context.md updates are part of the findings, not silent changes
