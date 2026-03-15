# Connect Mode

Surface missing `[[wikilinks]]` and related notes across the vault. Can run vault-wide or scoped to a single note.

## Process

### 1. Build the title index

Glob `**/*.md` across vault directories from vault context (skip Excluded Directories, skip `tasks/completed/` in vault-wide mode). For each file, extract:
- `title` from frontmatter + filename (sans `.md`) as matchable identifiers
- `tags` array from frontmatter
- Existing `[[wikilinks]]` in the body

**Normalize for matching:** lowercase everything, treat hyphens and spaces as equivalent.

### 2. Detect missing wikilinks

For each note in scope, search the body for plain-text mentions of other notes' titles/filenames. Skip matches inside existing `[[...]]`, frontmatter, or code blocks.

Record: source file, line number, matched text, target note. If both filename and title match the same target, report once using the title form.

### 3. Find tag-based connections

Find note pairs sharing 2+ tags that aren't already wikilinked. Rank by shared tag count. Deduplicate reciprocal pairs in vault-wide mode.

### 4. Present results

```
## Missing Wikilinks (N suggestions)
1. path/to/source.md (line 12): "backup procedures" → [[backup-procedures]]

## Related Notes (N suggestions)
1. tasks/some-task.md ↔ knowledge/tech/some-ref.md
   Shared tags: homelab, observability (2)
```

Number each suggestion for easy reference.

### 5. Actions

- **"Apply wikilinks"** — replace plain-text with `[[wikilinks]]`, update `updated` date
- **"Apply specific ones"** — user picks by number
- **"Dig deeper on [note]"** — read the note and all tag-related notes, analyze thematic relationships beyond surface matches, present additional connections with explanations
- **"Just the report"** — no changes

## Rules

- NEVER modify files without showing suggestions first
- NEVER add tags or change frontmatter beyond `updated` date
- Use `[[wikilinks]]` with filename (sans `.md`), not full path
- Flag ambiguous matches for user to choose
