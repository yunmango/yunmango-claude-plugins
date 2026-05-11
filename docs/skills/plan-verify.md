# plan-verify

Claude Opus drafts a plan, then Codex (gpt-5.5, xhigh reasoning, fast mode) verifies it against the codebase and returns a verdict.

```
/yumango-plugins:plan-verify <task description>
```

## Pick the right skill

| Use `plan-verify` | Use [`cross-plan`](cross-plan.md) |
| --- | --- |
| One drafter + one critic | Two parallel drafters |
| Reviewer needs the full plan | Wall-clock matters |
| Want a `PASS / NEEDS_REVISION` verdict | Want side-by-side approaches |

## Flow

```text
              User
               │
               ▼
           Team Lead ◄── clarify (if ambiguous)
               │
               ▼
       Claude Planner (Opus)
               │
               ▼
       Codex Verifier (gpt-5.5 · xhigh · fast, read-only)
               │
        ┌──────┴──────┐
        ▼             ▼
      PASS    PASS_WITH_NOTES /
        │     NEEDS_REVISION
        │             │
        │             ▼
        │      Triage + revise
        │             │
        └──────┬──────┘
               ▼
     .claude/plans/<name>.md
```

```mermaid
flowchart TD
    User([User]):::actor --> Lead[Team Lead]:::lead
    Lead --> Q{Ambiguous?}:::decision
    Q -- yes --> Ask[/Ask user/]:::io --> Lead
    Q -- no --> CP[Claude Planner<br/>Opus]:::agent
    CP --> CV[Codex Verifier<br/>gpt-5.5 · xhigh · fast]:::agent
    CV --> V{Verdict}:::decision
    V -- PASS --> Adopt[Adopt original plan]:::lead
    V -- "PASS_WITH_NOTES /<br/>NEEDS_REVISION" --> Triage[Triage findings]:::lead --> Build[Revise plan]:::lead
    Adopt --> Save[(.claude/plans/&lt;name&gt;.md)]:::store
    Build --> Save
    Save --> Done([Done]):::actor

    classDef actor fill:#1e293b,color:#fff,stroke:#0f172a;
    classDef lead fill:#f97316,color:#fff,stroke:#c2410c;
    classDef agent fill:#0ea5e9,color:#fff,stroke:#0369a1;
    classDef decision fill:#fde68a,color:#78350f,stroke:#b45309;
    classDef io fill:#fef3c7,color:#78350f,stroke:#b45309;
    classDef store fill:#e2e8f0,color:#0f172a,stroke:#475569;
```

```text
1. User           ── /plan-verify ──►  Team Lead
2. Team Lead      ── plan ──────►      Claude Planner
3. Claude Planner ── plan ──────►      Team Lead
4. Team Lead      ── verify ────►      Codex Verifier   (read-only)
5. Codex Verifier ── verdict + findings ──►  Team Lead
6. Team Lead      (triage + revise, if not PASS)
7. Team Lead      ── final plan ──►    User
```

```mermaid
sequenceDiagram
    actor User
    participant Lead as Team Lead
    participant CP as Claude Planner
    participant CV as Codex Verifier

    User->>Lead: /plan-verify <task>
    opt If ambiguous
        Lead->>User: Clarifying questions
        User-->>Lead: Answers
    end
    Lead->>+CP: Plan
    CP-->>-Lead: Plan
    Lead->>+CV: Verify (read-only)
    CV-->>-Lead: Verdict + findings
    alt PASS
        Lead->>User: Original plan
    else PASS_WITH_NOTES / NEEDS_REVISION
        Lead->>Lead: Triage + revise
        Lead->>User: Revised plan
    end
```

## Verdict routing

| Verdict | Result |
| --- | --- |
| **PASS** | Original plan adopted as-is |
| **PASS_WITH_NOTES** | Triage findings → minor revisions |
| **NEEDS_REVISION** | Triage findings → revise + change list |

## Triage rules

Each Codex finding is classified:

| Disposition | When |
| --- | --- |
| **ACCEPT** | Codebase-grounded factual corrections (default) |
| **ACCEPT_WITH_MODIFICATION** | Valid concern, lighter mitigation |
| **REJECT** | Empirically wrong, out of scope, speculative, or pure style — requires one-line justification |

When uncertain, the team lead reads the referenced file before classifying.

## Source

[`plugin/skills/plan-verify/SKILL.md`](https://github.com/yunmango/yunmango-claude-plugins/blob/main/plugin/skills/plan-verify/SKILL.md)
