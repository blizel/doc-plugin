# Restructure Mode

Layout changes that hygiene mode can't handle — creating directories, moving files, updating references.

## Process

### 1. Understand the change

Read the user's description and current layout. Use Glob to map existing structure. Identify:
- Files/directories moving
- New directories needed
- References that will break (wikilinks, vault-context.md, CLAUDE.md)

### 2. Propose the plan

Present a concrete before/after:
- Directory tree diff (old → new)
- Files moving (old → new paths)
- References to update
- vault-context.md changes (Directory Map, Status Map)

**Wait for approval before proceeding.**

### 3. Execute

1. Create new directories
2. Move files (`mv`)
3. Update wikilinks in all referencing files (Grep to find, Edit to fix)
4. Update vault-context.md
5. Update CLAUDE.md if it references moved paths
6. Run scanner on affected directories to verify

### 4. Summary

Show what changed: files moved, references updated, config updated.
