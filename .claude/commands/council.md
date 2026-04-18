---
description: Multi-perspective review. Calls both directors plus designer and engineer simultaneously on a topic.
argument-hint: <topic or draft file>
---

# /council — multi-agent review

Get independent perspectives from creative-director, technical-director, designer, and engineer on a topic or draft.

Use this **before** a major decision — direction change, tech-stack shift, scope question, ambiguous spec.

> **Cost note:** `/council` runs Opus×2 + Sonnet×2 in parallel. Use it sparingly — for decisions you genuinely cannot resolve alone. For smaller doubts, ask one agent directly.

## Process

1. **Establish the topic.** If `$ARGUMENTS` is a file path, read it and use it as the subject. Otherwise treat `$ARGUMENTS` as the topic text.

2. **Brief all four subagents in a single parallel batch** — dispatch `creative-director`, `technical-director`, `designer`, and `engineer` in one message with parallel tool calls. Each receives the same input and cannot see the others' responses.
   - `creative-director` → identity/tone implications
   - `technical-director` → architecture/performance implications
   - `designer` → player-experience/system implications
   - `engineer` → feasibility/effort/risks

3. **Assemble the verdicts** (you, the main Claude, compile this) into a single report:

   ```markdown
   ## Council — <topic>

   ### Creative Director
   <verdict + 10-line take>

   ### Technical Director
   <verdict + 10-line take>

   ### Designer
   <10-line take>

   ### Engineer
   <10-line take>

   ### Tensions
   <where perspectives conflict — this is the useful output>

   ### Open questions for the user
   <what the council cannot resolve without you>
   ```

4. **Print the assembled report.** Do not save to file unless the user asks — councils produce a lot of text and most don't need archiving.

## Rules

- Do not try to reconcile the verdicts yourself. Present the conflicts honestly — that's the value.
- If all four agents agree, say so and suggest the user may not have needed a council for this.
- Do not implement anything as part of `/council`. This is advisory only.

$ARGUMENTS
