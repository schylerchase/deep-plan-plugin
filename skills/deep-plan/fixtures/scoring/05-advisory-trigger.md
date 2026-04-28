---
fixture_type: scoring_golden
size_class: advisory
bias: balanced
files_modified: 15
tasks: 8
key_links: 5
artifacts: 10
truths: 15
novel: 3
checkpoints: 2
unknown_deps: 4
input_tokens: 190000
skip_research: false
expected_volume: 8.2
expected_structure: 37.5
expected_risk: 31.0
expected_combined: 48.9
expected_model: opus
expected_advisory: true
---

# Fixture: Phase-split advisory triggers (D-01 strict AND gate)

This fixture exercises the D-01 advisory: input_tokens > 180000 AND combined >= opus_threshold. Both gates clear (190k > 180k AND 48.9 >= 12), so the advisory fires. ROADMAP success criterion #3. Per Phase 8 success criterion #1, the eval script computes scores from the inputs above and compares them against the expected_* fields with 0.05 tolerance, then re-runs and asserts byte-equal output for determinism.

-- Worked example (manual cross-check) --

Inputs: files_modified=15, tasks=8, key_links=5, artifacts=10, truths=15, novel=3, checkpoints=2, unknown_deps=4, input_tokens=190000

volume    = sqrt(15)*1.5 + 8*0.3      = 3.873*1.5 + 2.400 = 5.809 + 2.400 = 8.2
structure = 5*3 + 10*1.5 + 15*0.5     = 15.000 + 15.000 + 7.500 = 37.5
risk      = 3*5 + 2*2 + 4*3           = 15.000 + 4.000 + 12.000 = 31.0
combined  = sqrt(37.5^2 + 31.0^2 + 0.3*8.2^2) = sqrt(1406.250 + 961.000 + 20.172) = sqrt(2387.422) = 48.9

Threshold (bias=balanced): opus=12, sonnet=4. 48.9 >= 12 -> expected_model: opus.
Advisory (D-01): input_tokens=190000 > 180000 AND combined=48.9 >= opus_thresh=12 -> expected_advisory: true.
Borderline (D-12): |48.9 - 12| = 36.9 > 1.2 -> no hint.

-- End sample --

The eval script in tests/eval-scoring.sh asserts each computed score against the expected_* frontmatter field with 0.05 tolerance, asserts the advisory and borderline_hint fields when declared, and re-runs the same fixture twice to assert byte-equal output (success criterion #1 determinism).
