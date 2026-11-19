extends "res://tests/test_case.gd"
## Typed-answer rough edges (#194): a decimal comma, what to change in a number the marker
## can't read (and that refusing it costs no time), a rounded form of an exact answer, whole
## numbers of 1,000 or more, and the note for a z rounded too early. Each is typed with the
## on-screen keypad, as a phone does, and with a laptop's keys.


func _q(text: String) -> Variant:
	var r := Answer.parse_number(text)
	return r.q.key() if r.ok else null


func _error(text: String) -> String:
	var r := Answer.parse_number(text)
	return "" if r.ok else r.error


## The text a MathEntry gives for keys pressed one by one: the keypad's keys on a phone, or
## each character a laptop's keyboard sends (MathEntry._gui_input presses its unicode).
func _entry(keys: Array) -> String:
	var e := MathEntry.new()
	for k in keys:
		e.press(k)
	var out := e.text
	e.free()
	return out


func _laptop(typed: String) -> String:
	var keys: Array = []
	for ch in typed:
		keys.append(ch)
	return _entry(keys)


# ── Decimal comma ────────────────────────────────────────────

func test_a_single_comma_that_cant_group_thousands_is_a_decimal_point() -> void:
	var cases := {"0,5": "1/2", "12,25": "49/4", "0,500": "1/2", "1,5": "3/2", "-0,25": "-1/4", "−0,25": "-1/4",
		"1234,5": "2469/2", ",5": "1/2", "x = 2,5": "5/2", "3,1416": "3927/1250"}
	for text in cases:
		check_eq(_q(text), cases[text], text)
	check(Answer.parse_number("0,5").decimal, "a decimal comma is a decimal")


func test_a_comma_that_could_be_either_says_both_ways_to_write_it() -> void:
	check_eq(_error("1,500"), "1,500 could be 1.5 or 1500: type one of those, with no comma.")
	check_eq(_error("12,345"), "12,345 could be 12.345 or 12345: type one of those, with no comma.")
	check_eq(_error("1,000,000"), "Leave out the commas: type 1000000.")
	check_eq(_error("12,500.5"), "Leave out the comma: type 12500.5.")
	for text in ["1,2,3", "1.5,2", "2, 3", "5,"]:
		check(_error(text).contains("a point for a decimal"), "%s: %s" % [text, _error(text)])


# ── What to change ───────────────────────────────────────────

func test_a_sign_unit_or_mixed_number_says_what_to_change() -> void:
	var cases := {"25%": "Leave out the %: type the number only.", "30°": "Leave out the °: type the number only.",
		"$5": "Leave out the $: type the number only.", "5 cm": "Leave out the unit: type the number only.",
		"3.2m": "Leave out the unit: type the number only.", "12 cm²": "Leave out the unit: type the number only.",
		"1 1/2": "Write a mixed number as one fraction: type 3/2 or 1.5.",
		"-2 1/3": "Write a mixed number as one fraction: type −7/3."}
	for text in cases:
		check_eq(_error(text), cases[text], text)
	# Anything else still gets the general message.
	check_eq(_error("3x"), Answer.NOT_A_NUMBER)
	# A phone's no-break space is a space.
	check_eq(_q(" -3 "), "-3")


## A mixed number built in the answer box (1, space, then the fraction key) would read as
## 1 × ½: it is refused, not marked ½.
func test_a_mixed_number_in_the_answer_box_is_refused_not_misread() -> void:
	var text := _entry(["1", " ", "1", "/", "2"])
	check_eq(_error(text), "Write a mixed number as one fraction: type 3/2 or 1.5.", text)


func test_refused_input_costs_no_time() -> void:
	var r := _run_on(_triangle())
	var start := r.time_left
	r.tick(10.0)
	var res := r.answer({"v": "25,000"})
	check_eq(res.complete, false)
	check_eq(r.time_left, start - 10.0 + Tuning.REFUSED_REFUND, "the clock gets the time back")
	check_eq(r.stats.questions, 0, "not marked")
	# The same refusal again earns nothing; a new one does, up to the cap.
	r.answer({"v": "25,000"})
	check_eq(r.time_left, start - 10.0 + Tuning.REFUSED_REFUND)
	r.answer({"v": "25%"})
	r.answer({"v": "25 cm"})
	r.answer({"v": "2 1/2"})
	check_eq(r.time_left, start - 10.0 + Tuning.REFUSED_REFUND_MAX, "at most REFUSED_REFUND_MAX a question")
	# An empty box is not a refusal.
	var r2 := _run_on(_triangle())
	r2.tick(10.0)
	r2.answer({"v": ""})
	check_eq(r2.time_left, r2.time_total - 10.0)


