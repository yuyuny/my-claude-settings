# my-claude-settings

Shared Claude Code configuration for 1–3 person indie game development (JS/TS).
Five agents, six commands, two hooks — the minimum structure for disciplined solo game dev.

## What this is

A small, opinionated workflow system that forces coherent decisions across weeks of solo work, where the main risk isn't lack of skill but **drift**: the you-from-last-week disagreeing with the you-from-today.

Not a framework. Not a plugin. Just configuration files for Claude Code that encode a four-phase loop and a handful of reviewer roles.

## The loop

```
/spec → /build → /check → /reflect
                     ↑
                     /prototype (uncertainty branch; promote to /spec when clear)
```

1. **`/spec <name>`** — Designer drafts a spec. Creative-director checks pillar alignment and offers sub-pillar aesthetic proposals. You approve before save.
2. **`/build <spec>`** — Engineer proposes a plan. Technical-director checks architecture. You approve before code.
3. **`/check <spec>`** — Automated gates (typecheck/test/lint) + playtester observations appended to the spec.
4. **`/reflect`** — Honest diary of the session, 40-line cap, saved to `reflections/`.

Plus:

- **`/prototype <name>`** — scaffolds a throwaway spike under `prototypes/<name>/`. Standards relaxed; promote with a `/spec` when ready.
- **`/council <topic>`** — all four workers and directors weigh in independently before a major decision. Use when uncertain about direction.

## Agents

| Agent | Model | Role |
|---|---|---|
| `creative-director` | Opus | pillars, tone, identity. Validates alignment and proposes sub-pillar aesthetic improvements. |
| `technical-director` | Opus | architecture, performance, ADRs. Read-only. |
| `designer` | Sonnet | spec authorship, playtest planning. |
| `engineer` | Sonnet | implementation, code review. Two modes: strict (`src/`) and relaxed (`prototypes/`). |
| `playtester` | Haiku | fresh-eyes evaluator of feel and pacing. |

Agents are invoked automatically by commands. You rarely need to call them by name.

## Skills

- **`project-bootstrap`** — scaffold a new project with pillars, ADR template, directory structure. Asks about engine (Phaser / PixiJS / Three.js / Canvas2D / Electron+React+PixiJS).
- **`web-release`** — pre-flight checklist for itch.io, Netlify, Vercel, or static hosts. Walk through before shipping.

Invoke with natural language: *"bootstrap a new project"*, *"ready to ship a web build"*.

## Hooks

- **`session-start.sh`** — on every session, prints current branch, last reflection title, and specs with unchecked acceptance criteria.
- **`validate-commit.sh`** — PreToolUse on Bash. Blocks `git commit --no-verify`, `git push --force main|master`, and obviously-unsafe `rm -rf /`.

## Directory layout of a project using this

```
specs/                  one file per spec (YYYY-MM-DD-slug.md)
reflections/            /reflect output
prototypes/<name>/      spike code + README.md
playtests/              optional standalone playtest notes
docs/
  pillars.md            3 design pillars — creative-director reads this
  adrs/NNNN-slug.md     technical-director owns these
src/                    production code
assets/                 art, audio, data
.claude/                this config (or a symlink/copy of it)
```

## Setup

**Option A — use this repo directly as `~/.claude/`**

```bash
git clone <this-repo> ~/.claude
```

Claude Code will pick up `~/.claude/CLAUDE.md`, `~/.claude/agents/`, `~/.claude/commands/` as user-level config for every session.

> **Hook note:** The hooks reference `$CLAUDE_PROJECT_DIR`, which resolves to each *project's* root at runtime — not `~/.claude`. This means the hooks run correctly from each project's context. If you clone into `~/.claude` and the hooks are not firing, copy `.claude/settings.json` into your project's `.claude/settings.json` so the hook paths resolve correctly.

**Option B — copy into a specific project**

```bash
cd your-game-project
cp -r path/to/my-claude-settings/.claude ./
```

Project-level `.claude/` overrides user-level for commands and agents.

**Option C — sync as upstream**

Keep `my-claude-settings` as a separate repo, symlink or rsync into each project's `.claude/`. Let each project keep its own `.claude/rules/project/*.md` for project-specific rules (hot paths, styling conventions, etc.) that should not be globalized.

## Typical day

```
# Start of session
# SessionStart hook prints context automatically.

# You have a fuzzy idea — not sure it'll feel right.
/prototype wall-bounce
# ... iterate, play, learn ...
# If it works: promote.
/spec wall-bounce-physics
# Designer drafts; creative-director reviews pillar fit; you approve.
/build specs/2026-04-17-wall-bounce-physics.md
# Engineer plans; technical-director reviews; you approve; implementation runs.
/check specs/2026-04-17-wall-bounce-physics.md
# Automated gates + playtester observations written back into the spec.

# End of meaningful session.
/reflect
```

Before a big decision (should we pivot to roguelike structure? switch from PixiJS to Phaser? cut multiplayer?):

```
/council should we switch the game to permadeath
```

Before shipping:

```
# Invoke the web-release skill implicitly by asking for a release.
ship the web build to itch
```

## Settings

- `defaultMode: plan` — every session starts in plan mode.
- `model: opusplan` — Opus for planning/directors, Sonnet for execution.
- Hooks wired for SessionStart context + Bash safety gate.

## Philosophy (why it's this small)

The original reference (Claude-Code-Game-Studios) ships 49 agents and 72 commands. That's built for an actual studio. For 1–3 people, 90% of that is ceremony that nobody executes.

What remains here:
- **2 directors** — the minimum for "am I being consistent with my own past decisions?"
- **3 workers** — designer/engineer/playtester, each with a viewpoint that cannot be collapsed.
- **4-phase loop** — spec/build/check/reflect is the smallest rhythm that still forces discipline.
- **1 escape hatch** — `/prototype` for when the spec-first discipline would kill exploration.
- **1 review gate** — `/council` for when the solo dev needs to argue with themselves.

Anything more is weight. Anything less and you lose the ability to come back to this project in 3 weeks and still know what past-you was thinking.

## Prerequisites

- [Claude Code](https://claude.ai/code) (latest stable release recommended).
- A JS/TS game project. The workflow assumes a `package.json` exists with scripts named `typecheck`, `test` (or `test:run`), and `lint`. The package manager is auto-detected (`pnpm`, `yarn`, `bun`, or `npm`).
- No global pnpm requirement — whichever package manager your project uses is fine.

## Upstream

This configuration is a distillation of [Claude-Code-Game-Studios](https://github.com/Anthropic-claude-code-game-studios/claude-code-game-studios) (49 agents, 72 commands) trimmed down for 1–3 person teams. See that project for the full-studio variant.

## License

MIT — see [LICENSE](LICENSE).
