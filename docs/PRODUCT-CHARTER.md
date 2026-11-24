# Product charter - Wasteland Academy

Status: **Accepted owner direction** (2026-11-21). Scope: Godot game, AA SL first.

> Wasteland Academy is a roguelike mathematics game where students enter play quickly and learn through the gameplay loop. Failure is expected and becomes part of progress; game systems reward effort and improvement, while optional explanatory lessons are accessible from the beginning and recommended when useful.

## Success criterion

A student can start an AA SL game quickly, solve varied and mathematically sound questions, survive or fail, receive meaningful feedback and rewards, and feel motivated to return. Their understanding, not their spending or speed, is the educational objective.

## First classroom-ready milestone (not just '100% coverage')

- Five AA SL syllabus zones have complete, coherent regional adventures and meaningful boss milestones, with the option to continue for a personal best after narrative victory.
- Common mechanics work end to end: map, character select and persistent progression, save/resume of one active run, question and mastery engine, in-world debrief, Bazaar, bounties, replayability and Thunderdome. The shared encounter runtime supports combat **and** noncombat challenges with coherent per-question status effects and conditional narrative milestones.
- Required AA SL explainers are actually present, accessible before play, correctly linked to specific skills, and reviewed for mathematical content, narration, notation and playback. A mapped explainer entry is **not** a completed voiced asset.
- Art has consistent direction; missing enemies, bosses, voiced lines and important UI polish are accounted for rather than hidden behind a numerical coverage percentage. **Not every major encounter is a voiced villain:** environmental hazards, robots, creatures, repairs and survival objectives should also feel dramatic.
- Every AA SL skill has representative, validated question **structures** from introductory scaffold to exam-standard reasoning; broad coverage, variety and tested correctness are separately measurable.
- Students never receive questions outside the selected IB syllabus; other courses shape content and architecture but cannot delay the AA SL release by uncontrolled feature expansion.
- A classroom test validates accessibility, pacing, touch interaction, timing, explanations and student engagement.

## Non-goals for this milestone

- New independent game modes without explicit owner approval.
- Four complete course content sets, cloud accounts/sync, competitive leaderboards, real-money purchases or gambling.
- A separately shipped academic product; preserve the maths-engine seam instead.
- Pixel-perfect expansion to every platform before the AA SL Godot web game works well.

## Product decisions that govern trade-offs

1. More meaningful maths solved > more mechanics or UI screens.
2. Low-friction entry > compulsory tutorials, logins or arbitrary prerequisite barriers.
3. Failure generates practice opportunities > punishment or loss of earned Scrap.
4. Skills and question structures > syllabus codes as the student-facing vocabulary.
5. Game flavour surrounds mathematically exact content; it must not obscure it.
6. Preserve and improve the existing maps and engine; no speculative rewrite.
7. Story villains should be satisfying to defeat; environmental/repair challenges provide variety without requiring constant antagonists or large amounts of voice acting.
8. Character, item and status modifiers must build upon a tested, reusable encounter framework; avoid accumulating bespoke systems.
9. Design examples are not implementation authorization. Explicitly postponed: a new stash/run-inventory/quickbar architecture.

## Source pointers

- Existing [SPEC.md](https://github.com/RktRobinhood/wasteland-academy/blob/main/SPEC.md), [ROADMAP.md](https://github.com/RktRobinhood/wasteland-academy/blob/main/ROADMAP.md), [curriculum coverage](https://github.com/RktRobinhood/wasteland-academy/blob/main/curriculum/COVERAGE.md).
- The ADRs in `docs/adr/` are the decision record for this charter. Where existing material conflicts, reconcile it explicitly.
