extends "res://tests/test_case.gd"
## Reading pass fixes for the exp-model and log-laws situations (FAL-1055, GitHub #193):
## fn-exponential-model and t1-log-laws. Each test loops over seeds 1..30 and the cells
## concerned.

const EM := "fn-exponential-model"
const LL := "t1-log-laws"
const SEEDS := 30


func _make(type: String, c: Dictionary, seed: int, format: String = "mcq") -> Dictionary:
	return QuestionEngine.make({"type": type, "unknown": c.unknown, "rep": c.rep, "angle": c.angle, "seed": seed, "format": format})


func _cells(type: String, unknown: String, angle: String = "") -> Array:
	return QuestionEngine.cells(false, [type]).filter(func(c): return c.unknown == unknown and (angle == "" or c.angle == angle))


func _steps(q: Dictionary) -> Array:
	var out: Array = []
	for sol in q.solutions:
		out.append_array(Step.texts(sol.steps))
	return out


static func _q(key: Variant) -> Q:
	var s := str(key)
	if "/" in s:
		var bits := s.split("/")
		return Q.new(int(bits[0]), int(bits[1]))
	return Q.new(int(s))


# ── exp-model ────────────────────────────────────────────────

func test_a_prediction_from_a_data_point_is_at_a_later_time() -> void:
	var cells := _cells(EM, "predict-from-data-point")
	check(not cells.is_empty(), "no predict-from-data-point cells")
	for c in cells:
		for seed in range(1, SEEDS + 1):
			var q := _make(EM, c, seed)
			check(not q.has("error"), "%s seed %d: %s" % [c.key, seed, q.get("error")])
			if q.has("error"):
				continue
			check(int(q.situation.t2) > int(q.situation.t1), "%s seed %d: asks for t2 = %s with the reading at t1 = %s" % [c.key, seed, q.situation.t2, q.situation.t1])


func test_whole_units_key_is_not_always_second_smallest() -> void:
	for c in _cells(EM, "whole-units-inequality"):
		var ranks := {}
		for seed in range(1, SEEDS + 1):
			var q := _make(EM, c, seed)
			if q.has("error"):
				fail("%s seed %d: %s" % [c.key, seed, q.error])
				continue
			var vals: Array = q.choices.map(func(o): return Q.of(o.values.v).to_float())
			var key: float = Q.of(q.choices.filter(func(o): return o.correct)[0].values.v).to_float()
			vals.sort()
			ranks[vals.find(key)] = true
		check(ranks.size() > 1, "%s: the key is always at rank %s of the options" % [c.key, ranks.keys()])


func test_no_time_option_is_one_unit_with_a_plural_unit() -> void:
	for u in ["whole-units-inequality", "time-from-graph"]:
		var cells := _cells(EM, u)
		check(not cells.is_empty(), "no %s cells" % u)
		for c in cells:
			for seed in range(1, SEEDS + 1):
				var q := _make(EM, c, seed)
				if q.has("error"):
					fail("%s seed %d: %s" % [c.key, seed, q.error])
					continue
				for o in q.choices:
					check(Q.of(o.values.v).to_float() > 1.0, "%s seed %d: option %s reads as one plural unit" % [c.key, seed, o.text])


func test_no_rounding_trap_is_shown_at_3_sf() -> void:
	for c in QuestionEngine.cells(false, [EM]):
		for seed in range(1, 11):
			var q := _make(EM, c, seed)
			if q.has("error"):
				fail("%s seed %d: %s" % [c.key, seed, q.error])
				continue
			for o in q.choices:
				if o.get("trap", false) and o.values.has("v"):
					var v: Q = Q.of(o.values.v)
					check(not Fmt.sf(v) in o.text or Fmt.sf(v) == Fmt.sf(v, 2), "%s seed %d: trap %s reads at 3 s.f." % [c.key, seed, o.text])


func test_a_limited_model_is_rearranged_before_taking_logs() -> void:
	var seen := 0
	for unknown in ["time-to-level", "whole-units-inequality"]:
		for c in _cells(EM, unknown, "log-both-sides"):
			for seed in range(1, SEEDS + 1):
				var q := _make(EM, c, seed)
				if q.has("error") or q.situation.form != "limited":
					continue
				for st in _steps(q):
					var at: int = st.find("ln of both sides")
					if at < 0:
						continue
					seen += 1
					check(st.substr(0, at).contains("e^(−"), "%s seed %d: logs taken before isolating: %s" % [c.key, seed, st])
					check(not st.contains("ln(%s − " % q.situation.L) and not st.contains("ln(%s − %s)" % [q.situation.C, q.situation.L]),
						"%s seed %d: ln of a difference: %s" % [c.key, seed, st])
	check(seen > 0, "no limited log-both-sides question was made")


func test_isolate_then_log_works_out_t() -> void:
	for c in _cells(EM, "time-to-level", "isolate-then-log"):
		for seed in range(1, SEEDS + 1):
			var q := _make(EM, c, seed)
			if q.has("error"):
				fail("%s seed %d: %s" % [c.key, seed, q.error])
				continue
			var t := Fmt.sf(float(q.situation.tL), 6)
			var shown := Step.texts(q.solutions[0].steps)
			check(shown.slice(0, shown.size() - 1).any(func(st): return st.contains(t)), "%s seed %d: t = %s never worked out: %s" % [c.key, seed, t, shown])


