extends "res://tests/test_case.gd"
## The reading pass on fn-transform-describe and fn-concept-transform-order (transform-chain),
## FAL-1605 / GitHub #193: each test pins one fixed finding, over seeds 1..30 and every cell
## of the unknown it is about.

const TD := "fn-transform-describe"
const TO := "fn-concept-transform-order"
const SEEDS := 30


func _cells(type: String, unknown: String) -> Array:
	return QuestionEngine.cells(false, [type]).filter(func(c): return c.unknown == unknown)


## Every question of an unknown, for each cell, seed and paper the cell has.
func _each(type: String, unknown: String, format: String = "mcq") -> Array:
	var out: Array = []
	for c in _cells(type, unknown):
		for paper in [1, 2]:
			for seed in range(1, SEEDS + 1):
				var q := QuestionEngine.make({"type": type, "unknown": unknown, "rep": c.rep, "angle": c.angle, "seed": seed,
					"format": format, "paper": paper})
				check(not q.has("error"), "%s seed %d: %s" % [c.key, seed, q.get("error", "")])
				if q.has("error"):
					break
				if paper == 2 and q.paper != 2:
					break
				out.append(q)
	return out


func _label(q: Dictionary) -> String:
	return "%s seed %d" % [q.cell, q.view.seed]


func _steps(sol: Dictionary) -> Array:
	return sol.steps.map(func(st): return Step.text(st))


func _all_steps(q: Dictionary) -> String:
	var out: Array = []
	for sol in q.solutions:
		out.append_array(_steps(sol))
	return "\n".join(PackedStringArray(out))


func _no_equal_options(q: Dictionary) -> void:
	var seen := {}
	for o in q.choices:
		check(not seen.has(o.text), "%s: two options read %s" % [_label(q), o.text])
		seen[o.text] = true
	check_eq(q.choices.filter(func(o): return o.correct).size(), 1, _label(q) + ": one correct option")


# ── fn-concept-transform-order ───────────────────────────────

## inside-opposite: "Move key points by the vector" was named on f(½x), and the scale rule's
## working on f(x − 1) was the translation's. Each method now only works its own move, and
## every cell builds a question with the method it names.
func test_inside_opposite_methods_fit_the_move() -> void:
	for q in _each(TO, "inside-opposite"):
		var stretch: bool = q.answer_text.begins_with("a horizontal stretch")
		for sol in q.solutions:
			check(sol.angle == ("scale-rule" if stretch else "track-points"), "%s: %s worked on %s" % [_label(q), sol.angle, q.answer_text])
		check_eq(q.solutions[0].angle, q.view.angle, _label(q) + ": the named method comes first")


## inside-opposite: f(x + 3) offered "up 3: the number is taken away" and "down 3: the number
## is added". Reading the inside change as outside follows the sign it is written with.
func test_inside_opposite_vertical_slip_follows_the_sign() -> void:
	var named := 0
	for q in _each(TO, "inside-opposite"):
		_no_equal_options(q)
		for o in q.choices:
			var t: String = o.text
			check(not (t.begins_with("up ") and t.ends_with("taken away")) and not (t.begins_with("down ") and t.ends_with("is added")), "%s: %s" % [_label(q), t])
			if o.ref == TO + "#5" and (t.begins_with("up ") or t.begins_with("down ")):
				named += 1
	check(named >= 20, "only %d translations carry the inside-as-outside slip" % named)


## inside-vs-outside: the scale rule was the method for f(x + 3) and f(x) + 3, and two
## fillers ("both move it along the x-axis") were the "same graph" option said again.
func test_inside_vs_outside_options_are_different_claims() -> void:
	var slips := 0
	for q in _each(TO, "inside-vs-outside"):
		_no_equal_options(q)
		for sol in q.solutions:
			if sol.angle == "scale-rule":
				check(not _steps(sol).any(func(t): return "moves it along" in t), "%s: the scale rule works a translation" % _label(q))
		if q.rep != "equation":
			continue
		for o in q.choices:
			var halves: PackedStringArray = o.text.split("; ")
			if halves.size() == 2:
				check(not ("x-axis" in halves[0] and "x-axis" in halves[1]) and not ("y-axis" in halves[0] and "y-axis" in halves[1]), "%s: %s" % [_label(q), o.text])
			if o.ref in ["SL2.11.describe#0", "SL2.11.stretch#0"]:
				slips += 1
	check(slips >= 20, "only %d questions offer the inside change read as written" % slips)


