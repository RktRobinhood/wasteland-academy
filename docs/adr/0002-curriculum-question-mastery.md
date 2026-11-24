# ADR-0002: One syllabus-filtered question engine and seven-level skill mastery

- Status: **Accepted principles; numerical calibration OPEN**, 2026-11-21
- Scope: all gameplay modes and the four IB courses

## Context

The existing Godot `MathsEngine` exposes curriculum filtering, generation, marking, worked solutions and evidence; the catalogue maps official syllabus entries to granular skill IDs. The current evidence mostly records correctness counts per generated cell. The owner requires adaptive skill proficiency, not just percent accuracy. `question difficulty` is 0-5, but displayed mastery should be 1-7.

## Decision

1. All game modes use **one** maths/question engine, one coherent skill identity system and one mastery record. Selected IB course is a **hard eligibility filter**, not a difficulty preference. Course switching remains in Player Settings; overlapping skill mastery carries over.
2. The engine conceptually separates **generation** (valid instances and solutions), **learning evidence/mastery** (skill-level confidence), and **adaptive selection** (what the player sees). Put the new mastery and selection logic behind explicit, testable interfaces, keeping combat-specific code outside the maths boundary.
3. Question coverage demands syllabus-appropriate **structural breadth** across instructional scaffolds, representations, unknowns and exam-standard problems. Different seeds/numbers alone do not demonstrate variety. One question may assess multiple granular skills; it contributes evidence to each, with uncertainty about exactly which caused a miss.
4. Each skill has a **seven-stage** display. Not-yet-attempted is a separate state, not zero proficiency. Levels 4-5 mean Exam Ready; 6-7 require progressively more evidence and carry humorous skill-specific wasteland titles. No requirement to split practice across separate runs. One long, varied run can reach the top, but diminishing returns make it difficult.
5. Replace the provisional 'two correct/two wrong' rule with **difficulty-weighted evidence**, calibrated to similar progress at matched skill/question difficulty. Success on harder questions has more upward effect; failure on harder questions has less downward effect; failure far below mastery may immediately lower it. Success far below mastery has little effect. Mathematical assists yield reduced mastery evidence. Do not fake skill certainty for unattempted material.
6. **Overworld** selects difficulty from the *specific skill's* estimated mastery and continues updating it; first visits should provide appropriate scaffolding. **Thunderdome** samples a fixed starting difficulty floor based on the average of skills with evidence only, raises lower/unattempted skill selection to that floor, respects higher demonstrated skill mastery, and escalates as the run deepens. Difficulty floor does not drop during that run. Actual mastery evidence still updates globally.
7. Student Mastery Dashboard: five recognizable topic headings; within each, human-readable subgroups and individual skill bars; hide official subtopic codes by default. Show all relevant skills, including Not Yet Attempted, and link each to its explainer and relevant practice location between runs.
8. Explainers are accessible from the outset; failed runs can recommend them through in-world debriefs/bounties. Explainers must be syllabus-appropriate and linked to the exact skill rather than a broad topic label.
9. Do **not** equate examination *standard* with exam *format*. Paper/calculator status must be represented independently of intrinsic difficulty; extended linked exam-style questions work especially well as bosses.

## Explicitly unresolved numerical details

- Mastery evidence weighting, level thresholds, upper-level diminishing-return curve, contribution from multi-skill questions, and handling of hint degree/time-out/partial work.
- Baseline for a player with **no attempted skills** in Thunderdome.
- Quantitative rule for whether a player may be declared Exam Ready from assisted attempts alone.
- Exact calculation of confidence and spaced review selection. Do not implement a mandatory decay clock without approval.

## Consequences and verification

- Extend save schema with versioned skill evidence/proficiency, retaining existing `cells`, `probes` and histories; support migration and rollback. Shared IDs remain stable across syllabus switches.
- Add unit/property tests for: difficult success accelerates; easy failure can reduce; difficult failure is nonpunitive relative to easy failure; assists reduce credit; multi-skill evidence; no out-of-syllabus question; no duplicate skill proficiency across overlapping courses; stage six/seven diminishing returns; Thunderdome floor fixed during a run; overworld uses current skill estimate.
- Report coverage as **(a) syllabus skill mapping, (b) playable generators, (c) validated structures/difficulty, (d) explainers mapped vs recorded/approved**, never one percent masquerading as all four.

## References

- `curriculum/{aa-sl,aa-hl,ai,question-types}.json`, `curriculum/COVERAGE.md`, `curriculum/PEDAGOGY_GAPS.md`
- `game/engine/{maths_engine,planner,progress,courses}.gd`, `game/docs/{MATHS-ENGINE,QUESTION-ENGINE}.md`
