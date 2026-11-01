extends "res://ui/practice.gd"
## The engine explorer at /next/?explore (FAL-391): pick a course, a topic and a
## question class, then what is asked for, how it is shown, the method and the format,
## and play the question exactly as on the practice screen. "Ask it another way" keeps
## the situation (the same numbers) and asks the next unknown of its family
## (QuestionEngine.families()). Nothing is saved.
##
##   web:      /next/?explore&view=<type>/<unknown>/<rep>/<angle>/<value|mcq>&seed=3
##   desktop:  -- --explore --view=... --seed=3
## Add ten=1 to show ten versions, or autoplay=right (or wrong) to answer at once.
## The URL follows the screen, so a state can be bookmarked.
##
## Question classes come from the engine catalogue: a type is live when its situation
## is built (QuestionEngine.built_types()), so new situations show up here with no
## change. Courses come from data/courses.json when it is there.

const COURSES := "res://data/courses.json"
## Used until data/courses.json lands (FAL-393): AA SL from the catalogue, the other
## three waiting for their syllabus maps.
const DEFAULT_COURSES := [
	{"id": "aa-sl", "short": "AA SL", "name": "Analysis and Approaches SL", "status": "live"},
	{"id": "aa-hl", "short": "AA HL", "name": "Analysis and Approaches HL", "status": "pending"},
	{"id": "ai-sl", "short": "AI SL", "name": "Applications and Interpretation SL", "status": "pending"},
	{"id": "ai-hl", "short": "AI HL", "name": "Applications and Interpretation HL", "status": "pending"},
]
const STATUS := {"live": "live", "mapped": "syllabus mapped", "planned": "planned",
	"pending": "syllabus mapping in progress"}
const REPS := {"equation": "Equation", "words": "Words", "graph": "Graph", "table": "Table"}
const FORMAT_NAMES := {"value": "Value", "mcq": "Multiple choice", "error-spot": "Error spot", "method-pick": "Method pick",
	"true-false-reason": "True or false"}
## Base units: the choices pane's width in landscape, and the widest the screen gets.
const LEFT := 1150
const WIDEST := 2900
const VERSIONS := 10
const SEED_MAX := 99999
const TAB := 30
const COURSE_FONT := 28

var courses: Array = []
var course := "aa-sl"
var topic := 0
var type_id := ""
var unknown := ""
var rep := ""
var angle := "any"
var fmt := "value"
var seed := 1
var exam_only := false
var versions := false
var show_unbuilt := false
## Portrait shows one pane at a time: "choose" or "question".
var pane := "choose"
var wide := false

var tabs_row: HBoxContainer
var body: HBoxContainer
var left: ScrollContainer
var choices: VBoxContainer
var right: VBoxContainer
var situation_label: Label
var new_button: Button
var another_button: Button
var versions_button: Button
var seed_label: Label
var _tab_buttons := {}


func _ready() -> void:
	theme = UiTheme.make()
	save = {}
	courses = load_courses()
	_build()
	resized.connect(_fit)
	var args := url_args()
	var deep := view_from(args)
	if not deep.is_empty() and deep.view.has("unknown") and _live_types().has(deep.view.type):
		var v: Dictionary = deep.view
		type_id = v.type
		topic = int(QuestionEngine.type_of(type_id).get("topic", 0))
		unknown = v.unknown
		rep = v.rep
		angle = v.angle
		fmt = v.format
		seed = maxi(1, int(v.seed))
		versions = args.has("ten")
		pane = "question"
	else:
		seed = randi_range(1, SEED_MAX)
		_pick_topic(_first_live_topic())
	_fit()
	_refresh()
	_show()
	if not deep.is_empty() and deep.autoplay != "" and not versions:
		autoplay(deep.autoplay == "right")


## The courses in data/courses.json, or DEFAULT_COURSES when it isn't there or can't
## be read. The explorer never fails without it.
static func load_courses(path: String = COURSES) -> Array:
	if not FileAccess.file_exists(path):
		return DEFAULT_COURSES.duplicate(true)
	var f := FileAccess.open(path, FileAccess.READ)
	var json := JSON.new()
	if f == null or json.parse(f.get_as_text()) != OK:
		return DEFAULT_COURSES.duplicate(true)
	var data = json.data
	if not data is Dictionary or not data.get("courses") is Array or data.courses.is_empty():
		return DEFAULT_COURSES.duplicate(true)
	return data.courses


