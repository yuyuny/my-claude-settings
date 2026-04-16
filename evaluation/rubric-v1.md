# Evaluation Guideline v1.0

**Applied from**: 2026-03-07
**Last modified**: 2026-04-17

> This is a **guideline**, not a scoring formula. Use it to calibrate judgment, not to derive a number.

---

## What PASS Means

PASS requires all three:
1. **Deliverables complete** — every item in the spec's "## Deliverables" is present and works as described in the acceptance criteria
2. **VERIFY gates pass** — all gates in `verify-commands.md` succeed
3. **No critical issues** — no security holes, data loss paths, or broken core functionality

If any of these fail, verdict is FAIL regardless of other quality.

---

## Quality Dimensions (calibration only — not scored)

These help identify *why* something is FAIL and what to put in "Needs Improvement":

| Dimension | What to look for |
|-----------|-----------------|
| **Feature completeness** | Are all acceptance criteria met, including alternative paths? |
| **Code quality** | Is the code readable, tested where meaningful, and reviewed (REVIEW log)? |
| **Design/UX** | (if applicable) Does the UI behave as the spec describes? |
| **Edge cases** | Are error paths, invalid inputs, and boundary conditions handled? |

---

## Weight Adjustments by Project Type

Use these to calibrate how much weight each dimension gets in your FAIL feedback:

| Project type | Feature | Quality | Design | Edge cases |
|--------------|---------|---------|--------|------------|
| **With UI** | high | medium | high | medium |
| **CLI / Library** | high | high | low (API design) | medium |
| **Infrastructure** | high | medium | low (ops ergonomics) | high |

---

## Change History

| Version | Date | Changes |
|---------|------|---------|
| v1.0 | 2026-03-07 | Initial version. 4-dimension scoring. |
| v1.1 | 2026-04-17 | Converted from scoring rubric to calibration guideline. Removed numeric thresholds. |
