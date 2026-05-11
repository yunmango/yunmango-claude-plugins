# yunmango-plugins

**의도 명확화와 교차검증 계획 수립**용 Claude Code 플러그인 — 코드를 쓰기 전에 사용.

## Skills

| Skill | 역할 |
| --- | --- |
| [`deep-interview`](skills/deep-interview.md) | 모호한 요청을 계획 **이전에** Socratic Q&A로 명세화 |
| [`cross-plan`](skills/cross-plan.md) | Claude + Codex가 **병렬로** 계획을 작성한 뒤 합성 |
| [`plan-verify`](skills/plan-verify.md) | Claude가 작성, Codex가 코드베이스 대비 **검증** |

`deep-interview`는 계획 skill의 *상위(upstream)* 단계입니다. 두 계획 skill은 *팀 리드* 패턴을 따릅니다 — Claude Code는 명확화·조율·합성만 하며, 직접 계획을 작성하지 않습니다.

## 다음 단계

- [시작하기](getting-started.md) — 설치하고 첫 계획 실행
- [Skill 작동 원리](how-skills-work.md) — 무엇이 skill을 트리거하고, 매치 후 무슨 일이 일어나는지
