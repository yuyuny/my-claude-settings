# Workflow Reference

핵심 규칙은 `.claude/rules/multi-agent-workflow.md` 참조.
이 파일에는 상태 머신, 디렉토리 구조, 세미-자동화 상세 정보를 기록합니다.

---

## 세미-자동화 (Stop hook)

각 커맨드가 끝나면 Stop hook(`.claude/scripts/workflow-advance.sh`)이 자동으로 다음 단계를 안내합니다:
- 다음 명령어를 **클립보드에 복사**
- **데스크톱 알림** 발송 (macOS)
- **Claude 세션에 안내 메시지 주입**

사람이 개입해야 하는 **승인 게이트 3곳**:

| 상태 | 게이트 이유 |
|---|---|
| `spec_ready` | spec 내용 확정 전 검토 (잘못된 전제 차단) |
| `evaluated_pass/fail` | 머지 확인 또는 재작업/포기 결정 |
| Evaluator 실행 시점 | 별도 세션 수동 시작 (독립성 원칙) |

나머지 전환(brainstorm→spec, spec→generate, reflect→done)은 hook이 자동 진행을 권장합니다.

---

## 상태 머신

```
# /brainstorm 포함 경로:
idle → brainstorming → spec_draft → spec_ready → generating
                                              → handoff_ready → evaluating → evaluated_pass → reflecting → done
                                                                           → evaluated_fail  (사람이 재작업/스펙재정의/포기 결정)

# /brainstorm 생략 시: idle → spec_ready (brainstorming/spec_draft 건너뜀)
```

- `brainstorming`: `/brainstorm` Step 1(제목 결정) 직후 기록
- `spec_draft`: `/brainstorm` 완료 후 기록 — `/spec`이 아직 실행되지 않은 중간 상태
- `spec_ready`: `/spec` 완료 후 기록 (brainstorm 유무 무관)

상태는 `.claude-workflow/sessions/{title}.json` 에 기록됩니다 (gitignore, 로컬 전용).
현재 상태 조회: `/workflow-status`

---

## 동시 세션

여러 `{title}`을 병렬로 진행해도 충돌 없음:
- 상태 파일이 세션별로 분리 (`.claude-workflow/sessions/{title}.json`)
- Generator 워크트리가 `.worktrees/{title}`로 물리 격리
- Stop hook은 `CLAUDE_WORKFLOW_TITLE` 환경변수로 현재 세션 식별 (미설정 시 최신 파일 fallback)

---

## 디렉토리

- `.worktrees/` — git worktree 작업 공간 (.gitignore 추가)
- `.claude-workflow/` — 워크플로우 실행 상태 (gitignore, 로컬 전용)
- `brainstorms/` — Brainstormer 산출물. **메인 브랜치**에 커밋. (`/brainstorm` 생략 시 없음)

아래 디렉토리는 **워크트리 브랜치** (`.worktrees/{title}/`) 안에 생성됩니다:
- `specs/` — `/spec`이 작성. Generator 수정 금지. Evaluator PASS 판정 후 체크박스만 업데이트.
- `handoffs/` — Generator → Evaluator 컨텍스트
- `evaluation/` — Evaluator 보고서
- `reflections/` — 세션 회고 기록

머지(`git merge {title}`) 시 위 산출물이 모두 메인 브랜치에 반영됩니다.
