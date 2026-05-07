# How Skills Work

A short tour of the **Claude Code skill system** so you know what's actually happening when `cross-plan` or `plan-verify` "kicks in."

## The one-line definition

A **skill** is a markdown file (`SKILL.md`) with a frontmatter `description` and a body of instructions. When the user's request matches the description, Claude loads the body and follows it.

Skills do not run code on their own. They are *additional context* that Claude reads at the right moment.

## Anatomy of a skill

Every skill in this plugin lives at `plugin/skills/<name>/SKILL.md` with a structure like this:

```markdown
---
name: cross-plan
description: Cross-verification planning skill that spawns Claude and Codex
  planner agents in parallel... Trigger on "cross plan", "cross verify",
  "교차검증", "dual plan", or "/cross-plan".
invokable: true
---

# Cross-Plan Skill

(body — instructions Claude follows when the skill is loaded)
```

Two things matter here:

| Field | Role |
| --- | --- |
| `description` (frontmatter) | The matchmaking text. Claude scans descriptions of available skills and picks the one whose description fits the user's intent. |
| Body (after frontmatter) | The actual playbook. Loaded into Claude's context **only after** the skill is matched, so it can be long and detailed without crowding every conversation. |

## How a skill gets triggered

There are three triggering paths, and skills in this plugin support all three:

### 1. Slash command

The user types the namespaced command directly:

```
/yumango-plugins:cross-plan add a /healthz endpoint
```

This is unambiguous — Claude loads the matching skill immediately.

### 2. Natural-language match

The user says something like *"plan this feature and have Codex verify it."* Claude looks at the descriptions of all installed skills and picks the best fit. That is why each skill's `description` lists trigger phrases explicitly:

> Trigger on any of these signals — explicit commands like "/plan-verify", Korean phrases like "계획 검증", "검증 계획"... or English phrases like "verified plan", "plan and verify", "validate the plan".

### 3. Negative triggers

A good description also says when **not** to fire. From `plan-verify`:

> Do NOT trigger for simple planning without verification, cross-plan (parallel dual planning), direct Codex delegation, or code review of existing changes.

This keeps overlapping skills from stepping on each other.

## What happens after a match

Once a skill matches, Claude reads the body of `SKILL.md` and executes it like a procedure. Bodies in this plugin describe:

- **Roles.** Who does what (e.g. team lead vs. planner vs. verifier).
- **Architecture.** A diagram of the steps and which subagents run in which order.
- **Prompt templates.** The exact prompts sent to each subagent — model, reasoning effort, and sandbox flags included.
- **Critical notes.** Constraints that must hold no matter what (e.g. "Codex Verifier must use `--model gpt-5.5 --effort xhigh`").

Subagents are spawned with the `Agent` tool. For example, both skills use `general-purpose` for the Claude Planner, and `plan-verify` uses `codex:codex-rescue` for the Codex Verifier. Codex CLI runs in a sandboxed read-only mode for verification.

## Where the skills live

| Skill | File |
| --- | --- |
| `cross-plan` | `plugin/skills/cross-plan/SKILL.md` |
| `plan-verify` | `plugin/skills/plan-verify/SKILL.md` |

If you want to read the full instructions Claude follows, those files are the authoritative source. The pages on this site are summaries written for users.

## Further reading

- Anthropic's official docs: <https://docs.claude.com/en/docs/claude-code/overview>
- The plugin manifest: `plugin/.claude-plugin/plugin.json`
