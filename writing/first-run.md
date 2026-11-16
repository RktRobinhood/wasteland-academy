# First run

The copy for a new student's first minutes (GitHub #186): the course choice, four cards on how a fight works, and the small hints around them. Written on FAL-1032 against [`glossary.md`](glossary.md). Coder applies it on Classroom C7. Strings are in code blocks so they can be copied exactly. `{n}` marks a number the code fills in.

The order on a blank save: **Play → Your course → (callsign and character, if that step is built) → The Wasteland**. The fight cards show the first time a run starts, before its first question.

## 1. Your course

Shown once, on a blank save, before The Wasteland opens. The course can be changed later in Settings and on every topic screen (string audit ST9, R3).

Heading:

```
Which maths course are you taking?
```

Line under the heading:

```
You'll only get questions from your course. You can change it later in Settings.
```

One button per course, in this order. The code (`short`) goes first, big, then the full name and the line, smaller.

| Course id | Code | Full name | Line |
|---|---|---|---|
| `aa-sl` | `AA SL` | `Analysis and Approaches SL` | `Algebra, functions, trigonometry, statistics and calculus, with some proof.` |
| `aa-hl` | `AA HL` | `Analysis and Approaches HL` | `Everything in AA SL, plus more proof, complex numbers, vectors and harder calculus.` |
| `ai-sl` | `AI SL` | `Applications and Interpretation SL` | `Maths for modelling real situations, with lots of statistics and a calculator to hand.` |
| `ai-hl` | `AI HL` | `Applications and Interpretation HL` | `Everything in AI SL, plus matrices, graph theory, vectors and more statistics.` |

A tag on each course whose `status` in `courses.json` isn't `live` (today that's AA HL, AI SL and AI HL):

```
Still being built: some topics have no questions yet.
```

Under the buttons:

```
Not sure which one? Ask your teacher.
```

The button that goes on, enabled once a course is picked:

```
Continue
```

Nothing is pre-picked. The game used to fall back to AA SL without asking (`courses.gd:21`), and that's what #186 is about.

## 2. Callsign and character (only if this step is built)

SPEC §10 promises this step. #186 keeps it optional. If the Coder builds it, use these.

```
What should we call you?
```

Placeholder in the box:

```
Callsign
```

Line under the box:

```
It shows on your name plate. A nickname works best, not your full name.
```

```
Pick who you play as
```

```
You can switch between runs.
```

The character names and classes are in SPEC §10 and `TONE.md`. Lines never gender the player.

## 3. How a fight works

Four cards, shown the first time a run starts, before its first question. Every card can be skipped.

On every card:

- Small line at the top: `How a fight works · {n} of 4`
- Buttons: `Next` and `Skip`. On card 4, one button: `Got it`.

`Skip` and `Got it` both close the cards for good and start the question. Settings gets a button to see them again:

```
How a fight works
```

### Card 1

Title:

```
Right answers hit
```

Body:

```
Get a question right and you hit the enemy. Get it wrong and you take damage, and the worked solution shows you how it goes.

At 0 HP the run ends. You keep all the Scrap you earned.
```

### Card 2

Title:

```
Beat the timer
```

Body:

```
The timer bar runs from green to orange to red. A right answer in the red still hits, but you take a little damage.

If the timer runs out, you take full damage plus 10.
```

### Card 3

Title:

```
Lock it in
```

Body:

```
Tap a choice, or type on the keypad. For a fraction, type the top, tap the fraction key, then type the bottom. Then tap Lock in.

Paper 2 questions have a Calculator button. The timer keeps running while it's open. Paper 1 means no calculator.
```

If the cards can show images, draw the fraction key here as it looks on the keypad (two boxes over a bar), so "the fraction key" points at something.

### Card 4

Title:

```
Three lifelines
```

Body:

```
You get one of each every run.

50-50 takes away two wrong choices.
Hint shows the first step of the worked solution.
Freeze stops the timer for 15 seconds.

The Bazaar sells extra charges for Scrap.
```

## 4. Hints around the map

#186: on a touch screen the first tap on a place shows its card, and a second tap goes in. Nothing says so yet. Put this line on the card after the first tap, on touch screens only:

```
Tap again to go in
```

Locked places use the string audit's wording (M10, Z3, Z4): `Closed for now: lessons coming`.

## Checks

The numbers on the cards come from the code at `f622af0`:

- Start HP 100, and the run ends at 0 (`Tuning.BASE_HP`).
- A late hit is a right answer in the last fifth of the bar (`LATE_ZONE` 0.2). You take a quarter of the enemy's damage (`STAKES.late.player` 0.25). That's "a little".
- When time runs out, you take the full damage plus 10 (`STAKES.timeout`: player 1.0, plus 10).
- Every right, late or glancing answer earns Scrap. A run banks what it earned when it ends, whether you quit or reach 0 HP (`bazaar.gd:227`).
- One charge of each lifeline per run (`Tuning.LIFELINES`). 50-50 removes two wrong choices and only works on a question with choices (`run.gd:477`, `:494`). Hint is the first step of the first worked solution (`run.gd:504`). Freeze lasts 15 s (`FREEZE_SECONDS`). The Bazaar's "Lifeline +1" adds a charge every run.
- Fraction entry: type the top, then the fraction key turns it into the top and moves to the bottom (`math_entry.gd:145-161`). Starting with the fraction key also works, with an empty top.
- Paper 2 has the Calculator button, and the clock keeps running (`practice.gd:771`). Paper 1 has no calculator.

The course lines are short summaries of each course's content, written for this screen, not taken from the syllabus wording.
