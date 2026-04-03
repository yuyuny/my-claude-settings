# Multi-Agent Workflow

## 모델 배정

| 작업                           | 모델                 |
| ------------------------------ | -------------------- |
| 탐색 (SCOPE)                   | `haiku` — 병렬 2~3개 |
| 구현/리뷰 (IMPLEMENT, REVIEW)  | `sonnet`             |
| 설계/평가 (Planner, Evaluator) | `opus`               |
| 회고 (Reflector)               | `sonnet`             |

## 워크플로우

`/plan` → `/generate` → `/evaluate` (별도 세션) → `/reflect`

상세 프로세스는 각 커맨드 파일 참고 (`.claude/commands/`)

## 핵심 규칙

- 세션 식별자는 kebab-case: `auth-login`, `dashboard-ui`
- Generator는 `.worktrees/{title}`에서 작업 (메인 브랜치 직접 수정 금지)
- Evaluator는 반드시 Generator와 다른 세션에서 실행
- TDD 강제 (RED → GREEN → REFACTOR)
- `/simplify`로 매 2-3 태스크 후 diff 기반 코드 리뷰 (결과는 핸드오프 REVIEW 로그에 기록)
- VERIFY 통과 전 핸드오프 금지
- 독립 작업은 항상 병렬 실행

## 디렉토리

- `.worktrees/` — git worktree 작업 공간 (.gitignore 추가)
- `specs/` — Planner 스펙 (Generator 수정 금지. Evaluator PASS 판정 후 체크박스만 업데이트)
- `handoffs/` — Generator → Evaluator 컨텍스트
- `evaluation/` — Evaluator 보고서
- `reflections/` — 세션 회고 기록
