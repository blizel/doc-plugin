# Debug Mode

Aggressive self-critical pass for when the vault "feels off." Run hygiene mode first, then layer these checks on top.

## Deep Scan

Everything from hygiene, plus:

- **Contradictions** — docs describing the same thing differently
- **Unrealistic projects** — active/backlog with no progress in 90+ days, no clear goal
- **Orphaned docs** — files with no inbound or outbound links
- **Stale knowledge** — tech docs describing tools/configs that may have changed
- **Scope creep** — projects grown beyond original design without restructuring

## Present Findings

Be direct. Don't soften:

```
## Kill candidates
- projects/backlog/old-idea.md — 6 months inactive, vague goal. Archive or delete?

## Contradictions
- knowledge/tech/dns.md says X, but knowledge/tech/infra.md says Y

## Stale
- projects/active/big-project.md — last log 4 months ago, 2/12 tasks done

## Vault context drift
- vault-context.md doesn't match vault reality
```

## Suggest Actions

For each finding: **Archive**, **Delete**, **Merge**, **Update**, **Refine** (→ `/doc:refine`), or **Split**.

## Update Vault Context

If vault-context.md doesn't match reality (new directories, changed schemas), update it. These updates are findings, not silent changes — present them first.
