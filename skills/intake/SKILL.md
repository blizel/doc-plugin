---
name: intake
description: "capture ideas/tasks/notes into vault"
argument-hint: <ideas>
---

!`cat vault-context.md 2>/dev/null || echo "vault-context.md not found in current directory. Copy the template from ${CLAUDE_PLUGIN_ROOT}/vault-context.md to your vault root and configure it."`

# Idea Intake

Fast capture. Understand what the user is saying, place it correctly, set up for refinement. You are triaging and placing, not designing or structuring.

Read vault context above for directory structure and conventions. Read the relevant schema(s) from the schemas directory once you know the document type(s).

## Process

### 1. Parse and classify

From `$ARGUMENTS` or conversation, identify each distinct idea. If ambiguous, ask ONE clarifying question.

| Type | Sounds like... | Goes to |
|------|---------------|---------|
| task | Single doable thing | tasks directory |
| project | Multiple steps/phases | projects backlog directory |
| knowledge | Facts, reference, how-to | knowledge directory |
| writing | Something to share/publish | writing drafts directory |
| horizon | Direction or goal | horizons directory |

When in doubt: **task**. Promote later via `/doc:refine`.

### 2. Check for duplicates

Grep/Glob for similar titles, tags, filenames across vault directories.

- **Close match:** "This looks related to [[existing-doc]] — add to that, or create new?"
- **Loose matches:** Mention as context, proceed with new doc
- **No matches:** Proceed

Duplicate capture is worse than asking one question.

### 3. Place the seed

Read the schema for the target type from the schemas directory. Create a minimal seed:
- **Frontmatter:** type, title, tags (2-5), status (task=`todo`, project=`paused`, writing=`idea`), created/updated dates
- **Filename:** Per naming conventions from vault context
- **Body:** User's raw notes, lightly cleaned, NOT restructured. Add `[[wikilinks]]` to related docs.

### 4. Present and route

Show proposed file path + seed. Then:
- **Trivial capture:** "Save this?" — write as-is
- **Needs design:** "Save and refine with `/doc:refine`?"

### 5. Write on approval

Write new files, Edit existing (preserve file, update `updated` date). For existing docs: read → propose change → show diff → apply on approval.

## Rules

- NEVER write without showing the user first
- NEVER hardcode paths — always use vault context
- NEVER structure or design content — that's `/doc:refine`'s job
- Use `[[wikilinks]]` for cross-references, today's date for created/updated
