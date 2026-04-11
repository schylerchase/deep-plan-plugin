---
stage: build_planning_brief
deep_plan_step: 4
expected_mode: lite
hard_override: false
---

# Fixture: Build Planning Brief (synthesis needs nuance)

── deep-plan [4/11] Building planning brief ──
Phase 02 delivers JWT-based session auth with refresh rotation, replacing current opaque cookie sessions. Scope bounded to server-side token issuance and validation — client storage stays out of this phase per deferred section in CONTEXT.md.
Locked decisions: jose library over jsonwebtoken, 15-minute access TTL, 7-day refresh TTL, rotation on every refresh. Open question from Claude's Discretion: should revoked refresh tokens trigger session-wide invalidation or just the specific token chain.
Seed files identified: src/auth/session.ts, src/middleware/authorize.ts, src/routes/login.ts plus the existing passport strategy config. Research needs to trace how current session cookie is consumed downstream before we can safely cut it over.
