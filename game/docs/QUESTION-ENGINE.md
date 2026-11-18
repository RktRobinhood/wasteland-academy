# The question engine

The reference for the Godot game's question engine: recipes, situations, views, answers and marking, region by region, and the tools that check it. Split out of [`game/README.md`](../README.md) on FAL-1046 (#198). The reusable interface over it is in [`MATHS-ENGINE.md`](MATHS-ENGINE.md).

Paths are relative to `game/` unless they start with `tools/` or `curriculum/`, which are at the repo root.

## Recipes, situations and views


The maths engine plans from situations and views (FAL-310 plan), on the catalogue in
`curriculum/question-types.json`. The game reads a generated copy,
`data/catalogue.json`, with every type of all five topics and the topic names: rerun `node tools/game-catalogue.mjs --write` after changing the
catalogue (`tests/unit/game-catalogue.test.mjs` fails while the copy is stale).

- A **recipe** (`engine/situations/quadratic.gd`) generates a **situation**: a, the
  roots, the vertex, b, c, Δ, an extra point and a table, consistent and inside the
  catalogue's `clean` limits, in one of its `modes` (rational roots, surd roots, no real
  roots). Situations that extend `quadratic` call its `generate()` and add their own
  quantities. `engine/situations/triangle.gd` is the Topic 3 situation: one triangle
  ABC, with whole-number givens for the view (two sides and the angle between them,
  three sides, two angles and a side, and so on), solved whole. Its views
  (`triangle_views.gd`) show it in words or as a labelled drawing (`ui/triangle_view.gd`),
  and on Paper 2 every answer is a measure to 3 s.f. (FAL-395), never a rational value
  that needs no calculator. Its Paper 1 version (FAL-419) gives angles of 30°, 45°, 60°,
  90°, 120° or 135° and sides chosen so the answer is exact: a whole number (3, 5, 7 with
  120°) or m√r (the `surd` kind), marked exactly, with the exact sines and cosines in the
  working. On Paper 2 the working shows four figures, or more where the next step
  worked from four would be off in its last place (FAL-412: h = 10.465, not 10.47, so
  ½ × 16 × h gives the 83.7 shown); `tools/check-answers` works out every step's
  arithmetic from the figures shown. Every cell makes both papers but the sine rule's angle, which is Paper 2 only.
  `t3-ambiguous-case` (FAL-412) is on the same situation, Paper 2 only. Its `ssa-two`
  givens fit two triangles (`second` on the situation), both inside the limits, and its
  questions ask both values of the angle or both lengths of the third side. The answer
  is the `measures` kind: two 3 s.f. measures in either order, each marked like
  `measure`, with an option that stops at one (`only`). Its diagram draws both triangles
  on one base line, lettered B₁ and B₂ (`second` in the diagram spec), with a measuring
  line under the base for each asked length. `largest-angle` uses `ssa-mix`, one triangle
  or two half and half, in words only since a drawing would show how many fit, so the
  student has to decide before answering: the acute angle is right only when the obtuse
  one has no room. The checker solves each question from the sine rule and from the
  cosine rule as a quadratic, and the two must agree.
- `engine/situations/counting.gd` (FAL-695) is `t1-ahl-counting`, the first type built for
  AA HL only (AHL1.10, so on no other course's list, see "Courses"). It is an `extension`
  type, since the question bank behind the exam types is AA SL's and has no counting part;
  a count is exact, so every answer is a whole number of ways. Its views
  (`counting_views.gd`) ask 11 unknowns, from a story or, where the count has a symbol,
  as `7!`, `10P3`, `12C4` or `nP2 = 56`: a code (26^a × 10^b), numbers with no repeated
  digit, even numbers from 1 to m, n!, nPr for medal places, n from nP2, a committee,
  one with exactly j women, one with at least one woman, and two people together or
  apart in a row. Wrong options are AHL1.10's misconceptions (the leading zero, adding the
  stages, the free digits first, nCr for an ordered result, n^r, n!/r!, adding the groups,
  counting a committee twice, nPr for a committee, forgetting the block's own order,
  n! − 2). `tools/check-answers` counts every case again by listing the arrangements.
  The curriculum tools (`tools/pedagogy.mjs`, `tools/game-catalogue.mjs`) read skills from
  `aa-hl.json` and `ai.json` as well as `aa-sl.json`, so a type may name an AA HL or AI
  skill; the rule that every AA SL skill has a type still counts AA SL's alone.
- `engine/situations/arithmetic_sequence.gd` (FAL-392) is the Topic 1
  situation: one arithmetic sequence with u₁, d, n, uₙ, Sₙ, two later terms and the
  first four terms, for `t1-arithmetic-sequence`. Its representations are `notation`
  (u₁ = 7,  d = 3), `terms` (7, 10, 13, 16, …), `table` (n against uₙ) and `words`,
  and its answers are marked exactly (`exact` on the answer), because Paper 1 wants a
  whole-number sum such as 1807, not 1810. Its Paper 2 version (FAL-419), in words only,
  is a savings plan in dollars and cents or a training plan in km with a decimal u₁ and
  d, worked with a GDC: a term or a sum (money to 2 d.p. or a decimal, still exact, since
  it ends), or the first week or day whose term or running total is more than a round
  threshold (a whole n). Any type with a `situation` gets a copy in
  `data/catalogue.json`, whatever its topic.
- `engine/situations/arithmetic_context.gd` (FAL-752) is `t1-arithmetic-in-context`, Paper 2 throughout
  as every part of it in the bank is: an arithmetic sequence in a story, with
  `ArithmeticSequenceSituation`'s `term` and `sum` doing the sums. Its views
  (`arithmetic_context_views.gd`) show the story in words, a table of the first terms or of data, a
  graph (the line of uₙ against n with two labelled dots and the target drawn, or the data's labelled
  dots) or a figure (`stages` in `ui/plot_view.gd`: stacks of 1, 2 and 3 rows side by side), and ask 20
  unknowns. SL1.2.model: a term and a total (seats, pay, runs, hauls, a failing well), which calculation
  a question wants, "in year n" against "once n full years have passed", an amount after n steps, simple
  interest, d from first and last or as a regression gradient, a prediction from either, a comment on
  validity (near the data, far past it, or over a limit in the story), a stack's total, and the
  greatest running total of terms that fall past 0. SL1.2.find-n: the term with a value, the term that
  reaches 0, the number of terms, the first term or running total past a target, whether a value is a
  term at all (a whole n), and the fewest rows that use whole crates. What ends is marked exactly, what
  comes from imperfect data is to 3 s.f., and a judgement is a picked statement.
- `engine/situations/distribution.gd` (FAL-396) is the Topic 4 situation: one
  discrete random variable X with 3 to 5 values, its probabilities as multiples of k,
  a formula P(X = x) = k f(x) or decimals, or a game with prizes and a stake. Its views
  (`distribution_views.gd`) show it as a table, a formula or in words, and ask k, a
  missing probability, P(event), E(X), p and q from E(X), the fair stake, an expected
  number of occurrences or the number of trials. Every cell makes both papers (FAL-419):
  Paper 2 has awkward decimals to 3 d.p. (0.137), k beside them or in a reciprocal
  formula (k/x), and a lucky dip of 1000 tokens; k, E(X), an expected number and a
  formula's P(event) are then answered to 3 s.f. with the rounding trap, the stake to the
  nearest cent, and the rest exactly. Paper 1 keeps its numbers.
- `engine/situations/binomial.gd` (FAL-695) is `t4-binomial`, the first type built from
  the course audit's list (SL4.8, on all four syllabuses): X ~ B(n, p), with n from 5 to 20
  (more for a mean) and p in steps of 0.05. Its views (`binomial_views.gd`) show it as
  X ~ B(12, 0.35) or as one of eight stories (seeds, filters, scans, cans, arrows,
  bridges, drone trips, batteries), and ask 12 unknowns: n and p from a story, P(X = k),
  at most / fewer than, at least / more than, between, E(X), Var(X), the standard
  deviation, n and p from E(X) and Var(X), the least n for P(X ≥ 1) > c, "the kth success
  is on trial m" and a conditional P(X = j | X ≥ 1). Every question is Paper 2 (every
  binomial part in the bank is): probabilities and the standard deviation are answered to
  3 s.f. with the rounding trap, E(X), Var(X), n and p exactly. Probabilities are floats,
  as a GDC computes them, and the working uses binompdf and binomcdf, nCr, the complement
  or a sum. Wrong options come from the SL4.8 misconceptions (no nCr, swapped powers, cdf
  for pdf, `1 − P(X ≤ k)` for at least k, `< k` read as `≤ k`, the wrong subtraction for
  a range, Var = np, σ = Var, E(X) rounded, n rounded down, p = Var ÷ E, a kth success
  read as k in m trials, a conditional multiplied). As every exam type, it offers no extra
  format (error-spot, method-pick, true-false-reason): `test_extension.gd` holds that rule.
- `engine/situations/binomial_expansion.gd` (FAL-728) is `t1-binomial-term` (SL1.9, on the AA
  courses): one bracket (ax^p + b)^n, or nCr alone, with every coefficient a whole number worked
  out exactly. Binomial expansion, not the distribution above. Its views
  (`binomial_expansion_views.gd`) show the bracket or nCr, or Pascal's triangle as a staggered
  grid with no row numbers (a table, as reading the row is the skill), and ask 28 unknowns: nCr by
  formula, from the triangle, by symmetry, at the edges and with n to find, nC2 as a polynomial,
  a row of the triangle, the next row and n from a row, the number of terms, full expansions
  (small n, (x + b)^n, a negative term, a number beside x, x², b/x), the first three terms, one
  coefficient in the same shapes, a coefficient in terms of a letter, the term in x^k, a coefficient
  left as a letter, and the term in a given place. The GDC's nCr is Paper 2 only; the other cells
  make both papers, with Paper 2 having the longer rows. A question that reads the triangle stays
  at row 7. An expansion is typed term by term, and a row without its ends. Wrong options come
  from the SL1.9 misconceptions and the type's own five (no r!, the negative root for n, n terms,
  the place taken as r, (1/x)^r read as falling by one power).
- `engine/situations/differentiation.gd` (FAL-723) is `t5-differentiation-rules` (SL5.6, AA only):
  one function to differentiate, with whole-number coefficients. Its views ask 18 unknowns:
  standard results and rational powers, the chain rule on a bracket, an exponential, a log, a
  trig function or a root, the product and quotient rules, each with a rewrite beside it where
  the map lists one, a derivative shown to take a given form, a gradient at a point (one unknown
  per rule, so each keeps its one route) and a derivative with the letter p left in, which is
  Paper 2 only. A derivative is a `form` answer (see `engine/answer.gd`): the student types the
  numbers into the expression and it is marked exactly; a wrong option in another shape carries
  `shape`, so it can be picked but never typed. A Paper 1 gradient is exact (a whole number, a
  fraction, or −2e³), and a Paper 2 gradient is at an x to 1 d.p., to 3 s.f.
- `engine/situations/derivative_meaning.gd` (FAL-723) is `t5-derivative-meaning` (SL5.1, on all
  four syllabuses): a quantity in one of eight stories, modelled by A + B e^(−kt) or A + B sin(wt),
  and rational functions with 0/0 at a point. Every question is Paper 2, as every bank part is.
  It asks a rate from the GDC, what a rate means, its units, a sentence in derivative notation,
  a comparison of two rates, the limit of a model or of its rate as t → ∞, and a limit from a
  table, from a graph with a gap and a dot, or by cancelling. A reading in words is a `claim`.
- `engine/situations/derivative_graph.gd` (FAL-754) is `t5-derivative-graph` (SL5.7.f-from-derivative-graph
  and SL5.2.sign-from-graph), the `derivative-graph` situation: 13 unknowns over 29 cells, all Paper 1
  and exact. Three curve families, each with whole-number roots so every feature sits on a grid line:
  k(x − a)(x − b)², which crosses at a and touches at b (as f′, f″, or f itself), a parabola
  k(x − a)(x − b) with a whole vertex, and a parabola cut into two regions with whole, different areas.
  From f′ it asks a local maximum or minimum and its justification, points of inflexion, the nature of a
  touch, where f rises past the touch, where f is concave up, which of four graphs could be f, and a
  value or comparison of f from the signed areas; from f″ a point of inflexion; from f the sign of f′,
  where f′ is negative and the gradient at a turning point. The views (`derivative_graph_views.gd`) show
  the graph (regions shaded and lettered A and B), f′ or f″ as factors, or the stretches in words. A
  justification or comparison is a `claim`; an interval is MonotonicViews' between/outside form, and a
  wrong "x > 1" beside one carries `side`, so it can be picked but never typed.
- `engine/situations/optimisation.gd` (FAL-739) is `t5-optimisation-modelling` (SL5.8): one shape or
  journey with a fixed amount and one free length, in eight families: a yard against a wall with fixed
  fence, a plot against a wall with fixed area, a cylinder (closed or open, area or cost), an open
  square-based bin from a fixed sheet, a tray cut from a sheet, a rectangle under an arch, a route off
  a road (time or cost) and the closest point on a curve. Its 15 unknowns are the exam's stages: a
  second length from the constraint, a function built from a figure, a "show that", the derivative
  (from the one-variable function, or from two variables and a constraint, where the option that
  doesn't eliminate is the trap), the stationary point, an exact value (m√t on Paper 1, a cube root
  on Paper 2), the second-derivative and sign-change justifications, the optimum value, the second
  length, a quadratic by the vertex, a tray whose second root is outside the sheet, and a route's
  best point and least value. A "show that" follows `show-form`: the target has letters where its
  numbers go, and the student states them. Paper 1 is exact, with π left in; Paper 2 is to 3 s.f., and
  the GDC is a method there. A route is Paper 2 and a closest point Paper 1, as in the bank. Figures
  are PlotView's `sketch` and `solid` (which gained a cylinder, an open cylinder and an open bin) or a
  graph with its rectangle shaded. The checker reads the shape back from the words or the figure,
  builds the function again, and solves it with SymPy, or mpmath for a route (`check_optimisation`).
- `engine/situations/tangent_meets.gd` (FAL-754) is `t5-normal-meets-curve` (SL5.4), the
  `tangent-meets-curve` situation: a curve, a point P where x = x₀ (a whole number), and the tangent
  or the normal there, followed to the axes, to the triangle it cuts off with them, or to the curve
  again. Every question is Paper 2, as both bank parts are. The curve is ax² + bx + c, a cubic,
  px² + A/x + q or Ae^(kx) + px² + q. Its views (`tangent_meets_views.gd`) show f(x) and x₀, the same
  with the curve and the line drawn and P marked, or an exam's sketch with no numbers on the axes
  and the points lettered (A, B, Q), and ask 9 unknowns: where the tangent or the normal meets the
  x-axis or the y-axis, the area of the triangle either cuts off (shaded), and where the tangent
  (exactly, or to 3 s.f. on an e^(kx) curve) or the normal (to 3 s.f.) meets the curve again. For
  the exact Q the cubic or px² + A/x + q is built backwards from P and a whole-number Q, so curve
  minus tangent is a(x − x₀)²(x − r), solved by comparing x² terms or by the GDC's intersect. A
  polynomial curve's answers are exact, written as decimals where they end; an e^(kx) curve's are
  to 3 s.f. with the rounding trap, found by a scan whose sign check rules out a missed crossing
  (curve minus line has a third derivative that is never 0). Wrong options come from SL5.4's
  misconceptions: the curve's own y-intercept, x = 0 for the x-axis, a signed area, P given as Q,
  x₀ counted once among the roots, and −m or 1/m for the normal's gradient. The checker
  (`E12NM_check`) reads the curve back from the lines and solves curve = line again with SymPy.
- **The calculus extension types** (FAL-776, batch E13): six `t5-ext-*` types on five situations,
  each with views that extend `extension_views.gd`. They cover syllabus skills no exam type lists, so
  they carry no exam parts. `polynomial_conditions.gd` serves `t5-ext-unknown-coefficients` (SL5.3: k
  from a gradient, a and b from a gradient and a point, from two gradients or from a tangent line) and
  `t5-ext-stationary-conditions` (SL5.8: k from a stationary x, a and b from a stationary point, p from
  a point of inflexion, b and c from two stationary x-values, by equations or by f′ in factor form).
  The letters' whole-number values are picked first and the conditions worked out from them, so the
  equations always solve; one letter is typed as a number and two as `named`. The GDC's solver is
  Paper 2, and the rest is Paper 1. `always_increasing.gd` is `t5-ext-always-increasing` (SL5.2): f′
  is built so it keeps one sign (a quadratic with no real roots, increasing or decreasing; a sum of
  terms that can't be negative; 2ax + b/x on x > 0, with the inverse it gives; an exponential minus a
  line, whose least value only the GDC finds). Each answer is a pick of four written arguments, and the
  right one is the asked method's own. On the quadratics both methods are worked, and the other one
  ends by saying the same fact in the asked method's words. `hence_integral.gd` is
  `t5-ext-hence-integral` (SL5.10): a product rule result read backwards with its extra term moved
  across (x ln x, x e^(kx), x sin(kx), x cos(kx)), a composite one with its constant factor divided out
  (e^(px²), ln(x² + c), (x² + c)ⁿ, sin(x²)), the same as an exact definite value, the derivative itself,
  and which of four true results helps. `integral_gdc.gd` is `t5-ext-integral-gdc` (SL5.5, Paper 2):
  integrands only the GDC evaluates (e^x sin x, sin(x²), e^(x + c), √(x³ + c), ln(x² + c), 1/(x² + c))
  and a polynomial checked by hand, with the entry slips worked out as values: limits swapped, degree
  mode, a bracket closed before the + c. `area_under_curve.gd` is `t5-ext-area-under-curve` (SL5.5,
  both skills): R above the x-axis under a hump −a(x − r)(x − t), between two lines, between the roots
  or against the y-axis, under a straight line (a trapezium) or a Paper 2 curve, and a quadratic with
  surd roots for the GDC. The integral to write is a pick of four integrals; region-for-integral is pick
  the graph, four cards each shading one region (its own limits, from 0, on to the root, the part to
  the left). Every figure shades R with the graph spec's `shade`. Built formats: error-spot on the
  unknowns whose catalogue lists a slip for it, method-pick on always-increasing and hence-integral,
  true-false-reason on always-increasing and area-under-curve, and pick-the-graph for `graph-pick`. The
  catalogue's `match`, `order-steps` and `multipart` formats are not built in the engine, so these
  types don't offer them. The checker's sections are prefixed `E13PC_`, `E13AI_`, `E13HI_`, `E13IG_`
  and `E13AU_`.
