---
name: intake
description: "Use when the user has ideas, tasks, or reference material to capture into the vault — one item or many at once. Can also update existing docs. Trigger phrases: 'intake', 'capture this', 'log this', or any message that starts with an idea/task/fix description without an explicit skill invocation."
argument-hint: <ideas>
---

!`cat vault-context.md 2>/dev/null || echo "vault-context.md not found in current directory. Copy the template from ${CLAUDE_PLUGIN_ROOT}/vault-context.md to your vault root and configure it."`

# Idea Intake

Fast, accurate capture. Your job is to understand what the user is saying, place it correctly in the vault, and set up the agenda for refinement. You are not designing or structuring documents — you are triaging and placing.

## Before You Start

Read the vault context above for directory structure and conventions. Read the relevant schema(s) from the schemas directory once you know the document type(s).

## The Loop

### 1. Listen and parse

From `$ARGUMENTS` or conversation, identify each distinct idea: core concept and size (task, multi-step, reference). If ambiguous, ask ONE clarifying question.

### 2. Classify

| Type | Sounds like... | Goes to |
|------|---------------|---------|
| task | Single doable thing | tasks directory |
| project | Multiple steps/phases | projects backlog directory |
| knowledge | Facts, reference, how-to | knowledge directory |
| writing | Something to share/publish | writing drafts directory |
| horizon | Direction or goal | horizons directory |

When in doubt: **task**. Promote later via `doc:refine`.

### 3. Vault check — exist or create?

Search for existing docs that match the idea: Grep/Glob for similar titles, tags, filenames across vault directories.

- **Close match found:** Present it. Ask: "This looks related to [[existing-doc]] — should I add to that, or create something new?"
- **Loose matches:** Mention them as related context, proceed with new doc
- **No matches:** Proceed with new doc

This is a real decision point, not a courtesy check. Capturing a duplicate is worse than asking one question.

### 4. Place the seed

Read the schema from the schemas directory for the target type (e.g., `<schemas>/task.md`).

Create a minimal seed doc — just enough to exist correctly in the vault:
- **Frontmatter:** type, title, tags (2-5), status (initial: task=`todo`, project=`paused`, writing=`idea`), created/updated dates
- **Filename:** Follow the naming conventions from vault context
- **Body:** The user's raw captured notes/ideas, lightly cleaned up but NOT restructured or designed. Add `[[wikilinks]]` to related docs found in step 3.

The seed is a placeholder, not a finished document. Don't structure it, don't add sections, don't design it.

### 5. Present and route

Show proposed file path + seed document for each item. Then route:

- **Trivial capture** (a single fact, a bare task with obvious finish condition): "Save this?" — write as-is, done.
- **Needs design** (single item): "Save and refine?" — write the seed, then suggest `doc:refine`.
- **Needs design** (batch): "Save these? I'd suggest refining [x, y, z] next." — write all seeds, let the user invoke `doc:refine` when ready.

### 6. Write on approval

Write to create new files, Edit to update existing (preserve file, update `updated` date). Confirm what was written.

**Next step:** For docs that need design, suggest `/doc:refine <path>`.

## Updating Existing Docs

Find doc → read it → propose change → show diff → apply on approval → update `updated` date.

## Rules

- NEVER write without showing the user first
- NEVER hardcode paths — always use vault context
- NEVER structure or design document content — that's doc:refine's job
- Use `[[wikilinks]]` for cross-references
- Today's date for `created` and `updated`
- Keep it conversational
