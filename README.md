# yumango-plugins

A Claude Code plugin providing reusable skills for planning and cross-verification workflows.

## Skills

| Skill | Description |
|-------|-------------|
| `cross-plan` | Spawns Claude and Codex planners in parallel, then cross-verifies and synthesizes a final plan |
| `plan-verify` | Claude Opus drafts a plan, then Codex independently verifies it against the codebase |

## Prerequisites

- [Codex CLI](https://github.com/openai/codex) 설치 필요 (both skills use Codex internally)

## Installation

### Local / Development

```bash
git clone https://github.com/yunmango/yunmango-claude-plugins.git
claude --plugin-dir /path/to/yunmango-claude-plugins/plugin
```

### Marketplace

```bash
/plugin marketplace add yunmango/yunmango-claude-plugins
/plugin install yumango-plugins@yunmango-claude-plugins
```

## Usage

```bash
/yumango-plugins:cross-plan <task description>
/yumango-plugins:plan-verify <task description>
```

## Documentation

Full user guide (English / 한국어): <https://yunmango.github.io/yunmango-claude-plugins/>

## License

MIT
