# doc — Document Lifecycle Plugin for Claude Code

A Claude Code plugin that gives any Obsidian or markdown vault a complete document lifecycle: **capture → refine → plan → execute → maintain**.

## Skills

| Skill | Command | Purpose |
|---|---|---|
| Intake | `/doc:intake` | Fast capture — classifies input and places it in the right directory with frontmatter |
| Search | `/doc:search` | Find docs by keyword, tag, status, or type; excludes archived by default |
| Refine | `/doc:refine` | Guided brainstorming — asks questions, proposes approaches, then writes on approval |
| Plan | `/doc:plan` | Break a project into 2–4 phased task checklists with done conditions |
| Execute | `/doc:execute` | Start/resume/wrap work sessions with log entries and knowledge doc sync |
| Maintain | `/doc:maintain` | Hygiene scans, wikilink connection, restructuring, and debug critique mode |

## Installation

### From marketplace

```
/plugin marketplace add blizel/doc-plugin
/plugin install doc@doc-vault
```

### Local development

```bash
claude --plugin-dir ./doc-plugin
```

## Setup

1. Copy `vault-context.md` to the root of your vault
2. Edit it to match your vault's directory structure, schema paths, and conventions
3. Run Claude Code from your vault root directory

The plugin reads `vault-context.md` at runtime to understand your vault's layout. No hardcoded paths.

## Hooks

The plugin registers three PostToolUse hooks that run automatically after every `Write` or `Edit`:

| Hook | Script | What it does |
|---|---|---|
| Auto-date | `auto-date.sh` | Bumps the `updated` frontmatter field to today's date |
| Sync status | `sync-status.sh` | Sets the `status` field based on the file's directory |
| Validate | `validate-file.sh` | Checks required frontmatter and naming conventions |

## Lifecycle Flow

```
intake → refine → plan → execute → refine (iterate)
                           ↘ maintain (when vault feels off)
```

Each skill suggests the natural next step when it completes.

## License

MIT
