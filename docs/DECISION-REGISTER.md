# Decision register - authoritative interpretation of the owner interview

Interview date: 2026-11-21; adopted into the repository 2026-11-24. This register distinguishes accepted direction from ideas and OPEN choices for all build agents. Refer to the ADRs for full detail and acceptance cases. Implementation status belongs in the [current audit](ALIGNMENT-AUDIT-2026-11-24.md); work order belongs in [BUILD-LOOP.md](BUILD-LOOP.md).

The owner requested repository adoption and delivery reconciliation on November 24. Existing #215 interactive-explainer decisions and paid-production/prototype approval gates remain in force. Proposed handoff prompts do not override the live request. Unresolved timer recovery and save strategy details below must be checked against newer save work and #265's hidden-tab pause before proposing changes.

## A. Accepted product decisions

| Area | Accepted decision | ADR |
|---|---|---|
| North star | Fast-entry roguelike mathematics game; practice, improvement and optional help; do not substitute a curriculum browser for gameplay | 0001 |
| Scope | Finish all **five AA SL zones**, story/asset/voice polish, required explainers and core game systems before uncontrolled four-course or new-mode expansion | 0001 |
| Agent power | New game modes or major unapproved mechanics need owner approval; normal approved implementation proceeds | 0001 |
| Math | One question engine for all game modes; four course-specific hard content filters; granular cross-course skill IDs | 0002 |
| Coverage | Representative *structural* variation and mathematical validity to exam standard, not just numerical reskins or a coverage-count claim | 0002 |
| Help | Explainers available from start and linked to specific skills; optional 'Know Your Enemy' help from bounties | 0002/0003 |
| Mastery | Seven displayed proficiency levels per individual skill, 'Not Yet Attempted' separate; level 4-5 Exam Ready, 6-7 skill-specific funny titles | 0002 |
| Mastery evidence | Difficulty-weighted asymmetric evidence, partial credit for assists, higher-level hard successes meaningful, low-level misses can downgrade | 0002 |
| Mastery calibration | Accepted 2026-11-25 (FAL-1603, [#268](https://github.com/RktRobinhood/wasteland-academy/issues/268#issuecomment-7168441830)): all nine decisions in [the calibration proposal](proposals/mastery-calibration.md) §12 at their recommended values. Logistic Elo step (start 1.0, K = 1, scale 1, question rating `d + 1`, cap 7.999); credits MCQ 0.75, glancing 0.75, hint 0.5, 50-50 0.4, late/Time Freeze 1.0, timeout miss 0.5, probes not counted; assisted and migrated work stops at 3.999 and L4 needs 2 unassisted exam-tier successes; multi-skill blame by `1 − p` or the named misconception; damping ×0.5/×0.25/×0.125, cell gates 3 and 5, repeats half; Thunderdome floor = attempted mean frozen per run, `max(F, m)`, no-attempt 2.0; v7 back-fill by deterministic replay; bounty defaults per §10; descriptors 3/4 reworded | 0002 |
| Mode difference | Overworld uses each skill's current mastery; Thunderdome fixed-for-run floor from attempted-skill mean, escalates and respects higher individual levels | 0002 |
| Geography | Same overall and regional maps for all courses; unsupported locations visible but inert; five large zones accessible from start | 0003 |
| Prerequisites | No cross-zone gates; only real within-zone dependencies, unlock permanently from any mode; optional Test-Out for actual gates | 0003 |
| Runs | One savable active run, character locked for its duration; region boss offers finish/continue; earned Scrap and narrative milestones persist | 0003 |
| Bounties | Temporary, active-only and skill-specific; shown between runs; direct explainer/location navigation; disappear after sustained improvement | 0003 |
| Progression | Personal-best arcade scores, no player-v-player leaderboard; XP per active character, account accolades only once, three trees/character | 0003/0004 |
| Economy | Shared Scrap and collected items; Bazaar plus traveling merchants with limited **shop stock**; mathematical assists modify bonus and mastery evidence | 0004 |
| Raiders | Flashy item use attracts probabilistic raiders; subdued attention UI; repeatable raider boss may have exclusive drops, escapes; attention resets upon its defeat | 0004 |
| Thunderdome | Select syllabus topics; Exhibition open at start; Boss Rush unlock via meaningful Exhibition milestone and costs earned Scrap; wider scope yields larger potential rewards | 0004 |
| Questions in Thunderdome | Weighted random topics, avoid immediate repeat after focused miniboss, no guaranteed rotation; linked questions for bosses | 0004 |
| Encounters | One reusable framework for combat, traps, repair, survival, creatures/robots/mechs/environmental hazards, all with mathematics | 0005 |
| Status | Run-persistent until cured/recovered, tick after each resolved question, most may stack with cap; some states not stackable; class resistances and antidotes possible | 0005/0007 |
| Effect dials | Can affect timers and other question conditions as well as combat; use compatible, bounded modifiers; no forced new item inventory system | 0005/0007 |
| Stories | Narrative beats are separate from mastery, minimum introduction/complication/climax, conditional event flags; high mastery can accelerate mathematical demands but not skip story | 0006 |
| Villains | Antagonistic/memorable, victory satisfying; other major encounters not necessarily villain fights or voice-heavy | 0006 |
| Reuse | Defeated region bosses may enter Thunderdome random eligible roster with altered context; recurrent raider villains have different loop | 0006 |

## B. Specifically rejected or deferred

- No new independent game mode just because an AI agent imagines one.
- No cross-zone prerequisite or mandatory course completion before entering hard content.
- No mandatory relic/explainer viewing before play.
- No permanent player archive of cleared bounties displayed on the board.
- No competitive global/class leaderboards as a requirement.
- No cloud account/sync or restore-after-reinstall requirement for first release.
- No economic loss of already-earned Scrap on death; no extraction or mandatory banking mechanic.
- No automatically implemented separate stash/run-inventory/quick-bar or arbitrary capacity limits. User expressly said to leave inventory alone.
- No real-money gambling or real-money purchases as part of Boss Rush.
- No assumption every 'boss' is a voiced villain. Avoid forcing long scripts for hazards/animals/robots.
- No forced multi-run requirement to achieve mastery level 6/7; very long successful runs can attain them with diminishing returns.
- No permanent locking of an opened location after mastery falls, or course-switching popups on ineligible scenery.

## C. Ideas discussed but not authorized as individual features

A sandstorm shelter episode; giant mutant scorpion/sandworm/giant mosquito; armor-breaking mech then pilot phase; wheeled raider convoy; vehicle acting as a shield; Dune-style shield with break probability; 'rage' item raising difficulty/damage both ways; backpack upgrades; specific poison formulas, dazed timer effects as item specs; novelty title examples. These can serve as **writer/designer pitches and vertical-slice candidates** only. The *framework capabilities* they illustrate are approved where stated in ADRs; the *actual catalog entries* are not automatically approved.

## D. Still open (do not invent accepted numbers)

1. Exact progression graph and final-boss identity for each current region; reconciliation of repeated 'mile' boss with narrative win.
2. First region's three story beats, varied encounter lineup, and what math progression makes climax eligible.
3. ~~Exact mastery curve, assist weights, initial Thunderdome floor when no attempted skills.~~ Settled 2026-11-25 by the accepted [calibration proposal](proposals/mastery-calibration.md) (see A). Weighted run *scoring* stays open.
4. Character XP/level curve, ultimate-tier progression and alternate-character realism with once-only account accolades.
5. Scarcity/bazaar catalog, merchant rarity, Raider Attention probability/drop tables, status tick/recovery/stack cap values and composition rules.
6. Boss Rush entry fee/return, Exhibition unlock target, allowable stopping behavior, and topic-breadth reward formula.
7. Active-run timer pause/recovery behavior and save migration strategies.
8. User-facing naming of creatures, bosses, subclasses, story events, tone, bespoke lines and VO approvals.

## E. Conflict precedence

1. **Accepted owner decisions and ADRs** express desired product behavior.
2. **Current code and tests** express what actually exists, not necessarily what was intended.
3. **Current specification, roadmap and old issues** are evidence to reconcile, not automatic authority to override accepted decisions.
4. If two accepted decisions conflict, or a value isn't decided, propose alternatives with impact and ask the owner. Never manufacture approval.
