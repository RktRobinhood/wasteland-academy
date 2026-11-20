extends "res://tests/test_case.gd"
## The reading pass on fn-graph-table-composite-inverse (FAL-1055, GitHub #193): no reading
## gives back its own input or a named slip as the answer, the wrong options are slips or
## other readings rather than the key nudged by one, and every worked step reads from what
## the question shows, in the method's own words.

const T := "fn-graph-table-composite-inverse"
const SEEDS := 30
const R_VALUE_NOT_INVERSE := "SL2.2.inverse-undo#2"
const READINGS := ["read-graph-table", "vertical-read", "chain-readings"]


func _make(unknown: String, rep: String, angle: String, seed: int, format: String = "mcq") -> Dictionary:
	return QuestionEngine.make({"type": T, "unknown": unknown, "rep": rep, "angle": angle, "seed": seed, "format": format})


## Every question of an unknown, over every cell, seeds 1 … SEEDS and the formats.
func _each(unknown: String, formats: Array = ["mcq", "value"]) -> Array:
	var out: Array = []
	var cells: Array = QuestionEngine.cells(false, [T]).filter(func(c): return c.unknown == unknown)
	check(not cells.is_empty(), "%s has no cells" % unknown)
	for c in cells:
		for seed in range(1, SEEDS + 1):
			for f in formats:
				var q := _make(unknown, c.rep, c.angle, seed, f)
				check(not q.has("error"), "%s seed %d: %s" % [c.key, seed, q.get("error")])
				if not q.has("error"):
					out.append(q)
	return out


## Fails once for a list of bad cases, with the count and the first few.
func _none(bad: Array, what: String) -> void:
	check(bad.is_empty(), "%d %s, e.g. %s" % [bad.size(), what, " | ".join(bad.slice(0, 3))])


static func _name(q: Dictionary) -> String:
	return "%s seed %d %s" % [q.cell, q.view.seed, q.format]


## The whole numbers in a text, "−3" read as −3.
static func _nums(text: String) -> Array:
	var re := RegEx.create_from_string("−?\\d+")
	return re.search_all(text).map(func(m): return m.get_string().replace("−", "-").to_int())


## f (or g) at x, from the question's givens: the rule where there is one, else the points.
static func _at(q: Dictionary, x: Variant, name: String = "f") -> Variant:
	if x == null:
		return null
	var g: Dictionary = q.given
	if name == "f" and g.has("co"):
		var co: Array = g.co.map(func(c): return str(c).to_int())
		return co[0] + co[1] * x + co[2] * x * x
	var i: int = g.xs.find(x)
	return null if i < 0 else (g.fy if name == "f" else g.gy)[i]


## The input where f (or g) takes the value y, or null.
static func _where(q: Dictionary, y: int, name: String = "f") -> Variant:
	var ys: Array = q.given.fy if name == "f" else q.given.gy
	var i := ys.find(y)
	return null if i < 0 else q.given.xs[i]


static func _key(q: Dictionary) -> int:
	return int(q.answer.values.v.n)


static func _steps(sol: Dictionary) -> String:
	return " || ".join(Step.texts(sol.steps))


# ── Readings that give themselves away (check 7) ─────────────

## (f∘f)(a) never comes back to a (a 2-cycle), to f(a) or to f(a)², and f(a) is not a
## itself, so neither the input nor a named slip is the key.
func test_a_self_composite_is_not_a_fixed_point_or_a_cycle() -> void:
	var bad: Array = []
	for q in _each("self-composite-read"):
		var a: int = _nums(q.asked)[0]
		var mid: int = _at(q, a)
		var v: int = _at(q, mid)
		if _key(q) != v or mid == a or v == a or v == mid or v == mid * mid:
			bad.append("%s: f(%d) = %d, f(%d) = %d" % [_name(q), a, mid, mid, v])
	_none(bad, "self-composites give back the input or a slip")


## A rule shown beside a graph or table is read at shown inputs only: f(a) is one of them.
func test_a_self_composite_from_a_rule_reads_on_the_grid() -> void:
	var bad: Array = []
	for q in _each("self-composite-read"):
		if q.given.mode != "rule" or (q.graph == null and q.table == null):
			continue
		var mid: int = _at(q, _nums(q.asked)[0])
		if not mid in q.given.xs:
			bad.append("%s: f(a) = %d is off the grid" % [_name(q), mid])
	_none(bad, "rule readings off the grid")


