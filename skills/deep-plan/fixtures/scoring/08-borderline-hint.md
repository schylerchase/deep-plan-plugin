---
fixture_type: scoring_golden
size_class: borderline_hint
bias: balanced
files_modified: 2
tasks: 2
key_links: 2
artifacts: 2
truths: 4
novel: 0
checkpoints: 0
unknown_deps: 1
input_tokens: 25000
skip_research: false
expected_volume: 2.7
expected_structure: 11.0
expected_risk: 3.0
expected_combined: 11.5
expected_model: sonnet
expected_advisory: false
expected_borderline_hint: close to opus threshold; bump bias to quality if you want opus
---

# Fixture: Borderline opus hint (D-12, VALIDATION task 8-07-02)

This fixture is the dedicated D-12 borderline-hint assertion mandated by VALIDATION.md task 8-07-02. The combined score 11.5 sits in the lower ±10% band around opus threshold 12 (band: 10.8 to 13.2). The harness asserts the exact hint string against the expected_borderline_hint frontmatter field. Per Phase 8 success criterion #1, the eval script computes scores from the inputs above and compares them against the expected_* fields with 0.05 tolerance, then re-runs and asserts byte-equal output for determinism.

-- Worked example (manual cross-check) --

Inputs: files_modified=2, tasks=2, key_links=2, artifacts=2, truths=4, novel=0, checkpoints=0, unknown_deps=1

volume    = sqrt(2)*1.5 + 2*0.3       = 1.414*1.5 + 0.600 = 2.121 + 0.600 = 2.7
structure = 2*3 + 2*1.5 + 4*0.5       = 6.000 + 3.000 + 2.000 = 11.0
risk      = 0*5 + 0*2 + 1*3           = 3.0
combined  = sqrt(11.0^2 + 3.0^2 + 0.3*2.7^2) = sqrt(121.000 + 9.000 + 2.187) = sqrt(132.187) = 11.5

Threshold (bias=balanced): opus=12, sonnet=4. 11.5 < 12 AND 11.5 >= 4 -> expected_model: sonnet.
Advisory (D-01): input_tokens=25000 <= 180000 -> false.
Borderline (D-12): |11.5 - 12| = 0.5 <= 1.2 (10% of 12) -> opus borderline triggers -> expected_borderline_hint: "close to opus threshold; bump bias to quality if you want opus".

-- End sample --

The eval script in tests/eval-scoring.sh asserts each computed score against the expected_* frontmatter field with 0.05 tolerance, asserts the advisory and borderline_hint fields when declared, and re-runs the same fixture twice to assert byte-equal output (success criterion #1 determinism).