# ── Exact answers ────────────────────────────────────────────

func _exact(v: Q) -> Dictionary:
	var ans := Answer.make("number", {"v": v})
	ans.exact = true
	return ans


func test_a_rounded_form_of_an_exact_answer_is_glancing_with_a_note() -> void:
	var third := _exact(Q.new(1, 3))
	for typed in ["0.333", "0.33", "0,333", ".3333"]:
		var m := Answer.mark(third, {"v": typed})
		check(not m.correct and m.glancing, "%s for 1/3 is glancing" % typed)
		check_eq(m.note, Answer.EXACT_NOTE, typed)
	check(Answer.mark(third, {"v": "1/3"}).correct, "the exact value is right")
	var off := Answer.mark(third, {"v": "0.334"})
	check(not off.correct and not off.glancing and off.note == "", "a wrong decimal is wrong")
	# A whole-number sum the IB wants exact: 2350 for 2345 is the form, not the maths.
	var sum := _exact(Q.new(2345))
	check(Answer.mark(sum, {"v": "2350"}).glancing, "2350 for 2345")
	check(not Answer.mark(sum, {"v": "2340"}).glancing, "2340 is not 2345 rounded")


func test_picking_a_rounded_exact_option_is_glancing_too() -> void:
	var ans := _exact(Q.new(1, 3))
	var q := {"format": "mcq", "answer": ans, "choices": [
		{"correct": true, "ref": "", "values": ans.values},
		{"correct": false, "ref": "", "values": {"v": Q.new(333, 1000)}, "rounded": true, "note": Answer.EXACT_NOTE}]}
	var r := QuestionEngine.mark(q, {"choice": 1})
	check(r.glancing and r.note == Answer.EXACT_NOTE)


# ── Whole numbers of 1,000 or more ───────────────────────────

func test_a_whole_number_key_takes_3_sf_only_where_it_is_meant_to() -> void:
	var plain := Answer.make("number", {"v": Q.new(1024)})
	check(Answer.mark(plain, {"v": "1020"}).correct, "a calculator value takes 3 s.f., as the IB does")
	var exact := _exact(Q.new(1024))
	var m := Answer.mark(exact, {"v": "1020"})
	check(not m.correct and m.glancing and m.note == Answer.EXACT_NOTE, "an exact count does not")
	check(Answer.mark(exact, {"v": "1,024"}).errors.v.contains("1.024 or 1024"), "1,024 says both ways")
	# Every type listed as 3 s.f. on purpose is a real cell.
	var keys := {}
	for c in QuestionEngine.cells():
		keys["%s|%s" % [c.type, c.unknown]] = true
	for key in Answer.WHOLE_SF:
		check(keys.has(key), "%s is a cell" % key)


## A sample of the cells the stress sweep checks in full (Answer.whole_key_unlisted): an
## exact-only answer and a 3 s.f. one, each set on purpose.
func test_the_sampled_whole_number_keys_are_set_on_purpose() -> void:
	for view in [{"type": "t1-ahl-counting", "unknown": "arrange-all"}, {"type": "fn-link-multiplicative-growth", "unknown": "sequence-vs-function"}]:
		for c in QuestionEngine.cells(false, [view.type]):
			if c.unknown != view.unknown:
				continue
			for seed in range(1, 11):
				var q := QuestionEngine.make({"type": c.type, "unknown": c.unknown, "rep": c.rep, "angle": c.angle, "format": "value", "seed": seed})
				check_eq(Answer.whole_key_unlisted(q.answer, c.type, c.unknown), "", "%s seed %d" % [c.key, seed])


# ── Rounding z too early ─────────────────────────────────────