## inside-vs-outside graph: the curves are told apart from one point of f the question names,
## and the working finds where it lands on each.
func test_inside_vs_outside_graph_names_the_point() -> void:
	for q in _each(TO, "inside-vs-outside"):
		if q.rep != "graph":
			continue
		check(q.lines.any(func(l): return "on y = f(x) goes" in l), _label(q) + ": no point of f is named")
		for sol in q.solutions:
			check(_steps(sol).any(func(t): return t.begins_with("A is at ")), "%s: %s doesn't say where A is" % [_label(q), sol.angle])


## order-from-bracket: read as stretches then a translation, a(f(x) + d) is af(x) + ad, a
## stretch then a translation by ad, so that method never names a translation-first key.
func test_order_from_bracket_form_method_needs_a_stretch_first() -> void:
	for q in _each(TO, "order-from-bracket"):
		for sol in q.solutions:
			if sol.angle == "stretch-then-translate-form":
				check(q.answer_text.begins_with("a horizontal stretch"), "%s: the form method on %s" % [_label(q), q.answer_text])
		var said := _all_steps(q)
		check(not ("Each part now reads as one move." in said) and not ("That is a" in said), _label(q) + ": a step only states the answer")


## two-orders: with a horizontal pair, the "translation the wrong way" filler turned only D,
## which is 0, so it read as the key or as "the order never matters" again.
func test_two_orders_fillers_are_not_the_key_again() -> void:
	for f in ["mcq", "true-false-reason"]:
		for q in _each(TO, "two-orders", f):
			_no_equal_options(q)
			for o in q.choices:
				var m := RegEx.create_from_string("stretch first, g\\(x\\) = (.+) and .+; translation first, g\\(x\\) = (.+) and it goes").search(o.text)
				if m != null:
					check(m.get_string(1) != m.get_string(2), "%s: both orders give one g in %s" % [_label(q), o.text])


## two-orders and point-both-orders: the working found each order's rule and point instead of
## stating them; each now builds them a move at a time.
func test_order_workings_go_a_move_at_a_time() -> void:
	for u in ["two-orders", "point-both-orders"]:
		for q in _each(TO, u):
			for sol in q.solutions:
				var said := "\n".join(PackedStringArray(_steps(sol)))
				if sol.angle == "track-a-point":
					check("→" in said, "%s: %s gives no point's path" % [_label(q), sol.angle])
				else:
					check(" then " in said, "%s: %s doesn't build each order" % [_label(q), sol.angle])


## which-pairs-commute and undo-in-reverse: the working tries a pair both ways, and takes a
## point back a move at a time, rather than only saying the rule.
func test_pairs_and_reverse_are_tried_not_told() -> void:
	for q in _each(TO, "which-pairs-commute"):
		check("the other way round gives" in _all_steps(q), _label(q))
	for q in _each(TO, "undo-in-reverse"):
		check("The moves back take it one move at a time" in _all_steps(q), _label(q))


# ── fn-transform-describe ────────────────────────────────────

## describe-stretch on 1/x or a log: the filler was 2 × the factor, "scale factor 1" for ½.
func test_describe_stretch_never_offers_a_stretch_by_1() -> void:
	for q in _each(TD, "describe-stretch"):
		_no_equal_options(q)
		for o in q.choices:
			check(not o.text.ends_with("scale factor 1"), "%s: %s" % [_label(q), o.text])


