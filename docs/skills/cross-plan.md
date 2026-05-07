# cross-plan

Two planners run **in parallel** — Claude and Codex — then Claude Code synthesizes a single plan from both.

```
/yumango-plugins:cross-plan <task description>
```

## Pick the right skill

| Use `cross-plan` | Use [`plan-verify`](plan-verify.md) |
| --- | --- |
| Two parallel drafters | One drafter + one critic |
| Wall-clock matters | Reviewer should see the full plan |
| Want to compare approaches | Want a clear `PASS / NEEDS_REVISION` |

## Flow

```text
              User
               │
               ▼
           Team Lead ◄── clarify (if ambiguous)
               │
        parallel spawn (one message, two Agent calls)
        ┌──────┴──────┐
        ▼             ▼
  claude-planner   codex-planner
     (Opus)        (codex exec -s read-only)
        │             │
        └──────┬──────┘
               ▼
           Synthesize
    consensus · divergence · unique
               │
               ▼
     .claude/plans/<name>.md
```

```mermaid
flowchart TD
    User([User]):::actor --> Lead[Team Lead]:::lead
    Lead --> Q{Ambiguous?}:::decision
    Q -- yes --> Ask[/Ask user/]:::io --> Lead
    Q -- no --> Spawn(("parallel spawn")):::fork
    Lead --> Spawn
    Spawn --> CP[claude-planner<br/>Opus]:::agent
    Spawn --> XP[codex-planner<br/>codex -s read-only]:::agent
    CP --> Merge[Synthesize<br/>consensus · divergence · unique]:::lead
    XP --> Merge
    Merge --> Save[(.claude/plans/&lt;name&gt;.md)]:::store
    Save --> Done([Done]):::actor

    classDef actor fill:#1e293b,color:#fff,stroke:#0f172a;
    classDef lead fill:#f97316,color:#fff,stroke:#c2410c;
    classDef agent fill:#0ea5e9,color:#fff,stroke:#0369a1;
    classDef decision fill:#fde68a,color:#78350f,stroke:#b45309;
    classDef io fill:#fef3c7,color:#78350f,stroke:#b45309;
    classDef store fill:#e2e8f0,color:#0f172a,stroke:#475569;
    classDef fork fill:#fff,color:#1e293b,stroke:#1e293b,stroke-dasharray: 4 2;
```

```text
1. User           ── /cross-plan ──►  Team Lead
2. Team Lead      ── spawn ──────►    claude-planner   ┐
   Team Lead      ── spawn ──────►    codex-planner    ┘  parallel
3. claude-planner ── Claude plan ──►  Team Lead         ┐
   codex-planner  ── Codex plan ───►  Team Lead         ┘  await both
4. Team Lead      (synthesize)
5. Team Lead      ── final plan ──►   User
```

```mermaid
sequenceDiagram
    actor User
    participant Lead as Team Lead
    participant CP as claude-planner
    participant XP as codex-planner

    User->>Lead: /cross-plan <task>
    opt If ambiguous
        Lead->>User: Clarifying questions
        User-->>Lead: Answers
    end
    par Parallel spawn
        Lead->>+CP: Plan with Opus
    and
        Lead->>+XP: Plan with Codex (read-only)
    end
    CP-->>-Lead: Claude plan
    XP-->>-Lead: Codex plan
    Lead->>User: Synthesized plan
```

## Output

| Section | What it shows |
| --- | --- |
| **Consensus** | Items both planners agreed on |
| **Divergence** | Side-by-side disagreements + recommendation |
| **Unique Insights** | Points raised by only one planner |
| **Final Integrated Plan** | 6-heading synthesized plan |

Saved to `.claude/plans/<name>.md`.

## Failure modes

| claude | codex | Result |
| --- | --- | --- |
| ✅ | ✅ | Cross-verified |
| ✅ | ❌ | Claude only — *unverified* |
| ❌ | ✅ | Codex only — *unverified* |
| ❌ | ❌ | Retry suggested |

## Source

[`plugin/skills/cross-plan/SKILL.md`](https://github.com/yunmango/yunmango-claude-plugins/blob/main/plugin/skills/cross-plan/SKILL.md)