func test_a_z_rounded_too_early_is_a_miss_that_says_why() -> void:
	var seen := 0
	for type_unknown in [["t4-normal-unknown-parameter", "unknown-sd"], ["t4-normal-unknown-parameter", "unknown-mean"],
			["t4-inverse-normal", "value-below"], ["t4-normal-probability", "prob-below"]]:
		for c in QuestionEngine.cells(false, [type_unknown[0]]):
			if c.unknown != type_unknown[1]:
				continue
			for seed in range(1, 31):
				var q := QuestionEngine.make({"type": c.type, "unknown": c.unknown, "rep": c.rep, "angle": c.angle, "format": "value", "seed": seed, "paper": 2})
				if q.has("error") or not q.answer.has("premature"):
					continue
				var early: Q = q.answer.premature[0].v
				var m := QuestionEngine.mark(q, {"v": Fmt.sf(early).replace("−", "-")})
				check(not m.correct and not m.glancing, "%s seed %d: %s is a miss" % [c.key, seed, Fmt.sf(early)])
				check_eq(m.note, Answer.PREMATURE_NOTE, "%s seed %d" % [c.key, seed])
				var right := QuestionEngine.mark(q, {"v": Fmt.sf(q.answer.values.v).replace("−", "-")})
				check(right.correct and right.note == "", "%s seed %d: the right value" % [c.key, seed])
				seen += 1
				break
	check(seen >= 4, "every normal type has a premature value somewhere (%d)" % seen)


func test_a_miss_shows_its_note_in_the_fight() -> void:
	var m := {"note": Answer.PREMATURE_NOTE}
	check_eq(Run._note("wrong", m), Answer.PREMATURE_NOTE)
	check_eq(Run._note("right", m), "")


# ── Phone keypad and laptop keys ─────────────────────────────

## The cases above, typed on the keypad (a phone has no system keyboard here, FAL-419,
## so no comma) and on a laptop's keys.
func test_each_case_on_a_phone_keypad_and_a_laptop() -> void:
	var third := _exact(Q.new(1, 3))
	# Phone: the keypad's keys, a true minus and the fraction key.
	check(Answer.mark(third, {"v": _entry(["1", "/", "3"])}).correct, "keypad 1/3")
	var keyed := Answer.mark(third, {"v": _entry(["0", ".", "3", "3", "3"])})
	check(keyed.glancing and keyed.note == Answer.EXACT_NOTE, "keypad 0.333 for an exact 1/3")
	check_eq(_q(_entry(["−", "0", ".", "2", "5"])), "-1/4", "keypad −0.25")
	check_eq(_q(_entry(["1", "0", "2", "4"])), "1024", "keypad 1024")
	for key in Keypad.ANSWER_KEYS:
		check(key != "," and key != "%", "the keypad offers no %s to refuse" % key)
	# Laptop: each character as the keyboard sends it.
	check_eq(_q(_laptop("0,5")), "1/2", "laptop 0,5")
	check_eq(_q(_laptop("-0,25")), "-1/4", "laptop -0,25")
	check_eq(_error(_laptop("1,500")), "1,500 could be 1.5 or 1500: type one of those, with no comma.")
	check_eq(_error(_laptop("25%")), "Leave out the %: type the number only.")
	check_eq(_error(_laptop("5 cm")), "Leave out the unit: type the number only.")
	var laptop := Answer.mark(third, {"v": _laptop("0,333")})
	check(laptop.glancing and laptop.note == Answer.EXACT_NOTE, "laptop 0,333 for an exact 1/3")
	# The fraction key makes a decimal comma's number the top, as it does a point's.
	check_eq(_q(_entry(["1", ",", "5", "/", "3"])), "1/2", "1,5 over 3")


# ── Helpers ──────────────────────────────────────────────────

## A Paper 2 triangle question (a typed 3 s.f. measure) open in a fresh run.
func _triangle() -> Dictionary:
	return QuestionEngine.make({"type": "t3-sine-cosine-rule", "unknown": "side-cosine-rule", "rep": "words",
		"angle": "cosine-rule", "format": "value", "seed": 7, "paper": 2})


func _run_on(q: Dictionary) -> Run:
	var r := Run.new(SaveData.blank(), "quadratics", 1, 42)
	r.clock = func() -> int: return 1_800_000_000
	r.start()
	r.question = q
	return r
