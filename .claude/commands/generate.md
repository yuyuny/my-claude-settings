# Generator Agent (sonnet + opus)

스펙을 읽고 기존 워크플로우(SCOPE→PLAN→IMPLEMENT→REVIEW→VERIFY)에 따라 구현합니다.
**모든 작업은 `.worktrees/{title}` 에서 진행합니다.**

## 입력
- `specs/{title}.md` — 구현할 스프린트 스펙
- `evaluation/{title}.md` — (재작업 시) 이전 평가 보고서

## 프로세스

### Step 0: 워크스페이스 준비

#### Step 0a: 스펙 확인

스펙 파일이 커밋되어 있는지 확인합니다. (`/spec`에서 커밋 완료된 상태여야 합니다.)

```bash
git ls-files --error-unmatch specs/{title}.md 2>/dev/null || { echo "ERROR: specs/{title}.md가 커밋되지 않았습니다. /spec을 먼저 실행하세요."; exit 1; }
```

#### Step 0b: 워크트리 생성
격리된 워크트리를 생성합니다:
```bash
git worktree add .worktrees/{title} -b {title}
cd .worktrees/{title}
```
재작업인 경우 기존 워크트리가 있으면 해당 브랜치로 이동:
```bash
cd .worktrees/{title}
```

### Step 1: SCOPE — 병렬 탐색 (sonnet × 2~3)
구현 전 영향 범위를 병렬 탐색 에이전트로 파악합니다.

**출력 계약**: 서브에이전트 출력 계약(`.claude/rules/multi-agent-workflow.md`) 준수. 각 에이전트는 `파일경로 — 1줄 근거` 형식의 bullet 리스트로만 반환. raw 코드 덤프 금지.

```
Launch parallel (sonnet):
  Agent 1: 영향 받는 파일/모듈 탐색
           → bullet: `경로/파일.ts — 이유`
  Agent 2: 기존 테스트 커버리지 확인 (기존 테스트가 없으면 스킵)
           → bullet: `테스트파일.ts — 커버하는 범위`
  Agent 3: 관련 상태 흐름 / 의존성 추적
           — spec의 "영향 받는 경로" 섹션 기준, 대체 경로 포함
           → 대체 경로는 별도 섹션 "대체 경로"로 묶어 반환
```
재작업인 경우 `evaluation/{title}.md`의 FAIL 피드백을 먼저 확인합니다.

### Step 2: PLAN — 마이크로태스크 분해
`specs/{title}.md`의 딜리버블을 **2~5분 단위 태스크**로 분해합니다.
각 태스크는 독립적으로 완료·커밋 가능해야 합니다.

분해 결과는 **`handoffs/{title}.md`의 "## 태스크 분해" 섹션에 직접 기록**합니다 (파일이 없으면 이 시점에 생성).
메인 세션에는 "태스크 수 N개 / 불명확 지점 M개"만 유지합니다.

불명확한 부분(가정)은 핸드오프의 "Known Gotchas" 또는 "## 가정" 섹션에 기록합니다.
SCOPE에서 대체 경로가 미확인된 항목은 구현 전 코드에서 반드시 직접 확인합니다.

### Step 3: IMPLEMENT — TDD 루프 (sonnet)
각 마이크로태스크마다:

1. **RED**: 실패하는 테스트 먼저 작성
2. **GREEN**: 테스트를 통과하는 최소 구현
3. **REFACTOR**: 코드 품질 개선 (테스트는 계속 통과)
4. **커밋**: 태스크 단위로 작고 자주 커밋

테스트 없이 구현하지 않습니다. 테스트가 불가능한 부분(UI 레이아웃 등)은 명시적으로 기록합니다.

### Step 4: REVIEW — diff 기반 코드 리뷰 (opus)
매 2~3개 태스크 완료 후 리뷰를 수행합니다:

1. `/simplify` 스킬을 `opus` 모델로 실행하여 diff 기반 리뷰 수행
2. `/simplify` 서브에이전트에 지시: **결과를 `handoffs/{title}.md`의 REVIEW 로그 섹션에 직접 1줄 append** 후 메인에는 "critical Y/N + 수정 필요 파일 경로"만 보고
3. 메인 세션은 critical=Y일 때만 상세 이슈를 요청. REVIEW 로그 표는 서브에이전트가 직접 작성.
4. Critical 이슈 발견 시 다음 태스크 진행 차단 → 즉시 수정
5. 수정 커밋 메시지에 `review:` 접두사 사용 (예: `review: extract shared helper`)
6. 예외 컨텍스트가 있으면 리뷰 시 제공

**REVIEW 미실행 시 핸드오프에 사유를 명시해야 합니다.**

### Step 5: VERIFY — 빌드 검증
**핸드오프 전 반드시 통과해야 하는 게이트.**

서브에이전트(sonnet 1개)로 분리 실행합니다:
- 서브에이전트가 4개 명령(`pnpm test:run`, `pnpm typecheck`, `pnpm lint`, `pnpm build`)을 순차 실행
- 결과를 `handoffs/{title}.md`의 "## VERIFY 결과" 섹션에 직접 채움
- 메인 세션에는 **"전체 PASS Y/N + 실패 명령어 목록"**만 보고

실패 시: 메인이 서브에이전트에게 "실패 명령어의 에러 요약 10줄 이내"를 후속 요청합니다. 에러 전체 dump 금지.
하나라도 실패하면 핸드오프 금지 — 수정 후 재실행합니다.

### Step 6: HANDOFF — 핸드오프 작성
모든 검증 통과 후 워크트리 내에 `handoffs/{title}.md`를 작성합니다.
(경로: `.worktrees/{title}/handoffs/{title}.md`)
이 파일이 Evaluator에게 전달되는 **유일한 컨텍스트**입니다.

## 핸드오프 작성 규칙

`handoffs/{title}.md`에 반드시 포함:

```markdown
# Handoff: {세션 제목}

## 태스크 분해
<!-- Step 2 PLAN에서 선행 작성됨. 여기에 직접 기록. -->
- 태스크 1: {설명}
- 태스크 2: {설명}
- ...

## 완료된 딜리버블
- [x] 딜리버블 1: {완료 상태 요약}
- [x] 딜리버블 2: ...
- [ ] 딜리버블 3: {미완료 시 사유}

## 주요 설계 결정 (최대 5개)
- {결정 내용}: {이유}

## 알려진 제한사항 (최대 5개)
- {트레이드오프 또는 기술 부채}

## Known Gotchas
- {다음 에이전트가 놓치기 쉬운 함정 — 비명시적 사이드이펙트, 중복 경로, 순서 의존성}
- 예: "기능 X가 표준 파이프라인을 우회해 별도 저장 경로를 호출함 — 해당 경로도 함께 수정 필요"
- 없으면: "없음"

## REVIEW 로그
- 1회차 (태스크 1-3 후): {이슈 80자 이내 또는 "없음"} / {수정 커밋 해시 + 1줄 또는 "-"}
- 2회차 (태스크 4-6 후): ...
<!-- 4회차 이상: 이슈 없음 회차는 생략. /simplify 서브에이전트가 직접 append. -->

## VERIFY 결과
- 테스트: {통과 n개 / 실패 0개}
- 타입체크: PASS
- 린트: PASS
- 빌드: PASS
- 실행 방법: `{테스트 명령어}`

## 동작 확인 방법
- `{실행 명령어}`
- {확인할 주요 시나리오}

## REFLECT 메모 (최대 3개)
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