# ── Layout ───────────────────────────────────────────────────

func _build() -> void:
	super._build()
	title_label.text = "Engine"
	exam_toggle.text = "Exam-style only: off"
	head.add_theme_constant_override("separation", 16)
	progress.name = "ClassSize"
	progress.add_theme_color_override("font_color", UiTheme.SAND)
	var col := scroll.get_parent()

	tabs_row = HBoxContainer.new()
	tabs_row.name = "Panes"
	var group := ButtonGroup.new()
	for p in [["choose", "Choose"], ["question", "Question"]]:
		var b := Button.new()
		b.name = p[1]
		b.text = p[1]
		b.toggle_mode = true
		b.button_group = group
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.add_theme_font_size_override("font_size", UiTheme.SMALL)
		b.pressed.connect(_set_pane.bind(p[0]))
		tabs_row.add_child(b)
		_tab_buttons[p[0]] = b
	col.add_child(tabs_row)

	body = HBoxContainer.new()
	body.name = "Body"
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 48)
	col.add_child(body)
	left = ScrollContainer.new()
	left.name = "Left"
	left.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(left)
	choices = VBoxContainer.new()
	choices.name = "Choices"
	choices.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	choices.add_theme_constant_override("separation", 14)
	left.add_child(choices)
	right = VBoxContainer.new()
	right.name = "Right"
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 12)
	body.add_child(right)
	situation_label = UiTheme.label("", UiTheme.SMALL, UiTheme.TEAL)
	situation_label.name = "Situation"
	right.add_child(situation_label)
	col.remove_child(scroll)
	right.add_child(scroll)

	var actions := VBoxContainer.new()
	actions.name = "Actions"
	actions.add_theme_constant_override("separation", 10)
	var row1 := HBoxContainer.new()
	new_button = _action("New question", new_question)
	another_button = _action("Ask it another way", ask_another_way)
	row1.add_child(new_button)
	row1.add_child(another_button)
	actions.add_child(row1)
	var row2 := HBoxContainer.new()
	row2.add_theme_constant_override("separation", 16)
	# Down here, not in the head: on a phone the head is full up to the speaker and gear.
	var back := Button.new()
	back.name = "Back"
	back.text = "Title"
	back.add_theme_font_size_override("font_size", UiTheme.SMALL)
	back.pressed.connect(_to_title)
	row2.add_child(back)
	seed_label = UiTheme.label("", UiTheme.SMALL, UiTheme.DIM)
	seed_label.name = "Seed"
	seed_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	seed_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row2.add_child(seed_label)
	versions_button = _action("Show 10 versions", toggle_versions)
	versions_button.size_flags_horizontal = Control.SIZE_SHRINK_END
	versions_button.add_theme_font_size_override("font_size", UiTheme.SMALL)
	row2.add_child(versions_button)
	actions.add_child(row2)
	col.add_child(actions)


func _action(text: String, on_press: Callable) -> Button:
	var b := Button.new()
	b.name = text.replace(" ", "")
	b.text = text
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.add_theme_font_size_override("font_size", UiTheme.BIG)
	b.pressed.connect(on_press)
	return b


## Landscape shows the choices and the question side by side; portrait shows one at a
## time, with tabs to switch.
func _fit() -> void:
	wide = size.x > size.y
	var side := 36.0
	if wide:
		side = maxf(60.0, (size.x - WIDEST) / 2.0)
	margin.add_theme_constant_override("margin_left", int(side))
	margin.add_theme_constant_override("margin_right", int(side))
	margin.add_theme_constant_override("margin_top", 40)
	margin.add_theme_constant_override("margin_bottom", 30)
	hud_gap.custom_minimum_size.x = maxf(0.0, AudioHud.RESERVED_RIGHT - side)
	left.custom_minimum_size.x = LEFT if wide else 0
	left.size_flags_horizontal = Control.SIZE_FILL if wide else Control.SIZE_EXPAND_FILL
	tabs_row.visible = not wide
	_set_pane(pane)


