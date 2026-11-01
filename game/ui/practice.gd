extends Control
## The practice screen at /next/: the planner's questions one after another, with the
## answer slots or options, right or wrong feedback and the worked solution. No
## combat, timers or map yet; it is there to try the maths on a phone.
##
## A view can be asked for directly, which the screenshots and tests use:
##   web:      /next/?view=fn-quadratic-features/vertex-from-general/equation/complete-square/value&seed=3
##   desktop:  -- --view=fn-quadratic-features/... --seed=3
## Add autoplay=right (or wrong) to answer it at once and show the feedback and
## working. A probe view is type/probe/<index>.
##
## The map's region screen opens it on one region (launch_region): the planner then
## plans from that region's built types, and "Map" goes back to the region.

## Column width in base units: phone (portrait) and PC (landscape).
const COLUMN := 1000
const COLUMN_WIDE := 1500
## The answer keys (Keypad.ANSWER_KEYS): the calculator shares them (FAL-419).
const KEYS := Keypad.ANSWER_KEYS

## The region the map asked for, read once by _ready().
static var launch_region := ""

## Where the save lives. Tests point this somewhere else.
var save_path := SaveData.PATH
var save: Dictionary
var question: Dictionary = {}
var answered := false
## Plan from this region only ("" for every built type).
var practice_region := ""

var _slots := {}        # slot id -> LineEdit
var _picks := {}        # pick id -> chosen option ("" until chosen)
var _pick_buttons := {} # pick id -> Array of Buttons
var _choice := -1
var _choice_buttons: Array = []
var _focus: LineEdit

var margin: MarginContainer
var hud_gap: Control
var head: HBoxContainer
var title_label: Label
var exam_toggle: Button
var progress: Label
var scroll: ScrollContainer
var card: VBoxContainer
var check_button: Button
var next_button: Button
var feedback: Label
var working: VBoxContainer
## The in-game calculator (FAL-419), made the first time a Paper 2 question opens it.
var calculator: Calculator
var paper_box: HBoxContainer


func _ready() -> void:
	theme = UiTheme.make()
	if launch_region != "":
		practice_region = launch_region
		launch_region = ""
	_build()
	save = SaveData.load_from(save_path)
	exam_toggle.set_pressed_no_signal(save.settings.exam_only)
	exam_toggle.text = "Exam-style only: " + ("on" if save.settings.exam_only else "off")
	resized.connect(_fit)
	_fit()
	var deep := deep_link()
	if not deep.is_empty():
		show_view(deep.view)
		if deep.autoplay != "":
			autoplay(deep.autoplay == "right")
		open_from_link(url_args())
	else:
		next_question()


func _build() -> void:
	var bg := ColorRect.new()
	bg.color = UiTheme.BG
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	margin = MarginContainer.new()
	margin.name = "Margin"
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(margin)
	var col := VBoxContainer.new()
	col.name = "Column"
	col.add_theme_constant_override("separation", 18)
	margin.add_child(col)

	head = HBoxContainer.new()
	head.name = "Head"
	title_label = UiTheme.label("Practice", 84, UiTheme.TEAL)
	title_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	title_label.add_theme_font_override("font", UiTheme.TITLE_FONT)
	head.add_child(title_label)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(spacer)
	exam_toggle = Button.new()
	exam_toggle.name = "ExamOnly"
	exam_toggle.toggle_mode = true
	exam_toggle.text = "Exam-style only: off"
	exam_toggle.add_theme_font_size_override("font_size", UiTheme.SMALL)
	exam_toggle.toggled.connect(_on_exam_toggled)
	head.add_child(exam_toggle)
	# Keeps the toggle clear of the speaker and gear in the top-right corner.
	hud_gap = Control.new()
	hud_gap.name = "HudGap"
	hud_gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	head.add_child(hud_gap)
	col.add_child(head)
	var row := HBoxContainer.new()
	row.name = "ProgressRow"
	row.add_theme_constant_override("separation", 20)
	progress = UiTheme.label("", UiTheme.SMALL, UiTheme.DIM)
	progress.name = "Progress"
	progress.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(progress)
	var map := Button.new()
	map.name = "Map"
	map.text = "Map"
	map.add_theme_font_size_override("font_size", UiTheme.SMALL)
	map.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	map.pressed.connect(func():
		MapLink.go(get_tree(), MapLink.region_route(practice_region) if practice_region != "" else MapLink.WORLD))
	row.add_child(map)
	col.add_child(row)

	scroll = ScrollContainer.new()
	scroll.name = "Scroll"
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	col.add_child(scroll)
	card = VBoxContainer.new()
	card.name = "Card"
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_theme_constant_override("separation", 24)
	scroll.add_child(card)


