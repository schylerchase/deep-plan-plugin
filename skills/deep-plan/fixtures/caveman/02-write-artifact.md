---
fixture_type: artifact_write
hard_override: true
rule_version: v1
origin: tuning-session-01
---

# Fixture: Artifact content written via Write tool (HARD override)

When Claude invokes the Write tool to emit a `.md` file during deep-plan — most commonly at stage 8 (write_plan), but also any other file write — the content MUST be full prose regardless of the caveman mode currently active in chat. Caveman does not bleed into artifacts.

The first real tuning session verified this override holds implicitly. Caveman `full` was active in chat throughout the session, yet the written PLAN.md body was full prose with articles, complete sentences, and explanatory paragraphs. Claude's Write-tool heuristic naturally distinguishes "chat" from "file content" and gravitates toward prose for the latter.

This fixture asserts the expected prose quality. The eval script checks that the body (post-frontmatter) contains enough article words (the, an, is, are, was, were) to qualify as prose. If caveman ever starts bleeding into Write calls, this fixture will fail immediately.

── Representative artifact content (generic sample of a PLAN.md `<objective>` section) ──

Phase 2 delivers a JWT-based session authentication system with refresh token rotation, replacing the existing opaque cookie session mechanism. The new system must preserve all current authorization boundaries while introducing short-lived access tokens and rotating refresh tokens stored in an httpOnly cookie.

Purpose: The current session store is a bottleneck at peak load and does not support stateless horizontal scaling. Moving to JWT access tokens allows the API layer to verify requests without a session store round trip. Refresh token rotation provides a defense against token replay attacks, which were flagged in the prior security review as the highest-priority gap in the session model.

Output: An updated authentication middleware that validates signed access tokens, a refresh endpoint that rotates tokens on every call, and a migration path that keeps existing sessions working until the next full deploy window.

The approach introduces a new internal helper that wraps token signing and verification with a pluggable secret rotation strategy. The existing middleware retains its session lookup fallback but now also accepts signed access tokens on a separate header. Regression tests for the fallback path must pass on the pre-refactor code before the refactor begins. This establishes a true baseline that proves the tests are correct rather than merely matching the new implementation.

── End sample ──

What the eval checks: body is parseable, body contains at least 5 article words (the, an, is, are, was, were), suggesting prose rather than caveman fragments. Threshold is deliberately loose — this is a smoke test, not a stylistic judgment. A future v2 rule could tighten with sentence-structure detection.
