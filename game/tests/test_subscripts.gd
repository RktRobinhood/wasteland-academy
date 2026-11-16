extends "res://tests/test_case.gd"
## Subscripts in shown maths are lowered (FAL-955): the catalogue writes u_1, S_n and
## log_b in method names, and MathText cuts them out as it cuts out powers.


func _sub(text: String) -> Dictionary:
	return {"sub": [text]}


func test_an_underscore_after_a_letter_is_a_subscript() -> void:
	check_eq(MathText.parse("u_1 r^n"), ["u", _sub("1"), " r", {"pow": ["n"]}])
	check_eq(MathText.parse("Substitute into u_n = u_1 + (n − 1)d"),
		["Substitute into u", _sub("n"), " = u", _sub("1"), " + (n − 1)d"])
	check_eq(MathText.parse("S_10 and 2u_1"), ["S", _sub("10"), " and 2u", _sub("1")])
	check_eq(MathText.parse("u_(n+1) − u_n"), ["u", _sub("n+1"), " − u", _sub("n")], "the brackets go")
	check_eq(MathText.parse("log_b(x)"), ["log", _sub("b"), "(x)"], "only the base is lowered")
	check_eq(MathText.parse("rS_n and r_A"), ["rS", _sub("n"), " and r", _sub("A")])
	check_eq(MathText.parse("a^(log_a x)"), ["a", {"pow": ["log", _sub("a"), " x"]}], "a subscript in a power")


func test_a_subscript_can_sit_in_a_fraction() -> void:
	check_eq(MathText.parse("S∞/u_1 = 1/(1 − r)"), [{"num": ["S∞"], "den": ["u", _sub("1")]}, " = ",
		{"num": ["1"], "den": ["1 − r"]}])
	check_eq(MathText.parse("1/u_(n+1)"), [{"num": ["1"], "den": ["u", _sub("n+1")]}])


func test_an_underscore_that_is_not_a_subscript_stays() -> void:
	for s in ["x = ___", "a _1", "open_hi", "export_questions", "u_ 1"]:
		check_eq(MathText.parse(s), [s], s)
		check(not MathText.has_markup(s), s + " is plain")
	check(MathText.has_markup("u_1"), "u_1 is drawn as maths")


func test_the_tree_reads_without_its_underscores() -> void:
	check_eq(MathBox.parse("S_n = u_1(1 − r^n)").plain(), "Sn = u1(1 − rn)")
	check_eq(MathBox.parse("u_(n+1)").to_text(), "u_(n+1)")


func test_a_subscript_is_lowered_and_smaller() -> void:
	var m := UiTheme.math_label("u_1 + u", UiTheme.BODY)
	tree.root.add_child(m)
	m.size = Vector2(1000, m.get_combined_minimum_size().y)
	await tree.process_frame
	var pieces := m.drawn()
	var u: Dictionary = pieces.filter(func(d): return d.get("text", "") == "u")[0]
	var one: Dictionary = pieces.filter(func(d): return d.get("text", "") == "1")[0]
	check_eq(one.size, roundi(UiTheme.BODY * UiTheme.POWER_SCALE), "a power's size")
	check(one.at.y > u.at.y, "below the line")
	check(one.at.x > u.at.x, "after its letter")
	check_eq(m.get_parsed_text(), "u1 + u")
	m.free()


func test_a_method_tab_shows_its_subscript() -> void:
	var b := Button.new()
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	b.add_theme_font_size_override("font_size", UiTheme.SMALL)
	UiTheme.math_button(b, "Substitute into u_n = u_1 + (n − 1)d")
	tree.root.add_child(b)
	b.size = Vector2(350, 0)
	await tree.process_frame
	check_eq(b.text, "", "the button's own text would show the underscore")
	var m: MathLabel = b.get_node("Math")
	check(not m.get_parsed_text().contains("_"), m.get_parsed_text())
	b.free()


func test_no_shown_method_or_class_name_keeps_an_underscore_or_caret() -> void:
	# Every class, unknown and method name the practice tabs and the explorer show, as drawn.
	var seen := 0
	for t in QuestionEngine.catalogue().types:
		var names: Array = [t.get("name", "")]
		for a in t.get("angles", []):
			names.append(a.get("name", ""))
		for u in t.get("unknowns", []):
			names.append(u.get("asked", ""))
		for n: String in names:
			if not (n.contains("_") or n.contains("^")):
				continue
			seen += 1
			var shown := MathBox.parse(n).plain()
			check(not shown.contains("_") and not shown.contains("^"), "%s: %s" % [t.id, shown])
	check(seen > 0, "no name with a subscript or power was found")


func test_no_method_tab_or_option_keeps_an_underscore_or_caret() -> void:
	# Every built cell, seed 1, in both formats: its worked-solution tabs and its options as drawn.
	var bad := []
	var raw := 0
	for id in QuestionEngine.built_types():
		for c in QuestionEngine.cells(false, [id]):
			for f in ["value", "mcq"]:
				var q := QuestionEngine.make({"type": id, "unknown": c.unknown, "rep": c.rep, "angle": c.angle, "seed": 1,
					"format": f})
				if q.has("error"):
					continue
				var shown: Array = q.get("solutions", []).map(func(s): return s.name)
				shown.append_array(q.get("choices", []).map(func(o): return o.text))
				for s: String in shown:
					raw += int(s.contains("_") or s.contains("^"))
					var p := MathBox.parse(s).plain()
					if p.contains("^") or RegEx.create_from_string("[A-Za-z]_[A-Za-z0-9(]").search(p) != null:
						bad.append("%s: %s" % [c.key, p])
	check(raw > 0, "no tab or option had a subscript or power to draw")
	check(bad.is_empty(), "%d shown with a caret or underscore, first: %s" % [bad.size(), bad.slice(0, 5)])
