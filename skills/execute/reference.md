# execute Reference

## Log File Format

Each project gets one log file in its folder, named `<Title> Log.md` in sentence case (e.g., `my-project/My Project Log.md`). Entries are reverse-chronological (newest first), free-form narrative under date headings.

### Frontmatter

```yaml
---
type: log
project: "Project Title"
tags: [session-log]
created: YYYY-MM-DD
updated: YYYY-MM-DD
---
```

- `type: log` — distinct note type for session logs
- `project` — must match the parent project's title (required)
- `tags` — always includes `session-log`, plus inherits tags from the parent project on creation
- `updated` — bump on every log entry

### Entry Format

```markdown
## 2026-03-01

Built the search endpoint and wired it into the API router. Hit a
pagination issue with large result sets — switched from offset to
cursor-based. Disabled rate limiting temporarily while debugging
response times.

Left off: search working but needs tests. Rate limiting needs re-enabling.
```

- Multiple entries on the same date: append under the existing date heading
- New dates: insert above previous entries (reverse-chronological)

## Project Initialization

Project folder structure (promotion from single-file, overview, phase docs, log) is created by `/doc:plan`. Execute expects an initialized project folder. If execute encounters a single-file project, it redirects to `/doc:plan`.
