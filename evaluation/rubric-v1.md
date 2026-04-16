# Evaluation Rubric v1.0

**Applied from**: 2026-03-07
**Last modified**: 2026-04-14

> When changing the rubric, increment the version (v1.1, v2.0, etc.) and record the reason for the change.
> State the rubric version used at the top of every `evaluation/{title}.md` file.

---

## Scoring Criteria

| Criteria | Weight | Description |
|------|--------|------|
| **Feature completeness** | 30% | Whether the acceptance criteria in `specs/{title}.md` are met. Check all deliverables including alternative paths. |
| **Code quality** | 25% | Structure, readability, maintainability, test coverage. Includes whether REVIEW log was executed. |
| **Design/UX** | 25% | (if applicable) Usability, visual polish, responsiveness, completeness of i18n & accessibility. |
| **Edge cases** | 20% | Exception handling, alternative code path coverage, input validation, error recovery. |

---

## PASS Criteria

- Weighted average **≥ 7.0**
- All items **≥ 5.0** (prevents failure on a single item)
- All VERIFY gates passed (tests / typecheck / lint / build)

## Score Reference

| Score | Meaning |
|------|------|
| 9-10 | Exceeds production quality. Higher completion than expected. |
| 7-8 | Production quality. Ready for real use. |
| 5-6 | Works but needs improvement. PASS boundary. |
| 3-4 | Major features incomplete or quality issues. |
| 1-2 | Implementation attempt level. Mostly incomplete. |

> **Note**: A 7 means "production ready", not "good enough".
> No score inflation. Judge by evidence only (code + execution results).

---

## Weight Adjustments by Project Type

The "Design/UX" item applies to **projects with a UI**.
For projects without UI (CLI tools, libraries, infrastructure code, etc.), use the alternative weights below.

| Project type | Feature completeness | Code quality | Design/API | Edge cases |
|--------------|------------|----------|----------|------------|
| **With UI** (default) | 30% | 25% | 25% (UX) | 20% |
| **CLI / Library** | 35% | 30% | 15% (API design) | 20% |
| **Infrastructure / Scripts** | 35% | 25% | 10% (operational ergonomics) | 30% |

- State the weight profile used at the top of the evaluation file (e.g., `Weight profile: CLI/Library`)
- PASS criteria (weighted average ≥ 7.0, all items ≥ 5.0) are the same regardless of profile

---

## Change History

| Version | Date | Changes |
|------|------|-----------|
| v1.0 | 2026-03-07 | Initial version. 4-dimension scoring (features 30% / quality 25% / UX 25% / edge 20%). |
