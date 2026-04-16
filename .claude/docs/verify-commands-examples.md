# Verify Commands — Stack Examples

> This file is for reference only. Actual gates are defined solely in the **Current Project Gates** section of `verify-commands.md`.
> When setting up a new project, copy the appropriate stack example below into `verify-commands.md`.

---

## Node / pnpm

```bash
pnpm test:run   # tests (vitest / jest)
pnpm typecheck  # type check (tsc --noEmit)
pnpm lint       # lint (eslint / oxlint)
pnpm build      # build (if applicable)
```

## Python

```bash
poetry run pytest           # tests
poetry run mypy src/        # type check
poetry run ruff check .     # lint
python -m build             # package build (if applicable)
```

## Go

```bash
go test ./...       # tests
go vet ./...        # static analysis
golangci-lint run   # lint (if installed)
go build ./...      # build
```

## Rust

```bash
cargo test          # tests
cargo clippy        # lint
cargo build         # build
```

## Unity (C#)

```bash
# Unity batch mode tests (adjust project path as needed)
/Applications/Unity/Hub/Editor/{version}/Unity.app/Contents/MacOS/Unity \
  -batchmode -runTests -testPlatform EditMode \
  -projectPath . -testResults test-results.xml -logFile -
```

## Unreal Engine

```bash
# UAT tests (adjust engine path as needed)
{UE_ROOT}/Engine/Build/BatchFiles/RunUAT.sh BuildCookRun \
  -project="{project}.uproject" -noP4 -platform=Win64 \
  -clientconfig=Development -build -cook -stage
```
