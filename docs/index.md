# yunmango-plugins

A Claude Code plugin for **clarifying intent and cross-verifying plans** — before you write any code.

## Skills

| Skill | What it does |
| --- | --- |
| [`deep-interview`](skills/deep-interview.md) | Socratic Q&A to crystallize a vague request **before** planning. |
| [`cross-plan`](skills/cross-plan.md) | Claude + Codex draft plans **in parallel**, then synthesize. |
| [`plan-verify`](skills/plan-verify.md) | Claude drafts, then Codex **verifies** against the codebase. |

`deep-interview` runs upstream of the planning skills. The two planning skills follow a *team-lead* pattern — Claude Code clarifies, coordinates, and synthesizes; it never writes the plan itself.

## Next

- [Getting Started](getting-started.md) — install and run your first plan
- [How Skills Work](how-skills-work.md) — what triggers a skill and what happens after
