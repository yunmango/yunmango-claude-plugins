# Getting Started

This guide walks you from a clean machine to running your first cross-verified plan.

## Prerequisites

- **[Claude Code](https://docs.claude.com/en/docs/claude-code/overview)** installed and authenticated.
- **[Codex CLI](https://github.com/openai/codex)** installed and authenticated. Both bundled skills delegate verification work to Codex, so without it the verifier step will fail.

Verify both are working:

```bash
claude --version
codex --version
```

## Install the plugin

### Option A — Marketplace (recommended)

```bash
/plugin marketplace add yunmango/yunmango-claude-plugins
/plugin install yumango-plugins@yunmango-claude-plugins
```

### Option B — Local / development

```bash
git clone https://github.com/yunmango/yunmango-claude-plugins.git
claude --plugin-dir /path/to/yunmango-claude-plugins/plugin
```

## Verify installation

Inside a Claude Code session, list the available skills:

```
/help
```

You should see `yumango-plugins:cross-plan` and `yumango-plugins:plan-verify` listed.

## Run your first plan

Pick the skill that matches your need:

=== "Cross-verified plan (parallel)"

    Two planners run **at the same time** — faster wall-clock, two independent perspectives.

    ```
    /yumango-plugins:cross-plan add a /healthz endpoint that reports DB and Redis status
    ```

=== "Plan-then-verify (sequential)"

    Claude drafts first, then Codex critiques. Slower, but Codex sees the full plan when reviewing.

    ```
    /yumango-plugins:plan-verify add a /healthz endpoint that reports DB and Redis status
    ```

Either skill will:

1. Ask clarifying questions if your request is ambiguous.
2. Run the planner(s) — they read your codebase before writing anything.
3. Produce a **structured plan** with consensus, divergences, and risks called out.
4. Save the final plan to `.claude/plans/<name>.md` and ask whether to proceed with implementation.

## Triggering without slash commands

Both skills also auto-trigger on natural language. For example:

- "Plan this feature and have Codex verify it" → `plan-verify`
- "Cross-verify a plan for refactoring the auth middleware" → `cross-plan`
- "계획 좀 단단하게 세워줘" → `plan-verify`

See [How Skills Work](how-skills-work.md) for why this matching happens.

## Troubleshooting

**The Codex step fails with "command not found".**
Codex CLI is not on your `PATH`. Reinstall it and confirm `codex --version` works in the same shell where you launched Claude Code.

**The planner returns an empty or truncated plan.**
The agent may have ended its turn with a tool call instead of a text message. Re-run the skill — both skills include explicit instructions for the agents to end with the full plan as the final message, but agents occasionally diverge.

**Codex modifies files instead of just reviewing.**
This indicates the read-only sandbox flag was dropped. Re-run the skill; the bundled prompts always include the read-only sandbox instruction.
