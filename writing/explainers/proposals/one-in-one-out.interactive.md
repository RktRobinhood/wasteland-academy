# One In, One Out: interactive draft

A proposal, not a script the game or the checker reads. It reworks `ex.functions.function-machine.json` (Rook Dead-Air) to test a lesson shape before any more scripts are written or recorded. The maths, the misconceptions and most of Rook's lines are the approved script's. What changes is what the player does.

## The shape

| Act | What happens | Player does |
|---|---|---|
| 1. The signal | A situation in the wasteland and a question | Calls the output before anything is taught. Nothing is marked. |
| 2. Play the relay | The idea, found by using the machine | Dials inputs, throws the switch, hunts for an output |
| 3. Put it on paper | Notation, then worked examples that fade | Watches one, builds one line by line, types a part of the exam one |
| 4. On air | Spot the slip, exam-style turn, back to the call from act 1 | Finds the crossed wire, answers a live question |

Rules this draft holds itself to:

- **Never more than about 45 seconds of talk before the player does something.** The approved script's longest run is 281 words.
- **No longer than the approved script.** Interaction replaces talk; it isn't added on top.
- **A lesson can't be lost.** A slip has a small, funny cost in the world (static, a signal to the wrong place, Rook wincing) and the player goes again.
- **Know, then do, then apply.** The player plays with the machine, watches one worked example, builds the next one, and only then meets the exam layout.

## What would need building

| Piece | Kind | Reused by |
|---|---|---|
| Typed or dialled "call" at the start, remembered until the recap | new: `predict` | every explainer |
| The relay: a dial, a switch, a log of in and out | new: `toy` | every Functions explainer that has a rule |
| Build the working: pick the next board line from three tiles | new: `build` | every explainer |
| Typed answer inside an example | the game already types answers in maths notation | every explainer |
| Reaction lines and static, played on a slip | new: stock lines, recorded once per tutor | every explainer |

## The script

`ROOK:` is a line on the main path. `ROOK (…):` plays only on that branch. `PLAYER` is something to do.

### Act 1. The signal

Screen: the mast at dusk, the relay box at the top, a runner out of breath.

- ROOK: "Signal Tower, this is Rook. There's a relay at the top of this mast. It squares whatever comes in, takes away four, and sends the rest out to the settlements."
- ROOK: "A runner's brought up minus three. Before I throw the switch: what goes out? Your call. Over."
- PLAYER predict: type a number. It is stored and not marked.
- ROOK: "Logged. We'll find out."

### Act 2. Play the relay

Screen: the relay, with a dial from −5 to 5 and a switch. Each send adds a row to the board: `in 2 → out 0`.

- ROOK: "Here's the relay. Dial a signal in, throw the switch, and watch what comes out. Send me three signals. Over."
- PLAYER toy: send any three inputs. Rook answers each with a stock "Copy." or "Sent."
- ROOK: "What you dial in is the input. What comes out is the output. I won't swap those two words, ever. Swap them on air and a message goes to the wrong settlement."
  Board: `input: what goes in.   output: what comes out`
- ROOK: "Now send the runner's signal. Minus three. Over."
- PLAYER toy: send −3. Out comes 5. Board: `input −3:  (−3)² − 4 = 9 − 4 = 5`
- ROOK (call was 5): "Five. That's what you called. Loud and clear."
- ROOK (call was anything else): "Five. Minus three in brackets, squared, is plus nine. Take away four."
- ROOK: "Send it again. Same input. Over."
- PLAYER toy: send −3 again. Out comes 5.
- ROOK: "Five again. Tomorrow, five again. Each input gives exactly one output. That's a function."
  Board: `function: each input gives exactly one output`
- ROOK: "Scrap Fields wants a twelve. What do you send? Over."
- PLAYER toy: find an input that gives 12 (4 or −4). A send that gives something else goes out anyway: a pin lights on the wrong part of the map, static, and a stock reaction line.
- ROOK: "Four does it. So does minus four. Two inputs, one output: that's allowed. One input, two outputs: never."
- ROOK: "My oupa had a radio where one spot on the dial gave you two stations at once. Rugby and the news, on top of each other. That's no function."
- PLAYER toy (optional gag): tap oupa's radio and hear both stations at once.

