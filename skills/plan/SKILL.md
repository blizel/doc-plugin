---
name: plan
description: "break project into phased task checklists"
argument-hint: <project-path-or-search-term>
allowed-tools: Bash(${CLAUDE_PLUGIN_ROOT}/scripts/*)
---

!`${CLAUDE_PLUGIN_ROOT}/scripts/find-vaults.sh`

# Plan a Vault Project

Break a designed project into phased implementation checklists. You are not designing — the design is done (via `/doc:refine`). If the project has no clear design or goal, redirect to `/doc:refine` first.

## Process

### 1. Find and read

Resolve `$ARGUMENTS` via Glob/Grep across project directories from vault context. Read the project doc for design decisions, scope, goals. Check for existing partial work.

### 2. Analyze and propose phases

Identify discrete work items, map dependencies, note risks. Present 2-4 phases:
- **Phase name and goal** — what it accomplishes
- **Checkbox tasks** in execution order
- **Done condition** — what "finished" looks like

Principles: each phase delivers independent value, front-load risk, keep phases session-sized, tasks must be concrete and verifiable.

### 3. Evaluate phase docs

If a phase is substantial enough to be its own body of work (multiple sub-tasks, its own context/decisions, would benefit from independent tracking), propose splitting it into a separate phase doc: `<Title> Phase N - Name.md` in the project folder. Phase docs mention blocking dependencies on other phases in their content.

Lightweight phases stay inline in the project overview.

### 4. Write on approval — initialize the project

On approval, scaffold the full project structure:

1. **Promote to folder** (if single-file):
   - Create `<project-dir>/<kebab-name>/`
   - Move the project file in, renaming to `<Title> Overview.md` (sentence case)

2. **Write the overview** with phases under `## Tasks`:

   ```markdown
   ### Phase 1 — [Name]
   - [ ] Task one
   - [ ] Task two
   ```

3. **Create phase docs** for substantial phases: `<Title> Phase N - Name.md` with its own frontmatter (`type: project`, same tags as parent, links back to overview). The overview links to phase docs with `[[wikilinks]]`.

4. **Create the log file**: `<Title> Log.md` with frontmatter (see execute skill's reference for format).

Preserve already-checked items. Update `updated` date.

The project is now initialized and ready to browse in Obsidian before any work begins.

**Next step:** Suggest `/doc:execute` to start working.

## Rules

- NEVER design or brainstorm — redirect to `/doc:refine`
- NEVER propose more than 4 phases — split into multiple projects instead
- ALWAYS preserve completed tasks when rewriting a plan
