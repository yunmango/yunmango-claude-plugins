# How Skills Work

A skill is a markdown file (`SKILL.md`) with a `description` and a body. When the user's request matches the description, Claude loads the body and follows it.

## Anatomy

```markdown
---
name: cross-plan
description: ... Trigger on "cross plan", "교차검증", "/cross-plan".
---

# Cross-Plan Skill

(body — instructions Claude follows when matched)
```

| Field | Role |
| --- | --- |
| `description` | The matchmaking text. Claude scans descriptions to pick the best fit. |
| Body | The actual playbook. Loaded **only after** matching. |

## Three triggering paths

| Path | Example |
| --- | --- |
| Slash command | `/yunmango-plugins:cross-plan add /healthz endpoint` |
| Natural language | *"plan this and have Codex verify it"* → `plan-verify` |
| Negative match | "Do NOT trigger for code review" — keeps overlapping skills apart |

That is why each skill's `description` lists trigger phrases (and anti-triggers) explicitly.

## After a match

Claude reads the body and follows it like a procedure. Bodies in this plugin specify:

- **Roles** — team lead vs. planner vs. verifier
- **Architecture** — step order, which subagents run when
- **Prompt templates** — exact prompts (model, reasoning effort, sandbox flags included)
- **Critical notes** — invariants that must hold (e.g. *"Codex Verifier must use `--model gpt-5.5 --effort xhigh`"*)

Subagents are spawned with the `Agent` tool — `general-purpose` for the Claude Planner, `codex:codex-rescue` for the Codex Verifier. Codex CLI runs in a read-only sandbox.

## Source files

| Skill | File |
| --- | --- |
| `deep-interview` | `plugin/skills/deep-interview/SKILL.md` |
| `cross-plan` | `plugin/skills/cross-plan/SKILL.md` |
| `plan-verify` | `plugin/skills/plan-verify/SKILL.md` |

Those are authoritative — this site is a summary.

## Further reading

- [Anthropic — Claude Code overview](https://docs.claude.com/en/docs/claude-code/overview)
