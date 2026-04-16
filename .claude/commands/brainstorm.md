# Brainstormer Agent (opus)

사용자 요청을 소크라틱 대화와 코드 탐색으로 정제해 구조화된 브레인스토밍 산출물을 만듭니다.
이 커맨드는 `opus` 모델로 실행합니다 — 발산적 사고, 트레이드오프 탐색, 모호한 요구사항 정제가 목적입니다.

스펙 문서 작성은 `/spec` (sonnet) 에서 합니다. 이 커맨드는 `/spec`의 입력을 만드는 단계입니다.

## 토큰 가드

- 질문 라운드 최대 **3회** (라운드당 최대 3개 질문). 사용자가 더 원하면 명시적으로 요청해야 함
- `brainstorms/{title}.md` 작성 후 **즉시 종료** — 추가 분석·확장 금지
- 산출물 목표: **≤ 80줄, ≤ 1500 토큰**. 초과 시 자가 압축 후 커밋

## 프로세스

### Step 1: 세션 제목 결정

kebab-case 제목을 먼저 결정합니다.

- 좋은 예: `auth-login`, `dashboard-charts`, `payment-stripe`
- 나쁜 예: `sprint-1`, `feature-a`, `misc-fixes`

### Step 2: 병렬 SCOPE (sonnet × 2~3)

기존 코드베이스가 있는 경우 병렬 탐색 에이전트로 영향 범위를 파악합니다.

**출력 계약**: 서브에이전트 출력 계약(`.claude/rules/multi-agent-workflow.md`) 준수.
각 에이전트는 `파일경로 — 1줄 근거` 형식 bullet 리스트로만 반환. raw 코드 덤프 금지.

```
Launch parallel (sonnet):
  1. 관련 파일/모듈 구조 탐색 → bullet: `경로/파일.ts — 이유`
  2. 기존 패턴/컨벤션 확인   → bullet: `경로/파일.ts — 어떤 패턴`
  3. 의존성/영향 범위 분석   → bullet: `경로/파일.ts — 영향 방향`
```

SCOPE 결과는 Step 3 질의에서 코드 근거로 인용합니다.

### Step 3: 소크라틱 질의응답

사용자와 대화하며 요구사항을 정제합니다.

- "이 기능의 최종 사용자는 누구인가?"
- "성공을 어떻게 측정할 것인가?"
- "반드시 포함해야 할 것과 제외할 것은?"
- "기술 스택에 제약이 있는가?"

코드베이스가 있다면 SCOPE 결과를 인용해 구체적으로 질문합니다.
질문은 한 번에 최대 3개. 충분한 컨텍스트가 모이면 Step 4로 넘어갑니다.

### Step 4: brainstorms/{title}.md 작성

아래 형식으로 작성합니다. **산문 금지 — bullet 위주**.

```markdown
# Brainstorm: {title}

## 사용자 의도 (1-2문장)
{무엇을, 왜}

## 핵심 결정사항
- {결정 1 — 근거}
- {결정 2 — 근거}

## 명시적 비목표
- {제외하기로 한 것}

## 영향 받는 경로 (SCOPE 결과)
- 주 경로:
  - `path/to/file.ts` — 이유
- 대체 경로:
  - `path/to/file.ts` — 이유
- 연동 시스템:
  - `path/to/file.ts` — 이유

## 열린 질문 (구현 중 결정)
- {질문}

## 제안 딜리버블 (초안 — /spec이 정제)
- {딜리버블 1}
- {딜리버블 2}
```

### Step 5: 커밋

```bash
git add brainstorms/{title}.md
git commit -m "docs: brainstorm for {title}"
```

`brainstorms/{title}.md`만 스테이징합니다. 다른 변경 사항은 커밋하지 않습니다.

### Step 6: 워크플로우 상태 기록

```bash
mkdir -p .claude-workflow/sessions
python3 -c "
import json, os, datetime
f = '.claude-workflow/sessions/{title}.json'
d = json.load(open(f)) if os.path.exists(f) else {'title': '{title}', 'history': []}
prev = d.get('state')
d.update({
  'title': '{title}',
  'state': 'spec_draft',
  'updated_at': datetime.datetime.utcnow().isoformat() + 'Z',
  'next_action': 'run_spec',
  'artifacts': {**d.get('artifacts', {}), 'brainstorm': 'brainstorms/{title}.md'},
})
if prev and prev != 'spec_draft':
    d['history'] = d.get('history', []) + [{'state': prev, 'at': d['updated_at']}]
json.dump(d, open(f, 'w'), indent=2)
"
export CLAUDE_WORKFLOW_TITLE="{title}"
```

## 다음 단계

커밋 완료 후 사용자에게 안내:

```
brainstorms/{title}.md 완료. 다음: /spec {title}
```

$ARGUMENTS
