# CLAUDE.md

이 저장소는 Claude Code 멀티에이전트 워크플로우 템플릿입니다.

## 워크플로우 개요

`/brainstorm` (선택) → `/spec` → `/generate` → `/evaluate` (별도 세션) → `/reflect`

핵심 규칙: `.claude/rules/multi-agent-workflow.md`

## 새 프로젝트 적용 시 수정 필요 파일

1. `.claude/rules/verify-commands.md` — 현재 프로젝트 게이트 섹션을 스택에 맞게 교체
2. `evaluation/rubric-v1.md` — 프로젝트 유형(UI/CLI/인프라)에 맞는 가중치 프로필 확인
3. `.claude/settings.local.json` — 프로젝트에서 사용하는 CLI 권한 추가

## 세션 상태 확인

```
/workflow-status
```

## 스택별 게이트 예시

`docs/verify-commands-examples.md` 참조
