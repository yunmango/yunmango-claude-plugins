# cross-plan

**병렬 교차검증 계획.** Claude Code가 팀 리드 역할을 맡아 두 개의 독립된 플래너 에이전트를 동시에 실행한 뒤, 그 결과로부터 단일한 검증된 계획을 합성합니다.

## 언제 쓰나

다음과 같은 경우 `cross-plan`이 적합합니다:

- 같은 작업에 대해 **두 개의 독립된 시각**을 얻은 뒤 결정을 내리고 싶을 때.
- 벽시계 시간이 중요할 때 — 두 플래너가 병렬로 실행됩니다.
- 어떤 에이전트의 코드베이스 해석이 더 정확할지 미리 알 수 없어 비교가 필요할 때.

대신 한 명이 작성하고 한 명이 비평하는 순차 흐름이 필요하다면 [`plan-verify`](plan-verify.md)를 보세요.

## 빠른 시작

```
/yumango-plugins:cross-plan <작업 설명>
```

또는 의도로 트리거:

> user 모델을 UUID로 마이그레이션하는 계획을 교차검증해줘.

## 실행 흐름

```
Claude Code (팀 리드)
    │
    ├── Step 0: 작업 분석 및 명확화 질문 (필요 시)
    │
    ├── Step 1: 두 플래너를 병렬 spawn (백그라운드)
    │     ├── claude-planner   (Opus, Read/Glob/Grep로 코드베이스 읽기)
    │     └── codex-planner    (Codex, `codex exec -s read-only` 실행)
    │
    ├── Step 2: 두 결과 대기
    │
    ├── Step 3: 실패 처리 (한쪽만 성공 시 single-source 폴백)
    │
    ├── Step 4: 교차검증 및 합성
    │
    ├── Step 5: 최종 계획을 .claude/plans/<name>.md에 저장
    │
    └── Step 6: 사용자에게 구현 진행 여부 질문
```

팀 리드는 **자체 계획을 작성하지 않습니다** — 명확화·조율·합성만 담당합니다.

## 결과물

합성된 출력은 네 부분으로 구성됩니다:

| 섹션 | 목적 |
| --- | --- |
| **합의 (Consensus)** | 두 플래너가 동의한 항목. 신뢰도가 가장 높음. |
| **차이 (Divergence)** | 플래너들이 의견을 달리한 항목의 좌우 비교 표 + 팀 리드의 권고. |
| **고유 인사이트 (Unique Insights)** | 한 플래너만 짚은 가치 있는 지점. 평가 후 합당하면 반영. |
| **최종 통합 계획 (Final Integrated Plan)** | 합성된 계획. 6개 고정 헤딩 형식 (Goal, Analysis, Architecture, Implementation Steps, Testing Strategy, Edge Cases & Risks). |

최종 계획은 `.claude/plans/<kebab-case-name>.md`에 저장되어 나중에 다시 보거나, 구현 시작점으로 넘길 수 있습니다.

## 실패 모드

한 플래너가 죽어도 유의미한 결과를 받습니다:

| claude-planner | codex-planner | 동작 |
| --- | --- | --- |
| OK | OK | 정상 교차검증 흐름 |
| OK | FAIL | Claude 계획만 표시. *"Single-source plan (unverified)"*로 라벨링 |
| FAIL | OK | Codex 계획만 표시. *"Single-source plan (unverified)"*로 라벨링 |
| FAIL | FAIL | 양쪽 오류 보고 후 재시도 안내 |

## 팁

- **명확화 단계를 건너뛰지 마세요.** 작업 설명이 모호하면 (해석이 여러 갈래거나 제약이 빠졌으면) 팀 리드가 질문합니다. 사후 수정보다 사전 답변이 훨씬 좋은 계획을 만듭니다.
- **두 답이 모두 그럴듯한 설계 결정에 사용하세요.** 작업이 기계적이라면 단일 플래너로 충분합니다 — `plan-verify`(또는 skill 없이)가 더 저렴합니다.
- **차이 표를 꼼꼼히 보세요.** 가장 유용한 인사이트는 합의가 아니라 차이에서 나옵니다.

## 원본

프롬프트 템플릿과 서브에이전트 설정을 포함한 전체 실행 명세는 다음 파일에 있습니다:

- [`plugin/skills/cross-plan/SKILL.md`](https://github.com/yunmango/yunmango-claude-plugins/blob/main/plugin/skills/cross-plan/SKILL.md)
