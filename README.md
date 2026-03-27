# my-claude-settings

Anthropic 하네스(Planner-Generator-Evaluator 분리) + Superpowers(TDD, 마이크로태스크) + 기존 Agent Orchestration(모델 전략, 병렬 탐색, VERIFY)을 결합한 Claude Code 프로젝트 템플릿입니다.

## 프로젝트 구조

```
.claude/
  commands/
    plan.md          ← /plan (Planner, opus)
    generate.md      ← /generate (Generator, haiku+sonnet)
    evaluate.md      ← /evaluate (Evaluator, opus, 별도 세션)
.worktrees/          ← 세션별 git worktree 작업 공간 (.gitignore에 추가)
  {title}/           ← 예: .worktrees/auth-login/
CLAUDE.md            ← 프로젝트 루트 설정
specs/               ← Planner 출력 (예: specs/auth-login.md)
handoffs/            ← Generator → Evaluator 컨텍스트 전달
evaluation/          ← Evaluator 보고서
src/                 ← 구현 코드
```

## 모델 배정

| 에이전트 / 작업              | 모델     |
| ---------------------------- | -------- |
| Planner                      | opus     |
| Generator — SCOPE (탐색)     | haiku    |
| Generator — IMPLEMENT/REVIEW | sonnet   |
| Evaluator                    | opus     |

## 사용법

### 1단계: 기획 (opus)
```bash
claude /plan "소셜 미디어 대시보드 만들어줘"
```

### 2단계: 구현 (haiku + sonnet)
```bash
claude /generate "dashboard-ui"
```
Generator가 자동으로 `.worktrees/dashboard-ui` 를 생성하고 그 안에서 작업합니다.
내부 워크플로우:
```
Worktree 생성 → SCOPE(haiku×병렬) → PLAN → IMPLEMENT(TDD,sonnet) → REVIEW(/simplify) → VERIFY → REFLECT → HANDOFF
```

### 3단계: 평가 (opus, 새 세션에서!)
```bash
# 반드시 새 터미널/세션에서 실행
claude /evaluate "dashboard-ui"
```
Evaluator는 `.worktrees/dashboard-ui` 에서 검증을 수행합니다.

### PASS 후 머지
```bash
cd .worktrees/dashboard-ui && git checkout main && git merge dashboard-ui
git worktree remove .worktrees/dashboard-ui && git branch -d dashboard-ui
```

### 재작업 (FAIL 시)
```bash
claude /generate "dashboard-ui 재작업 - evaluation/dashboard-ui.md 참고"
```
기존 `.worktrees/dashboard-ui` 에서 이어서 작업합니다.

## 워크플로우 다이어그램

```
사용자 요청
    │
    ▼
┌──────────────────┐    specs/{title}.md
│ /plan (opus)     │──────────────────────┐
│ + SCOPE(haiku)   │                      │
└──────────────────┘                      │
                                          ▼
                   ┌───────────────────────────────────┐
                   │ /generate (haiku+sonnet)           │
                   │ 작업 공간: .worktrees/{title}       │
                   │                                    │
                   │  Worktree 생성                      │
                   │       │                            │
                   │  SCOPE ─→ PLAN ─→ IMPLEMENT        │
                   │    │              (TDD)             │
                   │  haiku            sonnet            │
                   │    ×2~3             │               │
                   │                 REVIEW              │
                   │               (/simplify)           │
                   │                     │               │
                   │                 VERIFY ────✗──→ 수정 │
                   │                     │               │
                   │                 REFLECT              │
                   │                     │               │
                   │                 HANDOFF              │
                   └─────────┬───────────────────────────┘
                             │
                   handoffs/{title}.md
                             │
                             ▼
                   ┌──────────────────────────────┐
                   │ /evaluate (opus)              │
                   │ (별도 세션)                    │
                   │ 검증 위치: .worktrees/{title}  │
                   │                               │
                   │ VERIFY 재검증                  │
                   │ 코드 검증                      │
                   │ 동작 검증                      │
                   │ 채점 + 판정                    │
                   └──────────┬────────────────────┘
                              │
                    ┌─────────┴─────────┐
                    │                   │
                  PASS               FAIL
                    │                   │
              main에 머지         evaluation/{title}.md
              worktree 정리             │
                    │                   ▼
                 다음 세션         /generate 재작업
                                  (기존 worktree 유지)
```

## 기존 규칙과의 통합 요약

| 기존 규칙 | 하네스 내 위치 |
|---|---|
| SCOPE (병렬 탐색, haiku) | /plan Step 2 + /generate Step 1 |
| PLAN (todo.md) | /plan의 specs/{title}.md로 대체 |
| IMPLEMENT (TDD) | /generate Step 3 |
| REVIEW (/simplify) | /generate Step 4 |
| VERIFY (test+typecheck+lint) | /generate Step 5 + /evaluate Step 2 (재검증) |
| REFLECT | /generate Step 6 → handoff에 기록 |
| COMMIT | VERIFY 통과 후 /generate 내에서 수행 |
