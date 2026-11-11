extends "res://tests/test_case.gd"
## Fractions in shown maths are stacked over a bar (FAL-797, GH #62): MathText cuts them
## out of the text, MathBox lays them out and MathLabel draws them.


func _f(num: Variant, den: Variant) -> Dictionary:
	return {"num": num if num is Array else [num], "den": den if den is Array else [den]}


func test_a_sign_stays_in_front_of_the_bar() -> void:
	check_eq(MathText.parse("m = −1/2"), ["m = −", _f("1", "2")])
	check_eq(MathText.parse("(−1/2, 3)"), ["(−", _f("1", "2"), ", 3)"])
	check_eq(MathText.parse("x/(−1) + y/7 = 1"), [_f("x", "−1"), " + ", _f("y", "7"), " = 1"])
	check_eq(MathText.parse("b/−1 = 2"), [_f("b", "−1"), " = 2"])


func test_a_bracket_round_a_top_or_bottom_goes() -> void:
	check_eq(MathText.parse("(x + 1)/(x − 1)"), [_f("x + 1", "x − 1")])
	check_eq(MathText.parse("dy/dx = 16/(4x − 11)"), [_f("dy", "dx"), " = ", _f("16", "4x − 11")])
	# A bracket that is only part of the top stays.
	check_eq(MathText.parse("(x + 1)²/2"), [_f("(x + 1)²", "2")])


func test_a_whole_term_is_the_top_or_the_bottom() -> void:
	check_eq(MathText.parse("2π/3"), [_f("2π", "3")])
	check_eq(MathText.parse("3√2/2"), [_f(["3", {"root": ["2"]}], "2")])
	check_eq(MathText.parse("d²y/dx²"), [_f("d²y", "dx²")])
	check_eq(MathText.parse("n!/(r!(n − r)!)"), [_f("n!", "r!(n − r)!")])
	check_eq(MathText.parse("1/f(1)"), [_f("1", "f(1)")])
	check_eq(MathText.parse("g′(x)/g(x)"), [_f("g′(x)", "g(x)")])
	check_eq(MathText.parse("u₁/(1 − r)"), [_f("u₁", "1 − r")])
	check_eq(MathText.parse("x = (3x + 3 − 4y)/2y"), ["x = ", _f("3x + 3 − 4y", "2y")])
	check_eq(MathText.parse("6.344 / 13 = 0.4880"), [_f("6.344", "13"), " = 0.4880"])
	check_eq(MathText.parse("sin A = a sin B / b"), ["sin A = a ", _f("sin B", "b")])


func test_a_function_takes_its_argument() -> void:
	check_eq(MathText.parse("2 sin 4x/cos 4x"), ["2 ", _f("sin 4x", "cos 4x")])
	check_eq(MathText.parse("sin²θ/cos²θ"), [_f("sin²θ", "cos²θ")])
	check_eq(MathText.parse("t = 2 + ln(39/50)/ln 0.81"), ["t = 2 + ", _f(["ln(", _f("39", "50"), ")"], "ln 0.81")])
	check_eq(MathText.parse("log_a b = log_c b / log_c a."), ["log_a b = ", _f("log_c b", "log_c a"), "."])


func test_a_bracket_after_a_number_multiplies() -> void:
	check_eq(MathText.parse("17 cos(π/4(t − 4)) + 38"), ["17 cos(", _f("π", "4"), "(t − 4)) + 38"])
	check_eq(MathText.parse("S_n = n/2(u_1 + u_n)"), ["S_n = ", _f("n", "2"), "(u_1 + u_n)"])


func test_nested_fractions() -> void:
	var inner := _f("sin²θ", "cos²θ")
	check_eq(MathText.parse("(1 − sin²θ/cos²θ)/(1 + sin²θ/cos²θ)"), [_f(["1 − ", inner], ["1 + ", inner])])
	check_eq(MathText.parse("(1/2)/3"), [_f([_f("1", "2")], "3")])
	# A chain goes from the left, as 1/4/3 means (1/4)/3.
	check_eq(MathText.parse("1/4/3"), [_f([_f("1", "4")], "3")])
	check_eq(MathText.parse("S₂ = 18(1 − (1/3)²)/(1 − (1/3))"),
		["S₂ = ", _f(["18(1 − (", _f("1", "3"), ")²)"], ["1 − ", _f("1", "3")])])


