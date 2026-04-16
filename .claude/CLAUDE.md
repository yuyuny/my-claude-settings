# CLAUDE.md

이 저장소는 Claude Code 멀티에이전트 워크플로우 템플릿입니다.

## 워크플로우 개요

`/brainstorm` (선택) → `/spec` → `/generate` → `/evaluate` (별도 세션) → `/reflect`

핵심 규칙: `.claude/rules/multi-agent-workflow.md`

## 새 프로젝트 적용 시 수정 필요 파일

1. `.claude/rules/verify-commands.md` — 현재 프로젝트 게이트 섹션을 스택에 맞게 교체
2. `evaluation/rubric-v1.md` — 프로젝트 유형(UI/CLI/인프라)에 맞는 가중치 프로필 확인
3. `.claude/settings.local.json` — 프로젝트에서 사용하는 CLI 권한 추가
4. `.claude/settings.json` — `"model"` 설정 확인 (기본값: `opusplan`)

## 기본 동작

- **기본 모드**: `plan` (settings.json) — 구현 시 ask/auto 모드로 전환 필요
- **Stop hook**: 각 커맨드 완료 후 다음 단계를 자동 안내 (클립보드 복사 + 알림)

## 세션 상태 확인

```
/workflow-status
```

## 스택별 게이트 예시

`.claude/docs/verify-commands-examples.md` 참조
