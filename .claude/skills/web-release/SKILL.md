---
name: web-release
description: Pre-flight checklist and build pipeline for shipping a web game build (itch.io HTML5, Netlify, Vercel, plain static host). Use when publishing a new version or cutting a release.
---

# web-release

Checklist-driven release for web-deployable builds. Invoke at release time, not mid-development.

## When to use

- User says "ship it", "publish", "release", "deploy", or names a host (itch.io, Netlify, etc.).
- A milestone / jam submission is due.

## Pre-flight checklist

Walk the user through each. Do not skip.

### 1. Code state
- [ ] Working tree clean (`git status`).
- [ ] On the release branch (usually `main`). Confirm with user.
- [ ] Version bumped in `package.json`. Propose a version following semver (or date-based for jams).

### 2. Quality gates
- [ ] `pnpm typecheck` — green.
- [ ] `pnpm test:run` — green.
- [ ] `pnpm lint` — green (or known-OK diff reviewed).
- [ ] Latest `/check` run on the last shipped spec.

### 3. Build
- [ ] `pnpm build` (or `pnpm build:web` if split configs exist).
- [ ] Inspect `dist/` size. Flag anything unusual (>20MB for web is suspicious for indie scope).
- [ ] Source map presence: remove if leaking internals is a concern; keep if debugging public errors matters more.

### 4. Asset paths
- [ ] Test a local static serve (`pnpm exec vite preview` or `python3 -m http.server` in `dist/`).
- [ ] Confirm all assets load — especially audio, fonts, sprite atlases.
- [ ] **itch.io specific**: all asset paths must be relative (`./assets/...`, not `/assets/...`). itch serves under a subpath.

### 5. Metadata
- [ ] `index.html` `<title>` matches the game name.
- [ ] `<meta name="description">` set.
- [ ] Open Graph tags if the page will be shared socially (`og:title`, `og:image`, `og:description`).
- [ ] Favicon present.

### 6. itch.io packaging (if target is itch)
- [ ] Zip `dist/` contents (not the `dist/` folder itself — zip the files).
- [ ] Filename: `<game-name>-web-<version>.zip`.
- [ ] On itch.io: set "This file will be played in the browser" and configure the embed size.

### 7. Static host (Netlify / Vercel / GitHub Pages)
- [ ] Build command and output directory configured in host settings.
- [ ] Custom domain / subdomain verified if applicable.
- [ ] `_redirects` or `vercel.json` for SPA routing if the game uses client-side routing.

### 8. Post-deploy smoke
- [ ] Open the deployed URL in a clean browser session.
- [ ] Play the opening minute. Confirm: no console errors, audio works, inputs work, save/load works (if present).
- [ ] On mobile if targeted.

### 9. Tag
- [ ] `git tag v<version>` and `git push --tags` — only after user explicitly approves.

## Rules

- Do not run destructive commands unprompted (`git tag -d`, `git push --force`).
- If any checklist item fails, stop and surface it. Do not paper over.
- A release is not done until the smoke test passes on the deployed URL.
