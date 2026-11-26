# Proposal: skill mastery calibration

- Status: **ACCEPTED 2026-11-25 (FAL-1603).** Matt accepted all nine §12 decisions at their recommended values; the record is on [#268](https://github.com/RktRobinhood/wasteland-academy/issues/268#issuecomment-7168441830). The values below marked PROPOSED are now the accepted values. Implementation lands in bounded PRs that follow §11, starting with the engine update and reads (FAL-1667).
- Issue: [#268](https://github.com/RktRobinhood/wasteland-academy/issues/268) (Paperclip FAL-1603), queue row 3 in [BUILD-LOOP](../BUILD-LOOP.md).
- Governed by [ADR-0002](../adr/0002-curriculum-question-mastery.md). It fills in that ADR's "Explicitly unresolved numerical details" and nothing else.
- Evidence: [`game/tests/test_mastery_calibration_sim.gd`](../../game/tests/test_mastery_calibration_sim.gd) runs the model in [`game/tests/sim/mastery_calibration_model.gd`](../../game/tests/sim/mastery_calibration_model.gd) through the existing test runner. Its printed trajectories are in [`mastery-calibration-sim-output.txt`](mastery-calibration-sim-output.txt). The model sits under `tests/`, which every export preset excludes, so the game does not use it.

Every number below is marked **PROPOSED** as it was reviewed, with a one-line reason. Since 2026-11-25 each is accepted at that value (see Status). The simulation shows the numbers behave as described.

## 1. Terms kept apart

| Quantity | Range | Where it lives | Moved by | Must not be used as |
|---|---|---|---|---|
| **Question difficulty** | 0–5 | `level` on each unknown in `curriculum/question-types.json`. Each skill has a range in `curriculum/aa-sl.json` (`difficulty: [lo, hi]`) | Content authors only | A learner's mastery, or a paper |
| **Mastery rating** | 1.000–7.999, continuous | New per-skill record (§2), one per skill id, shared by every course and mode | Marked answers only (§3) | Displayed directly |
| **Mastery level** | 1–7 | Derived from the rating and the evidence gates (§5) | Never stored; always recomputed | XP, score, an unlock |
| **Not Yet Attempted** | No record at all | A missing record | The first marked answer on the skill | Level 0, a rating of 1, a failure |
| **Paper / calculator policy** | `paper` 1, 2 or either | Request `paper` and the skill's `paper` field | The course and the question context | A difficulty tier |
| **Character XP** | Per character | Game save (ADR-0004) | Play by the active character, accolades | Mastery evidence |
| **Score** | Per run | Run stats | Encounters, real difficulty, accuracy, fewer assists | Mastery evidence |

The update reads difficulty and writes mastery. Nothing else flows between these rows. XP and score may *read* a mastery level (an accolade for a first L4, for example), but they never write it.

**Conflict to fix later (content, not this proposal):** the catalogue's difficulty descriptors in `curriculum/aa-sl.json` say `3 = "5-6 mark Paper 1 (no calculator)"` and `4 = "5-6 mark Paper 2 (calculator)"`. That ties levels 3 and 4 to a paper, which ADR-0002 §9 rules out. This proposal treats 0–5 purely as demand. Rewording the descriptors (for example, 3 = "5–6 mark exam-standard", 4 = "5–6 mark exam-standard, extended reasoning") is a separate content task. It does not change any stored `level`.

## 2. The per-skill record

Stored in the evidence next to `cells`, `probes` and `history`, so the game save and the study screen's `user://study.json` both carry it:

```text
evidence.mastery = {
  "version": 1,
  "skills": {
    "<skill id>": {
      "m": 4.375,            # rating
      "n": 17,               # answers that counted
      "exam_ok": 3,          # unassisted successes at the exam tier (§5)
      "ok_cells": [...],     # distinct cell keys answered right (PROPOSED cap 16: the gates need 5, and the save stays small)
      "recent_ok": [...],    # last 3 cell keys answered right
      "last": 1764000000,    # time of the last answer (for display; no decay)
      "migrated": false      # true while the record holds only replayed v7 evidence
    }
  }
}
```

A skill with no entry is Not Yet Attempted. The record is keyed by the stable skill id only, never by course (see §9).

## 3. The update function

An Elo-style step on a logistic curve. Let `d` be the question's difficulty and `m` the skill's rating.

```text
e      = d + 1                          # the question's rating; d3 sits at Level 4
p      = 1 / (1 + exp(-(m - e)))        # expected chance of success
success:  m += K · (1 - p) · credit · damp(m) · repeat
miss:     m -= K · p · miss_weight · share
clamp m to [1.000, 7.999]; an assisted or migrated success also stops at 3.999
```

`share` is 1 for a single-skill question (§4). On the skill's top tier, once `m ≥ e`, a success uses `e = m`. That makes it count as a matched success rather than an easy one, so a skill whose hardest question is d3 can still reach L6 and L7 through consistency (see "Low-ceiling skills" below).

| Constant | PROPOSED value | Reason |
|---|---|---|
| Start rating on first evidence | 1.0 | Do not fake certainty. A strong learner climbs fast anyway: 4 straight d3 successes reach L4. |
| `K` | 1.0 | A matched success then moves the rating 0.5: about two matched successes per level, as #268 asks. |
| Logistic scale | 1 level | A one-level gap gives p = 0.73, so harder and easier questions differ clearly without swamping matched evidence. |
| `e = d + 1` | offset 1 | 50% on d3, the bulk exam tier (679 unknowns), puts a learner at the start of L4 Exam Ready. 73% on d3 puts them at L5. |
| Cap | 7.999 | Leaves headroom inside L7, so one miss does not drop a hard-won L7. |
| Floor | 1.0 | Below L1 there is nothing to show. Not Yet Attempted is separate. |

What this gives (all printed in the simulation output):

- **Matched successes**: an ideal match moves exactly 0.5 per success, so L1→L5 takes 2 successes per level. With the planner's whole-number difficulties, one varied run of all-right answers first shows L4 at success 7, L5 at 8, L6 at 12 and L7 at 19.
- **Above-level success moves further.** From m = 3.5, a success at d1/d2/d3/d4/d5 moves +0.18/+0.38/+0.62/+0.82/+0.92.
- **Above-level failure is nonpunitive.** From m = 4.5, a miss at d5 costs 0.18, a miss at d3 costs 0.62 and a miss at d1 costs 0.92. One miss at d0–d3 drops an L4 to L3 at once.
- **Below-level failure from high up**: an L6 (m = 6.2) who misses two d1 questions falls to L4 (6.2 → 5.22 → 4.25).
- **Success far below the rating does little**: +0.18 at one and a half levels below (d1 from m = 3.5), and about +0.03 at three and a half levels below (d0 from m = 4.5).

### Outcomes and assists

The fight already separates `right`, `late`, `glancing`, `wrong` and `timeout`, and has three lifelines: hint, 50-50 and Time Freeze. Credit multiplies the upward step, and miss weight multiplies the downward step.

| Outcome or assist | PROPOSED | Reason |
|---|---|---|
| Typed value, unassisted | credit 1.0 | Full evidence. |
| `late` (right, in the late zone) | credit 1.0 | Speed is not the chief objective (glossary: Score). |
| Time Freeze | credit 1.0 | It changes the clock, not the maths. |
| Multiple choice | credit 0.75 | With four options, a guess lands one time in four. |
| `glancing` (right value, wrong accuracy) | credit 0.75; not counted for Exam Ready | The maths was right but the IB would drop the accuracy mark. |
| Hint (the first worked step) | credit 0.5; not counted for Exam Ready | The hint gives away the start of the method. |
| 50-50 on multiple choice | credit 0.4 (replaces 0.75) | With two options left, a guess lands one time in two. |
| Hint + 50-50 | 0.4 × 0.5 = 0.2 | Credits multiply. |
| Assisted success (hint or 50-50) | rating cannot pass 3.999 | ADR-0002 leaves open whether assisted work alone can make a learner Exam Ready. The proposed answer is no: assisted work carries a skill to the edge of L4 and stops there. |
| `wrong` | miss weight 1.0 | Full evidence. |
| `timeout` | miss weight 0.5 | Giving no answer is weaker evidence than a wrong one, but it is not no evidence. Otherwise waiting out the clock would protect a rating. |
| Incomplete response | no update | The fight already refuses it, and nothing is marked. |
| "Another way" follow-up | updates like any answer | It is a separate cell, so it is honest variety. |
| Boss part | updates per part, per the part's own cell | Each part is its own question. |
| Concept probe | no update in v1 | Probes are keyed by type, not by skill, and are extension material. Revisit once probes carry skill ids. |

**Repeats.** A success on a cell that is among the skill's last 3 successes counts half (PROPOSED. Reason: the same structure again shows less than a new one, and ADR-0002 §3 says seeds alone are not variety). After 10 d3 successes, one repeated cell gives m = 4.74 (L4) and ten different cells give m = 5.57 (L5).

## 4. Multi-skill questions

The catalogue has 1,753 single-skill unknowns, 221 with two skills, 17 with three and 2 with four.

- **Success**: every listed skill gets the full update. (PROPOSED. Reason: the item could not be answered without each of them.)
- **Miss with a misconception whose ref names one of the skills**: that skill takes the whole miss and the others take none. (PROPOSED. Reason: the marker already knows which mistake was made.)
- **Miss otherwise**: blame is shared by how likely each skill was to be the one that failed, `share_i = (1 - p_i) / Σ(1 - p_j)`. The shares sum to one answer's worth. (PROPOSED. Reason: a multi-skill miss is still a single miss, not two misses.) In the simulation, A (m = 5.0) and B (m = 2.5) miss a d3 question together: A takes 0.25 of the blame and B takes 0.75.
- An unattempted skill in a multi-skill question gets a record that starts at 1.0, then takes its update. The question really did test it.

Implementation note: misconception refs come from `mark()` already. The catalogue would need each misconception tied to a skill id, which it does not yet do. Until it does, every miss uses shared blame.

## 5. Displayed level and evidence gates

```text
level = Not Yet Attempted                 if no record
      = clamp(floor(m), 1, 7), then:
        L7 needs right answers on ≥ 5 distinct cells (or every cell of the skill in the course)
        L6 needs right answers on ≥ 3 distinct cells (or every cell)
        L4+ needs ≥ 2 unassisted successes at the exam tier (d3, or the skill's top tier if lower)
```

| Gate | PROPOSED | Reason |
|---|---|---|
| Exam Ready: 2 unassisted exam-tier successes | 2 | One could be luck. Two on exam-standard work is the smallest honest claim. |
| L6: 3 distinct cells | 3 | A wasteland title should cover more than one question structure. |
| L7: 5 distinct cells | 5 | Top rank means breadth. Capped at the skill's own cell count, so small skills are not locked out. |
| Upward damping | ×1 below L5; ×0.5 in L5; ×0.25 in L6; ×0.125 inside L7 | L5→L6 then takes about 4 matched successes and L6→L7 about 8, so the top levels need more evidence, as ADR-0002 §4 asks. |

### Diminishing returns at L6 and L7

Damping only the upward step does two things. The top levels take more evidence, and they also need more consistency to hold. The simulation prints the success rate that keeps a rating steady when questions are chosen at that rating:

| Hold this rating | Recommended (×0.5 / ×0.25) | Softer alternative (×0.75 / ×0.5) |
|---|---|---|
| m 4.0 (start of L4, d3) | 50% | 50% |
| m 5.0 (start of L5, d4) | 67% | 57% |
| m 6.0 (start of L6, d5) | 80% | 67% |
| m 7.0 (start of L7, d5) | 92% | 85% |
| Skill with top tier d3: L5 / L6 / L7 | 75% / 88% / 94% | 66% / 78% / 88% |

Seeded simulated learners, 80 questions each, chosen at their rating (recommended damping):

| True ability | Right | Final | First L6 | First L7 |
|---|---|---|---|---|
| 3.0 | 42/80 | m 3.72, L3 | – | – |
| 4.5 | 44/80 | m 4.72, L4 | – | – |
| 6.0 | 52/80 | m 5.49, L5 | q28 | – |
| 7.0 | 58/80 | m 5.64, L5 | q12 | – |
| 8.0 | 71/80 | m 6.19, L6 | q12 | q30 |

**Recommendation: the recommended damping.** L6 and L7 are wasteland titles, and holding them should take near-mastery of the hardest questions. The cost is that a learner who gets 73% of the hardest questions right settles at L5. L5 is still Exam Ready, at its stronger degree. Choose the softer alternative if Matt wants L6 to be a normal goal for strong students rather than a rare one.

**Low-ceiling skills.** 21 unknowns are at d5, and many skills top out at d2–d3. Without the top-tier rule, the rating could never rise past a skill's hardest question. With it, a skill whose range is `[1, 3]` reaches L7 after 19 straight successes over 6 cells, and one miss at its top tier from there drops it back to L6.

## 6. Overworld selection (consumer, unchanged engine)

The planner keeps its rules (unseen cell → recent wrong → exam frequency) and gains one input. For the skill a cell tests, it prefers cells whose difficulty is `round(m − 1)` within the skill's range, and uses the skill's lowest tier when the skill is Not Yet Attempted. That gives the scaffolding on first visits that ADR-0002 §6 asks for. The selection uses the existing `Seeded` streams and does not draw extra random numbers, so a given request still produces the same question (§9). The weighting is for the implementation PR to set and test. This proposal fixes only the target difficulty.

## 7. Thunderdome floor

- **Floor** `F` = the mean rating of the skills that have evidence among those eligible for this run (course ∩ chosen topics). It is taken **once at the start of the run** and stored in the run snapshot (#267), so it cannot drop during the run.
- **Per skill**: a question for skill `s` is chosen at `max(F, m_s)`, so a skill already above the mean keeps its own higher level. An unattempted skill is chosen at `F`, but **no rating is written for it until it is answered**.
- **Escalation** by depth stays with the existing Thunderdome tuning (ADR-0004), added on top of that start. It is not set here.
- Answers still update mastery globally as normal. Only the floor is frozen.
- **No-attempt fallback (PROPOSED: F = 2.0, so d1 questions).** Reason: d1 is the lowest syllabus tier (d0 is prior learning), and Thunderdome escalates quickly from there. It writes nothing to the save. Alternatives: 1.0 (start at prior learning; gentler but slow), or the course-wide attempted mean when the chosen topics have no evidence but others do. **Recommended: 2.0 when nothing in the pool has evidence. Do not borrow other topics' means**, because strength in Calculus says little about Probability.

Simulation: attempted A 5.2, B 2.4 and C 3.4, with D Not Yet Attempted, give F = 3.667. A asks at d4; B, C and D ask at d3. After three misses, B falls to 1.96 while the run's floor stays at 3.667, and D still has no record.

## 8. Migration (save v7 → v8)

- **Additive.** `cells`, `probes`, `history` and every game field are kept byte-for-byte. The migration adds `mastery` (§2) and bumps `SaveData.VERSION` to 8, in a new `_step(7)` case. The study evidence file gets the same addition.
- **Back-fill (recommended)**: rebuild each skill from the v7 cell counts by replaying them.
  - Cells are taken in sorted key order. Each cell's rights and wrongs are spread evenly, with misses first on a tie, so no order is invented in the learner's favour.
  - The difficulty is the cell's catalogue `level`. Every skill the unknown lists is updated.
  - Each replayed success gets credit 0.75, the `migrated` assist, because the format and assists are unknown.
  - Migrated evidence is capped at 3.999 and **never counts toward Exam Ready**.
  - In the simulation, 12 right and 3 wrong across two cells give m = 3.999 (L3). Two new unassisted exam-tier successes then open L4.
- Alternative: start everyone as Not Yet Attempted. It is honest, but it wipes the progress learners can already see. Not recommended.
- **Deterministic**: the same v7 save always migrates to the same v8 record (checked in the simulation).
- **Rollback**: because the change is additive, a v8 save can go back to a v7 build by removing `mastery` and setting `version: 7`. Today a v7 build refuses a newer save ("That save is from a newer version"). The implementation PR should ship a tested `downgrade(8 → 7)` for export/import.
- Skill-id renames: none. ADR-0002 keeps ids stable. If one is ever needed, it is a keyed move inside `mastery.skills` in a later migration step.

## 9. Identity, courses and reproducibility

- **One record per skill id**, shared by AA SL, AA HL, AI SL and AI HL. Switching course changes which skills are *eligible* and *shown*. It never copies, splits or resets a record, and the same skill never has two ratings.
- **Course filtering** happens on read: the dashboard, the selection and the Thunderdome mean all use the current course's skills (`Courses`).
- **Seed reproducibility**: the update is a pure function of (record, question difficulty, skill range, outcome, assists, cell key). It draws no random numbers, so a given request and seed still produce the same question, marking and worked solution on both screens (`test_one_request_gives_the_same_maths_on_both_screens`).
- **One engine**: the update and the level live in `MathsEngine`'s learning-results section (`record` gains outcome and assists; `mastery(evidence, skill)` and `mastery_levels(evidence, course)` are new reads). There is no second maths engine, and nothing moves into `run.gd`.
- **No decay**: ratings change only when an answer is marked. `last` is for display. Spaced review stays an OPEN selection question (ADR-0002).

## 10. Consumers

**Student Mastery Dashboard** (ADR-0002 §7) reads `mastery_levels(evidence, course)`:

- five topic headings, then human-readable subgroups, then a segmented bar for each skill;
- Not Yet Attempted is shown as its own empty state, not as L1;
- L4–L5 are marked Exam Ready, and L6–L7 show the skill's title (creative content, not set here);
- each skill links to its explainer and its practice location.

A bar may show progress through the current level, `m − floor(m)`. It is not a percentage of the syllabus.

**Bounties** (ADR-0003 §7) read mastery signals and never write mastery. Proposed defaults, owned by ADR-0003's open list:

- **Open** a bounty when a skill's displayed level drops, or when it collects ≥ 2.0 weighted misses (Σ miss_weight × share) in its last 6 answers.
- **Resolve** it when the skill is back at or above the level it had when the bounty opened, with 2 unassisted successes at that difficulty in the bounty's region, plus the region's narrative step.

Within-zone prerequisites and Test-Out (ADR-0003) would read levels the same way. Their thresholds are not set here.

## 11. Checks for the implementation PR

One test or more each, mapped to ADR-0002's verification list:

1. Harder success moves further; easy failure can drop a level at once; harder failure costs less than easier failure.
2. A matched success moves 0.5 × damping; two matched successes per level up to L5.
3. Hint and 50-50 reduce credit; Time Freeze and `late` do not; assisted-only evidence never shows L4.
4. Multi-skill: success credits each skill; shared blame sums to one; a misconception naming a skill takes the whole miss.
5. L6/L7 damping and the distinct-cell gates; a skill whose top tier is d3 can still reach L7.
6. Not Yet Attempted is a missing record. No read path creates a record, and the Thunderdome floor ignores it.
7. The Thunderdome floor is the mean of attempted eligible skills, fixed for the run and stored in the run snapshot; higher skills keep their own level; the no-attempt fallback is 2.0.
8. The overworld target difficulty follows the skill's current rating.
9. Every question asked is in the course's syllabus; there is one record per skill across course switches.
10. Migration v7 → v8 keeps `cells`, `probes` and `history` byte-for-byte, is deterministic, caps migrated evidence below L4, and a downgrade back to v7 round-trips.
11. The engine-boundary test (`test_maths_engine.gd`) still passes; mastery code reaches no game code.
12. The seed check still passes on both screens; the update draws no random numbers.
13. The coverage report keeps its four separate counts (ADR-0002 Consequences), with no mastery percentage among them.

## 12. Decisions for Matt

Accepting the proposal means accepting each of these, or naming a different value:

1. **The update function**: logistic Elo step, start 1.0, K = 1, scale 1 level, question rating `d + 1`, cap 7.999.
2. **Outcome and assist credits**: MCQ 0.75, glancing 0.75, hint 0.5, 50-50 0.4 (multiplicative), late and Time Freeze 1.0, timeout miss weight 0.5, probes not counted in v1.
3. **Assisted-only cannot be Exam Ready**: assisted and migrated work stop at 3.999; L4 needs 2 unassisted exam-tier successes.
4. **Multi-skill**: full credit to each skill on success; on a miss, shared blame by `1 − p`, or the whole miss to the skill a misconception names.
5. **L6/L7**: damping ×0.5 / ×0.25 / ×0.125, recommended over the softer ×0.75 / ×0.5 / ×0.25. Distinct-cell gates 3 and 5. Repeated-cell successes count half.
6. **Thunderdome**: floor = mean of attempted eligible skills, frozen at run start; per skill `max(F, m)`; **no-attempt fallback 2.0**, with no borrowing from other topics.
7. **Migration**: back-fill by deterministic replay (recommended) or start fresh as Not Yet Attempted.
8. **Bounty defaults** (§10): accept them here, or leave them to the ADR-0003 bounty proposal.
9. **Content follow-up**: reword the catalogue's difficulty descriptors 3/4 so they no longer name a paper.

Matt accepted all nine on 2026-11-25 (FAL-1603). Exact active-run work (#267) and the encounter audit (#269) carry on independently.
