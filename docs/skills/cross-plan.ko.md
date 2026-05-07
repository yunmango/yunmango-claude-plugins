# cross-plan

두 플래너(Claude, Codex)를 **병렬로** 돌린 뒤 Claude Code가 하나의 계획으로 합성합니다.

```
/yumango-plugins:cross-plan <작업 설명>
```

## 어느 skill이 맞나

| `cross-plan` | [`plan-verify`](plan-verify.md) |
| --- | --- |
| 작성자 둘이 병렬 | 작성자 1명 + 비평가 1명 |
| 벽시계 시간이 중요 | 검토자가 전체 계획을 봐야 함 |
| 접근법을 비교하고 싶음 | 명확한 `PASS / NEEDS_REVISION` 필요 |

## 흐름

```text
             사용자
               │
               ▼
            팀 리드 ◄── 명확화 (모호한 경우)
               │
        병렬 spawn (한 메시지, Agent 호출 2개)
        ┌──────┴──────┐
        ▼             ▼
  claude-planner   codex-planner
     (Opus)        (codex exec -s read-only)
        │             │
        └──────┬──────┘
               ▼
              합성
       합의 · 차이 · 고유
               │
               ▼
     .claude/plans/<name>.md
```

```mermaid
flowchart TD
    User([사용자]):::actor --> Lead[팀 리드]:::lead
    Lead --> Q{모호함?}:::decision
    Q -- 예 --> Ask[/사용자에게 질문/]:::io --> Lead
    Q -- 아니오 --> Spawn(("병렬 spawn")):::fork
    Lead --> Spawn
    Spawn --> CP[claude-planner<br/>Opus]:::agent
    Spawn --> XP[codex-planner<br/>codex -s read-only]:::agent
    CP --> Merge[합성<br/>합의 · 차이 · 고유]:::lead
    XP --> Merge
    Merge --> Save[(.claude/plans/&lt;name&gt;.md)]:::store
    Save --> Done([완료]):::actor

    classDef actor fill:#1e293b,color:#fff,stroke:#0f172a;
    classDef lead fill:#f97316,color:#fff,stroke:#c2410c;
    classDef agent fill:#0ea5e9,color:#fff,stroke:#0369a1;
    classDef decision fill:#fde68a,color:#78350f,stroke:#b45309;
    classDef io fill:#fef3c7,color:#78350f,stroke:#b45309;
    classDef store fill:#e2e8f0,color:#0f172a,stroke:#475569;
    classDef fork fill:#fff,color:#1e293b,stroke:#1e293b,stroke-dasharray: 4 2;
```

```text
1. 사용자         ── /cross-plan ──►  팀 리드
2. 팀 리드        ── spawn ──────►    claude-planner   ┐
   팀 리드        ── spawn ──────►    codex-planner    ┘  병렬
3. claude-planner ── Claude 계획 ──►  팀 리드           ┐
   codex-planner  ── Codex 계획 ───►  팀 리드           ┘  양쪽 대기
4. 팀 리드        (합성)
5. 팀 리드        ── 최종 계획 ──►    사용자
```

```mermaid
sequenceDiagram
    actor User as 사용자
    participant Lead as 팀 리드
    participant CP as claude-planner
    participant XP as codex-planner

    User->>Lead: /cross-plan <작업>
    opt 모호한 경우
        Lead->>User: 명확화 질문
        User-->>Lead: 답변
    end
    par 병렬 spawn
        Lead->>+CP: Opus로 계획
    and
        Lead->>+XP: Codex로 계획 (read-only)
    end
    CP-->>-Lead: Claude 계획
    XP-->>-Lead: Codex 계획
    Lead->>User: 합성된 계획
```

## 결과물

| 섹션 | 내용 |
| --- | --- |
| **합의 (Consensus)** | 두 플래너가 동의한 항목 |
| **차이 (Divergence)** | 좌우 비교 + 권고 |
| **고유 인사이트** | 한쪽만 짚은 항목 |
| **최종 통합 계획** | 6-헤딩 형식의 합성 계획 |

`.claude/plans/<name>.md`에 저장됩니다.

## 실패 모드

| claude | codex | 결과 |
| --- | --- | --- |
| ✅ | ✅ | 교차검증 완료 |
| ✅ | ❌ | Claude만 — *미검증* |
| ❌ | ✅ | Codex만 — *미검증* |
| ❌ | ❌ | 재시도 안내 |

## 원본

[`plugin/skills/cross-plan/SKILL.md`](https://github.com/yunmango/yunmango-claude-plugins/blob/main/plugin/skills/cross-plan/SKILL.md)