func _fit() -> void:
	var col := COLUMN_WIDE if size.x > size.y else COLUMN
	var side := maxf(36.0, (size.x - col) / 2.0)
	margin.add_theme_constant_override("margin_left", int(side))
	margin.add_theme_constant_override("margin_right", int(side))
	margin.add_theme_constant_override("margin_top", 40)
	margin.add_theme_constant_override("margin_bottom", 30)
	hud_gap.custom_minimum_size.x = maxf(0.0, AudioHud.RESERVED_RIGHT - side)


func now() -> int:
	return int(Time.get_unix_time_from_system())


func next_question() -> void:
	var v := Planner.next(save, now(), {"region": practice_region} if practice_region != "" else {})
	SaveData.store(save, save_path)
	show_view(v)


## Shows the question for a view (a QuestionEngine view, or a probe view).
func show_view(view: Dictionary) -> void:
	if view.get("format") == "probe":
		question = QuestionEngine.probe(view.type, int(view.probe))
	else:
		question = QuestionEngine.make(view)
	render_question()


## Draws `question` on the card: the fight screen (ui/fight.gd) uses this too.
func render_question() -> void:
	_clear_card()
	_update_progress()
	if question.has("error"):
		card.add_child(UiTheme.label("Can't make that question: " + question.error, UiTheme.BODY, UiTheme.PINK))
		_add_next()
		return

	var meta := "%s · level %d" % [question.type_name, question.level]
	if question.get("exam", false):
		meta += " · exam style"
	if question.format == "probe":
		meta += " · concept"
	var meta_row := HBoxContainer.new()
	meta_row.name = "MetaRow"
	meta_row.add_theme_constant_override("separation", 16)
	var meta_label := UiTheme.label(meta, UiTheme.SMALL, UiTheme.DIM)
	meta_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	meta_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	meta_row.add_child(meta_label)
	paper_box = HBoxContainer.new()
	paper_box.name = "PaperBox"
	meta_row.add_child(paper_box)
	card.add_child(meta_row)
	show_paper()
	var prompt := UiTheme.label(question.prompt, UiTheme.BODY)
	prompt.name = "Prompt"
	card.add_child(prompt)

	if question.format != "probe":
		_add_representation()
	match question.format:
		"value":
			_add_slots()
		"probe":
			_add_options(question.options)
		"pick-the-graph":
			_add_graph_options()
		_:
			_add_options(question.choices.map(func(c): return c.text))
	check_button = Button.new()
	check_button.name = "Check"
	check_button.text = "Check"
	check_button.add_theme_font_size_override("font_size", UiTheme.BIG)
	check_button.pressed.connect(check_answer)
	card.add_child(check_button)
	feedback = UiTheme.label("", UiTheme.BODY)
	feedback.name = "Feedback"
	feedback.visible = false
	card.add_child(feedback)
	working = VBoxContainer.new()
	working.name = "Working"
	working.add_theme_constant_override("separation", 12)
	working.visible = false
	card.add_child(working)
	_add_next()


## Empties the card and forgets the last question's inputs.
func _clear_card() -> void:
	answered = false
	_slots.clear()
	_picks.clear()
	_pick_buttons.clear()
	_choice = -1
	_choice_buttons.clear()
	_focus = null
	for c in card.get_children():
		card.remove_child(c)
		c.queue_free()
	scroll.scroll_vertical = 0


func _add_next() -> void:
	next_button = Button.new()
	next_button.name = "Next"
	next_button.text = "Next question"
	next_button.add_theme_font_size_override("font_size", UiTheme.BIG)
	next_button.visible = question.has("error")
	next_button.pressed.connect(next_question)
	card.add_child(next_button)


func _add_representation() -> void:
	for line in question.lines:
		# A student's working (error-spot) reads as lines of text, not as the equation.
		var is_eq: bool = ((question.rep == "equation" and (line.begins_with("f(") or line.contains(" = "))) \
			or question.rep in ["notation", "terms"]) and not line.begins_with("Line ")
		var l := UiTheme.label(line, UiTheme.BIG if is_eq else UiTheme.BODY, UiTheme.SAND if is_eq else UiTheme.TEXT)
		if is_eq:
			l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		card.add_child(l)
	if question.graph != null:
		card.add_child(graph_for(question.graph))
	if question.table != null:
		card.add_child(_table(question.table))
	if question.get("diagram") != null:
		var d := TriangleView.new()
		d.name = "Diagram"
		d.set_spec(question.diagram)
		card.add_child(d)


