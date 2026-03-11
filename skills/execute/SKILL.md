---
name: execute
description: "Use when starting, resuming, or wrapping up work on a vault project — ensures session context is captured and project state stays current."
argument-hint: <project-name-or-search-term>
---

!`cat vault-context.md 2>/dev/null || echo "vault-context.md not found in current directory. Copy the template from ${CLAUDE_PLUGIN_ROOT}/vault-context.md to your vault root and configure it."`

# Execute Vault Project Work

Manage a work session end-to-end: resolve the project, open the session, do the work with periodic logging, and wrap up cleanly. Session narrative is captured in a log file per project so context is never lost between sessions.

For log file format and project promotion details, see `${CLAUDE_SKILL_DIR}/reference.md`.

## Scope

- `$ARGUMENTS` provided: resolve and start working
- Empty `$ARGUMENTS`: ask what project to work on
- Already mid-session: skip to work loop

## Process

### 1. Resolve project

Use vault context to find the project. Glob/Grep across project directories. Read the project doc (`<folder-name>.md`) and log (`<folder-name>-log.md`) if they exist.

Surface to the user:
- Current status and open tasks
- Last log entry — what happened last time, where things were left off
- Impacted knowledge docs (from project's References/Related section)

### 2. Open session

- Set project `status` to `active` if currently paused or in backlog
- Bump `updated` date on the project doc
- Write opening log entry: what we're picking up and what the goal is

If the project is a single file (no folder), promote it first — see `${CLAUDE_SKILL_DIR}/reference.md`.

### 3. Work loop

Do the work. At natural breakpoints, append a log entry to the project's log file (`<folder-name>-log.md`). Breakpoints are the same moments you'd git commit:

- **Completed a chunk** — got something working, checked off a task
- **Changed direction** — tried something, abandoned it, pivoted
- **Modified state** — paused a workflow, changed a config, disabled a feature
- **Hit a blocker** — something unexpected stopped progress
- **Significant discovery** — found something that changes the plan

Log entries are free-form narrative under a `## YYYY-MM-DD` heading. Write them without asking for approval.

**Knowledge doc sync:** When a task completes that changes something described in a knowledge doc (runbook, tech reference), update that doc immediately — not at wrap-up. Temporary changes mid-debugging go in the log only; knowledge docs reflect landed state. The project's References section lists which docs this project impacts.

### 4. Wrap up

- Final log entry: where we left off, open threads, anything temporarily changed
- Set project status: `active` if continuing, `paused` if shelving, `shipped` if done
- Bump `updated` date
- Surface a short summary of the session to the user

**Next step:** If iterating on design, suggest `/doc:refine`. If the vault feels off, suggest `/doc:maintain debug`.

## Rules

- ALWAYS resolve the project before doing anything — don't assume paths
- ALWAYS write an opening log entry before starting work
- ALWAYS write a wrap-up log entry before ending a session
- NEVER ask for approval on log entries — write them like git commits
- NEVER skip logging because the work feels small — if state changed, log it
- NEVER defer knowledge doc updates to wrap-up — update them when the task that changes them completes
- NEVER use this skill for brainstorming or design — use `doc:refine` first
- Log entries are narrative, not structured — no bullet categories, just write what happened
- Update the project doc's `updated` date on every log write