func test_a_bracket_round_just_a_fraction() -> void:
	check_eq(MathText.parse("(3/2)x² + 3x"), [_f("3", "2"), "x² + 3x"])
	check_eq(MathText.parse("−(1/3)(x − 1)"), ["−", _f("1", "3"), "(x − 1)"])
	check_eq(MathText.parse("So m = (1/2)."), ["So m = ", _f("1", "2"), "."])
	# Kept when it is needed: a power, a function, a number it multiplies, a sign.
	check_eq(MathText.parse("(2/3)⁵"), ["(", _f("2", "3"), ")⁵"])
	check_eq(MathText.parse("(1/2)^n"), ["(", _f("1", "2"), ")", {"pow": ["n"]}])
	check_eq(MathText.parse("ln(3/2)"), ["ln(", _f("3", "2"), ")"])
	check_eq(MathText.parse("2(1/2)"), ["2(", _f("1", "2"), ")"])
	check_eq(MathText.parse("(1/2) × (−k/(−3))"), [_f("1", "2"), " × (−", _f("k", "−3"), ")"])


func test_fractions_in_powers() -> void:
	check_eq(MathText.parse("3x^(1/2)"), ["3x", {"pow": [_f("1", "2")]}])
	check_eq(MathText.parse("e^((1/3)(x − 1))"), ["e", {"pow": [_f("1", "3"), "(x − 1)"]}])
	check_eq(MathText.parse("x^(−1/2)"), ["x", {"pow": ["−", _f("1", "2")]}])
	# A power in a fraction.
	check_eq(MathText.parse("e^(2x)/3"), [_f(["e", {"pow": ["2x"]}], "3")])
	check_eq(MathText.parse("(1 + r/(100k))^(kn)"), ["(1 + ", _f("r", "100k"), ")", {"pow": ["kn"]}])


func test_a_slash_that_is_not_a_fraction_is_left() -> void:
	for s in ["Its velocity, in m/s, t seconds", "a(t) in m/s², t", "at 10 km/h.", "So rate = 108°/s.",
			"P/Y = 1, C/Y = 1", "GDC zero/root function", "GDC max/min of v", "a/ b", "a /b", "/", "x⁰/ 0"]:
		check_eq(MathText.parse(s), [s], s)
	check(not MathText.has_markup("Its velocity, in m/s"), "a unit is plain text")
	check(MathText.has_markup("m = −1/2"), "a fraction is maths")
	check_eq(MathBox.parse("e^(2x) + (3/2)x").plain(), "e2x + 3/2x")
	check_eq(MathBox.parse("(x + 1)/(x − 1)").plain(), "(x + 1)/(x − 1)", "a top or bottom with a space gets its brackets back")


func test_a_root_takes_a_bracket_a_number_or_a_letter() -> void:
	check_eq(MathText.parse("√(x + 1)"), [{"root": ["x + 1"]}])
	check_eq(MathText.parse("x = 2 ± √2.5"), ["x = 2 ± ", {"root": ["2.5"]}])
	check_eq(MathText.parse("(−b ± √Δ)/(2a)"), [_f(["−b ± ", {"root": ["Δ"]}], "2a")])
	check_eq(MathText.parse("1/(2√u)"), [_f("1", ["2", {"root": ["u"]}])])
	check_eq(MathText.parse("√(9/4) = 3/2"), [{"root": [_f("9", "4")]}, " = ", _f("3", "2")])
	check_eq(MathText.parse("√(2)^2"), [{"root": ["2"]}, {"pow": ["2"]}])
	for s in ["∛8 = 2", "√ alone", "√()"]:
		check_eq(MathText.parse(s), [s], s)
	check(MathText.has_markup("2√3"), "a root is maths")
	check_eq(MathBox.parse("(−b ± √Δ)/(2a) + √(x + 1)").plain(), "(−b ± √Δ)/2a + √(x + 1)")


