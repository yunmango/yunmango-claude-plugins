# plan-verify

Claude Opus가 계획을 작성하고, Codex(xhigh)가 코드베이스 대비 검증해 verdict을 반환합니다.

```
/yumango-plugins:plan-verify <작업 설명>
```

## 어느 skill이 맞나

| `plan-verify` | [`cross-plan`](cross-plan.md) |
| --- | --- |
| 작성자 1명 + 비평가 1명 | 작성자 둘이 병렬 |
| 검토자가 전체 계획을 봐야 함 | 벽시계 시간이 중요 |
| `PASS / NEEDS_REVISION` verdict 필요 | 좌우 비교가 필요 |

## 흐름

```mermaid
flowchart TD
    User([사용자]):::actor --> Lead[팀 리드]:::lead
    Lead --> Q{모호함?}:::decision
    Q -- 예 --> Ask[/사용자에게 질문/]:::io --> Lead
    Q -- 아니오 --> CP[Claude Planner<br/>Opus]:::agent
    CP --> CV[Codex Verifier<br/>gpt-5.5 · xhigh]:::agent
    CV --> V{Verdict}:::decision
    V -- PASS --> Adopt[원안 채택]:::lead
    V -- "PASS_WITH_NOTES /<br/>NEEDS_REVISION" --> Triage[Triage]:::lead --> Build[수정 계획]:::lead
    Adopt --> Save[(.claude/plans/&lt;name&gt;.md)]:::store
    Build --> Save
    Save --> Done([완료]):::actor

    classDef actor fill:#1e293b,color:#fff,stroke:#0f172a;
    classDef lead fill:#f97316,color:#fff,stroke:#c2410c;
    classDef agent fill:#0ea5e9,color:#fff,stroke:#0369a1;
    classDef decision fill:#fde68a,color:#78350f,stroke:#b45309;
    classDef io fill:#fef3c7,color:#78350f,stroke:#b45309;
    classDef store fill:#e2e8f0,color:#0f172a,stroke:#475569;
```

```mermaid
sequenceDiagram
    actor User as 사용자
    participant Lead as 팀 리드
    participant CP as Claude Planner
    participant CV as Codex Verifier

    User->>Lead: /plan-verify <작업>
    opt 모호한 경우
        Lead->>User: 명확화 질문
        User-->>Lead: 답변
    end
    Lead->>+CP: 계획
    CP-->>-Lead: 계획
    Lead->>+CV: 검증 (read-only)
    CV-->>-Lead: Verdict + findings
    alt PASS
        Lead->>User: 원안
    else PASS_WITH_NOTES / NEEDS_REVISION
        Lead->>Lead: Triage + 수정
        Lead->>User: 수정 계획
    end
```

## Verdict별 처리

| Verdict | 결과 |
| --- | --- |
| **PASS** | 원안 그대로 채택 |
| **PASS_WITH_NOTES** | Triage → 경미한 수정 |
| **NEEDS_REVISION** | Triage → 수정 + 변경 목록 |

## Triage 규칙

Codex의 각 finding을 분류:

| 분류 | 사용 시점 |
| --- | --- |
| **ACCEPT** | 코드베이스 사실 정정 (기본값) |
| **ACCEPT_WITH_MODIFICATION** | 우려는 타당, 완화책은 가볍게 |
| **REJECT** | 경험적으로 틀림 / 범위 밖 / 추측 / 순수 스타일 — 한 줄 사유 필수 |

확신이 없으면 팀 리드가 분류 전에 참조 파일을 직접 읽습니다.

## 원본

[`plugin/skills/plan-verify/SKILL.md`](https://github.com/yunmango/yunmango-claude-plugins/blob/main/plugin/skills/plan-verify/SKILL.md)