## Composites, inverse values, mixed composites and missing entries: the key is not the
## asked input, the inner value, or f(b) for f⁻¹(b).
func test_two_step_readings_do_not_give_the_input_or_the_inner_value() -> void:
	var bad: Array = []
	for q in _each("composite-from-table"):
		var a: int = _nums(q.asked)[0]
		var fg: bool = q.asked.begins_with("Find (f∘g)")
		var mid = _at(q, a, "g" if fg else "f")
		var v = _at(q, mid, "f" if fg else "g")
		if v == a or v == mid:
			bad.append("%s: %s, inner %s, answer %s" % [_name(q), q.asked, mid, v])
	for q in _each("inverse-value-read"):
		var b: int = _nums(q.asked.replace("f⁻¹", "f"))[0]
		var a := _key(q)
		if a == b or _at(q, b) == a:
			bad.append("%s: %s = %d" % [_name(q), q.asked, a])
	for q in _each("mixed-inverse-composite"):
		var b: int = _nums(q.asked.replace("g⁻¹", "g"))[0]
		var a = _where(q, b, "g")
		if _key(q) == b or _key(q) == a:
			bad.append("%s: %s = %d" % [_name(q), q.asked, _key(q)])
	for q in _each("missing-entry"):
		var a: int = _nums(q.asked)[0]
		var ga := _key(q)
		if ga == a or _at(q, ga) == ga:
			bad.append("%s: g(%d) = %d" % [_name(q), a, ga])
	_none(bad, "readings give back the input or the inner value")


# ── Wrong options (check 7) ──────────────────────────────────

## Every wrong option is a slip or a filler the views give: none is the engine's nudge.
func test_no_wrong_option_is_a_nudge() -> void:
	var bad: Array = []
	var units := {}
	for c in QuestionEngine.cells(false, [T]):
		units[c.unknown] = true
	for u in units:
		for q in _each(u, ["mcq"]):
			for o in q.choices:
				if o.get("src", "") == "nudge":
					bad.append("%s: %s (answer %s)" % [_name(q), o.text, q.answer_text])
	_none(bad, "nudged options")


## No single-number question has three unnamed wrong options all within 2 of the key.
func test_unnamed_options_do_not_crowd_the_key() -> void:
	var bad: Array = []
	for c in QuestionEngine.cells(false, [T]):
		for seed in range(1, SEEDS + 1):
			var q := _make(c.unknown, c.rep, c.angle, seed)
			if q.has("error") or not q.answer.values.has("v") or not (q.answer.values.v is Q) or q.answer.values.size() != 1:
				continue
			var key: float = q.answer.values.v.to_float()
			var near: Array = q.choices.filter(func(o): return not o.correct and o.ref == "" and absf(Q.of(o.values.v).to_float() - key) <= 2.0)
			if near.size() == 3:
				bad.append("%s: %s" % [_name(q), q.choices.map(func(o): return o.text)])
	_none(bad, "questions whose wrong options are all fillers next to the key")


## A sentence lists the asked value's own entry where it is an input, so its slip (f(b) for
## f⁻¹(b), f(k) for solving f(x) = k) is offered from a sentence too.
func test_a_sentence_offers_the_named_slip() -> void:
	var bad: Array = []
	var named := 0
	for u in ["inverse-value-read", "solve-from-table"]:
		for q in _each(u, ["mcq"]):
			if q.rep != "words":
				continue
			var t: int = _nums(q.asked.replace("f⁻¹", "f").replace("f(x)", ""))[0]
			var slip = _at(q, t)
			if slip == null or t == _key(q) or slip == _key(q):
				continue
			var listed: bool = ("f(%s) = " % Fmt.num(t)) in q.lines[0]
			var offered: bool = q.choices.any(func(o): return o.ref != "")
			named += 1 if offered else 0
			if not listed or not offered:
				bad.append("%s: %s, %s" % [_name(q), q.asked, q.lines[0]])
	_none(bad, "sentences without the asked value's slip")
	check(named > 0, "no sentence offers a named slip")


## The domain and range of f⁻¹ and the points of f⁻¹ have slips for wrong options, not
## one end moved by one.
func test_inverse_domain_range_and_points_have_slip_options() -> void:
	var bad: Array = []
	for u in ["inverse-domain-read", "inverse-range-read", "inverse-points"]:
		for q in _each(u, ["mcq"]):
			if q.choices.filter(func(o): return not o.correct and o.get("src", "") in ["wrongs", "fillers"]).size() != 3:
				bad.append("%s: %s" % [_name(q), q.choices.map(func(o): return "%s [%s]" % [o.text, o.get("src", "")])])
	_none(bad, "inverse domain, range or points questions short of slip options")


