# yumango-plugins

A Claude Code plugin for reusable skills and agents — planning, cross-verification, and more.

## Project Structure

```
plugin/                      ← Distributed to users (this is the plugin)
  .claude-plugin/plugin.json — Plugin manifest
  skills/                    — Production skills
    cross-plan/
    plan-verify/
drafts/                      ← Development workspace (NOT distributed)
  evals/                     — Eval data and sample projects
.claude-plugin/
  marketplace.json           — Marketplace definition (points to plugin/)
.claude/
  settings.json              — Local dev settings
```

## Workflow

1. **Develop** — Create new skills in `drafts/`
2. **Verify** — Test and evaluate using `drafts/evals/`
3. **Promote** — Move verified skills from `drafts/` to `plugin/skills/`

## Testing

- Test plugin locally: `claude --plugin-dir ./plugin`
- Plugin skills are namespaced: `/yumango-plugins:<skill-name>`

## Distribution

- Published via GitHub: `yunmango/yunmango-claude-plugins`
- Install:
  ```
  /plugin marketplace add yunmango/yunmango-claude-plugins
  /plugin install yumango-plugins@yunmango-claude-plugins
  ```
- Only `plugin/` directory is distributed — `drafts/` and `.claude/` are excluded