func _set_pane(p: String) -> void:
	pane = p
	left.visible = wide or pane == "choose"
	right.visible = wide or pane == "question"
	_tab_buttons[pane].set_pressed_no_signal(true)


func _to_title() -> void:
	if OS.has_feature("web"):
		JavaScriptBridge.eval("window.history.replaceState(null, '', window.location.pathname)")
	get_tree().change_scene_to_file("res://scenes/main.tscn")


# ── What can be picked ───────────────────────────────────────

func _course() -> Dictionary:
	for c in courses:
		if c.get("id") == course:
			return c
	return courses[0] if not courses.is_empty() else DEFAULT_COURSES[0]


## Whether the engine can ask this course anything: it covers a built type (Courses).
## courses.json's `status` is the syllabus map's, and only says so in the note.
func _live() -> bool:
	return not _live_types().is_empty()


func _live_types() -> Array:
	return QuestionEngine.built_types(course)


## The topics of the course: from courses.json, else the catalogue's (AA SL) names.
func _topics() -> Array:
	var ts: Array = _course().get("topics", [])
	if not ts.is_empty():
		return ts
	return QuestionEngine.catalogue().get("topics", [])


## The catalogue's question types in a topic: [built ones, not built ones].
func _types_in(n: int) -> Array:
	var live := _live_types()
	var built: Array = []
	var not_built: Array = []
	for t in QuestionEngine.catalogue().types:
		if int(t.get("topic", 0)) != n:
			continue
		if t.id in live:
			built.append(t)
		else:
			not_built.append(t)
	return [built, not_built]


func _first_live_topic() -> int:
	for t in _topics():
		if not _types_in(int(t.n))[0].is_empty():
			return int(t.n)
	return 1


func _cells() -> Array:
	if type_id == "":
		return []
	return QuestionEngine.cells(exam_only, [type_id], course)


func _unknowns() -> Array:
	var out: Array = []
	for c in _cells():
		if not out.has(c.unknown):
			out.append(c.unknown)
	return out


func _reps_for(u: String) -> Array:
	var out: Array = []
	for c in _cells():
		if c.unknown == u and not out.has(c.rep):
			out.append(c.rep)
	return out


func _angles_for(u: String) -> Array:
	var out: Array = ["any"]
	for a in QuestionEngine.angles_for(QuestionEngine.type_of(type_id), u, course):
		if a != "any":
			out.append(a)
	return out


## Plain words for an unknown: what is asked and what it is found from.
func unknown_name(t: Dictionary, u: String) -> String:
	var info := QuestionEngine.unknown_of(t, u)
	var given: Array = info.get("given", [])
	var text: String = info.get("asked", u)
	if not given.is_empty():
		text += ", from " + " and ".join(given)
	return text.left(1).to_upper() + text.substr(1)


func angle_name(t: Dictionary, u: String, a: String) -> String:
	if a == "any":
		return "Any method"
	return QuestionEngine.angle_info(t, u, a).get("name", a)


## The family of unknowns that share one situation with the current view, as far as
## the exam-style switch allows.
func family() -> Array:
	if type_id == "" or unknown == "":
		return []
	var allowed := _unknowns()
	return QuestionEngine.family_of(type_id, unknown, rep).unknowns.filter(func(u): return u in allowed and rep in _reps_for(u))


# ── Choosing ─────────────────────────────────────────────────

func _pick_course(id: String) -> void:
	course = id
	if _live():
		_pick_topic(topic if topic > 0 else _first_live_topic())
	_refresh()
	if _live():
		_show()


func _pick_topic(n: int) -> void:
	topic = n
	var built: Array = _types_in(n)[0]
	if not built.is_empty() and not built.any(func(t): return t.id == type_id):
		_pick_type(built[0].id)
	elif built.is_empty():
		type_id = ""
		unknown = ""


func _pick_type(id: String) -> void:
	type_id = id
	var us := _unknowns()
	unknown = us[0] if not us.is_empty() else ""
	_fix_view()


## Keeps the representation and method if they suit the unknown, else takes the first.
func _fix_view() -> void:
	if unknown == "":
		return
	var reps := _reps_for(unknown)
	if not rep in reps:
		rep = reps[0] if not reps.is_empty() else ""
	if not angle in _angles_for(unknown):
		angle = "any"
	_fix_format()


