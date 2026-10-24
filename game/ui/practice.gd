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

## Column width in base units: phone (portrait) and PC (landscape).
const COLUMN := 1000
const COLUMN_WIDE := 1500
const KEYS := ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0", ".", "/", "−", "⌫"]

## Where the save lives. Tests point this somewhere else.
var save_path := SaveData.PATH
var save: Dictionary
var question: Dictionary = {}
var answered := false

var _slots := {}        # slot id -> LineEdit
var _picks := {}        # pick id -> chosen option ("" until chosen)
var _pick_buttons := {} # pick id -> Array of Buttons
var _choice := -1
var _choice_buttons: Array = []
var _focus: LineEdit

var margin: MarginContainer
var exam_toggle: Button
var progress: Label
var scroll: ScrollContainer
var card: VBoxContainer
var check_button: Button
var next_button: Button
var feedback: Label
var working: VBoxContainer


func _ready() -> void:
	theme = UiTheme.make()
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

	var head := HBoxContainer.new()
	var title := UiTheme.label("Practice", 84, UiTheme.TEAL)
	title.autowrap_mode = TextServer.AUTOWRAP_OFF
	title.add_theme_font_override("font", UiTheme.TITLE_FONT)
	head.add_child(title)
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
	col.add_child(head)
	progress = UiTheme.label("", UiTheme.SMALL, UiTheme.DIM)
	progress.name = "Progress"
	col.add_child(progress)

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


func now() -> int:
	return int(Time.get_unix_time_from_system())


func next_question() -> void:
	var v := Planner.next(save, now())
	SaveData.store(save, save_path)
	show_view(v)


## Shows the question for a view (a QuestionEngine view, or a probe view).
func show_view(view: Dictionary) -> void:
	if view.get("format") == "probe":
		question = QuestionEngine.probe(view.type, int(view.probe))
	else:
		question = QuestionEngine.make(view)
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
	card.add_child(UiTheme.label(meta, UiTheme.SMALL, UiTheme.DIM))
	var prompt := UiTheme.label(question.prompt, UiTheme.BODY)
	prompt.name = "Prompt"
	card.add_child(prompt)

	if question.format != "probe":
		_add_representation()
	match question.format:
		"value":
			_add_slots()
		"mcq":
			_add_options(question.choices.map(func(c): return c.text))
		"probe":
			_add_options(question.options)
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
		var is_eq: bool = question.rep == "equation" and (line.begins_with("f(") or line.contains(" = "))
		var l := UiTheme.label(line, UiTheme.BIG if is_eq else UiTheme.BODY, UiTheme.SAND if is_eq else UiTheme.TEXT)
		if is_eq:
			l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		card.add_child(l)
	if question.graph != null:
		var g := GraphView.new()
		g.name = "Graph"
		g.set_spec(question.graph)
		card.add_child(g)
	if question.table != null:
		card.add_child(_table(question.table))


func _table(t: Dictionary) -> Control:
	var box := PanelContainer.new()
	box.name = "Table"
	box.add_theme_stylebox_override("panel", UiTheme.panel(Color(0.08, 0.1, 0.14)))
	var grid := GridContainer.new()
	grid.columns = t.xs.size() + 1
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 10)
	for row in [["x", t.xs], ["f(x)", t.ys]]:
		var head := UiTheme.label(row[0], UiTheme.BODY, UiTheme.SAND)
		head.autowrap_mode = TextServer.AUTOWRAP_OFF
		grid.add_child(head)
		for v in row[1]:
			var cell := UiTheme.label(Fmt.num(v), UiTheme.BODY)
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
		_focus.call_deferred("grab_focus")


## Number keys, so a phone needs no system keyboard.
func _keypad() -> Control:
	var grid := GridContainer.new()
	grid.name = "Keypad"
	grid.columns = 7
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	for k in KEYS:
		var b := Button.new()
		b.text = k
		b.focus_mode = Control.FOCUS_NONE
		b.custom_minimum_size = Vector2(120, 104)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.add_theme_font_size_override("font_size", UiTheme.BIG)
		b.pressed.connect(_on_key.bind(k))
		grid.add_child(b)
	return grid


