---
fixture_type: scoring_golden
size_class: reduced_confidence
bias: balanced
files_modified: 5
tasks: 3
key_links: 2
artifacts: 4
truths: 5
novel: 0
checkpoints: 1
unknown_deps: 0
input_tokens: 20000
skip_research: true
expected_volume: 4.3
expected_structure: 14.5
expected_risk: 2.0
expected_combined: 14.8
expected_model: opus
expected_advisory: false
---

# Fixture: Reduced confidence — `--skip-research` zero-fallback (D-08)

This fixture represents a phase where the `--skip-research` flag was passed; novel and unknown_deps fall back to zero per D-08. The algorithm still produces a recommendation, but the banner appends a reduced-confidence note (Plan 03 will document the banner string). Per Phase 8 success criterion #1, the eval script computes scores from the inputs above and compares them against the expected_* fields with 0.05 tolerance, then re-runs and asserts byte-equal output for determinism.

-- Worked example (manual cross-check) --

Inputs: files_modified=5, tasks=3, key_links=2, artifacts=4, truths=5, novel=0 (forced by --skip-research), checkpoints=1, unknown_deps=0 (forced by --skip-research)

volume    = sqrt(5)*1.5 + 3*0.3       = 2.236*1.5 + 0.900 = 3.354 + 0.900 = 4.3
structure = 2*3 + 4*1.5 + 5*0.5       = 6.000 + 6.000 + 2.500 = 14.5
risk      = 0*5 + 1*2 + 0*3           = 2.0
combined  = sqrt(14.5^2 + 2.0^2 + 0.3*4.3^2) = sqrt(210.250 + 4.000 + 5.547) = sqrt(219.797) = 14.8

Threshold (bias=balanced): opus=12, sonnet=4. 14.8 >= 12 -> expected_model: opus.
Advisory (D-01): input_tokens=20000 <= 180000 -> false.
Borderline (D-12): |14.8 - 12| = 2.8 > 1.2 -> no hint.

-- End sample --

The eval script in tests/eval-scoring.sh asserts each computed score against the expected_* frontmatter field with 0.05 tolerance, asserts the advisory and borderline_hint fields when declared, and re-runs the same fixture twice to assert byte-equal output (success criterion #1 determinism).
