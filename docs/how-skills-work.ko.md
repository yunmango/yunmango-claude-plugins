# Skill 작동 원리

Skill은 `description`과 본문으로 구성된 마크다운 파일(`SKILL.md`)입니다. 사용자 요청이 description과 매치되면, Claude가 본문을 로드해 따릅니다.

## 구조

```markdown
---
name: cross-plan
description: ... Trigger on "cross plan", "교차검증", "/cross-plan".
---

# Cross-Plan Skill

(본문 — 매치 시 Claude가 따르는 지시)
```

| 필드 | 역할 |
| --- | --- |
| `description` | 매칭용 텍스트. Claude가 이걸 보고 가장 잘 맞는 skill을 고름. |
| 본문 | 실제 플레이북. 매치 **이후에만** 로드. |

## 세 가지 트리거 경로

| 경로 | 예시 |
| --- | --- |
| 슬래시 명령 | `/yumango-plugins:cross-plan /healthz 엔드포인트 추가` |
| 자연어 | *"이거 계획 세우고 Codex가 검증하게 해줘"* → `plan-verify` |
| 부정 매칭 | "Do NOT trigger for code review" — 겹치는 skill끼리 침범 방지 |

그래서 각 skill의 `description`은 트리거 문구와 안티 트리거를 명시합니다.

## 매치 후

Claude가 본문을 읽고 절차처럼 실행합니다. 이 플러그인의 skill 본문에는:

- **역할** — 팀 리드 vs. 플래너 vs. 검증자
- **아키텍처** — 단계 순서, 어떤 서브에이전트가 언제 실행되는지
- **프롬프트 템플릿** — 모델·reasoning 강도·샌드박스 플래그 포함한 정확한 프롬프트
- **중요 사항** — 어떤 경우에도 지켜야 할 제약 (예: *"Codex Verifier는 `--model gpt-5.5 --effort xhigh` 사용"*)

서브에이전트는 `Agent` 도구로 생성됩니다 — Claude Planner는 `general-purpose`, Codex Verifier는 `codex:codex-rescue`. Codex CLI는 read-only 샌드박스로 실행됩니다.

## 원본 파일

| Skill | 파일 |
| --- | --- |
| `cross-plan` | `plugin/skills/cross-plan/SKILL.md` |
| `plan-verify` | `plugin/skills/plan-verify/SKILL.md` |

이 파일들이 정본이고, 이 사이트는 요약입니다.

## 더 읽을거리

- [Anthropic — Claude Code overview](https://docs.claude.com/en/docs/claude-code/overview)