func test_the_tree_gives_back_text_that_expr_reads() -> void:
	# FAL-812 and FAL-813 build a tree as it is typed and mark the text it gives back.
	var cases := {"−3/4": -0.75, "3/−4": -0.75, "(1/2)/3": 1.0 / 6.0, "0.5/2": 0.25, "2^(1/2)": sqrt(2.0),
		"√(2)^2": 2.0, "1/(1/3)": 3.0, "2√(9/4)": 3.0}
	for s in cases:
		var t := MathBox.parse(s).to_text()
		var r := Expr.evaluate(t.replace("−", "-"))
		check(r.ok and absf(r.value - cases[s]) < 1e-9, "%s gives %s, which should be %s: %s" % [s, t, cases[s], r])
	check_eq(MathBox.parse("−3/4").to_text(), "−(3)/(4)")
	var typed := MathBox.row([MathBox.fraction(MathBox.row([MathBox.text_box("1")]), MathBox.row())])
	check_eq(typed.to_text(), "(1)/()")


## A MathLabel in the tree, w wide, after a frame.
func _label(text: String, w: float, size: int = UiTheme.BODY) -> MathLabel:
	var m := UiTheme.math_label(text, size)
	tree.root.add_child(m)
	m.size = Vector2(w, m.get_combined_minimum_size().y)
	await tree.process_frame
	return m


func _bars(m: MathLabel) -> Array:
	return m.drawn().filter(func(d): return d.has("bar")).map(func(d): return d.bar)


func _piece(m: MathLabel, text: String) -> Dictionary:
	for d in m.drawn():
		if d.get("text", "") == text:
			return d
	return {}


func test_the_top_sits_over_the_bar_and_the_bottom_under_it() -> void:
	var m: MathLabel = await _label("m = −1/2", 1000)
	var bars := _bars(m)
	check_eq(bars.size(), 1, "one bar")
	var bar: Rect2 = bars[0]
	var top := _piece(m, "1")
	var bottom := _piece(m, "2")
	var s: int = top.size
	check(top.at.y + s * MathBox.INK_DESCENT <= bar.position.y + 0.5, "the top is over the bar")
	check(bottom.at.y - s * MathBox.INK_ASCENT >= bar.end.y - 0.5, "the bottom is under the bar")
	var font := ThemeDB.fallback_font
	var top_w := font.get_string_size("1", HORIZONTAL_ALIGNMENT_LEFT, -1, s).x
	check(bar.position.x < top.at.x and bar.end.x > top.at.x + top_w, "the bar runs past the top")
	check_eq(top.size, roundi(UiTheme.BODY * MathBox.FRACTION_SCALE), "the top's size")
	# Words are drawn one by one: "m", "=", and "−" with its fraction.
	var minus := _piece(m, "−")
	check(minus.at.x + font.get_string_size("−", HORIZONTAL_ALIGNMENT_LEFT, -1, UiTheme.BODY).x <= bar.position.x,
		"the minus is in front of the bar")
	check(bar.position.y < minus.at.y and bar.end.y > minus.at.y - UiTheme.BODY * 0.5, "the bar is level with the minus")
	check(m.size.y >= top.at.y - bottom.at.y, "the label is as tall as the fraction")
	check(m.get_combined_minimum_size().y > ThemeDB.fallback_font.get_height(UiTheme.BODY), "a fraction makes the line taller")
	m.free()


