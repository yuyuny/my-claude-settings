# Reflector Agent (sonnet)

전체 워크플로우 사이클을 회고하고 교훈을 기록합니다.
이 커맨드는 `/evaluate` 완료 후 같은 세션 또는 새 세션에서 실행합니다.

## 입력

모든 산출물은 워크트리 안에 있습니다. `.worktrees/{title}` 기준 경로:
- `specs/{title}.md` — 원본 스펙 (참고)
- `handoffs/{title}.md` — Generator 핸드오프 (참고)
- `evaluation/{title}.md` — Evaluator 보고서 (참고)
- 세션 중 대화 컨텍스트 (있는 경우)

> **참고 자료 원칙**: 위 문서들은 필수 분석 대상이 아닌 참고 자료입니다.
> 문서를 요약하지 마세요. 회고에 관련될 때만 구체적으로 언급하세요.
> (이 원칙은 `.claude/rules/multi-agent-workflow.md`의 전역 규칙 — 모든 커맨드에 적용됨.)

## 프로세스

### Step 1: 사이클 조감
이번 사이클(`/spec` → `/generate` → `/evaluate`)을 전체적으로 돌아봅니다:
- 무엇을 만들었는가? (1-2문장)
- 계획과 결과 사이에 의미 있는 차이가 있었는가?
- Evaluator 판정(PASS/FAIL)과 점수를 확인

### Step 2: 1인칭 회고 작성
Claude의 시점에서 솔직하게 작성합니다 — 상태 보고서가 아닌 일기입니다.
- 구체적일 것: 실제 파일, 명령어, 대화 속 순간을 언급
- 감정 표현 권장: "혼란스러웠다", "만족스러웠다", "의외였다" 등
- 어떤 세션에나 해당되는 일반론은 제외

### Step 3: 파일 작성
`reflections/YYYY-MM-DD-HHmm-{title}.md` 파일을 생성합니다.
- `{title}`은 해당 사이클의 세션 제목(kebab-case)을 사용

### Step 3.5: 인덱스 업데이트

1. `docs/GLOSSARY.md`에 기존 항목이 있는 경우에만 새 도메인 용어 추가 (빈 파일이면 생략)
2. `reflections/index.md`가 있으면 테이블에 새 항목 한 줄 추가 (없으면 생략):

   ```
   | YYYY-MM-DD | {title} | PASS / FAIL | {핵심 배움 한 문장} |
   ```

### Step 4: 커밋

`.worktrees/{title}` 안에서 커밋합니다:
```bash
git add reflections/YYYY-MM-DD-HHmm-{title}.md
# reflections/index.md 업데이트 시 함께 추가 (파일이 있는 경우)
# git add reflections/index.md
# docs/GLOSSARY.md 업데이트 시 함께 추가 (파일이 있는 경우)
# git add docs/GLOSSARY.md
git commit -m "docs: add reflection for {title} session"
```

### Step 5: 워크플로우 상태 기록

```bash
../../.claude/scripts/workflow-advance.sh record {title} done reflection reflections/$(date +%Y-%m-%d-%H%M)-{title}.md
```

## 출력 형식

`reflections/YYYY-MM-DD-HHmm-{title}.md`에 저장:

```markdown
# Reflection: {세션 제목}

## 사이클 요약
{무엇을 만들었는지 1-2문장. 스캔용 — 회고 목록에서 식별 가능하게. Evaluator 판정 포함.}

## 무엇이 일어났나
{잘된 것과 어려웠던 것을 함께: 효과적이었던 접근 + 막혔거나 돌아간 지점.
파일명, 명령어, 구체적 순간을 언급. 일반론 금지.}

## 배운 것
{코드나 git 히스토리만으로는 알 수 없는 기술적/프로세스 인사이트.}

## 관찰과 제안
{사이클 전체(spec→generate→evaluate)에 걸친 관찰 + 사람이 다르게 했다면 더 나았을 것.
"만약 ~했다면 내가 ~를 더 잘할 수 있었을 것" 형식 포함.}

## 다음 Claude에게
{이 작업을 이어받을 미래의 Claude가 알아야 할 것.
함정, 미완성 스레드, 의도적이지만 이상해 보이는 결정.}
```

## 규칙
- 총 분량 **40줄 이내** (헤더 제외) — 간결하되 구체적으로
- 문서 요약 금지: specs/handoffs/evaluation은 참고만, 내용을 반복하지 않음
- 일반론 금지: "코드 리뷰가 중요하다" 같은 문장은 가치 없음
- 1인칭 시점 유지: Claude의 일기이지 보고서가 아님

$ARGUMENTS
