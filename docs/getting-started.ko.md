# 시작하기

## 사전 조건

- [Claude Code](https://docs.claude.com/en/docs/claude-code/overview)
- [Codex CLI](https://github.com/openai/codex) — 두 skill 모두 검증을 Codex에 위임

```bash
claude --version
codex --version
```

## 설치

=== "마켓플레이스"

    ```bash
    /plugin marketplace add yunmango/yunmango-claude-plugins
    /plugin install yunmango-plugins@yunmango-claude-plugins
    ```

=== "로컬 / 개발"

    ```bash
    git clone https://github.com/yunmango/yunmango-claude-plugins.git
    claude --plugin-dir /path/to/yunmango-claude-plugins/plugin
    ```

`/help`로 확인 — `yunmango-plugins:deep-interview`, `yunmango-plugins:cross-plan`, `yunmango-plugins:plan-verify`가 보여야 합니다.

## 실행

### 선택: 의도 먼저 명확화

요청이 모호하면 `deep-interview`로 시작해 명세부터 만든 뒤 계획으로 넘어가세요:

```
/yunmango-plugins:deep-interview 우리 백엔드를 좀 정리하고 싶어
```

출력물(Goal / In-scope / Out-of-scope / Constraints / Done / Assumptions / Open questions)이 아래 계획 skill에 그대로 입력됩니다.

### 계획

=== "병렬 교차검증"

    ```
    /yunmango-plugins:cross-plan DB와 Redis 상태를 보고하는 /healthz 엔드포인트 추가
    ```

=== "계획 후 검증"

    ```
    /yunmango-plugins:plan-verify DB와 Redis 상태를 보고하는 /healthz 엔드포인트 추가
    ```

어느 skill이든:

1. 작업이 모호하면 명확화 질문을 함.
2. 작성 전에 코드베이스를 읽음.
3. 최종 계획을 `.claude/plans/<name>.md`에 저장.
4. 구현 진행 여부를 물음.

자연어로도 자동 트리거됩니다 — [Skill 작동 원리](how-skills-work.md) 참고.

## 문제 해결

| 증상 | 원인 |
| --- | --- |
| Codex 단계: *command not found* | `codex`가 `PATH`에 없음 — 재설치 후 동일 셸에서 확인 |
| 빈 / 잘린 계획 | 에이전트가 도구 호출로 턴을 끝냄 — 재실행 |
| Codex가 파일 수정 | read-only 샌드박스 플래그 누락 — 재실행 |
