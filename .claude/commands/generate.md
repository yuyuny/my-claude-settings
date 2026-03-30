# Generator Agent (haiku + sonnet)

스펙을 읽고 기존 워크플로우(SCOPE→PLAN→IMPLEMENT→REVIEW→VERIFY→REFLECT)에 따라 구현합니다.
**모든 작업은 `.worktrees/{title}` 에서 진행합니다.**

## 입력
- `specs/{title}.md` — 구현할 스프린트 스펙
- `evaluation/{title}.md` — (재작업 시) 이전 평가 보고서

## 프로세스

### Step 0: Worktree 생성
작업 시작 전 격리된 워크트리를 생성합니다:
```bash
git worktree add .worktrees/{title} -b {title}
cd .worktrees/{title}
```
재작업인 경우 기존 워크트리가 있으면 해당 브랜치로 이동:
```bash
cd .worktrees/{title}
```

### Step 1: SCOPE — 병렬 탐색 (haiku × 2~3)
구현 전 영향 범위를 병렬 탐색 에이전트로 파악합니다:
```
Launch parallel (haiku):
  Agent 1: 영향 받는 파일/모듈 탐색
  Agent 2: 기존 테스트 커버리지 확인
  Agent 3: 관련 상태 흐름 / 의존성 추적
```
재작업인 경우 `evaluation/{title}.md`의 FAIL 피드백을 먼저 확인합니다.

### Step 2: PLAN — 마이크로태스크 분해
`specs/{title}.md`의 딜리버블을 **2~5분 단위 태스크**로 분해합니다.
각 태스크는 독립적으로 완료·커밋 가능해야 합니다.

```
예시: "사용자 인증 구현"
  ├── 태스크 1: User 모델 + 마이그레이션
  ├── 태스크 2: 회원가입 API 엔드포인트
  ├── 태스크 3: 로그인 API + JWT 발급
  ├── 태스크 4: 인증 미들웨어
  └── 태스크 5: 로그인 UI 컴포넌트
```

불명확한 부분은 구현 전에 가정(assumptions)으로 기록합니다.

### Step 3: IMPLEMENT — TDD 루프 (sonnet)
각 마이크로태스크마다:

1. **RED**: 실패하는 테스트 먼저 작성
2. **GREEN**: 테스트를 통과하는 최소 구현
3. **REFACTOR**: 코드 품질 개선 (테스트는 계속 통과)
4. **커밋**: 태스크 단위로 작고 자주 커밋

테스트 없이 구현하지 않습니다. 테스트가 불가능한 부분(UI 레이아웃 등)은 명시적으로 기록합니다.

### Step 4: REVIEW — diff 기반 코드 리뷰 (sonnet)
매 2~3개 태스크 완료 후 리뷰를 수행합니다:
- `/simplify` 스킬로 diff 기반 리뷰 실행
- **스펙 준수**: 딜리버블과 일치하는가?
- **코드 품질**: 중복, 네이밍, 구조
- Critical 이슈 발견 시 다음 태스크 진행 차단 → 즉시 수정
- 예외 컨텍스트가 있으면 리뷰 시 제공

### Step 5: VERIFY — 빌드 검증
**핸드오프 전 반드시 통과해야 하는 게이트:**
```bash
pnpm test:run    # 또는 프로젝트의 테스트 명령
pnpm typecheck   # 타입 체크
pnpm lint        # 린트
pnpm build       # 빌드 (해당 시)
```
하나라도 실패하면 핸드오프 금지 — 수정 후 재실행합니다.
빌드 에러 해결이 필요하면 에러 메시지 기반으로 디버깅합니다.

### Step 6: REFLECT — 돌아보기
변경 사항을 돌아보고 교훈을 기록합니다:
- 예상과 다르게 진행된 부분
- 발견한 기술 부채
- 다음 스프린트에 참고할 사항

이 내용은 핸드오프 파일에 포함합니다.

### Step 7: HANDOFF — 핸드오프 작성
모든 검증 통과 후 워크트리 내에 `handoffs/{title}.md`를 작성합니다.
(경로: `.worktrees/{title}/handoffs/{title}.md`)
이 파일이 Evaluator에게 전달되는 **유일한 컨텍스트**입니다.

## 핸드오프 작성 규칙

`handoffs/{title}.md`에 반드시 포함:

```markdown
# Handoff: {세션 제목}

## 완료된 딜리버블
- [x] 딜리버블 1: {완료 상태 요약}
- [x] 딜리버블 2: ...
- [ ] 딜리버블 3: {미완료 시 사유}

## 주요 설계 결정
- {결정 내용}: {이유}

## 알려진 제한사항
- {트레이드오프 또는 기술 부채}

## VERIFY 결과
- 테스트: {통과 n개 / 실패 0개}
- 타입체크: PASS
- 린트: PASS
- 빌드: PASS
- 실행 방법: `{테스트 명령어}`

## 동작 확인 방법
- `{실행 명령어}`
- {확인할 주요 시나리오}

## REFLECT 메모
- {교훈, 기술 부채, 다음 스프린트 참고사항}
```

## 규칙
- 스펙에 없는 기능을 임의로 추가하지 않음 (scope creep 방지)
- `specs/{title}.md`의 체크박스를 수정하지 않음 — 체크박스는 Evaluator가 PASS 판정 후 직접 업데이트함
- VERIFY 통과 전 절대 핸드오프하지 않음
- 컨텍스트가 길어지면 현재까지 진행 상황을 handoffs/{title}.md에 기록하고 새 세션 시작 가능
- 모든 작업은 반드시 `.worktrees/{title}` 에서 진행 (메인 브랜치 직접 수정 금지)
- 워크트리 내 커밋은 `{title}` 브랜치에 쌓임 → Evaluator PASS 후 메인에 머지

$ARGUMENTS
