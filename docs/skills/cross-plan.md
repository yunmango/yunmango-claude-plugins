# cross-plan

**Parallel cross-verified planning.** Claude Code acts as the team lead, spawns two independent planner agents at the same time, and synthesizes a single verified plan from their outputs.

## When to use it

Reach for `cross-plan` when:

- You want **two independent perspectives** on the same task before committing.
- Wall-clock matters — both planners run in parallel.
- You don't yet know which agent's reading of the codebase will be more accurate, and you want to compare.

If instead you want one drafter and one critic in sequence, see [`plan-verify`](plan-verify.md).

## Quick start

```
/yumango-plugins:cross-plan <task description>
```

Or trigger by intent:

> Cross-verify a plan for migrating the user model to UUIDs.

## How it runs

```
Claude Code (Team Lead)
    │
    ├── Step 0: Analyze task & ask clarifying questions (if needed)
    │
    ├── Step 1: Spawn both planners in parallel (background)
    │     ├── claude-planner   (Opus, reads codebase via Read/Glob/Grep)
    │     └── codex-planner    (Codex, runs `codex exec -s read-only`)
    │
    ├── Step 2: Wait for both results
    │
    ├── Step 3: Handle failures (single-source fallback if one fails)
    │
    ├── Step 4: Cross-verify and synthesize
    │
    ├── Step 5: Save final plan to .claude/plans/<name>.md
    │
    └── Step 6: Ask user whether to implement
```

The team lead **does not write its own plan** — it clarifies, orchestrates, and synthesizes.

## What you get back

The synthesized output is structured into four sections:

| Section | Purpose |
| --- | --- |
| **Consensus** | Items both planners agreed on. Highest reliability. |
| **Divergence** | A side-by-side table of items where the planners disagreed, plus the team lead's recommendation. |
| **Unique Insights** | Valuable points raised by only one planner. Evaluated and kept if valid. |
| **Final Integrated Plan** | The synthesized plan, in a fixed 6-heading format (Goal, Analysis, Architecture, Implementation Steps, Testing Strategy, Edge Cases & Risks). |

The final plan is saved to `.claude/plans/<kebab-case-name>.md` so you can revisit it later or hand it off as a starting point for implementation.

## Failure modes

Even if one planner crashes, you still get something useful:

| claude-planner | codex-planner | What happens |
| --- | --- | --- |
| OK | OK | Full cross-verification (normal flow) |
| OK | FAIL | Claude's plan is shown, labeled *"Single-source plan (unverified)"* |
| FAIL | OK | Codex's plan is shown, labeled *"Single-source plan (unverified)"* |
| FAIL | FAIL | Both errors are reported and you're prompted to retry |

## Tips

- **Don't skip the clarification step.** If the task description is ambiguous (multiple valid interpretations, missing constraints), the team lead will ask. Answering up front yields a much better plan than retroactive fixups.
- **Use it for design choices that genuinely have two right answers.** If the task is mechanical, a single planner is enough — `plan-verify` (or no skill at all) is cheaper.
- **Read the divergence table carefully.** The most useful insight is often there, not in the consensus.

## Source

The full executable specification, including prompt templates and subagent configuration, is at:

- [`plugin/skills/cross-plan/SKILL.md`](https://github.com/yunmango/yunmango-claude-plugins/blob/main/plugin/skills/cross-plan/SKILL.md)
