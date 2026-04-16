# Workflow Status

현재 진행 중인 모든 세션의 상태를 조회합니다.
새 세션을 열었을 때 컨텍스트를 즉시 복원하는 용도입니다.

## 프로세스

### Step 1: 상태 파일 스캔

```bash
python3 -c "
import json, os, glob, datetime

sessions_dir = '.claude-workflow/sessions'
if not os.path.exists(sessions_dir):
    print('활성 세션 없음 — .claude-workflow/sessions/ 디렉토리가 없습니다.')
    exit()

files = sorted(glob.glob(f'{sessions_dir}/*.json'), key=os.path.getmtime, reverse=True)
if not files:
    print('활성 세션 없음')
    exit()

STATE_LABELS = {
    'spec_draft':      '📝 spec 작성 필요',
    'spec_ready':      '⚠️  [승인 게이트] spec 검토 후 /generate',
    'generating':      '🔨 구현 진행 중',
    'handoff_ready':   '📦 [다음] 별도 세션에서 /evaluate',
    'evaluating':      '🔍 평가 진행 중',
    'evaluated_pass':  '✅ [승인 게이트] PASS — 머지 확인 후 /reflect',
    'evaluated_fail':  '❌ [승인 게이트] FAIL — 재작업/스펙재정의/포기 결정',
    'reflecting':      '💭 회고 진행 중',
    'done':            '🎉 완료',
}

print()
print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━')
print('[workflow-status] 진행 중인 세션')
print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━')
for f in files:
    try:
        d = json.load(open(f))
        title = d.get('title', os.path.basename(f).replace('.json', ''))
        state = d.get('state', 'unknown')
        label = STATE_LABELS.get(state, state)
        updated = d.get('updated_at', '')[:16].replace('T', ' ')
        print(f'  {title}')
        print(f'    상태: {label}')
        print(f'    마지막 업데이트: {updated} UTC')
        arts = d.get('artifacts', {})
        existing = [k for k, v in arts.items() if v and os.path.exists(v)]
        if existing:
            print(f'    산출물: {\" / \".join(existing)}')
        next_a = d.get('next_action')
        if next_a:
            print(f'    다음 액션: {next_a}')
        print()
    except Exception as e:
        print(f'  {f}: 읽기 실패 ({e})')
print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━')
"
```

### Step 2: git 컨텍스트 보조

```bash
# 활성 워크트리 목록
git worktree list 2>/dev/null | grep -v "$(git rev-parse --show-toplevel)" || true
```

### Step 3: 다음 액션 안내

Step 1 출력에서 `[승인 게이트]` 표시가 있는 세션은 사람의 결정이 필요합니다.
나머지는 안내된 커맨드를 그대로 실행하면 됩니다.

## 규칙

- 이 커맨드는 읽기 전용입니다. 상태 파일을 수정하지 않습니다.
- 상태 파일이 없어도 오류 없이 종료합니다.
- 진행 중인 세션이 많을 경우 가장 최근 수정 순서로 표시됩니다.

$ARGUMENTS
