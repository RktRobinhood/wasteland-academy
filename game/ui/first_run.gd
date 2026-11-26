class_name FirstRun
extends Control
## A new student's first minutes (FAL-1041, GitHub #186). Two overlays, wording from
## writing/first-run.md:
##   FirstRun.course_pick()  asks for the course once, on a blank save (the map shows it
##                           before The Wasteland opens). Nothing is pre-picked
##   FirstRun.fight_cards()  four skippable cards on how a fight works, shown before the
##                           first question of the first run, and again from Settings
## Each is a full-screen Control that frees itself. `finished` fires with the picked
## course id for the pick, and with "" for the cards.

signal finished(result: String)

const COURSE_HEADING := "Which maths course are you taking?"
const COURSE_LINE := "You'll only get questions from your course. You can change it later in Settings."
const COURSE_UNSURE := "Not sure which one? Ask your teacher."
const COURSE_BUILDING := "Still being built: some topics have no questions yet."
const COURSE_LINES := {
	"aa-sl": "Algebra, functions, trigonometry, statistics and calculus, with some proof.",
	"aa-hl": "Everything in AA SL, plus more proof, complex numbers, vectors and harder calculus.",
	"ai-sl": "Maths for modelling real situations, with lots of statistics and a calculator to hand.",
	"ai-hl": "Everything in AI SL, plus matrices, graph theory, vectors and more statistics.",
}
## Title and body of each fight card.
const CARDS := [
	["Right answers hit",
		"Get a question right and you hit the enemy. Get it wrong and you take damage, and the worked solution shows you how it goes.\n\nAt 0 HP the run ends. You keep all the Scrap you earned."],
	["Beat the timer",
		"The timer bar runs from green to orange to red. A right answer in the red still hits, but you take a little damage.\n\nIf the timer runs out, you take full damage plus 10."],
	["Lock it in",
		"Tap a choice, or type on the keypad. For a fraction, type the top, tap the fraction key, then type the bottom. Then tap Lock in.\n\nPaper 2 questions have a Calculator button. The timer keeps running while it's open. Paper 1 means no calculator."],
	["Three lifelines",
		"You get one of each every run.\n\n50-50 takes away two wrong choices.\nHint shows the first step of the worked solution.\nFreeze stops the timer for 15 seconds.\n\nThe Bazaar sells extra charges for Scrap."],
]

## The frame's margin on every side.
const MARGIN := 48

var picked := ""
var continue_button: Button
var card_at := 0
var _body: VBoxContainer


## The course question. Nothing is pre-picked; Continue opens once a course is.
static func course_pick() -> FirstRun:
	var f := FirstRun.new()
	f.name = "CoursePick"
	f._frame()
	f._build_course()
	return f


## The "How a fight works" cards, starting at the first.
static func fight_cards() -> FirstRun:
	var f := FirstRun.new()
	f.name = "FightCards"
	f._frame()
	f._show_card(0)
	return f


func _frame() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var bg := ColorRect.new()
	bg.color = Color(UiTheme.BG, 0.98)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, MARGIN)
	add_child(margin)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	margin.add_child(scroll)
	_body = VBoxContainer.new()
	_body.name = "Body"
	_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_body.add_theme_constant_override("separation", 22)
	scroll.add_child(_body)


func _clear() -> void:
	for c in _body.get_children():
		_body.remove_child(c)
		c.queue_free()


func _heading(text: String) -> void:
	var h := UiTheme.label(text, 84, UiTheme.TEAL)
	h.name = "Heading"
	h.add_theme_font_override("font", UiTheme.TITLE_FONT)
	# Wraps clear of the speaker and gear in the top-right corner (FAL-1608): the frame
	# is already MARGIN in from the edge.
	var clear := StyleBoxEmpty.new()
	clear.content_margin_right = AudioHud.RESERVED_RIGHT - MARGIN
	h.add_theme_stylebox_override("normal", clear)
	_body.add_child(h)


# ── Course ───────────────────────────────────────────────────

func _build_course() -> void:
	_clear()
	_heading(COURSE_HEADING)
	_body.add_child(UiTheme.label(COURSE_LINE, UiTheme.BODY, UiTheme.DIM))
	for id in Courses.ids():
		var info := Courses.info(id)
		var b := Button.new()
		b.name = id
		b.toggle_mode = true
		b.set_pressed_no_signal(id == picked)
		b.custom_minimum_size.y = 200
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.add_theme_font_size_override("font_size", UiTheme.BIG)
		var line := String(COURSE_LINES.get(id, ""))
		b.text = "%s\n%s" % [info.short, info.name]
		b.pressed.connect(_pick.bind(id))
		_body.add_child(b)
		var small := UiTheme.label(line, UiTheme.SMALL, UiTheme.DIM)
		small.name = id + "Line"
		_body.add_child(small)
		if info.status != "live":
			var tag := UiTheme.label(COURSE_BUILDING, UiTheme.SMALL, UiTheme.SAND)
			tag.name = id + "Tag"
			_body.add_child(tag)
	_body.add_child(UiTheme.label(COURSE_UNSURE, UiTheme.SMALL, UiTheme.DIM))
	continue_button = Button.new()
	continue_button.name = "Continue"
	continue_button.text = "Continue"
	continue_button.disabled = picked == ""
	continue_button.add_theme_font_size_override("font_size", UiTheme.BIG)
	continue_button.custom_minimum_size.y = 120
	continue_button.pressed.connect(_continue)
	_body.add_child(continue_button)
	# Keyboard focus starts on the first course, not on the screen underneath (FAL-1042).
	_focus.call_deferred(_body.get_node(Courses.ids()[0]))


func _pick(id: String) -> void:
	picked = id
	for c in Courses.ids():
		(_body.get_node(c) as Button).set_pressed_no_signal(c == id)
	continue_button.disabled = false


func _continue() -> void:
	if picked == "":
		return
	finished.emit(picked)
	queue_free()


# ── Cards ────────────────────────────────────────────────────

func _show_card(i: int) -> void:
	card_at = clampi(i, 0, CARDS.size() - 1)
	_clear()
	var top := UiTheme.label("How a fight works · %d of %d" % [card_at + 1, CARDS.size()], UiTheme.SMALL, UiTheme.DIM)
	top.name = "Count"
	_body.add_child(top)
	_heading(CARDS[card_at][0])
	var text := UiTheme.label(CARDS[card_at][1], UiTheme.BIG)
	text.name = "Text"
	_body.add_child(text)
	var row := HBoxContainer.new()
	row.name = "Buttons"
	row.add_theme_constant_override("separation", 24)
	_body.add_child(row)
	var last := card_at == CARDS.size() - 1
	var go := Button.new()
	go.name = "Done" if last else "Next"
	go.text = "Got it" if last else "Next"
	go.add_theme_font_size_override("font_size", UiTheme.BIG)
	go.custom_minimum_size = Vector2(300, 120)
	go.pressed.connect(_done if last else _show_card.bind(card_at + 1))
	row.add_child(go)
	if not last:
		var skip := Button.new()
		skip.name = "Skip"
		skip.text = "Skip"
		skip.add_theme_font_size_override("font_size", UiTheme.BIG)
		skip.custom_minimum_size = Vector2(300, 120)
		skip.pressed.connect(_done)
		row.add_child(skip)
	_focus.call_deferred(go)


func _focus(b: Button) -> void:
	if is_instance_valid(b) and b.is_inside_tree():
		b.grab_focus()


func _done() -> void:
	finished.emit("")
	queue_free()