func _on_key(k: String) -> void:
	if answered or _focus == null:
		return
	if k == "⌫":
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
		"mcq":
			result = QuestionEngine.mark(question, {"choice": _choice})
		"probe":
			if _choice < 0:
				result = {"complete": false, "errors": {"choice": "Choose one."}}
			else:
				result = QuestionEngine.mark_probe(question, question.options[_choice])
	feedback.visible = true
	if not result.complete:
		var msgs: Array = result.errors.values()
		feedback.text = msgs[0] if msgs.size() == 1 else "Fill in every box."
		feedback.add_theme_color_override("font_color", UiTheme.SAND)
		return
	answered = true
	SaveData.record(save, question.cell, result.correct, now(), result.get("misconception", ""), question.format == "probe")
	SaveData.store(save, save_path)
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


func _show_feedback(result: Dictionary) -> void:
	var probe: bool = question.format == "probe"
	if result.correct:
		feedback.text = "Right!" if not probe or question.verdict != "" else "Good. Compare with this answer:"
		feedback.add_theme_color_override("font_color", UiTheme.TEAL)
	else:
		if probe:
			feedback.text = "Not quite." if question.verdict != "" else "Here is the answer:"
		else:
			feedback.text = "Not quite. The answer is %s." % question.answer_text
		feedback.add_theme_color_override("font_color", UiTheme.PINK)
		var ref: String = result.get("misconception", "")
		if ref != "":
			for m in QuestionEngine.type_of(question.view.type).get("misconceptions", []):
				if m.ref == ref:
					feedback.text += "\nWatch out: " + m.text + "."
					break
	if question.format in ["mcq", "probe"]:
		for i in _choice_buttons.size():
			var right_option: bool = question.choices[i].correct if question.format == "mcq" else question.options[i] == question.verdict
			if right_option:
				_choice_buttons[i].add_theme_color_override("font_disabled_color", UiTheme.TEAL)
			elif i == _choice:
				_choice_buttons[i].add_theme_color_override("font_disabled_color", UiTheme.PINK)
	working.visible = true
	if probe:
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
		box.add_child(UiTheme.label(st, UiTheme.BODY))


func _update_progress() -> void:
	var pool := QuestionEngine.cells(save.settings.exam_only)
	var seen := 0
	var right := 0
	for c in pool:
		var r: Dictionary = save.cells.get(c.key, {})
		if r.get("seen", 0) > 0:
			seen += 1
			if r.get("last_result") == "right":
				right += 1
	progress.text = "%d of %d checked · %d right last time" % [seen, pool.size(), right]


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
		"mcq", "probe":
			var pick := -1
			var items: Array = question.choices if question.format == "mcq" else question.options
			for i in items.size():
				var ok: bool = question.choices[i].correct if question.format == "mcq" else items[i] == question.verdict or (question.verdict == "" and i == 0)
				if ok == right and pick < 0:
					pick = i
			# A wrong answer picks a misconception's option when there is one.
			if not right and question.format == "mcq":
				for i in items.size():
					if question.choices[i].ref != "":
						pick = i
						break
			if pick < 0:
				pick = 0
			_choice_buttons[pick].button_pressed = true
			_choice = pick
		"value":
			var values: Dictionary = question.answer.values
			if not right:
				for c in question.choices:
					if not c.correct:
						values = c.values
						if c.ref != "":
							break
			for id in _slots:
				_slots[id].text = Answer.export_values({id: values[id]})[id]
			for id in _picks:
				_picks[id] = values[id]
				for b in _pick_buttons[id]:
					b.button_pressed = b.text == values[id]
	check_answer()


## A view asked for in the URL (web) or on the command line, or {}.
static func deep_link() -> Dictionary:
	var args := {}
	if OS.has_feature("web"):
		var search = JavaScriptBridge.eval("window.location.search", true)
		if search is String and search.length() > 1:
			for part in search.substr(1).split("&"):
				var kv: PackedStringArray = part.split("=", true, 1)
				if kv.size() == 2:
					args[kv[0].uri_decode()] = kv[1].uri_decode()
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--") and a.contains("="):
			var kv := a.substr(2).split("=", true, 1)
			args[kv[0]] = kv[1]
	if not args.has("view"):
		return {}
	var p: PackedStringArray = args.view.split("/")
	var view := {}
	if p.size() >= 3 and p[1] == "probe":
		view = {"type": p[0], "probe": int(p[2]), "format": "probe"}
	elif p.size() >= 4:
		view = {"type": p[0], "unknown": p[1], "rep": p[2], "angle": p[3], "format": p[4] if p.size() > 4 else "value",
			"seed": int(args.get("seed", "1"))}
	else:
		return {}
	return {"view": view, "autoplay": args.get("autoplay", "")}
