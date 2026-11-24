# Alignment audit — 2026-11-24

Scope: accepted November 21 interview versus GitHub default branch. Started from local `146e2cf`, fetched actual main `d208766`, then reviewed and merged [#265](https://github.com/RktRobinhood/wasteland-academy/pull/265) as `5306847`. The local checkout had been 1,925 changed files behind; that is checkout drift, not a claim all those changes happened after the interview. No later main commits existed at intake. This is a source/CI audit, not a classroom playtest.

## Five highest-impact discrepancies

1. Governance allowed inference to become approval; SPEC said the game wins over the specification. Reconciled in AGENTS/SPEC with ADR-0001 and the accepted/proposed/open distinction. Existing ordinary-work, spending, voice, art, privacy and release rules are retained.
2. Full AA SL product completion was being conflated with playable-skill coverage, while the roadmap put platforms and further courses ahead. Charter/queue now make all five AA SL adventures and learning support the target; generated coverage remains an independent metric.
3. Mid-run saves bank earned Scrap, but do not restore an active run. `SaveData.blank()` has no active-run snapshot; `fight.gd` constructs a new Run, and navigation quits it. [#267](https://github.com/RktRobinhood/wasteland-academy/issues/267) tracks exact restoration and course policy.
4. Cell accuracy and floor-based selection do not implement seven-level weighted skill mastery, the dashboard or active skill bounties. [#268](https://github.com/RktRobinhood/wasteland-academy/issues/268) prepares calibration; shipping the numbers requires acceptance.
5. Repeatable mile bosses and journey events do not prove regional story victory or common persistent statuses. [#269](https://github.com/RktRobinhood/wasteland-academy/issues/269) inventories reuse and proposes story mapping before further content/mechanics.

## Implementation truth table

“Tests exist” means source contains relevant checks, not that a new local Godot execution occurred. #265's CI ran successfully on its exact head against `d208766` before merge, including Godot, WebKit, answers and browser/export jobs.

| Capability | Owner direction | Code / documentation evidence | Tests / player access | Assessment / next work |
|---|---|---|---|---|
| Shared maths interface, four-course hard filter | Accepted, ADR-0002 | `game/engine/maths_engine.gd`, `courses.gd`, `game/docs/MATHS-ENGINE.md` | `test_maths_engine.gd`, `test_courses.gd`; game and `?study` consumers | Implemented groundwork; #134 still has neutral-context/bank integration requirements |
| AA SL playable skills | Accepted minimum, not whole release | `curriculum/COVERAGE.md`: 286/286 AA SL skills, 6,014 coverage cells; 193 catalogued types / 184 built across courses | Generated report; mathematical checker/read-signoff are separate | Playable mapping complete; structural/difficulty breadth and classroom readiness not established by it |
| Exact answers, seed validity and prose quality | Accepted | Answer/checker/verified-seed tools; `curriculum/signoff.json` | Existing unit, independent answer, nightly stress and prose review workflows | Continue #193 and current signoff gaps; do not assume all structures have human approval |
| Safe save and earned Scrap | Accepted, ADR-0003/0007 | `save_data.gd` v7: atomic/backup/unreadable recovery and transfer; `Run._bank()` | `test_save_safety.gd`, fight tests; accessible Settings export/import | Already shipped via #262/#263; preserve it |
| One exact active run | Accepted | Run state held in memory; no corresponding snapshot in save schema | Banking tests do not show restoration of HP/question/timer/boss part | Missing; #267. Character locking will also need integration as characters are built |
| First-launch course/cards/student wording | Accepted | `first_run.gd`, `map.gd`, `writing/glossary.*`, `string-audit.md`; #264 | `test_first_run.gd`; #265 adds touch journey | Substantial implementation; #186 still needs fresh-player evidence; #203 docs/copy review remains explicit |
| Course settings / inert excluded scenery | Accepted | `map.gd` still draws `_course_row()` on topic screens and suggests another course for excluded content | Existing hard filters protect served questions | Partial/contradictory UX; #267 moves control between runs |
| Weighted seven-level mastery and adaptive floor | Accepted principles; calibration OPEN | MathsEngine evidence is cells/probes/history; Progress accuracy; Planner unseen/recent/frequency and Dungeon floor pools | Existing evidence/selection tests exercise older policy | Missing target model; #268 proposal first, then implementation and migration |
| Skill dashboard and temporary active bounties | Accepted, ADR-0002/0003 | Topic accuracy/weakest-skill summaries exist; not the target skill dashboard/board | Current map summaries accessible | Missing target; follows approved skill evidence, not a new independent mode |
| Encounter reuse / statuses / narrative | Accepted principles; content/tuning OPEN | `run.gd` resolve/stakes, `modifiers.gd`, `dungeon.gd`, journey events, `game/data/bosses.json` | Existing combat/journey checks; no evidence of accepted persistent status/story contract | Partial reuse; no proven separate narrative flags/finish-or-continue story milestone. #269 audit first |
| Characters, XP, accolades, advanced economy | Accepted principles; numbers OPEN | Save `class: null`, `trees: {}`; Bazaar upgrades/perks/cosmetics exist | Existing Bazaar and run checks | Partial; no claim independent character XP/trees/once-only accolades are done |
| Thunderdome Exhibition / Boss Rush | Accepted target, ADR-0004 | Existing all-topic dungeon and recurring linked bosses | Existing Thunderdome/dungeon checks | Existing play != target topic policy, fixed mastery floor, paid-in-Scrap Boss Rush or comparable PBs |
| Optional explainers | Accepted; #215 interactive direction retained | 336 mapped explainers / 181 AA SL; 12 script files; shared lesson player and Spark worked-step player exist | `test_lesson_player.gd`; `game/docs/LESSONS.md` says lessons are unapproved and have no student-map links | Mapping != accessible approved narrated assets. #218/#222 owner prototype evidence, #223 rework, #224 budget gate remain |
| Safari / mobile timer / keyboard | Accepted | #265 hidden-tab timer pause, first course focus, WebKit touch and save tests, device checklist | All #265 CI checks green. #187 comment records focus can leave overlay; typed/quit keyboard checks incomplete | Automated portion landed; real iPhone/Android/Chromebook and complete keyboard pass remain. #187 stays open |
| Accessibility/art/classroom | Accepted | Reduced-motion groundwork, #196; art workflow #201/#226 | Human evidence not established by this audit | Keep issues open until their criteria pass; no paid production/student release approval inferred |

## Remote branch disposition

At intake there were 19 non-main remote branches and one open PR (#265). No remote branches were deleted. Ahead/behind counts describe commit ancestry before #265 merged; squash merges can leave unique commits, so ancestry alone cannot prove content is unmerged.

| Branch / group | Intake evidence | Disposition / next action |
|---|---|---|
| `fal-1042-webkit-tap` | 2 ahead / 0 behind; PR #265, clean and all executed checks green | Reviewed and merged to main as `5306847`; #187 retained for remaining acceptance |
| `art/fal-1034-prompt-cards` | 1 ahead / 44 behind; PR #208 CLOSED, not merged | Preserve; compare prompt cards against current #201 workflow before reviving. No automatic merge |
| `art/fal-830-look-frames` | 3 ahead / 46 behind; PR #200 CLOSED, not merged | Preserve; verify current accepted assets before taking any unique work |
| `fal-1001-r3-modelling` plus `fal-1001-r3-{ch,cu,ex,fi,li,qu,si,te,va}` | 10 AI modelling branches, each 11 behind / 1–7 ahead; some explicitly WIP; no PR found among recent 200 | Park behind AA SL milestone. Later one integrator assesses scaffold and builders together, retaining partial work and running actual acceptance checks |
| `fal-1008-ahl-inequalities` plus `fal-1008-r10-{ai,li,me,mg}` | 5 HL scaffold/builders, each 11 behind / 1–7 ahead; one explicit WIP; no PR found among recent 200 | Park; no unchecked mass merge or new builders. Preserve compatibility when eventually integrated |
| `fal-1035-voice-cap` | 1 ahead / 45 behind; unapproved whole-map production estimate | Reference only; #224 requests revised interactive-format tiers after prototype review. Do not resume paid production |

The two other local branches have gone upstreams (`chore/issue-resolution-policy`, `chore/merge-completed-work`). Their policy/fixes are already reflected on main; leave local history intact. After #265 there is no remaining pre-existing open PR to close or merge.

## Delivery and external-state limits

The owner confirmed the build loop runs on Paperclip and asked that fresh/interrupted agents can catch up through the repository. This change supplies root startup instructions, the queue and issue checkpoints. No Paperclip connector/task-state access was available in this session; no scheduler/agent configuration or Paperclip task status was changed. An already-running agent must fetch and reread current main guidance. GitHub #204 remains the restart index, with #266 the open product umbrella.

The November 21 source audit is retained as historical evidence. Current code contradicting accepted behavior stays visible as implementation work, not silently “fixed” through documentation or a speculative gameplay rewrite.
