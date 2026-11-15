extends Control
## The study screen (#134, FAL-798): a plain, academic presentation of the mathematics
## engine, beside the game. Pick a course, a topic, a question type, what is asked and
## a seed; answer; see the marking, the worked solution and what the evidence says.
## It uses MathsEngine only: no game theme, art, sound, characters, combat, rewards or
## map, and its evidence is its own file, not the game's save.
##
##   web:      /?study&view=<type>/<unknown>/<rep>/<angle>/<format>&seed=3
##   desktop:  -- --study --view=... --seed=3
## Add autoplay=right (or wrong) to answer it at once and show the marking and working.
##
## The same request and seed give the same question here as on the practice and fight
## screens (tests/test_maths_engine.gd). Graphs and diagrams are not drawn here yet, so
## the question list offers the representations this screen can show.

const EVIDENCE := "user://study.json"
## Representations this screen shows: words and symbols, and tables as a grid.
const SHOWN_REPS := ["equation", "words", "table", "notation", "terms"]
const FORMATS := {"value": "Type the answer", "mcq": "Multiple choice"}
const FONT := 34
const SMALL := 28
const INK := Color(0.1, 0.1, 0.12)
const MUTED := Color(0.35, 0.36, 0.4)
const RIGHT := Color(0.05, 0.45, 0.2)
const WRONG := Color(0.65, 0.1, 0.1)
const SEED_MAX := 99999

## Where the evidence lives. Tests point this somewhere else.
var evidence_path := EVIDENCE
var evidence: Dictionary
var course := "aa-sl"
var request: Dictionary = {}
var question: Dictionary = {}
var result: Dictionary = {}

var course_pick: OptionButton
var topic_pick: OptionButton
var type_pick: OptionButton
var cell_pick: OptionButton
var format_pick: OptionButton
var seed_box: SpinBox
var body: VBoxContainer
var feedback: Label
var solution: VBoxContainer
var results_label: Label
var mark_button: Button

var _boxes := {}       # answer box id -> LineEdit
var _picks := {}       # pick id -> OptionButton
var _choices: Array = [] # CheckBoxes, one per option
var _requests: Array = []
var _hud_was_visible := true


func _ready() -> void:
	theme = _theme()
	evidence = _load_evidence(evidence_path)
	_build()
	# The game's sound controls float over every scene; this screen has none.
	var hud := get_node_or_null("/root/AudioHud") as CanvasLayer
	if hud != null:
		_hud_was_visible = hud.visible
		hud.visible = false
	_fill_courses()
	_on_course(course_pick.selected)
	var link := deep_link()
	if not link.is_empty():
		select_request(link)
		var auto: String = url_args().get("autoplay", "")
		if auto in ["right", "wrong"] and not question.has("error"):
			enter(MathsEngine.model_response(question, auto == "right"))
			check_answer()


func _exit_tree() -> void:
	var hud := get_node_or_null("/root/AudioHud") as CanvasLayer
	if hud != null:
		hud.visible = _hud_was_visible


func _theme() -> Theme:
	var t := Theme.new()
	t.default_font_size = FONT
	t.set_color("font_color", "Label", INK)
	for kind in ["Button", "OptionButton", "CheckBox", "LineEdit", "PopupMenu"]:
		for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
			t.set_color(c, kind, INK)
	for kind in ["Button", "OptionButton", "LineEdit"]:
		t.set_stylebox("normal", kind, _box(Color(1, 1, 1), MUTED))
		t.set_stylebox("hover", kind, _box(Color(0.94, 0.95, 0.97), INK))
		t.set_stylebox("pressed", kind, _box(Color(0.88, 0.9, 0.94), INK))
		t.set_stylebox("focus", kind, _box(Color(1, 1, 1, 0), INK))
	t.set_stylebox("read_only", "LineEdit", _box(Color(0.94, 0.94, 0.92), MUTED))
	t.set_stylebox("disabled", "Button", _box(Color(0.92, 0.92, 0.9), MUTED))
	t.set_stylebox("panel", "PopupMenu", _box(Color(1, 1, 1), MUTED))
	return t


func _box(fill: Color, edge: Color) -> StyleBoxFlat:
	var b := StyleBoxFlat.new()
	b.bg_color = fill
	b.border_color = edge
	b.set_border_width_all(2)
	b.set_corner_radius_all(6)
	b.set_content_margin_all(12)
	return b


