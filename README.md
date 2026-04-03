# yumango-plugins

A Claude Code plugin providing reusable skills for planning and cross-verification workflows.

## Skills

| Skill | Description |
|-------|-------------|
| `cross-plan` | Spawns Claude and Codex planners in parallel, then cross-verifies and synthesizes a final plan |
| `plan-verify` | Claude Opus drafts a plan, then Codex GPT-5.4 independently verifies it against the codebase |

## Installation

```bash
# Add marketplace
/plugin marketplace add yunmango/yunmango-claude-plugins

# Install plugin
/plugin install yumango-plugins
```

## Usage

```bash
/yumango-plugins:cross-plan <task description>
/yumango-plugins:plan-verify <task description>
```

## License

MIT
