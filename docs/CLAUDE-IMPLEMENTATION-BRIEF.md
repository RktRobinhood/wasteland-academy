# Claude handoff - bounded recovery plan for Wasteland Academy

> Historical staged proposal from the November 21 package. The owner requested repository adoption on November 24; its documentation phase is now being delivered. Use [BUILD-LOOP.md](BUILD-LOOP.md) and [the current audit](ALIGNMENT-AUDIT-2026-11-24.md) for actual sequencing, newer implementation and issue state. The response-format instructions and requests for a new intake/review below are preserved source material, not fresh instructions. Accepted ADRs still govern; OPEN choices still need acceptance.

Prepared 2026-11-21. **Do not start by building features.** Start by reconciling the codebase and owner decisions in a documentation-only branch.

## Mission

Recover owner control of Wasteland Academy and finish the AA SL roguelike, rather than expanding modes from ambiguous terms. Preserve validated work. Make the existing architecture communicate correctly between curriculum/question generation, proficiency evidence, selection, run rules, character progression and map UI.

## Mandatory intake

1. Check out the **latest** repository commit and capture the SHA, `git status`, open issues/PRs and currently active Paperclip tasks. Treat this dated handoff as accepted **product intent**, not proof of current implementation. Review changes made since 2026-11-21 before applying it.
2. Read `docs/PRODUCT-CHARTER.md`, `docs/DOMAIN-GLOSSARY.md`, `docs/adr/0001` through `0007`, `docs/DECISION-REGISTER.md`, `docs/REPOSITORY-AUDIT-2026-11-21.md`, `docs/implementation/ENCOUNTER-AND-BOSS-AUDIT.md`, and existing `AGENTS.md`, `SPEC.md`, `ROADMAP.md`, `writing/glossary.md`, `game/README.md`, `curriculum/README.md` and engine references.
3. **Do not silently rename or drop** existing `island`, `zone`, `region`, `floor`, `mile`, `type`, `cell` or skill identifiers; preserve save migrations and question seed reproducibility.
4. Inventory actual code and data: question recipes, skill IDs and curriculum mapping, `MathsEngine` interface, `SaveData`, `Run`, `Dungeon`, `Planner`, `Progress`, `Courses`, `Bazaar`, maps, explainer assets and lesson prototypes. Build a truth table with one line per feature: **owner approved? documented? coded? tested? player accessible?**
5. In your first response to the owner, summarize only **five highest-impact contradictions** and the smallest recommended fixes. Ask permission where a genuine design choice remains open. Do **not** merge an unapproved new mode.

## PR 0 - decisions and ownership (documentation only)

- Merge the approved product charter, domain glossary and ADRs; link them from root README.
- Modify `AGENTS.md` using `AGENTS-POLICY-INSERT.md`: approved scope can proceed autonomously; **new modes/mechanics require explicit approval**. Keep existing Paperclip permissions for paid services, user data, releases, voices and art.
- Reconcile `SPEC.md` with decisions. Do not leave 'current code wins whenever it conflicts with spec' as a product-authority rule. Mark 'not implemented' honestly.
- Reconcile `ROADMAP.md` and `TEACHERS.md` from live code and **generated** coverage reports. Preserve historical issue links; never hand-edit generated reports.
- Update the existing player-facing `writing/glossary.md` and `glossary.json` only for approved UI terms, preserving the existing tone.
- **Acceptance:** no product redesign or gameplay code diff, relevant documentation/validation checks pass, owner reviews changed governance and conflicts.

## PR 1 - proficiency model (after owner signs off the proposed math)

