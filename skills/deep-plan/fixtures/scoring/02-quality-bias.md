---
fixture_type: scoring_golden
size_class: sonnet
bias: quality
files_modified: 3
tasks: 2
key_links: 1
artifacts: 2
truths: 3
novel: 0
checkpoints: 0
unknown_deps: 1
input_tokens: 45000
skip_research: false
expected_volume: 3.2
expected_structure: 7.5
expected_risk: 3.0
expected_combined: 8.3
expected_model: opus
expected_advisory: false
---

# Fixture: Quality-bias selection drives threshold mapping (W8 lock)

This fixture proves bias selection drives threshold mapping. Under balanced bias the same inputs would route to sonnet (combined 8.3 < opus 12); under quality bias they route to opus (combined 8.3 >= opus 8). ROADMAP success criterion #3. Per Phase 8 success criterion #1, the eval script computes scores from the inputs above and compares them against the expected_* fields with 0.05 tolerance, then re-runs and asserts byte-equal output for determinism.

-- Worked example (manual cross-check) --

Inputs: files_modified=3, tasks=2, key_links=1, artifacts=2, truths=3, novel=0, checkpoints=0, unknown_deps=1

volume    = sqrt(3)*1.5 + 2*0.3       = 1.732*1.5 + 0.600 = 2.598 + 0.600 = 3.2
structure = 1*3 + 2*1.5 + 3*0.5       = 3.000 + 3.000 + 1.500 = 7.5
risk      = 0*5 + 0*2 + 1*3           = 3.0
combined  = sqrt(7.5^2 + 3.0^2 + 0.3*3.2^2) = sqrt(56.250 + 9.000 + 3.072) = sqrt(68.322) = 8.3

Threshold (bias=quality): opus=8, sonnet=3. 8.3 >= 8 -> expected_model: opus.
Advisory (D-01): input_tokens=45000 <= 180000 -> false.
Borderline (D-12): |8.3 - 8| = 0.3 <= 0.8 (10% of 8) -> would fire opus hint, but this fixture omits expected_borderline_hint so the harness does not assert it. See fixture 08 for the dedicated D-12 borderline assertion.

-- End sample --

The eval script in tests/eval-scoring.sh asserts each computed score against the expected_* frontmatter field with 0.05 tolerance, asserts the advisory and borderline_hint fields when declared, and re-runs the same fixture twice to assert byte-equal output (success criterion #1 determinism).
