extends "res://tests/test_case.gd"
## Equivalent answers (FAL-788): a typed answer with the answer's value is right, unless the
## question asks for a form it breaks; then it is a glancing hit whose note names the rule.
## No multiple-choice option that is marked wrong has the answer's value.


func _mark(ans: Dictionary, typed: Dictionary) -> Dictionary:
	return Answer.mark(ans, typed)


func _right(ans: Dictionary, typed: Dictionary, why: String) -> void:
	var r := _mark(ans, typed)
	check(r.correct, "%s should be right: %s" % [why, typed])


func _glancing(ans: Dictionary, typed: Dictionary, note: String, why: String) -> void:
	var r := _mark(ans, typed)
	check(not r.correct and r.glancing, "%s should be glancing: %s" % [why, typed])
	check_eq(r.get("note", ""), note, why)


func _wrong(ans: Dictionary, typed: Dictionary, why: String) -> void:
	var r := _mark(ans, typed)
	check(not r.correct and not r.glancing, "%s should be wrong: %s" % [why, typed])


func test_brackets2_is_marked_by_its_product() -> void:
	var ans := Answer.make("brackets2", {"a1": Q.new(2), "b1": Q.new(1), "a2": Q.new(1), "b2": Q.new(3)})
	_right(ans, {"a1": "2", "b1": "1", "a2": "1", "b2": "3"}, "the answer")
	_right(ans, {"a1": "1", "b1": "3", "a2": "2", "b2": "1"}, "the brackets swapped")
	_right(ans, {"a1": "-2", "b1": "-1", "a2": "-1", "b2": "-3"}, "both brackets negated")
	_right(ans, {"a1": "4", "b1": "2", "a2": "1/2", "b2": "3/2"}, "Factorise. does not ask for integers")
	_wrong(ans, {"a1": "2", "b1": "3", "a2": "1", "b2": "1"}, "another product")
	_wrong(ans, {"a1": "-2", "b1": "-1", "a2": "1", "b2": "3"}, "one bracket negated")
	# "Factorise, if it can be done over the integers" (difference of squares)
	var dos := Answer.make("brackets2", {"a1": Q.new(3), "b1": Q.new(-2), "a2": Q.new(3), "b2": Q.new(2)})
	dos.integers = true
	_right(dos, {"a1": "-3", "b1": "2", "a2": "-3", "b2": "-2"}, "negated over the integers")
	_glancing(dos, {"a1": "6", "b1": "-4", "a2": "3/2", "b2": "1"}, "Same expression, but the brackets need whole-number coefficients.", "fractions over the integers")


func test_common_takes_any_full_factorisation_and_a_partial_one_is_glancing() -> void:
	var ans := Answer.make("common", {"g": Q.new(2), "a": Q.new(3), "b": Q.new(1)})
	_right(ans, {"g": "2", "a": "3", "b": "1"}, "2x(3x + 1)")
	_right(ans, {"g": "-2", "a": "-3", "b": "-1"}, "−2x(−3x − 1) is fully factorised")
	var note := "Same expression, but not fully factorised: take out the highest common factor."
	_glancing(ans, {"g": "1", "a": "6", "b": "2"}, note, "x(6x + 2) asked fully")
	_glancing(ans, {"g": "4", "a": "3/2", "b": "1/2"}, note, "4x(1.5x + 0.5)")
	_wrong(ans, {"g": "2", "a": "3", "b": "-1"}, "another expression")


func test_an_exact_surd_is_marked_by_value_unless_simplest_form_is_asked() -> void:
	var exact := Answer.make("surd", {"m": Q.new(4), "r": Q.new(2)}, {}, "AC = ", " cm")
	exact.exact = true
	_right(exact, {"m": "4", "r": "2"}, "4√2")
	_right(exact, {"m": "2", "r": "8"}, "2√8 for an exact length")
	_right(exact, {"m": "1", "r": "32"}, "√32 for an exact length")
	_wrong(exact, {"m": "-4", "r": "2"}, "−4√2 is another number")
	_wrong(exact, {"m": "4", "r": "3"}, "another surd")
	var simplest := Answer.make("surd", {"m": Q.new(4), "r": Q.new(2)})
	simplest.exact = true
	simplest.simplest = true
	_right(simplest, {"m": "4", "r": "2"}, "simplest form")
	_glancing(simplest, {"m": "2", "r": "8"}, "Same value, but not in simplest surd form.", "2√8 asked simplest")
	_wrong(simplest, {"m": "2", "r": "2"}, "another surd")


