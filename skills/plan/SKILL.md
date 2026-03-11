---
name: plan
description: "Use when a project needs structured implementation phases — breaking a designed project into actionable, ordered task checklists."
argument-hint: <project-path-or-search-term>
---

!`cat vault-context.md 2>/dev/null || echo "vault-context.md not found in current directory. Copy the template from ${CLAUDE_PLUGIN_ROOT}/vault-context.md to your vault root and configure it."`

# Plan a Vault Project

Take a designed project and structure it into phased implementation checklists. You are not designing — the design is already done (via `doc:refine`). You are breaking it into executable chunks.

## Process

### 1. Find and read context

- `$ARGUMENTS` may be a file path, search term, or project name
- Resolve using vault wayfinding: Glob for filename matches, Grep for frontmatter/content. Search project directories from vault context
- Read the project doc — look for design decisions, scope, goals
- If the project has no clear design or goal, suggest `/doc:refine` first

### 2. Analyze scope

- Identify all discrete work items from the project doc
- Map dependencies between them
- Note what's riskiest or most uncertain
- Check for existing partial work (completed tasks, prior log entries)

### 3. Propose phases

Present 2-4 phases, each with:
- **Phase name and goal** — what this phase accomplishes
- **Checkbox tasks** in execution order
- **Dependencies** on previous phases
- **Done condition** — what "finished" looks like for this phase

Principles:
- Each phase should deliver something independently valuable
- Front-load the hardest or riskiest work
- Keep phases small enough for one focused work session
- Tasks should be concrete and verifiable — no vague "improve X"
- If a task is too big, break it into subtasks

### 4. Confirm and write

Get explicit approval of the phased plan. Then write it into the project doc under a `## Tasks` section using checkbox format:

```markdown
### Phase 1 — [Name]
- [ ] Task one
- [ ] Task two

### Phase 2 — [Name]
- [ ] Task three
- [ ] Task four
```

If the project doc already has a Tasks section, replace it with the new phased plan (preserve any already-checked items).

Update the project's `updated` date.

### 5. Hand off

Suggest: "Ready to start working? Try `/doc:execute`."

## Rules

- NEVER design or brainstorm — that's doc:refine's job. If the project isn't ready, redirect there.
- NEVER propose more than 4 phases — if the project is that big, it should be split into multiple projects
- NEVER write vague tasks — every checkbox should have a clear finish condition
- ALWAYS preserve completed tasks when rewriting a plan
- ALWAYS read the project doc before proposing phases