## An extra format the view no longer offers goes back to multiple choice.
func _fix_format() -> void:
	if fmt in QuestionEngine.EXTRA_FORMATS and not fmt in QuestionEngine.extra_formats(type_id, unknown, angle):
		fmt = "mcq"


func _choose(field: String, value: Variant) -> void:
	match field:
		"course":
			_pick_course(value)
			return
		"topic":
			_pick_topic(value)
		"type":
			_pick_type(value)
		"unknown":
			unknown = value
			_fix_view()
		"rep":
			rep = value
		"angle":
			angle = value
			_fix_format()
		"format":
			fmt = value
	_refresh()
	_show()


func new_question() -> void:
	seed = randi_range(1, SEED_MAX)
	_set_pane("question")
	_show()


## Same situation (same seed, same family), next unknown.
func ask_another_way() -> void:
	var fam := family()
	if fam.size() < 2:
		return
	unknown = fam[(fam.find(unknown) + 1) % fam.size()]
	_fix_view()
	versions = false
	_refresh()
	_set_pane("question")
	_show()


func toggle_versions() -> void:
	versions = not versions
	_set_pane("question")
	_show()


func _on_exam_toggled(on: bool) -> void:
	exam_only = on
	exam_toggle.text = "Exam-style only: " + ("on" if on else "off")
	if type_id != "" and not unknown in _unknowns():
		var us := _unknowns()
		unknown = us[0] if not us.is_empty() else ""
	_fix_view()
	_refresh()
	_show()


# ── The choices pane ─────────────────────────────────────────

func _refresh() -> void:
	var keep := left.scroll_vertical
	for c in choices.get_children():
		choices.remove_child(c)
		c.queue_free()
	_heading("Course")
	var cgrid := _grid(4)
	for c in courses:
		var b := _toggle(c.get("short", c.get("id", "?")) + "\n" + STATUS.get(c.get("status", ""), c.get("status", "")),
			c.get("id") == course, _choose.bind("course", c.get("id")), COURSE_FONT)
		b.name = "Course_" + str(c.get("id"))
		cgrid.add_child(b)

	_heading("Topic")
	var tgrid := _grid(3)
	for t in _topics():
		var n := int(t.n)
		var text := "%d\n%s" % [n, t.name]
		if _live():
			var split := _types_in(n)
			text += "\n%d / %d" % [split[0].size(), split[0].size() + split[1].size()]
		var b := _toggle(text, n == topic, _choose.bind("topic", n), TAB)
		b.name = "Topic_%d" % n
		tgrid.add_child(b)
	if not _live():
		_course_note()
	else:
		_class_list()
		if type_id != "":
			_pickers()
	_update_progress()
	_update_actions()
	left.set_deferred("scroll_vertical", keep)


func _course_note() -> void:
	var c := _course()
	var text := "%s: %s." % [c.get("name", c.get("short", "")), STATUS.get(c.get("status", ""), c.get("status", ""))]
	for t in c.get("topics", []):
		if int(t.n) == topic:
			text += "\nTopic %d, %s: %d subtopics, %d skills, %d hours." % [topic, t.name, int(t.get("subtopics", 0)),
				int(t.get("skills", 0)), int(t.get("hours", 0))]
	text += "\nQuestion classes are built for AA SL first."
	var l := UiTheme.label(text, UiTheme.BODY, UiTheme.DIM)
	l.name = "CourseNote"
	choices.add_child(l)