## vector-from-key-point: from (0, 0) the moved point is the vector, so the "moved point"
## slip (fn-transform-describe#16) was the key and a key ± 1 nudge took its place.
func test_vector_from_key_point_offers_the_moved_point() -> void:
	for q in _each(TD, "vector-from-key-point"):
		_no_equal_options(q)
		check(q.choices.any(func(o): return o.ref == TD + "#16"), _label(q) + ": no moved-point slip")
		var kx: Q = Q.of(q.answer.values.x)
		var ky: Q = Q.of(q.answer.values.y)
		for o in q.choices:
			var dx := Q.of(o.values.x).sub(kx).abs_q()
			var dy := Q.of(o.values.y).sub(ky).abs_q()
			# One part's sign turned round is a filler, 1 away only when that part is ±0.5.
			var flipped: bool = Q.of(o.values.x).eq(kx.neg()) or Q.of(o.values.y).eq(ky.neg())
			check(flipped or not ((dx.eq(1) and dy.is_zero()) or (dy.eq(1) and dx.is_zero())), "%s: %s nudges the key" % [_label(q), o.text])


## relate-two-models: "q(t) = 1 sin(5t) + 5", and a words view's working used sin(5t) and
## a period the question never gave.
func test_relate_two_models_reads_its_waves() -> void:
	for q in _each(TD, "relate-two-models"):
		var said := "\n".join(PackedStringArray(q.lines)) + "\n" + _all_steps(q)
		check(not (" 1 sin" in said) and not ("= 1 sin" in said), _label(q) + ": 1 sin")
		if q.rep == "words":
			check(not ("sin(" in _all_steps(q)), _label(q) + ": the working writes a rule the words don't give")


## stretch-and-shift-parameters on (x − u)² + v: g read "((1/3)x − 2)² − 2 − 2".
func test_a_vertex_parabola_has_one_constant() -> void:
	var two := RegEx.create_from_string("\\)² [+−] [0-9/.]+ [+−] [0-9/.]+$")
	for q in _each(TD, "stretch-and-shift-parameters"):
		for l in q.lines:
			check(two.search(l) == null, "%s: %s" % [_label(q), l])


## describe-from-graphs: "the ratio of those changes gives the stretch, and what is left over
## is the translation" left both moves unfound. The working now divides and subtracts.
func test_describe_from_graphs_finds_both_moves() -> void:
	for q in _each(TD, "describe-from-graphs"):
		for sol in q.solutions:
			var said := "\n".join(PackedStringArray(_steps(sol)))
			check("÷" in said and "so the translation is by the vector" in said, "%s: %s" % [_label(q), sol.angle])


## A graph view gives no rule for g, but the rewrite worked from "Written with f, g(x) = …";
## it now reads g off P and Q first. The GDC on a graph is given f's rule.
func test_graph_views_read_g_from_the_points() -> void:
	for u in ["describe-translation", "describe-stretch", "describe-with-reflection", "stretch-and-shift-parameters"]:
		for q in _each(TD, u):
			if q.rep != "graph":
				continue
			for sol in q.solutions:
				var said: Array = _steps(sol)
				check(not said.any(func(t): return t.begins_with("Written with f")), "%s: %s uses a rule the graph doesn't give" % [_label(q), sol.angle])
			if u == "describe-translation":
				check(q.lines.any(func(l): return l.begins_with("f(x) = ")), _label(q) + ": the GDC has no rule for f")


## describe-with-reflection named only the reflection in its working; describe-after-
## completing-square stated d; the substitute method's letters didn't match its name (a, b).
func test_describe_workings_find_each_part() -> void:
	for q in _each(TD, "describe-with-reflection"):
		check("Then " in _all_steps(q), _label(q) + ": the second move isn't read")
		check(not ("graphs: The" in _all_steps(q)), _label(q) + ": a capital mid-sentence")
	for q in _each(TD, "describe-after-completing-square"):
		check("a² + b = " in _all_steps(q), _label(q) + ": b is stated, not found")
	for q in _each(TD, "describe-translation"):
		var said := _all_steps(q)
		check(not ("across: The" in said), _label(q) + ": a capital mid-sentence")
		for sol in q.solutions:
			if sol.angle == "substitute":
				check("x − a" in "\n".join(PackedStringArray(_steps(sol))), _label(q) + ": the substitute working doesn't use a and b")
