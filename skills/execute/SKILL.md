---
name: execute
description: "start/resume/wrap work session on a project"
argument-hint: <project-name-or-search-term>
---

!`cat vault-context.md 2>/dev/null || echo "vault-context.md not found in current directory. Copy the template from ${CLAUDE_PLUGIN_ROOT}/vault-context.md to your vault root and configure it."`

# Execute Vault Project Work

Manage a work session: resolve project, open session, work with periodic logging, wrap up. Session narrative is captured in a log file so context is never lost. See `${CLAUDE_SKILL_DIR}/reference.md` for log format and project promotion.

## Process

### 1. Resolve project

Glob/Grep across project directories from vault context. Read the project doc and log if they exist. Surface: current status/open tasks, last log entry, impacted knowledge docs.

### 2. Open session

- Set status to `active` (if paused/backlog), bump `updated` date
- Write opening log entry: what we're picking up, goal for this session
- Single-file projects: promote to folder first (see `${CLAUDE_SKILL_DIR}/reference.md`)

### 3. Work loop

Do the work. At natural breakpoints (same moments you'd git commit), append a log entry:
- Completed a chunk / checked off a task
- Changed direction or pivoted
- Hit a blocker or made a significant discovery

Log entries are free-form narrative under `## YYYY-MM-DD` headings. Write without asking approval.

**Knowledge sync:** When a task changes something described in a knowledge doc, update that doc immediately — not at wrap-up.

### 4. Wrap up

- Final log entry: where we left off, open threads
- Set status: `active` if continuing, `paused` if shelving, `shipped` if done
- Bump `updated`, surface session summary

## Rules

- ALWAYS resolve project first — don't assume paths
- ALWAYS write opening and closing log entries
- NEVER ask approval on log entries — write them like commits
- NEVER defer knowledge doc updates to wrap-up