## The view that draws a question's graph: PlotView for a graph with a "kind" (number
## line, normal curve, sin or cos, bars), else GraphView's parabola.
static func graph_for(spec: Dictionary) -> Control:
	var g: Control = PlotView.new() if spec.get("kind", "") != "" else GraphView.new()
	g.name = "Graph"
	g.set_spec(spec)
	return g


func _table(t: Dictionary) -> Control:
	var box := PanelContainer.new()
	box.name = "Table"
	box.add_theme_stylebox_override("panel", UiTheme.panel(Color(0.08, 0.1, 0.14)))
	var grid := GridContainer.new()
	# A table is x against f(x) (or its own heads, such as n and uₙ); a distribution's
	# comes as written rows.
	var heads: Array = t.get("heads", ["x", "f(x)"])
	var rows: Array = t.rows if t.has("rows") else [[heads[0], t.xs.map(func(v): return Fmt.num(v))], [heads[1], t.ys.map(func(v): return Fmt.num(v))]]
	grid.columns = rows[0][1].size() + 1
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 10)
	for row in rows:
		var head := UiTheme.label(row[0], UiTheme.BODY, UiTheme.SAND)
		head.autowrap_mode = TextServer.AUTOWRAP_OFF
		grid.add_child(head)
		for v in row[1]:
			var cell := UiTheme.label(v, UiTheme.BODY)
			cell.autowrap_mode = TextServer.AUTOWRAP_OFF
			cell.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			grid.add_child(cell)
	box.add_child(grid)
	return box


## The answer as slots: text with boxes to type numbers in and buttons for words.
func _add_slots() -> void:
	var flow := HFlowContainer.new()
	flow.name = "Slots"
	flow.add_theme_constant_override("h_separation", 8)
	flow.add_theme_constant_override("v_separation", 14)
	for item in question.answer.template:
		if item is String:
			if item != "":
				var l := UiTheme.label(item, UiTheme.BIG)
				l.autowrap_mode = TextServer.AUTOWRAP_OFF
				l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
				flow.add_child(l)
		elif item.has("slot"):
			var e := LineEdit.new()
			e.name = "Slot_" + item.slot
			e.custom_minimum_size = Vector2(150, 0)
			e.alignment = HORIZONTAL_ALIGNMENT_CENTER
			e.placeholder_text = "?"
			e.virtual_keyboard_enabled = false
			e.focus_entered.connect(func(): _focus = e)
			e.text_submitted.connect(func(_t): check_answer())
			flow.add_child(e)
			_slots[item.slot] = e
		else:
			var group := ButtonGroup.new()
			var buttons: Array = []
			_picks[item.pick] = ""
			for opt in item.options:
				var b := Button.new()
				b.text = opt
				b.toggle_mode = true
				b.button_group = group
				b.add_theme_font_size_override("font_size", UiTheme.BIG)
				b.pressed.connect(func(): _picks[item.pick] = opt)
				flow.add_child(b)
				buttons.append(b)
			_pick_buttons[item.pick] = buttons
	card.add_child(flow)
	if not _slots.is_empty():
		card.add_child(_keypad())
		_focus = _slots.values()[0]
		# Deferred, so the card may have been replaced by then.
		_grab.call_deferred(_focus)


func _grab(e: Variant) -> void:
	if is_instance_valid(e) and e.is_inside_tree():
		e.grab_focus()


## Number keys, so a phone needs no system keyboard: the keypad the calculator shares.
func _keypad() -> Control:
	var pad := Keypad.make()
	pad.key.connect(_on_key)
	return pad


func _on_key(k: String) -> void:
	if answered or _focus == null:
		return
	if k == "Del":
		_focus.text = _focus.text.left(-1)
	else:
		_focus.text += "-" if k == "−" else k
	_focus.caret_column = _focus.text.length()


func _add_options(texts: Array) -> void:
	var box := VBoxContainer.new()
	box.name = "Options"
	box.add_theme_constant_override("separation", 14)
	var group := ButtonGroup.new()
	for i in texts.size():
		var b := Button.new()
		b.text = texts[i]
		b.toggle_mode = true
		b.button_group = group
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.add_theme_font_size_override("font_size", UiTheme.BIG if question.format == "probe" else UiTheme.BODY)
		b.pressed.connect(func(): _choice = i)
		box.add_child(b)
		_choice_buttons.append(b)
	card.add_child(box)


