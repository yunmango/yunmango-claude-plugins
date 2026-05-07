# plan-verify

**Sequential plan-then-verify workflow.** Claude Opus drafts an implementation plan, then Codex (xhigh reasoning) independently verifies it against the actual codebase and returns a verdict.

## When to use it

| Use `plan-verify` when… | Use [`cross-plan`](cross-plan.md) instead when… |
| --- | --- |
| You want **one drafter + one critic** in sequence. | You want **two parallel drafters** to compare. |
| The reviewer should see the **full plan**, not just the task. | Wall-clock matters and you can run two planners at once. |
| You want a clear `PASS / NEEDS_REVISION` verdict before implementing. | You want to surface divergent approaches side-by-side. |

## Quick start

```
/yumango-plugins:plan-verify <task description>
```

Or trigger by intent:

> Plan the auth middleware refactor and have Codex verify it.

> 계획 좀 단단하게 세워줘

## Architecture at a glance

```mermaid
flowchart TD
    User([User]):::actor
    Lead[Team Lead<br/>Claude Code]:::lead
    Q{Ambiguous?}:::decision
    Ask[/AskUserQuestion/]:::io
    CP[Claude Planner<br/>Opus]:::agent
    CV[Codex Verifier<br/>gpt-5.5 · xhigh]:::agent
    V{Verdict?}:::decision
    Adopt[Adopt original plan]:::lead
    Triage[Triage findings<br/>ACCEPT · MODIFY · REJECT]:::lead
    Build[Build revised plan]:::lead
    Save[(Save to<br/>.claude/plans/&lt;name&gt;.md)]:::store
    Done([Done]):::actor

    User --> Lead --> Q
    Q -- yes --> Ask --> Lead
    Q -- no --> CP
    CP -- "Step 1: structured plan" --> CV
    CV -- "Step 2: Confirmed / Gaps / Risks" --> V
    V -- PASS --> Adopt --> Save
    V -- "PASS_WITH_NOTES /<br/>NEEDS_REVISION" --> Triage --> Build --> Save
    Save --> Done

    classDef actor fill:#1e293b,color:#fff,stroke:#0f172a;
    classDef lead fill:#f97316,color:#fff,stroke:#c2410c;
    classDef agent fill:#0ea5e9,color:#fff,stroke:#0369a1;
    classDef decision fill:#fde68a,color:#78350f,stroke:#b45309;
    classDef io fill:#fef3c7,color:#78350f,stroke:#b45309;
    classDef store fill:#e2e8f0,color:#0f172a,stroke:#475569;
```

## Who talks to whom

```mermaid
sequenceDiagram
    actor User
    participant Lead as Team Lead
    participant CP as Claude Planner
    participant CV as Codex Verifier

    User->>Lead: /plan-verify <task>
    opt Ambiguities exist
        Lead->>User: Clarifying questions
        User-->>Lead: Answers
    end

    Lead->>+CP: Plan (Opus, read codebase)
    CP-->>-Lead: Structured plan

    Lead->>+CV: Verify plan vs. codebase<br/>--model gpt-5.5 --effort xhigh<br/>(read-only)
    CV-->>-Lead: Confirmed · Gaps · Risks · Verdict

    alt Verdict = PASS
        Lead->>Lead: Adopt original plan
    else PASS_WITH_NOTES / NEEDS_REVISION
        Lead->>Lead: Triage findings<br/>(ACCEPT · MODIFY · REJECT)
        Lead->>Lead: Build revised plan
    end

    Lead->>User: Final verified plan
    User-->>Lead: Approve · decline
```

## Step-by-step

### Step 0 — Clarify (only if needed)

The team lead checks for ambiguity, missing constraints, or design choices with multiple valid answers. Asks via `AskUserQuestion` if found. **Skipped if the task is already clear.**

### Step 1 — Claude Planner (foreground)

A single `Agent` call with:

- Subagent type: `general-purpose`
- Model: `opus`
- Tools: `Read`, `Glob`, `Grep` (no external CLI)
- Output: 6-heading plan (Goal · Analysis · Architecture · Implementation Steps · Testing Strategy · Edge Cases & Risks)

The full plan becomes input to the next step.

### Step 2 — Codex Verifier (foreground)

A single `Agent` call to `codex:codex-rescue` with the prompt **starting** as:

```
--model gpt-5.5 --effort xhigh

This is a read-only review task. Do not modify any files.
```

…followed by the verification prompt template containing the original task and the Claude Planner's full plan. Codex re-explores the codebase and returns:

| Section | What it contains |
| --- | --- |
| **Confirmed** | Plan items grounded in real code. |
| **Gaps** | Missing files, dependencies, or considerations. |
| **Risks** | Potential issues with mitigations. |
| **Ordering Issues** | Steps that depend on something not yet created. |
| **Verdict** | One of `PASS`, `PASS_WITH_NOTES`, `NEEDS_REVISION`. |

### Step 3 — Synthesize the final plan

How the team lead handles the verifier output depends on the verdict:

```mermaid
flowchart LR
    V{Verdict}:::decision
    A[PASS<br/>Adopt original plan as-is]:::pass
    B[PASS_WITH_NOTES<br/>Triage → revise minor items]:::warn
    C[NEEDS_REVISION<br/>Triage → revise + change list]:::fail

    V --> A
    V --> B
    V --> C

    classDef decision fill:#fde68a,color:#78350f,stroke:#b45309;
    classDef pass fill:#bbf7d0,color:#14532d,stroke:#15803d;
    classDef warn fill:#fde68a,color:#78350f,stroke:#b45309;
    classDef fail fill:#fecaca,color:#7f1d1d,stroke:#b91c1c;
```

#### Step 3a — Triage (skipped on PASS)

Each finding is classified:

| Disposition | When to use |
| --- | --- |
| **ACCEPT** | Codebase-grounded factual corrections (file paths, function signatures, ordering errors). Default. |
| **ACCEPT_WITH_MODIFICATION** | Concern is valid but the suggested fix is heavier than needed — rephrase, narrow, or split. |
| **REJECT** | Only allowed if the finding is empirically wrong, out of scope, speculative, or pure stylistic preference. **Each REJECT carries a one-line justification.** |

When unsure, the team lead **reads the referenced file** before classifying — trust-but-verify is the default for high-impact items (architecture changes, regex correctness, ordering issues, missing dependencies).

#### Step 3b — Build the revised plan

ACCEPT and ACCEPT_WITH_MODIFICATION items are merged into the 6-heading plan. REJECT items are surfaced separately so you can see what was deliberately skipped and why.

For `NEEDS_REVISION`, a brief change list is attached so you can see what moved.

### Step 4 — Save and confirm

The plan is written to `.claude/plans/<kebab-case-name>.md` with:

```text
*Planned by Claude Opus · Verified by Codex (xhigh reasoning)*
```

The team lead asks whether to proceed. Approve → enter plan mode. Decline → stop here.

## Output structure

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

## Tips

- **`PASS_WITH_NOTES` is the most common verdict.** A clean `PASS` on a non-trivial task is rare. Treat the notes as cheap insurance.
- **Watch for ordering issues.** Codex is unusually good at flagging "step N depends on something not created until step N+2." Almost always worth accepting.
- **`REJECT` should be rare.** If you find yourself rejecting most findings, the planner's draft is probably out of touch with the codebase — re-run with a more specific task description.

## Source

The full executable specification — planner and verifier prompt templates, model/effort flags, sandbox requirements — lives in:

- [`plugin/skills/plan-verify/SKILL.md`](https://github.com/yunmango/yunmango-claude-plugins/blob/main/plugin/skills/plan-verify/SKILL.md)
