# CE Subagent Prompts

This file contains the full prompt bodies deep-plan uses to invoke `compound-engineering:research:repo-research-analyst`. Loaded on demand from SKILL.md Step 6.

## Decision: warm-start vs cold-start

Pick warm-start when `gsd_knowledge` block (built in Step 4 from intel/ + research/) is non-empty. Pick cold-start when no GSD intel exists.

## Warm-start prompt body

```
Task compound-engineering:research:repo-research-analyst(
  "Analyze the codebase for Phase {N}: {phase_name}.
  
  Project conventions: read $PROJECT_ROOT/CLAUDE.md before starting research. Apply naming conventions, code style, and project-specific constraints from CLAUDE.md to all findings.
  
  Planning brief: {planning_brief}
  
  ## Already Known (from GSD analysis — do NOT re-research these)
  {gsd_knowledge block from Step 3}
  
  ## What I Need From You (focus tokens here)
  1. Deep code tracing: actual function signatures, data flow, and closures 
     for the seed files — GSD mapped structure but not internals
  2. Integration points: how the files in scope actually connect at runtime 
     (imports, callbacks, event chains, shared state)
  3. Gaps and contradictions: anything the GSD analysis missed or got wrong
     (it may be stale — verify against live code)
  4. Test infrastructure: existing test patterns, frameworks, fixtures 
     relevant to this phase
  5. Risk signals: build/deploy issues, version conflicts, breaking changes
     that GSD's static analysis wouldn't catch
  
  Seed files to examine: {files from code_context}
  
  Do NOT spend tokens on: dependency listing, file tree enumeration, 
  architecture overview, or tech stack identification — these are already known.
  
  Return: code-level findings, integration map, gaps found, test patterns, risks."
)
```

## Cold-start prompt body

```
Task compound-engineering:research:repo-research-analyst(
  "Analyze the codebase for Phase {N}: {phase_name}.
  
  Project conventions: read $PROJECT_ROOT/CLAUDE.md before starting research. Apply naming conventions, code style, and project-specific constraints from CLAUDE.md to all findings.
  
  Planning brief: {planning_brief}
  
  Seed files to examine: {files from code_context}
  
  Focus on:
  1. Current file organization and patterns relevant to this phase
  2. Dependencies and integration points
  3. Existing code that will be modified or extended
  4. Testing infrastructure and conventions
  5. Build/deployment considerations
  
  Return: technology context, architectural patterns, relevant files with line counts,
  risks or gaps not covered in the existing research."
)
```

## Finding confidence tags

Tag each CE finding with a confidence level:

- **HIGH** — verified against live code (file exists, signature confirmed, test ran)
- **MEDIUM** — inferred from patterns (naming conventions, similar code, dependency graph)
- **LOW** — speculative (based on docs, comments, or assumptions not yet verified)

Include all findings regardless of confidence. The rating is informational — it helps the user gauge which findings to trust during execution.

## Merge rules

- New file paths and patterns → add to planning context (with confidence tag)
- Gaps not covered by GSD research → flag as new findings (with confidence tag)
- Contradictions with GSD intel → note for user (intel may be stale)
- Dead dependencies, stale docs, unused code → note as bonus findings

## Post-CE announce templates

- Warm: `{N} findings ({high} high, {med} medium, {low} low) | {gaps} gaps | {risks} risk signals`
- Cold: `{N} relevant files | {M} findings ({high}/{med}/{low}) (Tip: /gsd-scan before planning = faster)`