## Pick the graph (Q13): the four graphs in a 2 × 2 grid, each card above its letter
## button. Tapping a card picks it too. Readable on a 360 px wide phone: each card is
## half the column, with fewer, larger labels (GraphView's card mode).
func _add_graph_options() -> void:
	var grid := GridContainer.new()
	grid.name = "GraphOptions"
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 18)
	var group := ButtonGroup.new()
	for i in question.choices.size():
		var cell := VBoxContainer.new()
		cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cell.add_theme_constant_override("separation", 6)
		var g := GraphView.new()
		g.name = "Card%d" % i
		g.custom_minimum_size = Vector2(0, 430)
		g.mouse_filter = Control.MOUSE_FILTER_STOP
		g.set_spec(question.graphs[i])
		var b := Button.new()
		b.text = question.choices[i].text
		b.toggle_mode = true
		b.button_group = group
		b.add_theme_font_size_override("font_size", UiTheme.BODY)
		b.pressed.connect(func(): _choice = i)
		g.gui_input.connect(func(e: InputEvent):
			if e is InputEventMouseButton and e.pressed and not b.disabled:
				b.button_pressed = true
				_choice = i)
		cell.add_child(g)
		cell.add_child(b)
		grid.add_child(cell)
		_choice_buttons.append(b)
	card.add_child(grid)


## Marks the answer, records it in the save and shows the feedback and working.
func check_answer() -> void:
	if answered or question.is_empty() or question.has("error"):
		return
	var result: Dictionary
	match question.format:
		"value":
			var response := {}
			for id in _slots:
				response[id] = _slots[id].text
			for id in _picks:
				response[id] = _picks[id]
			result = QuestionEngine.mark(question, response)
		"probe":
			if _choice < 0:
				result = {"complete": false, "errors": {"choice": "Choose one."}}
			else:
				result = QuestionEngine.mark_probe(question, question.options[_choice])
		_:
			result = QuestionEngine.mark(question, {"choice": _choice})
	feedback.visible = true
	if not result.complete:
		var msgs: Array = result.errors.values()
		feedback.text = msgs[0] if msgs.size() == 1 else "Fill in every box."
		feedback.add_theme_color_override("font_color", UiTheme.SAND)
		return
	answered = true
	_record(result)
	_show_feedback(result)
	_update_progress()
	check_button.visible = false
	next_button.visible = true
	for e in _slots.values():
		e.editable = false
	for b in _choice_buttons:
		b.disabled = true
	for bs in _pick_buttons.values():
		for b in bs:
			b.disabled = true


## Keeps the answer in the save, for the planner. The explorer screen keeps nothing.
func _record(result: Dictionary) -> void:
	SaveData.record(save, question.cell, result.correct, now(), result.get("misconception", ""), question.format == "probe")
	SaveData.store(save, save_path)


func _show_feedback(result: Dictionary) -> void:
	var probe: bool = question.format == "probe"
	if result.correct:
		feedback.text = "Right!" if not probe or question.verdict != "" else "Good. Compare with this answer:"
		feedback.add_theme_color_override("font_color", UiTheme.TEAL)
	else:
		if probe:
			feedback.text = "Not quite." if question.verdict != "" else "Here is the answer:"
		else:
			feedback.text = "Not quite. The answer is %s." % right_text(question)
		feedback.add_theme_color_override("font_color", UiTheme.PINK)
		var why := QuestionEngine.misconception_text(QuestionEngine.type_of(question.view.type), result.get("misconception", ""))
		if why != "":
			feedback.text += "\nWatch out: " + why + "."
	# An error-spot, method-pick or true-false-reason question says why.
	if question.has("reason"):
		feedback.text += "\n" + question.reason
	if question.format == "probe" or QuestionEngine.is_choice(question):
		for i in _choice_buttons.size():
			var right_option: bool = question.choices[i].correct if question.format != "probe" else question.options[i] == question.verdict
			if right_option:
				_choice_buttons[i].add_theme_color_override("font_disabled_color", UiTheme.TEAL)
			elif i == _choice:
				_choice_buttons[i].add_theme_color_override("font_disabled_color", UiTheme.PINK)
	_show_working()


## The right answer as feedback names it: the answer, or for an extra format the right
## option (Line 3, a method, True).
static func right_text(q: Dictionary) -> String:
	if q.format in QuestionEngine.EXTRA_FORMATS:
		for c in q.choices:
			if c.correct:
				return c.text
	return q.answer_text


