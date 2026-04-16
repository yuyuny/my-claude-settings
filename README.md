# my-claude-settings

멀티에이전트 워크플로우(Brainstormer → Spec Writer → Generator → Evaluator → Reflector)를 구현한 Claude Code 프로젝트 템플릿입니다.

## 프로젝트 구조

```
.claude/
  commands/
    brainstorm.md      ← /brainstorm (Brainstormer, opus, 선택)
    spec.md            ← /spec (Spec Writer, sonnet)
    generate.md        ← /generate (Generator, sonnet)
    evaluate.md        ← /evaluate (Evaluator, opus, 별도 세션)
    reflect.md         ← /reflect (Reflector, sonnet)
    reflect-batch.md   ← /reflect-batch (패턴 집계, sonnet)
    workflow-status.md ← /workflow-status (상태 조회, 읽기 전용)
  rules/
    multi-agent-workflow.md  ← 핵심 워크플로우 규칙
    verify-commands.md       ← 검증 게이트 정의 (프로젝트마다 수정)
    web-browsing.md          ← 웹 탐색 규칙
  scripts/
    workflow-advance.sh      ← Stop hook + 상태 기록 + merge/cleanup
    workflow-status.py       ← /workflow-status 스크립트
.worktrees/            ← 세션별 git worktree (.gitignore)
  {title}/             ← 예: .worktrees/auth-login/
    specs/             ← Spec Writer 산출물
    handoffs/          ← Generator → Evaluator 컨텍스트
    evaluation/        ← Evaluator 보고서
    reflections/       ← 세션 회고
brainstorms/           ← /brainstorm 산출물 (메인 브랜치)
docs/
  GLOSSARY.md          ← 도메인 용어 사전
evaluation/
  rubric-v1.md         ← 평가 루브릭
reflections/
  index.md             ← 회고 인덱스 + 배치 집계 기록
```

## 모델 배정

| 에이전트 / 작업        | 모델   |
|------------------------|--------|
| Brainstormer           | opus   |
| Spec Writer            | sonnet |
| Generator — SCOPE      | sonnet |
| Generator — IMPLEMENT  | sonnet |
| Evaluator              | opus   |
| Reflector              | sonnet |
| Reflect-Batch          | sonnet |

## 사용법

### 0단계: (선택) 브레인스토밍 (opus)

요구사항이 모호할 때 먼저 실행합니다.

```bash
claude "/brainstorm {title}"
```

### 1단계: 스펙 작성 (sonnet)

```bash
claude "/spec {title}"
```

### 2단계: 구현 (sonnet)

```bash
claude "/generate {title}"
```

Generator가 `.worktrees/{title}` 안에서 작업합니다:

```
SCOPE(sonnet×병렬) → PLAN → IMPLEMENT(TDD) → REVIEW(/simplify) → VERIFY → HANDOFF
```

### 3단계: 평가 (opus, **반드시 새 세션에서**)

```bash
# 새 터미널/세션에서 실행 — Evaluator 독립성 원칙
claude "/evaluate {title}"
```

### 4단계: 회고 + 머지

PASS 판정 후 순서를 지켜 진행합니다:

```bash
# ① 회고 먼저 (worktree 안 산출물 참조 필요)
claude "/reflect {title}"

# ② 회고 완료 후 머지 (프로젝트 루트에서 실행)
git checkout main && git merge {title}
git worktree remove .worktrees/{title} && git branch -d {title}
```

> **주의**: `/reflect` 전에 worktree를 삭제하면 산출물을 참조할 수 없습니다.

### 재작업 (FAIL 시)

```bash
# evaluation/{title}.md 피드백 반영해 재작업
claude "/generate {title}"
```

기존 `.worktrees/{title}` 에서 이어서 작업합니다.

### 상태 확인

```bash
claude "/workflow-status"
```

---

## 워크플로우 다이어그램

```
사용자 요청
    │
    ▼
┌─────────────────────┐
│ /brainstorm (opus)  │  brainstorms/{title}.md  [선택]
│ 소크라틱 대화        │─────────────────────────────┐
└─────────────────────┘                             │
    │ (또는 바로 /spec)                              │
    ▼                                              ▼
┌─────────────────────────────────────────────────────┐
│ /spec (sonnet)                                      │
│ 워크트리 생성: .worktrees/{title}                    │
│ SCOPE → specs/{title}.md 작성 → 커밋               │
└─────────────────────────────────────────────────────┘
    │
    ▼  [승인 게이트: spec 검토]
┌─────────────────────────────────────────────────────┐
│ /generate (sonnet)                                  │
│ 작업 공간: .worktrees/{title}                       │
│                                                     │
│  SCOPE(sonnet×2~3) → PLAN → IMPLEMENT(TDD)         │
│                              │                      │
│                           REVIEW(/simplify, opus)   │
│                              │                      │
│                           VERIFY ──✗──→ 수정        │
│                              │                      │
│                           HANDOFF                   │
└──────────────────────┬──────────────────────────────┘
                       │ handoffs/{title}.md
                       ▼
            ┌──────────────────────────────┐
            │ /evaluate (opus, 새 세션!)    │
            │ 검증 위치: .worktrees/{title} │
            │                              │
            │ VERIFY 재검증                 │
            │ 코드 검증                     │
            │ 동작 검증                     │
            │ 채점 + 판정                   │
            └──────────┬───────────────────┘
                       │
             ┌─────────┴─────────┐
             │                   │
           PASS               FAIL
             │                   │
    [승인 게이트]         evaluation/{title}.md
             │                   │
      ① /reflect            /generate 재작업
      ② git merge           (기존 worktree 유지)
      ③ worktree 정리
             │
      /reflect-batch
      (5회 이상 누적 시)
```

---

## 세미-자동화 (Stop hook)

각 커맨드가 끝나면 Stop hook이 자동으로:
- 다음 명령어를 **클립보드에 복사** (macOS)
- **데스크톱 알림** 발송 (macOS)
- **Claude 세션에 안내 메시지 주입**

사람이 개입해야 하는 **승인 게이트 3곳**:

| 상태 | 이유 |
|------|------|
| `spec_ready` | spec 내용 확정 전 검토 |
| `evaluated_pass` | 머지 확인 |
| `evaluated_fail` | 재작업/스펙재정의/포기 결정 |

---

## 기존 규칙과의 통합 요약

| 기존 규칙 | 하네스 내 위치 |
|-----------|----------------|
| SCOPE (병렬 탐색) | /brainstorm Step 2 + /spec Step 2 + /generate Step 1 |
| PLAN | specs/{title}.md + handoffs/{title}.md |
| IMPLEMENT (TDD) | /generate Step 3 |
| REVIEW (/simplify) | /generate Step 4 |
| VERIFY (test+typecheck+lint) | /generate Step 5 + /evaluate Step 2 (재검증) |
| HANDOFF | /generate Step 6 |
| REFLECT | /reflect 커맨드 (사이클 종료 후) |

---

## 빠른 설정

1. 이 저장소를 프로젝트에 복사합니다
2. `.claude/rules/verify-commands.md`의 **현재 프로젝트 게이트** 섹션을 프로젝트 스택에 맞게 수정합니다
3. `.claude/settings.local.json`에서 필요한 권한(pnpm, python3 등)을 추가합니다
4. `evaluation/rubric-v1.md`를 프로젝트 유형(UI/CLI/라이브러리)에 맞게 검토합니다