func test_a_nested_fraction_stacks_inside_the_outer_one() -> void:
	var m: MathLabel = await _label("(1 − sin²θ/cos²θ)/(1 + sin²θ/cos²θ)", 1000)
	var bars := _bars(m)
	check_eq(bars.size(), 3, "three bars")
	bars.sort_custom(func(a: Rect2, b: Rect2): return a.position.y < b.position.y)
	var outer: Rect2 = bars[1]
	check(bars[0].end.y < outer.position.y and bars[2].position.y > outer.end.y, "one inner bar above the outer bar, one below")
	check(outer.size.x > bars[0].size.x and outer.size.x > bars[2].size.x, "the outer bar is the widest")
	for d in m.drawn():
		if d.has("text"):
			check(d.size >= roundi(UiTheme.BODY * UiTheme.POWER_SCALE), "%s is drawn at %d" % [d.text, d.size])
	m.free()


func test_a_fraction_in_a_power_is_raised_at_the_power_size() -> void:
	var m: MathLabel = await _label("y = 2^(x/2)", 1000)
	var bars := _bars(m)
	check_eq(bars.size(), 1, "one bar")
	var base := _piece(m, "2")
	var top := _piece(m, "x")
	check_eq(top.size, roundi(UiTheme.BODY * UiTheme.POWER_SCALE), "the power's size")
	check(bars[0].end.y < base.at.y - UiTheme.BODY * MathBox.AXIS, "the bar is above a fraction's bar on the line")
	m.free()


func test_a_root_has_its_bar_over_what_is_under_it() -> void:
	var m: MathLabel = await _label("x = √(x + 1)", 1000)
	var signs := m.drawn().filter(func(d): return d.has("radical"))
	check_eq(signs.size(), 1, "one radical sign")
	var pts: PackedVector2Array = signs[0].radical
	var under := _piece(m, "x + 1")
	var font := ThemeDB.fallback_font
	var w := font.get_string_size("x + 1", HORIZONTAL_ALIGNMENT_LEFT, -1, under.size).x
	var bar_y := pts[pts.size() - 1].y
	check(bar_y < under.at.y - under.size * MathBox.INK_ASCENT, "the bar is over the ink")
	check(pts[3].x <= under.at.x and pts[4].x >= under.at.x + w, "the bar runs over all of it")
	check(pts[2].y >= under.at.y, "the foot is on or under the baseline")
	check_eq(under.size, UiTheme.BODY, "what is under a root keeps the line's size")
	check_eq(m.get_parsed_text(), "x = √(x + 1)")
	# A fraction under a root: the sign grows to the fraction's height.
	var tall: MathLabel = await _label("√(9/4)", 1000)
	var sign: PackedVector2Array = tall.drawn().filter(func(d): return d.has("radical"))[0].radical
	var bottom := _piece(tall, "4")
	check(sign[2].y >= bottom.at.y - 1.0, "the foot reaches the bottom of the fraction")
	m.free()
	tall.free()


func test_a_root_too_wide_for_the_line_wraps_as_text() -> void:
	var text := "AB = √((0.377067 − (−0.622969))² + (2.18853 − 1.68852)²) = 1.11807, from the stored values."
	var wide: MathLabel = await _label(text, 4000)
	check_eq(wide.drawn().filter(func(d): return d.has("radical")).size(), 1, "drawn as a root where it fits")
	var narrow: MathLabel = await _label(text, 360)
	check_eq(narrow.drawn().filter(func(d): return d.has("radical")).size(), 0, "written √(…) where it doesn't")
	var font := ThemeDB.fallback_font
	for d in narrow.drawn():
		var w := font.get_string_size(d.text, HORIZONTAL_ALIGNMENT_LEFT, -1, d.size).x
		check(d.at.x >= 0.0 and d.at.x + w <= narrow.size.x + 0.5, "%s runs off a 360 wide label" % d.text)
	check_eq(narrow.get_parsed_text(), text)
	narrow.size.x = 4000
	await tree.process_frame
	check_eq(narrow.drawn().filter(func(d): return d.has("radical")).size(), 1, "drawn again once there is room")
	wide.free()
	narrow.free()


