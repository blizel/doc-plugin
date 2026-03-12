---
name: refine
description: "brainstorm and redesign rough/incomplete docs"
argument-hint: <doc-path-or-search-term>
---

!`cat vault-context.md 2>/dev/null || echo "vault-context.md not found in current directory. Copy the template from ${CLAUDE_PLUGIN_ROOT}/vault-context.md to your vault root and configure it."`

# Refine a Vault Document

Collaborative brainstorming and design. Take a rough document and work with the user to figure out what it should become. Once the plan is confirmed, read `${CLAUDE_SKILL_DIR}/references/write-document.md` and execute it inline.

<HARD-GATE>
Do NOT write the document until the plan is confirmed. Every refinement goes through brainstorming — "obvious" refinements are where unexamined assumptions cause the most wasted edits.
</HARD-GATE>

## Process

### 1. Find and read context

Resolve `$ARGUMENTS` via Glob/Grep across vault directories. If multiple matches, ask which one. If no match, offer `/doc:intake`. Read the schema from schemas directory and any `[[wikilinked]]` docs. Grep for related items by tags.

### 2. Brainstorm

**Skip if brainstorming already happened this conversation** (e.g., user just came from doc:intake).

- **Anchor:** Present current state, what you think the doc is trying to be
- **Clarify:** One question per message, prefer multiple choice, 1-3 questions
- **Propose 2-3 approaches:** Lead with recommendation, explain trade-offs, YAGNI ruthlessly

If the user rejects proposals twice, read `${CLAUDE_SKILL_DIR}/references/ultra-refine.md` for workshop techniques to break through the stall.

### 3. Converge on a plan

Present design scaled to the doc type:

| Type | Cover |
|------|-------|
| Task | finish condition, context, effort, parent project |
| Project | goal, scope, phased checklist, references, success criteria |
| Knowledge | summary, key sections, sources |
| Writing | thesis, audience, outline, tone |

The plan should include: sections/content, structural decisions, frontmatter updates, `[[wikilinks]]` to add.

### 4. Confirm and execute

Get explicit approval. Then read `${CLAUDE_SKILL_DIR}/references/write-document.md` and execute it — translating the plan into a vault-ready document.

**Next step:** For projects, suggest `/doc:plan`. Otherwise done.

## Rules

- NEVER skip brainstorming, even for "simple" docs
- NEVER write the document before the plan is confirmed
- ALWAYS read schemas at runtime from the schemas directory
