# plan-verify

**순차 계획-검증 워크플로.** Claude Opus가 구현 계획 초안을 작성한 뒤, Codex(xhigh reasoning)가 실제 코드베이스에 비추어 그 계획을 독립적으로 검증하고 verdict을 반환합니다.

## 언제 쓰나

다음과 같은 경우 `plan-verify`가 적합합니다:

- **한 명이 작성하고 한 명이 비평**하는 흐름이 필요할 때 (병렬 두 작성자가 아님).
- 검토 모델이 작업 설명만이 아닌 **전체 계획을 보고** 검증하기를 원할 때.
- 구현 시작 전에 명확한 **verdict** (`PASS` / `PASS_WITH_NOTES` / `NEEDS_REVISION`)를 원할 때.

두 플래너를 병렬로 돌려 비교하는 흐름이 더 맞다면 [`cross-plan`](cross-plan.md)을 보세요.

## 빠른 시작

```
/yumango-plugins:plan-verify <작업 설명>
```

또는 의도로 트리거:

> auth 미들웨어 리팩토링 계획 세우고 Codex가 검증하게 해줘.

> 계획 좀 단단하게 세워줘

## 실행 흐름

```
Claude Code (팀 리드)
    │
    ├── Step 0: 요구사항 분석 및 모호성 명확화
    │
    ├── Step 1: Claude Planner (foreground)
    │     └── 코드베이스 탐색 → 구조화된 계획 반환
    │
    ├── Step 2: Codex Verifier (foreground)
    │     └── codex:codex-rescue (--model gpt-5.5 --effort xhigh)
    │     └── 코드베이스 대비 계획 검증
    │     └── Confirmed / Gaps / Risks / Ordering Issues / Verdict 반환
    │
    ├── Step 3: 최종 계획 합성 (명시적 triage 단계 포함)
    │
    └── Step 4: 계획 저장 및 진행 여부 질문
```

Step 1과 Step 2는 **순차로** 실행됩니다 — 검증자는 작업 설명만이 아니라 플래너의 출력 자체를 봅니다.

## Verdict

Codex Verifier는 다음 중 하나를 반환합니다:

| Verdict | 의미 |
| --- | --- |
| **PASS** | 계획에 문제가 없음. Claude의 원안이 최종 계획으로 채택됨. |
| **PASS_WITH_NOTES** | 실행 가능하지만 짚을 만한 누락이나 리스크가 있음. Triage 진행 후 수용된 항목을 반영해 최종 계획을 만듦. |
| **NEEDS_REVISION** | 중대한 문제 (의존성 누락, 잘못된 파일 참조, 순서 오류 등) 존재. Triage 진행 후 변경 요약과 함께 계획 재작성. |

## Findings triage (Step 3a)

팀 리드는 Codex의 발견 사항을 **무조건 수용하지 않습니다**. Gaps, Risks, Ordering Issues 각각을 분류합니다:

- **ACCEPT** — 그대로 반영. 코드베이스 사실 정정(파일 경로, 함수 시그니처, 순서 오류 등)의 기본값.
- **ACCEPT_WITH_MODIFICATION** — 반영하되 표현을 다듬거나 범위를 좁히거나 단계를 분할. 우려는 타당하나 제안된 완화책이 과한 경우.
- **REJECT** — 발견이 경험적으로 틀렸거나, 범위 밖이거나, 추측적이거나, 스타일 문제일 때만 허용. 각 REJECT는 한 줄짜리 사유를 동반.

확신이 안 서면 팀 리드가 분류 전에 관련 파일을 직접 읽습니다 — 영향이 큰 항목(아키텍처 변경, regex 정확성, 순서 이슈, 의존성 누락)에 대해서는 trust-but-verify가 기본입니다.

## 결과물

출력 구조:

```text
## Verification Summary

**Verdict**: <PASS | PASS_WITH_NOTES | NEEDS_REVISION>

### Codex Verification Highlights
- Confirmed: ...
- Gaps: ...
- Risks: ...

### Findings Triage  (Verdict이 PASS면 생략)
- ACCEPT: ...
- ACCEPT_WITH_MODIFICATION: ...
- REJECT: ...   (각 항목에 사유 첨부)

### Final Verified Plan
<6개 헤딩 계획>
```

최종 계획은 *"Planned by Claude Opus · Verified by Codex (xhigh reasoning)"* 푸터와 함께 `.claude/plans/<kebab-case-name>.md`에 저장됩니다.

## 팁

- **`PASS_WITH_NOTES`가 가장 흔한 verdict입니다.** 비자명한 작업에서 깨끗한 `PASS`는 드뭅니다. 노트는 저렴한 보험으로 다루세요.
- **순서 이슈를 주의 깊게 보세요.** Codex는 "단계 N이 단계 N+2까지 만들어지지 않는 무언가에 의존함" 같은 패턴을 찾는 데 특히 강합니다. 거의 항상 수용 가치가 있습니다.
- **`REJECT`는 드물어야 합니다.** 발견 항목 대부분을 reject하고 있다면, 플래너 초안이 코드베이스와 동떨어져 있을 가능성이 큽니다 — 더 구체적인 작업 설명으로 skill을 다시 실행하세요.

## 원본

플래너와 검증자 프롬프트 템플릿을 포함한 전체 실행 명세는 다음 파일에 있습니다:

- [`plugin/skills/plan-verify/SKILL.md`](https://github.com/yunmango/yunmango-claude-plugins/blob/main/plugin/skills/plan-verify/SKILL.md)
