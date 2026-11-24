# Encounter and boss audit: what Claude must inventory before adding content

**Status:** audit specification. Figures below are *reported from prior read-only repository inspection* and must be verified against the current checked-out HEAD. No local Godot playthrough or full art/audio asset inventory was available in the handoff environment.

## Preliminary snapshot to VERIFY

- Prior public-source inspection found `bosses.json` with **13 named bosses + 13 minibosses** (26 definitions); **8 boss/miniboss pairs reportedly associated with Functions**, and one each for Number/Algebra, Geometry, Statistics, Calculus and Thunderdome. These are **definitions**, not evidence of 26 voiced, illustrated, distinct encounters.
- Existing ordinary enemy roles were described as five tiers (Scavenger through Overseer).
- Existing journey reportedly distinguished Explore/Puzzle/Combat presentation but shared similar question/consequence mechanisms.
- Current repeated 'mile' arrangement reportedly places a miniboss near encounter 5 and boss near encounter 10. **Verify actual code/data and do not assume these milestones equal one-time region completion.**

Do not rely on these figures if the repository has changed. Validate with source paths/line references, counts grouped by ID/zone, game runtime tests, and visual/audio inventory.

## Required deliverable: one evidence-backed inventory table

Create/maintain `docs/implementation/ENCOUNTER-INVENTORY-LIVE.md` (in the real repo) with **one row per actual content definition**, columns:

| ID | Category | Location / maths topic | Existing asset and style QA | Encounter phases / mechanics | Dialogue / voice status | Math/question tags and eligibility | Referenced in runnable Godot scene? | Tests/playtested? | Status |
|---|---|---|---|---|---|---|---|---|---|

Category must distinguish at least: ordinary adversary, creature/robot, environmental/repair obstacle, miniboss, regional narrative villain, repeatable raider villain, Thunderdome native boss, Thunderdome unlocked appearance. The same *character asset* may have multiple content roles; don't double-count it as a unique person.

Use completion statuses: `idea`, `defined`, `assets`, `voiced-if-needed`, `wired`, `tested`, `polished`. 'Voiced-if-needed' can be N/A for non-speaking hazards.

## Criteria for 'enough' bosses (not a raw count)

- Each of five AA SL zones has a **credible narrative arc and climactic encounter**, including required narrative state flags and a satisfying payoff.
- Repeated ordinary encounters feel varied through **objectives**, creatures/robots/environments, mechanics and question structures, not recolored copies of the same one-dimensional attack.
- Miniboss and boss roles are explicitly mapped to the existing mile structure and **not mistaken** for the regional story-ending milestone.
- There are several non-human / non-voiced high-stakes encounters; speaking villains are used sparingly, with consistent personalities.
- The shared encounter engine can render at least one combat example, one survival/repair example and one multi-phase example before multiplying content.
- Thunderdome has a baseline general roster and can optionally draw previously defeated region villains, without locking basic Thunderdome maths.
- Content is mathematically validated, appropriately leveled and course-filtered. A beautiful enemy without correct usable questions is **not finished**.
- Visual/sound consistency is checked across all five zones, including age-appropriate humor and readability on web/mobile.

## Suggested writer-facing content card (not mandatory format)

For each proposed major encounter, document:

- **Role:** region story beat / generic encounter / miniboss / hazard / arena / repeatable raider
- **Narrative reason:** why students should care; if villain, why defeating them feels good
- **Visual and sound assets needed:** art reuse vs newly required, VO only if essential
- **Objective and phases:** survive, repair, defeat, escape, disarm, etc.
- **Eligible skills:** stable skill IDs, selected course/pool, structural variety, difficulty progression
- **Mechanics:** existing tags/modifiers/statuses, or clearly flagged request for an unapproved new mechanic
- **State transitions:** prerequisites, flags, fail-forward, success, escapes, save/resume, unlocked Thunderdome roster
- **QA:** deterministic behavior, mathematical checks, accessibility, voice/tone/asset review

## Implementation order for variety

1. Inventory the actual game and remove documentation/count ambiguity.
2. Implement/refactor **one shared encounter contract** within existing architecture.
3. Demonstrate one villain combat, one environmental/repair event, one multi-phase event end to end.
4. Get the owner to approve first-region narrative arc and what triggers its final showdown.
5. Expand *approved* content across remaining AA SL regions, prioritizing missing content types and art/audio polish, not simply boss count.
6. Add unlocked defeated-region villain appearances to Thunderdome when the event registry and arena director are verified.

## Core warning

**Do not order new voice lines or generate twenty more villains as a response to a content count.** The owner's priority is a coherent, reusable game with enough diversity and mathematical practice. The writer supplies character and environmental creativity only after it is grounded in approved encounter capabilities.
