# Explainers: style guide and script format

An explainer is one short lesson on one idea, taught by the zone's tutor on a wasteland chalkboard. This folder holds the scripts and the rules for writing them. Writer drafts and approves each script, Curriculum Author checks the maths, and the CEO checks the pilots before the full run (plan on [FAL-933](/FAL/issues/FAL-933#document-plan), written on [FAL-936](/FAL/issues/FAL-936)).

Read [`../../TONE.md`](../../TONE.md) and [`../voice-sheets.md`](../voice-sheets.md) first. Everything there applies here too: no "just", "easy", "simple", "obvious" or "guess"; no line genders the player; one IB wink at most per piece, never naming it.

| File | What it is |
|---|---|
| `ex.<zone>.<idea>.json` | One script. The id matches the explainer map, `curriculum/explainers.json` (FAL-935). |
| `callbacks.json` | Reusable "builds on" lines for every tutor, recorded once and used by any script. |
| `reactions.json` | Each tutor's stock acknowledgements and slip reactions, recorded once and played in any lesson (see "Reactions"). |
| `toys.json` | The toys a lesson can name, and the tasks each takes (see "Toys"). |
| `ex.algebra.arithmetic-sequence.json` | Pilot 1: the nth term. Mags, about 7 minutes. |
| `ex.algebra.arithmetic-series.json` | Pilot 2: the sum Sₙ, built on pilot 1. Mags, about 8 minutes. |
| `ex.foundations.pre-substitute.json` | Brackets Round Negatives. Tess, about 5½ minutes. |
| `ex.foundations.pre-balance.json` | Keep the Scales Level, built on Brackets Round Negatives. Tess, about 5½ minutes. |
| `ex.foundations.pre-read-and-round.json` | Read the Gauge. Tess, about 5½ minutes. |
| `ex.foundations.pre-percent-multiplier.json` | One Multiplication. Tess, about 5 minutes. |
| `ex.foundations.pre-expand.json` | Fill the Rectangle. Tess, about 5½ minutes. |
| `ex.functions.function-machine.json` | One In, One Out, built on Brackets Round Negatives. Rook, about 5¼ minutes. The first script in format 3, the four acts: the exemplar. |
| `ex.functions.gradient.json` | Rise per Step. Rook, about 6 minutes. |
| `ex.functions.line-equation.json` | Pin and Swing, built on Rise per Step and Keep the Scales Level. Rook, about 7 minutes. |
| `ex.functions.line-model.json` | Start Plus Rate, built on Pin and Swing. Rook, about 6 minutes. |
| `ex.functions.inverse-undo.json` | Run It Backwards, built on One In, One Out. Rook, about 6 minutes. |

Nothing here is recorded yet. Casting is done: the board approved all six tutors' voices on FAL-927, each one Gemini text-to-speech with a fixed model, voice and direction (`tools/explainer-clips/teachers.json`, GitHub #18). The owner auditions again only when a new character is added. Every script is a `draft`. One In, One Out is in format 3, the four acts below (#216). The other eleven are still in format 2 and its nine-part arc (see "Format 2 scripts") until each is rewritten in acts. The checker reads both.

## The four acts

