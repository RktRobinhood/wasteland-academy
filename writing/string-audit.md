# String audit

Every player-facing string on the title, map, zone, topic, mile picker, fight, summary, Practice, Bazaar, settings and credits screens, with the wording to use. Written on FAL-1032 for GitHub #203 and #186, against [`glossary.md`](glossary.md) and `TONE.md`.

**Line numbers are for `main` at `f622af0`.** If a line has moved, find it by the "Now" text. `%d` and `%s` stay where they are unless the "Proposed" column moves them. `{zone}` means the zone's name from `ISLANDS[].name`, and `{topic}` means `Dungeon.region_name(id)`.

**Change** is one of:

- **text**: swap the string and nothing else.
- **logic**: the string depends on state the code doesn't have yet, or the code has to choose between wordings. The note says what's needed.
- **remove**: the string goes, with no replacement.
- **keep**: listed so the audit is complete. No change.

#203 says wording changes go in without sign-off. Matt comments afterwards on anything that reads wrong.

## Title screen: `game/scenes/main.tscn`, `game/ui/main.gd`

| # | Where | Now | Proposed | Change | Note |
|---|---|---|---|---|---|
| T1 | `main.tscn:53` | Wasteland Academy | Wasteland Academy | keep | |
| T2 | `main.tscn:62` | Same math. Different world. | Same maths. Different world. | text | Matt and the players write "maths". |
| T3 | `main.tscn:75` | Play | Play | keep | Opens The Wasteland. |
| T4 | `main.tscn:81` | Practice | Practice · no timer, no damage | text | #203 lists "Practice" as unclear. If the button is too narrow, put "No timer, no damage" on a small line under it. |
| T5 | `main.tscn:88` | Engine | (hidden) | remove | #186: hide the developer explorer behind a URL flag or teacher link. If it has to show somewhere, its name is "Question explorer". |
| T6 | `main.gd:130` | Credits | Credits | keep | |
| T7 | `main.gd:147` | Classic game | (hidden) | remove | The classic HTML game is removed for students (#197). |

## The Wasteland (main map): `game/ui/map.gd`

| # | Where | Now | Proposed | Change | Note |
|---|---|---|---|---|---|
| M1 | `map.gd:363` | The Wasteland (title) | The Wasteland | keep | |
| M2 | `map.gd:363` | Title (back button) | ◂ Title | text | Check the font has "◂" (U+25C2). If not, use "‹". The same goes for every "◂" below. |
| M3 | `map.gd:768` | Scrap: %d | Scrap: %d | keep | |
| M4 | `map.gd:775` | i.topic (Numbers and algebra, Functions …) | (same) | keep | The zone's card line under its name. |
| M5 | `map.gd:775` | Coming soon | Coming soon | keep | |
| M6 | `map.gd:776` | "%s: %s" (tooltip, name: topic) | (same) | keep | |
| M7 | `map.gd:782` | Locked (Thunderdome) | Locked | keep | |
| M8 | `map.gd:782` | Every island mixed | Questions from all over the Wasteland | text | Banned word (#203). |
| M9 | `map.gd:784` | Thunderdome: opens with a second island | Thunderdome: opens once two places are open | text | |
| M10 | `map.gd:87` | Opens after the maths engine | Closed for now: lessons coming | text | `RELIC_LIBRARY_LINE`. Developer wording (#186). |
| M11 | `map.gd:796` | %d Scrap (Bazaar card) | %d Scrap to spend | text | |
| M12 | `map.gd:798` | Bazaar · %d Scrap (tooltip) | Bazaar · %d Scrap to spend | text | |
| M13 | `map.gd:862` | · You are here | · You are here | keep | |

## A zone's board (Scrap Fields, Signal Tower …): `game/ui/map.gd`

| # | Where | Now | Proposed | Change | Note |
|---|---|---|---|---|---|
| Z1 | `map.gd:374` | World map (back button) | ◂ The Wasteland | text | #203: one name, including the back button. |
| Z2 | `map.gd:954` | {zone} (title) | {zone} | keep | |
| Z3 | `map.gd:1043` | Locked (Relic device card) | Closed for now | text | |
| Z4 | `map.gd:1043` | Locked · lessons later (tooltip) | Relic device: lessons coming | text | Developer wording (#186). |
| Z5 | `map.gd:1067` | Coming soon | Coming soon | keep | |
| Z6 | `map.gd:1070` | · SPARK's pick | · Spark's pick | text | Glossary: "Spark" in UI chrome. |
| Z7 | `map.gd:1072` | Not tried yet | Not tried yet | keep | |
| Z8 | `map.gd:1075` | Floor %d | Mile %d | text | Furthest mile on that topic. |
| Z9 | `map.gd:1077` | %d%% | %d%% right | text | A bare percentage reads as progress, not accuracy. |
| Z10 | `map.gd:1079` | Cleared | Cleared | keep | |
| Z11 | `dungeon.gd:24` | All regions | All topics | text | `ALL_NAME`. Shown as the middle spot's name and the topic screen's title. |
| Z12 | `dungeon.gd:27` | Thunderdome | Thunderdome | keep | |

## A topic's screen: `game/ui/map.gd`

| # | Where | Now | Proposed | Change | Note |
|---|---|---|---|---|---|
| R1 | `map.gd:1220` | Island (back button) | ◂ {zone} | logic | The zone's name, as in "◂ Signal Tower" (#203). The name is `ISLANDS[]` where `id == route.island`. |
| R2 | `map.gd:1220` | World map (Thunderdome's back button) | ◂ The Wasteland | text | |
| R3 | `map.gd:450` | Course | Your course | text | |
| R4 | `map.gd:458` | AA SL / AA HL / AI SL / AI HL (tooltip: the full name) | (same) | keep | |
| R5 | `map.gd:1239` | Coming soon | Coming soon | keep | |
| R6 | `map.gd:1245` | %s has no questions built here yet. Another course may: pick it above. | No %s questions here yet. Another course has some: pick it above. | text | `can_start(id)` with no course filter is true on this path, so another course does have questions. |
| R7 | `map.gd:1247` | This region's questions aren't built yet. It opens here as soon as they are. | No questions here yet. This topic opens as soon as they're built. | text | |
| R8 | `map.gd:1253` | Exam-style only: on / off (one toggle) | Two buttons in one group: **Exam questions only** · **Exam questions plus training** | logic | A `ButtonGroup` like the course row. "plus training" is pressed when `save.settings.exam_only` is false. A new save stays `exam_only: false`, so a new student starts on plus training (#203). |
| R9 | (new, under R8) | | Training adds concept checks and warm-ups you won't see on a paper. | logic | One line, `UiTheme.SMALL`, `UiTheme.DIM`. Use this wording exactly (#203). |
| R10 | `map.gd:1305` | Accuracy: %d%% · %d of %d right | Accuracy: %d%% · %d of %d right | keep | |
| R11 | `map.gd:1305` | Accuracy: no answers yet | Accuracy: no answers yet | keep | |
| R12 | `map.gd:1306` | Best floor: %d | Furthest mile: %d | text | |
| R13 | `map.gd:1306` | Best floor: no runs yet | Furthest mile: no runs yet | text | |
| R14 | `map.gd:1307` | Coverage: %d of %d checked | Different questions tried: %d of %d | text | Counts cells seen at least once (`MathsEngine.coverage`). |
| R15 | `map.gd:1320` | Weakest skills | Skills to work on | text | |
| R16 | `map.gd:1323` | None yet: a skill shows here after %d answers. | None yet. A skill shows here once you've answered it %d times. | text | `MIN_ATTEMPTS` (3) counts answers per skill, not answers in total. |
| R17 | `map.gd:1325` | • %s · %d%% of %d | • %s · %d%% right of %d | text | |
| R18 | `map.gd:1272` | Start floor 1 | Start a run at mile 1 | text | |
| R19 | `map.gd:1272` | Start at floor %d · floor %d boss beaten | Start at mile %d · mile %d boss beaten | text | |
| R20 | `map.gd:1281` | Practice | Practice · no timer, no damage | text | Same as T4. |

## Pick your starting mile: `game/ui/fight.gd` (`show_floor_select`)

| # | Where | Now | Proposed | Change | Note |
|---|---|---|---|---|---|
| F1 | `fight.gd:276` | {topic} (title) | {topic} | keep | |
| F2 | `fight.gd:277` | Choose a floor | Pick your starting mile | text | |
| F3 | `fight.gd:281` | A floor is %d fights: a mini-boss at fight %d and a boss at fight %d. Beat a floor's boss and later runs can start on the next floor. | Each mile is %d stops on the road, with a mini-boss at stop %d and a boss at stop %d. Beat a mile's boss and later runs can start on the next mile. | text | This is where "mile" and "stop" are explained the first time (#203). Same arguments, same order. |
| F4 | `fight.gd:286` | Best floor: %d · floor bosses beaten: %d | Furthest mile: %d · mile bosses beaten: %d | text | |
| F5 | `fight.gd:295` | Floor %d · %s | Mile %d · %s | text | |
| F6 | `fight.gd:334` | everything mixed, harder each floor | every level mixed, harder each mile | text | |
| F7 | `fight.gd:337` | levels %d to %d | questions at levels %d to %d | text | Keeps level and mile apart (#203). |
| F8 | `fight.gd:307` | Floor %d · beat the floor %d boss to start here | Mile %d · beat the mile %d boss to start here | text | |
| F9 | `fight.gd:312` | Back to the map | ◂ {topic} | logic | `to_map()` goes back to the topic's screen, so the button names that topic. Use the zone's name for an "All topics" run and "The Wasteland" for the Thunderdome, the same rule as R1 and R2. |

## Fight: `game/ui/fight.gd`, `game/ui/practice.gd`

| # | Where | Now | Proposed | Change | Note |
|---|---|---|---|---|---|
| B1 | `fight.gd:749` | %s · Floor %d (title) | %s · Mile %d | text | |
| B2 | `fight.gd:456` | Quit | Quit | keep | |
| B3 | `fight.gd:745` | Floor %d · %s · a miss costs %d HP | Mile %d · %s · wrong answer: %d damage | text | |
| B4 | `fight.gd:737` | fight %d of %d / stop %d of %d | stop %d of %d | logic | One word for both fights and jobs. The `job.is_empty()` branch goes. |
| B5 | `fight.gd:741` | · boss part (%s) of %d / · mini-boss part (%s) of %d | (same) | keep | |
| B6 | `fight.gd:744` | · question %d | · question %d | keep | |
| B7 | `fight.gd:750` | %s · D%d (enemy name) | %s · %s (name · rank) | logic | Use `Tuning` tier's `rank`, title case (Recruit, Operative, Sergeant, Commander). Overseer is both, so show "Overseer" once. A job's `label` is unchanged. |
| B8 | `fight.gd:762` | Scrap +%d | Scrap +%d | keep | |
| B9 | `fight.gd:768` | %s ×%d / %s free | (same) | keep | |
| B10 | `fight.gd:70` | 50-50, Hint, Freeze | (same) | keep | Bazaar must match (BZ12). |
| B11 | `fight.gd:781` | Perk: %s | Perk: %s | keep | |
| B12 | `fight.gd:789` | %ds, ❚❚ %ds | (same) | keep | |
| B13 | `practice.gd:205-209` | %s · level %d [· exam style] [· concept] | %s · {kind} · level %d of 5 | logic | **The question header (#203).** {kind} is `Exam question` when `question.exam` is true. Otherwise it's `Training · concept check` for a probe, `Training · warm-up` for level 0 prior learning, `Training · link question` for a link type, and `Training` for anything else. Before: "Work with algebraic fractions · level 0". After: "Work with algebraic fractions · Training · warm-up · level 0 of 5". |
| B14 | `fight.gd:673` | job verb, else Attack (submit) | Lock in | logic | One verb everywhere (#203). Stop reading `job.verb`. The job's `hit` and `done` lines stay. |
| B15 | `practice.gd:240` | Check (submit) | Lock in | text | Same verb as B14. |
| B16 | `fight.gd:674`, `practice.gd:294` | Next question | Next question | keep | |
| B17 | `fight.gd:676` | Another way: the same question, by this method. Bonus Scrap if you get it. | (same) | keep | |
| B18 | `fight.gd:684` | %s: “%s” (taunt) | (same) | keep | |
| B19 | `fight.gd:702` | Boss · part (%s) of %d [· link question] | (same) | keep | |
| B20 | `fight.gd:717` | (%s) right/missed · %s: %s | (%s) right/wrong · %s: %s | text | "missed" becomes "wrong". |
| B21 | `fight.gd:727` | From part (%s): %s. Carry on from this. | (same) | keep | |
| B22 | `fight.gd:810` | Hint: %s | Hint: %s | keep | |
| B23 | `fight.gd:833`, `practice.gd:528` | Fill in every box. | Fill in every box. | keep | |
| B24 | `fight.gd:860` | Hit! +%d Scrap | Hit! +%d Scrap | keep | Boss part. |
| B25 | `fight.gd:862` | Hit! −%d enemy HP · +%d Scrap | Hit! The %s takes %d damage · +%d Scrap | logic | Add `run.enemy.name` as the first argument. |
| B26 | `fight.gd:864` | %s +%d Scrap (job) | (same) | keep | |
| B27 | `fight.gd:866` | Glancing hit. / Glancing hit: half damage. / It barely moves: half the work. | (same) | keep | |
| B28 | `fight.gd:871` | Late hit! It lands, but you take %d damage · +%d Scrap | (same) | keep | Already in the glossary's form. |
| B29 | `fight.gd:873` | Late, but it gives. You take %d damage · +%d Scrap | (same) | keep | |
| B30 | `fight.gd:876` | Missed. −%d HP. %s | Wrong answer. You take %d damage. %s | text | #203. |
| B31 | `fight.gd:879` | Time's up. −%d HP. %s | Time's up. You take %d damage. %s | text | |
| B32 | `fight.gd:882` | Another way: +%d bonus Scrap. | (same) | keep | |
| B33 | `fight.gd:885`, `practice.gd:600` | Watch out: %s | (same) | keep | |
| B34 | `fight.gd:890` | Part (%s) done · %d of %d part(s) to go. | (same) | keep | |
| B35 | `fight.gd:893` | Part (%s) carries on from %s. | (same) | keep | |
| B36 | `fight.gd:895` | The %s falls. | (same) | keep | |
| B37 | `fight.gd:897` | +%d HP. | You heal %d HP. | text | |
| B38 | `fight.gd:899` | Floor %d cleared: floor %d is next. | Mile %d cleared: mile %d is next. | text | |
| B39 | `fight.gd:917` | See the summary | See how the run went | text | |
| B40 | `fight.gd:919` | Next floor | Next mile | text | |
| B41 | `fight.gd:921` | Next fight / Walk on | Next stop | logic | One label for both. |
| B42 | `fight.gd:923` | Next part / Next question | (same) | keep | |
| B43 | `fight.gd:958` | Floor %d cleared (banner) | Mile %d cleared | text | |
| B44 | `fight.gd:958` | Mini-boss beaten (banner) | Mini-boss beaten | keep | |
| B45 | `practice.gd:788` | No calculator (small, dim) | Paper 1 · No calculator | logic | #203: too small to notice. Give it the Calculator button's look: `TITLE_FONT`, `UiTheme.SMALL + 4`, a bordered panel, in `UiTheme.SAND` rather than `DIM`. |
| B46 | `practice.gd:770` | Calculator | Paper 2 · Calculator | text | Says which paper, the same way as B45. |
| B47 | `practice.gd:771` | Paper 2: open the calculator. The clock keeps running. | Paper 2: open the calculator. The timer keeps running. | text | |
| B48 | `assets/journey/signal-tower/*.json` `verb` | Pry, Turn, Dig, Heave, Thump, Cut | (unused) | logic | Not shown after B14. Leave the field in the files, or drop it in the same change. Its `label`, `hit` and `done` stay. |
| B49 | `journey_assets.gd:22` | DEFAULT_WORDS: Work / It gives. / Job done. | verb unused; It gives. / Job done. | logic | As B48. |

## Run summary: `game/ui/fight.gd` (`show_summary`)

| # | Where | Now | Proposed | Change | Note |
|---|---|---|---|---|---|
| S1 | `fight.gd:996` | Run over (you quit) | Run over | keep | |
| S2 | `fight.gd:996` | You're down (0 HP) | You're down | keep | Clear, and in-world. |
| S3 | `fight.gd:1007` | Floor %d reached · bosses beaten: %d | Reached mile %d · bosses beaten: %d | text | |
| S4 | `fight.gd:1011` | Questions right: %d of %d · fights won: %d | Questions right: %d of %d · stops cleared: %d | text | `fights_won` counts every enemy or job beaten, so "stops" is the right word. |
| S5 | `fight.gd:1012` | Scrap earned: %d | Scrap earned this run: %d | text | |
| S6 | `fight.gd:1013` | Scrap in the bank: %d | Scrap in the bank: %d | keep | |
| S7 | `fight.gd:1019` | Skills missed | Skills to work on from this run | text | |
| S8 | `fight.gd:1019` | No skills missed. | Nothing to work on from this run. | text | |
| S9 | `fight.gd:1028` | Play again | Play again | keep | Opens the mile picker. |
| S10 | `fight.gd:1037` | Spend Scrap at the Bazaar | Spend Scrap at the Bazaar | keep | |
| S11 | `fight.gd:1043` | Back to the map | ◂ {topic} | logic | Same as F9. |

## Practice: `game/ui/practice.gd`

| # | Where | Now | Proposed | Change | Note |
|---|---|---|---|---|---|
| P1 | `practice.gd:111` | Practice (title) | Practice | keep | Explained by T4 and R20 before you get here. |
| P2 | `practice.gd:77`, `:121`, `:694` | Exam-style only: on / off | Exam questions only · Exam questions plus training, with the help line | logic | The same two-way choice and line as R8 and R9. All three places share one setting. |
| P3 | `practice.gd:140` | Map | ◂ {topic}, or ◂ The Wasteland | logic | It goes to the topic's screen when `practice_region` is set, and to the main map otherwise. |
| P4 | `practice.gd:688-689` | [%s · ]%d of %d checked · %d right last time | [%s · ]Different questions tried: %d of %d · right last time: %d | text | |
| P5 | `practice.gd:201` | Can't make that question: %s | (same) | keep | Error path. |
| P6 | `practice.gd:588` | Right! / Good. Compare with this answer: | (same) | keep | |
| P7 | `practice.gd:592-596` | Not quite. / Here is the answer: | (same) | keep | Practice has no damage, so "Not quite" stays. |
| P8 | `practice.gd:620` | Worked solution | Worked solution | keep | |
| P9 | `practice.gd:636` | Another way: %s | (same) | keep | |
| P10 | `practice.gd:660` | Watch it | Watch the explainer | text | "Watch it" doesn't say what plays. |

## Bazaar: `game/ui/bazaar.gd`, `game/engine/bazaar.gd`

| # | Where | Now | Proposed | Change | Note |
|---|---|---|---|---|---|
| BZ1 | `bazaar.gd:166` | Bazaar (title) | Bazaar | keep | |
| BZ2 | `bazaar.gd:176` | World map (back) | ◂ The Wasteland | text | |
| BZ3 | `bazaar.gd:227` | Scrap comes from runs. Every run banks some, even a short one. | (same) | keep | |
| BZ4 | `bazaar.gd:278` | Scrap: %d | Scrap: %d | keep | |
| BZ5 | `bazaar.gd:295` | Bought %s for %d Scrap. | (same) | keep | |
| BZ6 | `bazaar.gd:390-392` | Maxed / %d Scrap | (same) | keep | |
| BZ7 | `bazaar.gd:407` | Upgrades · Kept for good, on every run. | (same) | keep | |
| BZ8 | `bazaar.gd:413` | Max HP %d of %d · bought %d of %d | (same) | keep | |
| BZ9 | `bazaar.gd:420` | Bought %d of %d[: …] | (same) | keep | |
| BZ10 | `bazaar.gd:428` | Perks · One perk, for your next run only. It's used up when the run starts. | (same) | keep | |
| BZ11 | `bazaar.gd:431-432` | Ready for your next run: %s / Your slot is empty. | Ready for your next run: %s / No perk bought for your next run. | text | "Slot" hasn't been explained anywhere. |
| BZ12 | `engine/bazaar.gd:19` | Time Freeze | Freeze | text | `LIFELINE_NAMES.freeze`. Then `bazaar.gd:494` can use the table like the others. |
| BZ13 | `engine/bazaar.gd:22-32` | Max HP +10, Lifeline +1, Field Manual (Hints are free.), Scrap Armour (+20 HP.), Lucky Find, Second Wind (Heal 20 HP after each boss.), Field Watch (+10 s on every question.) | (same) | keep | |
| BZ14 | `bazaar.gd:446` | Cosmetics · Name plate · Frames and colours for your name plate and HP bar. Looks only. | (same) | keep | |
| BZ15 | `bazaar.gd:449,469` | YOU | YOU | keep | Name plate preview. |
| BZ16 | `bazaar.gd:454` | Frames / Colours | (same) | keep | |
| BZ17 | `bazaar.gd:471` | Plain / Teal / colour names | (same) | keep | |
| BZ18 | `bazaar.gd:479` | Worn / Wear | (same) | keep | |
| BZ19 | `game/data/shopkeeper.json` | the shopkeeper's lines | (same) | keep | Dialogue. "Mind the floor, it bites." is a real floor, and the banned-word test only checks UI strings for "floor". |

## Settings: `game/scenes/settings.tscn`, `game/scenes/audio_hud.tscn`, `game/audio/settings_panel.gd`

| # | Where | Now | Proposed | Change | Note |
|---|---|---|---|---|---|
| ST1 | `settings.tscn:51` | Sound | Sound | keep | |
| ST2 | `settings.tscn:61` | All sound | All sound | keep | |
| ST3 | `settings.tscn:70`, `settings_panel.gd:61` | On / Off | (same) | keep | |
| ST4 | `settings.tscn:74,100,126` | Background music / Sound effects / Spark's voice | (same) | keep | |
| ST5 | `settings.tscn:155` | Sound is off, so nothing will play yet. | (same) | keep | |
| ST6 | `settings.tscn:162` | Close | Close | keep | |
| ST7 | `audio_hud.tscn:40` | Sound is off — tap to turn it on | Sound is off: tap to turn it on | text | House style: no dashes in UI copy. |
| ST8 | `audio_hud.tscn:50` | Sound settings | Sound settings | keep | |
| ST9 | (new) | | Your course: AA SL · AA HL · AI SL · AI HL | logic | #186: the course chosen on first run must be easy to change later. A course row here, the same as R3 and R4. |

## Credits: `game/ui/credits.gd`, `game/data/credits.json`

| # | Where | Now | Proposed | Change | Note |
|---|---|---|---|---|---|
| C1 | `credits.gd:40` | Credits | Credits | keep | |
| C2 | `credits.gd:46` | Close | Close | keep | |
| C3 | `credits.gd:61` | %s\nLicence: %s. Used in %s. | (same) | keep | `credits.json` has no "island" or "floor". |

## Lines in data files

| # | Where | Now | Proposed | Change | Note |
|---|---|---|---|---|---|
| D1 | `game/data/bosses.json:129` | Five islands, one ring. Show me what you brought. | Every corner of the Wasteland, one ring. Show me what you brought. | text | The Promoter, the Thunderdome boss. |

## Not covered here

- **The calculator** (`calculator.gd`): key labels and the graph readouts are a calculator's words. Kept as they are.
- **The study screen** (`study.gd`, `?study`): plain on purpose (#134), no game words. It keeps "Mark my answer".
- **The question explorer** (`explorer.gd`): a developer tool, hidden from students (T5).
- **Question text, worked solutions and misconception lines**: Curriculum Author's (`game/engine/situations/`).
- **Encounter lines** (`writing/encounters/*.json`): their `island` field is a key, not text a player reads.
- **The first-run screens**: new copy in [`first-run.md`](first-run.md).
