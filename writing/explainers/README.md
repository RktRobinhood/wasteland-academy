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
| `ex.functions.function-machine.json` | One In, One Out, built on Brackets Round Negatives. Rook, about 6¼ minutes. |
| `ex.functions.gradient.json` | Rise per Step. Rook, about 6 minutes. |
| `ex.functions.line-equation.json` | Pin and Swing, built on Rise per Step and Keep the Scales Level. Rook, about 7 minutes. |
| `ex.functions.line-model.json` | Start Plus Rate, built on Pin and Swing. Rook, about 6 minutes. |
| `ex.functions.inverse-undo.json` | Run It Backwards, built on One In, One Out. Rook, about 6 minutes. |

Nothing here is recorded yet. Casting is done: the board approved all six tutors' voices on FAL-927, each one Gemini text-to-speech with a fixed model, voice and direction (`tools/explainer-clips/teachers.json`, GitHub #18). The owner auditions again only when a new character is added. Every script is a `draft` in format 2 until it passes the checks below (#188 to #191).

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
| 7 | `example`, `level: exam` | 90–120 s | First the stem, read out in one or two plain lines (10–15 s) with its givens going on the board. Then parts (a), (b), (c) with command terms, and every board habit on show. |
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

## The script format

Scripts are JSON. Both readers are code: the Godot player parses JSON natively, and the clip renderer is JavaScript. The rest of the game's words are JSON already (`game/data/shopkeeper.json`, `writing/encounters/`). Markdown with fixed headings would read better on GitHub, but it would need a parser that someone keeps up to date, and a stray heading would break it without a warning. JSON can be checked: every move id exists in `curriculum/moves.json`, every speaker is in `teachers.json`, every `use` is in `callbacks.json`. `node tools/explainers.mjs` runs these checks on every script (`tools/explainer-scripts.mjs`, FAL-952), along with the map, the arc order, board keys, answer indexes, digits and banned words in captions, and jokes on the board. To read a script as a script, pull out the `say` fields in order.

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

The CEO settled the pilot questions on [FAL-953](/FAL/issues/FAL-953): the map follows the scripts, the length rule is the one in "The arc", and Gauss stays as pilot 2's story. The map follows the pilots now (FAL-952): `ex.algebra.arithmetic-sequence` teaches `SL1.2.nth-term` and builds on `ex.foundations.pre-substitute`, and `ex.algebra.arithmetic-series` teaches `SL1.2.sum`. Working back from terms and from a sum are their own explainers, `ex.algebra.arithmetic-from-terms` and `ex.algebra.arithmetic-sum-unknown`. What's still open:

- **Casting.** The board chose the voices on FAL-927, but GitHub #18 is still open. Mags's and Tess's blocks and the four notes above can change when casting is settled there.
- **Turns, the engine and recording ids.** How a `turn` maps to the maths engine, and whether lines need ids that survive edits, are phase 2, with Coder. Until then a recording is named by section and position, frozen at `approved`.
- **How symbols are said.** "u n" or "u sub n", and the like, is decided with the voice, at recording.
- **Pictures on the board.** The board is text only, so a gauge, an axis or an area grid is written as text (the Foundations scripts do this). A drawn figure would teach some ideas better. A `figure` board item would be a phase 2 question for Coder and Artist.