## The worked solution, with a tab per method (or a probe's reveal).
func _show_working() -> void:
	working.visible = true
	if question.format == "probe":
		working.add_child(UiTheme.label(question.reveal, UiTheme.BODY))
		return
	working.add_child(UiTheme.label("Worked solution", UiTheme.BIG, UiTheme.SAND))
	var tabs := VBoxContainer.new()
	tabs.name = "Methods"
	tabs.add_theme_constant_override("separation", 10)
	var steps := VBoxContainer.new()
	steps.name = "Steps"
	steps.add_theme_constant_override("separation", 10)
	var group := ButtonGroup.new()
	for i in question.solutions.size():
		var sol: Dictionary = question.solutions[i]
		var b := Button.new()
		b.text = sol.name if i == 0 else "Another way: " + sol.name
		b.toggle_mode = true
		b.button_group = group
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.add_theme_font_size_override("font_size", UiTheme.SMALL)
		b.pressed.connect(_show_steps.bind(steps, i))
		tabs.add_child(b)
		if i == 0:
			b.button_pressed = true
	if question.solutions.size() > 1:
		working.add_child(tabs)
	working.add_child(steps)
	_show_steps(steps, 0)


func _show_steps(box: VBoxContainer, i: int) -> void:
	for c in box.get_children():
		box.remove_child(c)
		c.queue_free()
	var sol: Dictionary = question.solutions[i]
	box.add_child(UiTheme.label(sol.name, UiTheme.SMALL, UiTheme.DIM))
	for st in sol.steps:
		box.add_child(UiTheme.label(Step.text(st), UiTheme.BODY))


func _update_progress() -> void:
	var pool := QuestionEngine.cells(save.settings.exam_only, Dungeon.region_types(practice_region) if practice_region != "" else [])
	var seen := 0
	var right := 0
	for c in pool:
		var r: Dictionary = save.cells.get(c.key, {})
		if r.get("seen", 0) > 0:
			seen += 1
			if r.get("last_result") == "right":
				right += 1
	progress.text = ("%s · " % Dungeon.region_name(practice_region) if practice_region != "" else "") + \
		"%d of %d checked · %d right last time" % [seen, pool.size(), right]


func _on_exam_toggled(on: bool) -> void:
	save.settings.exam_only = on
	exam_toggle.text = "Exam-style only: " + ("on" if on else "off")
	SaveData.store(save, save_path)
	_update_progress()


## Answers the question at once, right or wrong (screenshots and tests).
func autoplay(right: bool) -> void:
	if question.is_empty() or question.has("error"):
		return
	match question.format:
		"value":
			var values: Dictionary = question.answer.values
			if not right:
				for c in question.choices:
					if not c.correct:
						values = c.values
						if c.ref != "":
							break
			for id in _slots:
				# A measure is typed as a student would, to 3 s.f., and a decimal or money as written.
				if question.answer.kind == "measure":
					_slots[id].text = Fmt.sf(values[id]).replace("−", "-")
				elif question.answer.get("show", "") != "":
					_slots[id].text = Answer.shown(question.answer, values[id]).replace("−", "-")
				else:
					_slots[id].text = Answer.export_values({id: values[id]})[id]
			for id in _picks:
				_picks[id] = values[id]
				for b in _pick_buttons[id]:
					b.button_pressed = b.text == values[id]
		_:
			var pick := -1
			var items: Array = question.choices if question.format != "probe" else question.options
			for i in items.size():
				var ok: bool = question.choices[i].correct if question.format != "probe" else items[i] == question.verdict or (question.verdict == "" and i == 0)
				if ok == right and pick < 0:
					pick = i
			# A wrong answer picks a misconception's option when there is one.
			if not right and question.format != "probe":
				for i in items.size():
					if question.choices[i].ref != "":
						pick = i
						break
			if pick < 0:
				pick = 0
			_choice_buttons[pick].button_pressed = true
			_choice = pick
	check_answer()


# ── Paper 1 or 2, and the calculator (FAL-419) ───────────────

## Where the paper badge goes: the card's top row here; the fight screen keeps its own
## slot in the lifeline row.
func paper_slot() -> Control:
	return paper_box


