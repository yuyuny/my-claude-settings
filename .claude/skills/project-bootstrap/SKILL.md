---
name: project-bootstrap
description: Scaffold a new JS/TS indie game project with the workflow directories and core docs. Use when starting a new game from scratch or adopting this workflow into an existing project. Supports Phaser, PixiJS, Three.js, and plain Canvas 2D.
---

# project-bootstrap

Scaffolds directories and seed docs that the `/spec → /build → /check → /reflect` workflow expects.

## When to use

- Starting a new game project from zero.
- Adopting this workflow into an existing JS/TS project.
- User asks to "set up the project" or "bootstrap".

## What to create

### Directories
```
specs/          # /spec output
reflections/    # /reflect output
prototypes/     # /prototype spikes
playtests/      # standalone playtest notes (optional, outside /check)
docs/
  pillars.md    # game identity — the north star
  adrs/         # technical-director's ADR records
src/            # application code (likely already exists)
assets/         # art, audio, data (likely already exists)
```

### Seed files

**`docs/pillars.md`** — do not auto-fill. Prompt the user for 3 pillars. Example format:
```markdown
# Design Pillars

1. **<Name>** — <one paragraph: what this means and what it rules out>
2. **<Name>** — ...
3. **<Name>** — ...

## Rules of thumb
- If a feature contradicts a pillar, the pillar wins.
- Pillars change only after explicit review. Do not silently edit.
```

**`docs/adrs/0000-template.md`** — copyable template:
```markdown
# ADR NNNN — <title>

## Context
<What forced this decision.>

## Options considered
1. <Option A> — pros / cons
2. <Option B> — pros / cons

## Decision
<Chosen. Why.>

## Consequences
<What this makes easy. What this makes hard. What we'll need to revisit.>

## Status
proposed | accepted | superseded-by-NNNN | deprecated
```

**`.gitignore` additions** (if missing):
```
node_modules
dist
dist-*
.DS_Store
*.log
```

## Engine decision

Ask the user which engine before scaffolding build config. Each has trade-offs:

- **Phaser** — batteries-included 2D. Fastest path for arcade/platformer/puzzle.
- **PixiJS** — 2D renderer, bring your own systems. Best for bullet hell, unusual UIs, full control.
- **Three.js** — 3D. Consider only if 3D is core.
- **Canvas 2D (no framework)** — minimal bundle, maximum understanding. Fine for jams and small games.
- **Electron + React + PixiJS** — desktop-distributable, game-in-window pattern (see the `shoot` project structure).

Propose `vite` as the build tool by default (fast dev, simple config, web-deployable). Confirm before writing configs.

## Process

1. Ask: engine choice, target (web / desktop / both), project name, 3 design pillars.
2. Create directories.
3. Write seed `docs/pillars.md` with the user's pillars.
4. Write `docs/adrs/0000-template.md`.
5. If no `package.json` exists, scaffold one with `vite` + the chosen engine's core deps. Confirm deps list with user first.
6. Update `.gitignore`.
7. Print the tree and a single suggested next command: typically `/spec <first-feature>`.

## Rules

- Never auto-generate pillar content. Pillars are the user's commitment to an identity; you cannot guess them.
- Ask before running `pnpm install` or adding deps.
- Do not create source files (e.g. `src/main.ts`) — that's the first `/spec` + `/build` cycle, not bootstrap.
