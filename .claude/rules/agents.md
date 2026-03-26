# Agent Orchestration

## Model Strategy

작업 유형에 따라 적절한 모델을 배정한다:

| 작업 유형     | 모델     | 사용 시점                                      |
| ------------- | -------- | ---------------------------------------------- |
| **탐색/검색** | `haiku`  | 파일 검색, 코드 패턴 찾기, 간단한 질의응답     |
| **실행/구현** | `sonnet` | 코드 작성, 리팩토링, 테스트 작성, 코드 리뷰    |
| **계획/설계** | `opus`   | 아키텍처 결정, 복잡한 문제 분석, 구현 계획     |

### 적용

```
# 탐색 — haiku (빠르고 저렴)
Agent(subagent_type="Explore", model="haiku", ...)

# 실행 — sonnet (균형)
Agent(subagent_type="general-purpose", model="sonnet", ...)

# 계획 — opus (깊은 사고)
Agent(subagent_type="Plan", model="opus", ...)
```

### 판단 기준

- **haiku**: 결과가 맞는지만 빠르게 확인하면 되는 작업
- **sonnet**: 코드를 실제로 생성/수정하는 작업
- **opus**: 여러 파일에 걸친 영향 분석, 트레이드오프 판단이 필요한 작업

## Core Agent Team

### 상시 사용

1. **코드 리뷰** — `/simplify` 스킬 사용. 구현 후 매번 실행
2. **탐색 에이전트** — `Explore` 서브에이전트. 2~3개 병렬로 교차 검증
3. **TDD 가이드** — `test-driven-development` 스킬

### 필요시 호출

4. **빌드 에러 해결** — `pnpm build`/`pnpm typecheck` 실패 시에만
5. **리팩터/정리** — 명시적 정리 세션에서만

## Parallel Task Execution

독립적 작업은 항상 병렬 실행:

```markdown
# GOOD: 병렬 실행
Launch 3 agents in parallel:
1. Agent 1: 영향 범위 분석
2. Agent 2: 테스트 커버리지 확인
3. Agent 3: 상태 흐름 추적

# BAD: 불필요한 순차 실행
First agent 1, then agent 2, then agent 3
```

## Workflow

```
SCOPE → PLAN → IMPLEMENT(TDD) → REVIEW → VERIFY → REFLECT → COMMIT
```

1. **SCOPE**: 병렬 탐색 에이전트로 영향 범위 파악
2. **PLAN**: `tasks/todo.md`에 계획 작성
3. **IMPLEMENT**: TDD 사이클 (RED → GREEN → REFACTOR)
4. **REVIEW**: `/simplify`로 diff 기반 리뷰, 예외 컨텍스트 제공
5. **VERIFY**: `pnpm test:run` + `pnpm typecheck` + `pnpm lint`
6. **REFLECT**: 변경 돌아보기, 교훈 기록
7. **COMMIT**: 검증 완료 후 커밋
