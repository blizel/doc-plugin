# execute Reference

## Log File Format

Each project gets one log file in its folder, named `<project-folder>-log.md` (e.g., `my-project/my-project-log.md`). Entries are reverse-chronological (newest first), free-form narrative under date headings.

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

## Single-File Project Promotion

Projects without a folder get promoted when the first log entry is written:

```
Before:
  projects/backlog/my-project.md

After:
  projects/backlog/my-project/my-project.md       (moved)
  projects/backlog/my-project/my-project-log.md   (created)
```

Steps:
1. Create the project folder: `mkdir -p <project-dir>/<project-name>/`
2. Move the project file into it — filename stays the same as the folder
3. Create `<project-name>-log.md` with frontmatter
4. Wikilinks don't need updating if the vault editor resolves by filename (Obsidian does)
