# yumango-plugins

**교차검증** 기반의 계획 수립 skill을 묶어 놓은 Claude Code 플러그인입니다 — Claude와 Codex가 서로의 작업을 검토하므로, 코드를 짜기 전에 더 신뢰할 수 있는 계획을 얻을 수 있습니다.

## 구성

| Skill | 용도 |
| --- | --- |
| [`cross-plan`](skills/cross-plan.md) | Claude와 Codex 플래너를 **병렬로** 실행한 뒤, 교차검증된 계획으로 합성합니다. |
| [`plan-verify`](skills/plan-verify.md) | Claude가 계획 초안을 작성한 뒤 Codex가 그 계획을 코드베이스에 비추어 **독립적으로 검증**합니다. |

두 skill 모두 "팀 리드" 패턴을 따릅니다 — Claude Code 자체는 계획을 작성하지 않습니다. 작업을 명확화하고, 플래너들을 조율하고, 최종 결과를 합성하는 역할만 합니다.

## 왜 쓰나

- **두 개의 시각, 하나의 계획.** 같은 코드베이스를 읽는 독립된 에이전트는 서로 다른 누락 지점과 리스크를 짚어내는 경향이 있습니다. 합성 단계에서 합의·차이·고유 인사이트가 드러납니다.
- **코드베이스 기반.** 모든 계획은 에이전트가 실제 소스 파일을 읽은 뒤에 생성됩니다 — 파일 이름만 보고 추측하지 않습니다.
- **즉시 사용 가능.** 자연어 요청(예: *"이거 계획 세우고 Codex가 검증하게 해줘"*)이나 슬래시 명령(`/yumango-plugins:cross-plan`, `/yumango-plugins:plan-verify`)으로 자동 트리거됩니다.

## 다음 단계

- 처음 사용한다면 [시작하기](getting-started.md)부터.
- Claude Code skill 시스템 자체가 궁금하다면 [Skill 작동 원리](how-skills-work.md).
- 특정 skill을 바로 써보고 싶다면 [`cross-plan`](skills/cross-plan.md) 또는 [`plan-verify`](skills/plan-verify.md)로.