func _class_list() -> void:
	var split := _types_in(topic)
	var topic_name := ""
	for t in _topics():
		if int(t.n) == topic:
			topic_name = t.name
	var summary := UiTheme.label("Topic %d, %s · question types: %d live / %d catalogued" % [topic, topic_name,
		split[0].size(), split[0].size() + split[1].size()], UiTheme.SMALL, UiTheme.DIM)
	summary.name = "TopicSummary"
	choices.add_child(summary)
	_heading("Question class")
	var list := VBoxContainer.new()
	list.name = "Classes"
	list.add_theme_constant_override("separation", 10)
	choices.add_child(list)
	if split[0].is_empty():
		list.add_child(UiTheme.label("No question class is built in this topic yet.", UiTheme.BODY, UiTheme.DIM))
	for t in split[0]:
		var b := _toggle(t.name, t.id == type_id, _choose.bind("type", t.id), UiTheme.BODY)
		b.name = "Class_" + t.id
		list.add_child(b)
	if split[1].is_empty():
		return
	var more := _toggle("%s the %d not built yet" % ["Hide" if show_unbuilt else "Show", split[1].size()], false,
		func(): show_unbuilt = not show_unbuilt; _refresh(), UiTheme.SMALL)
	more.name = "NotBuilt"
	more.toggle_mode = false
	list.add_child(more)
	if show_unbuilt:
		for t in split[1]:
			var why := "not built yet" if not t.id in QuestionEngine.built_types() else "not in " + String(_course().get("short", course))
			var g := _toggle(t.get("name", t.id) + " · " + why, false, func(): pass, UiTheme.SMALL)
			g.disabled = true
			list.add_child(g)


func _pickers() -> void:
	var t := QuestionEngine.type_of(type_id)
	if t.get("summary", "") != "":
		choices.add_child(UiTheme.label(t.summary, UiTheme.SMALL, UiTheme.DIM))
	var us := _unknowns()
	if us.is_empty():
		choices.add_child(UiTheme.label("No exam-style questions in this class. Switch exam-style off to see them.",
			UiTheme.BODY, UiTheme.SAND))
		return
	_heading("Asked for")
	var ulist := VBoxContainer.new()
	ulist.name = "AskedFor"
	ulist.add_theme_constant_override("separation", 8)
	for u in us:
		var b := _toggle(unknown_name(t, u), u == unknown, _choose.bind("unknown", u), UiTheme.SMALL)
		b.name = "Unknown_" + u
		ulist.add_child(b)
	choices.add_child(ulist)
	_heading("Shown as")
	var rflow := _flow("ShownAs")
	for r in _reps_for(unknown):
		var b := _toggle(REPS.get(r, r.capitalize()), r == rep, _choose.bind("rep", r))
		b.autowrap_mode = TextServer.AUTOWRAP_OFF
		b.name = "Rep_" + r
		rflow.add_child(b)
	_heading("Method")
	var mlist := VBoxContainer.new()
	mlist.name = "Method"
	mlist.add_theme_constant_override("separation", 8)
	for a in _angles_for(unknown):
		var b := _toggle(angle_name(t, unknown, a), a == angle, _choose.bind("angle", a), UiTheme.SMALL)
		b.name = "Angle_" + a
		mlist.add_child(b)
	choices.add_child(mlist)
	_heading("Format")
	var fflow := _flow("Format")
	for f in ["value", "mcq"] + QuestionEngine.extra_formats(type_id, unknown, angle):
		var b := _toggle(FORMAT_NAMES[f], f == fmt, _choose.bind("format", f))
		b.autowrap_mode = TextServer.AUTOWRAP_OFF
		b.name = "Format_" + f
		fflow.add_child(b)


func _heading(text: String) -> void:
	var l := UiTheme.label(text, UiTheme.SMALL, UiTheme.SAND)
	choices.add_child(l)


func _grid(columns: int) -> GridContainer:
	var g := GridContainer.new()
	g.columns = columns
	g.add_theme_constant_override("h_separation", 10)
	g.add_theme_constant_override("v_separation", 10)
	choices.add_child(g)
	return g


func _flow(node_name: String) -> HFlowContainer:
	var f := HFlowContainer.new()
	f.name = node_name
	f.add_theme_constant_override("h_separation", 10)
	f.add_theme_constant_override("v_separation", 10)
	choices.add_child(f)
	return f


func _toggle(text: String, on: bool, on_press: Callable, font: int = UiTheme.SMALL) -> Button:
	var b := Button.new()
	b.text = text
	b.toggle_mode = true
	b.button_pressed = on
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.add_theme_font_size_override("font_size", font)
	b.pressed.connect(on_press)
	return b


# ── The question pane ────────────────────────────────────────

func view() -> Dictionary:
	return {"type": type_id, "unknown": unknown, "rep": rep, "angle": angle, "format": fmt, "seed": seed, "shared": true}


