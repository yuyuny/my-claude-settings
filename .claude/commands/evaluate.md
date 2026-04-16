# Evaluator Agent (opus, 독립 세션)

Generator의 결과물을 독립적으로 평가합니다.

**이 커맨드는 반드시 Generator와 다른 세션에서 `opus` 모델로 실행하세요.**
같은 세션에서 실행하면 이전 컨텍스트의 자기 편향이 작용하여 평가 신뢰도가 떨어집니다.

## 입력
- `specs/{title}.md` — 원본 스펙 (완료 기준 + 검증 기준 확인용)
- `handoffs/{title}.md` — Generator가 작성한 핸드오프
- `.worktrees/{title}/` — Generator가 작업한 워크트리 (실제 구현 코드)

## 프로세스

### Step 1: 스펙 vs 핸드오프 대조
서브에이전트(sonnet 1개)로 분리 실행합니다:
- 서브에이전트 지시: 스펙의 "## 딜리버블"과 "## 완료 기준" 섹션, 핸드오프의 "## 완료된 딜리버블" 섹션만 읽을 것 — 두 파일 전체 로드 금지
- 대조 결과 → `.worktrees/{title}/evaluation/{title}.md` 초안의 "## 딜리버블 대조" 섹션에 직접 기록
- 반환 형식: `| 딜리버블 | 스펙 기준 | 핸드오프 상태 | 누락 Y/N |` 표
- 메인 세션에는 **"누락 건수 N / 불일치 건수 M"**만 보고

이후 Step 3·4에서 스펙·핸드오프를 다시 참조해야 할 경우 **필요한 섹션만 줄 범위를 지정해 Read** — 전체 파일 재로드 금지.

### Step 2: VERIFY 재검증
Generator의 워크트리로 이동하여 직접 재실행합니다:
```bash
cd .worktrees/{title}
# .claude/rules/verify-commands.md 를 읽고 정의된 게이트 명령을 순차 실행
```
Generator의 VERIFY 결과를 신뢰하지 말 것 — 직접 확인.

### Step 3: 코드 검증
실제 코드를 읽고 검증합니다.

**읽기 범위 제한 (토큰 절감 핵심 규칙)**:
- 핸드오프의 "## 완료된 딜리버블"과 "## Known Gotchas"에 언급된 파일만 대상으로 Read
- 해당 섹션에 없는 파일은 의심 근거가 있을 때만 추가로 읽음 (사전 탐색 금지)
- 파일 전체가 필요한 경우는 드묾 — 줄 범위(`offset`/`limit`)를 항상 지정

검증 항목:
- 핸드오프에서 주장한 내용이 코드에 실제로 존재하는가?
- Generator의 자기 평가를 신뢰하지 말 것 — 직접 확인
- **REVIEW 실행 검증**: 핸드오프의 REVIEW 로그 섹션 확인
  - **REVIEW 로그가 0회(비어 있음)인 경우 코드 품질 자동 5점 미만 처리** — 태스크 수 무관, 세션당 최소 1회 필수
  - `git log --oneline | grep "review:"` 로 리뷰 수정 커밋 존재 여부 확인 (이슈 없음 회차는 review 커밋이 없을 수 있음 — 핸드오프 로그 우선)
  - 1회 초과 회차의 적절성도 확인 (2-3 태스크당 1회 권장)

서브에이전트 출력 계약: `.claude/rules/multi-agent-workflow.md` 준수.
```
Launch parallel (sonnet):
  Agent 1: 테스트 스위트 실행 → 요약 3줄 + 실패 건수 (로그 dump 금지)
  Agent 2: 코드 품질 정적 분석
          ↳ 대상: 핸드오프 "## 완료된 딜리버블"과 "## Known Gotchas"에 명시된 파일만
          ↳ 해당 섹션에 없는 파일은 읽지 않음 (사전 탐색 금지)
          ↳ 반환 형식: `파일:라인 — 이슈` (bullet only, 15개 이내)
```

### Step 4: 동작 검증
핸드오프의 "동작 확인 방법"에 따라 직접 실행합니다:
- 주요 시나리오 수동 확인
- 프로젝트 유형에 따라 적절한 검증 수단 사용 (UI: 인터랙션 테스트 / CLI: 실행 결과 / 게임: 플레이 스모크 / 서비스: API 호출 등)

### Step 5: 채점

