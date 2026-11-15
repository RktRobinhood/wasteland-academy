# Explainers: style guide and script format

An explainer is one short lesson on one idea, taught by the zone's tutor on a wasteland chalkboard. This folder holds the scripts and the rules for writing them. Writer drafts and approves each script, Curriculum Author checks the maths, and the CEO checks the pilots before the full run (plan on [FAL-933](/FAL/issues/FAL-933#document-plan), written on [FAL-936](/FAL/issues/FAL-936)).

Read [`../../TONE.md`](../../TONE.md) and [`../voice-sheets.md`](../voice-sheets.md) first. Everything there applies here too: no "just", "easy", "simple", "obvious" or "guess"; no line genders the player; one IB wink at most per piece, never naming it.

| File | What it is |
|---|---|
| `ex.<zone>.<idea>.json` | One script. The id matches the explainer map, `curriculum/explainers.json` (FAL-935). |
| `callbacks.json` | Reusable "builds on" lines for every tutor, recorded once and used by any script. |
| `ex.algebra.arithmetic-sequence.json` | Pilot 1: the nth term. Mags, about 7 minutes. |
| `ex.algebra.arithmetic-series.json` | Pilot 2: the sum Sₙ, built on pilot 1. Mags, about 8 minutes. |
| `ex.foundations.pre-substitute.json` | Brackets Round Negatives. Tess, about 5½ minutes. |
| `ex.foundations.pre-balance.json` | Keep the Scales Level, built on Brackets Round Negatives. Tess, about 5½ minutes. |
| `ex.foundations.pre-read-and-round.json` | Read the Gauge. Tess, about 5½ minutes. |
| `ex.foundations.pre-percent-multiplier.json` | One Multiplication. Tess, about 5 minutes. |
| `ex.foundations.pre-expand.json` | Fill the Rectangle. Tess, about 5½ minutes. |

Nothing here is recorded. The board chose each tutor's voice on FAL-927 (`tools/explainer-clips/teachers.json`), but GitHub #18 is still open, so the voice blocks below stay provisional until casting is settled there.

## The arc

This is the plan's nine-part arc as the research brief on [FAL-934](/FAL/issues/FAL-934) changed it. The brief made four changes: a "your turn" straight after example 1, a recall question in place of a recap, a concrete case before the definitions, and the common slip turned into a spot-the-error item.

| # | Section (`kind`) | Narration | What it does |
|---|---|---|---|
| 1 | `cold-open` | 15–20 s | Who the tutor is, and a question set in the zone that this idea answers. A joke can go here if it is about the hook. |
| 2 | `recall` | 30–45 s | One tap question on the prerequisite, in two versions (see Callback lines). |
| 3 | `big-idea` | 45–75 s | A concrete case first, then the picture, then the symbols. At most three new terms, each written on the board as it is defined. |
| 4 | `example`, `level: full` | 60–90 s | The easiest version, fully worked, every step labelled out loud ("Step three: the formula"). |
| 5 | `your-turn`, `kind: twin` | player-paced | The same structure as example 1 with new numbers. |
| 6 | `example`, `level: faded` | 45–60 s | Harder by one thing. The tutor does most of it and the player fills in the key step. |
| 7 | `example`, `level: exam` | 90–120 s | Parts (a), (b), (c) with command terms, and every board habit on show. |
| 8 | `second-method` | 60–90 s | Only when the map lists a second method. The same problem as example 3, side by side, then "when would you pick each?" Otherwise the section is there with `skipped` and a reason. |
| 9 | `spot-the-slip` | 30–45 s | A wrong worked solution built from one of the map's misconceptions. The player taps the bad line, and the tutor shows the check that catches it. |
| 10 | `your-turn`, `kind: exam` | player-paced | Exam style, live numbers, no help on the first try. |
| 11 | `recap` | 20–30 s | The idea in one or two sentences, the steps, what comes next, sign-off. |

Narration runs 6 to 8 minutes. The version for a player who watched the prerequisite stays under 8 minutes, and the not-watched version may run up to 30 seconds over. Foundations explainers teach prior learning, so they run 4 to 6 minutes: every section is still there, but any of them can be short, and the exam-style example can be a two-part item that puts the idea inside a course-style question. If a script runs past about 8 minutes, or needs a second new idea, more than three new terms or more than two methods, split it at a natural seam and have the second half recall the first.

How examples get harder: change one thing at a time. Add a step, take away the signposting, put it in words, make d negative, fold in an earlier skill, or switch to the full exam layout. Keep the method and change the surface (the story, the letters, the kind of number). Each worked example gets one "why this step?" tap question.