func test_a_continuous_k_is_a_signed_decimal_in_the_working() -> void:
	var frac := RegEx.create_from_string("/\\(−?\\d+/\\d+\\)")
	for unknown in ["time-to-level", "whole-units-inequality", "model-from-graph"]:
		for c in _cells(EM, unknown):
			for seed in range(1, SEEDS + 1):
				var q := _make(EM, c, seed)
				if q.has("error"):
					fail("%s seed %d: %s" % [c.key, seed, q.error])
					continue
				for st in _steps(q):
					check(not st.contains("+ −"), "%s seed %d: '+ −' in %s" % [c.key, seed, st])
					check(not st.contains("/−"), "%s seed %d: an unbracketed negative divisor in %s" % [c.key, seed, st])
					check(frac.search(st) == null, "%s seed %d: k as a fraction in %s" % [c.key, seed, st])


func test_method_names_match_the_working() -> void:
	for c in _cells(EM, "initial-from-later"):
		for seed in range(1, 4):
			var q := _make(EM, c, seed)
			check(not q.solutions[0].name.to_lower().contains("log"), "%s: %s" % [c.key, q.solutions[0].name])
	for c in _cells(EM, "log-model-solve"):
		for seed in range(1, 4):
			var q := _make(EM, c, seed)
			check(not q.solutions[0].name.contains("P₀") and not q.solutions[0].name.contains("Ae^"), "%s: %s" % [c.key, q.solutions[0].name])


# ── log-laws ─────────────────────────────────────────────────

func test_a_number_filler_is_not_always_one_more_than_the_key() -> void:
	for unknown in ["show-number", "evaluate-single", "given-log-laws", "ab-base-value", "ab-base-hence", "value-hidden",
			"log-of-root", "given-log-base", "single-ln-k", "value-difference"]:
		var fillers := 0
		var plus_one := 0
		for c in _cells(LL, unknown):
			for seed in range(1, SEEDS + 1):
				var q := _make(LL, c, seed)
				if q.has("error"):
					fail("%s seed %d: %s" % [c.key, seed, q.error])
					continue
				var right: Dictionary = q.choices.filter(func(o): return o.correct)[0].values
				var slot := "k" if right.has("k") else "v"
				for o in q.choices:
					if o.get("src", "") == "fillers" and o.values.has(slot):
						fillers += 1
						if Q.of(o.values[slot]).eq(Q.of(right[slot]).add(1)):
							plus_one += 1
		if fillers > 0:
			check(plus_one < fillers, "%s: all %d fillers are the key + 1" % [unknown, fillers])
			check(plus_one * 2 <= fillers + 4, "%s: %d of %d fillers are the key + 1" % [unknown, plus_one, fillers])


func test_a_surd_base_offers_the_times_base_slip() -> void:
	var surds := 0
	var shown := 0
	var largest := 0
	for c in _cells(LL, "evaluate-single"):
		for seed in range(1, SEEDS + 1):
			var q := _make(LL, c, seed)
			if q.has("error") or q.situation.shape != "surd":
				continue
			surds += 1
			if q.choices.any(func(o): return o.ref == LL + "#16"):
				shown += 1
			var vals: Array = q.choices.map(func(o): return Q.of(o.values.v).to_float())
			if Q.of(q.choices.filter(func(o): return o.correct)[0].values.v).to_float() == vals.max():
				largest += 1
	check(surds > 0, "no surd-base question was made")
	check(shown * 3 >= surds, "#16 shows in only %d of %d surd-base questions" % [shown, surds])
	check(largest < surds, "the key is the largest option in all %d surd-base questions" % surds)


func test_powers_of_ten_offer_the_named_slips() -> void:
	var seen := 0
	for c in _cells(LL, "expand-numbers"):
		for seed in range(1, SEEDS + 1):
			var q := _make(LL, c, seed)
			if q.has("error") or q.situation.shape != "ten":
				continue
			var i := int(q.situation.i)
			var j := int(q.situation.j)
			if i > 1 or j > 1:
				seen += 1
				check(q.choices.any(func(o): return o.ref == LL + "#2"), "%s seed %d: no power-of-log option" % [c.key, seed])
			if i > 0 and j > 0:
				check(q.choices.any(func(o): return o.ref == LL + "#8"), "%s seed %d: no product-of-logs option" % [c.key, seed])
	check(seen > 0, "no power-of-ten question with a power was made")


func test_no_worked_step_is_said_twice() -> void:
	for c in _cells(LL, "show-number"):
		for seed in range(1, SEEDS + 1):
			var q := _make(LL, c, seed)
			if q.has("error"):
				fail("%s seed %d: %s" % [c.key, seed, q.error])
				continue
			for sol in q.solutions:
				var st := Step.texts(sol.steps)
				for i in range(1, st.size()):
					check(st[i] != st[i - 1], "%s seed %d: step said twice: %s" % [c.key, seed, st[i]])


func test_no_step_says_a_thing_equals_itself() -> void:
	for c in _cells(LL, "log-of-root"):
		for seed in range(1, SEEDS + 1):
			var q := _make(LL, c, seed)
			if q.has("error"):
				fail("%s seed %d: %s" % [c.key, seed, q.error])
				continue
			for st in _steps(q):
				for piece in st.trim_suffix(".").split(" and "):
					var sides: PackedStringArray = piece.split(" = ")
					check(not (sides.size() == 2 and sides[0].strip_edges() == sides[1].strip_edges()), "%s seed %d: %s" % [c.key, seed, st])


func test_the_inverted_change_of_base_is_simplified() -> void:
	var seen := 0
	for c in _cells(LL, "cob-in-p-q"):
		for seed in range(1, SEEDS + 1):
			var q := _make(LL, c, seed)
			if q.has("error") or int(q.situation.j) != 0:
				continue
			for o in q.choices:
				if o.ref == LL + "#3":
					seen += 1
					check_eq(o.text, LogLawsViews.ratio_text(Q.new(1).div(_q(q.situation.co)), "q", "p"), "%s seed %d" % [c.key, seed])
	check(seen > 0, "no inverted option was shown")
