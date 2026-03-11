# Write Document

Mechanical translation of a confirmed plan into a vault-ready document. You are not designing — the plan is already approved. Your job is accurate, schema-compliant execution.

## Prerequisites

You should have:
- A confirmed plan from the brainstorming phase (what the doc contains, its structure, key decisions)
- The target document (existing file to edit, or path for a new file)
- The relevant schema already read from the schemas directory in vault context

## Process

### 1. Build frontmatter

From the confirmed plan and schema:
- Fill all required schema fields
- Add optional fields only when they have a value
- Set appropriate status
- Set `updated` to today's date
- Apply 2-5 tags from the plan

### 2. Structure content by type

**Task:**
- Finish condition (one clear sentence)
- Context (brief — why this matters, what triggered it)
- Parent project link if applicable

**Project:**
- Goal (2-3 sentences)
- Tasks (phased checkboxes from the plan)
- Reference (`[[wikilinks]]` to related docs)
- Notes (anything else from the plan)

**Knowledge:**
- Summary (one-line, also goes in frontmatter `summary` field if schema supports it)
- Structured sections per the plan
- Sources if applicable

**Writing:**
- Thesis/angle
- Outline from the plan
- Draft content if the plan included it

Add `[[wikilinks]]` to all related docs identified during brainstorming.

### 3. Handle promotions

**Type promotion:** If the plan calls for changing the doc type (e.g., task → project), build the new frontmatter for the target type, migrate content, propose the new file path per vault context conventions.

**Folder promotion:** If a project needs multiple artifacts, promote to project folder:
- Main project doc as `<folder-name>.md`
- Subdirectories for artifacts
- Move existing related docs into the folder
- Update wikilinks in referencing docs

### 4. Present diff

Show the user:
- Original → refined (side-by-side or diff format)
- Complete final document
- Any new files being created
- Any files being moved
- Wikilink additions to other docs

Ask: "Apply these changes?"

### 5. Apply on approval

- **Edit** to update existing files (preserves file identity)
- **Write** for new files
- Add `[[wikilinks]]` to related docs that should reference this one
- Update `updated` date on every touched file

### 6. Hand off

If the document is a project with actionable tasks, offer: "Ready to structure this into phases? Try `/doc:plan`."

For non-project docs, the work is done — confirm what was written.