- **The data, sampling and exact-triangle extension types** (FAL-778, batch E15): six types on six
  situations of their own, each with views that extend `extension_views.gd`, so the exam types' files
  and checks are untouched. They cover syllabus skills no exam type lists, so they carry no exam parts.
  `variable_kind.gd` is `t4-ext-data-type` (SL4.1): a bank of counted, stepped (half shoe sizes, cents,
  half points) and measured variables, some recorded to the nearest whole unit, in words or as a row of
  recorded values; the answer is the one true claim of kind and reason, or the one variable of the
  asked kind among four. `study.gd` is `t4-ext-population-sample` (SL4.1): a surveyor who asks some of
  a place's people, chosen by a numbered draw, at a spot, by a notice or from one group; it asks the
  population, the sample, whether the sample is random and what would make it random.
  `stratified_sample.gd` is `t4-ext-stratified-numbers` (SL4.1): three groups and a sample, with each
  share G × n ÷ N whole, or rounded (at least 0.1 from a half), the third group set so the sample adds
  up when the rounded shares don't, the sample size from one group's number, and shares from
  percentages. `histogram.gd` is `t4-ext-frequency-histogram` (SL4.2): 4 to 6 equal classes from 0,
  as a table or as a histogram drawn by GraphView, each bar a shaded strip with its outline and the
  class boundaries as `x_ticks`; it asks a missing frequency (a missing bar is marked ?), a bar's
  height, counts over classes, the class a boundary value goes in, the total, and which of four
  histogram cards shows a table (the wrong cards have gaps, two bars swapped or one bar too tall).
  `correlation.gd` is `t4-ext-describe-correlation` (SL4.4): 10 to 14 points made to a band of r
  (strong 0.85 to 0.98, moderate 0.5 to 0.72, weak 0.2 to 0.4, none up to 0.12, and a curve with r
  near 0 whose points fit a parabola), drawn as a GraphView scatter; it asks a description from the
  scatter or from r, whether the correlation shows cause (each story names the third thing both
  follow), what r near 0 says about a curve, which scatter card has a given r, and the strongest of
  four values of r. `exact_triangle.gd` is `t3-ext-exact-triangle` (SL3.5, Paper 1): two sides and an
  angle of 30°, 45°, 60°, 120°, 135° or 150°, or three sides, for an exact area, third side (m√r),
  cosine, side from an exact area, and a height drawn as PlotView's `sketch` with its right angle at
  the foot. Built formats: true-false-reason on the data-type, population-sample and correlation
  types, error-spot on stratified-numbers (an equal split, or the sample size where the population
  belongs) and exact-triangle (an area left as a decimal, a square root taken term by term), and
  pick-the-graph for `graph-pick`. The catalogue's `match` and `order-steps` formats are not built in
  the engine, so these types don't offer them. The six types' steps are not in
  `curriculum/moves-map.json` yet, as no type from E12 on is. The checker's sections are prefixed
  `E15DT_`, `E15PS_`, `E15SN_`, `E15FH_`, `E15DC_` and `E15ET_`.
- **The exponent, show-that and standard-form extension types** (FAL-780, batch E17): six types that
  cover syllabus skills no exam type lists, so they carry no exam parts. Four share an exam type's
  situation, adding unknowns to it, so the exam type's own cells, numbers and checks are unchanged:
  `t1-ext-common-base` (SL1.7) on `solve-exponential` asks b^x = N or 1/N, A^x = R and
  A^(x + c) = B^(kx + e) with both sides powers of one prime, and the x-coordinate where two such
  curves cross on a graph drawn by PlotView, solved exactly by equating the exponents, with logs or
  from a list of powers; `t1-ext-standard-form-add` (SL1.1) and `t1-ext-standard-form-powers` (SL1.1)
  on `standard-form` add and subtract two numbers 1 or 2 powers apart (with a carry past 10, a drop
  below 1, and a difference in a story), and square, cube, square-root or cube-root one, adjusting an
  odd power or one that isn't a multiple of 3, every answer exact; `t1-ext-real-value` (SL1.4) on
  `compound-interest` adds an inflation rate to an annual account and asks the real rate, the real
  value by the real rate and by deflating (the two at least a dollar apart, so each method gives its
  own), and whether the account keeps pace. Two have situations of their own: `integer_powers.gd` is
  `t1-ext-exponent-laws` (SL1.5): b^(−n) and (s/t)^(−n), c^0 + b^(−n), c/x^n and 1/(cx^n) as ax^p,
  (ax^m)^p × bx^n as cx^e, a quotient of a and b with positive exponents, and A^m × B^n as one power of
  a prime; `show_that.gd` is `t1-ext-numerical-show-that` (SL1.6): a log difference, an arithmetic
  sum, a common difference, an investment's value to the cent and a quadratic's root to verify, each
  answered by picking the one working that reaches the given result. Built formats: method-pick on
  common-base and real-value, error-spot on common-base (a power of a power added, the base's power on
  the x term only), exponent laws (the power on the x alone), standard form (the power moved without
  the point, a cube of the power of ten only, an odd power raised the wrong way), real value (the
  rates added, the inflation factor for one year) and show-that (starting from the given value, a
  value rounded to the dollar), and true-false-reason on exponent laws and show-that. The catalogue's
  `match` and `order-steps` formats are not built in the engine, so these types don't offer them.
  Their steps are not in `curriculum/moves-map.json` yet, as no type from E12 on is. The checker's
  sections are prefixed `E17CB_`, `E17EL_`, `E17SF_` (both standard-form types), `E17RV_` and
  `E17ST_`, with the tools they share prefixed `E17_`; on a shared situation the checker sends the
  new unknowns to its section and every other unknown to the exam type's checks as before.
- **The binomial extension types** (FAL-779, batch E16): two types on `binomial-expansion`, the
  situation of `t1-binomial-term`, that cover SL1.9 skills no exam type lists, so they carry no exam
  parts. Each adds unknowns of its own (`BinomialExpansionSituation.CONSTANT` and `PRODUCT`), so the
  exam type's cells, numbers and checks are unchanged. `t1-ext-binomial-constant-term`
  (SL1.9.constant-term, 6 unknowns, 13 cells) has x in both terms of the bracket, (ax^p ± k/x^q)^n:
  the power of x in the general term as pn − (p + q)r, the r of the term independent of x, the
  constant term with p = q (where the middle term is a method), with p ≠ q, with a number beside x,
  and the coefficient of a power other than 0; solved by setting the power, by listing the powers
  for each r, or by symmetry, which the catalogue says fails wherever p ≠ q or the power isn't 0.
  `t1-ext-binomial-product` (SL1.9.product-expansion, 6 unknowns, 12 cells) multiplies
  (a + bx)^n by a short bracket: a coefficient of (p + qx)(a + bx)^n, the power the first bracket's
  x term carries (where multiplying the two coefficients is the slip), the same "hence" from the two
  coefficients given, the constant term of (x² + c)(x + k/x)^n, k from a given coefficient of
  (1 + kx)(a + bx)^n, and n of 3 or 4, where expanding everything is a method too; every answer comes
  from two pairs of terms, neither 0. Every answer is exact. Built formats: method-pick on every
  cell, error-spot on the r of the constant term (the fraction's power of x written as positive), the
  constant term (the top of the fraction left unraised) and the product's coefficient (the x term
  paired with the term of the asked power). Wrong options are slips or declared fillers, never
  `generic`. The catalogue's `order-steps` and `multipart` formats are not built in the engine, so
  these types don't offer them. Their steps are not in `curriculum/moves-map.json` yet. The skill
  map's misconceptions for both skills no longer quote an example's numbers, and "Sign slips" now
  names the slip. The checker's sections are prefixed `E16BC_` and `E16BP_`, with the tools they
  share prefixed `E16A_`; `binomial-expansion`'s checks send the new unknowns there and every other
  unknown to the exam type's checks as before.