func _build() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.97, 0.97, 0.95)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var scroll := ScrollContainer.new()
	scroll.name = "Scroll"
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	var margin := MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 48)
	scroll.add_child(margin)
	var col := VBoxContainer.new()
	col.name = "Column"
	col.add_theme_constant_override("separation", 20)
	margin.add_child(col)

	col.add_child(_label("Mathematics practice", 48))
	col.add_child(_label("Choose a question, answer it, and check your working.", SMALL, MUTED))
	course_pick = _option(col, "Course", _on_course)
	topic_pick = _option(col, "Topic", _on_topic)
	type_pick = _option(col, "Question type", _on_type)
	cell_pick = _option(col, "What is asked", func(_i): _ask())
	format_pick = _option(col, "Answer", func(_i): _ask())
	for f in FORMATS:
		format_pick.add_item(FORMATS[f])
		format_pick.set_item_metadata(format_pick.item_count - 1, f)
	var seed_row := HBoxContainer.new()
	seed_row.add_theme_constant_override("separation", 16)
	seed_row.add_child(_word("Seed", SMALL, MUTED))
	seed_box = SpinBox.new()
	seed_box.name = "Seed"
	seed_box.min_value = 1
	seed_box.max_value = SEED_MAX
	seed_box.value = 1
	seed_box.value_changed.connect(func(_v): _ask())
	seed_row.add_child(seed_box)
	var another := Button.new()
	another.text = "Another question"
	another.pressed.connect(func(): seed_box.value = int(seed_box.value) % SEED_MAX + 1)
	seed_row.add_child(another)
	col.add_child(seed_row)
	col.add_child(HSeparator.new())

	body = VBoxContainer.new()
	body.name = "Question"
	body.add_theme_constant_override("separation", 16)
	col.add_child(body)
	mark_button = Button.new()
	mark_button.name = "Mark"
	mark_button.text = "Mark my answer"
	mark_button.pressed.connect(check_answer)
	col.add_child(mark_button)
	feedback = _label("", FONT)
	feedback.name = "Feedback"
	col.add_child(feedback)
	solution = VBoxContainer.new()
	solution.name = "Solution"
	solution.add_theme_constant_override("separation", 10)
	col.add_child(solution)
	col.add_child(HSeparator.new())
	results_label = _label("", SMALL, MUTED)
	results_label.name = "Results"
	col.add_child(results_label)


func _label(text: String, size: int = FONT, color: Color = INK) -> Label:
	var l := Label.new()
	l.text = text
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l


## A label that keeps to one line, for a row beside boxes.
func _word(text: String, size: int = FONT, color: Color = INK) -> Label:
	var l := _label(text, size, color)
	l.autowrap_mode = TextServer.AUTOWRAP_OFF
	l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return l


func _option(col: VBoxContainer, heading: String, on_pick: Callable) -> OptionButton:
	col.add_child(_label(heading, SMALL, MUTED))
	var o := OptionButton.new()
	o.name = heading.replace(" ", "")
	o.fit_to_longest_item = false
	o.clip_text = true
	o.item_selected.connect(on_pick)
	col.add_child(o)
	return o


# ── Choosing a request (MathsEngine curriculum selection) ────

func _fill_courses() -> void:
	course_pick.clear()
	for c in MathsEngine.courses():
		course_pick.add_item("%s: %s" % [c.short, c.name])
		course_pick.set_item_metadata(course_pick.item_count - 1, c.id)
		if c.id == course:
			course_pick.select(course_pick.item_count - 1)


func _on_course(i: int) -> void:
	course = String(course_pick.get_item_metadata(i)) if i >= 0 else ""
	topic_pick.clear()
	var have := {}
	for t in MathsEngine.types(course):
		have[t.topic] = true
	for tp in MathsEngine.topics():
		if have.has(int(tp.n)):
			topic_pick.add_item("%d. %s" % [tp.n, tp.name])
			topic_pick.set_item_metadata(topic_pick.item_count - 1, int(tp.n))
	_on_topic(0)


func _on_topic(i: int) -> void:
	type_pick.clear()
	if topic_pick.item_count == 0:
		return
	var n := int(topic_pick.get_item_metadata(maxi(i, 0)))
	for t in MathsEngine.types(course):
		if t.topic == n and not _shown_requests(t.id).is_empty():
			type_pick.add_item(t.name)
			type_pick.set_item_metadata(type_pick.item_count - 1, t.id)
	_on_type(0)


func _shown_requests(type_id: String) -> Array:
	return MathsEngine.requests(course, false, [type_id]).filter(func(c): return c.rep in SHOWN_REPS)


func _on_type(i: int) -> void:
	cell_pick.clear()
	if type_pick.item_count == 0:
		return
	_requests = _shown_requests(String(type_pick.get_item_metadata(maxi(i, 0))))
	for c in _requests:
		cell_pick.add_item("%s (%s; %s)" % [_asked(c), c.rep, MathsEngine.method_name(c.type, c.unknown, c.angle)])
	_ask()