## The question's paper as a badge: "No calculator" on Paper 1, and on Paper 2 a
## "Calculator" badge that is the button that opens the calculator. A question with no
## paper (an error) shows none. Moving to a Paper 1 question closes the calculator.
func show_paper() -> void:
	var slot := paper_slot()
	if slot == null:
		return
	for c in slot.get_children():
		slot.remove_child(c)
		c.queue_free()
	var paper := int(question.get("paper", 0))
	if paper != 2 and calculator != null:
		calculator.close()
	if paper == 2:
		var b := Button.new()
		b.name = "CalculatorButton"
		b.text = "Calculator"
		b.tooltip_text = "Paper 2: open the calculator. The clock keeps running."
		b.add_theme_font_override("font", UiTheme.TITLE_FONT)
		b.add_theme_font_size_override("font_size", UiTheme.SMALL + 4)
		var sb := UiTheme.panel(Color(UiTheme.TEAL, 0.18))
		sb.border_color = UiTheme.TEAL
		sb.set_border_width_all(3)
		sb.content_margin_top = 10
		sb.content_margin_bottom = 10
		sb.content_margin_left = 18
		sb.content_margin_right = 18
		for state in ["normal", "hover", "pressed", "focus"]:
			b.add_theme_stylebox_override(state, sb)
		b.add_theme_color_override("font_color", UiTheme.TEAL)
		b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		b.pressed.connect(open_calculator)
		slot.add_child(b)
	elif paper == 1:
		var l := UiTheme.label("No calculator", UiTheme.SMALL, UiTheme.DIM)
		l.name = "NoCalculator"
		l.autowrap_mode = TextServer.AUTOWRAP_OFF
		l.add_theme_font_override("font", UiTheme.TITLE_FONT)
		l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		slot.add_child(l)


## Opens the calculator over the screen, in `mode` ("sci" or "graph"; as it was if
## ""). Only a Paper 2 question can. Nothing stops: the clock keeps running.
func open_calculator(mode: String = "") -> void:
	if int(question.get("paper", 0)) != 2:
		return
	if calculator == null:
		calculator = Calculator.make()
		add_child(calculator)
	calculator.open(mode)


## Opens the calculator from a link, for screenshots: &calc=sci or &calc=graph, with
## &y1=, &y2=, &win=xmin,xmax,ymin,ymax, &tool=zero|max|min|intersect and &deg=1.
## In Scientific mode, &do=expr;expr works each one out in turn.
func open_from_link(args: Dictionary) -> void:
	if not args.has("calc"):
		return
	open_calculator("graph" if args.calc == "graph" else "sci")
	if calculator == null or not calculator.visible:
		return
	calculator.set_angle(args.get("deg", "") == "1")
	for line in str(args.get("do", "")).split(";", false):
		calculator.input.text = line
		calculator.evaluate()
	for i in 2:
		if args.has("y%d" % (i + 1)):
			calculator.fn_edits[i].text = args["y%d" % (i + 1)]
	calculator._refresh_graph()
	var win: PackedStringArray = str(args.get("win", "")).split(",")
	if win.size() == 4:
		calculator.graph.set_window(win[0].to_float(), win[1].to_float(), win[2].to_float(), win[3].to_float())
	if args.has("tool"):
		calculator.use_tool(args.tool)


## The URL's query (web) and the command line's --key=value arguments. A bare key
## (?explore, --explore) is there with the value "".
static func url_args() -> Dictionary:
	var args := {}
	if OS.has_feature("web"):
		var search = JavaScriptBridge.eval("window.location.search", true)
		if search is String and search.length() > 1:
			for part in search.substr(1).split("&"):
				var kv: PackedStringArray = part.split("=", true, 1)
				if kv[0] != "":
					args[kv[0].uri_decode()] = kv[1].uri_decode() if kv.size() == 2 else ""
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--"):
			var kv := a.substr(2).split("=", true, 1)
			args[kv[0]] = kv[1] if kv.size() == 2 else ""
	return args


## A view asked for in the URL (web) or on the command line, or {}.
static func deep_link() -> Dictionary:
	return view_from(url_args())


static func view_from(args: Dictionary) -> Dictionary:
	if not args.has("view"):
		return {}
	var p: PackedStringArray = args.view.split("/")
	var view := {}
	if p.size() >= 3 and p[1] == "probe":
		view = {"type": p[0], "probe": int(p[2]), "format": "probe"}
	elif p.size() >= 4:
		view = {"type": p[0], "unknown": p[1], "rep": p[2], "angle": p[3], "format": p[4] if p.size() > 4 else "value",
			"seed": int(args.get("seed", "1"))}
		if args.has("paper"):
			view.paper = int(args.paper)
	else:
		return {}
	return {"view": view, "autoplay": args.get("autoplay", "")}
