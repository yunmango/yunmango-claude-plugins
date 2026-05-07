# yumango-plugins

**교차검증 계획 수립**용 Claude Code 플러그인. 코드를 쓰기 전에 Claude와 Codex가 서로의 작업을 검토합니다.

## Skills

| Skill | 역할 |
| --- | --- |
| [`cross-plan`](skills/cross-plan.md) | Claude + Codex가 **병렬로** 계획을 작성한 뒤 합성 |
| [`plan-verify`](skills/plan-verify.md) | Claude가 작성, Codex가 코드베이스 대비 **검증** |

두 skill 모두 *팀 리드* 패턴을 따릅니다 — Claude Code는 명확화·조율·합성만 하며, 직접 계획을 작성하지 않습니다.

## 다음 단계

- [시작하기](getting-started.md) — 설치하고 첫 계획 실행
- [Skill 작동 원리](how-skills-work.md) — 무엇이 skill을 트리거하고, 매치 후 무슨 일이 일어나는지