func test_an_empty_part_keeps_its_place() -> void:
	# A typed fraction starts empty (FAL-812): its bar and its height must still be there.
	var f := MathBox.fraction(MathBox.row(), MathBox.row())
	f.layout(ThemeDB.fallback_font, UiTheme.BODY)
	var bars := f.drawn().filter(func(d): return d.has("bar"))
	check_eq(bars.size(), 1)
	check(bars[0].bar.size.x > 0.0, "an empty fraction still has a bar")
	check(f.asc > UiTheme.BODY * MathBox.INK_ASCENT and f.desc > UiTheme.BODY * MathBox.INK_DESCENT,
		"it is as tall as a fraction of digits")
	check(f.children[0].at.y < 0.0 and f.children[1].at.y > 0.0, "each part has its place")


func test_a_label_can_draw_a_tree_built_elsewhere() -> void:
	var m := MathLabel.new()
	m.box = MathBox.row([MathBox.text_box("x = "), MathBox.fraction(MathBox.parse("1"), MathBox.parse("2"))])
	tree.root.add_child(m)
	await tree.process_frame
	check_eq(_bars(m).size(), 1)
	check_eq(m.get_parsed_text(), "x = 1/2")
	m.free()


func test_it_wraps_at_spaces_but_never_inside_a_fraction() -> void:
	var text := "So the gradient of the line is m = (y₂ − y₁)/(x₂ − x₁) = (−7 − (−8))/(−5 − (−3)) = −1/2."
	var wide: MathLabel = await _label(text, 4000)
	var narrow: MathLabel = await _label(text, 360)
	check(narrow.get_combined_minimum_size().y > wide.get_combined_minimum_size().y * 2, "it wraps")
	check_eq(narrow.get_combined_minimum_size().x, 0.0, "no minimum width, as an autowrap label")
	var font := ThemeDB.fallback_font
	for d in narrow.drawn():
		if d.has("text"):
			var w := font.get_string_size(d.text, HORIZONTAL_ALIGNMENT_LEFT, -1, d.size).x
			check(d.at.x >= 0.0 and d.at.x + w <= narrow.size.x + 0.5, "%s runs off a 360 wide label" % d.text)
	# The top and the bottom of each fraction share a word, so they move together.
	var top := _piece(narrow, "y₂ − y₁")
	var bottom := _piece(narrow, "x₂ − x₁")
	check(bottom.at.y > top.at.y and bottom.at.y - top.at.y < UiTheme.BODY * 2, "the bottom is right under its top")
	check_eq(narrow.get_parsed_text(), text)
	wide.free()
	narrow.free()


func test_an_answer_choice_shows_its_fraction() -> void:
	var b := Button.new()
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.add_theme_font_size_override("font_size", UiTheme.BODY)
	UiTheme.math_button(b, "m = −1/2")
	tree.root.add_child(b)
	b.size = Vector2(800, 0)
	await tree.process_frame
	var m: MathLabel = b.get_node("Math")
	check_eq(b.text, "", "the button's own text is empty, so it isn't drawn twice")
	check_eq(UiTheme.button_text(b), "m = −1/2")
	check_eq(m.font_size(), UiTheme.BODY, "the button's font size")
	check(b.get_combined_minimum_size().y >= m.get_combined_minimum_size().y, "the button fits it")
	check_eq(m.mouse_filter, Control.MOUSE_FILTER_IGNORE, "a tap goes to the button")
	b.disabled = true
	b.add_theme_color_override("font_disabled_color", UiTheme.TEAL)
	check_eq(m._color(), UiTheme.TEAL, "the right answer's colour")
	var plain := Button.new()
	UiTheme.math_button(plain, "The limit does not exist")
	check_eq(plain.text, "The limit does not exist", "plain text stays the button's own")
	check_eq(plain.get_child_count(), 0)
	b.free()
	plain.free()


func test_feedback_can_be_recoloured_and_set_again() -> void:
	var m: MathLabel = await _label("", 800)
	m.text = "Not quite. The answer is m = −1/2."
	m.add_theme_color_override("font_color", UiTheme.PINK)
	await tree.process_frame
	check_eq(m._color(), UiTheme.PINK)
	check_eq(_bars(m).size(), 1)
	m.text = "Right!"
	check_eq(_bars(m).size(), 0)
	m.free()
