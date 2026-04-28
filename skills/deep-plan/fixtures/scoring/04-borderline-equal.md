---
fixture_type: scoring_golden
size_class: borderline
bias: balanced
files_modified: 0
tasks: 0
key_links: 4
artifacts: 0
truths: 0
novel: 0
checkpoints: 0
unknown_deps: 0
input_tokens: 10000
skip_research: false
expected_volume: 0.0
expected_structure: 12.0
expected_risk: 0.0
expected_combined: 12.0
expected_model: opus
expected_advisory: false
expected_borderline_hint: ""
---

# Fixture: Boundary case — combined exactly equals opus threshold

This fixture locks the `>=` decision (RESEARCH.md Pitfall 4): a phase scoring exactly the opus threshold maps to opus, not sonnet. Inputs are tuned so structure alone produces combined=12.0, matching the balanced opus threshold to the decimal. Per Phase 8 success criterion #1, the eval script computes scores from the inputs above and compares them against the expected_* fields with 0.05 tolerance, then re-runs and asserts byte-equal output for determinism.

-- Worked example (manual cross-check) --

Inputs: files_modified=0, tasks=0, key_links=4, artifacts=0, truths=0, novel=0, checkpoints=0, unknown_deps=0

volume    = sqrt(0)*1.5 + 0*0.3       = 0.000 + 0.000 = 0.0
structure = 4*3 + 0*1.5 + 0*0.5       = 12.000 + 0.000 + 0.000 = 12.0
risk      = 0*5 + 0*2 + 0*3           = 0.0
combined  = sqrt(12.0^2 + 0^2 + 0.3*0^2) = sqrt(144.000 + 0.000 + 0.000) = sqrt(144.000) = 12.0

Threshold (bias=balanced): opus=12, sonnet=4. 12.0 >= 12 -> expected_model: opus (locks the >= rule).
Advisory (D-01): input_tokens=10000 <= 180000 -> false.
Borderline (D-12, post-WR-2): combined=12.0 is NOT below opus_threshold=12 (the gate is `combined < opus_threshold`), so no opus hint fires. The fixture asserts `expected_borderline_hint: ""` to lock this behavior. The hint exists to surface a near-miss the user could correct by bumping bias — when combined already meets or exceeds the threshold, the user already routes to opus and the suggestion would be misleading. See fixture 08 for the lower-band case (combined=11.5 below opus=12) where the hint correctly fires.

-- End sample --

The eval script in tests/eval-scoring.sh asserts each computed score against the expected_* frontmatter field with 0.05 tolerance, asserts the advisory and borderline_hint fields when declared, and re-runs the same fixture twice to assert byte-equal output (success criterion #1 determinism).