func _asked(c: Dictionary) -> String:
	return MathsEngine.asked(c.type, c.unknown)


## The request the pickers make, or {}.
func current_request() -> Dictionary:
	if cell_pick.selected < 0 or cell_pick.selected >= _requests.size():
		return {}
	var c: Dictionary = _requests[cell_pick.selected]
	return {"type": c.type, "unknown": c.unknown, "rep": c.rep, "angle": c.angle,
		"format": String(format_pick.get_item_metadata(maxi(format_pick.selected, 0))), "seed": int(seed_box.value)}


func _ask() -> void:
	var r := current_request()
	if not r.is_empty():
		show_request(r)


## Sets the pickers to a request (as far as they list it) and asks it.
func select_request(r: Dictionary) -> void:
	var topic := MathsEngine.topic_of(r.get("type", ""))
	for i in topic_pick.item_count:
		if int(topic_pick.get_item_metadata(i)) == topic:
			topic_pick.select(i)
			_on_topic(i)
	for i in type_pick.item_count:
		if type_pick.get_item_metadata(i) == r.get("type"):
			type_pick.select(i)
			_on_type(i)
	for i in _requests.size():
		var c: Dictionary = _requests[i]
		if c.unknown == r.get("unknown") and c.rep == r.get("rep") and c.angle == r.get("angle"):
			cell_pick.select(i)
	for i in format_pick.item_count:
		if format_pick.get_item_metadata(i) == r.get("format", "value"):
			format_pick.select(i)
	seed_box.set_value_no_signal(int(r.get("seed", 1)))
	show_request(r)


# ── The question (MathsEngine generation) ────────────────────

## Asks a request exactly as given and shows its question.
func show_request(r: Dictionary) -> void:
	request = r
	question = MathsEngine.generate(r)
	result = {}
	_render()


func _render() -> void:
	for c in body.get_children():
		body.remove_child(c)
		c.queue_free()
	for c in solution.get_children():
		solution.remove_child(c)
		c.queue_free()
	_boxes = {}
	_picks = {}
	_choices = []
	feedback.text = ""
	_show_results()
	if question.has("error"):
		body.add_child(_label("This question can't be made: " + question.error, FONT, WRONG))
		mark_button.disabled = true
		return
	mark_button.disabled = false
	var meta := "%s · Paper %d" % [question.type_name, int(question.paper)]
	if int(question.get("marks", 0)) > 0:
		meta += " · %d marks" % int(question.marks)
	body.add_child(_label(meta, SMALL, MUTED))
	var p := _label(MathsEngine.prompt(question))
	p.name = "Prompt"
	body.add_child(p)
	for line in question.get("lines", []):
		body.add_child(_label(line))
	if question.get("table") != null:
		body.add_child(_table(question.table))
	if question.get("graph") != null or question.get("diagram") != null or question.has("graphs"):
		body.add_child(_label("This question comes with a graph or diagram, which this screen does not draw yet.", SMALL, MUTED))
	if MathsEngine.is_choice(question):
		_add_choices()
	else:
		_add_boxes()


func _table(t: Dictionary) -> Control:
	var grid := GridContainer.new()
	grid.name = "Table"
	var heads: Array = t.get("heads", ["x", "f(x)"])
	var rows: Array = t.rows if t.has("rows") else [[heads[0], t.xs.map(func(v): return Fmt.num(v))], [heads[1], t.ys.map(func(v): return Fmt.num(v))]]
	grid.columns = rows[0][1].size() + 1
	grid.add_theme_constant_override("h_separation", 28)
	for row in rows:
		grid.add_child(_label(str(row[0]), FONT, MUTED))
		for v in row[1]:
			grid.add_child(_label(str(v)))
	return grid


func _add_choices() -> void:
	var group := ButtonGroup.new()
	var texts: Array = question.options if question.format == "probe" else question.choices.map(func(c): return c.text)
	for i in texts.size():
		var b := CheckBox.new()
		b.name = "Choice%d" % i
		b.text = "%s.  %s" % [String.chr(65 + i), texts[i]]
		b.button_group = group
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		body.add_child(b)
		_choices.append(b)


func _add_boxes() -> void:
	var flow := HFlowContainer.new()
	flow.name = "Answer"
	flow.add_theme_constant_override("h_separation", 10)
	for item in question.answer.template:
		if item is String:
			if item != "":
				flow.add_child(_word(item))
		elif item.has("slot"):
			var e := LineEdit.new()
			e.name = "Box_" + item.slot
			e.custom_minimum_size = Vector2(180, 0)
			e.expand_to_text_length = true
			e.text_submitted.connect(func(_t): check_answer())
			flow.add_child(e)
			_boxes[item.slot] = e
		else:
			var o := OptionButton.new()
			o.name = "Pick_" + item.pick
			o.add_item("Choose")
			for opt in item.options:
				o.add_item(opt)
			flow.add_child(o)
			_picks[item.pick] = o
	body.add_child(flow)


