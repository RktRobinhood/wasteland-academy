# Domain glossary - shared language for humans and AI agents

Status: **Accepted terms unless explicitly marked OPEN/PROPOSED**. Reviewed 2026-11-21.

**Purpose:** define what each word means *for product design, data models and tests*. For the exact language displayed to players, preserve the existing [`writing/glossary.md`](../writing/glossary.md) and its tested `glossary.json`. Do not replace player copy from this file automatically.

Adopted 2026-11-24. These definitions describe the accepted target, not proof that code implements it; see the [current audit](ALIGNMENT-AUDIT-2026-11-24.md). Optional explainers retain #215's approved interactive direction and may reuse the existing lesson player. The Relic distinction does not require duplicate players/content or a new mode.

## 1. Mathematical content and evidence

| Term | Exact meaning | Not this |
|---|---|---|
| **IB course / syllabus selection** | AA SL, AA HL, AI SL, or AI HL. Hard constraint on eligible questions, encounters and enabled locations. Changeable in Player Settings. | A character class; a difficulty preference. |
| **Syllabus topic** | One of five official large content areas: Number and Algebra, Functions, Geometry and Trigonometry, Statistics and Probability, Calculus. | A mastery score. |
| **Syllabus subtopic / official code** | An IB mapping entry such as `SL5.6`; internal curriculum metadata and auditability. | A necessary player-facing label. |
| **Skill** | The smallest useful, stable mathematical capability tracked for mastery (for example Chain Rule, Product Rule, Quotient Rule). A skill may be finer than an IB subtopic. | A whole topic, a single question, or a class skill-tree perk. |
| **Skill ID** | Stable canonical identifier in the existing curriculum mapping. Reused by questions, mastery, explainers and bounties; overlaps share identity across courses. | A course-specific duplicate ID, a cosmetic name. |
| **Question type / template family** | A reusable pattern of *mathematical reasoning* represented in the question catalogue. Its generation recipe can make many instances. | A single generated question, or the same problem with new numbers. |
| **Structural variant** | A meaningful change of unknown, reasoning path, representation, conditions, application or linkage. E.g. differentiate versus determine a parameter or find a tangent. | Merely altering coefficients or the random seed. |
| **Situation / recipe** | Engine construction of mathematically consistent givens and derived quantities. Several question views may share one situation. | A level or enemy encounter. |
| **View / coverage cell** | An engine request configuration (type x unknown x representation x method/angle, subject to format and eligibility). Used for fine-grained generated-question coverage. | A distinct skill; a guaranteed new mathematical structure. |
| **Question instance** | Concrete, seeded realization of a valid template and view: prompt, answer, marking, hints and solution. | A separate curriculum objective. |
| **Difficulty** | Intrinsic demand of the particular question as an assessment task; existing catalogue uses 0-5 (0 prior-learning; 1-5 increasing). Different from a player's 1-7 mastery. | Which exam paper it comes from by itself. |
| **Exam-standard** | Degree of proficiency expected in authentic IB examination work. A performance benchmark reached around mastery levels 4-5. | An exam-style screen or a separate game mode. |
| **Exam-style / exam type** | A question structure rooted in exam-question patterns; may be used in ordinary encounters or multi-part bosses. | Necessarily the hardest question, or 'exam ready' proficiency. |
| **Paper/calculator policy** | Whether tools are permitted for the selected IB course and question context. Must be modeled separately from difficulty and question format. | Level 3 vs level 4 by definition. |
| **Question coverage** | Every selected syllabus skill has a sufficient *representative range* of verified question structures, scaffolds and difficulty, including exam-standard performance. Requires evidence of breadth and correctness. | One generator per skill; 100% 'playable' count; millions of seed variations. |
| **Playable coverage** | An existing generated metric: a built generator can produce at least one valid question tagged to a skill. | Educational completeness or human pedagogical approval. |
| **Explainer** | Optional, skill-linked instruction, planned to be fully narrated and visually coherent. Available from the beginning of a relevant region and discoverable via skill/profile/bounty links. | A skill gate, or simply a planned entry in `explainers.json`. |
| **Explainer access point** | Any skill/profile/bounty/zone link that opens a completed explanatory clip, available without playing first. | A mandatory prerequisite, or an unapproved Relic lesson. |
| **Relic playable lesson** | A separate interactive tutorial/story experience with its own prototype player and learning activities. May be staged separately, but must not gate access to the ordinary narrated explainer. | A mere voice clip; permission to introduce an unapproved new game mode. |
| **Mastery** | One persistent, evidence-weighted proficiency value per *skill*, shared by all courses and game modes. Can rise or fall. | XP, character level, scrap, high score, or a one-time achievement. |
| **Mastery level** | Student-facing seven-stage proficiency scale, including a 'not yet attempted' state outside the seven. L4-5 denote Exam Ready; L6-7 award themed skill-specific titles. | The question's 0-5 difficulty tier. |
| **Weighted mastery evidence** | Answer result weighted by question difficulty relative to current mastery, any mathematical assist, and performance. Above-level success gives stronger positive evidence and lower penalty for failure; below-level failure can cause an immediate downgrade. | Original two-correct/two-wrong streak rule (superseded). |
| **Mastery maintenance** | Revisiting known skills to keep proficiency current. Mastery can decrease as new failures provide evidence; no artificial requirement to span multiple runs to attain L7. | A forced daily login or an unapproved timed decay algorithm. |
| **Not yet attempted** | The player has no demonstrated evidence for a syllabus skill. It is *not* equal to zero proficiency. | A failing mark, or a lock on studying that skill. |
| **Difficulty floor** | In Thunderdome only, a fixed-for-run lower bound on presented question difficulty based on the average of **attempted** skills; skills above that mean keep their higher individual starting level. Unattempted skills use the mean for selection but are not assigned mastery. | A forced minimum proficiency value in the save. |
| **Adaptive selection** | Choosing eligible questions with regard to individual skill mastery, variety, meaningful structures, recent exposure, topic weights and game context. | Question generation or mastery calculation itself. |