- Introduce explicit `SkillEvidence`/mastery component under the reusable maths API. Keep question generation, evidence updates and adaptive question selection separable.
- Propose a mathematical update function in a short design note with test trajectories: two matched-difficulty successes approximate original leveling; above-level success accelerates; high-level failures are lower penalty; below-level failure may immediately decrease; mathematical assist lowers credit; L6-L7 diminishing returns.
- Distinguish question difficulty (0-5) from displayed mastery (1-7), from Paper/calculator policy and from player XP.
- Preserve cell histories, misconception records, stable skill IDs and migration from old saves. Document the no-attempt confidence state and multi-skill evidence.
- **Acceptance:** proof with deterministic tests and simulated learners showing the intended progression, course eligibility and no false course-specific duplicate skill mastery. Academic `/?study` still works as a consumer of the same maths interface.

## PR 2 - complete an ordinary run's lifecycle

- Serialize one **active** run state; resume it exactly after app close, navigation and device suspension. Verify `run.quit()`/back-button semantics before removing or changing them. Earned Scrap and secured achievements must not be lost.
- Move voluntary course switching into Player Settings. Out-of-syllabus locations become inert map scenery with no invitation to switch courses at that location.
- Add skill-first, five-topic avatar Mastery Dashboard, with drilldown, 'Not Yet Attempted', explainers and location shortcuts between runs.
- **Acceptance:** crash/relaunch and save-migration tests, course-filtered location accessibility, no mid-run class switch or bounty-board access.

## PR 3 - shared encounters, status effects and writer boundaries (approved framework, minimal vertical slice)

- Inventory current `bosses.json`, generic enemy tiers, named miniboss/boss scenes, creatures, robots, traps, Explore/Puzzle/Combat events, missing/duplicate art and voice, statefulness and completed maths. See `docs/implementation/ENCOUNTER-AND-BOSS-AUDIT.md`; **reverify the prior figures against latest HEAD**.
- Show where the current encounter / combat / run code can express reusable objectives and phases. Propose a minimal compatibility-preserving `Encounter`/`Status` contract using current classes; `docs/implementation/ENCOUNTER-CONTRACT-PROPOSAL.md` is **not prescriptive code**.
- Implement and test **one existing combat encounter, one non-villain hazard/repair and one multi-phase encounter** through common mechanics before bulk content work. Statuses should tick after each resolved question, may persist across encounters until cured/recovered, and have per-effect stacking/caps/resistances. The actual effect numbers, content choices and complicated timing need owner review.
- Model narrative flags separately from skill mastery, with three-beat regional stories, event-based eligibility and fail-forward. Verify that strong students can reach the narrative beats quickly without auto-completing them through Thunderdome mastery. A regional story climax is **not** automatically the recurring mile boss.
- Present named villains as worth defeating and other major events as visually distinctive but not voice-heavy. **No wholesale rewrite, new item-inventory architecture, or mass VO production.**
- **Acceptance:** deterministic save/restore/stack/tick tests; student solves actual course-filtered maths in all three representative encounters; code reuse demonstrated; owner signs off first story arc and content tone.


## PR 4 - regional milestone and personal best (requires owner-approved D-02 and D-03)

- Owner approves which boss ends a region's story, how existing floors interact with that milestone and exactly what 'continue for endless' means.
- Implement one region as a vertical slice first: boss victory persists, finish-or-continue choice, accurate scoring, personal bests and reward safety after later death. Test for mathematical score not being bought through assists.
- Then replicate this through all five AA SL zones, using their existing thematic map and mathematics IDs. No cross-zone prerequisites. Within-zone prerequisite links must be owner approved before activation.
- **Acceptance:** one region's complete player journey approved before mass rollout; later death cannot revoke victory; PBs reflect mathematically comparable configurations.

## PR 5 - Thunderdome and the economy (approved features only)

