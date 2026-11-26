extends "res://tests/test_case.gd"
## The reading pass on the `arithmetic-sequence` situation (t1-arithmetic-sequence,
## t1-ext-sigma-arithmetic) and the `arithmetic-context` situation (t1-arithmetic-in-context),
## FAL-1605 / GitHub #193: each test pins one fixed finding, over seeds 1..30 and every cell
## of the unknown it is about.

const SEQ := "t1-arithmetic-sequence"
const SIG := "t1-ext-sigma-arithmetic"
const CTX := "t1-arithmetic-in-context"
const SEEDS := 30
## A coefficient of 1 written out: "1d", "1(n − 1)", "(−1)(n − 1)", "1 × 26", "−1 × 45", or
## a "+ 0" left on the end.
const SPELLED_ONE := "((^|[^0-9.,])1d\\b|(^|[^0-9.])1\\(|\\(−1\\)\\(|(^|[ (:])−?1 × \\d|[+−] 0 =)"


func _make(type: String, unknown: String, rep: String, angle: String, seed: int, format: String = "mcq", paper: int = 0) -> Dictionary:
	var v := {"type": type, "unknown": unknown, "rep": rep, "angle": angle, "seed": seed, "format": format}
	if paper > 0:
		v.paper = paper
	return QuestionEngine.make(v)


## Every question of an unknown's cells over the seeds, with no errors.
func _each(type: String, unknown: String, format: String = "mcq", seeds: int = SEEDS, paper: int = 0) -> Array:
	var out: Array = []
	for c in QuestionEngine.cells(false, [type]):
		if c.unknown != unknown:
			continue
		for seed in range(1, seeds + 1):
			var q := _make(type, unknown, c.rep, c.angle, seed, format, paper)
			check(not q.has("error"), "%s seed %d: %s" % [c.key, seed, q.get("error")])
			if not q.has("error"):
				q.cell_key = c.key
				q.cell_rep = c.rep
				out.append(q)
	return out


func _steps(q: Dictionary) -> Array:
	var out: Array = []
	for sol in q.solutions:
		out.append_array(sol.steps.map(func(st): return Step.text(st)))
	return out


func _texts(q: Dictionary) -> Array:
	var out: Array = [q.prompt]
	out.append_array(q.lines)
	for o in q.get("choices", []):
		out.append(o.text)
	out.append_array(_steps(q))
	return out


static func _q(v: Variant) -> Q:
	if v is Q:
		return v
	var t := str(v)
	if "/" in t:
		var p := t.split("/")
		return Q.new(int(p[0]), int(p[1]))
	return Answer.parse_number(t).q


func _key(q: Dictionary) -> Q:
	for o in q.choices:
		if o.correct:
			return _q(o.values.v)
	return Q.new(0)


# ── arithmetic-sequence ──────────────────────────────────────

## No coefficient of 1 is written out: "u₂ = u₁ + 1d", "−24 + 1(n − 1)", "u₂₆ = 1 × 26 − 25",
## "−21 + (−1)(n − 1)", "u₁₃ = −5 × 13 + 0", and in Σ "1 × 1 + 9", "1 × 276 + 207". The constant
## summed, "Σ1 = 1 × 16, as each of the 16 terms is 1", is a count, not a coefficient.
func test_no_coefficient_of_one_is_written() -> void:
	var re := RegEx.create_from_string(SPELLED_ONE)
	var count := RegEx.create_from_string("^Σ\\d+ = \\d+ × \\d+ = \\d+, as each of the")
	var units := {SEQ: ["term-from-u1-d", "d-from-two-terms", "u1-from-two-terms"],
		SIG: ["evaluate-sigma", "evaluate-shifted", "write-sigma", "upper-from-total"]}
	for t in units:
		for u in units[t]:
			for q in _each(t, u, "value", SEEDS, 1):
				for line in _texts(q):
					check(count.search(line) != null or re.search(line) == null, "%s seed %d: %s" % [q.cell_key, q.view.seed, line])
	for q in _each(SIG, "evaluate-sigma", "error-spot", SEEDS):
		for line in q.lines:
			check(re.search(line) == null, "%s spot seed %d: %s" % [q.cell_key, q.view.seed, line])