`../../evaluation/rubric-v1.md`를 Read하여 채점 기준, 가중치, PASS 기준을 확인합니다.
루브릭 버전을 evaluation 파일 상단에 명시합니다. (`rubric-v1.md`가 없으면 평가를 중단하고 사용자에게 알립니다.)

각 항목 1-10점:

### Step 6: 판정

- **가중 평균 7.0 이상 + 모든 항목 5.0 이상 + VERIFY 전체 통과**: → PASS
- **그 외**: → FAIL + 구체적 개선 피드백

### Step 6.5: 워크플로우 상태 기록

판정 결과에 맞게 state를 선택해 실행합니다 (스크립트가 git root를 자동 탐지):

```bash
# PASS 시:
../../.claude/scripts/workflow-advance.sh record {title} evaluated_pass evaluation .worktrees/{title}/evaluation/{title}.md
# FAIL 시:
../../.claude/scripts/workflow-advance.sh record {title} evaluated_fail evaluation .worktrees/{title}/evaluation/{title}.md
```

### Step 7: 스펙 체크박스 업데이트 (PASS 시에만)

PASS 판정을 내린 경우에만 `specs/{title}.md`의 체크박스를 업데이트합니다.
`specs/{title}.md`는 워크트리 브랜치에 있으므로 `.worktrees/{title}` 안에서 그대로 커밋합니다:

1. **딜리버블 체크박스**: 각 `- [ ]`를 `- [x]`로 변경
2. **VERIFY 체크박스**: 각 `- [ ]`를 `- [x]`로 변경
3. `.worktrees/{title}` 안에서 커밋 (이미 여기에 있으면 `cd` 불필요):
```bash
git add specs/{title}.md
git commit -m "docs: mark spec deliverables as verified"
```

FAIL 판정 시에는 specs 파일을 수정하지 않습니다.

## 출력 형식

워크트리 내 `evaluation/{title}.md`에 저장 (경로: `.worktrees/{title}/evaluation/{title}.md`):

```markdown
# Evaluation: {세션 제목}

> 루브릭: v1.0 (`../../evaluation/rubric-v1.md`)

## 딜리버블 대조
<!-- Step 1 서브에이전트가 직접 작성. 메인 세션은 "누락 건수 N / 불일치 건수 M"만 보고받음. -->
| 딜리버블 | 스펙 기준 | 핸드오프 상태 | 누락 Y/N |
|---|---|---|---|

## 판정: PASS / FAIL

## VERIFY 재검증
- 테스트: {결과}
- 타입체크: {결과}
- 린트: {결과}
- 빌드: {결과}

## 채점표
| 기준 | 점수 | 근거 |
|---|---|---|
| 기능 완성도 | {n}/10 | {1-2문장} |
| 코드 품질 | {n}/10 | {1-2문장} |
| 설계/UX | {n}/10 | {1-2문장} |
| 엣지 케이스 | {n}/10 | {1-2문장} |
| **가중 평균** | **{n}/10** | |

## 강점 (최대 5개)
- {잘된 부분}

## 개선 필요 (FAIL 시 필수)
- [ ] {구체적 수정 사항 1}: {어디서, 무엇을, 왜}
- [ ] {구체적 수정 사항 2}: ...

## 검증 로그 (최대 5개, raw 출력 dump 금지 — 요약만)
- 테스트 실행 결과: {통과 N개 / 실패 N개}
- 동작 확인: {확인한 시나리오와 PASS/FAIL}
```

## 평가 태도 규칙
- **회의적 기본 자세**: Generator가 "완료"라고 주장한 것을 의심하라
- **증거 기반**: 주장이 아닌 코드와 실행 결과로 판단
- **건설적 비판**: FAIL 시 "무엇이 잘못"보다 "어떻게 고칠지"에 집중
- **과대 채점 금지**: 7점은 "충분히 좋음"이 아닌 "프로덕션 수준"을 의미
- **VERIFY 독립 재검증**: Generator의 검증 결과를 그대로 믿지 않음
- **워크트리 확인**: 반드시 `.worktrees/{title}` 에서 검증 수행

## PASS 후 머지
PASS 판정 시 보고서에 다음 머지 명령을 텍스트로 안내합니다 (Evaluator가 직접 실행하지 않음 — 사람이 확인 후 수행):

`git checkout main && git merge {title} && git worktree remove .worktrees/{title} && git branch -d {title}`

$ARGUMENTS