- Keep common `MathsEngine`, but separate Thunderdome selection policy. Exhibit topic selection, fixed floor at run start, weighted probabilistic topic mixing, progressively harder bosses and no guaranteed rotation.
- Introduce approved **Boss Rush** within Thunderdome only after owner reviews unlock/fee/reward values; no new third format inferred from the existing 'Endurance/Gauntlet' text.
- Character XP and tree system with three independent avatars and account-wide once-only accolades; simulate late-avatar leveling. Bazaar, travelling merchants and items through common modifiers. Distinguish mathematical assists from combat buffs in scoring and mastery updates. **Use the existing inventory model.** Do not implement a suggested separate stash/limited run bag/quick bar without new approval.
- Add probability-tested Raider Attention as approved, visually quiet mechanic with repeatable fleeing boss and exclusive drops. Add defeated-region villain appearances as an eligible Thunderdome boss pool once story flag mechanics are sound; these are optional probabilistic encounters, not compulsory gates.
- **Acceptance:** scenario/economy simulations and tests. Do not make item buying a substitute for solving maths. No real-money gambling.

## PR 6 - AA SL release review

- For each of the five zones report: all eligible AA SL granular skills -> representative structures across 0-5 question difficulty -> independent mathematical verification and human signoff -> required narrated explainers scripted/rendered/signed off/accessible -> **event-driven story arc with satisfying narrative climax (usually a named villain), alongside non-villain major encounters** -> varied enemies/hazards -> consistent bosses/assets/essential voice/music/sound/accessibility -> live device playtest.
- Cross-check the live Questions/Types/Situations cells against the separate question bank; avoid reproducing source exam questions or unsupported copyright claims.
- Review the connected explainer/player build, not just `explainers.json` mapping, and ensure a student can open learning help before first failure.
- **Acceptance:** a green release gate and observed successful class test, not '286/286 playable' alone.

## Agent behaviour contract

- One PR / subsystem boundary at a time. No unapproved feature branches, side game modes, extra accounts or secondary curriculum products.
- Clearly distinguish **observed facts**, **owner-accepted decisions**, **proposals** and **unknowns** in updates. If uncertain, ask one precise question before altering game semantics.
- Any new framework or dependency requires explicit justification and review; do not refactor for novelty.
- Existing tests may pass while intended behavior is wrong. Add acceptance tests corresponding to ADR cases. Run the repository's existing test and seed-sweep commands before claiming ready.
- CI passing does not imply art consistency, mathematical pedagogy, narration quality or lesson accessibility. Maintain separate human review gates.
- Do not close a GitHub issue merely because documentation has been drafted or one component exists. Link the actual acceptance evidence.

## First owner decision when narrative implementation is ready

**How should the existing recurring mile/floor bosses connect to a three-beat, event-driven regional storyline and its permanent completion milestone?** After surveying existing bosses/scenes, provide **2-3 smallest viable mapping options**; recommend one and present the first region's suggested introductory villain encounter, complication/escape and climactic fight. Avoid a full quest rewrite and do not implement a guess. The owner has approved separate narrative and mastery tracks, recurring/branching bosses and environmental encounter variety, **not the precise boss-to-region mapping**.

## Additional discipline for content generation

- Existing `bosses.json` reportedly contains 13 named bosses + 13 minibosses, with Functions overrepresented. **This is a prior unverified source snapshot, not a current count or proof of 26 finished fights.** Inventory definitions *and* scenes, art, voice, maths, state flags, accessibility and playtest evidence first.
- Add enough content to give each of five AA SL zones a coherent adventure and enough varied ordinary encounters. **Do not equate 'enough' with a fixed quota of humanoid bosses or voice lines.** A survival hazard, scorpion, robot, mech or repair scene can fill an encounter role if it exercises correct mathematics.
- Approved design structure is broader than approved content list: specific sandstorms, mechs, poison damage values, vehicle shields and Rage Serum are **pitches**. Track accepted vs proposed in `docs/DECISION-REGISTER.md`.
- Reverify current asset completeness and Math engine mappings before adding branches to existing content. Protect future course eligibility and deterministic question behavior.
- Keep the owner's request for oversight realistic: small PRs, limited concurrent coding agents, regular results-based check-ins; no 'finished' status without tests and actual QA evidence.