- **The sequence extension types** (FAL-779, batch E16, lane B): two types that cover syllabus skills
  no exam type lists, so they carry no exam parts. Both share an exam type's situation, adding unknowns
  to it, so the exam types' own cells, numbers and checks are unchanged. `t1-ext-partial-vs-infinite`
  (SL1.8.sn-vs-sinf) on `geometric-sequence` (with `t1-geometric-sequence` and `t1-sum-to-infinity`)
  is Paper 2 throughout: u₁ a multiple of 20 and 0 < r < 1, shown as u₁ and r or as four terms, and it
  asks the least n with S∞ − Sₙ below a gap, the least n with Sₙ past a percentage of S∞ (each crossing
  at least 0.1 from a whole number, so a GDC's table settles it), the share of S∞ the first k terms
  give (at most 99%) and the gap S∞ − Sₖ, both to 3 s.f. The least n is worked as the tail series
  S∞ × rⁿ with powers tried either side, with logs (the sign turned at ln r < 0), from a GDC table of
  S∞ − Sₙ or Sₙ, or where the graphs of the gap and the tolerance cross; a working value is written to
  six figures, keeping its zeros when it is rounded, and the next step works from what is shown.
  `t1-ext-sigma-arithmetic` (SL1.2.sigma) on `arithmetic-sequence` (with `t1-arithmetic-sequence`)
  reads Σ (r = a to b) (pr + q) as the sequence with u₁ = pa + q and d = p: the number of terms, its
  value from r = 1 and from a higher lower limit (by the first and last terms, by splitting into pΣr
  and Σq, as a difference of two sums from r = 1, or with the GDC's Σ, which is Paper 2), a series
  written out to put in Σ form (p, q and n, by u₁ + (r − 1)d or as a linear function), and the upper
  limit k from the total, whose quadratic has a negative whole second root. The skill map's example
  sums are left out, and SL1.2.sigma's map strings, which quoted them, now name the slip. Built
  formats: method-pick and error-spot on partial-vs-infinite (the inequality kept after dividing by
  ln r), and error-spot on sigma (the constant added once, the terms counted as b − a). The
  catalogue's `match` and `multipart` formats are not built in the engine, so these types don't offer
  them. Their steps are not in `curriculum/moves-map.json` yet, as no type from E12 on is. The
  checker's sections are prefixed `E16PI_` and `E16SA_`, with the tools they share prefixed `E16B_`
  (a line's =, < and > read with SymPy, a Σ summed first); on each shared situation the checker sends
  the new unknowns to its section and every other unknown to the exam type's checks as before.
- **The hidden-quadratic and two-observation extension types** (FAL-779, batch E16, lane C): two types
  that cover syllabus skills no exam type lists, so they carry no exam parts. Both add unknowns to an
  existing situation, so its other types' cells, numbers and checks are unchanged.
  `t1-ext-hidden-quadratic` (SL1.7) on `solve-exponential` draws the roots of a quadratic in u = b^x
  first, so a b^(2x) + B b^x + C = 0 (b^(2x) sometimes written (b²)^x, as 9^x) has whole coefficients:
  two roots that are powers of b (or one is 1/b), a power and a negative root, a b^(2x) = c b^x with
  the root u = 0, e^(2x) + Be^x + C = 0 with x = ln p or ln q (a `form` answer, either order), a root
  that is no power of b (x = ln r/ln b), and the number of real solutions (roots of both signs, a
  repeated root, a root between 0 and 1). It is solved by naming u, by factorising in b^x, or on
  Paper 2 by the GDC's zeros (the map's method is named "Graph the expression on the GDC and find its
  zeros", so the engine treats it as a calculator method); a root u that is 0 or negative is rejected.
  The skill map's examples are left out, with a root's sign flipped too. `t3-ext-two-observations`
  (SL3.3) on `bearings-elevation` has two observers a known distance apart on one side of the foot
  (angle ATB, BT, the height, BF) or on either side (the height), every question with the side view
  drawn to scale by PlotView's `sketch`; it is solved by the sine rule in ABT and then the right
  triangle BFT, by two tan equations, or by the GDC's intersection of the two height lines, and with
  30° and 60° the height is exact on Paper 1 (BT = AB, the triangle being isosceles). Each answer to
  3 s.f. is worked from the 5 s.f. figure before it and rounds the same. Built formats: error-spot on
  the hidden quadratic (b^(2x) read as 2u, a negative root's sign dropped, u = 0 taken as x = 0) and
  method-pick on both. The catalogue's `order-steps` and `multipart` formats are not built in the
  engine, so these types don't offer them. Their steps are not in `curriculum/moves-map.json` yet. The
  checker's sections are prefixed `E16HQ_` and `E16TO_`; each wraps its situation's existing check
  and sends only its own unknowns to its section.
- `engine/situations/monotonic.gd` (FAL-723) is `t5-increasing-decreasing` (SL5.2, on all four
  syllabuses): a cubic built from whole-number turning points, a quadratic from whole-number
  roots, f′(x) = a + bx − c e^x on Paper 2, and a letter that keeps f′ on one side of the axis.
  An interval is a `form` answer with a between/outside pick and two typed ends in either order,
  so the shape isn't given away; the ends being open or closed isn't asked, except for a
  parameter, where the boundary is the point of the question.
- `engine/situations/concavity.gd` (FAL-723) is `t5-concavity` (SL5.7, AA only): second derivatives,
  f″ at a point, where a graph is concave up or down, and three matching questions played as
  pick the graph (f to f′, f′ to f″, and the signs of f′ and f″ to f). The Paper 2 value of f″ is
  at an x to 1 d.p.; f′(x) = a + bx − c e^x has b ≠ c, so ln(b/c) needs a calculator.
- `engine/situations/integration.gd` (FAL-724) is `t5-indefinite-integral` (SL5.5 and SL5.10):
  one integrand with whole-number coefficients. Its 18 unknowns ask sums of powers, the standard
  results, composites with ax + b (a is never ±1), the reverse chain rule, and integrands to
  rewrite first. An integral is a `form` answer and + C is part of it, so an option without it is
  wrong. Where two shapes are both right, (ax + b)³/(3a) or the expanded polynomial, and
  (k/2) sin² x or −(k/4) cos 2x, the method sets the shape and the other is never offered.
- `engine/situations/definite_integral.gd` (FAL-724) is `t5-definite-integral-area` (SL5.11 and
  SL5.5): 23 unknowns on exact values, areas with parts below the axis, an unknown limit or
  stretch, a region cut by a tangent or a line, and a rate in a story. A value is a `form` answer
  (`DefiniteIntegralViews.val`), so a wrong one can read differently, with + C or in rate units:
  exact on Paper 1, and 3 s.f. on Paper 2, which only the GDC methods ask. A region is shaded on
  its figure with the graph spec's `shade` (see `ui/graph_view.gd`).
- `engine/situations/antiderivative_condition.gd` (FAL-740) is `t5-antiderivative-condition` (SL5.5
  and SL5.10), the `antiderivative-condition` situation: a derivative and a condition that fixes
  the constant. Its 21 unknowns ask f(x), a curve's equation, C or a further value, from powers,
  negative powers, cos and sin with a chain or a shift, 1/(ax + b), e^(ax), quotients that reverse
  to a log, a constant in the gradient fixed by a gradient at a point, two conditions from f″, a
  family y = F(x) + C drawn on one figure (its curves are the right C and three slips, labelled
  at their right-hand ends), the graph of f′ in straight pieces, and a decaying rate in a story.
  A function is a `form` answer with a slot for each coefficient and for the constant, which is
  never 0, so dropping it is always wrong; an option with + C left in can be picked but not
  typed. A log in C is typed around a fixed "ln n". Numbers are exact except the decimal e^(ax)
  and the rate model, to 3 s.f. Landmark angles, logs in C and sin or cos beside e^(ax) are Paper 1,
  decimals and the rate model Paper 2, and the GDC method Paper 2 only.
- `engine/situations/grouped_data.gd` (FAL-740) is `t4-grouped-data` (SL4.3), the `grouped-data`
  situation: a frequency table in classes or single values, a short list, or the sizes and means
  of a few groups. The table is drawn first and everything is worked out of it, exact with `Q`,
  except a standard deviation that isn't a perfect square, to 3 s.f. Its 24 unknowns ask the modal
  class, mid-interval values, an estimated mean, σ or variance and why it is an estimate, a missing
  frequency or value from a total, a mean or a median, and the totals of combined groups.
- `engine/situations/binomial_unknown.gd` (FAL-740) is `t1-binomial-find-unknown` (SL1.9), the
  `binomial-unknown` situation: `t1-binomial-term` run backwards. The letter is drawn first and the
  coefficient worked out from it, so its 16 unknowns (a letter in the bracket, n, both, equal or
  ratio coefficients, two brackets, a quotient, x from three terms in arithmetic mean) always come
  out. `gdc-search` is Paper 2 only.
- `engine/situations/normal_properties.gd` (FAL-740) is `t4-normal-properties` (SL4.9), the
  `normal-properties` situation: what the shape of the curve gives without finding an area from
  nothing: the 68-95-99.7 rule, mirrored tails, a shift between two curves with the same σ, and
  the central interval. Its 27 unknowns are exact, except a value a GDC gives, to 3 s.f. Two of
  them are `pick-the-graph`: four cards that share one window and one set of axis marks, so only
  the curves and the shading differ.
- `engine/situations/inverse_normal.gd` (FAL-752) is `t4-inverse-normal` (SL4.9.inverse-normal), the
  `inverse-normal` situation: normal-probability the other way round, with an area given and the value
  that cuts it off asked for. Its views (`inverse_normal_views.gd`) extend `NormalProbabilityViews` for
  the stories and the curve, and show X ~ N(μ, σ²), a story, or the curve with the area shaded and the
  value marked by a letter, so the figure says which side the area is on. It asks 14 unknowns. Ten are
  Paper 2, to 3 s.f. with the rounding trap, with every method of the map (invNorm with the left area,
  via z, a sketch first): a with P(X < a) = p or P(X > a) = p, the top or bottom k%, a quartile, a
  percentile, an area above a of more than a half, both ends of a central interval (typed), the other
  end of a band, and an end of a band whose tails are in a ratio r : 1. Four are Paper 1, exact, by
  via z or a sketch only, as the exam's one Paper 1 part reaches a value by comparing distances from
  the mean: a second curve with the same σ, a mirror tail, a tail of the 68-95-99.7 rule, or a line of
  N(0, 1) given. The mirror image of the answer is always offered, with one slip far from the mean, so
  the far slips don't give the answer away together. Working from a z shown works on from that z, so
  each number follows from the line before.
- `engine/situations/area_between.gd` (FAL-751) is `t5-area-between-curves` (SL5.11), the `area-between`
  situation: two curves and the region between them. Its views (`area_between_views.gd`) show the two
  equations, the curves named f and g with the region shaded (GraphView's `shade`, each strip between
  the curves), or a `diagram`: a parabola and a line with only points marked, so the equations come
  first. It asks 18 unknowns: the limits, an integral expression, an expression for curves that swap
  (two integrals on Paper 1, one with a modulus on the GDC), a parabola and a line, two parabolas, a
  cubic and a line, a swap inside two vertical lines, trig pairs at landmark angles, A e^(kx) and
  −B e^(kx), the two possible g = f + c from an area, a letter k from an area, the graph of f′ with
  its areas, and on Paper 2 the limits, two curves, three crossings, f and its inverse, and a region
  with three edges. Every method of the map is in a cell: top minus bottom, split at the crossings,
  ∫ |f − g| on the GDC (Paper 2 only), and the area under the top minus the area under the bottom. So
  that last one is honest, a parabola and its chord stay on or above the x-axis between the meeting
  points. Paper 1 is exact, and a value with a surd is typed by its numbers. Paper 2 is a `number`
  to 3 s.f. with the rounding trap. The curves that need a GDC are Paper 2 only, and the rest are
  Paper 1, so the type lands near the bank's 5 parts in 13.
- `engine/situations/box_plot.gd` (FAL-740) is `t4-box-plot` (SL4.2) and `t4-outlier-rule` (SL4.1,
  SL4.2), the `box-plot` situation: one or two data sets, the five numbers of a box plot and the
  1.5 × IQR rule. A figure uses `PlotView`'s `box` on an axis of 25 ticks, labelled every fifth, and
  every number read from it is on a tick. A list or a table follows `data_summary`'s quartiles.
  A test of a value puts it just beyond or just inside a fence on the same quartiles.
- `engine/situations/log_laws.gd` (FAL-751) is `t1-log-laws` (SL1.7.log-laws and SL1.7.change-of-base),
  the `log-laws` situation: one log expression, in ln, log, log₁₀ or a small base, with primes and
  powers drawn so the laws land on an exact value. Its views (`log_laws_views.gd`) ask 18 unknowns: an
  exact value (each log a power, a value only the combined log shows, the log of a sum, one log over
  another), ln k, one log from letters, an expansion in p and q (letters or primes), a shown form
  k ln c, a value from a given log, a base ab (the given log, then "hence"), one log in a power of a
  prime base, the log of a root (or f⁻¹ at a root), a log in terms of two others or of p and q, a
  given log in a base B^k, log in base B^k of x in terms of log base B of x, and a 3 s.f. value.
  The one representation is `equation`. Every answer is the `form` kind, so its numbers are typed
  and a wrong option in another shape, such as log(25/11), can be picked but not typed. A base the
  font can't lower reads "log base √3 of 81". The exam is all Paper 1, so a cell is Paper 2 only
  where it needs a calculator: `gdc-check` on the two letter unknowns, and both methods of the 3 s.f.
  value, which is why the type is in `OVER_SHARE` in `test_paper.gd`, at 4 cells of 32. A GDC check
  tries one value, shows what both forms give, and says it's a check and that the laws are the proof.
  `check_answers.py` (`e9log_*`) reads every expression back with a small parser of the game's
  notation and works it out at 40 digits. Letters take values that fit what's given, and an option
  must equal the target at three sets of them. Each tagged option is worked out from its slip, a
  typed answer's slots must make the expression it shows, and each equation in the working is
  evaluated. `test_log_laws.gd` covers the cells, the papers, the no-proof line and typed marking.
- `engine/situations/log_equation.gd` (FAL-956) is `t1-log-equation` (SL1.7.log-equations, with
  SL1.7.log-laws, SL1.7.change-of-base and SL1.5.exp-log-form), the `log-equation` situation: one
  equation in logs of linear arguments, with the root drawn first. Its views (`log_equation_views.gd`)
  ask 5 unknowns over 11 cells: a difference of logs equal to a number or a log (linear), a log equal to
  a number plus a log (write the number as a log), a sum of logs or 2 log − log that comes to a
  quadratic with one root rejected, two bases b and b^k (one argument in both, or one in each and a
  root rejected), and the root a student must reject. Every argument is linear, a quadratic has whole
  or half roots and exactly one of them stands, and every working checks the root in each argument or
  starts from the domain. "Both roots" and "no solution" are options in another shape. Paper 1
  throughout, as both bank parts are. `E18LE_check` in the SymPy checker reads the equation back, turns
  every log into one base, drops the logs, solves the polynomial, keeps the roots that make every
  argument positive, and rebuilds each tagged option from its slip. `test_log_equation.gd` covers the
  cells, the paper, the rejected root, typed marking and every tag.
- `engine/situations/approximation.gd` (FAL-999) is the first AI SL situation, `approximation`, for
  `t1-ai-percentage-error` (AI-SL1.6.round-accuracy, percentage-error and estimate-reasonableness) and
  `t1-ai-approx-bounds` (AI-SL1.6.bounds and max-percentage-error). Both are exam types (`home` ai-sl),
  so only the AI courses get them, and every question is Paper 2, as every AI paper allows a GDC. Its
  views (`approximation_views.gd`) ask 12 unknowns over 20 cells, all in words: a GDC value to n d.p.
  or n s.f. (the key keeps its zeros, as on FAL-1051), a cost with an allowance for waste to the cent,
  tins to buy (rounded up) or whole items that fit (rounded down), the percentage error of an estimate
  or of a rounding, the largest or smallest exact value a largest error allows, an estimate to 1 s.f.,
  the root of x(x + d) = A that is a width; then a bound of a rounded measurement or count, the least
  or greatest area, volume or route length, the greatest or least speed or density, and the maximum
  percentage error in an area or volume (each bound's value taken as exact, so the lower bound gives
  it). Wrong options are the five skills' slips (leading zeros, rounding in stages, money to 3 s.f.,
  over the approximate value, no × 100, the sign kept, the exact value rounded first, × for ÷, the
  negative root, a whole unit, the bound just below, the wrong unit for s.f., the length's own error,
  one bound, the same bound top and bottom) and the types' own (cut off, the allowance left out, the
  nearest whole item, the error applied to the measurement, the other end, the measured values, mixed
  bounds). `r1ap_check` in the SymPy checker reads every value back from the sentence, rounds with
  Decimal half up and works every value and slip out again exactly. `test_approximation.gd`.
- `engine/situations/tvm.gd` (FAL-999) is `tvm`, for `t1-ai-amortization` (AI-SL1.7.loan-repayment,
  loan-term-or-rate, outstanding-balance, total-interest-compare) and `t1-ai-annuity`
  (AI-SL1.7.savings-annuity, payout-annuity), beside `compound_interest.gd`, which has no payments:
  monthly payments at the end of each month (P/Y = 12), with interest compounded monthly, quarterly or
  half-yearly. Its views (`tvm_views.gd`) ask 16 unknowns over 25 cells: a loan's payment (after a
  deposit or not), the number of payments, the smaller last one, the rate, the balance after k
  payments, the interest in the first payment or the debt it pays off, the total interest, and two
  loans compared (in words or a table, as a statement with the dollar amount); the value of monthly
  deposits with or without an opening sum, the deposit for a target, the months to pass it, the
  interest earned; the fund for a monthly income, the number of full withdrawals, the balance after
  some years and the largest withdrawal. Methods: the TVM solver, the annuity and present-value
  formulas, the geometric series, the spreadsheet's rows, bal(), the amortization table and N × PMT.
  Money is exact to the cent and kept clear of the half-cent edge, and so is every slip; a payment
  shown in a question is the solver's payment to the cent, and the working uses it. `r1tv_check`
  works every value out again at 50 digits, counts the rows of a loan or a fund with exact fractions
  and solves for a rate. `test_tvm.gd`.
- `engine/situations/log_technology.gd` (FAL-999) is `log-technology`, for the extension type
  `t1-ext-logs-with-technology` (SL1.5.evaluate-tech), catalogued since FAL-311 and built here. It is
  on all four courses, Paper 2: log b or ln b, 10ˣ = b or eˣ = b, aˣ = b and p ln q − log r or
  p log q + ln r, each to 3 s.f., by the log keys, a graph's intersection or the equation solver. Wrong
  options: the other log key, log(b ÷ a), the logs the wrong way round, each log rounded first. It
  builds method-pick on every cell and error-spot on the two equations (the other key, or a bracket
  slip, on line 1 or line 2). `r1lt_check` and `r1lt_spot` work every value and every working line out
  again with SymPy. `test_log_technology.gd`. The map's skills list `match`, `multipart` and
  `order-steps` formats for AI-SL1.6 and AI-SL1.7; the engine doesn't build them, so none of these
  types offers them.
- `engine/situations/log_exp_form.gd` (FAL-753) is `t1-log-exp-form` (SL1.5.exp-log-form and
  SL1.5.log-context), the `log-exp-form` situation: 25 unknowns over 73 cells. Paper 1 changes a fact
  between log and exponential form, evaluates a log exactly, solves for the number, the bracket, the
  power or the base, and picks the log with or without a real value. Paper 2 is five invented scales
  (Howl rating, Rumble number, Glare class, Rad index, Bite) and a log model in time: a reading, an
  amount, the factor or rise between readings, a scale's constant, a level or a time, to 3 s.f. with
  the rounding trap, in standard form outside 0.01 to 100000. The views (`log_exp_form_views.gd`) show
  it as an equation or formula, as a rule in a sentence, as a table of readings and as a curve with
  a crossing or a line. exp-log-form is Paper 1 and log-context Paper 2, which makes the bank's 2/3
  Paper 2 share (48 of 73 cells). `E11LF_check` in the SymPy checker reads the scale back from the
  formula or the sentence.
- `engine/situations/constant_change.gd` (FAL-754) is `t4-constant-changes` (SL4.3.constant-changes),
  the `constant-change` situation: 15 unknowns over 99 cells. A data set's summary statistics, and every
  value put through y = x + b, y = ax or y = ax + b: the new mean, median, mode, quartiles, standard
  deviation, variance, IQR or range, or the change run backwards to the original ones; a and b found from
  two means and two spreads, the factor from two variances, and which statement of the effect is true.
  The original statistics are drawn first and the new ones worked out of them exactly, so every cell is
  Paper 1 and every number ends within two decimal places. The views (`constant_change_views.gd`) show
  an equation, a story (a pallet's mass, cm to mm, a pay rate, °C to °F), a list of the data or a box
  plot to scale on whole ticks, and work the shift-and-stretch rules, the picture of the histogram or box
  plot sliding and stretching, or the change tried on 1, 2, 3. Run backwards, a variance whose "apply
  the change again" option would pass 100000 (a² twice over, 10⁸ for metres to centimetres) is drawn
  again.
- `engine/situations/rational_exponents.gd` (FAL-754) is `t1-rational-exponents`
  (SL1.7.rational-exponents), the `rational-exponents` situation: 12 unknowns over 23 cells, all
  Paper 1, as the bank is. The value of a whole number or a fraction to a positive or negative
  fractional power, x from x^(m/n) = k, a root of x (inside, outside or under 1) or a power times,
  over or under a root as one power of x, a bracket (c x^q)^(m/n), products and quotients of powers
  of x, a product or quotient of powers of one prime, and a sum of two or three terms over a root of
  x split into powers. Every number is drawn as a perfect power first, so it all comes out by hand.
  The views (`rational_exponents_views.gd`) work it root first, power first, through a prime base,
  by the laws of indices or term by term, and the wrong options come from the 21 SL1.7 slips
  (the base times the power, a negative value, multiplied or divided powers, the root alone, no
  reciprocal, a flipped power, a lost minus sign, the number in a bracket left alone, the first
  term alone divided). `E12RE_check` in the SymPy checker parses the expression shown and works it
  again.
- `engine/situations/solve_exponential.gd` (FAL-754) is `t1-solve-exponential` (SL1.7.solve-with-logs),
  the `solve-exponential` situation: 7 unknowns over 26 cells, every method of the skill. Two powers with
  different bases, a^(x + p) = b^x or a^x = b^(c − x), to 3 s.f. or exactly as ln p/ln q (a `form` answer
  with both numbers typed); k e^(mx) + d = c isolated first, exactly as ln a or (ln r)/m (the `lnq` kind,
  marked by value), or with a decimal rate or a whole base to 3 s.f.; and growth stories: the exact time
  A₀e^(kt) takes to reach a level, and when A₀e^(kt) and B₀ × g^t meet, to 3 s.f. The views
  (`solve_exponential_views.gd`) show the equation, the story, or the two curves (a curve and a line)
  crossing at P with each curve named. The bank's one part is Paper 2, so every cell is Paper 2; an exact
  cell can also make Paper 1 when one is asked for, with no calculator method. The 3 s.f. options include
  the logs rounded to 2 d.p. too early, which moves the answer in its third figure only. Every two-bases
  answer, exact or 3 s.f., has |x| at most 12 (`MAX_X`), so close bases with a big shift are refused.
- `engine/situations/trig_wave.gd` (FAL-751) is `t3-trig-read-features` (SL3.7.read-features) and
  `t3-trig-model-use` (SL3.7.model-context), the `trig-wave` situation, which extends `trig-model`: it
  keeps that situation's Paper 2 wave, contexts and graph, and `TrigWaveViews` extends its views.
  A reading (16 unknowns) is a fn(bx) + d for sin, cos and tan, with b whole, a fraction, a multiple of
  π or a decimal: amplitude, period, both, principal axis, maximum, minimum, range, the first x at a
  maximum, tan's period and a claim that it has no amplitude, b or a and d off a figure, r in terms of
  q from a sin(qx)'s marked intercepts, and b, the amplitude and axis or a wheel's a and b from a story.
  A figure hides its equation and marks its turning points, except a `gdc-graph` cell, which prints
  the equation and drops the marks, so that the GDC has something to graph and something to find. A
  use (13 unknowns) is a model in a story, in the forms the bank writes it (a cos at a peak, a sin a
  quarter of a period earlier, −a cos at a trough, a decimal b): a value, the first or every time at a
  level, how long past a level in a cycle or a span of whole cycles, the first maximum, the gap from a
  low to a high, counts of maxima and minima, what an extreme means and whether a level is reached.
  Degree mode is a worked distractor on every value and time: the model is solved again with its
  angle in degrees. Its one Paper 1 exact value is at a whole t past the first quadrant, in TrigKit's
  exact numbers, and whether a level is reached makes Paper 1 too.
- `engine/situations/trig_sketch.gd` (FAL-754) is `t3-trig-sketch` (SL3.7.sketch), the `trig-sketch`
  situation: 9 unknowns over 22 cells, all three methods of the skill (five key points per period,
  transform sin x or cos x, graph on the GDC and transfer). A phone can't take a drawing, so the four
  sketches (a sin or cos wave, the wave from a table of its five key points, a reflected wave and
  a tan(bx) + d with its asymptotes) are pick-the-graph: four cards on one window with one set of axis
  marks, each wrong card one slip (tan with turning points, a cosine started on its axis, straight
  lines for a curve, the base period, a missed reflection, d the wrong way, tan's asymptotes at its
  crossings). What a sketch must mark is typed: the maximum and minimum points, the y-intercept, the
  x-intercepts (where fn(bx) = ±1/2, from the equation or a figure with nothing marked), tan's
  asymptotes and two blanks in a table of key points. Paper 1 is exact, in multiples of π or in
  degrees; the GDC's cells are Paper 2, where a sketch keeps Paper 1's numbers and a maximum point
  or an x-intercept is on a wave with tenths, to 3 s.f. Both bank parts are Paper 1, so those 5 cells
  of 22 put the type in `OVER_SHARE` in `test_paper.gd`. The views are `trig_sketch_views.gd`.
- `engine/situations/trig_model_equation.gd` (FAL-752) is `t3-trig-model-equation` (SL3.8.graphical,
  SL2.10), the `trig-model-equation` situation, which extends `trig-wave`, and `TrigModelEquationViews`
  extends `TrigWaveViews`. Its 18 unknowns don't repeat `t3-trig-model-use`'s and fall in four families:
  exact times in a story on Paper 1, where the level is half of the amplitude from the axis, so
  fn(bracket) = ±1/2 (every time in a span, the time at least or at most a level in one cycle); a
  story and a level on Paper 2 (every time in a window that starts after 0, the set of times above or
  below a level, in one stretch or two, and the total time or the chance past a level in a span that
  isn't whole cycles); a wave on an interval on either paper (the number of solutions of f(x) = k,
  with k inside the range or at a turning point, the band of k with exactly n solutions, the k with at
  least one or no solutions, a letter of the wave from a touching line, and the two k with exactly
  one solution); and a trig curve against a line or a falling exponential on Paper 2 (every solution,
  or how many). Counts walk the wave's monotonic pieces, so a line at a turning point or an end is
  counted once. A set of times is a `form`, typed end by end to 3 s.f. The figures are the model's or
  wave's graph with the level dashed, or both curves. A question's tagged wrong options are rotated by
  its `spin`, so every slip shows up across the seeds even where only two fit beside the rounding trap.
- `engine/situations/distance_midpoint.gd` (FAL-751) is `t3-distance-midpoint` (SL3.1), the
  `distance-midpoint` situation: points in 2D or 3D, drawn first, so a distance is the root of a
  whole number and a midpoint is exact. Its 15 unknowns ask a distance, k from a distance (two whole
  values, or a ± b√c), which sides of an isosceles triangle are equal, a cuboid's space diagonal, a
  pyramid's edge or height, a radius from a centre or a diameter, the distance from the origin to a
  point on a curve, a midpoint, a centre and a missing endpoint. Lengths are exact on Paper 1 and to
  3 s.f. on Paper 2, where midpoints and endpoints use coordinates to 1 d.p. A figure is `PlotView`'s
  `space`: the points on axes with the coordinates on them, a cuboid or pyramid on the axes, or a
  round solid with no axes. Position vectors are the map's vector representation, listed as
  `notation`. The 2D unknowns use the type's own `distance-formula-2d` method.
- `engine/situations/solid_angle.gd` (FAL-754) is `t3-3d-angle` (SL3.1.angle-line-plane and
  SL3.1.angle-two-lines), the `solid-angle` situation: 11 unknowns over 49 cells and all six methods. A
  line and a plane: a cuboid's space diagonal and its base, a pyramid's slant edge or the line VM to the
  middle of a base edge and the base, a cone's slant height and its base, a line through two points and
  the xy-plane; two lines: a cuboid's two space diagonals at M, two slant edges at the apex, a diagonal
  and an edge, and angle ABC from three points (with or without a right angle at A or C). The lengths and
  coordinates are drawn first as whole numbers and the angle is worked out of them; every cell is Paper 2
  to 3 s.f. but `landmark-angle`, which is Paper 1 with lengths chosen to make 30°, 45° or 60° exactly.
  The views (`solid_angle_views.gd`) give the solid in a story or as `PlotView`'s `space` figure, which
  gained optional shaded `faces`, cone `rims`, measures on `lines`, `angles` arcs and `rights` marks for it;
  points come as coordinates, position vectors or on axes. The bank's pyramid and the skill's worked
  examples are left out.
- `engine/situations/motion.gd` (FAL-724) is `t5-kinematics-motion` (SL5.9): Paper 1 is
  v(t) = 3A(t − p)(t − q), with s(t) whole, and a cubic that touches 0 for a change of direction;
  Paper 2 is A t e^(−kt) − B, A sin(wt) + B or A e^(−kt) cos(wt), with rests and extremes found
  numerically. Graphs are in straight pieces with whole-number corners, on axes named t and v
  or s (`y_name`). The acceleration at maximum speed is only asked where that speed is at an end
  of the interval, as it is 0 at a turning point of v.
- `engine/situations/motion_distance.gd` (FAL-739) is `t5-kinematics-distance` (SL5.9), the
  `motion-distance` situation, which extends `motion`: it keeps that situation's Paper 2 models,
  rest finder and graphs, and adds an antiderivative, the legs of a trip between rests, and its
  own families. Paper 1 is v(t) = 3A(t + u)(r − t) with one rest, the two-rest quadratic, s(t) =
  ct(2q − t) and a straight v(t); s(t) stays whole, at most 300, up to T = 8. Paper 2 is the base
  models, s(t) = A cos(wt) + Bt + C, a repeating v that is always positive and a race between
  two A(1 − e^(−kt)). Its views (`motion_distance_views.gd`) ask 23 unknowns: s(t) and v(t) with
  + C, a position, a displacement over a stretch, the position at the top of v, whether a
  particle gets back to its start, s(0), where the displacement rises, a distance split at rests
  or by ∫|v| dt on the GDC, from s(t), up to the first turn or between two times, a distance's
  expression left unevaluated (a `form` answer with four limits to type), a time from a distance,
  the gap between ridges, a race, and areas on a v–t graph with a corner at every zero. A curve
  in the `graph` representation sits under its equation, as in the exam. Integrating with + C is
  Paper 1 only, since a Paper 2 model can't be integrated by hand at SL.
- `engine/situations/geometric_sequence.gd` (FAL-728) is `t1-geometric-sequence` (SL1.3, on all four
  syllabuses) and `t1-sum-to-infinity` (SL1.8), one situation for both. Paper 1 is whole numbers and
  simple fractions, marked exactly; Paper 2 is decimals that end, marked exactly when whole or within
  3 figures and otherwise to 3 s.f. Its views (`geometric_sequence_views.gd`) ask 21 and 19 unknowns:
  r, a term and uₙ (a `form` answer, where the method sets u₁r^(n − 1) or (u₁/r)r^n), r and u₁ from two
  terms, both signs for an even gap, a far term's sign, the terms between two terms, three terms in k,
  coefficients of (1 + hx)ⁿ, Sₙ by each map method, closed forms, a Σ read, evaluated and written, and
  a ball's distance to a landing; then whether S∞ exists (a `claim`), x from −1 < r < 1 (a `form`
  answer; a wrong option in another shape can be picked but not typed), S∞, u₁ or r from it, a log
  series, a quadratic in r with a root to reject, and a ball, a recurring block, nested squares, a
  shaded square, a running total against a target and the first amount for a target. GDC and
  partial-sums methods are Paper 2 only, and their working isn't shown on Paper 1. PlotView's
  `bounce` and `squares` draw the figures; a sequence's dots and the band −1 < y < 1 use GraphView.
- `engine/situations/geometric_context.gd` (FAL-752) is `t1-geometric-in-context` (SL1.3.model and
  SL1.3.find-n), the `geometric-context` situation: a story that a geometric sequence models. Paper 2
  powers run far enough to overflow a `Q`, so a value there is a float, as a GDC gives it. Its views
  (`geometric_context_views.gd`) ask 18 unknowns: r from a percentage, a value after t rounds (t
  multiplications) and in round n (n − 1), which term is "after t", a rebound height, uₙ in terms of n
  (a `form` answer), a total, the gap between a flat deal and a rising one, the first round a geometric
  model passes an arithmetic one, the area of the nth rectangle with its sides scaled and their mean as
  p × (b^a − 1), and the least n for uₙ or Sₙ past a target, for S∞ − Sₙ below a small value, for a
  first term below one, after finding r from u₁ and a later term, the least whole t after a start, and
  a count of terms from an exact power. Every method of the two skills is in a cell. The one Paper 1
  part in the bank is the rectangles, so they, r, the indexing, tabulating a rebound or uₙ and an
  exact power are Paper 1; a value, a rebound or uₙ by the multiplier makes both papers, with small
  powers on Paper 1; the rest is Paper 2. A method's title follows the story ("Build a
  bounce-by-bounce table"). A figure is PlotView's `bounce`, dots with the target as a line (the first
  three labelled, so u₁ and r can be read), or two rivals as curves named at their right-hand ends.
