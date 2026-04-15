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
- Generator는 `.worktrees/{title}`에서 작업 (메인 브랜치 직접 수정 금지)
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

## 디렉토리

- `.worktrees/` — git worktree 작업 공간 (.gitignore 추가)
- `brainstorms/` — Brainstormer 산출물 (Spec Writer 입력. `/brainstorm` 생략 시 없음)
- `specs/` — Spec Writer 스펙 (Generator 수정 금지. Evaluator PASS 판정 후 체크박스만 업데이트)
- `handoffs/` — Generator → Evaluator 컨텍스트
- `evaluation/` — Evaluator 보고서
- `reflections/` — 세션 회고 기록
