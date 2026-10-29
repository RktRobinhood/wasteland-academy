extends "res://tests/test_case.gd"
## The in-game calculator (FAL-419): the Calculator button only on Paper 2 questions,
## Scientific mode (keys, recent results, Ans, degrees, 6 s.f.), Graph mode (two
## functions and the four tools, with marks), the clock running and nothing spent while
## it is open, its art slots with the coded fallback, and a 360 px phone.

const PRACTICE := "res://scenes/practice.tscn"
const FIGHT := "res://scenes/fight.tscn"
const SAVE := "user://test_calculator_save.json"
## Paper 2 only, and Paper 1 only, in the exam.
const P2 := {"type": "fn-exponential-model", "unknown": "predict-value", "rep": "equation", "angle": "substitute-model",
	"format": "value", "seed": 3}
const P1 := {"type": "fn-quadratic-features", "unknown": "vertex-form-from-general", "rep": "equation",
	"angle": "complete-square", "format": "value", "seed": 2}


func _area(window: Vector2i) -> Vector2:
	var base := Vector2(1080, 1920)
	var scale := minf(window.x / base.x, window.y / base.y)
	return Vector2(window) / scale


func _practice(area: Vector2) -> Array:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE))
	var frame := Control.new()
	frame.size = area
	tree.root.add_child(frame)
	var p: Control = (load(PRACTICE) as PackedScene).instantiate()
	p.save_path = SAVE
	frame.add_child(p)
	await tree.process_frame
	return [frame, p]


func _done(made: Array) -> void:
	made[0].free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE))


func _calc() -> Calculator:
	var c := Calculator.make()
	c.size = Vector2(1080, 1920)
	return c


func _type(c: Calculator, keys: Array) -> void:
	for k in keys:
		c.press(k)


func test_the_button_is_hidden_on_paper_1_questions() -> void:
	var made: Array = await _practice(_area(Vector2i(390, 844)))
	var p: Control = made[1]
	p.show_view(P1)
	await tree.process_frame
	check_eq(p.question.paper, 1)
	check(p.paper_slot().get_node_or_null("CalculatorButton") == null, "no Calculator button on Paper 1")
	check(p.paper_slot().get_node_or_null("NoCalculator") != null, "a No calculator badge on Paper 1")
	p.open_calculator()
	check(p.calculator == null or not p.calculator.visible, "Paper 1 can't open it")
	p.show_view(P2)
	await tree.process_frame
	check_eq(p.question.paper, 2)
	var b: Button = p.paper_slot().get_node_or_null("CalculatorButton")
	check(b != null, "a Calculator button on Paper 2")
	b.pressed.emit()
	check(p.calculator != null and p.calculator.visible, "it opens the calculator")
	# A Paper 1 question next closes it and hides the button.
	p.show_view(P1)
	await tree.process_frame
	check(not p.calculator.visible, "closed on the next Paper 1 question")
	check(p.paper_slot().get_node_or_null("CalculatorButton") == null)
	_done(made)


func test_scientific_mode() -> void:
	var c := _calc()
	tree.root.add_child(c)
	c.open("sci")
	_type(c, ["2", "^", "3", "^", "2", "EXE"])
	check_eq(c.history[-1].text, "512", "2^3^2")
	_type(c, ["Ans", "/", "1", "0", "0", "0", "EXE"])
	check_eq(c.history[-1].text, "0.512", "Ans")
	_type(c, ["−", "3", "^", "2", "EXE"])
	check_eq(c.history[-1].text, "−9", "−3^2")
	_type(c, ["√", "2", ")", "EXE"])
	check_eq(c.history[-1].text, "1.41421", "6 s.f.")
	c.set_angle(true)
	_type(c, ["sin", "3", "0", ")", "EXE"])
	check_eq(c.history[-1].text, "0.5", "sin 30° in degrees")
	c.set_angle(false)
	_type(c, ["ln", "e", ")", "EXE"])
	check_eq(c.history[-1].text, "1", "ln e")
	_type(c, ["2", "π", "EXE"])
	check_eq(c.history[-1].text, "6.28319", "2π")
	# A recent result taps back into the line.
	var rows := c.history_box.get_children().filter(func(n): return n is Button)
	(rows[3] as Button).pressed.emit()
	check_eq(c.input.text, "1.41421", "a recent result is used again")
	c.input.text = "print(1)"
	check(is_nan(c.evaluate()) and c.message.visible, "not maths: a message, nothing run")
	check(c.keypad.buttons["x"].disabled, "x is for graphs only")
	c.free()


func test_six_significant_figures() -> void:
	var cases := {0.0: "0", 512.0: "512", 2.0 / 3.0: "0.666667", -1.0 / 3.0: "−0.333333", 1234567.0: "1234570",
		0.000123456789: "0.000123457", 1.0e12: "1E12", 6.02214076e23: "6.02214E23", 1.5e-7: "1.5E−7", 999999.7: "1000000"}
	for v in cases:
		check_eq(CalcFormat.sf6(v), cases[v], str(v))