- `engine/situations/regression.gd` (FAL-695) is `t4-regression-gdc` (SL4.4, on all four
  syllabuses): paired data, 6 to 9 whole-number points near a line (x from 1 to 20, y from 8
  to 99, 0.8 ≤ |r| ≤ 0.99, up or down as the story says), so the means, the regression line
  and every sum are exact `Q` and r is the one float. Its views (`regression_views.gd`)
  ask 6 unknowns, all Paper 2 with the GDC's LinReg: the line y = ax + b, r, the mean point,
  c in y = ax + c from a given mean point, an estimate at an x inside the data, and an
  estimate from a line given to 3 s.f. Answers are to 3 s.f. with the rounding trap (the
  line and the mean point have none), and the mean point is exact. Wrong options come from
  the SL4.4 misconceptions: the line of x on y for swapped lists, a and b rounded to 3 s.f.
  before the estimate, r² for r, c = 0 for a line forced through the origin, and the line
  rearranged for x. A table's heads are x and y with a story line above. The game's font
  has no precomposed ȳ, so the mean point is written y plus a combining macron, as x̄ is.
  As every exam type, it offers no extra format: `test_extension.gd` holds that rule.
- `engine/situations/regression_pair.gd` (FAL-725) is `t4-regression-x-on-y` (SL4.10, AA only):
  the same paired data, with both lines. Its views (`regression_pair_views.gd`) ask the line
  x = cy + d (a `named` answer: c and d), d from a mean point, which line to use (a `claim`), an
  estimate of x from data or from both lines, whether an estimate is reliable (a `claim`), the
  mean point from both lines (on the equations, or with both lines drawn) and one mean from the
  other. The table, the estimates and the judgement are Paper 2; choosing a line and the mean
  point are on both papers, with lines through a whole-number mean point and 0 < ac < 1.
- `engine/situations/regression_interpret.gd` (FAL-751) is `t4-regression-interpret` (SL4.4, Paper 2,
  on `SL4.4.interpret-ab` and `SL4.4.predict`). It draws its own tables with `RegressionSituation.stats`,
  because its eight stories carry units, some have x = 0 in the table and others far below it, and r
  can be weak: |r| is at least 0.9 or at most 0.5, never between. A line given to 3 s.f., with its r
  and range, is always a real table's. Its views (`regression_interpret_views.gd`) ask what a and b
  mean, whether b is sensible, the change for k more of x, whether an estimate is reliable, why a
  worked estimate is not appropriate (outside the data, or y on x solved for x) and a reading from
  a drawn line, to the nearest 5. Most answers are a `claim`, so multiple choice only, and three of
  the wrong statements are taken from a shuffled list. The scatter is a `Plot.spec` with unlabelled dots.
- `engine/situations/normal_unknown.gd` (FAL-725) is `t4-normal-unknown-parameter` (SL4.12, AA only,
  all Paper 2): X is normal with something hidden. The student's facts stay clean (whole values,
  areas in hundredths), and the hidden parameter is whatever they force, so z and the answers are
  floats, from `SymmetrySituation.phi` and `inv_norm`. Its views (`normal_unknown_views.gd`) ask 11
  unknowns: k from an area, an event for Z (a `form` answer with the inequality picked and the
  bound typed), P(within kσ), σ or μ from a tail, σ from an interquartile range or a central
  area, μ and σ from two tails (a `named` answer), μ and σ from equal tails, and μ from two
  z-values. Representations are the equation, a story with percentages, and a shaded curve.