func _show() -> void:
	_update_actions()
	_sync_url()
	if not _live() or type_id == "" or unknown == "":
		return
	if versions:
		_show_versions()
	else:
		show_view(view())
	var fam := family()
	if fam.size() > 1:
		situation_label.text = "One situation, %d questions from it: this is %d of %d" % [fam.size(), fam.find(unknown) + 1, fam.size()]
	else:
		situation_label.text = "This question has a situation of its own"


## Ten seeds of the current view on one screen, each with its answer.
func _show_versions() -> void:
	var first := QuestionEngine.make(view())
	if first.has("error"):
		show_view(view())
		return
	question = first
	_clear_card()
	card.add_child(UiTheme.label("%s · %d versions" % [first.type_name, VERSIONS], UiTheme.SMALL, UiTheme.DIM))
	card.add_child(UiTheme.label(first.prompt, UiTheme.BODY))
	var list := VBoxContainer.new()
	list.name = "Versions"
	list.add_theme_constant_override("separation", 18)
	card.add_child(list)
	for i in VERSIONS:
		var v := view()
		v.seed = seed + i
		var q := QuestionEngine.make(v)
		var box := PanelContainer.new()
		box.add_theme_stylebox_override("panel", UiTheme.panel())
		var inner := VBoxContainer.new()
		inner.add_theme_constant_override("separation", 8)
		box.add_child(inner)
		inner.add_child(UiTheme.label("seed %d" % v.seed, UiTheme.SMALL, UiTheme.DIM))
		if q.has("error"):
			inner.add_child(UiTheme.label(q.error, UiTheme.SMALL, UiTheme.PINK))
		else:
			for line in q.lines:
				inner.add_child(UiTheme.label(line, UiTheme.BODY, UiTheme.SAND if line.contains(" = ") else UiTheme.TEXT))
			if q.graph != null:
				var g := graph_for(q.graph)
				g.custom_minimum_size.y = mini(480, int(g.custom_minimum_size.y))
				inner.add_child(g)
			if q.table != null:
				inner.add_child(_table(q.table))
			inner.add_child(UiTheme.label("Answer: " + q.answer_text, UiTheme.BODY, UiTheme.TEAL))
		list.add_child(box)
	answered = true


## The card's own button after an answer asks the same situation the next way.
func _add_next() -> void:
	super._add_next()
	next_button.text = "Ask it another way"
	next_button.pressed.disconnect(next_question)
	next_button.pressed.connect(ask_another_way)
	if family().size() < 2:
		next_button.text = "New question"
		next_button.pressed.disconnect(ask_another_way)
		next_button.pressed.connect(new_question)


func next_question() -> void:
	new_question()


func _record(_result: Dictionary) -> void:
	pass


## The class size line: unknowns × representations × methods, and the question shapes
## (coverage cells) they make.
func _update_progress() -> void:
	if progress == null:
		return
	var cs := _cells() if _live() else []
	if cs.is_empty():
		progress.text = ""
		return
	var us := {}
	var rs := {}
	var ms := {}
	for c in cs:
		us[c.unknown] = true
		rs[c.rep] = true
		if c.angle != "any":
			ms[c.angle] = true
	progress.text = "%d unknowns × %d representations × %d methods: %d question shapes, new numbers on every seed" % [
		us.size(), rs.size(), maxi(1, ms.size()), cs.size()]


func _update_actions() -> void:
	if new_button == null:
		return
	var ok := _live() and type_id != "" and unknown != ""
	new_button.disabled = not ok
	versions_button.disabled = not ok
	another_button.disabled = not ok or family().size() < 2
	versions_button.text = "Play one" if versions else "Show 10 versions"
	seed_label.text = "seed %d" % seed if ok else ""


func _sync_url() -> void:
	if not OS.has_feature("web"):
		return
	var q := "?explore"
	if _live() and type_id != "" and unknown != "":
		q += "&view=%s/%s/%s/%s/%s&seed=%d" % [type_id, unknown, rep, angle, fmt, seed]
		if versions:
			q += "&ten=1"
	JavaScriptBridge.eval("window.history.replaceState(null, '', %s)" % JSON.stringify(q))
