---
fixture_type: scoring_golden
size_class: opus
bias: balanced
files_modified: 10
tasks: 3
key_links: 2
artifacts: 3
truths: 4
novel: 0
checkpoints: 0
unknown_deps: 2
input_tokens: 30000
skip_research: false
expected_volume: 5.6
expected_structure: 12.5
expected_risk: 6.0
expected_combined: 14.2
expected_model: opus
expected_advisory: false
---

# Fixture: Hybrid signal extraction with `<signals>` override block (D-13)

**Scope note (post-WR-5 Phase 8 review):** This fixture is a **spec/UI artifact**, not an end-to-end signal-merge test. Phase 8 does not ship a `<signals>` block parser — the eval harness reads frontmatter only via the frontmatter-only `yaml_get` helper, which is gated on `---` fences and cannot extract keys from a body-level `<signals>` block. The frontmatter values below show the **post-merge** values (i.e., what compute_scores would see AFTER a real `<signals>` parser ran), so the harness validates the math given those merged inputs. A buggy `<signals>` parser would still pass this fixture because no `<signals>` parser is exercised. End-to-end coverage of the `<signals>` extraction + merge code path arrives with the SKILL.md Step 9.5 implementation (Phase 9+).

The fixture therefore proves: (a) the worked-example math for an opus-routed phase with override-derived inputs is correct, and (b) the schema for what a future parser must produce (post-merge signal values) is locked. It does **not** prove the parser itself works.

This fixture represents a CONTEXT.md with a `<signals>` override block per D-13. The frontmatter shows the POST-merge values; the override replaced an auto-extracted files_modified=4 with the manual files_modified=10. Specified signals are manual values, missing signals fall back to auto-extraction. Per Phase 8 success criterion #1, the eval script computes scores from the inputs above and compares them against the expected_* fields with 0.05 tolerance, then re-runs and asserts byte-equal output for determinism.

-- Representative `<signals>` override block (illustrative — not parsed by the harness in Phase 8) --

<signals>
files_modified: 10
</signals>

-- Worked example (manual cross-check) --

Inputs (post-merge): files_modified=10, tasks=3, key_links=2, artifacts=3, truths=4, novel=0, checkpoints=0, unknown_deps=2

volume    = sqrt(10)*1.5 + 3*0.3      = 3.162*1.5 + 0.900 = 4.743 + 0.900 = 5.6
structure = 2*3 + 3*1.5 + 4*0.5       = 6.000 + 4.500 + 2.000 = 12.5
risk      = 0*5 + 0*2 + 2*3           = 6.0
combined  = sqrt(12.5^2 + 6.0^2 + 0.3*5.6^2) = sqrt(156.250 + 36.000 + 9.408) = sqrt(201.658) = 14.2

Threshold (bias=balanced): opus=12, sonnet=4. 14.2 >= 12 -> expected_model: opus.
Advisory (D-01): input_tokens=30000 <= 180000 -> false.
Borderline (D-12): |14.2 - 12| = 2.2 > 1.2 -> no hint near opus. |14.2 - 4| = 10.2 > 0.4 -> no hint near sonnet.

-- End sample --

The eval script in tests/eval-scoring.sh asserts each computed score against the expected_* frontmatter field with 0.05 tolerance, asserts the advisory and borderline_hint fields when declared, and re-runs the same fixture twice to assert byte-equal output (success criterion #1 determinism).

**Tracking item for Phase 9+:** when the SKILL.md Step 9.5 implementation lands and ships a `<signals>` parser, replace this fixture with a real end-to-end variant that declares pre-merge values in frontmatter (e.g., a `signals_pre_merge` block) plus the body-level `<signals>` override, asserts the parser merges them correctly, and asserts compute_scores then produces the expected scores from the post-merge values. See review finding WR-5 in `.planning/phases/08-scoring-algorithm-foundation/08-REVIEW.md` for context.
