---
fixture_type: scoring_golden
size_class: opus
bias: balanced
files_modified: 12
tasks: 6
key_links: 4
artifacts: 8
truths: 10
novel: 2
checkpoints: 2
unknown_deps: 3
input_tokens: 95000
skip_research: false
expected_volume: 7.0
expected_structure: 29.0
expected_risk: 23.0
expected_combined: 37.2
expected_model: opus
expected_advisory: false
---

# Fixture: Opus-class large phase under balanced bias

This fixture represents a large multi-unit phase with significant structure and risk signals. The combined score sits well above the balanced opus threshold (12.0), so the algorithm routes to opus. Input tokens stay under the 180k advisory threshold, so the advisory does not fire even though combined complexity is high. Per Phase 8 success criterion #1, the eval script computes scores from the inputs above and compares them against the expected_* fields with 0.05 tolerance, then re-runs and asserts byte-equal output for determinism.

-- Worked example (manual cross-check) --

Inputs: files_modified=12, tasks=6, key_links=4, artifacts=8, truths=10, novel=2, checkpoints=2, unknown_deps=3

volume    = sqrt(12)*1.5 + 6*0.3      = 3.464*1.5 + 1.800 = 5.196 + 1.800 = 7.0
structure = 4*3 + 8*1.5 + 10*0.5      = 12.000 + 12.000 + 5.000 = 29.0
risk      = 2*5 + 2*2 + 3*3           = 10.000 + 4.000 + 9.000 = 23.0
combined  = sqrt(29.0^2 + 23.0^2 + 0.3*7.0^2) = sqrt(841.000 + 529.000 + 14.700) = sqrt(1384.700) = 37.2

Threshold (bias=balanced): opus=12, sonnet=4. 37.2 >= 12 -> expected_model: opus.
Advisory (D-01): input_tokens=95000 <= 180000 -> false (combined exceeds opus_thresh but token gate fails the strict AND).
Borderline (D-12): |37.2 - 12| = 25.2 > 1.2 -> no hint.

-- End sample --

The eval script in tests/eval-scoring.sh asserts each computed score against the expected_* frontmatter field with 0.05 tolerance, asserts the advisory and borderline_hint fields when declared, and re-runs the same fixture twice to assert byte-equal output (success criterion #1 determinism).
