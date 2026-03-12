---
name: plan
description: "break project into phased task checklists"
argument-hint: <project-path-or-search-term>
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

### 3. Write on approval

Write into the project doc under `## Tasks`:

```markdown
### Phase 1 — [Name]
- [ ] Task one
- [ ] Task two
```

Preserve already-checked items. Update `updated` date.

**Next step:** Suggest `/doc:execute` to start working.

## Rules

- NEVER design or brainstorm — redirect to `/doc:refine`
- NEVER propose more than 4 phases — split into multiple projects instead
- ALWAYS preserve completed tasks when rewriting a plan
