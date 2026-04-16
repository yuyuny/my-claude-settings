# Spec Template

`specs/{title}.md` must use the format below.

```markdown
# Spec: {session title}

## Goal

{1-2 sentence summary}

## Deliverables

- [ ] Deliverable 1: {described from the user's perspective}
- [ ] Deliverable 2: ...

## Acceptance Criteria (shared with Evaluator)

1. {concrete, verifiable condition}
2. {e.g., "Response within 1 frame after player input"}
3. {e.g., "Error handling exists at all entry points"}

## Verification Criteria (VERIFY)

> Based on the gates defined in `.claude/rules/verify-commands.md`.

- [ ] {gate 1 — e.g., all tests pass}
- [ ] {gate 2 — e.g., build passes}
- [ ] {include only applicable gates}

## Affected Paths

- Primary path: {the standard execution path for the feature. e.g., main entry function → core handler → repository}
- Alternative paths: {non-primary paths yielding the same result — bypasses or special branches. e.g., a shortcut that skips the standard pipeline under certain conditions}
- Interconnected systems: {side systems that must also be updated. e.g., logging/analytics, i18n (if any), docs, external catalogs}

## Technical Constraints

- {stack, compatibility, performance requirements, etc.}

## Non-functional Requirements

- {accessibility, security, performance thresholds, etc.}

## Dependencies

- Preceding session: {none or previous session title}
```
