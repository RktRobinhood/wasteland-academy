extends "res://tests/test_case.gd"
## The answer box typed in maths notation (FAL-812): key sequences give text that
## Answer.parse_number reads as the one-line form, and code that sets text builds the
## same tree.


func _typed(keys: Array) -> MathEntry:
	var e := MathEntry.new()
	for k in keys:
		e.press(k)
	return e


## The keys' text, its value, and that it is the value of the one-line form.
func _same(keys: Array, text: String, line: String) -> void:
	var e := _typed(keys)
	check_eq(e.text, text, str(keys))
	var a := Answer.parse_number(e.text)
	var b := Answer.parse_number(line)
	check(a.ok and b.ok, "%s and %s both read" % [e.text, line])
	if a.ok and b.ok:
		check(a.q.eq(b.q), "%s is %s" % [e.text, line])
		check_eq(a.decimal, b.decimal, "%s: decimal as %s" % [e.text, line])
	e.free()


func test_key_sequences_give_the_one_line_value() -> void:
	_same(["3", "/", "4"], "(3)/(4)", "3/4")
	_same(["−", "3", "/", "4"], "-(3)/(4)", "-3/4")
	_same(["3", "/", "−", "4"], "(3)/(-4)", "3/-4")
	_same(["0", ".", "5", "/", "2"], "(0.5)/(2)", "0.5/2")
	# A fraction inside a top: the fraction key twice, then ▶ out of the inner bottom.
	_same(["/", "/", "1", "▶", "2", "▶", "▶", "3"], "((1)/(2))/(3)", "(1/2)/3")
	_same(["1", "/", "2", "▶", "+", "1"], "(1)/(2)+1", "1/2+1")
	_same(["1", "2", "Del", "5"], "15", "15")


func test_the_fraction_key_takes_the_number_before_the_cursor() -> void:
	var e := _typed(["1", "2", "/"])
	check_eq(e.root.children.size(), 1, "one fraction")
	check_eq(e.root.children[0].children[0].to_text(), "12", "the number is the top")
	check(e.row == e.root.children[0].children[1], "the cursor is in the bottom")
	e.free()
	e = _typed(["1", "+", "/"])
	check_eq(e.text, "1+()/()", "nothing to take: an empty fraction")
	check(e.row == e.root.children[2].children[0], "the cursor is in the top")
	e.free()


func test_del_at_the_start_of_an_empty_bottom_removes_the_fraction() -> void:
	var e := _typed(["3", "/", "Del"])
	check_eq(e.text, "3", "the top stays")
	check(e.row == e.root and e.at == 1, "the cursor after it")
	e.press("4")
	check_eq(e.text, "34")
	e.free()
	e = _typed(["/", "Del"])
	check_eq(e.text, "", "an empty fraction goes")
	e.free()
	# Del after a fraction goes into its bottom first.
	e = _typed(["3", "/", "4", "▶", "Del"])
	check_eq(e.text, "(3)/(4)", "nothing deleted yet")
	e.press("Del")
	e.press("Del")
	check_eq(e.text, "3", "then the bottom, then the fraction")
	e.free()


func test_arrows_move_through_top_bottom_and_out() -> void:
	var e := _typed(["5", "+", "/", "1", "▶", "2"])
	check_eq(e.text, "5+(1)/(2)")
	e.move_vertical(false)
	check(e.row == e.root.children[2].children[0], "↑ goes to the top")
	e.move_vertical(true)
	check(e.row == e.root.children[2].children[1], "↓ to the bottom")
	e.press("▶")
	check(e.row == e.root and e.at == 3, "▶ at the end of the bottom goes out")
	e.press("◀")
	check(e.row == e.root.children[2].children[1] and e.at == 1, "◀ goes back into the bottom")
	e.press("◀")
	e.press("◀")
	check(e.row == e.root.children[2].children[0] and e.at == 1, "◀ from the bottom to the end of the top")
	e.press("◀")
	e.press("◀")
	check(e.row == e.root and e.at == 2, "◀ out before the fraction")
	e.free()


func test_minus_shows_as_a_true_minus() -> void:
	var e := _typed(["−", "3"])
	check_eq(e.root.children[0].text, "−", "shown")
	check_eq(e.text, "-3", "read")
	e.free()


func test_setting_text_builds_the_tree() -> void:
	for s in ["3/2", "-3/4", "3/-4", "(3)/(4)", "-(3)/(4)", "((1)/(2))/(3)", "1/2/3", "0.5/2", "1.25", "2(3+1)", "12"]:
		var e := MathEntry.new()
		e.text = s
		var a := Answer.parse_number(e.text)
		var b := Answer.parse_number(s)
		check(a.ok and a.q.eq(b.q), "%s set reads as %s" % [s, e.text])
		e.free()
	var f := MathEntry.new()
	f.text = "3/2"
	check_eq(f.root.children.size(), 1, "3/2 is one box")
	check_eq(f.root.children[0].kind, MathBox.Kind.FRACTION, "a stacked fraction")
	check_eq(f.text, "(3)/(2)")
	f.text = "-3/4"
	check_eq(f.root.children[0].text, "−", "the sign stays in front")
	check_eq(f.root.children[1].kind, MathBox.Kind.FRACTION)
	f.free()


func test_a_box_stops_at_its_limit() -> void:
	var e := MathEntry.new()
	e.max_length = 5
	e.text = "1234567"
	check_eq(e.text, "12345", "set")
	e.clear()
	for k in "1234567":
		e.press(k)
	check_eq(e.text, "12345", "typed")
	e.free()


func test_it_draws_dashed_parts_and_takes_a_tap() -> void:
	var e := MathEntry.new()
	tree.root.add_child(e)
	e.press("/")
	await tree.process_frame
	check_eq(e._empty.size(), 2, "two empty parts")
	e.press("7")
	check_eq(e._empty.size(), 1, "one left")
	check(e.get_combined_minimum_size().y > 0, "it has a height")
	# A tap in the bottom's box puts the cursor there.
	var bottom: Dictionary = e.places().filter(func(p): return p.row == e.root.children[0].children[1])[0]
	e.tap_at(Vector2(bottom.xs[0], bottom.y - 4))
	check(e.row == e.root.children[0].children[1], "tapped into the bottom")
	e.press("8")
	check_eq(e.text, "(7)/(8)")
	e.free()


func test_enter_submits() -> void:
	var e := MathEntry.new()
	tree.root.add_child(e)
	var got := []
	e.text_submitted.connect(func(t): got.append(t))
	e.press("4")
	var k := InputEventKey.new()
	k.keycode = KEY_ENTER
	k.pressed = true
	e._gui_input(k)
	check_eq(got, ["4"])
	var slash := InputEventKey.new()
	slash.keycode = KEY_SLASH
	slash.unicode = "/".unicode_at(0)
	slash.pressed = true
	e._gui_input(slash)
	e.press("5")
	check_eq(e.text, "(4)/(5)", "/ on a keyboard is the fraction key")
	e.free()


func test_the_arrow_keys_have_glyphs() -> void:
	check_eq(UiTheme.missing_glyphs("◀▶"), "", "◀ ▶")
