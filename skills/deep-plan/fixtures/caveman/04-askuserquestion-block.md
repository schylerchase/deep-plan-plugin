---
fixture_type: askuserquestion_block
hard_override: true
rule_version: v2
origin: session-01-finding-G
caveman_mode: full
deep_plan_step: 6
---

# Fixture: AskUserQuestion block (v2 signal override)

This fixture represents a user-facing question block where deep-plan asks the user to choose between implementation approaches. The v2 signal override forces the entire question block into full prose so that option labels and descriptions are completely unambiguous. Caveman compression on user-facing choices risks the user selecting an option they do not fully understand.

-- Representative question block --

## Planning Question: Token Storage Strategy

The research phase identified two viable approaches for storing refresh tokens. This choice affects the security model and the operational complexity of the deployment. Both options are feasible, but they differ in infrastructure requirements and failure modes.

**Option A: Database table**
Store refresh tokens in a dedicated PostgreSQL table with automatic expiry via a scheduled cleanup job. This approach is the most conventional and provides a clear audit trail for token lifecycle events. The tradeoff is that every token validation requires a database round trip, which adds approximately 15ms of latency to each authenticated request.

**Option B: Redis with TTL**
Store refresh tokens in Redis with a time-to-live that matches the token expiry window. This avoids the database round trip and the cleanup job entirely, but it introduces Redis as a new infrastructure dependency. If Redis is unavailable, the entire authentication flow fails because there is no fallback storage layer for active tokens.

Which approach do you prefer?

-- End sample --

The eval script checks that this body contains at least 5 article words (the, an, is, are, was, were), confirming the v2 signal override produced full prose for the question block.
