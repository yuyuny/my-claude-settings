# Workflow Status

현재 진행 중인 모든 세션의 상태를 조회합니다.
새 세션을 열었을 때 컨텍스트를 즉시 복원하는 용도입니다.

## 프로세스

### Step 1: 상태 파일 스캔

```bash
python3 .claude/scripts/workflow-status.py
```

### Step 2: git 컨텍스트 보조

```bash
# 활성 워크트리 목록
git worktree list 2>/dev/null | grep -v "$(cd "$(git rev-parse --git-common-dir)/.." && pwd)" || true
```

### Step 3: 다음 액션 안내

Step 1 출력에서 `[승인 게이트]` 표시가 있는 세션은 사람의 결정이 필요합니다.
나머지는 안내된 커맨드를 그대로 실행하면 됩니다.

## 규칙

- 이 커맨드는 읽기 전용입니다. 상태 파일을 수정하지 않습니다.
- 상태 파일이 없어도 오류 없이 종료합니다.
- 진행 중인 세션이 많을 경우 가장 최근 수정 순서로 표시됩니다.

$ARGUMENTS
