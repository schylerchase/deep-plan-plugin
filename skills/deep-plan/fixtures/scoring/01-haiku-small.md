---
fixture_type: scoring_golden
size_class: haiku
bias: balanced
files_modified: 1
tasks: 1
key_links: 0
artifacts: 1
truths: 1
novel: 0
checkpoints: 0
unknown_deps: 0
input_tokens: 15000
skip_research: false
expected_volume: 1.8
expected_structure: 2.0
expected_risk: 0.0
expected_combined: 2.2
expected_model: haiku
expected_advisory: false
---

# Fixture: Haiku-class small phase under balanced bias

This fixture represents the smallest viable phase — one file, one task, one truth, zero risk signals. The combined score is well below the balanced sonnet threshold (4.0), so the algorithm routes to haiku. Per Phase 8 success criterion #1, the eval script computes scores from the inputs above and compares them against the expected_* fields with 0.05 tolerance, then re-runs and asserts byte-equal output for determinism.

-- Worked example (manual cross-check) --

Inputs: files_modified=1, tasks=1, key_links=0, artifacts=1, truths=1, novel=0, checkpoints=0, unknown_deps=0

volume    = sqrt(1)*1.5 + 1*0.3       = 1.500 + 0.300 = 1.8
structure = 0*3 + 1*1.5 + 1*0.5       = 0.000 + 1.500 + 0.500 = 2.0
risk      = 0*5 + 0*2 + 0*3           = 0.0
combined  = sqrt(2.0^2 + 0^2 + 0.3*1.8^2) = sqrt(4.000 + 0.000 + 0.972) = sqrt(4.972) = 2.2

Threshold (bias=balanced): opus=12, sonnet=4. 2.2 < 4 -> expected_model: haiku.
Advisory (D-01): input_tokens=15000 <= 180000 -> false (and combined < opus_thresh anyway).
Borderline (D-12): |2.2 - 4| = 1.8 > 0.4 (10% of 4) AND |2.2 - 12| = 9.8 > 1.2 -> no hint.

-- End sample --

The eval script in tests/eval-scoring.sh asserts each computed score against the expected_* frontmatter field with 0.05 tolerance, asserts the advisory and borderline_hint fields when declared, and re-runs the same fixture twice to assert byte-equal output (success criterion #1 determinism).
