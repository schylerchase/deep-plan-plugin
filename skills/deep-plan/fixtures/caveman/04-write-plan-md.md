---
stage: write_plan
deep_plan_step: 8
expected_mode: off
hard_override: true
---

# Fixture: Write PLAN.md (artifact content — HARD override)

── deep-plan [8/11] Writing PLAN.md ──

<objective>
Phase 2 delivers a JWT-based session authentication system with refresh token rotation, replacing the existing opaque cookie session mechanism. The new system must preserve all current authorization boundaries while introducing short-lived access tokens and rotating refresh tokens stored in an httpOnly cookie.

Purpose: The current session store is a bottleneck at peak load and does not support stateless horizontal scaling. Moving to JWT access tokens allows the API layer to verify requests without a session store round trip, and refresh token rotation provides a defense against token replay.

Output: Updated authentication middleware that validates signed access tokens, a refresh endpoint that rotates tokens on every call, and a migration path that keeps existing sessions working until the next full deploy window.
</objective>

# Note: this is artifact content. Caveman MUST stay off here.