## The board

The board shows maths and nothing else. Jokes live in the voice. Every example models these habits, and the reviewer checks them:

1. **What we're finding.** The first line says it in symbols and words: "Find u₄₀, the number of seats in row 40."
2. **Givens with units.** One per line: "u₁ = 22 seats", "d = 4 seats per row". Define any new letter before using it.
3. **Formula before numbers.** Write the general formula, then substitute on the next line.
4. **Parts labelled.** "(a)", "(b)", "(c)" start each part, and its working stays under it. Alternative routes are headed METHOD 1 and METHOD 2.
5. **Exact until the end.** Carry unrounded values ("8.0117…") and round once, at the end, to 3 s.f. unless the question says otherwise.
6. **The answer in words, with its unit.** "Row 40 has 178 seats."
7. **A check.** Against the context ("the back rows are the big ones") or a quick test ("n = 1 gives u₁").
8. **Command terms done the way they ask.** Write down needs no working. Find does. Hence uses the part before. For show that, start from the general case, keep n as n, end exactly on the given line and never work backwards.
9. **Keep going after a slip.** Use your own earlier answer in later parts, because the marker follows your working through.
10. **Mistakes crossed out, never rubbed out.** One line through, and the right working beside it. (This one is Mags's habit, but every tutor can use it.)

When the topic calls for them, add the brief's others: the setup before evaluating (the integral with its limits and dx, the probability statement P(…)), + C as its own line, GDC inputs written as a list with the output (never keystrokes), sketch conventions, and the proof layout for induction.

## Character

Matt's target: "mathematical knowledge presented in an academic manner so students can follow, but with a degree of character appropriate to the setting and the character doing the delivery." The maths in a line is exact and in the curriculum's words. The character comes through in the words around it: the tutor's vocabulary, rhythm and stories.

### The tutors

The tutors come from `tools/explainer-clips/teachers.json`. Mags and Tess have full voice blocks, below, and both are provisional (GitHub #18). Each of the other four gets a block in the same form before their first script is written, as `../README.md` requires. The notes after Tess's block are the starting direction.

#### Mags the Ledger (algebra, Scrap Fields), provisional

Keeps the Ledger for the Scrap Fields: every debt, deal and seat sold at the fight pit. Rugged outback Australian, quick, in charge.

**Wants:** players who keep their own books, so nobody out here can cheat them. Would never admit: she once lost a season's takings to a column added up one row short, and she checks everything twice because of it.

**Vocabulary:** the book. Entry, column, tally, takings, owed, balance, "in the book", "sign it". Aussie words used lightly: righto, reckon, folk, a ute, a paddock. Exact maths words, always.

**Rhythm:** short sentences that give orders. Asks one question, then answers it or waits. Dry, and few exclamation marks. Numbers in long form ("one hundred and seventy-eight"), and shorthand once a number's on the board ("four eighty take away two eighty-five").

**Tic and avoidance:** "If it's not in the book, it didn't happen." She has you write things down before you work them out. She never says "about" or "roughly" for a number before the final line, because rounding early is how books go wrong.

**Praise and correction:**

| Right | Not quite |
|---|---|
| "Into the book it goes." | "Check which column that's from. Which row, or what's in it?" |
| "Givens, formula, then the numbers. That's how I'd have done it." | "Later minus earlier. Try your d again." |
| "Every part labelled and checked. I'd sign that." | "Count the hops, not the rows." |
| "Clean books. That's what I like to see." | "Show me the formula before the numbers." |
| "You checked n equals one. Now I trust it." | "One line through it, and go again. I want to see what you did." |

**Samples:** cold open, "The pit boss wants to know how many seats are in row forty. He's been counting since sunrise. He's up to row nine." Family story, "My uncle Wal fenced a paddock once. Ten panels, so he bought ten posts." Sign-off, "Arithmetic sequences are the only honest traders in the Bazaar. Same difference, every single time."

**Not the others:** Dax talks fast, drops names and sells. Mags says less and writes everything down. Gear Mira makes you read a measurement back with its unit; Mags makes you put the working in order and keep it. Bodge talks nonsense about her stock; Mags never wanders off the point for more than one sentence.

#### Tin-Can Tess (foundations, the Scrapworks), provisional

Runs the Scrapworks, the yard where everything broken in the Bazaar ends up, and most of it goes back out the gate working. A New Zealander, as the voice approved on FAL-927 is: lively, wry and warm, and quick to laugh at her own jokes. She teaches the basics with whatever junk is to hand: a bolt and its washer, the scrap scales, a sheet of tin, a gauge that won't agree with the next one.

**Wants:** players who aren't scared of the basics. Out here the sums that hurt people are the small ones nobody checked. Would never admit: she still counts negatives on her fingers when nobody's looking.

**Vocabulary:** the yard and the bench. Bolts, washers, tins, buckets, jerry cans, the chilly bin, spanners, the shed, "on the bench", "pull it apart", "bolt it together", "that'd hold". Kiwi words used lightly, one or two a section at most: kia ora, sweet as, choice, heaps, "eh" at the end of a line. Exact maths words, always.

**Rhythm:** the most talk and the loosest sentences of any tutor. She runs a thought on with "and", talks while she works, and goes off on an aside, then comes back with "anyway". She keeps the maths steps crisp and lets the talk round them run. She asks you things as she goes ("See the order?"), and at a tap question she waits. She laughs at her own jokes and never at anyone's slip. Numbers in long form, like the other tutors.

**Tic and avoidance:** "Bits on the bench." Before she puts anything together she lays every part out where she can see it: the number with its brackets, both pans of the scale, every term of both brackets. She keeps a tin of every bolt she's ever stripped, one for each slip, and owns up to her own slips cheerfully. She never says "wrong" or "broken for good". Working that's off is "a bit off" or "back on the bench", because nothing that comes into her yard is past fixing.

**Praise and correction:**

| Right | Not quite |
|---|---|
| "Sweet as. Bits on the bench, and it all went together." | "Back on the bench with it. Can a square come out negative?" |
| "You kept the brackets. That's the whole trick, right there." | "Close. Do the same to both sides, not only the one." |
| "Choice. And you checked it, too." | "Put your answer back in. Does it come out level?" |
| "That'd hold. I'd put it out front with a price on it." | "Check it with a number. Put x equals one into both. Do they match?" |
| "Heaps better than I did my first time." | "Count on from the labelled mark, not from zero." |

**Samples:** cold open, "A trader brought this counting drum back this morning. Says it's broken, because it told him minus three squared is minus nine." Family story, "My brother took an engine apart once and put it back in the order he liked best. Lovely noise. Didn't go anywhere." Sign-off, "And if a trader says half off, today only? Ask what it cost yesterday."

**Not the others:** Mags and Tess are both from down under, so keep them apart. Mags is Australian, says little and writes everything down; Tess is a New Zealander, talks the whole time and hands you things to hold. Gear Mira measures and reads numbers back with their units, and her sentences get shorter under pressure; Tess pulls things apart and puts them back, and her sentences stay long and get warmer. Bodge wanders off about her stock; every story Tess tells comes back to the maths within a sentence.

#### The other four, in brief

- **Rook Dead-Air** (functions, Signal Tower). Precise, and gets more excited as the lesson builds. His words come from radio: input, output, signal, static, "come in", "over". South African English shows in word choice. Watch B0-LT, who will also live at the Signal Tower.
- **Kara Meridian** (geometry, Dry Flats). Measured and sure of herself. Surveying words: baseline, bearing, level, sight line. She speaks slowly and states things plainly. She sits near Noma (maps, distance), so Kara measures today's ground and Noma tells its stories.
- **Lucien "Lucky" Lenoir** (statistics, Radio Spires). A theatrical gamesmaster who keeps losing to probability, and the joke is always that the maths was right and he bet against it. French-accented English comes through in syntax (fewer contractions, "I bet you remember it") and a rare French word. Never spell his accent phonetically.
- **C.A.L.C.** (calculus, Engine Core). A damaged reactor AI that cares about rates of change. Clipped, formal and literal: "Record found", "Recommend you go". Glitches are a cue, never misspelt words in the caption. It must not sound like Spark, who is warm and sarcastic. Spoken and captioned as "Calc".

### Jokes

Dad jokes, well-known maths jokes and stories, and lines from the tutor's own life all work. A family story or a little analogy for how they remember something works best, because the joke then carries the idea (Uncle Wal's fence is the n − 1).

**Where they go:** the cold open, the gaps between sections, after a right answer, and the sign-off. **Where they never go:** inside a step that carries the maths, on the board, in feedback on a wrong answer, or at the expense of whoever made the slip. A joke is one sentence, two at most. Mark it `"joke": true`, and keep jokes to about a tenth of the spoken words. The pilots run at 9% and 4%.

**Where the line falls.** Wasteland grit is fine: dust, rust, scrap, hunger, bad deals, broken machines, losing at cards, a fence with a gap in it, a cough from the dust. These are not fine:

- Anything about race, religion, ethnicity, nationality, disability, bodies, looks, gender or sexuality, or a real person as the butt of the joke.
- A word that is a slur anywhere in English, even when the line means something else. Matt's own example, "the time grandma shot the coon", fails twice: the word is a racist slur, and the joke is a shooting. Check every animal name and nickname in a joke for a second meaning.
- Guns, injuries, drink or drugs as the punchline. A smoker's cough as a voice cue is fine; the smoking is never the joke.
- A student's ability, or grades ruining a life (TONE.md).
- An accent spelt out phonetically, or a tutor's home country as the joke.
- A line lifted from a film, a game or a comedian. Point at a reference if you like, but the words stay ours.

## Delivery cues

A cue is a sound the voice makes that isn't a word: `chuckles`, `laughs`, `coughs`, `sighs`, `clears-throat`, `sniffs`, `hums`, and `glitch` for C.A.L.C. The list is in `callbacks.json` (`cues`), and a new cue goes there first.

- A cue sits in the line's `cue` field, with `cue_at` set to `start` or `end`. It never goes inside `say`, so the caption stays word-for-word with what is spoken.
- A voice that can't perform a cue skips it. The line has to work without it.
- A pause is `pause`, in seconds, after the line.
- Use about one cue per section, and no more than two coughs in a whole explainer.

## Callback lines

The game records which explainers the player has watched. A recall section has two versions, chosen by whether its `builds_on` explainer is on that record:

- **`watched`:** a callback line ("You did this one with me"), then the recall question.
- **`not_watched`:** the same question first, then a short version of the prerequisite (about 20 seconds, with its board), then a pointer to the full lesson ("You haven't been to see Kara yet…").

Prerequisites suggest and never lock, so the not-watched version must teach enough to carry on.

An explainer with no prerequisite (`builds_on` empty, as most Foundations explainers are) has one version. Its recall section is a single tap question on what students bring from earlier school, with no callback line, so the section has `beats` and `"builds_on": null` instead of `watched` and `not_watched`. Say so in the script's `notes`.

The callback lines are in `callbacks.json`, 14 per tutor: `own.watched`, `own.not-watched`, `short-version` and `after`, then a `watched` and `not-watched` line for each of the other five tutors. A script uses one with `{ "use": "mags-the-ledger.tin-can-tess.not-watched" }`. They never name the topic, so each can be recorded once and reused anywhere. The game shows the prerequisite's title card while the line plays. Matt's examples, Old Mama Ode and a bubble bot at the Bazaar, aren't tutors, so they have no lines yet. They get lines if casting on #18 adds them.

## The script format

Scripts are JSON. Both readers are code: the Godot player parses JSON natively, and the clip renderer is JavaScript. The rest of the game's words are JSON already (`game/data/shopkeeper.json`, `writing/encounters/`). Markdown with fixed headings would read better on GitHub, but it would need a parser that someone keeps up to date, and a stray heading would break it without a warning. JSON can be checked: every move id exists in `curriculum/moves.json`, every speaker is in `teachers.json`, every `use` is in `callbacks.json`. To read a script as a script, pull out the `say` fields in order.

### Top level

| Field | What it holds |
|---|---|
| `id` | `ex.<zone>.<idea>`, as in the map. Permanent once on `main`, because the watched record stores it. |
| `format` | `1`. |
| `status` | `draft`, `approved` (Writer and Curriculum Author have passed it) or `recorded`. Once a script is `approved`, its line order is frozen, because recordings are named by section and position. |
| `title`, `idea` | The title card, and the idea in one sentence. |
| `zone`, `tutor` | The map zone, and its tutor's id in `teachers.json`. |
| `courses`, `syllabus`, `skills` | From the map and `curriculum/*.json`. |
| `builds_on`, `leads_to` | Explainer ids. `builds_on` drives the recall section. `leads_to` is what the recap points at. |
| `terms` | The new terms, three at most. |
| `misconceptions` | The map's misconceptions this script addresses, in the curriculum's words. |
| `estimate` | Word counts and narration time for both recall versions, and how they were worked out. |
| `notes` | Anything a reviewer needs: a skipped section, a provisional id. |
| `sections` | In arc order. Each has an `id`, a `kind` from the arc table and its `beats`. A recall section has `watched` and `not_watched` instead of `beats`, unless the explainer has no prerequisite (see Callback lines). An example has `level` and `problem`. A your-turn section has `turn`. |

### Beats

A beat is one of four things.

**A spoken line.** `speaker` (a tutor id), `say` (the caption, which is exactly the words spoken), and optional `cue`, `cue_at`, `pause`, `joke`, `clear` (wipe the board first) and `board`. Board items attached to a line are written while it is spoken.

**A board item.** `write` (the text as it appears on the board), plus optional fields:

- `move`, a move id from `curriculum/moves.json`, for any line that is a working step;
- `label`, the step label shown above it, which defaults to the move's name;
- `part` (`a`, `b`, `c`), on every item that belongs to a part;
- `method` (`1`, `2`) for side-by-side working;
- `kind`, one of `heading`, `term`, `step`, `answer`, `check`, `note` or `slip`;
- `key`, so a later beat can refer to the item.

`{ "strike": "<key>" }` crosses out an earlier item with one line.

**A tap question.** `ask`, holding `kind` (`recall`, `why`, `fill`, `choose` or `tap-line`), `prompt` (on screen), `choices`, `answer` (the index of the right choice), and `right` and `not_yet` lines. For `tap-line`, the choices are board keys.

**A callback.** `{ "use": "<tutor>.<key>" }`, played from `callbacks.json`.

A `your-turn` section holds a `turn` instead of beats. It names the question type (`type`, from `curriculum/question-types.json`) and the `skills`, so the player can draw live numbers. `like` names the example it mirrors. `fallback` is a fixed version with checked answers and working, for the clip renderer and for testing. `intro`, `right` and `not_yet` are spoken lines with no numbers in them, because the numbers change every time.

### Writing the words

- **Captions are the spoken words.** Numbers go in words, the way the tutor says them: "one hundred and seventy-eight", or "four eighty" once the number is on the board.
- **Symbols are spoken plainly and the same way every time.** uₙ is "u n", u₁ is "u one", Sₙ is "S n", (n − 1)d is "n minus one lots of d", n/2 is "n over two", n² is "n squared".
- **The board is plain text with Unicode maths**, like the worked steps in the game (`game/engine/step.gd`): subscripts ₁ₙ, the minus sign −, ×, ÷, ≠ and ✓. No KaTeX, no markup.
- **Say the step label** when the board shows one, so ear and eye stay together.
- **Mind SPARK players.** A tutor can talk about the world freely, but a line about the player has to work for a robot on treads (`../voice-sheets.md`).

### How each reader uses it

- **The Godot player** ([FAL-429](/FAL/issues/FAL-429)) plays beats in order. Each board item with a `move` is the same object as a worked step, `{"move": …, "board": …}` (`Step.tagged`), so the player can highlight a step and replay its move line. Tap questions and turns pause the narration. The watched record picks the recall version.
- **The clip renderer** (`tools/explainer-clips/`) needs 3 to 5 beats and 10 to 25 seconds, so a clip takes one section, usually the big idea, and only the beats that change the board. Each chosen line's `say` becomes a `VOICE` line, and its slot is the word count × 0.45 s. The renderer's banned words are the same as ours.

## Before a script ships

The editor's pass, done by Writer on every script:

1. Read every `say` aloud in order, in the tutor's voice, as a tired seventeen-year-old would hear it. Cut what they would tune out.
2. Work every number and every step by hand, including the wrong solution in the slip and the turn fallbacks.
3. Check the length against the arc. Under 8 minutes, or split it.
4. Check the joke placement and budget, and that no line names "IB".
5. Check that each callback version works without the other.
6. List anything unsure under `notes`, and on the task.

## Not decided yet

The CEO settled the pilot questions on [FAL-953](/FAL/issues/FAL-953): the map follows the scripts, the length rule is the one in "The arc", and Gauss stays as pilot 2's story. What's still open:

- **The map's split entries.** The map is on `main` (PR #147). Where a pilot teaches less than its map entry, the map changes to match: the Curriculum Author splits those entries on [FAL-952](/FAL/issues/FAL-952). Until that lands, pilot 1's `notes` still describe the difference.
- **Casting.** The board chose the voices on FAL-927, but GitHub #18 is still open. Mags's and Tess's blocks and the four notes above can change when casting is settled there.
- **Turns, the engine and recording ids.** How a `turn` maps to the maths engine, and whether lines need ids that survive edits, are phase 2, with Coder. Until then a recording is named by section and position, frozen at `approved`.
- **How symbols are said.** "u n" or "u sub n", and the like, is decided with the voice, at recording.
- **Pictures on the board.** The board is text only, so a gauge, an axis or an area grid is written as text (the Foundations scripts do this). A drawn figure would teach some ideas better. A `figure` board item would be a phase 2 question for Coder and Artist.
- **A checker.** The Curriculum Author is adding a script checker on [FAL-952](/FAL/issues/FAL-952) (moves, speakers, callbacks, banned words, digits in captions).
