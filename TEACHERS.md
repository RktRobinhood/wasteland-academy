# For teachers

Wasteland Academy is a revision game for IB mathematics. Students answer exam-style questions to win fights on a run, and every wrong answer shows the worked solution. It plays in the browser at <https://rktrobinhood.github.io/wasteland-academy/>, on a phone or a laptop, and works offline after the first visit. What it stores and sends is in [`PRIVACY.md`](PRIVACY.md).

Figures below were checked against [`curriculum/COVERAGE.md`](curriculum/COVERAGE.md) on 2026-11-24. That generated report is the count source. A playable skill has at least one built question; this does not establish structural breadth, mathematical/human signoff, a finished adventure or an available narrated lesson. The [product charter](docs/PRODUCT-CHARTER.md) defines the broader classroom-ready target; the [alignment audit](docs/ALIGNMENT-AUDIT-2026-11-24.md) records remaining work.

## What each course can play

A new student is asked for their course on first launch: AA SL, AA HL, AI SL or AI HL. It can currently be changed on a topic's screen. Moving that control into Settings is accepted work still to do. The game serves only the selected course's content.

| Course | Skills in the course | Playable | Different questions |
|---|--:|--:|--:|
| AA SL | 286 | 286 (100%) | 6,014 |
| AA HL | 452 | 306 (68%) | 6,122 |
| AI SL | 211 | 157 (74%) | 2,911 |
| AI HL | 409 | 186 (45%) | 3,354 |

A **skill** is one kind of question the IB sets within a syllabus subtopic. A skill is playable when the game can build a question that tests it.

- **AA SL** has playable generators tagged to every mapped skill across all five topics. The complete AA SL game and its learning support remain the first release target.
- **AA HL, AI SL and AI HL** have partial playable coverage, including shared mathematics and some additional content. See the generated report by subtopic for what is built; complete rollout of those courses is deferred behind AA SL completion.

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

- **Paper 1 questions want exact answers.** A typed number must equal the answer exactly: 0.5 is accepted for ½. A rounded form of an exact answer, such as 0.333 for ⅓, is a glancing hit with the note "Exact value needed": the maths is right but the form is not, the way an IB paper drops the final accuracy mark. Surds and multiples of π go into their own boxes, for example m√r.
- **Paper 2 questions follow the IB's 3 significant figure rule.** An answer is right if it rounds to the same 3 s.f. as the exact value, or if it is the exact value correctly rounded to more figures. For 12.3456, the game accepts 12.3, 12.35 and 12.346.
- **The right value with too few figures is a glancing hit.** 2.3 for 2.347 earns half the damage and half the Scrap. In multiple choice, one wrong option is often the answer rounded to 2 s.f., to catch the same slip.
- **Equivalent answers are right** unless the question asks for a form. If it asks for integer coefficients, a line written with fractions is marked glancing and the student is told why.
- **The order of a list doesn't matter** when the answer is a set, such as two roots or two points.
- **A typed answer must work out to a number.** Entries like √2 or ln 2 in a number box are turned down with a note to work them out, and nothing is marked.
- **A decimal comma is accepted** where it can only be a decimal point: 0,5 is read as 0.5. Where a comma could be a decimal point or a thousands separator, as in 1,500, the game says the two ways to write it. A %, °, unit, currency sign or mixed number such as 1 1/2 is turned down with a note saying what to change. A turned-down answer is not marked and gives back the seconds it took to read the note.
- **Whole numbers of 1,000 or more.** A count, a sum, money or a binomial coefficient is marked exactly, so 1020 for 1024 is a glancing hit with "Exact value needed". A value from a calculator, such as a model's prediction, follows the 3 s.f. rule like any other Paper 2 answer.
- **Rounding too early.** On normal distribution questions, an answer that is off because z was rounded midway is a miss, and the note says so: keep z's full value to the end.
- **What the boxes give away.** A typed question shows one box for each solution, and an indefinite integral's answer is printed with its + C. So typed entry doesn't test how many solutions there are, or remembering the constant. Multiple choice does: some wrong options drop one of the solutions, or the + C.

Paper 2 questions have an in-game calculator. Students can use their own GDC as well. Each question has a timer based on its marks, with 15 extra seconds for a typed answer. A right answer late in the timer still counts, but costs some HP.

On every change to the game, an independent SymPy checker solves thousands of generated questions again. It checks the answer, that only one option is right, and that the worked solution ends at the answer.

## Where progress is kept

Progress is kept on the device, in the browser the student plays in. There are no accounts and no sync.

- A student who switches from a phone to a laptop, or from one browser to another, starts again there.
- Clearing the browser's site data deletes their progress. Some school-managed laptops do this at sign-out, and Safari on iPhones and iPads may clear a website's data after about a week without a visit, unless the game is added to the home screen.
- A student can move or back up their progress: in Settings (the gear), "Export or import save" gives a code to copy or a file to save, and the same screen imports it on another device. Back up before clearing site data. The code and file stay wherever the student puts them; the game sends nothing.
- A save the game can't read is kept aside, not deleted, and the game keeps a backup of the last good save.

The game reports nothing to the teacher. Ask students to show you their screen if you want to see how they did.