- `engine/situations/normal_probability.gd` (FAL-728) is `t4-normal-probability` (SL4.9, all Paper 2):
  X is normal with μ and σ known, and a region of it is asked for. It is a thin layer on
  `normal-unknown`: one normal distribution, the same stories and the same curve (its views extend
  `NormalUnknownViews`). Its views (`normal_probability_views.gd`) ask 13 unknowns: below, above,
  between and outside values, a percentage or proportion, an expected count, a rejection rule and
  its expected count, exactly k of a sample (the area as a binomial's p), a variable that can be
  negative, a variance written in place of σ, a value recorded to a rounding unit, and a middle
  from two given tails, which is exact. On a shaded curve the stem doesn't say the region again. A
  recorded value has no curve: its strip is too thin to read, and labelling it gives the half unit away.
- `engine/situations/venn.gd` (FAL-725) is `t4-venn-addition-rule` (SL4.6, on all four syllabuses):
  four regions out of a total, shown as decimals, fractions or counts in a story, a Venn diagram
  (PlotView's `venn`, rep `diagram`) or a two-way table (rep `table`, with heads and totals as
  rows). Its views (`venn_views.gd`) ask 12 unknowns: P(A ∪ B), P(A ∩ B), P(A′ ∩ B′), P(A ∩ B′),
  exactly one, a region of a diagram, x in a diagram of expressions, a table entry, and the least
  and greatest overlap. Paper 1 is exact; Paper 2 has decimals to 3 places or counts answered to
  3 s.f. An option that should be a probability is one: `build()` adds near values, because the
  engine's last-resort nudges add 1.
- `engine/situations/sample_space.gd` (FAL-752) is `t4-sample-space` (SL4.6): two dice, a die and a
  spinner, or two spinners on an m × n grid of outcomes, fair or with unusual faces, scored by sum,
  product, difference or larger number. Its views (`sample_space_views.gd`) show the grid as a `table`
  with heads, the two objects drawn (`graph` of kind `spinners`, `ui/spinner_plot.gd`: a die laid out
  flat, a spinner with its sectors to scale) or sentences, and ask 17 unknowns: a hidden cell, the
  number of outcomes, a count, P(score), the boundary words, the complement, a property of the score,
  the first number higher than the second, a sum on matching objects by its mirror, a points rule, a
  biased die or spinner rolled twice, a total to reach with two rolls left, a face from the largest
  sum, a repeated face from the distribution, and q and E(Y) from P(X < Y). Grid-symmetry suits only
  the unknowns whose objects always match, so "Another way" always has a mirror to use. Paper 1 is
  exact, Paper 2 (the grid and rolled-twice unknowns only) is to 3 s.f. Wrong options come from the two
  SL4.6.sample-space-grid misconceptions and the type's own 18.
- `engine/situations/basic_probability.gd` (FAL-728) is `t4-probability-basic` (SL4.5): one chance
  set-up for each unknown. Its views (`basic_probability_views.gd`) ask 18 unknowns: a bag and a bag
  after a change, a two-way table (rep `table`, with totals), a list of data, a total on two dice or
  spinners in words or as a sample space table (rep `diagram`), a listed sample space, the complement
  of a given probability, table, count or two prize rules, at least one with a tree for two trials
  (PlotView's `tree`), a relative frequency from a table or bars (`bars`), a grouped table with no
  total, a long-run value from a running relative frequency (`cumfreq`, every point a real count),
  the more reliable of two tests, and a run of results. Paper 1 is exact; Paper 2 counts and
  products are answered to 3 s.f. Every option is a probability written as the answer is: a decimal
  question drops a slip that doesn't end, and `build()` adds near values.
- `engine/situations/conditional.gd` (FAL-725) is `t4-conditional-probability` (SL4.11, AA only). The
  events come from `VennSituation`; it also draws a two-stage tree (PlotView's `tree`), two draws
  without replacement, the multiplication rule, and normal, binomial and discrete conditionals.
  Its views (`conditional_views.gd`) ask 13 unknowns. A normal conditional on a curve shades the
  given and the wanted area, so the overlap shows darker. Answers are exact on Paper 1, in the
  numbers the question uses, and to 3 s.f. on Paper 2; normal and binomial ones are Paper 2 only.
- `engine/situations/tree_diagram.gd` (FAL-739) is `t4-tree-diagram` (SL4.6, AA only). It extends
  `conditional`: the fit test, colours and answers are shared, and its trees are PlotView's `tree`
  with `heads` (stage names), which allows 2 or 3 branches at each fork and a letter (x, y, ?) on a
  missing branch. Its views (`tree_diagram_views.gd`) ask 14 unknowns: a missing branch, a branch in
  terms of k, a branch after a draw from a tin that loses or gains one, a path, a total over paths
  (a tree, or crates in a story), same or different colours, at least one by the complement, three
  in a row from a tin or a table, a draw in terms of n, the try a first or only success comes on,
  normal groups as the branches (a total, or which group), k on a branch from a path with its other
  root rejected, the rounds of a game that beat a total, and n in a tin that grows. Paper 1 is exact;
  Paper 2 is to 3 s.f., except a branch read off the tree. k and a growing tin are Paper 1; n, normal
  groups and games are Paper 2. Set-ups that repeat a past paper's numbers are left out.
- `engine/situations/independence.gd` (FAL-739) is `t4-independence` (SL4.6, SL4.11, AA only). P(A)
  and P(B) are drawn first, with an exact product. Then the events are known to be independent, or
  they are tested: a fair coin, drawn before anything else, either keeps the overlap at that
  product or moves it a little, with P(A) and P(B) unchanged. So the two cases look alike, and on
  Paper 2 values that differ stay 0.002 apart and read differently to 3 s.f. Its views
  (`independence_views.gd`) ask 13 unknowns: P(A ∩ B), a region such as P(A′ ∩ B), P(A ∪ B), a
  conditional such as P(A′ | B′), P(B) from the union, P(B) from P(A) = kP(B) with a root rejected,
  x = P(A ∩ B) from the two "only" regions (with one repeated root), and five tests, from
  probabilities or percentages, a Venn diagram, a two-way table, two sources on a tree or in words,
  and P(B | A) with the union. `classify-events` picks mutually exclusive, independent or neither,
  a third each, so the two ideas are kept apart. A test's answer is a `form`: the two numbers of the
  method asked are typed and the verdict picked. Every option quotes true values, and two end in
  each verdict, so an option can have the right verdict and still be wrong for its reason: "P(A ∩ B)
  is not 0, so not independent". The quadratics are Paper 2 only; the rest make both papers, exact
  on Paper 1 and to 3 s.f. on Paper 2. Figures reuse PlotView's `venn` and `tree` and the two-way
  table of `VennViews`.
- `engine/situations/sampling.gd` (FAL-726) is `t4-sampling` (SL4.1, on all four syllabuses): a
  population in named groups and a surveyor's method, on both papers, Paper 2 with larger numbers.
  Each group is the interval times its share of the sample, so numbers in proportion are whole.
  Its views (`sampling_views.gd`) ask 17 unknowns: the technique, a disadvantage (a wrong one is
  false of that technique), a systematic sample, its interval and a later pick, the best technique,
  whether a sample is simple random, a group's number in proportion, a shortfall, the most
  under-represented group, and why a sample is biased, which way it leans, what fixes it, what a
  larger sample can't do, why a random sample can miss the mix, how to improve reliability and why
  a source may not be reliable. A reading in words is a `claim`. Representations are a story and a
  table of the groups. The separate `t4-ext-stratified-numbers` still owns rounding to strata.
- `engine/situations/cumulative_frequency.gd` (FAL-726) is `t4-cumulative-frequency` (SL4.2, on all
  four syllabuses), Paper 1 only, as every bank part is. A curve is on a grid of 20 squares by 20
  (PlotView's `cumfreq`): a square up is n ÷ 20, so every 5% of n is a grid line, and a square
  across is set by the story. The curve goes through knots at grid corners, and every value a
  question reads, right or wrong, is a knot, so a reading has one value. Knots are joined by a
  cubic on each stretch whose gradients can't overshoot. Its views (`cumulative_frequency_views.gd`)
  ask 30 unknowns: the median, quartiles, IQR, percentiles and range from the curve or by
  interpolating a table; how many or what percentage lie below, above or between values, a cut-off
  for the top or a top percentage, a share of a limit, and a sample scaled to its whole group; a
  table's running totals and frequencies, p and q from the curve, the point plotted for a class,
  where the curve starts, and pick the curve (GraphView cards, with the points at midpoints or lower
  boundaries, or the frequencies in place of the totals). A table's classes are equal, its estimates
  end in at most one decimal, and its counts are whole.
- `engine/situations/arc_sector.gd` (FAL-726) is `t3-arc-sector` (SL3.4, AA only): one sector, with
  θ in radians, degrees or as a multiple of π. Paper 1 is exact: every value is a + bπ, kept as
  [a, b] and answered as a `form` whose slots follow its shape (`5π/6`, `12 + 3π`, `9π − 4.5`), and
  a wrong option in another shape can be picked but not typed. Paper 2 is to 3 s.f., and a worked-back
  r or θ comes from a given arc, area or perimeter to 1 d.p. Its views (`arc_sector_views.gd`) ask
  22 unknowns: conversions, arcs, perimeters, areas, r and θ back from each, major arcs and sectors,
  r in terms of θ, a bent strip, and a sector rolled into a cone. As the bank asks them, the curved
  strip between two circles and the plate with two segments cut away are Paper 2 only; the plate
  brings in `SL3.4.segment-shaded`, with θ found on the GDC. PlotView's `sector` draws the real
  angle, and `plate` the cut plate.
- `engine/situations/circular_region.gd` (FAL-739) is `t3-composite-circular-region` (SL3.4, AA only):
  a region added up from sectors, triangles, rectangles and circles, or one sector fixed by two
  conditions. Its views (`circular_region_views.gd`) ask 25 unknowns: a segment's area (to 3 s.f. with
  θ in radians or degrees, exact with a landmark angle, and in terms of θ), its perimeter and r worked
  back; a sector and a triangle on a straight wall, its area, its area in terms of θ and an angle in
  the isosceles triangle; a segment and a triangle in a ratio, for the equation θ = k sin θ, θ on the
  GDC and r; a rectangle under a segment; a curved strip's area and its area in terms of r; a semicircle
  on a rectangle, in letters; the part between two tangents and a circle; and θ in terms of r, the
  quadratic in r, r, θ and both roots from a perimeter and an area, r from an arc and an area, and a
  cone from a sector's area. On two conditions the roots r1 < r2 give θ = 2r2/r1 and 2r1/r2, so r2/r1
  above π throws out the small root: `two-conditions-r` and `-theta` keep r2/r1 at 3.3 or more, and
  `two-conditions-both` at 2.9 or less. `ui/region_plot.gd` draws PlotView's `region` kind, each shape
  to its real proportions with the region shaded; a curved strip and a cone use PlotView's `sector`.
  As in the bank the type is nearly all Paper 2: only `segment-exact` is Paper 1 alone, and the
  sector from two conditions makes both papers, with whole-number roots on Paper 1.
- `engine/situations/circular_motion.gd` (FAL-753) is `t3-circular-motion` (SL3.4.convert, AA only):
  something turning steadily about a point, at a rate given as a time for one turn, revolutions per
  minute, degrees or radians per second, with a straight line beside it or an arm. Every question is
  Paper 2, as the bank's three parts are. Its views (`circular_motion_views.gd`) ask 25 unknowns: the
  angle in one second, θ in terms of t, the angle after a time, rates and turns converted, the time to
  turn an angle, half of and all of angle AOB from arccos(d/r), the time on the chord AB with the rate
  given three ways, the time off it, the fraction of a turn on it, the arc beyond it, the distance d
  worked back from that time, and the arc and speed of a tip. An exact answer is a `form` (a multiple
  of π, or whole degrees or seconds); on an exact chord d is k, k√2 or k√3 with r = 2k, so counting in
  landmarks is a true method, and it is offered on those cells and on landmark conversions alone.
  Everything else is 3 s.f. with the rounding trap. A chord is RegionPlot's `sweep`, drawn to its real
  shape with the turning arrow and the marked angle; a turn with no line is PlotView's `sector` on its
  whole circle. The working runs on from the figures it shows, and the situation refuses numbers where
  that would not land on the answer to 3 s.f.
- `engine/situations/bearings_elevation.gd` (FAL-726) is `t3-bearings-elevation` (SL3.3, on all four
  syllabuses). Every question is Paper 2. Its views (`bearings_elevation_views.gd`) ask 19 unknowns:
  back bearings, angles from a bearing, two-leg journeys by the cosine rule or by components, due
  east and due west triangles, elevation and depression with an eye height, a chain or a speed, a
  route's time, connected triangles, and which rule to use (a `claim`). PlotView's `sketch` draws
  the real coordinates, with a north line at each bearing and each label clear of the others; the
  small angles of `time-from-depression` are marked not to scale. A bearing that is worked out stays
  at 100° or more, so its 3 s.f. are three figures.
- `engine/situations/trig_kit.gd` (FAL-727) holds what the exact trig types share: a value is
  [a, b, r], which is a + b√r, with the landmark table, the writing ("(1 + √3)/2", root on top)
  and the `form` answer whose slots follow the value's shape. `ui/plot_view.gd` adds `unit-circle`
  (points, an angle, a shaded quadrant, a dashed line y = k or x = k) and `straight-angle`, and a
  GraphView spec's `x_ticks` marks the across axis in multiples of π.
- `engine/situations/right_triangle.gd` (FAL-739) is `t3-right-angle-trig` (SL3.2 and SL3.3, on all
  four syllabuses): 24 unknowns, 50 cells, about 1 in 10 Paper 1. A triangle has its letters dealt at
  random and is turned on the page, so the right angle is not always at the bottom (no vertex is
  called N: a sketch reads an arc from "N" as a bearing). A ratio can be a fraction, a surd or in
  the letters p, q and r. A side is on top of the ratio or under it, by the other acute angle, from
  a special triangle, a chord from a radius, or a rectangle's side in terms of r and θ. An angle
  comes from two sides, an exact ratio or a gradient, because gradient is tan θ, and a symmetrical
  frame asks for the angle with the vertical and the lengths of a sloping beam's two edges.
  Elevation and depression are always drawn, with the horizontal at the eye, in degrees or radians:
  a walk towards a tower, two towers with equal angles, a cone seen from eye level, the line of
  sight, two points below, and which angle in the figure is the one named. `RightTriangleViews`
  extends `BearingsViews` for its writing and sketch helpers; a sketch gained `circles`.
  `check_right_triangle` reads the numbers back and works everything out again, with exact surds
  or mpmath, and holds each angle of elevation or depression to the horizontal in the figure.
- `engine/situations/exact_trig.gd` (FAL-727) is `t3-exact-values` (SL3.5, AA only, all Paper 1): 11
  unknowns on landmark values, a number in front, sums, related angles past the first quadrant,
  negative or on the second turn, a ratio of π − θ, π + θ or −θ from a given ratio, and the unit
  circle (P's coordinates, sin, cos and tan from a point, signs by quadrant, why tan has no value).
  Representations are the written value, a special triangle or the unit circle, a wave, and a
  table of landmark values with one cell to fill. A reading in words is a `claim`.
- `engine/situations/trig_identity.gd` (FAL-727) is `t3-identity-values` (SL3.6, AA only, all Paper 1):
  13 unknowns on one ratio and a quadrant (the other ratio, tan, sin 2θ, cos 2θ, each with the map's
  methods), cos θ from cos 2θ, written or from a triangle's cosine rule, and expressions to rewrite
  (in sin x or cos x alone, as a cos bx, as a sin bx, a + b sin cx, and a maximum after rewriting).
- `engine/situations/algebraic_proof.gd` (FAL-728) is `t1-algebraic-proof` (SL1.6, AA only): 14
  unknowns on one statement to prove, an identity (a difference of squares, (x − a)² + b, a fraction
  to combine or split, a reciprocal difference, a Pythagorean triple in x) or a claim about integers
  (a multiple of m, a sum of consecutive terms, n² + an + b always even, a sum of squares never
  divisible). A phone can't read a written proof, so each unknown is one decision a proof turns on,
  typed in slots (a `form`) or picked (a `claim`): the simplified form, what both sides reach, a
  hidden line, the next line, the first wrong line and its correction, k in E = mk, the integer
  bracket, the greatest divisor, a remainder, the opening with two letters, or which of four
  arguments is a proof. `AlgebraicProofViews.chain()` writes every proof as lines from the numbers,
  and a slip is that chain with one wrong move carried on, so wrong options are what the slip gives.
  Identities are Paper 1 or 2 and integer proofs Paper 1, as in the bank.
- `engine/situations/prove_identity.gd` (FAL-753) is `t3-prove-identity` (SL3.6.prove-identity, all Paper 1):
  16 unknowns and 34 cells on one trig identity from 14 shapes, each with a number in front and a multiple
  of the letter inside, on the SL identities only (no sec, cosec or cot, no sin 3x). As in `algebraic_proof`,
  each unknown is one decision a proof turns on, typed in slots (a `form`) or picked (a `claim`): the simple
  form, the next line, a hidden line, the first wrong line and its fix, what both sides reach, which of four
  arguments is a proof, the side to start from, which form of cos 2x cancels the 1, a factorised first line,
  and then a value at an angle, a value from a ratio, or a greatest or least value. `ProveIdentityViews.chain()`
  writes every proof as lines from the numbers, and a slip is that chain with one wrong move carried on, so
  wrong options are what the slip gives. Shown as an equation, or for four shapes as a sentence.
- `engine/situations/trig_model.gd` (FAL-727) is `t3-trig-model-parameters` (SL3.7, AA only): 15
  unknowns on one wave from its turning points. Paper 1 has x in multiples of π and whole a, b and d;
  Paper 2 is a story in t, or a decimal phase, to 3 s.f., six parts in seven as in the bank. It also
  asks p sin kx + q cos kx as one cosine, a tan graph's a and b, the shift with b taken out, an
  image's equation, the transformations (a `claim`), p and q of f(x − p) + q, a wheel starting at
  the bottom, c from a rising crossing, and a level from the time above it.
- `engine/situations/trig_equation.gd` (FAL-727) is `t3-trig-equation` (SL3.8, AA only): 16 unknowns
  on one equation on an interval. Every solution comes from `solve()`, on the landmarks; each is a
  slot of a `form` answer in any order, and a wrong option with another count can be picked but not
  typed. Paper 2 is the two decimal unknowns only, as the GDC method needs one (4 cells in 100),
  so the type stays on the bank's Paper 1. Factorising, dividing to tan and rejecting a factor
  each have their own unknowns, with the lost solutions as their wrong options.
- `engine/situations/solid.gd` (FAL-726) is `t3-solid-volume-area` (SL3.1, on all four syllabuses):
  one solid, as a labelled sketch (PlotView's `solid`, rep `diagram`) or in words: a cone, pyramid,
  sphere, hemisphere, a composite of them, a hollow cylinder, a cylinder inside a sphere, or the flat
  sector that rolls into a cone. Its views (`solid_views.gd`) ask 32 unknowns: volumes and surface
  areas, a height from a slant height, slant height or slant edge, l and V from a total surface, r
  and h from a volume, the cost of painting a tank, r from a composite's volume with the GDC's
  solver (Paper 2 only), expressions in x or in r and h, and the sector's radius, angle and area.
  Paper 1 measures are whole, from Pythagorean triples where a slant comes in, and a multiple of π
  is a `form` answer with the multiple typed. Paper 2 measures have one decimal place and answers
  are to 3 s.f. Expressions are Paper 1 only, except S from a cylinder's volume.
- `engine/situations/standard_form.gd` (FAL-726) is `t1-standard-form` (SL1.1, on all four
  syllabuses): numbers a × 10^k with a an exact `Q` and k an int, so nothing has to fit a float. Its
  views (`standard_form_views.gd`) ask 19 unknowns: converting both ways, bringing a back between 1
  and 10, the largest or smallest of four mixed forms, a GDC display, p × q, p/q and p²q, and
  stories: how many times larger, a time, a total, a change of unit, a multiple of an amount and a
  volume π(a × 10^k). An answer a × 10^k is a `form` answer with a and k typed, so 64 × 10⁵ can be
  typed and is marked wrong, and a negative k is typed like any negative number. `form` has no
  rounding trap of its own, so the views set one, with a to 2 s.f. E-notation is an option that can
  be picked but never typed. The font draws every superscript digit and ⁻; `Fmt.sup` leaves a power
  of 1 out, so `StandardFormViews.ten` writes 10¹ and 10⁰ itself. The GDC methods are Paper 2 and
  the by-hand multiplying and dividing is Paper 1.
- `engine/situations/data_summary.gd` (FAL-695) is `t4-summary-statistics` (SL4.3, on all four
  syllabuses): one discrete data set, shown as a list in no particular order (rep `terms`)
  or as a frequency table, all exact (`Q`). Its views (`data_summary_views.gd`) ask 11
  unknowns: the mean, median, mode, range, quartiles (the median of each half, the median
  itself left out when n is odd) and interquartile range of the data; a missing value in a
  list or a missing frequency p in a table from a given mean; a combined mean of two
  groups; and, for eight measurements with one outlier, the best measure of the centre or
  the measure of spread it leaves alone (a `choice` answer). A cell says which papers it can
  make (`papers()`): the GDC working (`gdc-1var`) is Paper 2 only, the totals, combined
  mean and outlier questions are Paper 1 only, the rest make both. Paper 1 has small whole
  numbers and a mean ending in at most one decimal place; on Paper 2 a mean needs rounding
  and is answered to 3 s.f. with the rounding trap, and everything else stays exact. Wrong
  options come from the SL4.3 misconceptions (the middle of the unordered list, the position
  for the median, the count for the mode, Q₁ + Q₃ for the IQR, the quartiles of the
  unordered list, the mean of the two means, p left out of Σf, the mean or the mode as the
  best average) and never read as a fraction (`DataSummaryViews.tidy`). As every exam type, it
  offers no extra format: `test_extension.gd` holds that rule.
- `engine/situations/sequence_proof.gd` (FAL-753) is `t1-sequence-proof` (SL1.6.series-proof), Paper 1
  throughout as all four of its parts in the bank are: one claim about arithmetic and geometric terms,
  picked from twelve shapes. As in `algebraic_proof_views.gd`, whose helpers its views extend, a phone
  can't read a written proof, so `sequence_proof_views.gd` asks 21 unknowns, each one decision a proof turns
  on: a relation between unevenly spaced terms, the bound on a second term when two sequences share
  their ends, the common ratio that proves three terms in k are geometric, d in terms of a when
  arithmetic terms are also geometric, the logs of a geometric sequence, uₙ₊₁ − uₙ, uₙ from Sₙ, a cubic
  whose first gaps are equal, a sum by the formula or forwards and backwards, a hidden line, the next
  line, the first wrong line and its correction, and which of four arguments is a proof. They show the
  claim in symbols or in words, or a figure (`dots` in `ui/plot_view.gd`: a rectangle in L-shaped layers,
  or two staircases that fit together), so all four of the map's methods are played. `lines_of()` writes
  every proof as lines from the numbers, and a slip carried down it makes each wrong line.

- `engine/situations/trig_quadratic.gd` (FAL-753) is `t3-trig-quadratic` (SL3.8.quadratic-in-trig),
  the `trig-quadratic` situation, and `TrigQuadraticViews` extends `TrigEquationViews`. The equation
  is built forward from its roots in sin x, cos x or tan x, so it factorises cleanly, then disguised:
  with cos²x, with cos 2x, as a quadratic in sin 2x, as a number over a bracket, as sin 2x equal to a
  multiple of cos²x, or with surd coefficients. Its 22 unknowns take the solution a step at a time
  (the quadratic in u, the identity, the brackets, the values of u, the exact root from the formula,
  the root to reject and why, the letter from one solution) or whole (every solution, in radians or
  degrees, how many, one of them, their sum). The figures are the whole equation as one curve, or
  y = sin x with a dashed line at each root. Everything is Paper 1 with exact answers but `gdc-solve`
  and `gdc-count`, where the map's GDC method lives: that is 6 of the 48 cells, so `test_paper.gd`
  gives the type an `OVER_SHARE`, and the bank's and the map's own equations are never drawn.
- `engine/situations/depreciation.gd` (FAL-752) is `t1-depreciation` (SL1.4), the `depreciation`
  situation: a price P that keeps a fixed fraction c of its value each year, month or quarter. Its
  views (`depreciation_views.gd`) show it as a story, as V = P(c)^t, as a table of three whole times
  (exact to the cent) or, for a time, as the curve and the target with their crossing marked. It asks
  12 unknowns, all Paper 2: the value after n years (or on a date), the total loss, the loss in one
  year, the price paid, the rate from two values or read off the model, a value with a different
  rate in the first year, the extra money needed on top of an account, and the least whole number of
  years to fall below a target or a percentage of the price, or of years or months or quarters from a
  rate per month or quarter. Methods are the multiplier, the TVM solver with a negative rate, a
  year-by-year run, logs, a GDC table and a graph. Money is answered exactly to the dollar, and every
  value, and every slip offered, leaves a fraction of a dollar at least 0.15 from the edge at 0.5.
- `engine/situations/derivative_model.gd` (FAL-753) is `t5-derivative-model-gdc` (SL5.6.rules-with-values
  and SL5.1.interpret-derivative), the `derivative-model` situation: a story modelled by an exponential, a
  logistic, a product te^(−kt), a wave with a trend or a logarithm, and the chain, product and quotient
  rules with values. Its views (`derivative_model_views.gd`) show the model on a line or in a story, with
  a graph of the model and its tangents, of the rate and a line, or of two models; a table of values and
  rates; or straight pieces to read. It asks 20 unknowns over 62 cells, all Paper 2: the rate at a time,
  with its units or per a shorter unit, the first time a rate is reached, the greatest rate and when, which
  way the quantity is going, what a rate means in the story, two models compared, the total time one rate
  is greater, the steeper of two tangents, a tangent's estimate, and a product, quotient or composite from
  a table or from graphs. The GDC's dy/dx is the method `gdc-derivative`, appended to SL5.6.rules-with-values.
  A model's answers are to 3 s.f. with the rounding trap and values from a table or graphs are exact.
- `engine/situations/compound_interest.gd` (FAL-695) is `t1-compound-interest` (SL1.4, on all
  four syllabuses): money invested at a nominal annual rate r %, compounded 1, 2, 4 or 12
  times a year, for n years. Its views (`compound_interest_views.gd`) ask 6 unknowns, all
  Paper 2 with the formula or the GDC's TVM solver: the value after n years, the interest
  earned, the amount to invest now, the annual rate, the least whole number of years to pass a
  target, and how much more one account is worth than another (as a sentence or as a table).
  Values are floats, as a GDC computes them. Money is answered exactly to the cent, so every
  value, and every wrong option offered, leaves a fraction of a cent at least 0.15 from the
  rounding edge at 0.5 (`CompoundInterestSituation.cents_clear`). A rate is a quarter of a
  per cent and is answered to 3 s.f. with the rounding trap, found from the FV as shown (a hair
  off the quarter, so the trap's side is fixed); a time is the first whole number of years that
  passes the target. Wrong options come from the SL1.4 misconceptions: the annual rate over kn
  periods, simple interest, the total for the interest (and back), the root with no 1 taken
  off, the total growth shared over n years, the time rounded to nearest, the periods given as
  years, and two accounts compared on their nominal rates. As every exam type, it offers no
  extra format: `test_extension.gd` holds that rule.
- The rest of the Quadratics region (FAL-414) is four more situations. Three extend
  `quadratic` by calling its `generate()`: `quadratic_parameter.gd` (a quadratic with a
  constant k, given directly or as a line meeting a curve, for `fn-discriminant`),
  `quadratic_equation.gd` (the quadratic = 0, plain or wrapped: a context, b^(2x), x + c/x,
  a sum of logs, for `fn-solve-quadratic`) and `quadratic_inequality.gd` (the parabola
  against a number, for `fn-quadratic-inequality`). `curve_line.gd` stands alone: it picks
  the meeting x-values first and builds the curve as the line plus a(x − x₁)(x − x₂), for
  `fn-curve-intersection-quadratic`. Their answers add kinds to `answer.gd`: `interval`
  (k is between or outside two numbers, with the ends left out or included), `bound`
  (k > 4), `kvals`, `delta_nature`, `quad_in` (Δ in k, or a quadratic in u), `kpoint`,
  `points2` (two points, either order), `surd` (m√r), `surd_roots`, `line`, `npoint`,
  `kroot`, `ineq_a` and `choice`. The graph view also draws a line (`graph.line`). The
  Paper 2 context (a length to 3 s.f.) is never for the factorising method:
  `QuestionEngine.make()` passes the method that made the numbers to the recipe as
  `need.angle`. That is the `same_angle` method for "Another way", so switching to
  factorising keeps a Paper 2 context, and the factorising working says it fails there
  and uses the formula.
  Paper 2 versions (FAL-419), chosen by `need.paper` with each views' `papers()`: in
  `fn-solve-quadratic` a context, b^(2x) (u not a power of b, so x = ln u/ln b) and a sum
  of logs (x(x + d) = c with no whole root), each x to 3 s.f.; in `fn-quadratic-inequality`
  against 0, against a constant and with a < 0, whole-number coefficients with irrational
  roots, the interval's ends to 3 s.f. (a Paper 2 graph marks no roots), and the
  largest-integer context is always Paper 2; in `fn-discriminant` equal roots (not on a
  sketch), an interval of k and "always positive" on the families whose Δ is a quadratic
  in k (b, grad, both) with irrational zeros, k to 3 s.f. `interval`, `bound` and `kvals`
  answers honour `show: "sf"`. `fn-ext-quadratic-model` picks its own paper, but takes a
  forced one (a ball with a = −4.9 on Paper 2; pens and tables are Paper 1).
- `engine/situations/cubic.gd` is the Topic 5 situation: a cubic built
  from f′(x) = 3a(x − p)(x − q), so its stationary points are on whole numbers, with a
  point x₀ for the gradient, tangent and normal (FAL-394). Its Paper 2 version
  (FAL-419) is a calculator cubic with decimal coefficients and irrational stationary
  points, x₀ a decimal: x for a gradient, the tangent, the normal, the stationary points
  and the local maximum are then asked to 3 s.f. with GDC working (`roots`, `line` and
  `points2` honour `show: "sf"`); the derivatives, k, the nature and the inflexion stay
  Paper 1.
- **The Quadratics extension types** (FAL-459) are seven more situations, one per
  type: `expand.gd`, `factorise.gd`, `surds.gd` and `linear_inequality.gd` (the
  `fn-pre-*` prior learning, which the dungeon's warm-ups and after-a-miss questions
  now play), `quadratic_model.gd` (a thrown ball or a fenced pen, Paper 2 with
  a = −4.9), `equivalent_forms.gd` and `symmetry.gd` (the two link types, which reach
  into log laws, cos 2x, negative powers, the normal curve, related angles and nCr).
  Their views extend `extension_views.gd`. Each is built from its answer, so the
  numbers stay clean. The `fn-pre-*` misconceptions have no catalogue ref, so they
  are logged as `<type id>#<index>` (`QuestionEngine.misconception_text`). The area
  grid of `fn-pre-expand` and `fn-pre-factorise` is a table, and `ui/plot_view.gd` draws
  the graphs that aren't a parabola: a number line, a shaded normal curve, sin x or
  cos x on [0, 2π], and the bars of a row of Pascal's triangle. Views whose context
  depends on the method (find-the-mirror: a parabola or nCr) define `build_view()`,
  which is told the method. New answer kinds: `poly` (powers fixed or typed),
  `named`, `pair`, `brackets`, `brackets2`, `common`, `pm_surd`, `range2`,
  `related`, `features` and `angles`. An answer can set `show: "sf"` (3 s.f.), and
  options of such an answer are told apart by their text.
- **The Exponentials and logs region** (FAL-418) adds four exam situations and three
  extension ones. `exp_model.gd` is one model in a context, Paper 2 (values and times to
  3 s.f.): growth or decay as P₀(a)ᵗ, shifted, continuous with k given or from a
  half-life or a reading, limited growth C + Ae^(−kt), a log₁₀ reading, or two models
  that meet. `exp_log_pair.gd` is an exponential and its log inverse, with modes for
  bases from one family, an e-equation, a composite inequality, a translation or stretch
  between exponentials, f∘g against g∘f and the log of a square; `fn-ext-exp-graph`
  shares it (A·b^(x − h) + c). Its Paper 2 version (FAL-419) asks g at an input whose
  inside is not a power of b, g⁻¹ at a decimal, log_b(x − h) + c = a decimal and
  e^(mx) + c = d, each to 3 s.f. with a GDC and the rounding trap; `fn-ext-exp-graph`
  stays Paper 1. `log_quadratic.gd` extends `quadratic`: a downward
  parabola whose top is a whole power of the log's base, so the maximum, the base and the
  surd zeros come out exact. `log_function.gd` extends `exp-log-pair`: A·log_b(mx + n) + c.
  The extension situations are `percent.gd` (`fn-pre-percent-multiplier`),
  `growth_patterns.gd` (`exp-growth-vs-linear`, extending `exp-model`) and
  `link_growth.gd` (`fn-link-multiplicative-growth`). `engine/plot.gd` makes graph specs
  of sampled curves with dashed asymptotes, which `ui/graph_view.gd` draws. New answer
  kinds: `lnq` (an exact k as m·ln r, marked by value, so (1/5) ln(1/2) is −(ln 2)/5),
  `pct` (a rise or fall of r%), `expmodel` (P₀(a)ᵗ), `limited` (C, A and k), `fn` (a
  function of x with its shifts typed; a wrong option may take another form, such as
  1/f(x) or (x − p)ᵇ + q), `logform` (log_b x = y) and `xpow` (xⁿ). `Answer.typable()`
  says whether an option could be typed into the answer's slots; a wrong option in
  another form can be picked but is never taken as a typed misconception. The
  catalogue's pick-the-graph unknowns on those situations play as four descriptions
  (from the equation) or four equations (from the graph).
- **The Graphs and key features region** (FAL-420) adds five exam situations, all but
  one Paper 2, whose numbers only a GDC finds. `engine/situations/gdc_kit.gd` is what
  they share: every zero of a function on an interval (a sign change on a sample grid,
  closed in by Brent's method, `engine/brent.gd`), turning points as the zeros of the
  derivative, the region's way of writing a function, and the pick-the-graph cards.
  Values are kept as Q to nine decimal places, shown to 6 s.f. in the working (as a GDC
  shows them) and asked to 3 s.f. `gdc_curve.gd` is one awkward curve on a closed
  domain (an exponential plus a line, a cubic, a bell curve, sine or cosine plus a line,
  a factorised product, an x-factor cubic, a log with its asymptote at one end, a bell
  form), for `fn-sketch-gdc` and `fn-gdc-features`. `gdc_two_curves.gd` is two curves
  that cross one to three times (a curve and a line, two models of time, f and f⁻¹, or
  one crossing past x = 10), for `fn-gdc-intersection`. `gdc_combined.gd` extends it
  with a function made from them (how far one town or drug is ahead, the distance from
  a point to a curve, the sum), for `fn-gdc-optimise-combined`. `gdc_context_equation.gd`
  is an equation that mixes families from a context (x = k sin x, a circle's segment, an
  exponential against a line, a first time, savings, two curves in two unknowns), for
  `fn-gdc-solve-equation`. `graph_from_features.gd` is Paper 1: exact features (a
  parabola, a model on an interval, a curve that levels off, sin or cos on 0 to 2π, a
  curve from conditions) and the sketch that shows them, for `fn-sketch-from-features`.
  Each recipe draws its family once and looks at 48 samples before it finds roots, so a
  question takes about 7 ms, about ten times the rest of the sweep; CI runs the sweep in
  eight shards (`tools/stress-questions --shard=k/8`). New answer kinds: `xs` (a
  list of x-values, any order; options may have other counts), `pts` (a list of points,
  any order; a wrong option may give only the x-coordinates) and `graph` (pick the
  graph). A view's rounding trap can carry a misconception (`trap_ref`) where the
  catalogue's mistake is too few figures: picking it is a glancing hit that logs it.
  `Answer._sorted` and `_pairs` compare as floats, because Q.lt's cross-multiplying
  overflows on nine-decimal values. The crossing scan of `gdc-two-curves` also looks at
  every sample that sits lower than both neighbours on one side of the line (`_dips`):
  a curve that only just dips through it (two crossings 0.04 apart, 0.001 deep) has no sign
  change between samples, and the situation is turned down for the shallow angle, as the
  answer checker's finer grid would find them (FAL-695). The checker keeps a crossing exact
  when x is a rational root and y is rational (`gc_exact_point`), as the game does.
  The region's extension types: `fn-concept-solutions-as-intersections` is more views
  on `gdc-two-curves`; `gdc_inequality.gd` extends it with f(x) > g(x) or < g(x), solved
  from the crossings (`fn-ext-inequality-graphical`); `graph_reading.gd` is reading a
  grid and rounding (`fn-pre-graph-reading`); `graph_match.gd` matches y = a·bˣ + c or a
  factorised quadratic to its graph (`fn-ext-match-graph`; the match format isn't
  built, so matching several plays as picking one); `link_extremes.gd` is an extreme
  found several ways (a height model's top, a wave's range and first peak, a touching
  line, a closed interval, a cubic's turning points: `fn-link-extremes`); and
  `link_graph_algebra.gd` is an equation as two graphs that meet (`fn-link-graph-vs-algebra`).
  The two link types extend `extension_views.gd` and offer true-false-reason and
  method-pick; the concept type and graph-match offer true-false-reason. Not built yet:
  error-spot (fn-ext-inequality-graphical, fn-pre-graph-reading) and method-pick for
  fn-concept-solutions-as-intersections.
- **The Composite and inverse region** (FAL-422) adds three exam situations. `composite_pair.gd`
  is two rules chained, f and g, as `{"t", "co"}` polynomials (a line, x² + c, (x − h)², x³ + c,
  or sin x on Paper 2, with a generic quadratic for an outer rule to find), with modes for
  the forward composites and a value, a constant k from a value or from a stated coefficient,
  an equation (f∘g)(x) = t, f∘f, f∘g against g∘f, a chain of steps in words, a rule split in
  two, and the two reversed composites (find g given f and f∘g, find f given g and f∘g). Its
  views (`composite_pair_views.gd`) say each rule as f(x) = … or in steps ("double, then
  subtract 3"); an expression is the `poly` kind, k a `kvals` pair or a number, the solutions
  an `xs` list and the order-of-composition and decompose questions a pick of four sentences.
  The one Paper 2 value is (f∘g)(x₀) with f = sin x in radians, to 3 s.f. with the rounding
  trap, and a k from (a·x₀ + k)² = r with r not a square, to 3 s.f. `inverse_rule.gd` is a rule
  from a family with its domain: a line, (ax + b)/(cx + d) with whole-number asymptotes,
  √(px + q) + r, a quadratic on one side of its vertex, or b^x + q. Students can't type a
  function of x, so its views (`inverse_rule_views.gd`) offer an inverse, a domain, an
  asymptote pair or a reflection claim as four written options (the `choice` kind), and a
  constant, a value or a k as a number. The checker reads each option back with SymPy and
  tests it as maths, so the right one is the inverse and every wrong one is shown not to be.
  `graph_table.gd` is f (and g) at six consecutive whole numbers, drawn as dots joined by
  lines (so a one-to-one f is always rising or falling) or written as a table or a sentence
  of values, with a rule mode for the views that print the rule beside the graph. Its views
  (`graph_table_views.gd`) read a value, a composite, an inverse value, a domain or range,
  the matching points of f⁻¹ (the `pts` kind), every solution of f(x) = k on a graph that
  turns back, and why it has no inverse. The checker rebuilds f and g from the table, the
  graph's dots or the sentence, never from the engine's givens. Paper: the algebra of
  `fn-inverse-algebraic` is exact on both papers, so its Paper 2 questions (four in five, as
  the exam has them) have the same exact numbers and the calculator on offer; the graph and
  table readings are all Paper 1. A mini-boss on `fn-composite` asks the composite and then
  its value (`Tuning.CHAINS`); the other unknowns each need their own numbers, so they are
  single questions.
- **The Rational functions region** (FAL-423): `rational_function.gd` is one
  linear-over-linear function f(x) = (ax + b)/(cx + d) = A + B/(x − h), built from its asymptotes
  and stretch so its intercepts are never none (a, d ≠ 0) and ad − bc ≠ 0. Paper 1 keeps
  c = 1, 2 or 3 and intercepts that are whole numbers, halves or thirds; a graph or card needs c = 1
  with the asymptotes and both intercepts whole and inside the plot. Paper 2 (`papers()`) gives
  a, b, c, d that need a calculator, so the asymptotes and intercepts of `fn-rational-asymptotes-
  intercepts` are decimals that don't end, asked to 3 s.f. with the rounding trap, and `fn-rational-
  sketch`'s reciprocal of f is Paper 2 (as in the bank) with asymptotes between the grid lines. Its
  extras, asked by a view's need, are a line y = mx + n that meets f 0, 1 (a tangent) or 2 times, a
  parabola that meets it 1 to 3 times (a count by the cubic's discriminant, found again numerically;
  a restricted domain `x > 0` changes the count), a horizontal line y = k, k = A or not, a relation
  and a k (0, or a value whose boundary is whole) for an inequality, and the 1, 2 or 3 of y = k/x.
  `rational_cards.gd` draws every graph: a curve is a triple (A, B, h), drawn as two branches that
  run to the edge of the plot and stop, so **no line is drawn across x = h** (a card with such a
  line is the wrong one, `through`). The views (`rational_function_views.gd`) are 24 unknowns:
  asymptotes and intercepts are typed (`axis`, `xint`, `yint`, `named`, `number`), the rest are
  a pick of four written options (`choice`), a pick of four graphs (Q13) or a count. Each wrong
  graph changes one thing of the right one (`flipped`: B's sign, `zero-at-h`: the asymptote and the
  zero swapped, `through`, `mirrored`: x = −h, `swapped`: the asymptotes swapped), tagged with its
  misconception. `axis` answers honour `show` and a wrong option may be the number alone (var ""), the
  asymptote written as a number. The checker reads each card back as a triple from its dashed lines
  and its curve and tests it against the change it names, and finds every asymptote, intercept,
  solution set and count again with SymPy. `ui/graph_view.gd` draws a rational function's branches in
  one colour (`one_colour`) and a second curve (the line or the parabola) in the other
  (`sand_from`). The exam types offer no extra format.
  **The Rational functions extension types** (FAL-423): `fn-ext-transformed-reciprocal` is seven more
  unknowns on the same `rational-function` situation (mode `split`: f = A + k/(cx + d) with A and k
  whole and c = 2 or 3, for the scaled split), asked as `named` constants (A and B, A and k, or A, B and
  h read off a graph with one marked point), a pick of four translations ("3 right and 2 up"), of a
  stretch and a translation in order, or of single fractions. `algebraic_fraction.gd`
  (`fn-pre-algebraic-fractions`, the level-0 prior learning, so the dungeon's warm-ups can play it) is
  built from its answer: an excluded value, a fraction simplified by cancelling a factor (or one that
  can't be, where cancelling terms is the slip), a sum of two fractions, an equation a + k/(x − h) = c
  whose solution is whole and never excluded, and a missing numerator. The answers are written options
  (`choice`) checked as functions by SymPy, and an equation's solution is a typed number. Its
  misconceptions have no ref, so they are logged as `fn-pre-algebraic-fractions#<index>`.
  `asymptote_gallery.gd` (`fn-concept-asymptote-meaning`) is curves with asymptotes side by side: a
  linear-over-linear one, a curve that meets its horizontal asymptote (x/(x² + 1), x·e^(−x), A + x/(x²
  + 1)) or does not, (ax + b)/(cx + d) with ad = bc (a gap, not an asymptote) and a level that settles.
  What an asymptote means is an explanation, so each answer is one of four statements, and the
  type's true-false-reason format plays them as a student's claim. `rational_model.gd`
  (`fn-ext-rational-model`) is a model (αx + β)/(x + γ) in a context: an average cost
  (F + vn)/n, a mixture topped up (s + px)/(V + x) or a level that settles (Lt + P₀k)/(t + k), with an input
  where the value ends, a table, a whole input and its value, a target whose input is not whole (so the
  least whole number rounds up: rounding down and giving the output are the slips) and one data point
  for a constant. Every answer is exact (Paper 1): the catalogue's Paper 2 versions, to 3 s.f., and
  its `multipart` format are not built. Built formats of the extension types: error-spot on
  `split-to-form` and on `clear-and-solve` (the catalogue's one error-spot slip of each),
  true-false-reason on every unknown of the gallery and the model. Not built: method-pick, order-steps
  and match (see the formats above).
- **The Function basics region** (FAL-424): `basic_function.gd` is one rule (a polynomial, a root,
  an exponential, a rational or a model such as a falling ball, a cost, a population or a cooling
  drink) and its inputs and outputs. `fn-evaluate-function` and `fn-concept-function-notation` are
  on it, and two situations extend its rules: `basic_restricted.gd` (`fn-domain-range`: a rule with
  a stated domain, a reflection, a second function or an inverse, so the range has to be worked out)
  and `basic_one_to_one.gd` (`fn-inverse-reflection`: a one-to-one curve with key points on grid
  points, so the inverse comes from swapping coordinates). `basic_relation.gd` (`fn-ext-is-function`)
  is a relation that may or may not be a function, as a graph, a mapping or an equation, and
  `substitute.gd` is the level-0 `fn-pre-substitute`. The graph's `filled` and `open` points mark
  whether a domain's end is included. Paper 2 rules need a calculator; the extension types are Paper 1.
  Boss chains: `fn-evaluate-function`, `fn-domain-range` and `fn-inverse-reflection`.
- **The Lines region** (FAL-424): `line_conditions.gd` is a segment and a line built from it: the
  two points come first, then the gradient, the midpoint and a new line through a chosen point, so
  any of them can be hidden. `fn-line-from-conditions` and `fn-concept-gradient-meaning` are on it. The
  answer kind `gline` is ax + by + d = 0, right at any non-zero whole-number multiple of either sign
  (the question asks for integers, not a > 0; a fractional multiple is glancing, FAL-788), and a `line`
  answer's text is y = mx + c. `line_crossing.gd` (`fn-ext-intersection-lines`) picks the meeting point
  first; a Paper 2 pair has one that needs the GDC, to 3 s.f. `line_model.gd` (`fn-ext-line-model`) is a
  fixed amount plus a steady rate. `linear_equation.gd` and `simultaneous.gd` are level-0, with the
  solution picked first. `link_rate.gd` (`fn-link-rate-of-change`) is one rate in four forms: a
  sequence's d, a line's m, a regression gradient and a derivative. Its `match-rate-kind` is a match in
  the catalogue, so it plays as one pick of the whole matching, A to D, until that format is built.
- **The Transformations region** (FAL-424): `transform_chain.gd` is a base graph and up to three
  moves, with the moves picked first and everything derived from them, so f, g, the moves or a point
  can each be hidden: f and the moves give g, f and g give the moves, g and the moves give f.
  `fn-transform-describe`, `fn-transform-apply` and `fn-concept-transform-order` share it, each with its
  own views file, and the sketch unknowns are a pick of four graphs (Q13). `link_transformations.gd`
  is one vector and factor in a parent graph, a data set, a normal curve or an area, and
  `link_vectors.gd` is one vector as a translation, a vertex, a wave's shift, a line's direction, a
  step in 3D or a time delay. The checker works every chain again from the base and the moves, reads
  each option back into a curve or a chain, and calls it right only if it is the same curve as the
  truth. A graph in straight pieces has no rule, so there the letter f stands for a cubic with no
  symmetry. Not built in these three regions: `match` and `order-steps` (the format isn't built
  yet), and error-spot on `fn-ext-intersection-lines`, `fn-concept-transform-order`, `fn-link-vectors`
  and the exam types.
- **The E14 extension types** (FAL-777): six types, each on its own situation. `mutually_exclusive.gd`
  and `conditional_diagram.gd` (a two-way table, a Venn diagram or a tree, drawn) for SL4.6;
  `z_score.gd` (a normal curve with μ and steps of σ marked) for SL4.12; `sign_at_point.gd`,
  `gradient_from_graph.gd` (a curve with its tangent ruled, a table either side of x = a, or the
  GDC) and `rate_of_rate.gd` (a quantity, its rate and the rate of its rate, as signs, a sentence,
  a curve or a cubic model) for SL5.1, SL5.2 and SL5.7. Choosing the tangent at P is a pick of four
  graphs (Q13). Built extra formats: true-false-reason on every unknown of the z-score,
  sign-at-point, mutually-exclusive and rate-of-rate types and on all but pick-tangent of
  gradient-from-graph; error-spot on z and x of the z-score type and on the table and Venn cells of
  the conditional type; method-pick on every conditional cell. Not built: `match` on
  `t4-ext-mutually-exclusive`, `t4-ext-z-scores` and `t5-ext-interpret-second-derivative` (the format
  isn't built yet). A sign-at-point answer is a direction and its reason, so its `value` format
  plays as a pick of four.
- A **view** picks the unknown, the representation, the angle (method) and the format.
  `engine/situations/quadratic_views.gd` has one builder per unknown: what is shown,
  the answer, the wrong options (each catalogue misconception's `wrong` rule, tagged
  with its `ref`; then `fillers`, options with no slip behind them) and a worked
  solution for every method that suits the unknown.
- A **worked-solution step** (FAL-426) in `methods[angle].steps` is a String, or
  `{"move": "<move id>", "board": "<text>"}` when it carries a move tag for the
  explainers: the move is the general step from `curriculum/moves.json`, and the board
  is this question's text. Read steps with `Step.text(st)` (what is shown: the board,
  or the String) and `Step.move(st)` (the move id, or ""), never by type. The checker's
  export writes steps as text, with each solution's `moves` beside them (a move id or
  null per step).
- `QuestionEngine.make(view)` (`engine/question_engine.gd`) returns the question, its
  marking and its working for any explicit view and seed. The same view and seed always
  give the same question. `QuestionEngine.cells()` lists the coverage cells.
- **One situation, many questions**: each view sets its own `need`, so on its own each
  unknown gets its own numbers. `QuestionEngine.families(type, rep)` splits the
  unknowns that list a representation into families whose needs merge with no conflict
  (`merge_need()`: booleans or-ed, `"any"` gives way to a set value). A view with
  `"shared": true` is built on its family's situation, generated from the merged need,
  so every unknown of the family has the same numbers for the same seed. A situation's
  views can define their own `merge_need()` if the default doesn't suit them.
- **Formats**: the layer names all eight from the plan. `value` (slot inputs such as
  a(x − □)² + □) and `mcq` are built, and the concept probes play as a verdict
  (true or false; always, sometimes or never; the sign) and then the reason.
  Three more are built on a question's multiple-choice form (FAL-459), each as four
  options with a `reason` shown after the answer: **error-spot** (a student's four
  lines of working, from the catalogue's `error-spot` misconceptions; which line is
  the first wrong one), **method-pick** (which method works: the view's method against
  the catalogue's failing methods and the view's own `pick_wrongs`; never asked on a
  method the catalogue says fails) and **true-false-reason** (a student's answer,
  right or one of the wrong options; agreeing with a misconception logs it). A cell
  offers one only where its type's catalogue `formats` lists it and its views build it
  (`QuestionEngine.extra_formats()`), and the planner and a boss's link part ask one
  about a third of the time (`EXTRA_SHARE`). Exam types offer none. **pick-the-graph**
  (Q13, FAL-420; the catalogue calls it `graph-pick`) is built: students can't draw, so
  a sketch question shows four graphs, `q.graphs`, and asks which is right. A view
  whose answer is the `graph` kind plays it whatever format was asked
  (`GdcKit.pick()` shuffles and letters the cards). Each wrong card changes one thing,
  a typical mistake: its option's `ref` is the misconception (logged like any other),
  `mistake` names the change (the checker tests that change alone) and `why` says what
  is wrong, which the feedback shows as `reason`. The practice and fight screens draw
  the four cards in a 2 × 2 grid, each above its letter button, in GraphView's card
  mode (thinner lines, smaller dots, fewer numbers), so they read on a 360 px phone.
  `match`, `multipart` and `order-steps` are not built.
- **Paper 1 or 2** (FAL-419): every question carries `paper`. Paper 1 numbers come out
  exact; Paper 2 numbers need a calculator, and only Paper 2 questions show the
  Calculator button (see "The calculator" in [`game/README.md`](../README.md)). A type the IB asks on both papers makes
  both, in the ratio of its bank parts (`paper: {"p1", "p2"}` in `data/catalogue.json`,
  from `stats.paper`). Each situation's views say which papers a cell can make
  (`papers(unknown, rep, angle)`: `[1]`, `[2]` or `[1, 2]`); `QuestionEngine` draws the
  paper on its own seeded stream (so the numbers stream is untouched), boosting the
  cells that can make both so the type lands on the exam's share
  (`QuestionEngine.paper_chance`), and hands it to the recipe as `need.paper`. A
  situation that sets its own `paper` has the last word, so the badge always matches the
  numbers. A boss chain and a family's shared situation are on one paper. Extension types
  have no exam counts, so their recipes decide as before. Concept probes are Paper 1. A
  view may force one with `"paper": 1` or `2` (and a deep link with `&paper=2`).
- **No calculator on Paper 1** (FAL-758): a method that needs a calculator (`QuestionEngine.gdc_method`: an id
  starting `gdc-`, a name with GDC in it, or `CALCULATOR_METHODS`) never shows on Paper 1. A cell asked by one is
  always Paper 2, in `cell_papers`, so a shared family or a boss chain can't fall back to Paper 1. A Paper 1
  question drops the rest from its solution tabs and from "Another way" (`angles_on_paper`). A cell whose views
  build only Paper 1 numbers keeps them on Paper 2, unless `tools/check_answers.py` holds it to Paper 1: the
  catalogue then doesn't list that method for its unknown. `test_paper.gd` scans every Paper 1 question for calculator
  words. `OVER_SHARE` there lists the types this puts above their exam's Paper 2 share.
- **The Method line** (FAL-758): a fight hides it on exam-style questions, as the exam leaves the method to the
  student. "Another way" follow-ups, other questions and the explorer keep it. Two integrals keep it because the
  method sets the answer's form (`linear-square`, `rewrite-trig-product`). Neither is an exam-style unknown.
- **Marking** (`engine/answer.gd`): exact or right to 3 s.f. More figures are right too
  when they are the value correctly rounded (12.35 for 12.3456). The right value with
  too few figures (2.3 for 2.347) is a **glancing hit** (Q7): `mark()` returns
  `glancing`, and combat does half damage with the note "The IB needs 3 s.f.". Only a
  value that needs rounding has one (1 is not a glancing ½), and an `exact` answer has none. An answer's `show` writes
  it as a decimal (0.35) or as money (2.50) instead of a fraction; probabilities are
  answered the way the question gives them. Typed numbers are read
  by the calculator's expression engine (`engine/expr.gd`), so 3/2, −1.5, 2(3) and 2^-1
  all work; the value must be a fraction of whole numbers (`Expr.eval_exact`), so exact
  marking stays exact, and √2 or ln 2 gets "Work that out to a number". Godot's
  `Expression` class is never used on what a student types (`test_expr.gd` checks).
- **Equivalent answers** (FAL-788): an answer with the right value is right unless the question asks
  for a form it breaks; then it is a glancing hit whose note names the rule ("Same line, but a, b and d
  must be integers."). `gline`, `common`, `brackets2`, `surd`, `pm_surd` and an exact-length `form` are
  marked by value or identity (`Answer.same_value`), with `simplest` and `integers` on the answer where
  the wording asks for them. No option marked wrong has the answer's value; one in a broken form is
  flagged `form` and is glancing when picked. `check_equivalent_options` in `tools/check_answers.py`
  checks both with SymPy. The audit of every kind is the FAL-788 document `equivalence-audit`.
- **Planner** (`engine/planner.gd`): never-seen cell, then a recently missed one, then
  exam frequency. "Exam-style only" (off by default) keeps exam cells only and follows
  exam frequency. An exam cell is an exam unknown in an exam representation of an
  exam-style type (`QuestionEngine.exam_style()`): an exam type, or an extension type
  with `examStyle`, such as AA HL counting (FAL-796). The course decides who gets it. It plans only from the cells the save's course covers (see "Courses").
- **Courses** (`engine/courses.gd`, FAL-397): the save's `course` is `aa-sl`, `aa-hl`,
  `ai-sl` or `ai-hl` (`SaveData.set_course()`, `Courses.of(save)`), and a course is a
  filter over the shared skills, not a separate game. `data/courses.json` lists the
  subtopics each course covers (written by `node tools/courses.mjs --write` from the
  `courses` on every subtopic), and a skill is in the subtopic of the first two parts of
  its id (`SL2.6.vertex` is in `SL2.6`). A cell is **covered** when every skill of its
  unknown is in the course and the method (angle) it asks by teaches a skill that is too
  (`QuestionEngine.covered()`); an unknown with no skills (prior-learning algebra) is
  covered by every course. `QuestionEngine.cells()`, `built_types()`, `probes()` and
  `angles_for()` take a course (`""` for none), and so do `Dungeon`'s floors, warm-ups,
  prior-learning steps, boss chains and link parts, `Planner`, `Progress` and the map's
  locked regions. A `Run` reads the course when it starts. AA HL covers every
  question built, and AA SL every one but the types built for AHL subtopics, which are on
  AA HL's list alone (`t1-ahl-counting`, the first). AI SL and AI HL get fewer cells,
  about three in ten of the built ones at the time of writing: a cell needs every skill it
  tests in the course, and the AI guide shares only some of AA's subtopics (`SL2.6`
  quadratics and `SL2.9` exponentials and logs are AA's alone). The rest needs AI content
  built. Changing course keeps every cell record, so progress on shared skills is not lost.
- **Rounding trap** (Q7), **a rule for every situation**: a view's builder returns
  `trap`, from `Answer.rounding_trap(answer)`. Where the answer is one number that
  needs rounding at 3 s.f., that is the number rounded to 2 s.f., and `_choices()`
  makes it one of the four options (shown as a decimal, tagged `trap`), first in line
  ahead of the misconceptions. Picking it is a glancing hit. Where it doesn't fit, it is
  `{}`. The `quadratic` views set it; every quadratic answer is exact today, so none has
  one yet. Situations whose answers are 3 s.f. measures (triangles, distributions) need
  a checker rule for the 2 s.f. text before they offer it.
- **Typed-answer rough edges** (#194): `Answer.parse_number` reads a single comma that
  can't group thousands as a decimal point (0,5, 12,25), and refuses with what to change
  where it could be either (1,500: "1.5 or 1500"), where commas group thousands, or where
  the text has a %, °, unit, currency sign or mixed number (`Answer.refusal`). A refusal
  is not marked, and `Run.answer` gives the clock back `Tuning.REFUSED_REFUND` seconds for
  each new one, up to `REFUSED_REFUND_MAX` a question; an empty box earns nothing. A
  rounded form of an `exact` answer (0.333 for 1/3, 2350 for 2345) is glancing with
  `Answer.EXACT_NOTE`, typed or picked (`Answer.rounded_exact`, an option's `rounded`).
  The normal-probability, inverse-normal and unknown-parameter views give their answer the
  values a z rounded midway (to 2 d.p. or 3 s.f.) leads to, with `Answer.add_premature`;
  typing one is a miss whose note is `Answer.PREMATURE_NOTE`. A whole-number key of
  1,000 or more takes any 3 s.f. rounding unless the answer is exact, so each type with one
  is exact or listed in `Answer.WHOLE_SF` on purpose: today a model's input or prediction,
  C from a graph, a value after n years from a calculator, and a sector area with π in
  it. Every other such key (a count, a sum, money, nCr) is exact, and the seed sweep fails
  on a key that is neither (`Answer.whole_key_unlisted`). `tools/whole_number_keys.gd`
  lists every type and unknown with such a key and how it is marked.
- **Marks**: each question carries `marks`, the type's median marks in the exam bank
  (`stats.marks.median`, copied into the catalogue as `marks`), unless the view sets its
  own. The timer is built from it. Extension types have none and use `Tuning.DEFAULT_MARKS`.
- **Save** (`engine/save_data.gd`): versioned, with a migration step per version.
  Version 2 (FAL-413): `class` is null until classes exist, `trees` and `lessons` are
  empty, `scrap` is the Scrap banked from runs and `runs` totals them. A save without
  `class` or `trees` gets them on load. Version 3 (FAL-415): `dungeon` holds each
  region's best floor and the floors whose boss fell. Version 4 (FAL-416): `bazaar`,
  what the Bazaar sold; an older save gets a blank one and keeps its Scrap to spend.
  Version 5 (FAL-397): `course`, `aa-sl` for every save made before it.

## Checking the engine

### The SymPy answer checker

`tools/check-answers` exports questions from the engine with fixed seeds (at least 50
per coverage cell and 1,000 per type), then `tools/check_answers.py` solves each one
again with SymPy from its givens. It shares no code with the engine. It checks the
answer, the clean limits, that every option but one is wrong and that all four differ,
that every worked solution ends at the answer, and that the equations shown parse to
the givens. Each situation has its own checks (`SITUATION_CHECKS`, keyed by the
`situation_id` every question exports); the answer, option and working checks are
shared. For arithmetic sequences it reads u₁, d and n back from the notation line, the
terms, the table, the words and the question text, solves them with SymPy, and checks
they give the sequence in the givens. For the four FAL-414 situations it reads the
equations, sentences and sketches back, solves the unknown (Δ in k, the meeting points,
the valid root, the solution set) and works out each tagged misconception's wrong value
itself, and every worked solution must be 2 to 5 steps. For the seven FAL-459 situations
it does the same, with SymPy, mpmath and the catalogue's own method names: an error-spot
question's first wrong line is found again from the working (each line an identity, a
solution set or a surd claim), a method-pick question's wrong methods must not work, and
a true-false-reason question's student answer must be one of the question's options.
For the FAL-418 situations it reads the model or function back from the lines, works
out every value with SymPy (an inverse is checked by composing it with the original at
several points; domains, signs and inequalities with `solveset`), checks the curves and
marked points of each graph against the function, and keeps the clean limits (`EM_*`,
`LQ_*`, `LF_*`, `PC_*`, `LG_*`), including that no 3 s.f. answer sits on a rounding edge.
For the FAL-420 situations it reads the function (or both curves, the models, the
equation) back from the question's text with SymPy, scans a fine float grid for sign
changes and refines every zero, turning point and crossing to 30 digits with mpmath,
then compares each answer and option as the game writes it, to 3 s.f. (`GC_*`, `TC_*`,
`CB_*`, `CE_*`, `GF_*`). Each tagged misconception's value is worked out again, and
each card of a pick-the-graph question is tested: the right card is the function on
its domain with every feature marked, and each wrong card is exactly its named mistake
(−f, f past the domain, f with a turning point moved onto the axis, a V at the vertex,
and so on).
For the four FAL-723 situations it reads the function, model or graph back from the question
(`calc_expr`), differentiates with SymPy and compares every option with that at three points
at 30 digits; each tagged wrong option is worked out again from its misconception, a `form`
answer's slots must make the expression it shows, and a pick-the-graph card must be its named
mistake (`dr_*`, `dm_*`, `mo_*`, `co_*`).
For the three FAL-724 situations it reads the integrand, region, rate or motion back from the
question. An indefinite integral is checked by differentiating every option, and + C counts; a
definite integral or area is worked out again with SymPy, or mpmath for a model, split at the
roots it finds itself, and each shaded strip must be the region asked for; rests and extremes are
found again from v(t), exactly on Paper 1 (`check_integration`, `check_definite_integral`,
`check_motion`).
For `trig-wave` it reads the wave back from the equation, or from a figure's marks and its curve, and
works every feature again with SymPy, testing that nothing before a first maximum is as high. Crossings
of a level are found by scanning the model for sign changes and bisecting, and durations are added up
between them, so no formula is shared with the engine; degree mode is the same scan with the angle in
degrees. The plain sums in the working are evaluated (`check_trig_wave`, `e9trig_*`).
For `arithmetic-context` it reads the story back from the words, the table, the graph's dots or the
figure's rows, then walks the sequence term by term, so no formula is shared with the engine: a term
number is found by scanning, a peak by keeping the running total, and data are fitted again. Every
statement offered is judged from those numbers, and the plain sums in the working are evaluated
(`e10ar_check`).
For `depreciation` it reads the price, rate, target and account back from the story, the model or
the table (a table's multiplier from its own values), works each value again with exact rationals, a
rate from a root and a time from a logarithm tested exactly either side of the answer, rebuilds each
tagged option from its slip, holds the figure's curve, line and crossing to the model, and requires
each method's numbers in its working (`e10de_check`).
For `sequence-proof` it reads the claim back from the words or the dots, and proves every line of a
proof with SymPy for general n, each left side held to what it means, so no value is sampled. A tagged
option must be true in a world where its slip was made and false in the real one, and a spoiled proof's
first false line must be the one it says, with the lines after it what that slip carries to
(`E11SP_check`).

For `derivative-model` it reads the model back from the line shown and differentiates it with SymPy.
Times come from a float scan for sign changes refined by bisection, a greatest rate from where the
second derivative changes sign, and a total time from the stretches between the crossings it finds.
Tables, sentences and straight-line graphs are read back and put through each rule with exact
rationals. Each tagged option is worked out from its slip, each figure's curves and tangents are held
to the model, and a derivative in the working is compared with SymPy's (`E11DM_check`).
For `derivative-graph` it holds the curve drawn (or the factors written) to the polynomial, then finds
its roots with SymPy and works each feature out again: sign changes and touches from the sign a quarter
either side of each root, turning points from where the derivative changes sign, the signed areas by
exact integration (each shaded strip held between the curve and the axis), and where f rises from f′
tested on a fine grid. For "which graph could be f?" it fits a polynomial to each card's samples and
requires the right card to be an antiderivative and each wrong card to be its named slip. Each tagged
option is rebuilt from its slip (`E12DG_check`).

For `log-exp-form` it reads a log, a power or a sentence back and tests the power that gives the number
exactly; on Paper 2 it reads each scale's constants back from its formula or its sentence, finds each
value from the logarithm to 40 digits, rebuilds each tagged option from its slip, and requires each
method's numbers in its working (`E11LF_check`).
For `constant-change` it reads the change and the statistics back from the equation, the story, the
list or the box plot (only the story's index comes from `given`), works every asked statistic again in
exact rationals from the definitions (a list's median, quartiles and mode by sorting and counting, a box
plot's from its five drawn numbers), rebuilds each tagged option from its slip and every statement
offered, and evaluates every plain sum in the working (`E12CC_check`).
For `rational-exponents` it parses the one line shown (roots, powers after a caret or in superscript,
products, quotients and sums) into SymPy with its own parser and works the value, x or the power of x
out again: a value exactly, x from SymPy's solve with x > 0, a power of x by comparing to 50 digits at
three rational points. Every option is read back and must be right exactly when it is marked right, each tagged option
is rebuilt from its slip, every equation in the working must hold, the numbers stay within the clean
limits, and the map's and the bank's own examples are refused (`E12RE_check`).
For `solve-exponential` it reads the equation back from the line, the graph's sentence or the story, turns
it into SymPy and finds its root by a scan for sign changes refined by bisection to 40 digits. The exact
answer is derived again from the equation's shape and must equal that root, and every option is evaluated
and must differ from it (an exact shift answer must be at most 12); each tagged option is rebuilt from its
slip, each figure's curves and crossing are held to the equation, and the map's own example equations are
refused (`E12SE_check`).
For `trig-sketch` it reads the function and its domain back from the line, the figure's sentence or
the table (whose five points must be a quarter of a period apart and on the wave it rebuilds), finds
turning points, zeros and asymptotes exactly with SymPy's solveset, and holds every card's curve to its
function sampled across the domain: the right card to the function, each wrong card to the curve its
slip draws, with its tag, its dots and, for tan, its asymptotes. Each typed option is rebuilt from its
slip, and Paper 2's 3 s.f. values come from mpmath (`E12TS_check`).
For `solid-angle` it reads the solid back from the sentences or the figure's measures (never the
question's `given`), checks the figure is drawn to them, puts the solid on its own axes with SymPy
integers and finds the angle again from vectors: a line and a plane from the rise over the length, two
lines from their dot product. It holds the clean limits, rebuilds each tagged option from its slip, and
evaluates every sum, named length, ratio and inverse in the working (`E12SA_check`).
For the E13 calculus extension types (FAL-776) it reads every curve and condition back from the
lines, the words or the figure's shaded strips, never the question's `given`. `polynomial-conditions`
solves the conditions for the letters with SymPy symbols, works each tagged slip from its own wrong
equations, checks every derivative and equation in the working, and judges error-spot lines one by
one (`E13PC_check`, `E13PC_spot`). `always-increasing` writes each argument again from SymPy's f′ (the
completed square, the discriminant, the term-by-term claims, the GDC's least value at 40 digits) and
fails on any option it can't say is wrong (`E13AI_check`). `hence-integral` judges every option by
differentiating or integrating it, so no wording is copied from the engine (`E13HI_check`).
`integral-gdc` integrates with mpmath and makes each slip from the integrand's shape: the negative,
every sin argument times π/180, h(inner) as h(inner − c) + c (`E13IG_check`). `area-under-curve`
integrates R again, checks f is above the axis inside it, and holds each card's shading to its
mistake (`E13AU_check`).
For `trig-model-equation` it reads the model, the wave or the two curves back from the question and
finds every crossing itself: a scan for sign changes refined by bisection, then turning points from a
scan of the slope, as a touch shows no sign change. Bands of k are rebuilt by counting at each height
and between them, and the counts in the working are compared. Degree mode is the same scan with the
angle in degrees, and the map's own example equations are refused (`e10tm_check`, `e10tm_*`).
For `prove-identity` it builds each statement from its numbers, reads every line, option and worked step
back as an expression, and proves equality by writing both in t = tan(x/2) and cancelling, after exact tests
at rational points. A wrong line must equal what its slip gives, worked out here, and a value from a ratio
comes from putting the angle itself into the first form at 40 digits (`E11PI_check`).
For `regression-interpret` it fits the data again with exact rationals and judges every statement
offered from those numbers, so a wrong statement that happens to be true fails (`e9regr_check`).
For `motion-distance` it integrates v(t) or s(t) again, exactly on Paper 1 and with mpmath on
Paper 2, summed over the stretches between rests it finds itself, so a distance is not the
engine's. A return is decided by the roots of s itself, a ridge's gap by the model's own period,
a race by solving for the winner's time, and every option of an expression is worked out and
must equal the distance only if it is the right one (`check_motion_distance`, `kd_*`).
For `geometric-context` it reads the story, table, dots or Σ back and works every value out again with
exact rationals. A least n comes from testing the terms or totals one at a time, and it must be the
first whole number past the crossing, which is at least 0.1 from a whole number. Each tagged option is
rebuilt from its slip, and the isolated power, the bound after logs, a table's two rows and each
listed row are held to the working's own lines (`e10ge_check`).
For the four FAL-725 situations it reads the facts back from the question: lines, percentages,
sentences, a Venn diagram, a tree or a table. It finds the regions, ratios and lines again with
exact rationals, and z and tail areas with mpmath at 40 digits. A σ or μ is checked by putting it
back into erf, and a shaded area must be the area given (`check_regression_pair`,
`check_normal_unknown`, `check_venn`, `check_conditional`).
For `inverse-normal` it reads μ, σ, the area and its side back from the lines, the story or the shading,
and finds each value with its own inverse (erfinv at 40 digits, put back through erfc), or exactly on
Paper 1, solving the shift with SymPy. Each tagged option is worked out from its slip, and each
invNorm, normalcdf and plain sum in the working is done again (`e10in_check`).
For `antiderivative-condition` it reads f′ (or f″) and the condition back from the lines, works
the antiderivative again with SymPy, and differentiates every option: only the right one may give
f′ back, meet the condition and have no C left in it (`check_antiderivative_condition`). Each
tagged wrong option is worked out from its slip. A family's curves are held to F + C and their
labels to the options, the corners of a graph of f′ give the areas again, the rate model is
integrated both exactly and numerically, and the sums in the working are evaluated.

For `grouped-data` it reads the table, list or groups back, works the frequencies, Σfx and the spread
again exactly, and solves for each missing value (`check_grouped_data`). For `binomial-unknown` it
reads the bracket and the condition, builds the expansion with SymPy and solves for the letter, so
every other option must fail (`check_binomial_unknown`). For `normal-properties` it reads the curve
or the given areas back and finds each area with mpmath (`check_normal_properties`). For `box-plot`
it reads the five numbers off the figure or the data, and applies the 1.5 × IQR rule itself
(`check_box_plot`).
For `area-between` it reads the two curves back from the lines, or fits them to a diagram's marked
points, and finds the meeting points, the top curve and every piece again: exactly with SymPy on
Paper 1, and with its own root search and mpmath on Paper 2. Each option of an integral expression
is integrated, each tagged slip is worked out from its misconception, each figure's curves and
strips must be the question's, and the plain sums in the working are evaluated (`check_area_between`).
For `distance-midpoint` it reads the points back from the sentences, the position vectors or the
figure's labels, works each length and midpoint again, solves for k with SymPy, rebuilds each tagged
option from its slip, and evaluates the sums in the working (`check_distance_midpoint`).
For `independence` it reads the facts back the same way and decides each test itself. Each of the
four comparisons must agree, and all four option texts are rebuilt from true values, so a false
number or a verdict that doesn't follow fails. It also multiplies and divides every plain step of
the working again (`check_independence`).
For `sample-space` it reads the two objects back from the grid's heads, the figure or the sentences,
holds every cell to the scoring rule, and lists every outcome again. A biased object's cells are
multiplied out, a letter on a face is found by trying every value it could have against the
distribution, q and r are solved with SymPy from P(X < Y), and each tagged slip is worked out. The
working's lists and counts must be the checker's own, and its plain sums are evaluated (`e10ss_check`).
For `basic-probability` it reads the story, table, bar chart, tree or curve back, counts the outcomes
again by listing every one, and checks that a curve is real counts settling on its answer
(`check_basic_probability`).
For `tree-diagram` it reads the tree off the figure, or the tin, crates, tries, groups or game off
the words. Every fork must add to 1 and every branch of a tin's tree must be the recount. Paths are
found again exactly, normal areas with mpmath, a game by listing every game, and a growing tin by
walking its selections. Each plain sum and product in the working is evaluated (`check_tree_diagram`).
For `sampling` it runs the checklist on the surveyor's sentence (a fixed interval, groups filled,
a random draw) to find the technique, and holds each wrong disadvantage to being false of it. For
`cumulative-frequency` it reads every value off the curve in the figure, which must rise strictly
and meet the reading on a corner of the grid the scale line describes; a table's estimates come from
its written rows, and a pick-the-graph card must hold the points its mistake says
(`check_sampling`, `check_cumulative_frequency`).
For `optimisation-model` it reads the shape back from the words or the figure, or the function from
its line, solves F′ = 0 with SymPy and takes the root in the domain, or finds a route's turning point
with mpmath, and works each tagged wrong option out from its slip (`check_optimisation`).
For the two FAL-726 situations it reads r, θ, the arc, the area, bearings and lengths back from
the lines or the figure, and works each answer out from those, exactly with a + bπ on Paper 1, or
at 40 digits. A sector must be drawn to the question's angle, and each length and bearing on a
sketch must match the points drawn, to one scale. The working's arithmetic is checked from the
figures shown (`check_arc_sector`, `check_bearings`).
For the two FAL-726 situations it reads the measures back from a sketch's labels or the sentences,
and the numbers back from the text, and finds each answer again with exact rationals and π, a
composite's r from the roots of its cubic at 40 digits. Each number a × 10^k is normalised again
without leaving exact numbers. Every step of the working that is plain numbers is evaluated, and
its sides must agree to the figures shown (`check_solid`, `check_standard_form`).
Each cell also gets 10 questions made on its family's shared situation, and 20 in each
extra format it offers (`--per-format`). Every mini-boss and boss chain is exported too
(`--per-chain`, 50 seeds), each part as a question checked like the rest, and then as a
chain: one situation, and each part's `carried` value is the part before's answer. It
prints a table per type and per cell. SymPy is pinned in
`requirements.txt` and installed into a gitignored `.venv/` on first run. CI runs it in
six `answers-shard` jobs (`--shard=k/6`: every sixth cell and boss chain, each with all
its questions). Each leaves a `summary.json`, and the `answers` job merges them
(`tools/check-answers --merge dir`) and fails unless every shard is there once, passed,
and together they give every cell 50 questions and every type 1,000.

### The seed sweep

`tools/feedback-check` takes every wrong option with a misconception tag and fails if
its "Watch out" text shows a number the question doesn't, states the false belief as if it
were true (each string opens by naming the slip: "Assuming ...", "Using ..."), or has no
text. It also fails on an absurdly large option. So strings carry no numbers of their own:
one string serves every question with that tag. Whether a tag fits its option has to be
read: `--rows=file.tsv` writes one row per type, unknown, representation and tag. A new type
is enforced from its first commit, and `REPORT_ONLY` is empty.

Every wrong option is a slip or a filler (FAL-815). A slip is a route students take: it
gets a misconception, its line and a tag, and the checker works it out again. A filler has
no route to it (the key scaled by a quarter, nudged, a number from nowhere), and the view
puts it in `fillers`, so a blank is a choice. The check fails on a blank that is neither:
a `wrongs` entry with no `ref`, or an option from `generic`, the list from before FAL-815
that mixed the two. A type whose `generic` isn't sorted yet is on `UNSORTED` in
`tools/feedback_check.gd`, where its blanks are only counted; once sorted, its views say
`fillers` and it leaves the list, and the check fails on a listed type with nothing left to
sort. A new type never joins it. A rounding trap with no misconception of its own shows
`Answer.TRAP_NOTE`, and the engine's last-resort nudges are fillers. The check prints the
share of multiple-choice wrong options with no line (`BLANK ...`), and `--blanks=file.tsv`
writes each blank once, with where it came from (`src`, `gi`) and a first example.

The checker only exports seeds 1 to 50. `tools/stress-questions` makes every cell with
seeds 51 to 2250 (about 258,000 questions, a few minutes) and checks that each question
is made with four options (every fourth seed also on its family's shared situation, and
in each extra format the cell offers), that its own answer typed exactly and to 3 s.f. is marked
right, and that every wrong option typed in is marked wrong with its misconception. It
does the same for every boss chain with seeds 51 to 1050, and checks each part's carried
value. It fails on any script error, such as a failed assert in `Q`. CI runs it as its
own `stress` job. `--types=id,id` sweeps only those types. An exact answer (an exact k,
−(ln 2)/3) is only right exactly, so its 3 s.f. decimal is checked only where that
decimal is the exact value, and a wrong option that can't be typed (`Answer.typable`) is
not typed in.

### The course audit

`tools/course-audit` shows where the engine stands for each IB course, so the order of
the rollout comes from numbers (FAL-695). `tools/course_report.gd` exports what the
engine can ask each course (`Courses`), and `tools/course-audit.mjs` joins that with the
curriculum maps and `curriculum/question-types.json`. It prints, and keeps in
`_scratch/course-audit/report.md` (nothing tracked, since the numbers move with every
type that lands):

- per course and topic: the skills the course has, the skills a type in the catalogue
  lists (**catalogued**) and the skills a built question tests (**playable**);
- the subtopics no type lists at all, which is every AA HL-only and AI-only subtopic so
  far: their types have to be designed before a generator can be built;
- the catalogued types not built yet, ranked by the skills they would make playable in
  each course.

`tests/unit/course-audit.test.mjs` runs the second half on a faked report.
