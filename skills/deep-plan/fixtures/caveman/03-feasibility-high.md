---
fixture_type: feasibility_high
hard_override: true
rule_version: v2
origin: session-01-finding-I
caveman_mode: full
deep_plan_step: 10
---

# Fixture: Feasibility review output with HIGH finding (v2 signal override)

This fixture represents the output of a feasibility review that contains at least one HIGH-severity finding. When a HIGH finding is present, the v2 signal override forces the entire feasibility section into full prose regardless of the active caveman mode. The rationale is that build-breaking issues demand complete sentences and unambiguous descriptions so the user can evaluate the severity and decide whether to proceed.

-- Representative feasibility review output --

## Feasibility Review -- Phase 18: Extract Auth Middleware

### Finding 1 (HIGH): Missing database migration for token table

The plan proposes storing refresh tokens in a `refresh_tokens` table, but there is no migration step in the implementation units. The existing schema does not have this table. Without the migration, the refresh token endpoint will throw a runtime error on the first request because Prisma will attempt to query a table that does not exist in the database.

**Impact:** The authentication flow will be completely broken on first deploy. Users cannot log in because the token validation path depends on a table that was never created. This is a blocking issue that must be resolved before execution begins.

**Recommendation:** Add a migration unit before Unit 2 that creates the `refresh_tokens` table with columns for `id`, `user_id`, `token_hash`, `expires_at`, and `created_at`. Run `prisma db push` as the verification step to confirm the table exists and is accessible from the application layer.

-- End sample --

The eval script checks that this body contains at least 5 article words (the, an, is, are, was, were), confirming the v2 signal override produced full prose rather than caveman-compressed fragments.