func test_pm_surd_is_a_pair_of_numbers() -> void:
	var exact := Answer.make("pm_surd", {"h": Q.new(2), "m": Q.new(2), "r": Q.new(3)}, {}, "x = ")
	exact.exact = true
	_right(exact, {"h": "2", "m": "2", "r": "3"}, "2 ± 2√3")
	_right(exact, {"h": "2", "m": "1", "r": "12"}, "2 ± √12 for exact zeros")
	_right(exact, {"h": "2", "m": "-2", "r": "3"}, "2 ± (−2)√3")
	_wrong(exact, {"h": "-2", "m": "2", "r": "3"}, "another centre")
	var simplest := exact.duplicate()
	simplest.simplest = true
	_right(simplest, {"h": "2", "m": "-2", "r": "3"}, "2 ± (−2)√3 in simplest form")
	_glancing(simplest, {"h": "2", "m": "1", "r": "12"}, "Same value, but not in simplest surd form.", "2 ± √12 asked simplest")


func test_an_exact_length_form_takes_an_unsimplified_root() -> void:
	var ans := Answer.make("form", {"m": Q.new(6), "r": Q.new(2), "text": "AB = 6√2"}, {"parts": ["AB = ", {"slot": "m"}, "√", {"slot": "r"}]})
	ans.exact = true
	ans.surd = true
	_right(ans, {"m": "3", "r": "8"}, "3√8 in exact form")
	_right(ans, {"m": "1", "r": "72"}, "√72 in exact form")
	_wrong(ans, {"m": "6", "r": "3"}, "another length")


func test_root_power_terms_come_in_either_order() -> void:
	var seen := 0
	for seed in range(1, 20):
		var q := QuestionEngine.make({"type": "t5-differentiation-rules", "unknown": "root-powers", "rep": "equation", "angle": "any", "seed": seed})
		if q.has("error"):
			continue
		seen += 1
		var v: Dictionary = q.answer.values
		var typed := {"c0": v.c1.key(), "e0": v.e1.key(), "c1": v.c0.key(), "e1": v.e0.key()}
		check(QuestionEngine.mark(q, typed).correct, "seed %d: %s with the terms swapped" % [seed, q.answer_text])
	check(seen > 0, "no root-powers question")


func test_a_rise_of_minus_r_is_a_fall_of_r() -> void:
	var ans := Answer.make("pct", {"dir": "fall", "v": Q.new(5)}, {"per": "per year"})
	ans.exact = true
	_right(ans, {"dir": "fall", "v": "5"}, "a fall of 5%")
	_right(ans, {"dir": "rise", "v": "-5"}, "a rise of −5%")
	_wrong(ans, {"dir": "rise", "v": "5"}, "a rise of 5%")


func test_an_interval_takes_its_ends_in_either_order() -> void:
	var ans := Answer.make("interval", {"shape": "between", "lo": Q.new(-2), "hi": Q.new(3), "ends": "left out"}, {"var": "x"})
	ans.exact = true
	_right(ans, {"shape": "between", "lo": "3", "hi": "-2", "ends": "left out"}, "between 3 and −2")
	_wrong(ans, {"shape": "outside", "lo": "3", "hi": "-2", "ends": "left out"}, "outside")


func test_a_form_option_is_glancing_when_picked() -> void:
	var seen := 0
	for seed in range(1, 30):
		var q := QuestionEngine.make({"type": "fn-pre-factorise", "unknown": "common-factor", "rep": "equation", "angle": "any", "seed": seed, "format": "mcq"})
		if q.has("error"):
			continue
		for i in q.choices.size():
			var c: Dictionary = q.choices[i]
			if c.get("form", false):
				seen += 1
				var r := QuestionEngine.mark(q, {"choice": i})
				check(not r.correct and r.glancing, "seed %d: %s" % [seed, c.text])
				check_eq(r.note, Answer.form_note(q.answer))
	check(seen > 0, "no x(Ax + B) option")


## Every built cell: no option marked wrong is the answer by value, and every form option is.
func test_no_wrong_option_is_equivalent_to_the_answer() -> void:
	var checked := 0
	for c in QuestionEngine.cells():
		for seed in [1, 2]:
			var q := QuestionEngine.make({"type": c.type, "unknown": c.unknown, "rep": c.rep, "angle": c.angle, "seed": seed})
			if q.has("error") or not q.has("answer") or q.answer.kind in Answer.MC_ONLY:
				continue
			for o in q.get("choices", []):
				if o.correct or o.get("trap", false) or not Answer.typable(q.answer, o.values):
					continue
				checked += 1
				check(not Answer.values_right(q.answer, o.values), "%s seed %d: option %s is the answer %s" % [c.key, seed, o.text, q.answer_text])
				check(o.get("form", false) == Answer.form_broken(q.answer, o.values), "%s seed %d: option %s" % [c.key, seed, o.text])
	check(checked > 1000, "only %d options checked" % checked)
