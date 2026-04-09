---
name: frontend-design
description: 'UX-first frontend design for any web work — pages, apps, dashboards, components. Enforces state design, accessibility, interaction quality, and information architecture before aesthetics. Detects existing design systems. Evaluates and identifies bad UI/UX. Use for both creating new interfaces and reviewing existing ones.'
---

# Frontend Design — UX First

Build frontend interfaces where usability, state completeness, and accessibility come before visual styling. This skill inverts the typical AI approach: instead of starting with fonts and colors, start with "does it actually work for the user?"

## Authority Hierarchy

1. **Existing design system / codebase patterns** — highest priority
2. **User's explicit instructions** — override skill defaults
3. **This skill's guidance** — applies in greenfield or when user asks for design help

Every rule here is a default. Existing codebases and user instructions override.

---

## Phase 0: Context & Questions

Before writing any code, understand what you're building and for whom.

### Detect Existing Design System

Scan the codebase for design signals using file-search and content-search tools:

- **Design tokens**: `--color-*`, `--spacing-*`, `--font-*` custom properties, theme files
- **Component libraries**: shadcn/ui, Material UI, Chakra, Ant Design, Radix, or project-specific components
- **CSS frameworks**: `tailwind.config.*`, styled-components themes, Bootstrap, CSS modules
- **Typography**: font imports, `@font-face`, Google Fonts links
- **Color palette**: color scales, brand files, token exports
- **Spacing/layout**: consistent scale usage, grid systems, layout components

**Mode classification:**
- **Existing system** (4+ signals): defer to it for aesthetics. Structural guidance still applies.
- **Partial** (1-3 signals): follow what exists, apply defaults where gaps exist.
- **Greenfield** (0 signals): full skill guidance applies.
- **Ambiguous**: ask the user before proceeding.

### Ask Before Building

These questions prevent wasted work and expose missing requirements. Ask the ones relevant to the scope — not all apply to every task.

**Users & Tasks:**
- Who uses this? What are their top 3 tasks here?
- Is this for novice users, power users, or both?
- What devices and screen sizes must this work on?

**States & Edge Cases:**
- What states does this feature have? (Enumerate: empty, loading, populated, error, partial)
- What happens on first use? (empty state)
- What happens if it fails? (error state with recovery)
- What happens at extremes? (0 items, 10,000 items, very long text, missing data)
- What happens offline or on slow connections?

**Complexity Assessment:**
- Is this a one-time action or a repeated workflow?
- How many fields? Are there dependencies between them?
- Is the action reversible? Does it have side effects? (sending email, charging money, deleting data)
- Will the dataset grow? What does the UI look like at 10 items vs 10,000?
- Do multiple user roles see different things?

When context is ambiguous, ask the user directly. If no question mechanism is available, assume conservative defaults and note assumptions.

---

## Phase 1: Information Architecture

Decide WHAT goes where BEFORE deciding how it looks. Structure drives usability more than styling ever will.

### Content Hierarchy