# ── Answering (MathsEngine marking and worked solutions) ─────

## What the student has entered, as MathsEngine.mark takes it.
func response() -> Dictionary:
	if MathsEngine.is_choice(question):
		for i in _choices.size():
			if _choices[i].button_pressed:
				return {"choice": i}
		return {"choice": -1}
	var out := {}
	for id in _boxes:
		out[id] = _boxes[id].text
	for id in _picks:
		var o: OptionButton = _picks[id]
		out[id] = o.get_item_text(o.selected) if o.selected > 0 else ""
	return out


## Puts a response in the answer controls (the inverse of response()).
func enter(r: Dictionary) -> void:
	if r.has("choice"):
		var i := int(r.choice)
		if i >= 0 and i < _choices.size():
			_choices[i].button_pressed = true
		return
	for id in _boxes:
		_boxes[id].text = str(r.get(id, ""))
	for id in _picks:
		var o: OptionButton = _picks[id]
		for i in o.item_count:
			if o.get_item_text(i) == str(r.get(id, "")):
				o.select(i)


func check_answer() -> void:
	if question.is_empty() or question.has("error") or not result.is_empty():
		return
	var r := MathsEngine.mark(question, response())
	if not r.complete:
		var msgs: Array = r.errors.values()
		feedback.text = msgs[0] if msgs.size() == 1 else "Answer every part."
		feedback.add_theme_color_override("font_color", MUTED)
		return
	result = r
	mark_button.disabled = true
	MathsEngine.record(evidence, question, r, int(Time.get_unix_time_from_system()))
	_store_evidence(evidence_path, evidence)
	if r.correct:
		feedback.text = "Correct." if not r.get("glancing", false) else "Correct value, but give it to the accuracy asked for. " + MathsEngine.answer_sentence(question)
		feedback.add_theme_color_override("font_color", RIGHT)
	else:
		var note: String = r.get("note", "")
		feedback.text = "Not correct. " + ("" if note == "" else note + " ") + MathsEngine.answer_sentence(question)
		feedback.add_theme_color_override("font_color", WRONG)
	_show_solution()
	_show_results()


func _show_solution() -> void:
	var sols := MathsEngine.worked_solutions(question)
	for i in sols.size():
		var s: Dictionary = sols[i]
		solution.add_child(_label(("Worked solution: " if i == 0 else "Another method: ") + s.name, FONT, MUTED))
		for st in s.steps:
			solution.add_child(_label(st))


# ── Learning results ─────────────────────────────────────────

func _show_results() -> void:
	var r := MathsEngine.results(evidence, course)
	var acc: Dictionary = r.accuracy
	var lines: Array = ["Your record on this course: %d of %d question kinds tried" % [r.coverage.checked, r.coverage.total]]
	if acc.seen > 0:
		lines.append("%d of %d answers correct (%d%%)" % [acc.right, acc.seen, acc.percent])
	if not r.weakest.is_empty():
		lines.append("To work on: " + ", ".join(r.weakest.map(func(w): return "%s (%d%%)" % [w.name, w.percent])))
	results_label.text = "\n".join(lines)


static func _load_evidence(path: String) -> Dictionary:
	var out := MathsEngine.blank_evidence()
	if not FileAccess.file_exists(path):
		return out
	var f := FileAccess.open(path, FileAccess.READ)
	var parsed = JSON.parse_string(f.get_as_text()) if f != null else null
	if parsed is Dictionary:
		for key in out:
			if parsed.has(key) and typeof(parsed[key]) == typeof(out[key]):
				out[key] = parsed[key]
	return out


static func _store_evidence(path: String, data: Dictionary) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(data, "\t"))


# ── Links ────────────────────────────────────────────────────

## The URL's query (web) and the command line's --key=value arguments; a bare key is "".
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


## Whether the link asks for this screen.
static func wanted() -> bool:
	return url_args().has("study")


## The request in the link (view=type/unknown/rep/angle/format, seed=n), or {}.
static func deep_link() -> Dictionary:
	var args := url_args()
	if not args.has("study") or not args.has("view"):
		return {}
	var p: PackedStringArray = str(args.view).split("/")
	if p.size() < 4:
		return {}
	return {"type": p[0], "unknown": p[1], "rep": p[2], "angle": p[3], "format": p[4] if p.size() > 4 else "value",
		"seed": int(args.get("seed", "1"))}
