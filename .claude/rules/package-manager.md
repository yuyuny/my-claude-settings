# Package manager detection

To detect the project's package manager, look for lock files in this order:
1. `pnpm-lock.yaml` → `pnpm`
2. `yarn.lock` → `yarn`
3. `bun.lockb` → `bun`
4. `package-lock.json` → `npm`
5. No lock file found → `npm`

Read `package.json` `scripts` before running. Use the detected manager to invoke only the scripts that exist (e.g. `typecheck`, `test:run` or `test`, `lint`, `lint:css`).
