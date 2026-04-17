---
description: Create a throwaway spike in prototypes/. No spec required, relaxed rules.
argument-hint: <prototype-name>
---

# /prototype — explore without commitment

Scaffold a spike in `prototypes/<name>/`. The point is fast learning, not quality.

## Process

1. **Confirm intent.** Prototypes are for **uncertain** ideas ("does this feel right?", "is this technically possible?"). If the idea is already well-defined, suggest `/spec` instead.

2. **Determine the name.** Kebab-case from `$ARGUMENTS`, or ask the user.

3. **Create `prototypes/<name>/`** with a minimal `README.md`:

   ```markdown
   # <name>

   **What I'm exploring:** <one sentence>

   **Hypothesis:** <what I expect to learn>

   **How to run:** <command or instruction>

   **Status:** exploring | promoted-to-spec | abandoned
   ```

4. **Invoke the `engineer` subagent in relaxed mode**. The engineer:
   - Writes the minimum code to test the hypothesis.
   - Skips typecheck, lint, formal tests.
   - Mutates freely, hardcodes freely.
   - Uses only the files inside `prototypes/<name>/` unless a shared dep is needed.

5. **When done**, ask the user whether to:
   - Promote: copy insights into a `/spec` for real implementation.
   - Abandon: update README status, leave in tree as a record.
   - Delete: remove entirely.

## Rules

- Nothing from `prototypes/` is ever imported by `src/`.
- Prototypes are not reviewed by creative-director or technical-director during exploration — they're off-map.
- Keep each prototype under ~500 lines. If it's bigger, it's not a prototype anymore.

$ARGUMENTS