## The roots of f(x) = k: no option is the key with one root moved by one.
func test_count_solutions_moves_no_root_by_one() -> void:
	var bad: Array = []
	for q in _each("count-solutions", ["mcq"]):
		var key: Array = _nums(q.answer_text)
		for o in q.choices:
			var xs: Array = _nums(o.text)
			if o.correct or xs.size() != 2:
				continue
			for i in 2:
				for j in 2:
					if xs[i] == key[j] and absi(xs[1 - i] - key[1 - j]) == 1:
						bad.append("%s: %s for %s" % [_name(q), o.text, q.answer_text])
	_none(bad, "count-solutions options with a root moved by one")


## why-no-inverse: a near miss names one-to-one too, and no wrong reason is half right.
func test_why_no_inverse_has_a_near_miss_and_no_half_right_reason() -> void:
	var bad: Array = []
	for q in _each("why-no-inverse", ["mcq"]):
		var texts: Array = q.choices.map(func(o): return o.text)
		if texts.filter(func(t): return "one-to-one" in t).size() < 2 or texts.any(func(t): return "maximum" in t or "minimum" in t):
			bad.append("%s: %s" % [_name(q), texts])
	_none(bad, "why-no-inverse questions with one one-to-one option or a half-right reason")


## (f∘g⁻¹)(b): the inverse-undo#2 slip is f(g(b)), g used for g⁻¹; never f(b) alone.
func test_mixed_composite_tags_g_for_g_inverse_only() -> void:
	var bad: Array = []
	for q in _each("mixed-inverse-composite"):
		var b: int = _nums(q.asked.replace("g⁻¹", "g"))[0]
		var gb = _at(q, b, "g")
		var want = _at(q, gb) if gb != null and gb in q.given.xs else null
		for o in q.choices:
			if o.ref == R_VALUE_NOT_INVERSE and (want == null or Q.of(o.values.v).to_float() != float(want)):
				bad.append("%s: %s tagged %s, f(g(b)) %s" % [_name(q), o.text, o.ref, want])
	_none(bad, "mixed composites tag f(b) as g used for g⁻¹")


# ── Worked steps (check 2) ───────────────────────────────────

## A method that reads a graph or table has one shown (a sentence is read as a sentence); a
## step that names the graph or the table has it there; substitution has a rule; and
## build-then-substitute builds f(f(x)), under a name with no g.
func test_every_method_works_from_what_is_shown() -> void:
	var bad: Array = []
	for u in ["read-value", "value-from-rule", "self-composite-read"]:
		for q in _each(u, ["mcq"]):
			var rule: bool = not q.lines.is_empty() and str(q.lines[0]).begins_with("f(x) = ")
			for sol in q.solutions:
				var text := _steps(sol)
				var why := ""
				if sol.angle in READINGS and q.graph == null and q.table == null and q.rep != "words":
					why = "reads with no graph or table"
				elif q.rep == "words" and ("graph" in sol.name or "Up from" in sol.name):
					why = "named for a graph or table"
				elif ("graph" in text or "curve" in text) and q.graph == null:
					why = "reads a graph that isn't shown"
				elif "table" in text and q.table == null:
					why = "reads a table that isn't shown"
				elif sol.angle in ["direct-substitution", "build-then-substitute"] and not rule:
					why = "substitutes with no rule"
				elif sol.angle == "build-then-substitute" and (not "f(f(x)) = " in text or "g(x)" in sol.name):
					why = "never builds f(f(x)), or is named for a g"
				elif sol.angle == "vertical-read" and q.graph == null and sol.name == "Up from x, across to y":
					why = "named for a graph"
				if why != "":
					bad.append("%s (%s): %s: %s" % [_name(q), sol.angle, why, text])
	_none(bad, "worked solutions that don't fit what is shown")


## "Go up" to a point above the x-axis, "Go down" to one below.
func test_a_vertical_reading_goes_up_or_down_by_the_sign() -> void:
	var bad: Array = []
	var re := RegEx.create_from_string("Go (up|down) from x = (−?\\d+)")
	for u in ["read-value", "self-composite-read", "value-from-rule"]:
		for q in _each(u, ["mcq"]):
			for sol in q.solutions:
				for m in re.search_all(_steps(sol)):
					var y: int = _at(q, m.get_string(2).replace("−", "-").to_int())
					if (m.get_string(1) == "up") != (y > 0) or y == 0:
						bad.append("%s: %s, and f there is %d" % [_name(q), m.get_string(), y])
	_none(bad, "vertical readings the wrong way")


