# yumango-plugins

A Claude Code plugin for **cross-verified planning**. Claude and Codex check each other's work before you write any code.

## Skills

| Skill | What it does |
| --- | --- |
| [`cross-plan`](skills/cross-plan.md) | Claude + Codex draft plans **in parallel**, then synthesize. |
| [`plan-verify`](skills/plan-verify.md) | Claude drafts, then Codex **verifies** against the codebase. |

Both follow a *team-lead* pattern — Claude Code clarifies, coordinates, and synthesizes; it never writes the plan itself.

## Next

- [Getting Started](getting-started.md) — install and run your first plan
- [How Skills Work](how-skills-work.md) — what triggers a skill and what happens after
