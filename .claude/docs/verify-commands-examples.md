# Verify Commands — 스택별 예시

> 이 파일은 참고용입니다. 실제 게이트는 `verify-commands.md`의 **현재 프로젝트 게이트** 섹션에만 정의합니다.
> 새 프로젝트 세팅 시 아래에서 해당 스택 예시를 복사해 `verify-commands.md`에 붙여넣으세요.

---

## Node / pnpm

```bash
pnpm test:run   # 테스트 (vitest / jest)
pnpm typecheck  # 타입 체크 (tsc --noEmit)
pnpm lint       # 린트 (eslint / oxlint)
pnpm build      # 빌드 (해당 시)
```

## Python

```bash
poetry run pytest           # 테스트
poetry run mypy src/        # 타입 체크
poetry run ruff check .     # 린트
python -m build             # 패키지 빌드 (해당 시)
```

## Go

```bash
go test ./...       # 테스트
go vet ./...        # 정적 분석
golangci-lint run   # 린트 (설치 시)
go build ./...      # 빌드
```

## Rust

```bash
cargo test          # 테스트
cargo clippy        # 린트
cargo build         # 빌드
```

## Unity (C#)

```bash
# Unity 배치 모드 테스트 (프로젝트 경로 조정 필요)
/Applications/Unity/Hub/Editor/{version}/Unity.app/Contents/MacOS/Unity \
  -batchmode -runTests -testPlatform EditMode \
  -projectPath . -testResults test-results.xml -logFile -
```

## Unreal Engine

```bash
# UAT 테스트 (엔진 경로 조정 필요)
{UE_ROOT}/Engine/Build/BatchFiles/RunUAT.sh BuildCookRun \
  -project="{project}.uproject" -noP4 -platform=Win64 \
  -clientconfig=Development -build -cook -stage
```