### Act 3. Put it on paper

**The name**

- ROOK: "On paper the machine gets a name, f, and its rule gets written down. f of x equals x squared minus four."
  Board: `f(x) = x² − 4`
- ROOK: "f of x means the output when the input is x. So f of minus three is five. You've already sent it."
  Board: `f(x): the output when the input is x` and `f(−3) = 5`
- PLAYER tap: "What does f(3) mean?" The output when the input is 3 / f times 3 / The input when the output is 3
- ROOK (right): "Copy that. The name of the machine, then its input."
- ROOK (not yet): "Those brackets aren't a times. f is the machine's name, and three is its input."

**Watch one.** The east mast, a second relay with its own rule.

- ROOK: "The east mast runs a different rule. g of x equals six minus two x. Find g of minus four: the output when minus four goes in."
  Board: `g(x) = 6 − 2x` and `Find g(−4): the output when the input is −4.`
- ROOK: "Substitute. Every x becomes minus four, inside brackets."
  Board: `g(−4) = 6 − 2(−4)`
- PLAYER tap: "Why does −4 go in brackets?" So the 2 multiplies all of −4, sign included / Brackets show the input is negative / g(x) always needs brackets
- ROOK (right): "Copy that. Two lots of minus four, sign and all."
- ROOK (not yet): "Without brackets, six minus two minus four looks like a subtraction. The two has to multiply all of minus four, sign included."
- ROOK: "Evaluate. Two lots of minus four is minus eight. Six take away minus eight is fourteen."
  Board: `= 6 + 8` and `= 14`
- ROOK: "Say it. g of minus four is fourteen. Input minus four, output fourteen. And it's more than six, as a negative input should make it."
  Board: `g(−4) = 14: input −4, output 14 ✓`

**Your turn** (engine, `fn-evaluate-function`, unchanged from the approved script)

- ROOK: "Your channel. Rule first, input in brackets, then evaluate. Over."
- PLAYER turn: a live question. Right: the mast lights and the signal goes out. Not yet: static, and go again.
- ROOK (right): "Loud and clear. Input, output, and you kept them apart."
- ROOK (not yet): "Put the input in brackets first, then multiply. Come in again."

**Build one.** The player writes the working by choosing each line.

- ROOK: "One thing harder: a square with a minus in front. h of x equals five minus x squared. The square belongs to x, not to the minus."
  Board: `h(x) = 5 − x².  Find h(−2).` and `5 − x² means 5 − (x²)`
- ROOK: "You build the working for h of minus two. Pick each line. I'll keep the channel open. Over."
- PLAYER build, line 1: `h(−2) = 5 − (−2)²` / `h(−2) = 5 − −2²` / `h(−2) = (5 − −2)²`
- ROOK (not yet): "Input in brackets, then the square. Come in again."
- PLAYER build, line 2: `= 5 − 4` / `= 5 + 4` / `= 5 − (−4)`
- ROOK (not yet): "Minus two in brackets, squared, is plus four. Then take it away."
- PLAYER build, line 3: `= 1` / `= 9` / `= −1`
- ROOK: "One. Lekker. And x squared is never negative, so h of x can never pass five. One is under five. Out."
  Board: `Check: x² ≥ 0, so h(x) ≤ 5, and 1 ≤ 5 ✓`

A wrong tile sparks and drops off the board, with a stock reaction line. The player picks again.

**The exam layout.** The tower's battery bank.

- ROOK: "Now the way an exam sets it. The tower's battery bank charges off a solar panel. The charge, as a percentage, t hours after sunrise, is C of t equals twenty plus twelve t, from zero to six hours."
  Board: `C(t) = 20 + 12t,  0 ≤ t ≤ 6` and `t = hours after sunrise.  C = charge, %`
- ROOK: "Part a. Write down C of zero, and say what it means. Zero hours is sunrise. Twenty plus zero is twenty. That's twenty percent charge at sunrise, not zero charge."
  Board: `(a)  C(0) = 20.  At sunrise the battery bank holds 20% charge.`
