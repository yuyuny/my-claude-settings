# Multi-Agent Workflow

## 모델 배정

| 작업                        | 모델                   |
| --------------------------- | ---------------------- |
| 탐색 (SCOPE)                | `sonnet` — 병렬 2~3개 |
| 구현 (IMPLEMENT)            | `sonnet`               |
| 리뷰 (REVIEW)               | `opus`                 |
| 브레인스토밍 (Brainstormer) | `opus`                 |
| 스펙 작성 (Spec Writer)     | `sonnet`               |
| 평가 (Evaluator)            | `opus`                 |
| 회고 (Reflector)            | `sonnet`               |

> 메인 세션은 `sonnet`을 가정. `/generate`를 `opus`로 띄우면 IMPLEMENT/PLAN 전구간 비용 급증.

## 워크플로우

`/brainstorm` (선택) → `/spec` → `/generate` → `/evaluate` (별도 세션) → `/reflect`

`/brainstorm`은 옵션이지 기본이 아님. 메인 세션에서 요구사항이 이미 명확하다면 생략하고 `/spec`으로 바로 시작.

상세 프로세스는 각 커맨드 파일 참고 (`.claude/commands/`)

## 핵심 규칙

- 세션 식별자는 kebab-case: `auth-login`, `player-movement`
- `/spec`부터 `.worktrees/{title}`에서 작업 (메인 브랜치 직접 수정 금지). `/brainstorm`은 메인에서 실행.
- Evaluator는 반드시 Generator와 다른 세션에서 실행
- 검증 게이트 강제 — 게이트 정의는 `.claude/rules/verify-commands.md` 참조. 코드 영역 기본값: TDD (RED → GREEN → REFACTOR). 테스트가 불가능한 영역(UI 레이아웃, 에셋, 밸런싱 수치 등)은 대체 검증 수단을 스펙의 검증 기준에 명시하고, 핸드오프에 사유를 기록할 것.
- `/simplify`로 diff 기반 코드 리뷰 — **세션당 최소 1회 필수** + 매 2-3 태스크당 1회 (결과는 핸드오프 REVIEW 로그에 기록). 태스크 수가 적어도 면제되지 않음.
- VERIFY 통과 전 핸드오프 금지
- 독립 작업은 항상 병렬 실행
- 참고 자료(specs/handoffs/evaluation 등)는 필요한 부분만 인용 — 요약·재작성 금지

## 서브에이전트 출력 계약

모든 서브에이전트(SCOPE, REVIEW 등)는 메인 세션 컨텍스트를 보호하기 위해 다음 규칙을 따름:

- **Bullet-only 반환**: bullet 리스트로만 반환. raw 코드·파일 내용 덤프 금지. 코드 스니펫은 3줄 이내.
- **15 bullet 상한**: 에이전트당 최대 15개 bullet. 초과 시 우선순위 top 15로 선별.
- **파일 직접 쓰기 우선**: 결과가 파일(핸드오프/평가/회고)에 저장될 것이라면, 서브에이전트가 직접 append하고 메인에는 "완료 Y/N + critical 여부"만 보고.
- **문서 요약 금지**: 참고 자료는 필요한 부분만 인용. 요약·재작성 금지.

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

### 상태 머신

```
# /brainstorm 포함 경로:
idle → brainstorming → spec_draft → spec_ready → generating
                                              → handoff_ready → evaluating → evaluated_pass → reflecting → done
                                                                           → evaluated_fail  (사람이 재작업/스펙재정의/포기 결정)

# /brainstorm 생략 경로 (/spec 직접 실행):
idle → spec_ready → generating → ...
```

- `brainstorming`: `/brainstorm` Step 1(제목 결정) 직후 기록
- `spec_draft`: `/brainstorm` 완료 후 기록 — `/spec`이 아직 실행되지 않은 중간 상태
- `spec_ready`: `/spec` 완료 후 기록 (brainstorm 유무 무관)
- `/brainstorm` 생략 시 `spec_draft`는 거치지 않고 `idle → spec_ready`로 직접 전이

상태는 `.claude-workflow/sessions/{title}.json` 에 기록됩니다 (gitignore, 로컬 전용).
현재 상태 조회: `/workflow-status`

### 동시 세션

여러 `{title}`을 병렬로 진행해도 충돌 없음:
- 상태 파일이 세션별로 분리 (`.claude-workflow/sessions/{title}.json`)
- Generator 워크트리가 `.worktrees/{title}`로 물리 격리
- Stop hook은 `CLAUDE_WORKFLOW_TITLE` 환경변수로 현재 세션 식별 (미설정 시 최신 파일 fallback)

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
