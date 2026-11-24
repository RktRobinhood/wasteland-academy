# Conceptual encounter contracts - for Claude's design review, NOT prescriptive code

**Status: PROPOSED technical decomposition to test against actual Godot code.** Do not create these specific classes, fields, files or migrations merely because they are named here. Reuse the existing `Dungeon`, `Run`, `Modifiers`, `MathsEngine`, question selection and save structures wherever possible.

## Responsibilities

| Responsibility | Produces / owns | Must not own |
|---|---|---|
| Question generation | Valid prompts, solutions, marking, tagged skills, structure, difficulty, compatibility | Enemy art, boss flags, reward schedule |
| Mastery updater | Skill-level weighted evidence and current proficiency | Boss victory or XP triggers |
| Question selector | Course eligibility, question variety, difficulty by mode, Thunderdome probability weights | UI storytelling and encounter victory flags |
| Encounter runtime | Current objective, state, phases, HP, effects, question result consequences | Independent maths solver |
| Status/modifiers | Timed/run-persistent effects, composable damage/timer/assist changes | Separate bespoke enemy implementations |
| Narrative director | Flag-based story eligibility, encounter variants, completion and arena-roster unlock | Direct editing of mastery levels |
| Reward/score manager | Score/PB, XP, earned Scrap, account-wide accolades, shop economy | Deciding mathematical correctness |
| Save/resume | Versioned snapshots of all persistent and active-run state | Inventing a new active run after pause |

## Pseudocode for one resolved question (illustrative ordering only)

```
question = selector.choose(course, skill_evidence, run_mode, encounter_constraints)
result = maths_engine.mark(question, learner_answer)
math_evidence = mastery.record(result, question, assist_history)
encounter_outcome = encounter.apply(result, active_modifiers)
status_outcome = statuses.tick_after_resolved_question()
rewards = reward_system.apply_verified_outcomes(result, encounter_outcome, math_evidence)
state = save_checkpoint(run, encounter, narrative_flags, statuses, inventory, rewards)
```

Ordering between status damage, defeat, cure and reward settlement is **unresolved**. Claude must propose and test it instead of copying this pseudocode literally.

## Authorable encounter data - capabilities, not schema

- Stable ID, encounter role, assigned locations/eligibility, optional art/voice references
- Type tags and status resistances (only from approved vocabulary)
- Mathematical skills/difficulty/structure and format capability requirements
- Objective and phases, with transitions on answers, HP, timer, flag triggers or setbacks
- Modifiers, stack policies, effect lifetimes and recovery checks
- Narrative conditions and outcomes (boss escapes, phase bypass, region victory, Thunderdome eligible pool)
- Rewards and safe persistence boundaries, with clear one-time vs repeatable flags

## Do not overbuild

Do **not** introduce a full general-purpose scripting language, procedural story generator, cloud content service, modular inventory overhaul or separate maths engine to achieve this. Verify whether existing Godot resources, JSON data and enums can express three representative examples. Only propose additional primitives when a demonstrated test case fails.
