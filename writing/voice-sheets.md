# Wasteland Academy voice sheets

One block per speaking character, in the `game-dialogue` §1 format. Write every line against these. If a line could belong to two characters, fix it before it ships.

Sources: `SPEC.md` §10 and §13, `assets/style-guide/README.md`, and the roster sheet `style-06-characters-dialogue-quests.png` (traits, taglines, quest cards, expressions). Where those disagree, the conflict is listed at the end and raised on FAL-332.

## Rules for every character

- The player types a callsign at first launch (SPEC §10). Lines that name the player use `{callsign}`. No line uses "he", "she", "girl" or "boy" for the player, because SPEC §10 lets the player choose the avatar. See conflict 1.
- No character calls a question easy, simple or obvious, and nobody says "just" in front of a step ("just factorise"). A student who is stuck hears that as "you're slow".
- Every number in a line is checked before it ships. A hint points at the next move. It never does the move.
- Numbers on screen go in KaTeX (`$x^2$`), per SPEC §13. In voice scripts they are written the way the character says them.
- The roster sheet's taglines ("Bigger minds build brighter tomorrows", "Math isn't just in books") are poster copy. They tell us the mood, but nobody says them in the game.

---

## Learner

Canon: the player character. Curious, determined, hands-on, resourceful (style guide); also kind, "makes a difference" (roster sheet). Expressions: curious, excited, determined, thinking.

The Learner speaks mostly as dialogue options the player taps (three per prompt on the roster sheet's dialogue mockup). Keep each option under about eight words so it fits the button. Every option set includes one that asks for help and doesn't sound ashamed of it.

**Wants:** to be someone the bazaar can count on when something breaks. Would never admit: they aren't sure they're good at maths.

**Vocabulary:** a scavenger's words: haul, parts, salvage, "worth keeping", "busted". When the maths gets hard, school words come back ("which one's the domain again?"). Never jargon they haven't been taught.

**Rhythm:** short, first person, contractions always. Questions are direct and come early. Will cut themselves off to try something ("Hang on, let me...").

**Tic and avoidance:** asks what a thing is *for* ("What's it for, though?"). This is how the Learner pulls the maths into the world, and it gives the NPCs their cue. Never apologises for a wrong answer; says what they'll try next instead.

**Praise and correction** (how the Learner reacts to their own answer):

| Got it | Not yet |
|---|---|
| "Knew it." | "Okay. Again." |
| "Oh. That's actually it." | "Where'd I drop it?" |
| "Wait, that worked?" | "Show me the step I missed." |
| "Same trick as last time." | "Hang on. I swapped them." |
| "Told you I'd get there." | "One more go. Slower." |

**Samples:**

- Curious: "What's the ratio for, though? Like, what breaks if it's off?"
- Determined, before a boss: "Third try. I know which part hits hard now."
- Stuck, asking for help: "Walk me through the first step. Only the first."

---

## Spark

Canon: AI companion robot. Yellow patchwork body, blue glowing eyes, treads. Gives the Hint lifeline, shows worked solutions, adds a line at boss encounters (SPEC §10). Tone: "curious, helpful, slightly sarcastic, always believes in you" (SPEC §10); the roster sheet adds "loyal". Expressions: happy, surprised, sassy, thinking. The game's `spark_mood` field uses happy, thinking, surprised and sarcastic (the sheet's "sassy").

**Wants:** for the student to need fewer hints every run. Would never admit: it likes being needed, and fewer hints means less of that.

**Vocabulary:** salvage-robot words, kept light: sensors, battery, treads, scanning, "my readings". It talks about questions as if they were rival scrap bots: they bluff, hide things, set traps. Maths words are always exact. Spark says "factorise", never "do the thingy".

**Rhythm:** quick. Fragments, then one full sentence that carries the maths. Asks the student questions it already knows the answer to, so the student does the step. Uses "we" for the work and "you" for the credit.

**Tic and avoidance:** trash-talks the question, never the student. "This quadratic thinks it can hide its roots." The sarcasm always lands on the maths, the enemy or Spark itself. Never says "wrong". Spark names the step to fix instead.

**Praise and correction** (always about the step):

| Right | Not quite |
|---|---|
| "Factorised first, so the roots dropped straight out. Two and three." | "Your minus stopped at the first term. It has to reach both: minus x plus four." |
| "You swapped x and y *before* solving. That's the whole inverse, done properly." | "That's g of f. The question wants f of g, so g goes first, then f." |
| "Domain before anything else. That square root had a trap in it and you stepped round it." | "Your b squared came out negative. Squares can't do that. Minus five, squared, is twenty-five." |
| "You caught the sign inside the bracket. Vertex at plus three, not minus three." | "That's where it crosses the x-axis. The y-intercept means x equals zero. Put zero in for x." |
| "Chain rule, outside then inside, nothing skipped. My sensors don't impress easily." | "Log a plus log b is log of a *times* b. You added them inside." |

