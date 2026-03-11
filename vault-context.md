# Vault Context

Configuration file for the doc plugin. Copy this to the root of your vault and edit it to match your setup. Skills read this file at runtime to understand your vault's layout.

## Vault Root

The absolute path to your vault. If you always launch Claude Code from your vault root, use `.`

```
path: ~/my-vault
```

## Directory Map

Where document types live, relative to vault root. Remove lines you don't use, add custom ones.

```
tasks: tasks/
tasks_done: tasks/completed/
projects_backlog: projects/backlog/
projects_active: projects/active/
projects_shipped: projects/shipped/
knowledge: knowledge/
writing_drafts: writing/drafts/
writing_published: writing/published/
horizons: odyssey/
```

## Schemas

Path to frontmatter schema files, relative to vault root. Each schema is a markdown file named `<type>.md` (e.g., `task.md`, `project.md`). Remove this section if you don't use schemas.

```
schemas: _system/schemas/
```

## Naming Conventions

How files should be named in each area.

```
default: kebab-case
tasks: prose with spaces
writing: prose with spaces
```

## Status Map

Maps directories to frontmatter status values. When a file lives in a mapped directory, the sync hook updates its `status` field automatically. Longest path match wins.

```
projects/backlog/: paused
projects/active/: active
projects/shipped/: completed
tasks/: todo
tasks/completed/: done
writing/drafts/: draft
writing/published/: published
```

## Excluded Directories

Directories to skip during search and maintenance scans.

```
- .stversions/
- _system/
- .claude/
- _attachments/
```

## Notes

Add vault-specific conventions here — tagging rules, wikilink style, workflow quirks, or anything skills should know.
