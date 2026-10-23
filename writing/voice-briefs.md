# Voice briefs: Spark, Gear Mira, Noma

For local voice design (VoxCPM2 on the shared GPU), per `game-dialogue` §5. Each character gets a short **control** string to paste into the model, notes for whoever picks the takes, and a six-line audition script. The script lines come from the voice sheets (`voice-sheets` on FAL-332), so the audition tests the lines the voice will actually say. Numbers and symbols are spelled the way the character says them.

The FAL-330 round used one neutral line per character, with no contractions ("Let us start with the gap"). That line can't show sarcasm, patience or age. These scripts cover each voice's full range: greeting, praise, correction, a tense moment, a joke and the tic.

---

## Spark

**Control:**

> A small robot companion with a bright, light, youthful voice, gender-neutral, quick pace with short sudden pauses, crisp clear consonants, dry amused tone with real warmth underneath, a little mischievous, lively but never shouting.

**Notes for picking a take:**

- Spark gives every hint and correction, so players hear this voice most. Pick the take that a stuck student wouldn't hear as mocking. The sarcasm should sound fond.
- Canon gives Spark no gender. FAL-330 tried an androgynous voice (Spark A) and a light male one (Spark B). This brief keeps it gender-neutral, closer to A.
- The voice model shouldn't try to sound robotic. If Spark needs a metallic or radio edge, add it afterwards as a light audio effect, so the words stay clear.
- Pace: quick on the jokes, slower and clearer on the maths line of each correction.

**Audition script:**

1. Greeting: "There you are. I've counted every bolt in this bazaar twice. Ready?"
2. Praise: "You factorised first, so the roots dropped straight out. Two and three."
3. Correction: "Your b squared came out negative. Squares can't do that. Minus five, squared, is twenty-five."
4. Tense, boss encounter: "Big one. Mostly derivatives and attitude. Stay with me, and take the first part slow."
5. Joke and tic: "This quadratic thinks it can hide its roots. Watch it fold the moment you factorise."
6. Hint (the live game's hint for x squared minus five x plus six): "Two numbers. They multiply to six and add to minus five. Start with the pairs that make six."

---

## Gear Mira

**Control:**

> A woman in her late twenties with a warm, slightly husky mid-low voice, steady unhurried pace, plain clear English, practical and patient, a voice used to carrying over engine noise, with a smile in it when she is pleased.

**Notes for picking a take:**

- The roster art shows a young woman with goggles and a wrench. FAL-330's Mira B ("slightly husky midrange") was closer to her than Mira A; this brief keeps the husk and adds her age.
- Mira gets quieter and shorter under pressure, never louder. Line 4 tests that.
- She waits for answers. Pick a take that leaves a real gap after "Read it back to me".

**Audition script:**

1. Greeting, at work: "Hold this. Both hands. Tell me what the gauge says, units and all."
2. Praise: "Six to two. Same as three to one. You kept the mix when we doubled the tank."
3. Correction: "You doubled the fuel and left the oil alone. Ratio's broken. Same factor, both parts."
4. Tense: "Generator's down and the hall's full. One fault at a time. Fuel line first."
5. Joke: "It's running. Don't touch it. Don't even look at it too hard."
6. Tic: "Read it back to me. Two point four amps? Good. That's the number I got."

---

## Noma

**Control:**

> An elderly woman of about seventy-five, low-to-mid pitch, soft grainy texture with a little breath in it, slow measured pace with natural pauses, clear diction, warm and dry, quietly amused, like someone retelling a story she has always enjoyed.

**Notes for picking a take:**

- The roster art shows Noma as an elderly woman with white braids and round glasses. Both FAL-330 controls said only "adult woman", which is why those takes sound too young. Age is the first thing to listen for.
- Noma is never rushed, even with bad news (line 4). Reject takes that speed up there.
- Her humour is dry. Line 5 should get a small smile, not a laugh.

**Audition script:**

1. Greeting and tic: "Ah. The one who fixed Mira's generator. Come and sit. Mind the maps."
2. Praise: "Three east, four north. That's the goat ridge. Right where the story puts it."
3. Correction: "You've swapped them. The first number walks you east. The second takes you north."
4. Tense: "The relay went quiet three nights ago. An unmarked thing doesn't stay unmarked long out there."
5. Joke: "This square was the Okafor sisters' ridge. Forty goats and one very bad fence. The goats won."
6. Patience: "Read it again, slowly. I'll wait. I've got nowhere to be."

---

## For the render run

- One take per line per seed, at least two seeds per character, so takes can be compared line by line.
- Every line is under 15 seconds at the brief's pace. The longest, Spark 3 and Spark 6, run about 7 seconds.
- Check the transcripts for "b squared", "factorised" and "Okafor"; the model may stumble on them. If it does, keep the spelling and note it, so we know which words need a fix later.
