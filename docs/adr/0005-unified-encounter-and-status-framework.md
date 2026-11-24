# ADR-0005: One encounter framework for combat, hazards and repairs

- Status: **Accepted architecture and behaviors; values, effects list and UI details OPEN**
- Decision date: 2026-11-21 (owner grilling session, continued after original audit)
- Depends on: ADR-0002 (questions/mastery), ADR-0003 (runs), ADR-0004 (characters/economy)

## Context

Wasteland Academy must give students varied reasons to solve mathematics without building a bespoke Godot implementation for each new enemy, trap, vehicle or survival situation. The owner wants robots, wasteland raiders, mutated desert creatures, mechanical traps, sandstorms, vehicle repairs and dramatic multi-phase adversaries. The gameplay remains mathematical questions + consequences + narrative feedback; it must not become a second, unrelated combat game.

## Accepted decisions

1. **One reusable encounter runtime** handles combat, survival, repair, disarming, escape and other objectives. Encounters may differ in objective, pacing, presentation, phases, rewards and consequences, but all draw eligible mathematics through the same `MathsEngine` boundary.
2. **Separate encounter presentation from mechanics.** An encounter definition may refer to an enemy/obstacle's tags, art, voice/sound, objectives, mathematical constraints, phases, status effects and narrative triggers. A new scorpion or sandstorm should normally be authorable as data/configuration once the relevant mechanic already exists.
3. **Question outcomes drive encounter outcomes:** an answer can advance the objective, deal damage, prevent a hazard, incur damage/setbacks, apply effects, and update mastery according to the common rules. Wrong mathematics cannot be treated as merely decorative combat feedback.
4. **Reusable tags and modifiers** can distinguish e.g. `creature`, `robot`, `raider`, `armored`, `venomous`, `vehicle`, `hazard`, `repair`. Class abilities and equipment can affect subsets of encounter types (e.g. creature resistance or armor damage) without duplicating question logic. **Exact tags and mechanics are design proposals to validate against existing code, not a mandatory new schema or list.**
5. **Run-persistent status effects:** once acquired, relevant conditions persist across encounters for that run until cured or naturally recovered. Their tick/recovery opportunity is **after each mathematical question**, regardless of whether the question was answered correctly.
6. Most statuses **may stack**, with a configurable maximum and potentially high cap; some conditions are inherently **non-stackable** states (e.g. dazed). Stacking rules are declared per effect, not global. Multiple exposures can increase severity.
7. Each eligible effect may have a probability of natural recovery; specific treatment items or class perks may cure, mitigate, resist or shorten it. This prevents a bad first encounter from guaranteeing a miserable entire run. Probabilities, caps, timing and ordering are unresolved tuning.
8. **Some effects may change question conditions** (timer speed/time remaining, eligibility of assists, or potential challenge adjustments). That is allowed, but must be explicit, bounded, communicated to the player and accounted for in score/mastery evidence. Do not silently change a student's persistent skill mastery based on a gameplay debuff.
9. General-purpose **modifier dials** may include question time, question difficulty policy, hint/solution-step availability, damage dealt/received, shields, status chance/duration/recovery, rewards and encounter odds. Items, class skills, enemy types and statuses should reuse those dials where compatible.
10. The owner rejected introducing a new **shared stash vs limited run inventory vs quick-bar** architecture at this stage. **Keep the existing inventory model unless a concrete defect needs an owner-reviewed change.** Raider Attention is the already-approved pressure against conspicuous excessive item use.

## Encounter roles (glossary, not separate code paths)

- **Ordinary encounter:** an enemy, creature, scavenging scene, obstacle, repair or trap using one or several questions.
- **Major non-villain encounter:** a memorable challenge such as surviving a sandstorm or repairing a collapsing vehicle; no requirement for dialogue or a human antagonist.
- **Miniboss:** a more demanding encounter, potentially themed or multi-step, but not necessarily an actor with a voice.
- **Villain boss:** a story antagonist with personality, persistent consequences and a satisfying showdown; see ADR-0006.
- **Raider boss:** a repeatable risk/reward encounter triggered probabilistically by Raider Attention; defeating it clears attention and it escapes or returns narratively. See ADR-0004.

## Explicitly proposed, not accepted as deliverables

Examples worth prototyping *after framework confirmation*: mutated scorpions/sandworms/giant insects, mech armor phase then exposed pilot, drivable vehicle-as-shield, poison stacking from 10 to 20 damage, sandstorm shelter-building, Rage Serum that increases question difficulty and mutual damage, raider convoy chase, dazed timer penalty. These are **ideas for using shared mechanisms**, not individually authorized backlog issues. **Do not instantiate all these characters, items or hazards just because they appear here.**

## Critical invariants

- Only one active run, fixed player character during that run; all existing save/resume requirements apply to statuses, phase state, encountered events, cooldowns and modifiers.
- Status effects tick once per *resolved question* (define interruption, retries and timeouts explicitly), not per render frame or UI click.
- Mathematical assists affect evidence and performance bonus; combat-only buffs do not automatically apply mathematical penalties.
- Question eligibility remains hard-filtered by selected IB course, even when a status or item raises the nominal difficulty.
- An encounter never relies on new question types not yet supported by the common maths engine; it must degrade gracefully or be excluded from the content registry.
- New mechanics require owner approval under ADR-0001. Adding another approved encounter *using existing mechanics* may proceed within agreed content bounds.

## Implementation review and tests

1. Inspect existing `run`, `fight`, `dungeon`, `modifiers`, question interface and save data. Prefer an adapter/refactor over a new engine where possible.
2. Produce an implementation proposal for a generic encounter definition, state machine and phase transitions, with ownership of question selection and scoring unambiguous.
3. Implement a small representative **vertical slice**: a current humanoid fight, a non-antagonist hazard/repair, and a multi-phase encounter, all through the same core machinery. Reuse existing assets where possible.
4. Unit/scenario tests for tick timing, stack caps, non-stackable conditions, cures/recovery, class resistance, save/restore, simultaneous effects, timer modification, consistent question/mastery results, and non-combat objectives.
5. Check touch UX and accessibility: timers must be readable and avoid unwinnable chains; status display should be comprehensible without clutter.

## Consequences

The content team can build varied wasteland situations with less custom code and voice work. The first task is to **audit and reuse the existing journey/combat system**, not to ship a brand-new subsystem automatically. Hard numerical tuning and final encounters require owner-approved review.
