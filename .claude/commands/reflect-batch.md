# Reflect-Batch Agent (sonnet)

`reflections/` 누적 파일에서 반복 패턴을 집계하고 워크플로우 규칙을 개선합니다.

## 언제 실행하는가

- 새 reflection 파일이 **5개 이상** 누적됐을 때 (마지막 배치 집계 이후 기준)
- 프로젝트 마일스톤(스테이지 완성, 릴리즈 등) 후
- 사람이 `/reflect-batch`를 직접 호출할 때

## 입력

- `reflections/index.md` — 마지막 배치 집계 날짜 확인
- `reflections/*.md` — 마지막 집계 이후 새 파일들
- `.claude/rules/*.md` — 현재 워크플로우 규칙
- `docs/GLOSSARY.md` — 현재 용어 사전

## 프로세스

### Step 1: 미처리 파일 파악

`reflections/index.md`의 "마지막 배치 집계" 날짜를 확인합니다.
해당 날짜 이후의 reflection 파일 목록을 수집합니다.

```bash
ls reflections/ | grep -v index.md | sort
```

### Step 2: 패턴 추출 (병렬)

미처리 파일들을 읽고 각 파일의 다음 섹션을 추출합니다:

```
Launch parallel (sonnet × 2):
  Agent 1: "어려웠던 점" 섹션 집계
  Agent 2: "프로세스 관찰" + "사람에게" 섹션 집계
```

각 에이전트는 발견한 내용을 구조화된 목록으로 반환합니다.

### Step 3: 반복 패턴 판별

집계 결과에서 **3회 이상** 반복된 주제를 찾습니다.

예시 반복 패턴:
- "대체 코드 경로 누락" → `generate.md` SCOPE 강화 (이미 반영됨)
- "핸드오프에 API 시그니처 미기재" → 핸드오프 템플릿에 항목 추가
- "린트 규칙 X가 자주 위반됨" → `rules/coding-style.md`에 명시

### Step 4: 규칙 업데이트 제안 및 적용

반복 패턴마다:

1. **해당 rules/ 파일 식별**: 어느 규칙 파일을 수정해야 하는가?
2. **변경 내용 작성**: 구체적으로 어떤 줄을 추가/수정하는가?
3. **적용**: 규칙 파일 직접 수정
4. **신규 규칙 필요 시**: `.claude/rules/{topic}.md` 신규 생성

반복 3회 미만 패턴은 `reflections/index.md`의 "반복 패턴 메모" 섹션에 기록만 합니다.

### Step 5: 인덱스 업데이트

`reflections/index.md`의 "마지막 배치 집계" 날짜를 오늘 날짜로 업데이트합니다.
"반복 패턴 메모" 섹션에 이번 집계 요약을 추가합니다:

```markdown
### YYYY-MM-DD 배치 집계

처리 파일: N개 (YYYY-MM-DD ~ YYYY-MM-DD)

**반복 패턴 (3회 이상 → 규칙 적용)**
- {패턴}: {적용한 rules/ 파일}

**약한 신호 (3회 미만 → 모니터링)**
- {패턴}: {N회}
```

### Step 6: 커밋

```bash
git add reflections/index.md .claude/rules/ docs/GLOSSARY.md
git commit -m "docs: reflect-batch — {주요 패턴 요약}"
```

## 규칙

- 추측 기반 규칙 추가 금지 — 반드시 reflection 파일에서 증거 3건 이상 확보 후 적용
- 기존 rules/ 파일 전면 재작성 금지 — 특정 항목 추가/수정만
- 사람에게 리뷰 요청 불필요한 경우: 명백한 누락 항목 추가 (예: 자주 빠지는 SCOPE 체크리스트 항목)
- 사람에게 리뷰 요청 필요한 경우: 기존 규칙과 충돌하거나 워크플로우 구조를 바꾸는 변경

$ARGUMENTS