func test_graph_mode_tools_mark_points() -> void:
	var c := _calc()
	tree.root.add_child(c)
	c.open("graph")
	c.fn_edits[0].text = "x^2"
	c.fn_edits[1].text = "2x+3"
	c._refresh_graph()
	var pts := c.use_tool("intersect")
	check_eq(pts.size(), 2, "x² meets 2x + 3 twice")
	check_eq(c.graph.marks.size(), 2, "both marked")
	check(c.readout.text.contains("x = −1") and c.readout.text.contains("x = 3, y = 9"), c.readout.text)
	check_eq(c.use_tool("min").size(), 1, "x² has one minimum")
	c._set_target(1)
	check_eq(c.use_tool("zero").size(), 1, "2x + 3 has one zero")
	check(c.readout.text.contains("−1.5"), c.readout.text)
	# A model reaching a level: the "when does it reach" tool.
	c.fn_edits[0].text = "5000e^(-0.2x)"
	c.fn_edits[1].text = "1000"
	c._refresh_graph()
	c.graph.set_window(0, 20, -500, 6000)
	var meet := c.use_tool("intersect")
	check(meet.size() == 1 and CalcFormat.sf6(meet[0].x) == "8.04719", str(meet))
	# A pole is a gap, not a zero.
	c.fn_edits[0].text = "1/x"
	c.fn_edits[1].text = ""
	c._set_target(0)
	c._refresh_graph()
	c.graph.set_window(-10, 10, -10, 10)
	check(c.use_tool("zero").is_empty(), "1/x has no zero")
	c.fn_edits[0].text = "2x+"
	c._refresh_graph()
	check(c.message.visible, "a line that doesn't read says so")
	c.free()


func test_pan_zoom_and_trace() -> void:
	var c := _calc()
	tree.root.add_child(c)
	c.open("graph")
	await tree.process_frame
	c.fn_edits[0].text = "x^3-x"
	c._refresh_graph()
	c.graph.zoom(0.5)
	check(is_equal_approx(c.graph.x_max - c.graph.x_min, 10.0), "zoomed in")
	c.graph.pan(Vector2(c.graph.size.x / 10.0, 0))
	check(c.graph.x_min < -5.0, "panned")
	c.graph.trace_at(0, 2.0)
	check(c.readout.text.contains("y = 6"), c.readout.text)
	c.free()


func test_the_clock_runs_and_it_costs_nothing() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE))
	var frame := Control.new()
	frame.size = _area(Vector2i(390, 844))
	tree.root.add_child(frame)
	var f: Control = (load(FIGHT) as PackedScene).instantiate()
	f.save_path = SAVE
	f.run_seed = 3
	f.select_first = false
	frame.add_child(f)
	await tree.process_frame
	f.run.question.paper = 2
	f._show_question()
	var b: Button = f.paper_slot().get_node_or_null("CalculatorButton")
	check(b != null, "the Calculator button in the lifeline row")
	var charges: Dictionary = f.run.lifelines.duplicate(true)
	var stats: Dictionary = f.run.stats.duplicate(true)
	var hp: int = f.run.hp
	var before: float = f.run.time_left
	b.pressed.emit()
	check(f.calculator.visible)
	f._process(5.0)
	check(f.run.time_left <= before - 4.99, "the clock keeps running: %s then %s" % [before, f.run.time_left])
	check_eq(f.run.lifelines, charges, "no lifeline spent")
	check_eq(f.run.stats, stats, "no Scrap or answer counted")
	check_eq(f.run.hp, hp, "no HP")
	check_eq(f.run.state, "question", "still the same question")
	frame.free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE))


func test_fits_a_360_phone_and_a_pc() -> void:
	for window in [Vector2i(360, 780), Vector2i(390, 844), Vector2i(1280, 800)]:
		var made: Array = await _practice(_area(window))
		var p: Control = made[1]
		p.show_view(P2)
		await tree.process_frame
		for m in ["sci", "graph"]:
			p.open_calculator(m)
			await tree.process_frame
			await tree.process_frame
			var area := Rect2(Vector2.ZERO, p.size)
			var box := Rect2(p.calculator.casing.position, p.calculator.casing.size)
			check(area.encloses(box), "%s %s: the calculator %s fits %s" % [window, m, box, area])
		_done(made)


func test_coded_look_without_art_and_art_when_there() -> void:
	var c := _calc()
	check(c.casing.get_theme_stylebox("panel") is StyleBoxFlat, "the coded casing")
	check(c.casing.get_node_or_null("Rivets") != null, "rivets drawn in code")
	c.free()
	var root := ArtSlots.root
	ArtSlots.root = "res://tests/fixtures/art/"
	var art := _calc()
	var has_fixture := ArtSlots.find(Calculator.ART + "casing") != ""
	if has_fixture:
		check(art.casing.get_theme_stylebox("panel") is StyleBoxTexture, "the casing art")
		check(art.casing.get_node_or_null("Rivets") == null, "no coded rivets over art")
		check(art.keypad.buttons["7"].get_theme_stylebox("normal") is StyleBoxTexture, "the key art")
	else:
		fail("tests/fixtures/art/ui/calculator/ has no casing fixture")
	art.free()
	ArtSlots.root = root


## Each licence notice is at the top of the file that uses it and in the game's credits,
## which the title screen opens.
func test_licences_in_the_files_and_the_credits() -> void:
	var expr := FileAccess.get_file_as_string("res://engine/expr.gd")
	var brent := FileAccess.get_file_as_string("res://engine/brent.gd")
	check(expr.find("Lewis Van Winkle") < 1500 and expr.contains("ALTERED SOURCE"), "TinyExpr's zlib notice heads expr.gd, marked altered")
	check(brent.find("Redistribution and use in source and binary forms") < 2500, "SciPy's BSD-3 notice heads brent.gd")
	var all := ""
	for s in Credits.sections():
		all += "%s %s %s\n" % [s.what, s.licence, s.notice]
	for want in ["TinyExpr", "zlib", "This notice may not be removed", "SciPy", "BSD-3-Clause",
			"Neither the name of the copyright holder", "Open Font License", "MIT"]:
		check(all.contains(want), "the credits have %s" % want)
	var main: Control = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	tree.root.add_child(main)
	await tree.process_frame
	var link: LinkButton = main.get_node_or_null("CreditsLink")
	check(link != null, "a Credits link on the title screen")
	if link != null:
		link.pressed.emit()
		var c := main.get_node_or_null("Credits")
		check(c != null, "the credits open")
	main.free()