- ROOK: "Part b. Find C of five. Yours. Over."
- PLAYER type: 80
- ROOK (right): "Eighty percent, five hours after sunrise. Copy."
- ROOK (not yet): "Five goes in for t. Twelve fives are sixty, and twenty more is eighty."
  Board: `(b)  C(5) = 20 + 12(5) = 80.  80% charge, 5 hours after sunrise.`
- ROOK: "Part c. The time when it's at seventy-four percent."
- PLAYER tap: "In part c, is 74 an input or an output?" An output: C(t) = 74 / An input: t = 74 / Neither: it's a percentage
- ROOK (right): "Output. Seventy-four is a charge, so it's C of t. The time is the input, and that's what they want."
- ROOK (not yet): "Crossed wire. Seventy-four is a charge, and charge is what comes out. So C of t is seventy-four, and t is what you're finding."
- ROOK: "So set the output to seventy-four and solve for the input. Take twenty off both sides: fifty-four equals twelve t. Divide by twelve. t is four point five."
  Board: `(c)  20 + 12t = 74`, `12t = 54`, `t = 4.5`
- ROOK: "Four and a half hours after sunrise, inside zero to six, so the model holds. Check: twelve lots of four point five is fifty-four, and twenty more is seventy-four. Out."
  Board: `74% charge, 4.5 hours after sunrise.` and `Check: C(4.5) = 74 ✓`

### Act 4. On air

**Spot the slip** (unchanged from the approved script, with a cost in the world)

- ROOK: "This came in over the line last night. Somebody's working, and one line has a crossed wire. Have a look."
  Board: `f(x) = 3x + 2.  Find f(2) + f(3).` then `f(2) + f(3) = f(2 + 3)`, `= f(5)`, `= 3(5) + 2`, `= 17`
- PLAYER tap a line: the first is the slip.
- ROOK (right): "That's the one. They treated f like a number you can take out of a bracket. f is a machine, not a multiplier."
- ROOK (not yet): "Look at the first line. Can two signals go through the machine as one?"
- ROOK: "Run each input through on its own. f of two is eight. f of three is eleven. Together, nineteen. Not seventeen."
  Board: strike the first line; `f(2) + f(3) = 8 + 11 = 19`
- ROOK: "Took me a week to find out who sent that one. It was me, a year ago."

**Your turn, exam style** (engine, unchanged)

- ROOK: "Your channel, and no help on the first try. Label the parts, and say what each value means. Over."
- PLAYER turn: a live exam-style question.
- ROOK (right): "Loud and clear. Every part labelled, and every value said in words."
- ROOK (not yet): "Crossed wire. Check whether the part wants an input or an output."

**Back to the call**

- ROOK: "So. A function takes each input to exactly one output. f of x is the output when the input is x. Input in brackets, run the rule, and say which one you've got."
  Board: `f(a): the output when the input is a`, then the three steps
- ROOK (call was 5): "You called five before I threw the switch. Now you can say why."
- ROOK (call was −13): "At the start you called minus thirteen. That's the brackets going missing. Half the map makes that call once."
- ROOK (any other call): "At the start you called it differently. Now you'd call five, and you could say why."
- ROOK: "Next time we run the relay backwards. Output in, input out. That's the transmission. Rook, out."

## Stock reaction lines

Recorded once for Rook and reused in every one of his lessons, like `callbacks.json`. They never name a number or a topic. Each tutor would get a set of about eight.

- "Copy."
- "Sent."
- "Static. Come in again."
- "Eish. That one's gone to the wrong settlement. They'll cope."
- "Shame. The relay didn't like that."
- "Hold on. Something's smoking up there. Go again."

## For the Writer and the Curriculum Author to check

- "Two inputs, one output: that's allowed" is new to this lesson. It is true and it sets up inverses, but it is a second idea, so cut it if it crowds the first.
- The first worked example now belongs to the east mast and is called g, so the lesson has f, g, h and C. The approved script used f twice.
- The check on the first worked example is folded into the "say it" line to save a beat. The board still shows it.
- The stock reaction lines are a first pass at Rook being put out without the player being told off.
