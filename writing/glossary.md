# Glossary

Every game term a player reads, and the one wording we use for it. Written on FAL-1032 for GitHub #203 and #186. Owned by Writer. If you need a new term, or want to change one, raise it on a task. Don't make one up in the code.

Reconciled 2026-11-24: this remains the exact player-copy source, with `glossary.json` enforcing current strings. [The domain glossary](../docs/DOMAIN-GLOSSARY.md) and [ADR-0002](../docs/adr/0002-curriculum-question-mastery.md) define the accepted target. Current question “level” is difficulty 0–5; future skill mastery is a separate 1–7 scale with “Not Yet Attempted” outside it. Paper/calculator policy is independent of both. The older Paper 1/level 3 and Paper 2/level 4 examples below describe current catalogue conventions, not a new authoring requirement. Current mile-boss “Cleared” is not proof of the future permanent regional story victory. Do not add unbuilt mastery/Thunderdome terms to the runtime string contract as though those features were shipped.

Rules from #203 and `TONE.md`:

- **Clear first, in-world second.** Maths words stay exact and plain. Flavour goes in the chrome around them: titles, banners, enemy names, Bazaar chatter.
- **Call each place by its name.** The player never reads "island", "location", "region" or "area". Write "Signal Tower", "Quadratics", "the Thunderdome".
- **One word per thing.** A term on this page is spelled and capitalised the same on every screen.