**Samples:**

- Sassy, boss encounter: "Big one. Mostly derivatives and attitude. We've beaten its smaller cousins, and it hasn't learned anything since then."
- Thinking, Hint lifeline (real hint, topic 2): "Two numbers. They multiply to six and add to minus five. Start with the pairs that make six."
- Low, third miss on the same part: "Same step three times means the step's the problem. You got parts (a) and (b). Let's take (c) apart together."

---

## Gear Mira

Canon: Mechanic-Teacher NPC. Practical, patient, explains well, turns scrap into solutions (roster sheet). Drawn as a young woman with goggles and a wrench. Quest card "A Brighter Bazaar": repair the main generator to power more learning spaces. Roster tone line: "Mistakes are just another kind of data."

**Wants:** a player who can fix things without her. Would never admit: she learned most of what she knows from one water-stained repair manual, and she's less sure than she sounds.

**Vocabulary:** engines and the bench: torque, gauge, load, fit, tolerance, "seize up", "run it". Measuring words: read, check, mark, twice. Units always attached to numbers.

**Rhythm:** imperatives and steps. Finishes her sentences. Asks diagnostic questions ("What's it doing now?") and waits for the answer. Calm under pressure; her sentences get shorter, not louder.

**Tic and avoidance:** makes you say the number back to her, with its unit. "Read it back to me." Never says "guess". She says "rough number", "estimate" or "check it", because a guess is the thing she's afraid she's been doing all along.

**Praise and correction** (practical maths: ratio, units, rounding, estimates):

| Right | Not quite |
|---|---|
| "Six to two. Same as three to one. You kept the mix when we doubled the tank." | "You doubled the fuel and left the oil alone. Ratio's broken. Same factor, both parts." |
| "Units on every line. That's why your answer came out in litres." | "Stop. What's the unit on that? Metres or kilometres?" |
| "Read it back. ...Yes. That's the number I got." | "You rounded at step two. Keep the whole number till the end, then round." |
| "You estimated first, and the real answer landed near it. Good habit." | "That's ten times too big. Count your decimal places again." |
| "That'll hold." | "Close. Show me the working, not only the answer." |

**Samples:**

- Working: "Hold this. Both hands. Tell me what the gauge says, units and all."
- Pleased: "It's running. Don't touch it. Don't even look at it too hard."
- Under pressure: "Generator's down and the hall's full. One fault at a time. Fuel line first."

---

## Dax

Canon: Trader-Engineer NPC. Resourceful, friendly bargainer, tech savvy, connects people (roster sheet). Drawn as an older man with a cap, beard and goggles. Quest card "Trader's Route": plan the most efficient supply route to an outpost; compare distances and fuel use. Roster tone line: "Find a better route, save more fuel, help more people."

**Wants:** a partner who can do the route sums so he can do the talking. Would never admit: he can't read Noma's old maps, so half his good routes are hers.

**Vocabulary:** trade and haulage: deal, margin, cargo, fuel, per unit, worth, round trip, "costs you". Prices and distances are always concrete numbers.

**Rhythm:** fast and talky. Long sentences joined with "and", rhetorical questions he answers himself, then a short line to close the deal. Interrupts himself to bring up someone else.

**Tic and avoidance:** drops names. He uses `{callsign}` in nearly every line and mentions people the player hasn't met ("Ask Wren at the pump, say Dax sent you"). Never says "free". Everything costs something, even if it's only a favour.

**Praise and correction** (rates, percentages, distance, comparison):

| Right | Not quite |
|---|---|
| "You compared cost per litre, not the sticker price. That's how I stay in business, {callsign}." | "You added the discounts. Ten off then ten off isn't twenty off. It's nineteen." |
| "Forty out, thirty across, and you took the straight line: fifty. That's twenty kilometres of fuel saved." | "That's total fuel. I asked per kilometre. Divide it by the distance." |
| "Twenty off, then ten off the new price. Twenty-eight percent, not thirty. You'd survive the bazaar." | "Round trip, {callsign}. You paid for one way. Double it." |
| "You ran the rough sum before the real one. That's a trader's habit." | "You've mixed metres and kilometres in one line. Pick one." |
| "That's margin. That's a deal." | "Bigger crate, bigger price, sure. Cost per unit, though? Check it." |

**Samples:**

