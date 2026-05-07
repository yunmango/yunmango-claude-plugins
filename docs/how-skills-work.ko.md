# Skill 작동 원리

`cross-plan`이나 `plan-verify`가 "발동"될 때 실제로 무슨 일이 일어나는지 알 수 있도록, **Claude Code skill 시스템**을 짧게 안내합니다.

## 한 줄 정의

**Skill**은 frontmatter의 `description`과 본문 지시문으로 구성된 마크다운 파일(`SKILL.md`)입니다. 사용자의 요청이 description과 매치되면, Claude가 본문을 로드해 그 지시를 따릅니다.

Skill이 직접 코드를 실행하지는 않습니다. 적절한 시점에 Claude가 읽어 들이는 *추가 컨텍스트*입니다.

## Skill의 구조

이 플러그인의 모든 skill은 `plugin/skills/<name>/SKILL.md` 위치에 있고, 다음과 같은 구조를 가집니다:

```markdown
---
name: cross-plan
description: Cross-verification planning skill that spawns Claude and Codex
  planner agents in parallel... Trigger on "cross plan", "cross verify",
  "교차검증", "dual plan", or "/cross-plan".
invokable: true
---

# Cross-Plan Skill

(본문 — skill이 로드되었을 때 Claude가 따르는 지시)
```

핵심은 두 가지입니다:

| 필드 | 역할 |
| --- | --- |
| `description` (frontmatter) | 매칭용 텍스트. Claude는 사용 가능한 skill의 description을 훑어 사용자 의도에 가장 잘 맞는 것을 선택합니다. |
| 본문 (frontmatter 이후) | 실제 플레이북. Skill이 매치된 **이후에야** 컨텍스트에 로드되므로, 모든 대화에 부담을 주지 않으면서도 길고 상세하게 작성할 수 있습니다. |

## Skill이 트리거되는 방식

세 가지 트리거 경로가 있고, 이 플러그인의 skill은 모두를 지원합니다:

### 1. 슬래시 명령

사용자가 네임스페이스가 붙은 명령을 직접 입력합니다:

```
/yumango-plugins:cross-plan /healthz 엔드포인트 추가
```

명확한 경우 — Claude는 즉시 해당 skill을 로드합니다.

### 2. 자연어 매칭

사용자가 *"이 기능 계획 세우고 Codex가 검증하게 해줘"* 같은 말을 합니다. Claude는 설치된 모든 skill의 description을 보고 가장 잘 맞는 것을 고릅니다. 그래서 각 skill의 `description`은 트리거 문구를 명시적으로 나열합니다:

> Trigger on any of these signals — explicit commands like "/plan-verify", Korean phrases like "계획 검증", "검증 계획"... or English phrases like "verified plan", "plan and verify", "validate the plan".

### 3. 부정 트리거

좋은 description은 **언제 발동하지 않을지**도 명시합니다. `plan-verify`에서:

> Do NOT trigger for simple planning without verification, cross-plan (parallel dual planning), direct Codex delegation, or code review of existing changes.

이렇게 해서 겹치는 skill끼리 서로의 영역을 침범하지 않게 합니다.

## 매치 후 무슨 일이 일어나나

skill이 매치되면, Claude는 `SKILL.md`의 본문을 읽고 절차처럼 실행합니다. 이 플러그인의 skill 본문에는 다음이 기술됩니다:

- **역할.** 누가 무엇을 하는지 (예: 팀 리드 vs. 플래너 vs. 검증자).
- **아키텍처.** 단계와 어떤 서브에이전트가 어떤 순서로 실행되는지의 다이어그램.
- **프롬프트 템플릿.** 각 서브에이전트에게 전달되는 정확한 프롬프트 — 모델, reasoning 강도, 샌드박스 플래그 포함.
- **중요 사항.** 어떤 경우에도 지켜져야 하는 제약 (예: "Codex Verifier는 반드시 `--model gpt-5.5 --effort xhigh`를 사용해야 함").

서브에이전트는 `Agent` 도구로 생성됩니다. 예를 들어 두 skill 모두 Claude Planner에 `general-purpose`를 사용하고, `plan-verify`는 Codex Verifier에 `codex:codex-rescue`를 사용합니다. Codex CLI는 검증 시 read-only 샌드박스 모드로 실행됩니다.

## Skill 위치

| Skill | 파일 |
| --- | --- |
| `cross-plan` | `plugin/skills/cross-plan/SKILL.md` |
| `plan-verify` | `plugin/skills/plan-verify/SKILL.md` |

Claude가 따르는 전체 지시문을 읽고 싶다면 그 파일들이 정본입니다. 이 사이트의 페이지는 사용자를 위한 요약입니다.

## 더 읽을거리

- Anthropic 공식 문서: <https://docs.claude.com/en/docs/claude-code/overview>
- 플러그인 매니페스트: `plugin/.claude-plugin/plugin.json`
