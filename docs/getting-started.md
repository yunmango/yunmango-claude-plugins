# Getting Started

## Prerequisites

- [Claude Code](https://docs.claude.com/en/docs/claude-code/overview)
- [Codex CLI](https://github.com/openai/codex) — both skills delegate verification to Codex

```bash
claude --version
codex --version
```

## Install

=== "Marketplace"

    ```bash
    /plugin marketplace add yunmango/yunmango-claude-plugins
    /plugin install yumango-plugins@yunmango-claude-plugins
    ```

=== "Local / dev"

    ```bash
    git clone https://github.com/yunmango/yunmango-claude-plugins.git
    claude --plugin-dir /path/to/yunmango-claude-plugins/plugin
    ```

Confirm installation with `/help` — `yumango-plugins:cross-plan` and `yumango-plugins:plan-verify` should appear.

## Run

=== "Parallel cross-verify"

    ```
    /yumango-plugins:cross-plan add a /healthz endpoint that reports DB and Redis status
    ```

=== "Plan-then-verify"

    ```
    /yumango-plugins:plan-verify add a /healthz endpoint that reports DB and Redis status
    ```

Either skill will:

1. Ask clarifying questions if the task is ambiguous.
2. Read your codebase before writing the plan.
3. Save the final plan to `.claude/plans/<name>.md`.
4. Ask whether to proceed with implementation.

Both also auto-trigger on natural language — see [How Skills Work](how-skills-work.md).

## Troubleshooting

| Symptom | Likely cause |
| --- | --- |
| Codex step: *command not found* | `codex` not on `PATH` — reinstall and verify in the same shell |
| Empty / truncated plan | Agent ended its turn with a tool call — re-run |
| Codex modified files | Read-only sandbox flag dropped — re-run |