### Important taxonomy rule

Keep the current skill IDs and syllabus mappings unless there is a documented migration need. `curriculum/COVERAGE.md` currently reports **62 AA SL Functions skills** and **286 AA SL skills overall**; these figures are not a count of question templates. `curriculum/QUESTION_TYPES.md` and `PEDAGOGY_GAPS.md` describe type families and richer views. Never report those counts interchangeably.

### 7-stage display (descriptors are illustrative below level 4)

- State 0: **Not Yet Attempted** (no evidence, not a mastery level).
- Level 1: **Foundations**; Level 2: **Developing**; Level 3: **Applying**.
- Levels 4 and 5: **Exam Ready**, with two degrees of strength/consistency.
- Levels 6 and 7: **Wasteland-themed skill-specific titles** (e.g., the Quadratics skill's title is not automatically used for Integration). Exact names and balancing are creative content, not a new progression mechanism.
- Mastery is displayed as a segmented/volume-style bar; grouped under five syllabus topics, then student-friendly subdivisions (e.g., Differential Calculus), then individual skills. Official numbered codes remain in metadata, not the default screen.

## 2. Game geography and advancement

| Term | Exact meaning | Boundary |
|---|---|---|
| **The Wasteland / overworld** | One canonical world map, shared across courses. Five major syllabus **zones** are accessible from day one. | No cross-zone prerequisite gates. |
| **Zone** (docs/code) | One of five broad mapped places: Scrap Fields, Signal Tower, Dry Flats, Radio Spires, Engine Core. Player-facing language uses their proper names. | 'Island' is a legacy internal identifier, not new UI text. |
| **Region / topic location** | A thematic sub-map/place within a zone, associated with a stable mathematical topic; existing ID/name/art retained. | A location should not be repurposed arbitrarily for unrelated mathematics across courses. |
| **Inactive location** | Visible map scenery but non-interactive because selected IB course excludes its content. | A clickable 'Beyond your syllabus' teaser. |
| **Within-zone prerequisite** | A specific mathematical skill requirement for advancing to a later location *inside the same zone*; visibly signposted and unlockable by mastery from any game mode. | Finishing a different large syllabus zone. |
| **Unlock** | Permanent player achievement of sufficient prerequisite evidence. Once open, stays open even if mastery falls. | Proof of permanently maintained mastery. |
| **Test-Out challenge** | Shorter, harder assessment to demonstrate a *within-zone prerequisite* and unlock a dependent location. Available only where a prerequisite would block progress; retries allowed with genuine variation. | A regional narrative win or high score. |
| **Regional victory** | Completing the regional narrative milestone by defeating its boss. Persists even if the player continues and later dies. | Full mathematical mastery or a Test-Out pass. |
| **Endless continuation** | Optional play after regional boss victory to push the personal high score and practise more questions. The story victory is already secure. | A new mode requiring its own world map. |
| **Bounty** | Temporary marker of repeated struggle with a granular mathematical skill. It appears in a relevant zone/region **regardless of where the struggle occurred**. | An automatic new quest type, a forced question queue, a lifetime achievement. |
| **Bounty Board** | Between-run interface showing **active bounties only**, links to the relevant explainer ('Know Your Enemy') and fast travel to practice. Completed bounties disappear and can reappear after later struggle. | Accessible during an active run, or an archive of all past bounties. |
| **Bounty resolution** | Meaningful improvement demonstrated during normal play in the relevant region, including sustained progress and an in-world accomplishment. | One easy correct answer, merely revisiting, or compulsory extra mechanics. |

## 3. Runs, scores and rewards

| Term | Exact meaning | Boundary |
|---|---|---|
| **Run** | One continuous roguelike session with an elected character, HP, inventory, seed and progress. Exactly one active run is persisted and resumed after closing the app. | A disposable session that ends on app exit. |
| **Mile / stop** | Existing exact player-facing terms from `writing/glossary.md`: mile = run floor; stop = encounter stage. | Do not rename save keys/IDs to match copy. |
| **Boss / miniboss** | A demanding encounter that can involve phases and linked exam-style mathematics. **Role matters:** a repeatable mile boss is not automatically a region-closing narrative villain. The approved regional story boss triggers a finish-or-continue milestone. | A requirement to master all skills first; always a humanoid villain. |
| **Thunderdome Exhibition** | Accessible main survival/roguelike Thunderdome format; player selects eligible topics; difficulty escalates quickly. Free or low-cost entry. | Forced full-syllabus exam or a chapter gate. |
| **Thunderdome Boss Rush** | Accepted higher-stakes format, unlocked permanently by an Exhibition milestone. Scrap entry fee, escalating multi-phase bosses, topic selection, greater rewards for breadth. | Real-money gambling, an unrelated new game mode. |
| **Controlled probability** | Encounter topic weights change based on recent exposure and coverage, but there is *no guaranteed topic rotation*. | Pure unweighted random or a deterministic syllabus checklist. |
| **Personal best (PB)** | A player's own highest performance for a mathematically comparable challenge/pool. Arcade-style celebration on improvement. No peer leaderboard. | Character XP, mathematical mastery, or a competition with classmates. |
| **Score** | Performance measurement favoring encounters completed, genuine question difficulty and accuracy; reduced bonus for mathematical assists. Speed is not the chief objective. | Scrap, XP, or an advantage purchasable without mathematical competence. |
| **Scrap** | Shared, permanent in-game currency. Earned Scrap remains after death. Pays for cosmetics, upgrades, consumables, entry fees and modest respecs. | Score, XP, real money. |
| **Character XP** | Earned **only by the actively played character**: limited from everyday play, more from genuine personal improvements or account accolades. Grows along a steep curve. | Mastery evidence or currency. |
| **Player accolade** | Account-wide first-time accomplishment, e.g. first region/boss victory or a new one-time mastery threshold. Bonus character XP granted once to the active character; alts cannot re-claim the same accolade. | Replayable per-character boss farm. |
| **Character / class** | One of Tilly (Scout), Banjo (Ranger), and cyber-dog (Tinker), each independently leveled. Switch between runs only. | Selected IB course. |
| **Class skill tree** | Three branches per character (nine total). Skill points allow specialization or mixing; max level cannot finish all branches. Modest-cost respecs. | A mathematics skill ID. |
| **Mathematical assist** | Item or class effect that makes answering a question easier: hint, 50/50, freeze, extra time, reveal solution step. Compatible only with suitable question formats. Reduces score bonus and mastery evidence accordingly. | Combat buff that only changes HP/damage. |
| **Combat modifier** | Healing, damage, armor etc. Alters survival or encounter outcome but not the mathematical question. Does not automatically reduce maths-score bonus. | A mathematical assist. |
| **Bazaar** | Stable main shop offering a broad collection of permanent and consumable options, cosmetics and modifiers. | Traveling merchant random inventory. |
| **Travelling merchant** | Rare/variable in-run encounter with small, possibly regional inventory and rarer items; limited overlap with Bazaar. | A separate economy. |
| **Raider Attention** | Probabilistic risk from **conspicuous/flamboyant item use or spending**, not merely needing help. Meter appears once attention is meaningful; increasing attention raises encounter probability. Defeating recurring raider boss resets attention; boss may drop rare/exclusive items. | Deterministic punishment for incorrect answers or a new game mode. |
| **Active run save** | Serialized snapshot sufficient to restore the *same* character, location, question/seed, inventory, HP, timer behavior and run progress across sessions. | Just banking earned Scrap or remembering the last region. |

## 4. Encounter framework, status effects and narrative

| Term | Exact meaning | Not this |
|---|---|---|
| **Encounter** | A mathematical question-driven gameplay event with an objective, outcome and possible setbacks: combat, survival, repair, disarm, escape, trap, puzzle or hazard. Uses the same underlying question system. | A separate math engine or necessarily an enemy fight. |
| **Encounter role** | Ordinary encounter, miniboss, regional story villain, major environmental event, repeatable raider boss, native arena boss, unlocked arena appearance. | A new game mode for each kind. |
| **Encounter objective** | What the player is trying to accomplish (defeat, survive, repair, build shelter, disarm, escape). | How the math problem is generated. |
| **Encounter tags** | Compatible descriptors such as creature, robot, armored, venomous, vehicle, raider or hazard that can interact with items/class modifiers. Exact tag schema to review against Godot first. | Automatically approved new enemy content. |
| **Encounter phase** | An ordered/conditional stage of an encounter. A mech might lose its chassis, a villain might escape, a repair might enter a critical phase. | A separate independent game mode. |
| **Status effect** | A condition on a character or encounter that persists between encounters for the current run until recovery/cure; ticks after each resolved mathematics question. | Automatically cleared at the end of an encounter. |
| **Question tick** | One resolved question advances ongoing effects and offers an eligible natural-recovery check, whether the answer is right or wrong. Precise timing for timeouts/interruptions is open. | Per-frame or per-button tick. |
| **Stackable status** | Repeated instances add severity up to an effect-specific configurable cap (e.g. poison). | A rule forcing every condition to stack. |
| **Non-stackable state** | An effect applied as a single gameplay state, e.g. dazed, even if multiple sources try to apply it. | Infinite stacking of boolean conditions. |
| **Resistance / recovery** | Class, item or situational modifiers that reduce effect application/severity/damage or improve the odds of clearing it. | Guaranteed immunity unless explicitly defined. |
| **Modifier dial** | Tested, compatible encounter/question settings: timers, question-condition options, damage, protection, effect odds, reward factors and encounter probabilities. | Bespoke code for each new item or creature. |
| **Narrative beat** | Story introduction, complication/escape, finale, or optional related event, with conditionally eligible progression. Approximately three meaningful beats form a useful minimum arc. | A compulsory fixed count of questions or linear content gate. |
| **Narrative flag** | Persisted game event evidence such as villain encountered, ambush survived, villain escaped, or climactic victory achieved; separate from maths mastery. | A duplicated skill mastery value. |
| **Regional story climax** | An owner-approved final confrontation requiring relevant narrative flags and some appropriate mathematical progression. Its win permanently completes that story. | Any repeatable boss at the end of an arbitrary mile. |
| **Villain boss** | A sufficiently unlikeable, memorable antagonist whose defeat feels rewarding. Can flee, return or branch based on combat outcomes. | Every sandstorm, robot or animal major encounter. |
| **Environmental major encounter** | Large-scale non-villain challenge such as a sandstorm, repair, radiation leak or trap, typically expressed through visual/sound design rather than long spoken scripts. | An excuse to add unrelated gameplay. |
| **Thunderdome unlocked boss** | After an approved regional narrative victory, the defeated antagonist can join Thunderdome's probabilistic eligible roster in a different arena context. | Immediate forced arena encounter or a new mode. |
| **Encounter status/authoring** | Distinct implementation facts: defined in data, assets exist, wired in Godot, mathematically verified, playtested and polished. | A named entry in `bosses.json` automatically means a finished playable boss. |

## 5. Documentation/process language

| Term | Exact meaning |
|---|---|
| **Accepted decision** | Owner confirmed. Preserve in ADR, do not reverse without explicit approval. |
| **Proposal** | Suggested mechanic/content, not permission to build. |
| **Unresolved** | Requires evidence, design question or balancing experiment before implementation. |
| **ADR** | Architecture Decision Record: context, decision, alternatives, consequences, testable implications and status. Not a task list. |
| **Acceptance criteria** | Observable conditions that let a reviewer verify an approved feature. Code existence alone is insufficient. |
| **Definition of classroom-ready** | Mathematics validity + representative skill coverage + working explainers + coherent five-zone gameplay + accessibility/playtest quality. |

## 6. Terms not yet numerically specified

Do **not** invent default values and describe them as agreed decisions: precise mastery update function and level thresholds, size of a 'substantially below mastery' error, syllabus-skill prerequisite threshold, story boss completion mechanics, score formula, personal-best comparison key, XP curve and max-level cap, Raider Attention probabilities, shop item prices, Thunderdome Boss Rush fee/prize schedule and unlock depth. These are **calibration and implementation proposals** requiring explicit review before shipping. Also open: effect stack caps, recovery chance, precise per-question tick ordering, boss/narrative event graphs, which formerly defeated villains join arena pools, and selected dialogue/VO scripts. The owner **deferred** rearchitecting the inventory/stash/quick bar. Individual sandstorm, mech, vehicle, scorpion and Rage Serum concepts are **illustrative candidates**, not approved content orders.

## Repository cross-reference

- Exact player copy: [`writing/glossary.md`](https://github.com/RktRobinhood/wasteland-academy/blob/main/writing/glossary.md).
- Syllabus and skill IDs: [`curriculum/README.md`](https://github.com/RktRobinhood/wasteland-academy/blob/main/curriculum/README.md).
- Engine terms and evidence shape: [`game/docs/MATHS-ENGINE.md`](https://github.com/RktRobinhood/wasteland-academy/blob/main/game/docs/MATHS-ENGINE.md).
- Type/seed/representation and current 0-5 question difficulty: [`game/docs/QUESTION-ENGINE.md`](https://github.com/RktRobinhood/wasteland-academy/blob/main/game/docs/QUESTION-ENGINE.md), [`curriculum/PEDAGOGY_GAPS.md`](https://github.com/RktRobinhood/wasteland-academy/blob/main/curriculum/PEDAGOGY_GAPS.md).
