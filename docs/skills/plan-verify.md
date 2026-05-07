# plan-verify

**Sequential plan-then-verify workflow.** Claude Opus drafts an implementation plan, then Codex (xhigh reasoning) independently verifies it against the actual codebase and returns a verdict.

## When to use it

Reach for `plan-verify` when:

- You want **one drafter and one critic**, not two parallel drafters.
- The plan should be reviewed by a model that has the full plan in front of it (not just the task).
- You want a clear **verdict** (`PASS` / `PASS_WITH_NOTES` / `NEEDS_REVISION`) before starting implementation.

If you'd rather have two planners work in parallel and compare, see [`cross-plan`](cross-plan.md).

## Quick start

```
/yumango-plugins:plan-verify <task description>
```

Or trigger by intent:

> Plan the auth middleware refactor and have Codex verify it.

> 계획 좀 단단하게 세워줘

## How it runs

```
Claude Code (Team Lead)
    │
    ├── Step 0: Analyze requirements & clarify ambiguities
    │
    ├── Step 1: Claude Planner (foreground)
    │     └── Explores codebase → returns structured plan
    │
    ├── Step 2: Codex Verifier (foreground)
    │     └── codex:codex-rescue (--model gpt-5.5 --effort xhigh)
    │     └── Verifies the plan against the codebase
    │     └── Returns Confirmed / Gaps / Risks / Ordering Issues / Verdict
    │
    ├── Step 3: Synthesize final plan (with explicit triage step)
    │
    └── Step 4: Save plan & ask user whether to proceed
```

Steps 1 and 2 run **sequentially** — the verifier reads the planner's output, not just the original task.

## The verdict

The Codex Verifier returns one of:

| Verdict | Meaning |
| --- | --- |
| **PASS** | The plan checks out. Claude's original plan is adopted as the final plan. |
| **PASS_WITH_NOTES** | Plan is workable but has gaps or risks worth addressing. Triage runs; final plan incorporates accepted changes. |
| **NEEDS_REVISION** | Plan has material problems (missing dependencies, wrong file references, ordering issues). Triage runs; final plan is rewritten with a brief change list. |

## Findings triage (Step 3a)

The team lead does **not** blanket-accept Codex's findings. Each item under Gaps, Risks, and Ordering Issues is classified:

- **ACCEPT** — incorporate as-is. Default for codebase-grounded factual corrections (file paths, function signatures, ordering errors).
- **ACCEPT_WITH_MODIFICATION** — incorporate but rephrase, narrow, or split. Use when the concern is valid but the suggested mitigation is heavier than needed.
- **REJECT** — only allowed if the finding is empirically wrong, out of scope, speculative, or stylistic. Each REJECT carries a one-line justification.

When unsure, the team lead reads the relevant file(s) before classifying — trust-but-verify is the default for high-impact items.

## What you get back

Output structure:

```text
## Verification Summary

**Verdict**: <PASS | PASS_WITH_NOTES | NEEDS_REVISION>

### Codex Verification Highlights
- Confirmed: ...
- Gaps: ...
- Risks: ...

### Findings Triage  (omitted when Verdict is PASS)
- ACCEPT: ...
- ACCEPT_WITH_MODIFICATION: ...
- REJECT: ...   (each with justification)

### Final Verified Plan
<6-heading plan>
```

The final plan is saved to `.claude/plans/<kebab-case-name>.md` with a footer noting it was *"Planned by Claude Opus · Verified by Codex (xhigh reasoning)."*

## Tips

- **`PASS_WITH_NOTES` is the most common verdict.** A clean `PASS` on a non-trivial task is rare. Treat the notes as cheap insurance.
- **Watch for ordering issues.** Codex is unusually good at flagging "step N depends on something that doesn't exist until step N+2." These are nearly always worth accepting.
- **`REJECT` should be rare.** If you find yourself rejecting most findings, the planner's draft is probably out of touch with the codebase — re-run the skill with a more specific task description.

## Source

The full executable specification, including the planner and verifier prompt templates, is at:

- [`plugin/skills/plan-verify/SKILL.md`](https://github.com/yunmango/yunmango-claude-plugins/blob/main/plugin/skills/plan-verify/SKILL.md)
