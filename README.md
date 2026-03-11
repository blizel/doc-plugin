# doc — Document Lifecycle Plugin for Claude Code

A Claude Code plugin that gives any Obsidian or markdown vault a complete document lifecycle: **capture → refine → plan → execute → maintain**.

## Skills

| Skill | Command | Purpose |
|---|---|---|
| Intake | `/doc:intake` | Capture ideas, tasks, and reference material into your vault |
| Search | `/doc:search` | Find documents by keyword, tag, status, or type |
| Refine | `/doc:refine` | Brainstorm and design — turn rough notes into structured docs |
| Plan | `/doc:plan` | Structure projects into phased implementation checklists |
| Execute | `/doc:execute` | Work sessions with logging and knowledge doc sync |
| Maintain | `/doc:maintain` | Hygiene scans and debug mode for vault self-critique |

## Installation

### From marketplace

```
/plugin marketplace add blizel/doc-plugin
/plugin install doc@blizel-doc-plugin
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

## Lifecycle Flow

```
intake → refine → plan → execute → refine (iterate)
                           ↘ maintain debug (when vault feels off)
```

Each skill suggests the natural next step when it completes.

## License

MIT