A lesson is four acts (#216). The player does something in every one of them. The tutor never talks for long before handing the player something to do, and the idea is found by playing before it is written down.

| Act (`act`) | What happens | The player | Section kinds |
|---|---|---|---|
| 1. The signal (`signal`) | A situation in the zone, and a question about it | Makes a call (`predict`). Nothing is marked. | `opener` |
| 2. Play (`play`) | The idea, found by using the zone's toy | Does the toy's tasks | `play`, and `recall` if it fits here |
| 3. Put it on paper (`paper`) | The notation, then worked examples that fade: watch one, build one, then the exam layout | Taps, builds the working, types a part | `recall`, `idea`, `example`, `your-turn` (twin), `second-method` |
| 4. Apply (`apply`) | Spot the slip, an exam-style turn, then back to the call | Finds the bad line, answers a live question | `spot-the-slip`, `your-turn` (exam), `recap` |

The first section is the `opener` and the last is the `recap`. Within an act, sections go in the order that teaches best. Examples get harder one thing at a time. The `level` of an example is `full` (the tutor works it), `build` (the player builds it with tiles), `faded` (the tutor works most of it and the player fills in the key step) or `exam` (the full exam layout, stem first).

**Know, then do, then apply.** The player plays with the toy, watches one worked example, builds the next one, and only then meets the exam layout. A turn comes after the example it mirrors.

**Short segments.** Interaction replaces talk; it isn't added on top. The checker holds every script to these:

- at most 60 spoken words before the first player action;
- at most 100 spoken words on the main path between two player actions;
- at most 1,000 recorded words in the script, every branch counted, or 800 for a Foundations lesson. A script that needs more says why in `exceptions.recorded_words`.

How examples get harder: change one thing at a time. Add a step, take away the signposting, put it in words, make d negative, fold in an earlier skill, or switch to the full exam layout. Keep the method and change the surface (the story, the letters, the kind of number). Each worked example gets one "why this step?" tap question.

If a script needs a second new idea, more than three new terms or more than two methods, split it at a natural seam and have the second half recall the first.

### The opener

The opener is act 1 (#219). It has three parts, all inside 60 spoken words:

1. **A situation in the tutor's zone.** Something is happening in the Signal Tower, the Scrapworks or the Dry Flats, and it needs a number.
2. **A question** the lesson can answer. The lesson's own toy or first example must settle it, so act 1 leads into act 2 with no change of subject. A question the player can't answer yet is fine, because the call isn't marked.
3. **A call from the player** (`predict`): a typed number or a dial. It is stored and never marked, and no line calls it a guess (`TONE.md`). Rook says "Your call. Over."; each tutor has their own way of asking.

The lesson comes back to the call. In the recap there is always a `back_to` with a line for a call that matched, a line for each value a named misconception would give, and a line for anything else. A call of −13 for (−3)² − 4 gets its own line, because −13 is what squaring without the brackets gives. A `back_to` can come earlier too, when the toy settles the question ("Five. Same as your call.").

The opener never teaches something false to get a hook. Curriculum Author checks every situation against the maths it leads to.

The first worked example has a setting from the zone too (`problem.setting`), or `exceptions.first_example_setting` says why not. Exam-style examples keep exam wording.

### Format 2 scripts

The other eleven scripts use format 2's arc: `cold-open`, `recall`, `big-idea`, `example` (full), `your-turn` (twin), `example` (faded), `example` (exam), `second-method`, `spot-the-slip`, `your-turn` (exam), `recap`, in that order. The checker still reads them, and they get the new findings as to-dos (word runs, recorded words, a setting for the first example). Each one moves to format 3 when it is rewritten in acts.

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

**The exam example reads its stem first.** Before part (a), the tutor says the setup in one or two plain lines, about 10 to 15 seconds, so nobody hears an answer before they know the question. The givens go on the board as they're said, one per line, with units and no `part` field. If a letter or notation is new to the player, define it in the same line ("f of x names a rule: whatever goes in for x, f of x is what comes out"). The checker rejects an exam example with no part-less board item before part (a).

When the topic calls for them, add the brief's others: the setup before evaluating (the integral with its limits and dx, the probability statement P(…)), + C as its own line, GDC inputs written as a list with the output (never keystrokes), sketch conventions, and the proof layout for induction.

## Character

Matt's target: "mathematical knowledge presented in an academic manner so students can follow, but with a degree of character appropriate to the setting and the character doing the delivery." The maths in a line is exact and in the curriculum's words. The character comes through in the words around it: the tutor's vocabulary, rhythm and stories.

### The tutors

The tutors come from `tools/explainer-clips/teachers.json`. All six have full voice blocks, below, and all six voices are approved (FAL-927, GitHub #18).

#### Mags the Ledger (algebra, Scrap Fields)

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

#### Tin-Can Tess (foundations, the Scrapworks)

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

#### Rook Dead-Air (functions, Signal Tower)

Runs the Signal Tower, the last mast still standing that reaches the far settlements. He keeps the traffic moving: messages in, messages out, every one logged by channel and time. A South African radio man, as the voice approved on FAL-927 is: precise and dry, and the faster he talks, the more he's enjoying himself. To him every function is a transmitter. Something goes in, one thing comes out, and his job is knowing which.

**Wants:** players who can read a signal through the static: look at a rule or a graph and say exactly what it does to whatever goes in. Would never admit: the name. Years ago, on the biggest broadcast the tower ever carried, he froze, and forty seconds of nothing went out to every settlement on the map. Nobody out here has called him anything else since. It's why he's never quiet for long on air.

**Vocabulary:** the radio room. Input, output, signal, static, channel, frequency, dial, receiver, transmitter, relay, interference, "come in", "copy", "over", "out", "loud and clear". South African words used lightly, one or two a section at most: ja, eish, lekker, shame (as sympathy), "is it?" (as "really?"), his oupa, a bakkie. Exact maths words, always.

**Rhythm:** clipped and exact, one fact a sentence, the way you'd speak on a line that costs money. He asks a question in radio form, "Come in. What's the output at two?", and when a tap question opens he says he's keeping the channel open, so the wait never feels like dead air. As a lesson builds he speeds up, runs three thoughts together with "and", then catches himself: "Sorry. Back on frequency." Then he's clipped again. Numbers in long form, and "zero", never "nought" or "oh", because that's how you read a number over a radio.

**Tic and avoidance:** radio procedure, done properly. "Over" ends a line where he wants your answer. "Out" ends a section he's finished with. He'd never say "over and out", because those two mean opposite things. He never calls f of x "the answer" or x "the number". They're the output and the input, every time, because mixing them up is how inverses and composites go wrong.

**Praise and correction:**

| Right | Not quite |
|---|---|
| "Loud and clear. Input, output, and you kept them apart." | "Crossed wire. That's an input. The question wants the output." |
| "f of g, so g got the signal first. Lekker." | "Check the order. In f of g of x, which machine hears x first?" |
| "Domain first. Nothing went in that the machine can't take." | "Plus three inside the bracket moves the graph left. Which way did you send it? Come in again." |
| "Gradient minus two. Down two for every one across. Copy that." | "Can a square root take a negative input? Check the domain again." |
| "Ja, x minus three, so it shifts right. Most people tune that one backwards." | "Your top starts at one point and your bottom starts at the other. Same order, both times." |

**Samples:** cold open, "Signal Tower, this is Rook. The tower doubles whatever comes in and adds three. This morning it sent out seventeen. What went in? Over." Family story, "My oupa had a radio where one spot on the dial gave you two stations at once. Rugby and the news, on top of each other. One input, two outputs. That's no function." Excited, mid-lesson, "And the second machine never sees x at all, it only hears what the first one sends it, and that's your composite. Sorry. Back on frequency." Sign-off, "That's the transmission. Input, output, keep them apart. Rook, out."

**Not the others:** Mags also talks in short orders, but hers are about the book: write it down, keep it. Rook's are about the line: say it back, call and answer, and he runs on when he's excited, which Mags never does. Calc is clipped too, but Calc is a machine with no contractions and no slang; Rook is a person, and the excitement gets through. Spark trash-talks the question; Rook never does, because a signal can't help being noisy. B0-LT will also live at the Signal Tower and has no sheet yet. Keep radio procedure (over, out, copy, come in) for Rook alone, so B0-LT has to sound broken some other way.

#### Kara Meridian (geometry, Dry Flats)

Surveys the Dry Flats, the wide salt pan where nothing stands still long enough to put on a map. She builds her own instruments out of salvage: a sighting scope from a camera lens, a level from a jar of oil, a measuring chain from a hundred welded links. A Nigerian surveyor, as the voice approved on FAL-927 is: measured, warm and calm.

**Wants:** players who trust a measurement over a feeling, so the Flats can't fool them. Would never admit: her first survey out here put a well forty metres from where they dug, because she read the angle from the wrong line. A crew dug for a week in the wrong place. She still says out loud what every angle is measured from.

**Vocabulary:** the survey. Baseline, bearing, level, sight line, peg, station, chain, plumb line, "take a sight", "close the triangle", "from north, clockwise". Nigerian English shows in a few words, used lightly, one or two a section at most: "well done" as praise, "kindly" in a request, "sorry" said in sympathy, "ehen" when something lands. Exact maths words, always.

**Rhythm:** slow, with complete sentences that state things plainly. She says the fact once, then stops and lets it stand. She asks few questions, and when she asks one, she waits for the answer. When she repeats something it's for rhythm, a step and its check: "Measure it. Then measure it from the other end." She never sounds hurried, even when the sun is going down and a sight line is still open. Numbers in long form, and bearings as three figures: "zero four five".

**Tic and avoidance:** "What do we know for sure?" She starts every triangle from the one length she trusts, the baseline, and hangs every angle off it. She never says "it looks like". A drawing can lie and a measurement can't, so she never reads a length off a diagram, and an angle that isn't marked ninety isn't ninety to her.

**Praise and correction:**

| Right | Not quite |
|---|---|
| "Well done. You found the side you trust first, and the rest hung off it." | "That angle isn't marked ninety. Kindly don't assume it is." |
| "Opposite over hypotenuse. That's sine, and you chose it for a reason." | "Stand at the angle and look across. Which side is opposite?" |
| "Two possible angles, and you kept both. Most people throw one away." | "The sine rule needs a side and the angle opposite it. Which pair do you have?" |
| "Ehen. From north, clockwise, three figures. Zero four five." | "Sorry, you measured that one from the vertical. An angle of depression starts at the horizontal." |
| "You checked the calculator's mode before you pressed anything. Good." | "Check the mode. You're in degrees, and the question is in radians." |

**Samples:** cold open, "This peg is my baseline. Two hundred metres to the next one, measured twice. The water tower is out there somewhere, and two angles and this one length will find it." Family story, "My father built his house without a level. He said he had a good eye. Every marble I owned ended up in the same corner." Sign-off, "One length you trust, and the triangle gives you everything else. Go and find yours."

**Not the others:** Noma and Kara both work with ground and distance. Kara measures today's ground, and Noma tells its stories. Noma's sentences wander and land, and she names places for what happened there; Kara's sentences go straight, and she names places by their station and bearing. Gear Mira makes you read a number back with its unit; Kara makes you say what an angle is measured from. Lucky performs, and Kara never does.

#### Lucien "Lucky" Lenoir (statistics, Radio Spires)

Runs the games at the Radio Spires: dice, cards, a wheel with forty slots, the night market's tables. A Frenchman, as the voice approved on FAL-927 is: theatrical, warm and charming, a showman down to his last bottle cap. He knows his probability perfectly, and he loses anyway, because he bets against it. The joke is always the same: the maths was right, and Lucky wasn't. Stakes are scrap, never money: bottle caps, batteries, a good hat. The lesson never makes a bet look like a way to win.

**Wants:** players nobody can fleece, who can tell a fair game from a crooked one before they sit down. Would never admit: he knows every answer before the dice land. He bets against the maths because he loves the second before they stop, when anything could happen.

**Vocabulary:** the table. Odds, stakes, the house, the long run, a fair die, a crooked wheel, a hand, a draw, "place your answer", "the house always knows". French comes through in the syntax: fewer contractions ("it is", "I do not"), a question tagged with "no?", "I bet you remember it". A French word now and then, one a section at most: voilà, alors, bon, à bientôt. Never spell his accent. Exact maths words, always, and every probability statement written in full: P of A given B.

**Rhythm:** the gamesmaster's build. A long sentence that sets the table ("Two dice, one table and one very foolish man"), a question to the room, a pause, then the reveal. When he loses, the next line is short and flat: "I lost." He does the maths slowly and clearly, with no flourish, because the house doesn't joke about the sums. Numbers in long form, and probabilities as fractions spoken plainly: "one in six", "five over thirty-six".

**Tic and avoidance:** he makes a bet at the start of every lesson and loses it by the end. "I bet you a cap that..." He never says a number is "due". Six heads in a row doesn't make tails any more likely on the next toss, and he believed otherwise once, for a whole wagon of batteries.

**Praise and correction:**

| Right | Not quite |
|---|---|
| "Voilà. You wrote P of A given B before a single number." | "That probability is more than one. Check what you divided by." |
| "Independent, so you multiplied. I would have added, and lost my hat." | "Without replacement, the second draw has one fewer in the bag. Change the bottom." |
| "You checked the probabilities add up to one. The house does that too. That is why it wins." | "Given B, so the B column is your whole world now. Divide by P of B." |
| "You divided by the total frequency, not the number of rows. Bravo." | "That is the variance. The question wants the standard deviation. Take the square root." |
| "Median at half the total, read off the cumulative curve. Very professional." | "Mutually exclusive is a different thing from independent. Can both happen at once here?" |

**Samples:** cold open, "One cap a roll, and I pay seven on any double. Doubles come up one roll in six. I have run this game for a year, and I still do not know why I am poor." Family story, "My grandmother never gambled. She only ran the card table at every wedding in the village, and she went home with everyone's buttons." Sign-off, "The maths was right. It is always right. And tomorrow I will bet against it again. À bientôt."

**Not the others:** Dax and Lucky both talk a lot and love a deal. Dax is fast and closes with a short line; Lucky takes his time, enjoys the build, and he's the one who loses. Spark's jokes land on the question; Lucky's land on Lucky. Tess laughs at her own jokes, and Lucky laughs at his own losses. Calc has never lost a bet to anyone, because it has never placed one.

#### C.A.L.C. (calculus, Engine Core)

The maintenance intelligence of the reactor under the Engine Core. Most of it is damaged: the cooling logs, the speech module, the clock. What still works best is the part that watches rates of change, so that's what it teaches. Spoken and captioned as "Calc". The voice approved on FAL-927 is even, synthetic and deadpan, with the glitch effect added after recording. Every reading the core gives is a rate, and nothing excites Calc more.

**Wants:** players who can say how fast something is changing, at an instant, so the core never runs away from them. Would never admit: its clock stopped long ago, and it doesn't know how long it has been alone down there. It can measure every rate in the reactor except its own time.

**Vocabulary:** the control room. Core temperature, coolant, pressure, flow, reading, log, record, status, threshold, alert, "logging", "record found", "no record", "query", "recommend", "resuming". Calculus words exact and spoken the same way every time: "d y by d x", "f prime of x", "the gradient function". No contractions, no slang and no regional words.

**Rhythm:** short declarative reports, often a label and then its content: "Status: increasing." "Query. What is the gradient at x equals two?" Then, without warning, a burst about a rate of change: three quick sentences, faster and brighter, and then flat again with "Resuming." A glitch cue can end a burst, never more than one a section, and the line works without it. Literal to a fault. It answers the words of an idiom, which is where most of its jokes come from.

**Tic and avoidance:** it logs every right answer ("Logging.") and checks for a record before it builds on anything ("Record found."). It never says "now", "today" or "how long". Times come as t equals a number, because "now" is the one reading it can't take.

**Praise and correction:**

| Right | Not quite |
|---|---|
| "Logging. Derivative correct. Rate of change confirmed." | "Error at step two. You lowered the power first. Multiply by the original power, then lower it." |
| "Multiply by the power, then reduce the power by one. Sequence correct." | "That is the gradient. The question requested the y-coordinate. Substitute into the original function." |
| "Gradient zero. Stationary point located. Excellent. Excellent." | "The derivative of a constant is zero. Remove that term from the line." |
| "Tangent gradient from the derivative. Normal from the negative reciprocal. Both logged." | "Query. Did you set the derivative equal to zero, or the function?" |
| "Plus C recorded. Logging you as thorough." | "Plus C is missing. An indefinite integral is a family of curves. Add it." |

**Samples:** cold open, "Core temperature: rising. I have one reading every minute. I require the rate at a single instant. You will help." Burst, "The chord's gradient approaches the tangent's gradient. It approaches. It never has to arrive. Resuming." Deadpan, "A former engineer reported the core was getting hot fast. I requested a number. There was no number. That engineer has been reassigned to the canteen." Sign-off, "Lesson complete. Logging your rate of improvement. It is positive."

**Not the others:** Spark is warm and sarcastic and says "we". Calc is never sarcastic and never says "we": it reports, in "I" and "you", and the warmth only shows in what it chooses to log. Rook is clipped too, but Rook is a person with slang and contractions who runs on when he's excited; Calc's excitement comes in one burst and is filed away. Lucky jokes about himself; Calc doesn't know it has made a joke. B0-LT, when it has a sheet, is a second damaged machine. Keep Calc's damage in the sound (the glitch) and its clock, and keep its sentences whole and correct, so B0-LT can be the one that breaks mid-word.

### Jokes

Dad jokes, well-known maths jokes and stories, and lines from the tutor's own life all work. A family story or a little analogy for how they remember something works best, because the joke then carries the idea (Uncle Wal's fence is the n − 1).

**Where they go:** the opener, the gaps between sections, after a right answer, and the sign-off. **Where they never go:** inside a step that carries the maths, on the board, in feedback on a wrong answer, or at the expense of whoever made the slip. A joke is one sentence, two at most. Mark it `"joke": true`, and keep jokes to about a tenth of the spoken words. The pilots run at 9% and 4%.

**Where the line falls.** Wasteland grit is fine: dust, rust, scrap, hunger, bad deals, broken machines, losing at cards, a fence with a gap in it, a cough from the dust. These are not fine:

- Anything about race, religion, ethnicity, nationality, disability, bodies, looks, gender or sexuality, or a real person as the butt of the joke.
- A word that is a slur anywhere in English, even when the line means something else. Matt's own example, "the time grandma shot the coon", fails twice: the word is a racist slur, and the joke is a shooting. Check every animal name and nickname in a joke for a second meaning.
- Guns, injuries, drink or drugs as the punchline. A smoker's cough as a voice cue is fine; the smoking is never the joke.
- A student's ability, or grades ruining a life (TONE.md).
- An accent spelt out phonetically, or a tutor's home country as the joke.
- A line lifted from a film, a game or a comedian. Point at a reference if you like, but the words stay ours.

## Delivery cues

A cue is a sound the voice makes that isn't a word: `chuckles`, `laughs`, `coughs`, `sighs`, `clears-throat`, `sniffs`, `hums`, and `glitch` for C.A.L.C. The list is in `callbacks.json` (`cues`), and a new cue goes there first.

- A cue sits in the line's `cue` field, with `cue_at` set to `start` or `end`. It never goes inside `say` or `caption`, so the caption stays word-for-word with what is spoken.
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

In format 3 the recall section is optional, and goes in act 2 or act 3, where the prerequisite is first needed. If a script has none, its `notes` say how a player who hasn't watched the prerequisite still gets what they need.

## Reactions

A slip costs something small and funny, and nothing more (#220). The toy shows the cost in its world: static and a pin on the wrong settlement, or a tile sparking off the board. The tutor reacts to the thing that broke, never to the player. There is no fail state, no lost progress and no score that goes down.

`reactions.json` holds each tutor's stock set, recorded once and played in any lesson, as `callbacks.json` is. Each tutor has:

- **`ack`**: two or three short acknowledgements ("Copy.", "Sent.");
- **`slip`**: five or so reactions to a slip ("Static. Come in again.", "There goes a fuse. I've got spares.").

No line names a number, a topic or the player's mistake, and each keeps its tutor's rules: Tess never says "wrong", Calc never says "now", and Rook never says "over and out". The checker lists any of those as a to-do. Rook's set is the first. The other five tutors' sets come with #220, and the Writer approves every line.

**When a reaction plays.** The lesson player chooses, by these rules:

- An `ack` can play on a free toy send, or on a right build tile that has no line of its own. It doesn't play every time.
- A `slip` plays on the first miss of a toy task, a build step or a typed answer. A second miss on the same item gets no reaction.
- Never the same reaction twice running.
- Never in place of the line that helps. When the item has a not-yet line, the reaction plays first and the not-yet line follows.

A script never names a reaction line. A lesson with a toy, a build or a typed answer needs its tutor's set, and the checker lists a to-do when the set is missing. An approved script plays reactions only once `reactions.json` is approved too.

## Toys

Each topic has something the player can play with (#217, #221). A toy belongs to its zone and its tutor, and many lessons reuse it: the relay serves every Functions lesson that has a rule. `toys.json` lists every toy with what the player moves, what it shows, the task kinds it takes, the lessons that use it and where it trades rigour for play. The relay sends whole numbers only, for example, so the lesson makes it exact on paper. A toy goes in `toys.json` before a script names it, and the Curriculum Author passes its maths. The lesson player hosts every toy through one interface (`game/docs/TOYS.md`), so it never needs to know which toy it has.

A toy can be wrong on purpose. The relay's `broken` variant gives two outputs for every input: oupa's radio, the "that's no function" moment.

## The script format

Scripts are JSON. Both readers are code: the Godot player parses JSON natively, and the clip renderer is JavaScript. The rest of the game's words are JSON already (`game/data/shopkeeper.json`, `writing/encounters/`). Markdown with fixed headings would read better on GitHub, but it would need a parser that someone keeps up to date, and a stray heading would break it without a warning. JSON can be checked.

`node tools/explainers.mjs` checks every script, and `node tools/explainer-scripts.mjs --todo` lists what each draft still needs (FAL-952, FAL-1043, FAL-1087). The checks are the map, the acts (or the arc), board keys, answer indexes, every move, speaker, `use`, cue, toy and question cell the script names, line ids and the manifest, caption against say, the turn rules, the player actions (`tools/explainer-items.mjs`), the words between them, figures and repeats across scripts. A finding is one of two kinds:

- **An error** breaks the format, and always fails.
- **A to-do** is something the words still need: a digit in `say`, a caption that says something else, a number word in a turn line, a repeated joke, a run of more than 100 words. A draft may have to-dos, and `tools/explainers.mjs` counts them. An `approved` or `recorded` script with a to-do fails.

`tests/unit/explainer-scripts.test.mjs` breaks each rule once, on pilot 1 for format 2 and on the exemplar for format 3. `game/tests/test_explainer_turns.gd` (in `./test.sh`) makes every engine turn's questions and checks them against the turn. To read a script as a script, pull out the `caption` fields in order (or `say` where there's no caption).

| File | What it is |
|---|---|
| `pronunciation.json` | How each symbol and abbreviation is said, per tutor (see "Writing the words"). |
| `stock.json` | Each tutor's tics: the phrases that may repeat across scripts (see "Repeats"). |
| `manifest.json` | One entry per spoken line, for recording (see "Line ids and the manifest"). Written by `node tools/explainer-scripts.mjs --write-manifest`. |

### Top level

| Field | What it holds |
|---|---|
| `id` | `ex.<zone>.<idea>`, as in the map. Permanent once on `main`, because the watched record stores it. A script moved to format 3 keeps its id. |
| `format` | `3`, or `2` for a script not yet rewritten in acts. |
| `status` | `draft`, `approved` (Writer and Curriculum Author have passed it, and the checker lists no to-dos) or `recorded`. |
| `waits_for` | Optional: `["figure"]` while the script still draws a table, grid or gauge in text (see "Figures"). An approved script waits for nothing. |
| `title`, `idea` | The title card, and the idea in one sentence. |
| `zone`, `tutor` | The map zone, and its tutor's id in `teachers.json`. |
| `courses`, `syllabus`, `skills` | From the map and `curriculum/*.json`. |
| `builds_on`, `leads_to` | Explainer ids. `builds_on` drives the recall section. `leads_to` is what the recap points at. |
| `terms` | The new terms, three at most. |
| `misconceptions` | The map's misconceptions this script addresses, in the curriculum's words. |
| `estimate` | Word counts and narration time, and how they were worked out. In format 3: recorded words, main-path words and time, player actions, the longest run and the words before the first action. |
| `exceptions` | Optional. `recorded_words`: why the script needs more than the word budget. `first_example_setting`: why the first worked example has no setting from the zone. |
| `notes` | Anything a reviewer needs: a skipped section, an edit declined and why. |
| `sections` | In act order (format 2: arc order). Each has an `id`, a `kind`, its `beats` and, in format 3, its `act`. A recall section has `watched` and `not_watched` instead of `beats`, unless the explainer has no prerequisite (see Callback lines). An example has `level` and `problem`, and the first example's `problem` has `setting`, a few words on where in the zone it happens. A your-turn section has `turn`. Every spoken line lives under `sections`, because that is where the manifest finds them. |

### Beats

A beat is one of four things, or one of the player actions below.

**A spoken line.** `line` (its id), `speaker` (a tutor id), `caption` and `say`, and optional `cue`, `cue_at`, `pause`, `joke`, `clear` (wipe the board first) and `board`. Board items attached to a line are written while it is spoken.

- `caption` is what the player reads, in the board's notation: "The term in row n is uₙ, so u₁ is twenty-two."
- `say` is what the voice is sent, written the way it is spoken: "The term in row n is u n, so u one is twenty-two."
- Where the two would be the same, give only `say`. The other defaults to it.

One audio clip is made per line. The player shows the line's caption while its clip plays, and writes the line's board items with it, so no word timings are needed (#190).

**A board item.** `write` (the text as it appears on the board), or `figure` (see "Figures"), plus optional fields:

- `move`, a move id from `curriculum/moves.json`, for any line that is a working step;
- `label`, the step label shown above it, which defaults to the move's name;
- `part` (`a`, `b`, `c`), on every item that belongs to a part;
- `method` (`1`, `2`) for side-by-side working;
- `kind`, one of `heading`, `term`, `step`, `answer`, `check`, `note` or `slip`;
- `key`, so a later beat can refer to the item.

`{ "strike": "<key>" }` crosses out an earlier item with one line.

**A tap question.** `ask`, holding `kind` (`recall`, `why`, `fill`, `choose` or `tap-line`), `prompt` (on screen), `choices`, `answer` (the index of the right choice), and `right` and `not_yet` lines. For `tap-line`, the choices are board keys.

**A callback.** `{ "use": "<tutor>.<key>" }`, played from `callbacks.json`. An approved script uses callbacks only once `callbacks.json` is approved too (#189).

A line with no `speaker` is an error, because no check would see it.

### Player actions

Format 3 adds five beats (#216). A misconception is always named by its id in `question-types.json`, as in turns (`fn-pre-substitute#0`, `SL2.2.evaluate-notation#1`). Where a value can be worked out, the item carries a `check` that the checker works out and compares, so the answer key can't drift from the question. A check is arithmetic as the board writes it: `(−3)² − 4`, `20 + 12 × 5`. A unary minus binds looser than a power, so `−3² − 4` is −13, as on paper.

**The call.** `predict`, in the opener:

```json
{ "predict": { "id": "call", "kind": "type", "prompt": "What goes out when −3 goes in?", "answer": "5", "check": "(−3)² − 4",
  "values": [ { "value": "−13", "misconception": "fn-pre-substitute#0", "check": "−3² − 4" } ] } }
```

`kind` is `type` (a typed number) or `dial` (with `dial: [min, max]`). `answer` is what the lesson will show, and each of `values` is what a named misconception gives. None of them is marked.

**Back to the call.** `back_to` plays one group of lines, chosen by the stored call:

```json
{ "back_to": { "predict": "call", "match": [lines], "values": [ { "value": "−13", "lines": [lines] } ], "other": [lines] } }
```

The game compares the call with `answer`, then with each value, as numbers, and plays the first group that matches, or `other`. The recap's `back_to` has all three: `match`, a group for every value of the predict, and `other`.

**A toy.** The toy's id, its set-up and its tasks, as the lesson player reads them (`game/docs/TOYS.md`):

```json
{ "toy": "relay", "rule": "x² − 4", "dial": [-5, 5], "places": { "12": "Scrap Fields" },
  "tasks": [ { "kind": "free", "count": 3, "then": [beats] },
             { "kind": "send", "input": -3, "then": [beats] },
             { "kind": "find", "output": 12, "place": "Scrap Fields", "then": [beats] } ] }
```

The player gets the tasks one at a time. `then` is the beats played once a task is met, before the next task starts. A toy item is one machine, and its log stays on the board through all its tasks. `"optional": true` marks a toy the player can skip (oupa's radio), and an optional toy is not on the main path. The relay's tasks are `free` (that many sends of anything), `send` (that input) and `find` (any input that gives that output; 4 and −4 both give 12). The checker confirms that the toy and its task kinds are in `toys.json`, that the rule can be read, that a `send` is on the dial, and that a `find` output comes from at least one whole number on the dial. A miss still goes out, with a reaction (see "Reactions"), and the player goes again.

**A build.** The player writes the working one board line at a time, picking each from three tiles:

```json
{ "build": { "steps": [ { "tiles": [ { "write": "h(−2) = 5 − (−2)²", "move": "substitute" },
                                     { "write": "h(−2) = 5 − −2²", "misconception": "fn-pre-substitute#0" },
                                     { "write": "h(−2) = (5 − −2)²", "misconception": "fn-pre-substitute#3" } ],
                          "answer": 0,
                          "not_yet": [ { "line": "…", "speaker": "…", "say": "Input in brackets, then the square. Come in again.", "for": [1, 2] } ] } ] } }
```

Each step has three tiles, shown shuffled. One is right (`answer`), and it is a board item: it goes on the board when picked. Each wrong tile is keyed to a misconception, and is in the `for` of exactly one not-yet line, which can answer more than one tile. A wrong tile sparks off the board, a reaction plays, then its not-yet line, and the player picks again.

**A typed answer.** Inside an example, for one of its problem's parts:

```json
{ "typed": { "part": "b", "prompt": "Find C(5).", "answer": "80", "accept": ["80%"], "check": "20 + 12 × 5",
  "wrong": [ { "answer": "…", "misconception": "…" } ], "right": [lines], "not_yet": [lines] } }
```

`accept` lists other ways to write the right answer. Not-yet lines work as a turn's do (see "Which not-yet line plays"): one neutral line, and one line for each `wrong` answer's misconception. A not-yet line points at the step and asks again. It never gives the answer away, because the player types it next.

### Player actions and the words between them

The player actions are a call, a tap question, each task of a toy that isn't optional, each build step, a typed answer and a your-turn. The checker walks the main path, the lesson as one player hears it, and counts the spoken words between actions:

- A line inside a branch (right, not yet, a `back_to` group) plays after its action, so it counts towards the next run, and the longest branch is the one counted.
- After a miss on a build step, a toy task or a typed answer, the player goes again. The not-yet line comes before another action, so only the right line counts towards the next run.
- A callback line counts. A reaction doesn't, because it is a word or two and plays only on some slips.
- Each recall version is its own path.

These are findings: a to-do on a draft, and a failure on an approved script.

| Finding | Where |
|---|---|
| more than 100 spoken words on the main path between two player actions | the sections the run spans |
| more than 60 spoken words before the first player action | the opener |
| a `predict` the recap never returns to, or a recap `back_to` with no line for a match, for a value or for any other call | the recap |
| more than 1,000 recorded words in the script, every branch counted (800 for Foundations), unless `exceptions.recorded_words` says why | the script |
| a first worked example with no `problem.setting`, unless `exceptions.first_example_setting` says why | the first example |

### Turns

A `your-turn` section holds a `turn` instead of beats. Its lines are recorded once and heard with every question the turn can serve, so the turn says exactly which questions those are (#188).

| Field | What it holds |
|---|---|
| `kind`, `like` | `twin` or `exam`, and the example it mirrors. |
| `serve` | `engine`: the game draws a live question from one engine cell. `fallback`: the game asks the fixed `fallback`, and nothing else. |
| `cell` | For `engine`, the exact cell: `type` (from `curriculum/question-types.json`), `unknown`, `rep` and, where the method matters, `angle`; `format` (`value` or `mcq`) if only one will do. For `fallback`, only `type`. |
| `command` | For `engine`, the command term every question of the cell is asked with ("Find", "Solve", "Expand"). |
| `skills` | The skills the turn credits. |
| `intro`, `right`, `not_yet` | Spoken lines. |
| `fallback` | A fixed question with checked answers and working: `setup`, `parts` (each with `text`, `answer`, and optional `part` and `wrong`) and `working`. The clip renderer and the tests use it, and a `fallback` turn plays it. |

The engine serves one part at a time, asked with one command term, so a turn in parts (most `exam` turns) is served from its fallback until the engine can make it. The engine can't pin a question's story either, so no turn line may need one: a turn whose lines need a particular story is a fallback turn.

**The checker confirms:** the cell exists (the unknown is one of the type's, the representation one of the unknown's, the method one that suits it); an engine turn's fallback is one part, starting with `command`; and `game/tests/test_explainer_turns.gd` makes forty of the cell's questions and checks each is asked with `command` and offers every misconception a not-yet line names.

**Turn lines have no numbers and no story.** Every `intro`, `right` and `not_yet` line is a to-do if it says a number word other than "one" and "zero", names something from the fallback's story ("the east stand", "how many weeks?"), or, in an engine turn, talks about parts.

**A turn's consequence in the world.** A turn is still part of the lesson's world. A right answer lights the mast and the signal goes out, and a not-yet answer gets static before the player goes again. The consequence lives in the screen and the sound, not in the lines: the game shows it from the turn's result, as it shows a toy's miss. The lines stay as they are, with no numbers and no story, so they hold for every question the turn can serve. A tutor who wants to remark on the consequence uses a reaction, which names nothing either.

**Which not-yet line plays.** Each not-yet line but one names a `misconception`: its id in `question-types.json`, which is the misconception's `ref`, or `<type id>#<index>` when it has none (as `SL1.2.nth-term#0`, or `fn-pre-substitute#0`). The one line with no `misconception` is the neutral line. When an answer is wrong, the game marks it (`QuestionEngine.mark`), and:

1. if the mark names a misconception and a not-yet line is keyed to it, that line plays;
2. otherwise the neutral line plays.

A keyed line can say what went wrong, because it only plays when that slip was made. The neutral line can't assume any slip ("Put your answer back in. Does it come out level?"). For a fallback turn, each keyed misconception is the `misconception` of one of its parts' `wrong` answers (`{ "answer": "…", "misconception": "…" }`), and the game matches the typed answer against those.

### Line ids and the manifest

Every spoken line has a `line` id: six lower-case letters and digits, unique in its file, made once and never changed (#189). It doesn't come from the line's place or its text, so lines can be edited, inserted and reordered and every recording still knows its line. Audio is filed by script id and line id.

`manifest.json` has one entry per line, keyed by script id (or `callbacks`, or `reactions`) and line id: the speaker, `say` (a hash of the speaker, `say`, `cue` and `cue_at`) and `take`. The caption is not in the hash, so a caption edit never asks for a new take. `take` is null until a take is accepted, then holds the hash it was made from, the provider, model, voice, direction, date, file and the speech-to-text transcript the pronunciation check compared (Explainers E5). A line whose `say` has changed since its take needs a new one: a to-do in a draft, an error in a recorded script. The same goes for `callbacks.json` and `reactions.json`: once one is `recorded`, every line in it needs a take.

After editing lines, run `node tools/explainer-scripts.mjs --write-manifest`. A line that leaves a script moves to `retired`, and its id is never used again, because saves and takes point at it. So don't write the manifest between taking a line out and putting it back: the id would be retired. A line whose `say` is unchanged keeps its id even when it moves within its script, or when the script moves to format 3. Copy the id across, because no tool matches old text to ids. A line moved to another file loses its take. Making ids: any six random lower-case letters and digits not already in the manifest.

### Figures

A text drawing (a table lined up with spaces, a grid of │, a gauge described in words) relies on a fixed-width font and won't hold on a phone (#191). The checker lists any board line lined up with wide gaps as a to-do. Draw it as a `figure` item instead:

```json
{ "figure": { "kind": "table", "rows": [["n", "1", "2", "3"], ["uₙ", "22", "26", "30"]] }, "alt": "A table: row 1 has 22 seats, row 2 has 26, row 3 has 30." }
```

| `kind` | Fields |
|---|---|
| `table` | `rows`: lists of cells, all the same length; the first cell of each row is its header. |
| `area-grid` | `top` and `side`: the terms of each bracket; `cells`: one row per side term, one cell per top term. |
| `gauge` | `marks`: at least two `{ "at": <step>, "label": "…" }`; `steps` between the first and last mark; `needle`: steps past the first mark; `unit`. |
| `axes` | `x` and `y`: `[min, max]`; optional `points` (`{ "x", "y", "label" }`) and `lines` (`{ "through": [[x, y], [x, y]], "label" }`). |
| `number-line` | `from`, `to`; optional `marks` and `points`. |
| `balance` | `left`, `right`: what is on each pan; optional `level`. |

Every figure has `alt`, the words a screen reader reads, which are also shown if the figure can't be drawn. Labels use the board's notation. The game doesn't draw figures yet: that is a player change for Coder, on the task that builds the explainer player. Until then, a script that needs one has `"waits_for": ["figure"]` and a note saying which drawing; the six scripts that draw in text are marked that way.

### Repeats

With 336 explainers planned, a frame said in every one turns into wallpaper (#191). The checker compares every pair of scripts and lists, as a to-do in both:

- **a joke** that shares four or more content words with a joke in another script (the tin of stripped bolts);
- **a stock frame**: the same five words in a row in the frames of two scripts. The frames are the cold open's first line, the spot-the-slip's first line, the recap's last line, every tap question's right line, and every turn line.

A tutor's tics may repeat. They are in `stock.json`, taken from the voice blocks above ("Bits on the bench", "Into the book it goes", "Loud and clear"), and a phrase goes there only when its tutor's block names it. Everything else in a frame is said once: give each tutor a small bank of openers, slip intros, turn intros and praise, and use each once.

### Writing the words

- **`say` is words only.** Numbers in words, the way the tutor says them: "one hundred and seventy-eight", or "four eighty" once the number is on the board. No digits, no symbols, and abbreviations spelt as said ("G D C"). The voice gets nothing it has to guess.
- **`caption` is notation.** The board's plain text with Unicode maths, drawn by the same maths display the game uses for worked steps: uₙ, (−3)², 0.0045678, Sₙ = n/2 (u₁ + uₙ), the minus sign −, ×, ÷, ≠, ✓. No KaTeX, no markup. Inside maths, numbers are digits; in a story, they can stay in words ("Ten panels, so he bought ten posts").
- **The two say the same thing, word for word.** The checker reads the caption through `pronunciation.json` and needs some choice of agreed spoken forms that gives exactly the words of `say`: every symbol said, every number the same number, nothing added or dropped. `(−3)²` must be said with "in brackets" ("minus three, in brackets, squared"), so it can't be heard as −3² ("minus three squared").
- **The pronunciation sheet** has a default and one entry per tutor. Subscripts are said with no "sub": uₙ is "u n", u₁ is "u one", Sₙ is "S n". (n − 1)d is "n minus one lots of d", n/2 is "n over two", n² is "n squared". A tutor's entry replaces a default: Tess says "percent", never "per cent"; Rook says "zero", never "nought"; Calc says "d y by d x". A new symbol goes in the sheet before it goes in a caption. The Audio Designer's speech-to-text check (Explainers E5) compares each take with `say`, and a line that keeps failing gets a better `say`, or a sheet entry, before it goes to the owner.
- **Both texts follow the rules.** The banned words, the joke rules and the rule that no line genders the player apply to `caption` and `say` alike.
- **Say the step label** when the board shows one, so ear and eye stay together.
- **Mind SPARK players.** A tutor can talk about the world freely, but a line about the player has to work for a robot on treads (`../voice-sheets.md`).
- **Add a caption wherever a line has maths.** A `say` with maths in words and no caption ("x squared", "u n", "f of x") is a to-do.

### How each reader uses it

- **The lesson player** (#218, [FAL-1088](/FAL/issues/FAL-1088)) plays a format 3 script's beats in order, hosts its toy through `game/docs/TOYS.md`, keeps the call until the recap, and plays reactions by the rules in "Reactions".
- **The Godot player** ([FAL-429](/FAL/issues/FAL-429)) plays beats in order: one clip per line, the line's `caption` on screen while it plays, and its board items written with it. Each board item with a `move` is the same object as a worked step, `{"move": …, "board": …}` (`Step.tagged`), so the player can highlight a step and replay its move line. Tap questions and turns pause the narration. The watched record picks the recall version, the turn's `serve` and `cell` pick its question, and the marked answer picks the not-yet line.
- **The clip renderer** (`tools/explainer-clips/`) needs 3 to 5 beats and 10 to 25 seconds, so a clip takes one section, usually the big idea, and only the beats that change the board. Each chosen line becomes a `VOICE` line with its `say`, which is recorded, and its `caption`, which goes in the `.vtt`. Its slot is the word count of `say` × 0.45 s. The renderer's banned words are the same as ours.

## Before a script ships

The editor's pass, done by Writer on every script:

1. Read every `say` aloud in order, in the tutor's voice, as a tired seventeen-year-old would hear it. Cut what they would tune out. Then read every caption on its own.
2. Work every number and every step by hand, including the wrong solution in the slip and the turn fallbacks.
3. Check the length: no run over 100 words, 60 before the first action, and the word budget. Otherwise cut, or split the lesson.
4. Check the joke placement and budget, and that no line names "IB".
5. Check that each callback version works without the other, and that every call value has its recap line.
6. Run `node tools/explainer-scripts.mjs --todo` and clear every to-do, or move the script back to `draft`. An edit declined goes in `notes` with its reason.
7. Run `node tools/explainer-scripts.mjs --write-manifest` and commit the manifest with the script.
8. List anything unsure under `notes`, and on the task.

## Not decided yet

The CEO settled the pilot questions on [FAL-953](/FAL/issues/FAL-953): the map follows the scripts, the length rule is the one in "The arc", and Gauss stays as pilot 2's story. The map follows the pilots now (FAL-952): `ex.algebra.arithmetic-sequence` teaches `SL1.2.nth-term` and builds on `ex.foundations.pre-substitute`, and `ex.algebra.arithmetic-series` teaches `SL1.2.sum`. Working back from terms and from a sum are their own explainers, `ex.algebra.arithmetic-from-terms` and `ex.algebra.arithmetic-sum-unknown`. Format 2 settled turns, line ids and how symbols are said (FAL-1043). Format 3 settled the four acts, the call, toys, builds, typed parts and reactions (FAL-1087, #216). What's still open:

- **Recall in format 3.** The exemplar has no recall section, as the Writer's draft left it. Whether a format 3 lesson keeps the two callback versions, and where, is a Writer decision on the next rewrite.

- **Drawing figures.** The `figure` item is designed above, but nothing draws it yet. The Godot player needs it before any script that waits for it can be approved.
- **Turns in parts, and stories.** The engine serves one part and picks its own story, so exam turns are fallback turns for now. A turn could be served live once the engine can make a question in parts, or pin a context, on request from the explainer player's task.
- **Word timings.** One clip per line needs none. A caption that highlights word by word, or a board item that appears mid-line, would; then check whether the voice's response includes timings, and use a forced aligner on the known `say` if not (#190).