## Off a graph, "Draw y = k" and "read down to the x-axis" have nothing to draw on.
func test_a_horizontal_reading_off_a_graph_reads_the_values() -> void:
	var bad: Array = []
	for u in ["inverse-value-read", "solve-from-table"]:
		for q in _each(u, ["mcq"]):
			if q.rep == "graph" or q.view.angle != "horizontal-line":
				continue
			var sol: Dictionary = q.solutions[0]
			if "x-axis" in _steps(sol) or "graph" in _steps(sol) or sol.name.begins_with("Draw y = k") or "Draw y = k" in q.prompt:
				bad.append("%s: %s: %s" % [_name(q), sol.name, _steps(sol)])
	_none(bad, "horizontal readings off a graph")


## f(a) = b puts (a, b) on f and (b, a) on f⁻¹.
func test_swapping_puts_the_swapped_point_on_the_inverse() -> void:
	var bad: Array = []
	for q in _each("inverse-value-read", ["mcq"]):
		var b: int = _nums(q.asked.replace("f⁻¹", "f"))[0]
		var a := _key(q)
		for sol in q.solutions:
			if sol.angle != "swap-coordinates":
				continue
			var want := "(%s, %s) is on f and (%s, %s) is on f⁻¹" % [Fmt.num(a), Fmt.num(b), Fmt.num(b), Fmt.num(a)]
			if not want in _steps(sol):
				bad.append("%s: %s" % [_name(q), _steps(sol)])
	_none(bad, "swap steps that put f's point on f⁻¹")


## The restricted domain starts where the graph does.
func test_the_restricted_domain_starts_at_the_graphs_left_end() -> void:
	var bad: Array = []
	for q in _each("restrict-from-graph", ["mcq"]):
		var lo := Fmt.num(q.given.xs.min())
		if not ("on the domain %s ≤ x ≤ k" % lo) in q.asked:
			bad.append("%s: %s" % [_name(q), q.asked])
	_none(bad, "restrictions without the left end")


## The images of A and B are listed A′ then B′, and neither A nor B is on y = x.
func test_the_inverse_points_come_in_a_then_b_order() -> void:
	var bad: Array = []
	var re := RegEx.create_from_string("^([AB]) \\((−?\\d+), (−?\\d+)\\)$")
	for q in _each("inverse-points", ["mcq"]):
		var pts := {}
		for p in q.graph.points:
			var m := re.search(str(p.label))
			if m:
				pts[m.get_string(1)] = [m.get_string(2), m.get_string(3)]
		if pts.size() != 2:
			bad.append("%s: labels %s" % [_name(q), pts])
			continue
		var want := "(%s, %s) and (%s, %s)" % [pts.A[1], pts.A[0], pts.B[1], pts.B[0]]
		if q.answer_text != want or pts.A[0] == pts.A[1] or pts.B[0] == pts.B[1]:
			bad.append("%s: A %s, B %s, answer %s" % [_name(q), pts.A, pts.B, q.answer_text])
	_none(bad, "inverse points out of order or on y = x")


## A method left off a question's tabs (no graph, table or rule for it) still has working of
## its own, and "Another way" asks it with its own working or not at all (test_engine's
## check, over seeds).
func test_a_method_without_a_tab_has_working_of_its_own() -> void:
	var bad: Array = []
	var t := QuestionEngine.type_of(T)
	for c in QuestionEngine.cells(false, [T]):
		for seed in range(1, 11):
			var q := _make(c.unknown, c.rep, c.angle, seed)
			var have: Array = q.solutions.map(func(sol): return sol.angle)
			for a in QuestionEngine.angles_for(t, c.unknown):
				if a in have:
					continue
				var again := QuestionEngine.make({"type": T, "unknown": c.unknown, "rep": c.rep, "angle": a, "same_angle": c.angle, "seed": seed})
				var own := _make(c.unknown, c.rep, a, seed)
				if not (again.has("error") or again.solutions[0].angle == a) or own.has("error") or own.solutions[0].angle != a:
					bad.append("%s seed %d: %s" % [c.key, seed, a])
	_none(bad, "methods with no working")