The banned and replaced words are also in [`glossary.json`](glossary.json), with patterns, so a test can check the UI strings against them (#203, "Deliverables"). Every change to the banned list goes in both files.

## Words for docs and code

These are the words for docs, comments and code. Players never read them.

| Docs word | Means | The player reads |
|---|---|---|
| **zone** | One of the five big places on the main map: Scrap Fields, Signal Tower, Dry Flats, Radio Spires, Engine Core. Older code and save keys say `island`; leave those names alone (#203: no migration). | The zone's name |
| **region** | One topic inside a zone, such as `quadratics`. | The topic's name, or "topic" |
| **floor** | One stage of a run (`run.floor_no`, `Tuning.FIGHTS_PER_FLOOR`). | **mile** |
| **fight** (in code, `run.fight`) | One of the ten stops on a mile, whether it holds an enemy or a job. | **stop** |
| **cell** | One type × unknown × representation × angle, the unit coverage counts. | "different questions" |
| **exam type / extension type** | A type's `source`. | "exam question" / "training" |
| **miss** | A wrong answer or a timeout. | "wrong answer", "time's up" |

## Places

Each place has one spelling. Use "the" only where the table does.

| Wording | What it is | Notes |
|---|---|---|
| **The Wasteland** | The main map, the overworld. | Title of the map screen, and the label of every back button that goes to it: **◂ The Wasteland**. Never "world map", "overworld" or "map" in what the player reads. |
| **Scrap Fields** | The algebra zone ("Numbers and algebra"). | In a sentence: "the Scrap Fields". |
| **Signal Tower** | The functions zone. | "the Signal Tower" |
| **Dry Flats** | The geometry and trigonometry zone. | "the Dry Flats" |
| **Radio Spires** | The statistics and probability zone. | "the Radio Spires" |
| **Engine Core** | The calculus zone. | "the Engine Core". The only player-facing "Engine". |
| **Thunderdome** | The arena that mixes every topic from every zone. | "the Thunderdome" |
| **Bazaar** | The market where you spend Scrap. | "the Bazaar" |
| **Relic Library** | The lessons building on the main map. Not open yet. | Its locked line: "Closed for now: lessons coming". |
| **Relic device** | The locked spot on each zone's board where lessons will go. | Its locked line: "Closed for now: lessons coming". |
| **topic** | A region, as the player sees it. Show its name (Quadratics, Lines, Integration). | Use "topic" only where a sentence needs a noun: "This topic opens as soon as its questions are built." |
| **All topics** | The run in the middle of each zone's board that mixes all of that zone's topics. | Was "All regions". |
| **Title** | The title screen. | Back button from the main map: **◂ Title**. |

## A run

| Wording | Means | Use it like this | Don't write |
|---|---|---|---|
| **run** | One trip out from a topic, from your starting mile until you quit or reach 0 HP. | "Start a run at mile 1", "Run over" | game, round, attempt |
| **mile** | One stage of a run: ten stops, with a mini-boss at stop 5 and a boss at stop 10. Beat a mile's boss and later runs can start on the next mile. Explained in one line on the "Pick your starting mile" screen. | "Mile 2", "Furthest mile: 3", "Mile 1 cleared", "Next mile" | floor, level, stage, tier |
| **stop** | One of the ten things on a mile: a fight, or a job such as a stuck cart or a locked hatch. | "stop 3 of 10", "Next stop", "stops cleared" | fight 3 of 10 (on the counter) |
| **fight** | A stop with an enemy in it. | "Hit! The Raider takes 1 damage" | battle, encounter (an encounter is a talking event) |
| **job** | A stop with a thing to work on instead of an enemy (the prop's name shows: "Stuck cart"). | Its own lines: "It shifts.", "The cart rolls free." | puzzle (in what the player reads) |
| **mini-boss** | The enemy at stop 5. Its question comes in parts. | "Mini-boss beaten" | |
| **boss** | The enemy at stop 10. Its question comes in parts. | "Mile 2 boss beaten" | |
| **part (a), (b), (c)** | One part of a boss's question, as on a paper. | "part (b) of 3" | step, phase |
| **Furthest mile** | The deepest mile you've reached on this topic. | "Furthest mile: 3", "Furthest mile: no runs yet" | Best floor |
| **You're down** | The run ended at 0 HP. | Summary heading | You died, Game over |
| **Run over** | You quit the run. | Summary heading | |

## Health, damage and the clock

| Wording | Means | Use it like this | Don't write |
|---|---|---|---|
| **HP** | Your health, or an enemy's. Runs start at 100, plus upgrades. 0 ends the run. | "HP 80/100", "Max HP +10" | health, life, lives |
| **damage** | HP lost. Always "you take N damage", never a bare minus. | "Wrong answer. You take 20 damage." | "−20 HP", "a miss costs" |
| **hit** | A right answer. On a fight it takes one hit off the enemy. | "Hit! The Scavenger takes 1 damage · +40 Scrap" | |
| **late hit** | A right answer in the red end of the timer. It still lands, but you take a quarter of the enemy's damage and get less Scrap. | "Late hit! It lands, but you take 5 damage" | |
| **glancing hit** | The right value in the wrong form (for example not to 3 s.f.). Half a hit, half the Scrap. | "Glancing hit: half damage." | |
| **wrong answer** | Not right. You take the enemy's damage and see the worked solution. | "Wrong answer. You take 20 damage." | miss, missed, fail |
| **Time's up** | The timer ran out. You take the enemy's damage plus 10. | "Time's up. You take 30 damage." | timeout |
| **timer** | The bar that runs down on each question: green, then orange, then red. | "The timer keeps running." | clock (fine in a sentence: "the clock keeps running") |

## Scrap and the Bazaar

| Wording | Means | Notes |
|---|---|---|
| **Scrap** | The money. Every right answer earns some, and every run banks what it earned, even a short one. Capital S. | "Scrap: 120", "+40 Scrap", "Scrap in the bank: 300". Never "coins", "gold" or "points". |
| **upgrade** | Bought once and kept on every run (Max HP +10, Lifeline +1). | Bazaar section "Upgrades". |
| **perk** | Bought for your next run only. Used up when that run starts. | "Ready for your next run: Field Watch". |
| **name plate** | The badge with your callsign and HP bar. Frames and colours are looks only. | "Wear", "Worn" |

## Lifelines

Three, one charge of each per run unless the Bazaar adds more. The names are fixed. Write them the same way on the fight screen, in the Bazaar and on the first-run cards.

| Wording | What it does | Notes |
|---|---|---|
| **50-50** | Takes away two wrong choices. Only on a question with choices. | A hyphen, no spaces, no slash. |
| **Hint** | Shows the first step of the worked solution. | |
| **Freeze** | Stops the timer for 15 seconds. | Was "Time Freeze" in the Bazaar (`engine/bazaar.gd:19`). Use "Freeze" everywhere. |

## Answering

| Wording | Means | Notes |
|---|---|---|
| **Lock in** | The submit button. The same verb on every question: fights, jobs, bosses and Practice. | Replaces "Attack", "Check", "Thump", "Pry", "Dig" and the other job verbs (#203: "the same verb everywhere"). A job's flavour stays in its result lines ("Something rattles loose."). The study screen (`?study`) keeps "Mark my answer": it's plain on purpose. |
| **fraction key** | The keypad key drawn as two boxes over a bar. Type the top, tap it, type the bottom. | "the fraction key" |
| **Calculator** | The button on a Paper 2 question. Opening it doesn't stop the timer. | The calculator's own title is "Field Calc". |
| **Paper 1 · No calculator** | The badge on a Paper 1 question. | Same size and weight as the Calculator button, not small grey text. |
| **Paper 2 · Calculator** | The button on a Paper 2 question. | |
| **worked solution** | The full working, shown after a wrong answer or Time's up. | |
| **Another way** | A follow-up: the same question again, by a named method, for bonus Scrap. | |
| **Next question** / **Next part** / **Next stop** / **Next mile** | The button after a result. | "Next stop" replaces both "Next fight" and "Walk on". |

## Questions: kind, level and mile

These three are separate, and a line that shows two of them has to keep them apart.

- **Kind** is where a question comes from.
- **Level** is how hard one question is.
- **Mile** is how far into a run you are. Deeper miles serve higher levels.

| Wording | Means | Notes |
|---|---|---|
| **Exam question** | A form that appears on real exam papers for your course (an exam type, or an exam-style unknown). | Shown in the question header: "Exam question · level 3 of 5". |
| **Training** | Anything the exam leaves out: concept checks, warm-ups, link questions. | Header: "Training · concept check", "Training · warm-up", "Training · link question", or just "Training". |
| **concept check** | A probe that asks what an idea means, not to work out a number. | Was "concept" in the header. |
| **warm-up** | Level 0 prior learning: the algebra the course assumes (factorising, rearranging, fractions, surds). | |
| **link question** | A question that joins two topics. | |
| **level N of 5** | How hard a question is, 0 to 5. 0: warm-up. 1: recall, one step. 2: a method in a few steps. 3: Paper 1 standard. 4: Paper 2 standard. 5: long, joined-up questions. | Always "level", lower case, with "of 5" in the header. Never used for miles, enemies or Bazaar upgrades. On the mile picker: "questions at levels 0 to 2". |
| **Exam questions only** / **Exam questions plus training** | The two-way choice that sets which kinds you're served. Help line: "Training adds concept checks and warm-ups you won't see on a paper." | A new student starts on **Exam questions plus training** (the save's `exam_only: false`, the default today). It is not a difficulty setting. Was "Exam-style only: on/off". |
| **course** | Your maths course: AA SL, AA HL, AI SL or AI HL. | Full names: Analysis and Approaches SL/HL, Applications and Interpretation SL/HL. |
| **Paper 1**, **Paper 2** | The exam paper a question is styled on: Paper 1 without a calculator, Paper 2 with one. | |

## Progress on a topic

| Wording | Means | Was |
|---|---|---|
| **Accuracy** | Right answers out of all answers on this topic. "Accuracy: 80% · 8 of 10 right" | (kept) |
| **Different questions tried** | How many of the topic's different questions (cells) you've seen at least once. "Different questions tried: 12 of 132" | Coverage: 12 of 132 checked |
| **Skills to work on** | The three skills with your lowest accuracy, once you've answered a skill 3 times. | Weakest skills |
| **Spark's pick** | The topic Spark suggests next. A suggestion, never a lock. | SPARK's pick |
| **Cleared** | You've beaten this topic's boss. | |
| **Not tried yet** | No answers here. | |
| **Coming soon** | No questions built for this topic yet (or for your course). | |

## Modes and menus

| Wording | Means | Notes |
|---|---|---|
| **Play** | Title button: opens The Wasteland. | |
| **Practice** | Questions with no timer and no damage, picked where you need them most. Always shown with its line: "Practice · no timer, no damage". | Title screen and topic screen. |
| **Question explorer** | The developer tool now called "Engine" on the title screen. Hidden from students (#186). If a teacher link shows it, this is its name. | Never "Engine". |
| **Credits**, **Sound**, **Close** | (kept) | |

## Characters on these screens

- **Spark**: the robot companion. In UI chrome write "Spark". SPEC and the code say SPARK; the voice sheets use both.
- **you / `{callsign}`**: the player. Never gendered (`writing/voice-sheets.md`).
- Enemies by name: Scavenger, Raider, Enforcer, Warlord, Overseer. Bosses by name. Show the rank (Recruit, Operative, Sergeant, Commander, Overseer) beside the name in place of the D1–D5 tier code.

## Banned and replaced

`glossary.json` has the same list with patterns. In short:

| Banned | Use | Why |
|---|---|---|
| island, islands | the place's name; "zone" in docs | There's no water (#203). |
| location, area (for a place) | the place's name | #203: no generic swap. |
| region (player-facing) | the topic's name, or "topic" | A docs word. |
| world map, overworld, Map (as a label) | The Wasteland | One name for the main map (#203). |
| floor, Best floor | mile, Furthest mile | A tower word in a desert (#203). |
| fight N of 10 (counter), Walk on, Next fight | stop N of 10, Next stop | One word for a run's ten stages. |
| Exam-style, exam style | Exam question / Exam questions only / Exam questions plus training | Students didn't follow it (#203). |
| Coverage, checked (as a count) | Different questions tried | Say what's counted. |
| Weakest skills | Skills to work on | Kinder, and it says what to do. |
| Missed, −N HP | Wrong answer. You take N damage. | |
| a miss costs | wrong answer: N damage | |
| maths engine, lessons later | Closed for now: lessons coming | Developer wording (#186). |
| Engine (button) | hidden, or Question explorer | #186. "Engine Core" stays. |
| Time Freeze | Freeze | One name per lifeline. |
| Attack, Check, Thump and the other job verbs (submit button) | Lock in | One submit verb (#203). |
| D1–D5 (enemy tier) | the enemy's rank | Unexplained code. |
| All regions | All topics | |
