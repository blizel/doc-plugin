---
name: refine
description: "Use when a vault document is rough, incomplete, or needs restructuring — projects missing checklists, knowledge docs with raw notes, tasks needing clarity."
argument-hint: <doc-path-or-search-term>
---

!`cat vault-context.md 2>/dev/null || echo "vault-context.md not found in current directory. Copy the template from ${CLAUDE_PLUGIN_ROOT}/vault-context.md to your vault root and configure it."`

# Refine a Vault Document

Collaborative brainstorming and design. Take a rough or incomplete vault document and work with the user to figure out what it should become. Once the plan is confirmed, read `${CLAUDE_SKILL_DIR}/references/write-document.md` and execute it inline — it's part of this skill, not a separate one.

<HARD-GATE>
Do NOT format, restructure, or write the document. Your job ends at a confirmed plan. This applies to EVERY document regardless of perceived simplicity.
</HARD-GATE>

## Anti-Pattern: "This Doc Just Needs Formatting"

Every refinement goes through brainstorming. "Obvious" refinements are where unexamined assumptions cause the most wasted edits. The brainstorm can be brief, but it must happen.

## Process

### 1. Find and read context

- `$ARGUMENTS` may be a file path, search term, or natural language description
- Resolve using vault wayfinding: Glob for filename matches, Grep for frontmatter/content. Search across vault directories from vault context
- If multiple matches, present them and ask which one
- If no match, say so — offer `/doc:intake` if the user wants to create something new
- Read the schema from the schemas directory and any `[[wikilinked]]` documents
- Quick Grep for related items by tags or key terms

### 2. Brainstorm

**Skip if brainstorming already happened this conversation** (e.g., the user just came from doc:intake and already discussed what this should be). Go straight to step 3.

**Anchor:** Present current state — what exists, what's rough. State what you think the doc is trying to be.

**Clarify:** One question per message. Prefer multiple choice. Focus on purpose, constraints, success criteria. Usually 1-3 questions.

**Propose 2-3 approaches:** Lead with recommendation, explain trade-offs. YAGNI ruthlessly.

**Track rejections.** If the user rejects your proposal twice, enter Ultra-Refine mode (step 2b).

### 2b. Ultra-Refine

When brainstorming stalls (2+ rejected proposals), deploy one workshop at a time to break through. Pick the workshop that targets the specific failure mode:

| Workshop | When to use | Prompt |
|----------|------------|--------|
| **Inversion** | Proposals feel directionless | "What would make this document actively harmful? Let's flip the problem." |
| **Concrete Example** | Too abstract, can't commit | "Walk me through one specific scenario where someone uses this." |
| **Five-Year-Old** | Overcomplicated, scope creep | "Explain what this document is for to a five-year-old." |
| **Before/After** | Unclear value | "What does the user's workflow look like before and after this doc exists?" |
| **Worst Version** | Perfectionism blocking progress | "What's the laziest, most half-assed version that would still be useful?" |
| **Audience Test** | No clear reader | "Who specifically will read this, and what will they do differently after?" |
| **Kill Test** | Might not be needed at all | "Should this document exist at all? What happens if we just delete it?" |

Rules for Ultra-Refine:
- Deploy ONE workshop at a time — don't stack them
- Wait for the user's response before choosing the next workshop
- If Kill Test concludes the doc shouldn't exist, hand off to `/doc:maintain` for cleanup
- Exit Ultra-Refine as soon as you have enough clarity to make a proposal the user accepts

### 3. Converge on a plan

Present the refined design by doc type:

| Type | Cover |
|------|-------|
| Task | finish condition, context, effort, parent project |
| Project | goal, scope, phased checklist, references, success criteria |
| Knowledge | summary, key sections, sources, include/exclude |
| Writing | thesis, audience, outline, tone |

Scale detail to complexity. Ask if each element looks right. Loop back if needed.

**The plan should include:**
- What the document will contain (sections, key content)
- Structural decisions (stays as-is, promoted to folder, type change)
- Frontmatter updates (status, tags, new fields)
- Related docs to link via `[[wikilinks]]`

### 4. Confirm and hand off

Get explicit approval of the plan. Then read `${CLAUDE_SKILL_DIR}/references/write-document.md` and execute it — translating the confirmed plan into a vault-ready document.

**Next step:** For projects, suggest `/doc:plan` to structure implementation phases. For other types, the work is done.

## Rules

- NEVER skip brainstorming, even for "simple" docs
- NEVER move past brainstorming without user approval
- NEVER write the document yourself before the plan is confirmed — then read and execute write-document.md inline
- ALWAYS read schemas at runtime from the schemas directory in vault context
- Track rejection count internally — trigger Ultra-Refine at 2+