## A series written out keeps one sign before its ellipsis: the fourth term's
## ("−13 − 17 − 21 − … − 117", not "… + … −").
func test_series_ellipsis_has_the_fourth_terms_sign() -> void:
	for q in _each(SIG, "write-sigma", "value"):
		var parts: PackedStringArray = q.lines[0].split(" … ")
		check_eq(parts.size(), 2, q.lines[0])
		var head := parts[0]
		var falls_below := head.ends_with(" −")
		# The fourth term is the third plus d: read the three terms back from the line.
		var nums := RegEx.create_from_string("(−?\\d+) ([+−]) (\\d+) ([+−]) (\\d+) ([+−])$").search(head)
		check(nums != null, "can't read " + head)
		if nums == null:
			continue
		var t1 := int(nums.get_string(1).replace("−", "-"))
		var t2 := int(nums.get_string(3)) * (-1 if nums.get_string(2) == "−" else 1)
		var t3 := int(nums.get_string(5)) * (-1 if nums.get_string(4) == "−" else 1)
		var t4 := t3 + (t2 - t1)
		check_eq(falls_below, t4 < 0, "%s: the ellipsis sign is not the fourth term's (%d)" % [q.lines[0], t4])


## Counting a Σ's terms asks with an IB command term.
func test_count_terms_uses_a_command_term() -> void:
	for q in _each(SIG, "count-terms", "mcq", 5):
		check(q.prompt.begins_with("Write down the number of terms"), q.prompt)


# ── arithmetic-context ───────────────────────────────────────

## A stack's table shows t₁ to t₄, so it never asks for one of them.
func test_a_stack_table_asks_for_a_stack_it_does_not_show() -> void:
	for q in _each(CTX, "stack-total", "value"):
		if q.cell_rep != "table":
			continue
		var m := RegEx.create_from_string("in a stack of (\\d+) rows").search(q.prompt)
		check(m != null and int(m.get_string(1)) > 4, "%s seed %d: %s" % [q.cell_key, q.view.seed, q.prompt])


## No wrong claim gives the key's verdict: "No: n = 7.5" beside the key "No: n = 8.5".
func test_whole_n_wrong_claims_give_the_other_verdict() -> void:
	for q in _each(CTX, "whole-n-test", "mcq"):
		var key: String = q.answer_text.split(":")[0]
		check_eq(q.choices.size(), 4, "%s seed %d: %d options" % [q.cell_key, q.view.seed, q.choices.size()])
		for o in q.choices:
			if not o.correct:
				check(not o.text.begins_with(key + ":"), "%s seed %d: %s beside the key %s" % [q.cell_key, q.view.seed, o.text, q.answer_text])


## A term's options don't sit the key between its two neighbours: key − d and key + d are
## both shown only when each is a named slip.
func test_a_term_is_not_between_its_neighbours() -> void:
	for u in ["term-in-context", "in-or-after", "value-after"]:
		for q in _each(CTX, u, "mcq"):
			var key := _key(q)
			check(not q.choices.any(func(o): return o.get("src", "") == "nudge"), "%s seed %d: a nudged option" % [q.cell_key, q.view.seed])
			var gaps := {}
			for o in q.choices:
				if not o.correct:
					gaps[_q(o.values.v).sub(key).key()] = o.get("src", "")
			for g in gaps.keys():
				var neg := _q(g).neg().key()
				if gaps.has(neg) and g != "0":
					check(gaps[g] == "wrongs" and gaps[neg] == "wrongs",
						"%s seed %d: the key %s sits between two options %s apart, one a filler: %s" % [q.cell_key, q.view.seed, key.text(), _q(g).abs_q().text(), q.choices.map(func(o): return o.text)])


## Finding n: when a named slip sits next to the key, the first filler is a slip of its own,
## not the key's other neighbour.
func test_an_n_filler_is_not_the_keys_other_neighbour() -> void:
	for u in ["term-number", "count-terms", "first-past", "stack-crates"]:
		for q in _each(CTX, u, "mcq"):
			var key := _key(q)
			check(not q.choices.any(func(o): return o.get("src", "") == "nudge"), "%s seed %d: a nudged option" % [q.cell_key, q.view.seed])
			var below: bool = q.choices.any(func(o): return not o.correct and o.get("src", "") == "wrongs" and _q(o.values.v).eq(key.sub(1)))
			if not below:
				continue
			for o in q.choices:
				if o.get("src", "") == "fillers" and o.get("gi", -1) != 0:
					# A later filler is used only when the first collided with another option.
					continue
				check(not (o.get("src", "") == "fillers" and _q(o.values.v).eq(key.add(1))),
					"%s seed %d: filler %s with the slip %s" % [q.cell_key, q.view.seed, o.text, key.sub(1).text()])


## The simple-interest working writes the interest a year as the table and the story do:
## "150.50", not "150.5".
func test_simple_interest_steps_write_money_alike() -> void:
	var re := RegEx.create_from_string("× \\d+\\.\\d(?!\\d)|d = \\d+\\.\\d(?!\\d)")
	for q in _each(CTX, "simple-interest", "value"):
		for line in _steps(q):
			check(re.search(line) == null, "%s seed %d: %s" % [q.cell_key, q.view.seed, line])
