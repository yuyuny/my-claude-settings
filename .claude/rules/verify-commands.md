# Verify Commands

Generator Step 5와 Evaluator Step 2에서 실행할 검증 게이트를 정의합니다.
이 파일만 교체하면 어떤 스택/도메인에서도 동일한 워크플로우가 작동합니다.

## 실행 규칙 (모든 서브에이전트 적용)

- 빌드/테스트/lint/타입체크/기타 언어 런타임 바이너리는 **반드시 프로젝트 패키지 매니저를 경유**해 호출한다.
- **Node/pnpm 스택**: `pnpm <script>` 또는 `pnpm exec <bin>` 사용. `npx`, `node <바이너리>`, 바이너리 직접 호출(`vitest`, `tsc`, `eslint`, `prettier`, `stylelint`, `oxlint`, `tsx` 등) **금지**.
- 이유: git worktree는 메인 저장소의 `node_modules`를 공유하지 않는다. 직접 호출은 `.bin` PATH를 찾지 못해 `command not found` 또는 `MODULE_NOT_FOUND`로 실패한다.
- 예외: `node -e "..."` 같은 인라인 스니펫은 허용 (파일 바이너리를 해석하지 않음).
- 다른 스택의 경우에도 동일 원칙 적용: `poetry run`, `go run` 등 해당 패키지 매니저 경유.

## 현재 프로젝트 게이트

> **이 섹션을 프로젝트에 맞게 수정하세요.**
> 기본값은 Node/pnpm 스택입니다.

```bash
pnpm test:run   # 테스트
pnpm typecheck  # 타입 체크
pnpm lint       # 린트
pnpm build      # 빌드 (해당 시)
```

## 스택별 참고 예시

프로젝트에 맞는 게이트로 위 기본값을 교체하면 됩니다.

### Python
```bash
pytest              # 테스트
mypy src/           # 타입 체크
ruff check .        # 린트
python -m build     # 패키지 빌드 (해당 시)
```

### Go
```bash
go test ./...       # 테스트
go vet ./...        # 정적 분석
golangci-lint run   # 린트 (설치 시)
go build ./...      # 빌드
```

### Unity (C#)
```bash
# Unity 배치 모드 테스트 (프로젝트 경로 조정 필요)
/Applications/Unity/Hub/Editor/{version}/Unity.app/Contents/MacOS/Unity \
  -batchmode -runTests -testPlatform EditMode \
  -projectPath . -testResults test-results.xml -logFile -
```

### Unreal Engine
```bash
# UAT 테스트 (엔진 경로 조정 필요)
{UE_ROOT}/Engine/Build/BatchFiles/RunUAT.sh BuildCookRun \
  -project="{project}.uproject" -noP4 -platform=Win64 \
  -clientconfig=Development -build -cook -stage
```

### Rust
```bash
cargo test          # 테스트
cargo clippy        # 린트
cargo build         # 빌드
```

## 규칙

- 게이트는 **순차 실행** — 앞 단계 실패 시 뒤 단계는 생략하지 않고 모두 실행 후 전체 결과 보고
- 게이트가 없는 항목(예: 빌드 불필요)은 `# 해당 없음`으로 명시
- 게이트 추가/제거 후 이 파일을 커밋하면 Generator·Evaluator 모두 자동 반영됨