Identify what is primary (the user's main task), secondary (supporting context), and tertiary (rarely needed). Apply the squint test: blur the page mentally — can you still tell what matters most?

### Navigation Pattern Selection

| Pattern | Use When |
|---------|----------|
| **Top nav** | < 5 items, content-focused, marketing sites |
| **Sidebar** | 5-10+ items, deep hierarchy, SaaS/enterprise, navigation will grow |
| **Bottom tab bar** | Mobile only, 3-5 primary actions, thumb-friendly |
| **Hybrid (top + sidebar)** | Complex apps — top for global context, sidebar for section nav |

### Scanning Pattern

| Pattern | Page Type | Approach |
|---------|-----------|----------|
| **F-pattern** | Text-heavy (docs, articles, blogs) | Key info in first two paragraphs, strong left-aligned headings |
| **Z-pattern** | Conversion-focused (landing, sign-up) | Logo top-left, CTA top-right, supporting content diagonal, primary action bottom-right |
| **Layered/Spotted** | Data-rich (dashboards, results) | Clear visual anchors (numbers, icons, bold text) users jump between |

### Component Selection

**Data display — table vs list vs card:**

| Pattern | Use When |
|---------|----------|
| **Table** | Comparing values across columns, sorting/filtering needed, bulk operations, structured data |
| **List** | Scanning sequentially, search results, messages — 1-2 attributes matter most |
| **Card grid** | Visual content drives decisions (images, thumbnails), heterogeneous data per item |

When unsure, start with list view. Add table when column comparison is the job. Add cards when visuals do the deciding.

**Containers — modal vs drawer vs inline:**

| Pattern | Use When | Avoid When |
|---------|----------|------------|
| **Modal** | Destructive action confirmation, focused task needing attention, multi-step workflow | User needs to reference content behind it |
| **Drawer** | Sub-task too complex for modal but not a full page, property panels, filtering | Simple confirmations (use modal) |
| **Inline expansion** | Small edits, revealing row details, tooltips, progressive disclosure | Complex multi-field forms |
| **Full page** | Primary workflow, complex multi-step, content deserving full attention | Quick actions, supplementary tasks |

**Selection controls — radio vs dropdown vs checkbox vs toggle:**

| Control | Use When |
|---------|----------|
| **Radio buttons** | Mutually exclusive, 2-6 options, user must pick one. All visible. Pre-select the most common. |
| **Dropdown** | Mutually exclusive, 7+ options, or space-constrained. Options hidden until clicked. |
| **Checkboxes** | Multiple selections allowed (0 to many), or a single yes/no. Each independent. |
| **Toggle** | Binary on/off with immediate effect. No save button — takes effect instantly. |
| **Segmented control** | 2-5 mutually exclusive view modes (list/grid, day/week/month). Equal weight. |

### Cognitive Load (Hick's Law)

Decision time increases logarithmically with the number of choices. Reduce visible options to reduce paralysis:

- Cap visible items at 5-7 per group. Use progressive disclosure or grouping beyond that.
- Primary action must be visually dominant. Secondary actions visually subordinate.
- When presenting many options (e.g., settings), group by category with collapsible sections.
- Avoid presenting all configuration at once — surface defaults, hide advanced options.
- For navigation: prefer shallow-and-wide (more top-level items) over deep-and-narrow (many click layers), but still cap top-level items at 5-7.

### Progressive Disclosure

Show minimum necessary information at each level. Reveal detail on demand. Use for: settings, advanced options, metadata, secondary actions.

Critical rule: progressive disclosure does NOT fix bad information architecture. If crucial information requires excessive drilling, the hierarchy itself is wrong.

---

## Phase 2: State Design — MANDATORY

This is not optional. Every data-driven screen must have ALL of these states designed before development starts. This is the single biggest differentiator between professional and amateur frontend work.

### The Five Mandatory States

**1. Empty state** — first use, no data yet.
- MUST include clear messaging explaining what normally appears here
- MUST include an actionable CTA ("Create your first project", "Upload a file")
- NEVER show a blank screen or generic "No items found" without context
- Use context-aware visuals (empty contact list shows person outline, not a generic icon)

**2. Loading state** — data being fetched or action in progress.
- Use **skeleton screens** for known content layouts (feeds, tables, cards, dashboards)
- Use **spinners** for short discrete actions (saving, authenticating, processing)
- Use **progress bars** for deterministic operations where completion % is known
- NEVER use skeletons for: toasts, dropdowns, modals, or action components (buttons, checkboxes)
- Optimistic UI for frequent actions: update immediately, revert on failure

**3. Populated state** — the happy path with real data.
- Test with realistic data volumes, not lorem ipsum
- Test with edge-case content: very long names, non-Latin characters, missing optional fields
- Consider both sparse (3 items) and dense (300 items) states

**4. Error state** — something failed.
- Plain language explaining what happened — not "Error 500" or "Something went wrong"
- Concrete recovery action: retry button, link to support, alternative path
- Preserve user input — NEVER clear what the user typed
- Use appropriate pattern:
  - **Inline** (next to field): form validation errors
  - **Banner** (page-level): system errors, auth failures, connectivity loss
  - **Toast**: low-priority confirmations, non-critical transient feedback
- NEVER use timed-dismissal toasts for critical errors

**5. Partial/degraded state** — some data loaded, some failed.
- Show what you have, indicate what is missing
- Offer retry for failed sections without refreshing the whole page
- Consider offline/slow-connection behavior

### Interactive Element States

Every interactive element (button, link, input, card) must handle:

| State | Required |
|-------|----------|
| Default | Yes — resting appearance |
| Hover | Yes — indicates interactivity on pointer devices |
| Focus | Yes — visible focus ring for keyboard navigation |
| Active/Pressed | Yes — feedback that the element responded |
| Disabled | When applicable — visually distinct, NOT just reduced opacity alone |
| Loading | When applicable — spinner or text change, button disabled to prevent double-submit |
| Error | When applicable — clear error indication with recovery |

### Form Validation

- **Inline validation on blur** (after user leaves field) — NOT on every keystroke
- Error messages directly adjacent to the field, not collected at page top
- Error messages in plain language: "Enter a valid email (e.g., you@example.com)" not "Invalid input"
- Use color AND icon together — never color alone (fails for colorblind users)
- Mark required fields with asterisk (*); label optional fields explicitly as "optional"
- Preserve all user input on error — never clear fields
- Remove error message as soon as input is corrected
- Multi-step forms: progress indicator mandatory, backward navigation without data loss

---

## Phase 3: Interaction Design

How the interface responds to the user. Every action must produce a visible result.

### Feedback Timing

| Delay | User Perception | Required Response |
|-------|-----------------|-------------------|
| < 100ms | Instantaneous | Button press state, toggle flip |
| 100ms - 1s | Noticeable but okay | Loading indicator optional, state change visible |
| 1s - 10s | Needs explicit feedback | Spinner, skeleton, progress bar |
| > 10s | Risk of abandonment | Progress bar with estimate, ability to cancel |

### Affordances

- Buttons MUST look like buttons: visible boundary, contrast from background, hover/press states
- Links MUST be distinguishable from body text: underline, distinct color, or both
- Clickable cards need a hover state or visual cue
- Ghost/outline buttons have low affordance — use only for secondary actions
- Disabled states must be clearly different from enabled (reduced opacity alone is insufficient)
- Clickable area must match visible element — no invisible hit targets extending beyond the visible button

### Concrete Interaction Rules

These come from industry-standard interface guidelines and prevent common implementation failures:

- Inputs MUST be wrapped in a `<form>` element so Enter key submits
- Input labels MUST be clickable and focus the input
- Inputs MUST use appropriate `type` attribute (email, tel, password, url, number)
- Toggles take effect immediately — no separate save button
- Buttons MUST disable after submission to prevent duplicate requests
- Icon-only interactive elements MUST have an explicit `aria-label`
- Interactive elements should disable `user-select` on inner content
- Focusable elements in lists should be navigable with arrow keys
- Destructive actions require confirmation before execution
- Irreversible actions need stronger confirmation (type-to-confirm for deleting accounts, etc.)

### Target Sizing

- **Mobile**: 44px minimum touch target (Apple HIG). 48px recommended (Material Design).
- **Desktop**: 24px minimum pointer target (WCAG 2.2 AA).
- Space between adjacent targets: at least 8px to prevent mis-taps.
- Edges/corners of screens are effectively infinite-size targets — exploit this for key actions.

### Responsive Design

Not "make it work on mobile" — design for every viewport intentionally.

**Breakpoints to verify:**
- 320px — smallest mobile (ensure no horizontal scroll)
- 375px — standard phone
- 768px — tablet portrait
- 1024px — tablet landscape / small laptop
- 1280px+ — desktop

**Common mobile failures to prevent:**
- Hover-only interactions with no touch alternative (dropdowns that only open on hover)
- Touch targets under 44px (buttons, links, icon actions)
- Fixed/sticky headers covering focused elements after scroll
- Text input fields breaking when software keyboard opens
- Heavy animations that degrade on mobile hardware
- Same large images served to mobile as desktop (use `srcset` or responsive images)
- Missing viewport meta tag: `<meta name="viewport" content="width=device-width, initial-scale=1">`

**Navigation adaptation:**
- Desktop: full horizontal nav or persistent sidebar
- Tablet: collapsible sidebar or compact horizontal nav
- Mobile: bottom tab bar (3-5 items, thumb-friendly) or hamburger menu

**WCAG 2.2 reflow requirement:** At 400% zoom (or 320px width), all content must reflow into a single column without horizontal scrolling. Exceptions: data tables, toolbars, maps.

---

## Phase 4: Accessibility — Not Optional

Accessibility is a core design constraint, not an add-on. Build it in from the start.

### Semantic HTML

Use the right element for the job — not divs for everything:

| Element | Use For |
|---------|---------|
| `<nav>` | Navigation sections |
| `<main>` | Primary page content |
| `<section>` | Thematic grouping with a heading |
| `<article>` | Self-contained content |
| `<button>` | Clickable actions (not `<div onclick>`) |
| `<a>` | Navigation to another page/section |
| `<form>` | Wrapping inputs that submit together |
| `<label>` | Form input labels (with `for` attribute) |

### Color and Contrast

- Text contrast: 4.5:1 minimum (WCAG AA). Aim for 7:1 for body text.
- Large text (18px+ bold or 24px+ regular): 3:1 minimum.
- UI components and graphics: 3:1 against adjacent colors.
- NEVER use color as the sole indicator of meaning — always pair with icon, text, or pattern.
- Test contrast in both light AND dark modes if both are supported.

### Focus Management

- Every interactive element MUST have a visible focus indicator.
- Focus indicator: at least 2px thick, 3:1 contrast between focused and unfocused state.
- NEVER remove focus outlines without replacing them with a custom visible focus style.
- Focused elements must NOT be obscured by sticky headers, cookie banners, or overlays.
- Tab order must follow visual reading order.
- When opening modals/drawers, move focus to the new content. On close, return focus to the trigger.

### Additional Requirements

- **Keyboard operability**: every flow completable via keyboard alone.
- **Heading hierarchy**: h1-h6 must reflect visual hierarchy. If it looks like a heading, tag it as one.
- **Image alt text**: descriptive for content images, empty `alt=""` for decorative.
- **Form labels**: every input must have an associated `<label>`, not just visual proximity.
- **Reduced motion**: respect `prefers-reduced-motion`. Replace motion-heavy animations with fade/opacity alternatives. Do NOT globally disable all animation.
- **Text resize**: content must work at 200% text zoom without loss of functionality.
- **Drag alternatives**: any drag interaction must also work via click/tap (WCAG 2.2).
- **Accessible authentication**: login must not require cognitive tests. Support password managers, passkeys, copy-paste in auth fields (WCAG 2.2).
- **Redundant entry**: don't ask for the same information twice in the same flow. Auto-fill shipping from billing, remember previously entered data (WCAG 2.2).
- **Consistent help**: help mechanisms (links, buttons, chat) must appear in the same relative location across all pages (WCAG 2.2).

---

## Phase 5: Visual Design

NOW — after usability, states, interaction, and accessibility are solid — make it look intentional and cohesive.

### Typography

- Choose readable fonts appropriate to context. If the project has existing fonts, use them.
- Two typefaces maximum: one for headings, one for body.
- Establish a type scale and use it consistently (don't ad-hoc font sizes).
- Ensure sufficient line-height for readability (1.4-1.6 for body text).

### Color

- Commit to a cohesive palette. Use CSS variables for consistency.
- One dominant brand color with a sharp accent for primary actions.
- Avoid multiple competing accent colors.
- Ensure palette works across all states (error red, success green, warning amber should not clash with brand colors).
- Light/dark mode: design both intentionally if supported, not just color-invert.

### Composition

- Start with composition, not components. Treat the first viewport as a hierarchy statement.
- Use whitespace, alignment, scale, and contrast to establish hierarchy BEFORE adding visual chrome (borders, shadows, cards).
- Cards are containers for user interaction (clickable, draggable, selectable). If removing the card styling doesn't hurt comprehension, it shouldn't be a card.
- Consistent spacing scale (4px or 8px base). Do not ad-hoc spacing values.

### Motion

- Purpose: guide attention, show relationships, provide feedback. Not decoration.
- Animate only `transform` and `opacity` — they run on GPU without triggering layout/paint.
- NEVER animate `width`, `height`, `top`, `left`, `margin`, `padding` — they trigger expensive layout recalculation.
- Use the project's existing animation approach if one exists.
- When no existing approach: CSS transitions/animations are the universal baseline. Reach for a library only when CSS cannot achieve the behavior.
- Respect `prefers-reduced-motion` (see Phase 4).
- Test on low-end devices, not just your development machine.

### Avoiding AI Slop

AI-generated frontends converge on statistical defaults. Actively avoid these in greenfield work:

**Aesthetic convergence defaults to break from:**
- Generic SaaS card grids as first impression
- Purple-to-blue gradients on white backgrounds
- Overused fonts (Inter, Roboto, Poppins, Arial) when building something distinctive
- Identical shadow treatment on every element
- Centered-everything layouts with no spatial tension
- Hero > three feature cards > testimonials > pricing > CTA (the template)
- Decorative gradients or abstract backgrounds standing in for real content

**Copy convergence defaults to break from:**
- "Empowering Your Journey" / "Seamless Integration" / "Unlock Your Potential"
- Headlines that sound like design commentary instead of product language
- Every section repeating the same mood statement in different words
- Marketing voice in utility UI (dashboard headings should say "Plan status" not "Unlock Your Potential")

The goal is intentionality, not novelty for its own sake. A calm, minimal design is not AI slop if it's a deliberate choice executed with precision.

---

## Phase 6: Performance as UX

Users perceive performance as part of the design. A beautiful interface that takes 5 seconds to load feels broken.

### Perceived Performance

- **Skeleton screens** make pages feel 20-30% faster than spinners for the same actual load time. Use them.
- **Optimistic UI** for frequent actions: update the interface immediately, revert only on failure.
- **Above-the-fold priority**: the main visible content must render first. Defer everything below the fold.
- Generic loading spinners for content loading are an anti-pattern. Reserve spinners for discrete actions only.

### Image Loading

- **Above-fold images**: load eagerly, never lazy-load.
- **Below-fold images**: use `loading="lazy"` attribute.
- **Responsive images**: use `srcset` to serve device-appropriate sizes. Don't send desktop-sized images to mobile.
- **Modern formats**: prefer WebP or AVIF where supported, with fallback.
- **Placeholders**: use low-quality image placeholders (LQIP) — blurred thumbnails that give users color/shape context while the full image loads.

### Animation Performance

- Animate ONLY `transform` and `opacity` — GPU-composited, no layout/paint cost.
- NEVER animate `width`, `height`, `top`, `left`, `margin`, `padding`.
- Use `will-change` sparingly — only on elements about to animate, not globally.
- Test animation smoothness on low-end mobile devices, not just development machines.
- CSS transitions > JS animation libraries for simple transitions (less main-thread work).

---

## Frontend Security Basics

AI-generated frontend code introduces security vulnerabilities at a high rate. Prevent these critical issues.

- **XSS prevention**: never insert user content into the DOM via raw HTML injection methods (innerHTML, framework-specific raw HTML directives). Use text content APIs or a sanitization library like DOMPurify.
- **Input validation**: validate on the server. Client-side validation is UX convenience, not security.
- **URL handling**: never construct URLs from user input without validation. Sanitize href attributes to prevent javascript: protocol injection.
- **Secrets**: never expose API keys, tokens, or credentials in client-side code or public environment variables.
- **Third-party scripts**: audit any external scripts. Every external script tag is a trust boundary.
- **Form CSRF**: ensure forms use CSRF tokens or same-site cookie policies when submitting to your backend.

---

## Red Flags Checklist — Evaluating UI/UX

Use this to review designs — your own or existing ones. Organized by severity.

### Critical (Fix immediately)

- [ ] No loading state — blank screen while data fetches
- [ ] No error state — or generic "Something went wrong" with no recovery
- [ ] No empty state — blank area with no guidance
- [ ] Form with no validation feedback — submit, reload, no indication of problem
- [ ] Interactive element without focus state — invisible to keyboard users
- [ ] Color as sole meaning indicator — red/green with no icon or text backup
- [ ] Touch targets under 44px on mobile
- [ ] Text unreadable over background (contrast failure)
- [ ] Prompt language or AI commentary visible in the UI
- [ ] Button that allows double-submission (no disable after click)
- [ ] User-generated content rendered as raw HTML without sanitization (XSS risk)
- [ ] Hover-only interaction with no touch/keyboard alternative

### Warning (Should fix)

- [ ] Button looks like a link, or link looks like a button (affordance violation)
- [ ] Modal that traps focus incorrectly — can't Tab through, can't Escape to close
- [ ] Toast/notification that disappears before user can read it (< 4 seconds)
- [ ] Navigation doesn't show current location — user doesn't know where they are
- [ ] Table with 100+ rows and no sort, filter, or search
- [ ] Toggle that requires a separate "Save" button instead of taking immediate effect
- [ ] Horizontal scrolling on mobile with no indication of hidden content
- [ ] Validation fires on focus instead of blur — tells user they're wrong before they type
- [ ] Required fields not visually distinguished from optional
- [ ] Inputs not wrapped in `<form>` — Enter key doesn't submit
- [ ] Cognitive overload — too many options, actions, or competing elements on one screen
- [ ] Stale UI state — data changed server-side but interface doesn't reflect it without manual refresh

### Minor (Improve when possible)

- [ ] Inconsistent spacing, font sizes, or border radius across the page
- [ ] Multiple competing accent colors
- [ ] Heading levels (h1-h6) don't match visual hierarchy
- [ ] Inconsistent date/number/currency formatting
- [ ] Truncated text with no way to see full content
- [ ] Decorative images without empty `alt=""`
- [ ] Disabled state using only reduced opacity (insufficient visual distinction)
- [ ] More than 3 clicks to complete a primary task
- [ ] Section headings that don't allow scanning (vague labels)
- [ ] Copy that sounds like a prompt instead of a product

---

## Visual Verification

After implementing, verify visually. One pass — a sanity check, not pixel-perfect review.

### Tool Preference

Use the first available option:
1. **Existing project browser tooling** — Playwright, Puppeteer, Cypress if already in the project
2. **Browser MCP tools** — if browser automation is available in the environment
3. **Mental review** — apply the Red Flags Checklist above as a self-review

Do NOT introduce new dependencies solely for verification.

### What to Check

- Does every screen have all five states designed? (empty, loading, populated, error, partial)
- Do interactive elements look interactive and respond to interaction?
- Is the information hierarchy clear from a 2-second glance?
- Can the core task be completed without instructions?
- Does it work at 320px viewport width without horizontal scroll?
- Are all focus states visible?

One iteration. Fix glaring issues. Move on.
