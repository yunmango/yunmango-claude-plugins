# yumango-plugins

A Claude Code plugin that bundles **planning skills** designed for cross-verification — Claude and Codex check each other's work so you get a more reliable plan before you start coding.

## What's inside

| Skill | Purpose |
| --- | --- |
| [`cross-plan`](skills/cross-plan.md) | Spawns Claude and Codex planners **in parallel**, then synthesizes a cross-verified plan. |
| [`plan-verify`](skills/plan-verify.md) | Claude drafts a plan, then Codex **independently verifies** it against the codebase. |

Both skills follow a "team lead" pattern: Claude Code itself does not write the plan — it clarifies the task, coordinates the planners, and synthesizes the final result.

## Why use it

- **Two perspectives, one plan.** Independent agents reading the same codebase tend to surface different gaps and risks. The synthesis step exposes consensus, divergence, and unique insights.
- **Codebase-grounded.** Every plan is generated after the agents read your actual source files — no guesses based on file names.
- **Drop-in.** The skills auto-trigger on natural-language requests (e.g. *"plan this and have Codex verify it"*) and via slash commands (`/yumango-plugins:cross-plan`, `/yumango-plugins:plan-verify`).

## Next steps

- New here? Start with [Getting Started](getting-started.md).
- Curious about how Claude Code skills work in general? See [How Skills Work](how-skills-work.md).
- Ready to use a specific skill? Jump to [`cross-plan`](skills/cross-plan.md) or [`plan-verify`](skills/plan-verify.md).
