# For teachers

Wasteland Academy is a revision game for IB mathematics. Students answer exam-style questions to win fights on a run, and every wrong answer shows the worked solution. It plays in the browser at <https://rktrobinhood.github.io/wasteland-academy/>, on a phone or a laptop, and works offline after the first visit. What it stores and sends is in [`PRIVACY.md`](PRIVACY.md).

Figures on this page are from [`curriculum/COVERAGE.md`](curriculum/COVERAGE.md) on 2026-11-16. That file is regenerated from the game's engine and is the current count.

## What each course can play

A student picks their course on any topic's screen: AA SL, AA HL, AI SL or AI HL. The game then serves only that course's content.

| Course | Skills in the course | Playable | Different questions |
|---|--:|--:|--:|
| AA SL | 286 | 286 (100%) | 6,006 |
| AA HL | 452 | 290 (64%) | 6,031 |
| AI SL | 211 | 145 (69%) | 2,858 |
| AI HL | 409 | 163 (40%) | 3,245 |

A **skill** is one kind of question the IB sets within a syllabus subtopic. A skill is playable when the game can build a question that tests it.

- **AA SL** is complete: every skill in all five topics.
- **AA HL** plays everything it shares with SL, plus the counting part of AHL1.10. The other HL-only content has no questions yet, including complex numbers, proof by induction, vectors, further calculus, Maclaurin series and differential equations.
- **AI SL and AI HL** play nearly all the content they share with AA. The AI-only content has no questions yet, including Voronoi diagrams, graph theory, matrices, hypothesis tests, Spearman's rank, amortization and the modelling subtopics.

`curriculum/COVERAGE.md` breaks this down by subtopic.

Each question is labelled **Exam question** or **Training**. Exam questions are forms that appear on real papers for the course. Training covers what the papers leave out: concept checks, warm-ups and questions that link topics. A switch on each topic's screen limits a run to exam questions only.

## What the game doesn't train

The game only sees the answer a student types or picks, so it can't train:

- **Written proofs.** A proof question asks for one step the proof turns on, or for the identity that finishes it. It can't read a proof the student writes out.
- **Sketching.** Students pick the right graph from four, or type the features a sketch must show, such as the intercepts and turning points. They never draw one.
- **Method marks.** Only the final answer is marked. Wrong working that lands on the right answer counts as right, and good working with a slip at the end counts as wrong.
- **Written explanation.** Questions that ask students to explain or justify are multiple choice, picking the statement or the reason.

Keep these for written work in class.

## How typed answers are marked

Some questions are multiple choice. On others the student types the answer with the game's keypad, which has a fraction key, powers and roots.

- **Paper 1 questions want exact answers.** A typed number must equal the answer exactly: 0.5 is accepted for ½, but 0.333 is not accepted for ⅓. Surds and multiples of π go into their own boxes, for example m√r.
- **Paper 2 questions follow the IB's 3 significant figure rule.** An answer is right if it rounds to the same 3 s.f. as the exact value, or if it is the exact value correctly rounded to more figures. For 12.3456, the game accepts 12.3, 12.35 and 12.346.
- **The right value with too few figures is a glancing hit.** 2.3 for 2.347 earns half the damage and half the Scrap. In multiple choice, one wrong option is often the answer rounded to 2 s.f., to catch the same slip.
- **Equivalent answers are right** unless the question asks for a form. If it asks for integer coefficients, a line written with fractions is marked glancing and the student is told why.
- **The order of a list doesn't matter** when the answer is a set, such as two roots or two points.
- **A typed answer must work out to a number.** Entries like √2 or ln 2 in a number box are turned down with a note to work them out, and nothing is marked.

Paper 2 questions have an in-game calculator. Students can use their own GDC as well. Each question has a timer based on its marks, with 15 extra seconds for a typed answer. A right answer late in the timer still counts, but costs some HP.

On every change to the game, an independent SymPy checker solves thousands of generated questions again. It checks the answer, that only one option is right, and that the worked solution ends at the answer.

## Where progress is kept

Progress is kept on the device, in the browser the student plays in. There are no accounts and no sync.

- A student who switches from a phone to a laptop, or from one browser to another, starts again there.
- Clearing the browser's site data deletes their progress. Some school-managed laptops do this at sign-out, and Safari on iPhones and iPads may clear a website's data after about a week without a visit, unless the game is added to the home screen.
- Export and import of a save are planned (GitHub issue #185), so a student will be able to move or back up their progress as a file.

The game reports nothing to the teacher. Ask students to show you their screen if you want to see how they did.
