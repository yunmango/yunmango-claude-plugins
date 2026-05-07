# 시작하기

깨끗한 환경에서 첫 교차검증 계획을 실행하기까지의 과정을 안내합니다.

## 사전 조건

- **[Claude Code](https://docs.claude.com/en/docs/claude-code/overview)** 설치 및 인증.
- **[Codex CLI](https://github.com/openai/codex)** 설치 및 인증. 두 skill 모두 검증 작업을 Codex에 위임하기 때문에, 이게 없으면 검증 단계에서 실패합니다.

둘 다 동작하는지 확인:

```bash
claude --version
codex --version
```

## 플러그인 설치

### 옵션 A — 마켓플레이스 (권장)

```bash
/plugin marketplace add yunmango/yunmango-claude-plugins
/plugin install yumango-plugins@yunmango-claude-plugins
```

### 옵션 B — 로컬 / 개발용

```bash
git clone https://github.com/yunmango/yunmango-claude-plugins.git
claude --plugin-dir /path/to/yunmango-claude-plugins/plugin
```

## 설치 확인

Claude Code 세션 안에서 사용 가능한 skill 목록 확인:

```
/help
```

`yumango-plugins:cross-plan`과 `yumango-plugins:plan-verify`가 보여야 합니다.

## 첫 계획 실행

용도에 맞게 skill을 선택하세요:

=== "교차검증 계획 (병렬)"

    두 플래너가 **동시에** 실행됩니다 — 벽시계 시간이 짧고, 두 개의 독립된 시각을 얻습니다.

    ```
    /yumango-plugins:cross-plan DB와 Redis 상태를 보고하는 /healthz 엔드포인트 추가
    ```

=== "계획 후 검증 (순차)"

    Claude가 먼저 작성하고, Codex가 그것을 비평합니다. 더 느리지만, Codex가 검토 시 전체 계획을 보고 검증합니다.

    ```
    /yumango-plugins:plan-verify DB와 Redis 상태를 보고하는 /healthz 엔드포인트 추가
    ```

어느 skill이든 다음을 수행합니다:

1. 요청이 모호하면 명확화 질문을 합니다.
2. 플래너를 실행합니다 — 작성 전에 코드베이스를 읽습니다.
3. 합의·차이·리스크가 명시된 **구조화된 계획**을 생성합니다.
4. 최종 계획을 `.claude/plans/<name>.md`에 저장하고, 구현으로 넘어갈지 묻습니다.

## 슬래시 명령 없이 트리거하기

두 skill은 자연어로도 자동 트리거됩니다. 예:

- "이 기능 계획 세우고 Codex가 검증하게 해줘" → `plan-verify`
- "auth 미들웨어 리팩토링 교차검증해줘" → `cross-plan`
- "계획 좀 단단하게 세워줘" → `plan-verify`

매칭이 어떻게 일어나는지는 [Skill 작동 원리](how-skills-work.md)를 참고하세요.

## 문제 해결

**Codex 단계에서 "command not found"가 납니다.**
Codex CLI가 `PATH`에 없습니다. 재설치 후, Claude Code를 띄운 동일한 셸에서 `codex --version`이 동작하는지 확인하세요.

**플래너가 빈 계획이나 잘려 나간 계획을 반환합니다.**
에이전트가 텍스트 메시지가 아닌 도구 호출로 턴을 종료한 경우입니다. skill을 다시 실행하세요 — 두 skill 모두 마지막 메시지로 전체 계획을 출력하라는 명시적 지시를 포함하지만, 에이전트가 가끔 이를 어깁니다.

**Codex가 검토만 하지 않고 파일을 수정합니다.**
read-only 샌드박스 플래그가 누락된 경우입니다. skill을 다시 실행하세요. 번들된 프롬프트는 항상 read-only 샌드박스 지시를 포함합니다.
