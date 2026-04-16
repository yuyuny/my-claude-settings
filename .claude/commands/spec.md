# Spec Writer Agent (sonnet)

브레인스토밍 산출물(`brainstorms/{title}.md`)을 읽고 정형 스펙 문서로 변환합니다.
이 커맨드는 `sonnet` 모델로 실행합니다 — 정해진 템플릿 채우기와 딜리버블 정제가 목적입니다.

요구사항이 모호하다면 `/brainstorm` (opus) 을 먼저 실행하세요.
요구사항이 이미 메인 세션에서 명확히 정의된 경우 `/brainstorm` 없이 바로 실행해도 됩니다.

## 프로세스

### Step 1: 입력 결정

- `brainstorms/{title}.md` 가 있으면 → 1차 입력으로 사용 (SCOPE 재실행 금지)
- 없으면 → 메인 세션 컨텍스트를 1차 입력으로 사용. 짧은 확인 1~2개만 던지고 바로 작성

### Step 1.5: 워크트리 생성

`/spec`부터 모든 산출물(스펙, 핸드오프, 평가, 회고)은 워크트리 브랜치에서 관리합니다.

```bash
git worktree add .worktrees/{title} -b {title}
```

이미 워크트리가 있으면(재작업 등) 생략하고 `cd .worktrees/{title}`로 이동만 합니다.
**이후 모든 Step은 `.worktrees/{title}` 안에서 실행합니다.**

### Step 2: SCOPE

- **brainstorms/{title}.md 있음**: "영향 받는 경로" 섹션을 스펙으로 **그대로 복사**. 탐색 에이전트 재실행 금지.
- **없음**: 병렬 탐색 에이전트(sonnet × 2~3)로 영향 범위 파악.

  **출력 계약**: 서브에이전트 출력 계약(`.claude/rules/multi-agent-workflow.md`) 준수.
  각 에이전트는 `파일경로 — 1줄 근거` 형식 bullet 리스트로만 반환. raw 코드 덤프 금지.

  ```
  Launch parallel (sonnet):
    1. 관련 파일/모듈 구조 탐색 → bullet: `경로/파일 — 이유`
    2. 기존 패턴/컨벤션 확인   → bullet: `경로/파일 — 어떤 패턴`
    3. 의존성/영향 범위 분석   → bullet: `경로/파일 — 영향 방향`
  ```

### Step 3: 세션 제목 확정

- brainstorms/{title}.md 가 있으면 그 제목을 그대로 사용
- 없으면 kebab-case 제목을 결정 (`auth-login`, `dashboard-charts` 등)

### Step 4: 스펙 작성

`specs/{title}.md` 파일을 아래 출력 형식으로 생성합니다.

**딜리버블 중심으로 작성** — 구현 세부사항(어떤 함수, 어떤 패턴)은 Generator의 몫입니다.
Spec Writer가 구현 방법을 지정하면 오류가 전파(cascade)될 위험이 있습니다.

### Step 5: 스프린트 계약

각 스프린트마다 "완료 기준(Definition of Done)"을 명확히 정의합니다.
이 기준은 나중에 Evaluator가 동일하게 사용합니다.

**검증 기준도 반드시 포함**: 빌드, 테스트, 타입체크, 린트 통과 여부.

### Step 6: 스펙 커밋

`.worktrees/{title}` 안에서 실행합니다:

```bash
git add specs/{title}.md
git commit -m "docs: add spec for {title}"
```

**주의**: `specs/{title}.md`만 스테이징합니다. 다른 변경 사항은 커밋하지 않습니다.

### Step 7: 워크플로우 상태 기록

워크트리 안에서 프로젝트 루트의 상태 파일을 업데이트합니다:

```bash
mkdir -p ../../.claude-workflow/sessions
python3 -c "
import json, os, datetime
f = '../../.claude-workflow/sessions/{title}.json'
d = json.load(open(f)) if os.path.exists(f) else {'title': '{title}', 'history': []}
prev = d.get('state')
d.update({
  'title': '{title}',
  'state': 'spec_ready',
  'updated_at': datetime.datetime.utcnow().isoformat() + 'Z',
  'next_action': 'await_user_approval_then_generate',
  'artifacts': {**d.get('artifacts', {}), 'spec': 'specs/{title}.md'},
})
if prev and prev != 'spec_ready':
    d['history'] = d.get('history', []) + [{'state': prev, 'at': d['updated_at']}]
json.dump(d, open(f, 'w'), indent=2)
"
export CLAUDE_WORKFLOW_TITLE="{title}"
```

## 출력 형식

```markdown
# Spec: {세션 제목}

## 목표

{1-2문장 요약}

## 딜리버블

- [ ] 딜리버블 1: {사용자 관점에서 설명}
- [ ] 딜리버블 2: ...

## 완료 기준 (Evaluator와 공유)

1. {구체적이고 검증 가능한 조건}
2. {예: "플레이어 입력 후 1프레임 내 반응"}
3. {예: "모든 엔트리 포인트에 에러 핸들링 존재"}

## 검증 기준 (VERIFY)

> `.claude/rules/verify-commands.md`에 정의된 게이트를 기준으로 합니다.

- [ ] {게이트 1 — 예: 테스트 전체 통과}
- [ ] {게이트 2 — 예: 빌드 통과}
- [ ] {해당하는 게이트만 포함}

## 영향 받는 경로

- 주 경로: {기능의 표준 실행 경로. 예: 주 엔트리 함수 → 핵심 처리기 → 저장소}
- 대체 경로: {주 경로 외 동일 결과를 내는 우회·특수 분기. 예: 특정 조건에서 표준 파이프라인을 건너뛰는 단축 경로}
- 연동 시스템: {함께 업데이트해야 할 사이드 시스템. 예: 로깅/분석, 국제화(있다면), 문서, 외부 카탈로그}

## 기술 제약

- {스택, 호환성, 성능 요구사항 등}

## 비기능 요구사항

- {접근성, 보안, 성능 임계값 등}

## 의존성

- 선행 세션: {없음 또는 이전 세션 제목}
```

## 규칙

- 스프린트당 딜리버블은 3~7개
- 완료 기준은 주관적 표현 금지 ("좋은 UX" X → "버튼 클릭 후 1초 내 피드백" O)
- 이전 세션의 evaluation/{title}.md가 있으면 반드시 반영
- 야심찬 범위 설정: AI 기능 통합 기회가 있으면 적극 제안
- **영향 받는 경로 필수**: 주요 딜리버블마다 대체 실행 경로를 나열 (누락 시 구현 단계 FAIL 위험)
- 처음 등장하는 도메인 용어는 `docs/GLOSSARY.md`가 있으면 추가 (없으면 생략)

$ARGUMENTS