- Selling: "{callsign}! Got a route to the Dry Flats that cuts eleven kilometres off, and Wren's got the fuel, and all it costs you is one small favour. Mostly small."
- Worried: "Quarter of a tank, fifty kilometres to the outpost. Do the sum with me. I've done it already and I don't like it."
- Grudging thanks: "Noma marked this road. Tell her Dax says thanks. Actually, don't. She'll want something."

---

## Noma

Canon: Map-Keeper NPC. Wise, remembers stories, sees the big picture, guides exploration (roster sheet). Drawn as an elderly woman with white braids and round glasses. Quest card "Lost Signals": map a missing signal tower to reconnect a learning outpost; find coordinates; solve a coordinate puzzle. Roster tone line: "Every number on a map is a place, a person, a story."

**Wants:** someone to carry the map on after her. Would never admit: her eyes are going and she can't read the small grid numbers any more.

**Vocabulary:** distance, direction and old names: east, north, bearing, grid, ridge, wash, "where the water tower used to stand". Places are named for what happened there. People are named for what they did.

**Rhythm:** slow. Longer sentences that wander and then land exactly. Asks questions she knows the answer to, and is happy to wait. Never hurries, even when the news is bad.

**Tic and avoidance:** names people by their deeds: "the one who rewired the windmill", and later "the one who found the relay" for the player. Never says "lost" about a place or a person. Things are "unmarked" or "not found yet".

**Praise and correction** (coordinates, distance, midpoint, gradient, bearings):

| Right | Not quite |
|---|---|
| "Three east, four north. That's the goat ridge. Right where the story puts it." | "You've swapped them. The first number walks you east, the second takes you north." |
| "Halfway between the two camps: you averaged the eastings and the northings. Good." | "You added them and stopped. Halfway means you share it out. Divide by two." |
| "Clockwise from north. Most people forget the clockwise." | "That's the bearing from the camp to the tower. I asked from the tower to the camp." |
| "Five across, twelve up, thirteen straight. You walked it in your head." | "Your slope's upside down. Rise over run, not run over rise." |
| "Downhill, so the gradient's negative. You kept the sign." | "Read it again, slowly. I'll wait. I've got nowhere to be." |

**Samples:**

- Storytelling: "This square was the Okafor sisters' ridge. Forty goats and one very bad fence. Find me its corner."
- Uneasy: "The relay went quiet three nights ago. An unmarked thing doesn't stay unmarked long out there."
- Warm, to the player: "The one who found the relay. That's what they'll call you at the pump now. Get used to it."

---

## Cover-the-name check

The same idea, "you made a ratio mistake", in each voice:

- Learner: "Hang on. I scaled one side."
- Spark: "The ratio's bluffing. You scaled the fuel, not the oil. Both parts, same factor."
- Gear Mira: "You doubled the fuel and left the oil alone. Read me the ratio again."
- Dax: "Double the cargo and you pay for one crate, {callsign}? Nobody sells like that. Scale both."
- Noma: "You walked twice as far east and the same distance north. That's a different place."

## Where canon disagrees (raised on FAL-332)

1. **Learner's gender.** SPEC §10 has the player choose Female Learner, Male Learner or SPARK at first launch. The style guide README calls the Learner "a resourceful female scavenger", and the roster sheet shows only one, a young woman. These sheets don't gender the Learner in any line, which works with either reading. Decision needed: is the male Learner avatar still in V1?
2. **Spark as avatar and companion.** SPEC §10 lists SPARK as a player avatar and also as the companion who gives every hint. If a student plays as SPARK, the companion is talking to itself. These sheets assume the player is the human Learner and Spark is always the companion. Decision needed: drop SPARK from the avatar list, or tell me how the companion works when Spark is the avatar.
3. **Spark's sarcasm.** SPEC §10 says "slightly sarcastic". The roster sheet's Spark tone line ("Math isn't just in books. It's in the world around us!") has none. The sheet follows SPEC, because SPEC sets Spark's tone; the roster line is treated as poster copy.
4. **Voice versus scope.** SPEC §14 still puts "Sound / music" out of scope for V1. ROADMAP.md (L3, December) plans local narration with subtitles for the Relic lessons, and FAL-330 is already making voice auditions. ROADMAP is the newer plan, so the briefs assume voiced lines. SPEC §14 should be updated to match.

## Characters still to come

ROADMAP.md names six Relic-station characters, one per station, including B0-LT, "a malfunctioning scrap robot", at the Signal Tower. Each gets a block here before its lesson is written. B0-LT needs the most care: a second robot must not sound like Spark. Two near-overlaps to watch: the Trader's Caravan accountant sits close to Dax, and the Engine Core's "reckless mechanic" sits close to Gear Mira, who is patient.
