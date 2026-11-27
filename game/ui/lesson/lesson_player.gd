class_name LessonPlayer
extends Control
## The lesson player (#218): plays a tutor lesson from its script (writing/explainers/,
## format 3, #216) on the wasteland chalkboard. Each line shows its caption while its clip
## plays and writes its board items with it. With no clip it holds the caption long
## enough to read, so a lesson plays on captions alone; a recorded take drops in by line
## id at res://assets/audio/voice/explainers/<script id>/<line id>.ogg.
##
## The player's actions pause the lesson until they are done: the call, tap questions
## (tap-line taps the board), the toy's tasks through game/docs/TOYS.md, build tiles, a
## typed part, and both kinds of turn (an engine question or the fixed fallback). A slip
## plays a stock reaction (reactions.json, #220), then the not-yet line, and the player
## goes again: there is no fail state and no score. The call is kept until the back_to
## that answers it. Each section is a part that can be replayed or skipped, at 0.75×, 1×
## or 1.5×, with captions on or off. At the end the lesson goes in the watched record.
##
##   var p := LessonPlayer.make(Lesson.load_id("ex.functions.function-machine"))
##   add_child(p)
##
## driver, when set, is a ScriptedRun (ui/lesson/scripted_run.gd): it answers every
## action the way a player would, for ./test.sh and the capture.

signal closed
## The lesson reached its end. The watched record has been written.
signal finished
## Something the player can act on is on screen: {"kind": "predict" | "ask" | "tap-line"
## | "toy" | "optional" | "build" | "typed" | "turn", "item": the beat}.
signal waiting(what: Dictionary)
## A line started: the line, as the script has it (a callback or reaction resolved).
signal line_started(line: Dictionary)

const VOICE_DIR := "res://assets/audio/voice/explainers/"
const SPEEDS := [0.75, 1.0, 1.5]
## Seconds at 1×: per word of a line with no clip, and its least; per board item written
## on its own; after a reaction.
const READ_PER_WORD := 0.36
const READ_MIN := 1.4
const WRITE_ALONE := 0.9
const CHALK_FADE := 0.5
const ACT_NAMES := {"signal": "1 · The signal", "play": "2 · Play", "paper": "3 · Put it on paper", "apply": "4 · Apply"}
const KIND_COLOURS := {"heading": Explainer.DUST, "term": Explainer.TEAL, "answer": Explainer.CHALK,
	"check": Explainer.TEAL, "note": Color(Explainer.CHALK, 0.7), "slip": Explainer.CHALK}
const TOUCH := 150.0

var lesson: Lesson
var save: Dictionary = {}
var save_path := SaveData.PATH
## "watched" or "not_watched" plays that recall version whatever the record says.
var recall := ""
var driver: RefCounted = null
var speed := 1.0
var captions := true
var paused := false
var reduced_motion := false
var callbacks: Dictionary = {}
var reactions: Lesson.Reactions
var verified_voice: Dictionary = {}
var allow_why_help := false

## Where the lesson is: the section playing, and the beats still to play in it.
var seg := -1
var queue: Array = []
## "" (play the next beat), "line" (a line or item is showing), "input" (the player's
## turn), "toy" (a toy task is in hand) or "done".
var state := ""
var wait := 0.0
## Stored calls, by predict id.
var calls := {}
## The board: {"text", "kind", "key", "struck", "figure"} items, oldest first, and a copy
## at the start of each section for a replay.
var board: Array = []
var _snapshots := {}
var _voiced := false
var _toy: LessonToy
var _toy_tasks: Array = []
var _toy_task: Dictionary = {}
var _toy_misses := 0
var _rng := RandomNumberGenerator.new()
var _input_item: Dictionary = {}

var frame: Control
var title: Label
var part_label: Label
var board_panel: PanelContainer
var board_scroll: ScrollContainer
var lines: VBoxContainer
var toy_holder: PanelContainer
var caption_box: PanelContainer
var caption: Label
var actions: VBoxContainer
var prompt: Control
var controls: HFlowContainer
var pause_button: Button
var replay_button: Button
var skip_button: Button
var speed_button: Button
var cc_button: Button
var close_button: Button


static func make(l: Lesson, with_save: Dictionary = {}) -> LessonPlayer:
	var p := LessonPlayer.new()
	p.name = "LessonPlayer"
	p.lesson = l
	p.save = with_save if not with_save.is_empty() else SaveData.load_from()
	return p


func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_rng.seed = 218
	_build()


func _ready() -> void:
	theme = UiTheme.make()
	callbacks = Lesson.shared("callbacks")
	verified_voice = Lesson.shared("voice-index")
	reactions = Lesson.Reactions.new(lesson.tutor(), Lesson.shared("reactions"), 220)
	reduced_motion = LessonToy.reduce_motion(save)
	title.text = str(lesson.data.get("title", "Lesson"))
	if not Explainer.plain_words(title.text):
		title.remove_theme_font_override("font")
	resized.connect(_fit)
	_fit()
	start_section(0)


func _exit_tree() -> void:
	Audio.stop_voice()


# ── Layout ───────────────────────────────────────────────────

func _build() -> void:
	var bg := ColorRect.new()
	bg.color = Explainer.INK
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	frame = VBoxContainer.new()
	frame.name = "Column"
	frame.add_theme_constant_override("separation", 16)
	add_child(frame)

	var head := HBoxContainer.new()
	head.name = "Head"
	head.add_theme_constant_override("separation", 20)
	var names := VBoxContainer.new()
	names.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title = UiTheme.label("", UiTheme.BIG, Explainer.DUST)
	title.name = "Title"
	title.add_theme_font_override("font", UiTheme.TITLE_FONT)
	names.add_child(title)
	part_label = UiTheme.label("", UiTheme.SMALL, Color(Explainer.CHALK, 0.7))
	part_label.name = "Part"
	names.add_child(part_label)
	head.add_child(names)
	# Clear of the speaker and gear in the top corner (AudioHud).
	var hud := Control.new()
	hud.custom_minimum_size.x = AudioHud.RESERVED_RIGHT
	head.add_child(hud)
	frame.add_child(head)

	board_panel = Explainer.Board.new()
	board_panel.name = "Board"
	board_panel.clip_contents = true
	board_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var bs := StyleBoxFlat.new()
	bs.bg_color = Explainer.SLATE
	bs.border_color = Explainer.SLATE_DEEP
	bs.set_border_width_all(8)
	bs.set_corner_radius_all(6)
	bs.set_content_margin_all(30)
	board_panel.add_theme_stylebox_override("panel", bs)
	board_scroll = ScrollContainer.new()
	board_scroll.name = "Scroll"
	board_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	board_panel.add_child(board_scroll)
	lines = VBoxContainer.new()
	lines.name = "Lines"
	lines.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lines.add_theme_constant_override("separation", 16)
	board_scroll.add_child(lines)
	frame.add_child(board_panel)

	toy_holder = PanelContainer.new()
	toy_holder.name = "ToyHolder"
	var ts := StyleBoxFlat.new()
	ts.bg_color = Explainer.SLATE_DEEP
	ts.border_color = Explainer.IRON
	ts.set_border_width_all(6)
	ts.set_corner_radius_all(8)
	ts.set_content_margin_all(16)
	toy_holder.add_theme_stylebox_override("panel", ts)
	toy_holder.size_flags_vertical = Control.SIZE_EXPAND_FILL
	toy_holder.visible = false
	frame.add_child(toy_holder)

	caption_box = PanelContainer.new()
	caption_box.name = "Captions"
	var cs := StyleBoxFlat.new()
	cs.bg_color = Color(Explainer.INK, 0.9)
	cs.border_color = Explainer.IRON_SHADE
	cs.set_border_width_all(3)
	cs.set_corner_radius_all(8)
	cs.set_content_margin_all(16)
	caption_box.add_theme_stylebox_override("panel", cs)
	caption = UiTheme.label("", UiTheme.BODY, Explainer.CHALK)
	caption.name = "Caption"
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	caption.custom_minimum_size.y = 130
	caption_box.add_child(caption)
	frame.add_child(caption_box)

	actions = VBoxContainer.new()
	actions.name = "Actions"
	actions.add_theme_constant_override("separation", 14)
	actions.visible = false
	frame.add_child(actions)

	controls = HFlowContainer.new()
	controls.name = "Controls"
	controls.add_theme_constant_override("h_separation", 14)
	controls.add_theme_constant_override("v_separation", 14)
	pause_button = _button("Pause", "Pause")
	pause_button.pressed.connect(toggle_pause)
	controls.add_child(pause_button)
	replay_button = _button("Replay", "Replay part")
	replay_button.pressed.connect(replay_section)
	controls.add_child(replay_button)
	skip_button = _button("Skip", "Skip part")
	skip_button.pressed.connect(skip_section)
	controls.add_child(skip_button)
	speed_button = _button("Speed", "1×")
	speed_button.pressed.connect(next_speed)
	controls.add_child(speed_button)
	cc_button = _button("CC", "CC")
	cc_button.toggle_mode = true
	cc_button.button_pressed = true
	cc_button.toggled.connect(set_captions)
	controls.add_child(cc_button)
	close_button = _button("Close", "Close")
	close_button.pressed.connect(close)
	controls.add_child(close_button)
	frame.add_child(controls)


func _button(id: String, text: String) -> Button:
	var b := Button.new()
	b.name = id
	b.text = text
	b.add_theme_font_size_override("font_size", UiTheme.SMALL)
	b.custom_minimum_size.y = TOUCH
	return b


func _fit() -> void:
	var wide := size.x > size.y
	var w := minf(size.x - 48.0, 1700.0 if wide else 1040.0)
	frame.set_anchors_preset(Control.PRESET_CENTER_TOP)
	frame.offset_left = -w / 2.0
	frame.offset_right = w / 2.0
	frame.offset_top = 24.0 + (0.0 if wide else 90.0)
	frame.offset_bottom = size.y - 24.0
	frame.set_anchor(SIDE_BOTTOM, 0.0)


# ── Sections ─────────────────────────────────────────────────

## Start a section from its first beat, with the board as it was when it began.
func start_section(i: int) -> void:
	_end_input()
	_remove_toy()
	Audio.stop_voice()
	var all := lesson.sections()
	if i >= all.size():
		_finish_lesson()
		return
	seg = i
	if _snapshots.has(i):
		_set_board(_snapshots[i])
	else:
		_snapshots[i] = board.duplicate(true)
	var s: Dictionary = all[i]
	queue = _beats_for(s).duplicate()
	state = ""
	wait = 0.0
	var act := str(s.get("act", ""))
	part_label.text = "%s  ·  part %d of %d" % [ACT_NAMES.get(act, act.capitalize()) if act != "" else str(s.get("kind", "")).capitalize(), i + 1, all.size()]
	_step_now()


func _beats_for(s: Dictionary) -> Array:
	if s.has("turn"):
		var t: Dictionary = s.turn
		var out: Array = t.get("intro", []).duplicate()
		out.append({"_turn": t})
		return out
	return lesson.beats_of(s, watched(), recall)


func section() -> Dictionary:
	return lesson.sections()[seg] if seg >= 0 and seg < lesson.sections().size() else {}


func replay_section() -> void:
	if state == "done":
		_snapshots.clear()
		board = []
		_set_board([])
		start_section(0)
		return
	start_section(seg)


## Skip to the next part. The skipped part's board is written in full, so later parts
## that refer to it still read.
func skip_section() -> void:
	if state == "done" or seg < 0:
		return
	_end_input()
	_remove_toy()
	for b in queue:
		_settle(b)
	start_section(seg + 1)


func _settle(b: Variant) -> void:
	if not b is Dictionary:
		return
	if b.has("board"):
		for item in b.board:
			_write(item, false)
	if b.has("write") or b.has("figure") or b.has("strike"):
		_write(b, false)
	if b.has("build"):
		for st in b.build.get("steps", []):
			_write(st.tiles[int(st.get("answer", 0))], false)
	if b.has("toy"):
		for t in b.get("tasks", []):
			for x in t.get("then", []):
				_settle(x)


func _finish_lesson() -> void:
	state = "done"
	queue = []
	_remove_toy()
	_show_caption("End of transmission.")
	part_label.text = "Done  ·  Replay part starts again"
	var w := watched()
	if not w.has(lesson.id()):
		w.append(lesson.id())
	save["watched"] = w
	if save_path != "":
		SaveData.store(save, save_path)
	finished.emit()


## The watched record: explainer ids, oldest first.
func watched() -> Array:
	return save.get("watched", [])


# ── The beat loop ────────────────────────────────────────────

func _process(delta: float) -> void:
	if paused or state == "done":
		return
	advance(delta * speed)


## Moves the lesson on by dt seconds at 1×. The scripted run calls this too.
func advance(dt: float) -> void:
	if state == "line":
		wait -= dt
		if wait > 0.0:
			return
		state = ""
	_step_now()


func _step_now() -> void:
	while state == "":
		if queue.is_empty():
			start_section(seg + 1)
			return
		_play(queue.pop_front())


func _play(b: Dictionary) -> void:
	if b.has("line") or b.has("use"):
		_say(_resolve(b))
	elif b.has("write") or b.has("figure") or b.has("strike"):
		_write(b, true)
		_hold(WRITE_ALONE)
	elif b.has("predict"):
		_ask_predict(b.predict)
	elif b.has("back_to"):
		queue = lesson.back_to_lines(b.back_to, calls.get(str(b.back_to.get("predict", "")))) + queue
	elif b.has("ask"):
		_ask(b.ask, int(b.get("_misses", 0)))
	elif b.has("toy"):
		_start_toy(b)
	elif b.has("_toy_next"):
		_toy_next()
	elif b.has("build"):
		_build_step(b.build, int(b.get("_step", 0)), int(b.get("_misses", 0)), b.get("_gone", []))
	elif b.has("typed"):
		_typed(b.typed, int(b.get("_misses", 0)))
	elif b.has("_turn"):
		_turn(b._turn, int(b.get("_part", 0)), int(b.get("_misses", 0)), b.get("_question", {}))
	elif b.has("_lit"):
		_show_banner(str(b._lit), b.get("_good", true))
		_hold(0.6)


func _hold(t: float) -> void:
	state = "line"
	wait = t


## A callback ({"use": "<tutor>.<key>"}) as its line.
func _resolve(b: Dictionary) -> Dictionary:
	if not b.has("use"):
		return b
	var u := str(b.use)
	var dot := u.find(".")
	var l: Dictionary = callbacks.get("tutors", {}).get(u.substr(0, dot), {}).get("lines", {}).get(u.substr(dot + 1), {})
	if l.is_empty():
		return {"line": "", "say": "", "speaker": ""}
	var out := l.duplicate()
	out["_from"] = "callbacks"
	return out


## Show a line: its caption, its board items, its clip. It holds until the clip ends, or
## long enough to read.
func _say(l: Dictionary) -> void:
	if l.get("clear", false):
		_set_board([])
	for item in l.get("board", []):
		_write(item, true)
	var text := str(l.get("caption", l.get("say", "")))
	var cue := str(l.get("cue", ""))
	if cue != "":
		text = "(%s) %s" % [cue, text] if l.get("cue_at", "start") == "start" else "%s (%s)" % [text, cue]
	_show_caption(text)
	var stream := clip_for(l)
	var hold := maxf(READ_MIN, str(l.get("say", "")).split(" ", false).size() * READ_PER_WORD)
	if stream != null:
		hold = stream.get_length()
		Audio.play_voice(stream, speed)
	_hold(hold + float(l.get("pause", 0.0)))
	line_started.emit(l)


## A line's recorded take, or null: by script id (or callbacks, reactions) and line id.
func clip_for(l: Dictionary) -> AudioStream:
	var id := str(l.get("line", ""))
	var from := str(l.get("_from", lesson.id()))
	var cue := [l.get("speaker"), l.get("say", l.get("caption")), l.get("cue"), l.get("cue_at")]
	if id == "" or verified_voice.get(from, {}).get(id) != cue:
		return null
	var path := "%s%s/%s.ogg" % [VOICE_DIR, from, id]
	return load(path) as AudioStream if ResourceLoader.exists(path) else null


func _show_caption(text: String) -> void:
	caption.remove_theme_color_override("font_color")
	caption.text = text
	caption_box.modulate.a = 1.0 if captions else 0.0


## A stock reaction, over whatever is on screen: the toy keeps taking input.
func _react(l: Dictionary) -> void:
	if l.is_empty():
		return
	var r := l.duplicate()
	r["_from"] = "reactions"
	_show_caption(str(r.get("caption", r.get("say", ""))))
	var stream := clip_for(r)
	if stream != null:
		Audio.play_voice(stream, speed)
	line_started.emit(r)


# ── The board ────────────────────────────────────────────────

func _write(item: Dictionary, animate: bool) -> void:
	if item.has("strike"):
		for b in board:
			if b.get("key", "") == str(item.strike):
				b.struck = true
		_set_board(board)
		return
	var text := str(item.get("write", ""))
	if item.has("figure"):
		# Figures aren't drawn yet (README, "Figures"): the board shows the alt text.
		text = str(item.get("alt", "A figure."))
	var b := {"text": text, "kind": str(item.get("kind", "step")), "key": str(item.get("key", "")),
		"struck": false, "figure": item.has("figure")}
	board.append(b)
	var row := _row(b)
	lines.add_child(row)
	if animate and not reduced_motion:
		row.modulate.a = 0.0
		create_tween().tween_property(row, "modulate:a", 1.0, CHALK_FADE / speed)
	_show_row.call_deferred(row)


func _show_row(row: Control) -> void:
	if is_instance_valid(row) and board_scroll.is_ancestor_of(row):
		board_scroll.ensure_control_visible(row)


func _set_board(items: Array) -> void:
	board = items.duplicate(true)
	for c in lines.get_children():
		lines.remove_child(c)
		c.queue_free()
	for b in board:
		lines.add_child(_row(b))


func _row(b: Dictionary) -> Control:
	var row := Row.new()
	row.name = "Line%d" % lines.get_child_count()
	row.key = b.key
	row.struck = b.struck
	var colour: Color = KIND_COLOURS.get(b.kind, Explainer.CHALK)
	var l := UiTheme.math(b.text, UiTheme.BODY if b.kind != "heading" else UiTheme.BIG, colour)
	if b.figure:
		l = UiTheme.label(b.text, UiTheme.SMALL, Color(Explainer.CHALK, 0.7))
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(l)
	return row


## The board row with a key, or null.
func row_for(key: String) -> Control:
	for r in lines.get_children():
		if r is Row and r.key == key:
			return r
	return null


# ── The player's turn ────────────────────────────────────────

func _wait_for(kind: String, item: Dictionary, prompt_text: String) -> void:
	_end_input()
	state = "input"
	_input_item = item
	actions.visible = true
	if prompt_text != "":
		prompt = UiTheme.math(prompt_text, UiTheme.BODY, Explainer.DUST)
		prompt.name = "Prompt"
		actions.add_child(prompt)
	waiting.emit({"kind": kind, "item": item})
	if driver != null:
		driver.call_deferred("act", self, kind, item)


func _end_input() -> void:
	for c in actions.get_children():
		actions.remove_child(c)
		c.queue_free()
	actions.visible = false
	for r in lines.get_children():
		if r is Row:
			r.tappable = false
			for c in r.tapped.get_connections():
				r.tapped.disconnect(c.callable)
	_input_item = {}


func _resume(beats: Array) -> void:
	_end_input()
	queue = beats + queue
	state = ""
	_step_now()


func _choice_buttons(texts: Array, on_pick: Callable) -> Array:
	var box := VBoxContainer.new()
	box.name = "Choices"
	box.add_theme_constant_override("separation", 12)
	var out: Array = []
	for i in texts.size():
		var b := Button.new()
		b.name = "Choice%d" % i
		b.custom_minimum_size.y = TOUCH
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		UiTheme.math_button(b, str(texts[i]))
		b.pressed.connect(on_pick.bind(i))
		box.add_child(b)
		out.append(b)
	actions.add_child(box)
	return out


## A typed box with the game's keypad, and a send button. on_send gets the text.
func _entry(on_send: Callable) -> MathEntry:
	var row := HBoxContainer.new()
	row.name = "Entry"
	row.add_theme_constant_override("separation", 14)
	var e := MathEntry.new()
	e.name = "Box"
	e.custom_minimum_size = Vector2(260, TOUCH * 0.8)
	e.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	e.text_submitted.connect(func(_t): on_send.call(e.text))
	row.add_child(e)
	var send := Button.new()
	send.name = "Send"
	send.text = "Send"
	send.custom_minimum_size = Vector2(220, TOUCH)
	send.pressed.connect(func(): on_send.call(e.text))
	row.add_child(send)
	actions.add_child(row)
	var pad := Keypad.make_answer()
	pad.key.connect(func(k: String): e.press(k))
	actions.add_child(pad)
	_grab.call_deferred(e)
	return e


func _grab(c: Control) -> void:
	if is_instance_valid(c) and c.is_inside_tree():
		c.grab_focus()


## An engine question's answer boxes, as its template lays them out (the maths round the
## boxes, a box per slot, a button row per pick), with the keypad and a send button.
## on_send gets the response QuestionEngine.mark takes.
func _slots(q: Dictionary, on_send: Callable) -> void:
	var flow := HFlowContainer.new()
	flow.name = "Slots"
	flow.add_theme_constant_override("h_separation", 8)
	flow.add_theme_constant_override("v_separation", 12)
	var boxes := {}
	var picks := {}
	var focus: Array = [null]
	for item in q.answer.template:
		if item is String:
			if item != "":
				flow.add_child(UiTheme.math(item, UiTheme.BODY, Explainer.CHALK))
		elif item.has("slot"):
			var e := MathEntry.new()
			e.name = "Slot_" + str(item.slot)
			e.custom_minimum_size = Vector2(150, TOUCH * 0.8)
			e.focus_entered.connect(func(): focus[0] = e)
			flow.add_child(e)
			boxes[str(item.slot)] = e
			if focus[0] == null:
				focus[0] = e
		else:
			var group := ButtonGroup.new()
			picks[str(item.pick)] = ""
			for opt in item.options:
				var b := Button.new()
				b.toggle_mode = true
				b.button_group = group
				b.custom_minimum_size.y = TOUCH * 0.8
				UiTheme.math_button(b, str(opt))
				b.pressed.connect(func(): picks[str(item.pick)] = str(opt))
				flow.add_child(b)
	actions.add_child(flow)
	var send := Button.new()
	send.name = "Send"
	send.text = "Send"
	send.custom_minimum_size.y = TOUCH * 0.8
	send.pressed.connect(func():
		var resp := picks.duplicate()
		for k in boxes:
			resp[k] = boxes[k].text
		on_send.call(resp))
	actions.add_child(send)
	if not boxes.is_empty():
		var pad := Keypad.make_answer()
		pad.key.connect(func(k: String):
			if focus[0] != null:
				focus[0].press(k))
		actions.add_child(pad)
		_grab.call_deferred(focus[0])


## The call (act 1): typed, a dial or a choice. Stored and never marked.
func _ask_predict(p: Dictionary) -> void:
	_wait_for("predict", p, str(p.get("prompt", "Your call.")))
	var keep := func(v: String) -> void:
		if Lesson.norm(v) == "":
			return
		calls[str(p.get("id", ""))] = v
		_resume([])
	match str(p.get("kind", "type")):
		"choose":
			_choice_buttons(p.get("choices", []), func(i: int): keep.call(str(p.choices[i])))
		"dial":
			var d: Array = p.get("dial", [0, 10])
			var spin := SpinBox.new()
			spin.name = "Dial"
			spin.min_value = float(d[0])
			spin.max_value = float(d[1])
			spin.custom_minimum_size.y = TOUCH * 0.8
			actions.add_child(spin)
			var send := Button.new()
			send.name = "Send"
			send.text = "Send"
			send.custom_minimum_size.y = TOUCH * 0.8
			send.pressed.connect(func(): keep.call(RelayToy.num(spin.value)))
			actions.add_child(send)
		_:
			_entry(keep)


## A tap question: choices, or a tap on a board line. A right tap plays its right lines;
## a slip plays the not-yet line, then asks again (format 2 lessons move on).
func _ask(a: Dictionary, misses: int) -> void:
	var tap := str(a.get("kind", "")) == "tap-line"
	_wait_for("tap-line" if tap else "ask", a, str(a.get("prompt", "")))
	var pick := func(i: int) -> void:
		if i == int(a.get("answer", 0)):
			_resume(a.get("right", []))
			return
		var again: Array = a.get("not_yet", []).duplicate()
		if int(lesson.data.get("format", 2)) >= 3:
			again.append({"ask": a, "_misses": misses + 1})
		_resume(again)
	if tap:
		var keys: Array = a.get("choices", [])
		for i in keys.size():
			var r := row_for(str(keys[i]))
			if r != null:
				r.tappable = true
				r.tapped.connect(pick.bind(i))
	else:
		_choice_buttons(a.get("choices", []), pick)
		if allow_why_help and str(a.get("kind", "")) == "why" and misses > 0:
			var help := _button("ExplainWhy", "Explain why")
			help.pressed.connect(func(): _resume(a.get("right", [])))
			actions.add_child(help)


## Answer a tap-line question by its key, as a tap on the line does.
func tap_line(key: String) -> void:
	var r := row_for(key)
	if r != null and r.tappable:
		r.tapped.emit()


# ── Toys (game/docs/TOYS.md) ─────────────────────────────────

func _start_toy(item: Dictionary) -> void:
	_remove_toy()
	var toy := Toys.make(item)
	if toy == null:
		push_warning("lesson %s: toy %s can't be built: %s" % [lesson.id(), item.get("toy"), Toys.check(item)])
		return
	_toy = toy
	toy.reduced_motion = reduced_motion
	toy.set_anchors_preset(Control.PRESET_FULL_RECT)
	toy.acted.connect(_on_toy_act)
	toy.task_done.connect(_on_toy_done)
	toy_holder.add_child(toy)
	toy_holder.visible = true
	# The toy takes the room; the board keeps a strip for what the lesson writes.
	board_panel.size_flags_stretch_ratio = 0.3
	_toy_tasks = item.get("tasks", []).duplicate()
	if item.get("optional", false):
		_wait_for("optional", item, str(item.get("prompt", "Have a go on this one?")))
		var row := HBoxContainer.new()
		row.name = "Optional"
		row.add_theme_constant_override("separation", 14)
		var go := Button.new()
		go.name = "Try"
		go.text = "Try it"
		go.custom_minimum_size = Vector2(300, TOUCH)
		go.pressed.connect(func():
			_end_input()
			_toy_next()
			_step_now())
		row.add_child(go)
		var skip := Button.new()
		skip.name = "SkipToy"
		skip.text = "Skip"
		skip.custom_minimum_size = Vector2(300, TOUCH)
		skip.pressed.connect(func():
			_remove_toy()
			_resume([]))
		row.add_child(skip)
		actions.add_child(row)
		toy.mouse_filter = Control.MOUSE_FILTER_IGNORE
		return
	_toy_next()


func _toy_next() -> void:
	if _toy == null or _toy_tasks.is_empty():
		state = ""
		return
	var t: Dictionary = _toy_tasks.pop_front()
	_toy_task = t
	_toy_misses = 0
	_toy.mouse_filter = Control.MOUSE_FILTER_STOP
	_toy.start(t)
	state = "toy"
	waiting.emit({"kind": "toy", "item": t})
	if driver != null:
		driver.call_deferred("act", self, "toy", t)


func _on_toy_act(a: Dictionary) -> void:
	if a.get("hit") == false:
		_react(reactions.slip(_toy_misses))
		_toy_misses += 1
	elif a.get("hit") == null and state == "toy":
		_react(reactions.ack())


## The task is met: its then beats play, and the next task follows them. Deferred, as
## the toy is still inside its send.
func _on_toy_done(_result: Dictionary) -> void:
	if state != "toy":
		return
	var then: Array = _toy_task.get("then", []).duplicate()
	then.append({"_toy_next": true})
	queue = then + queue
	state = ""
	_step_now.call_deferred()


## The toy on screen, for the scripted run and tests.
func toy() -> LessonToy:
	return _toy


func _remove_toy() -> void:
	if _toy != null:
		_toy.queue_free()
		_toy = null
	_toy_tasks = []
	_toy_task = {}
	toy_holder.visible = false
	board_panel.size_flags_stretch_ratio = 1.0


# ── Builds ───────────────────────────────────────────────────

## One build step: three tiles, shuffled. The right one goes on the board. A wrong one
## sparks off, a reaction plays, then its not-yet line, and the player picks again.
func _build_step(build: Dictionary, step: int, misses: int, gone: Array) -> void:
	var steps: Array = build.get("steps", [])
	if step >= steps.size():
		return
	var st: Dictionary = steps[step]
	_wait_for("build", {"build": build, "step": step}, "Pick the next line." if step == 0 else "And the next line.")
	var order: Array = range(st.tiles.size())
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(lesson.id()) + step
	for i in range(order.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp = order[i]
		order[i] = order[j]
		order[j] = tmp
	var box := VBoxContainer.new()
	box.name = "Tiles"
	box.add_theme_constant_override("separation", 12)
	for i in order:
		var b := Button.new()
		b.name = "Tile%d" % i
		b.custom_minimum_size.y = TOUCH
		UiTheme.math_button(b, str(st.tiles[i].get("write", "")))
		b.disabled = gone.has(i)
		b.pressed.connect(_pick_tile.bind(build, step, i, misses, gone))
		box.add_child(b)
	actions.add_child(box)


func _pick_tile(build: Dictionary, step: int, i: int, misses: int, gone: Array) -> void:
	var st: Dictionary = build.steps[step]
	if i == int(st.get("answer", 0)):
		_write(st.tiles[i], true)
		var next: Array = []
		# A right tile has no line of its own, so an ack can play, as a line before the next.
		var ack := reactions.ack()
		if not ack.is_empty():
			var r := ack.duplicate()
			r["_from"] = "reactions"
			next.append(r)
		if step + 1 < build.steps.size():
			next.append({"build": build, "_step": step + 1})
		_resume(next)
		return
	_show_banner("Sparked off the board.", false)
	var after: Array = []
	var slip := reactions.slip(misses)
	if not slip.is_empty():
		var r := slip.duplicate()
		r["_from"] = "reactions"
		after.append(r)
	for l in st.get("not_yet", []):
		# JSON numbers are floats, and Array.has doesn't match 1.0 to 1.
		if (l.get("for", []) as Array).any(func(n): return int(n) == i):
			after.append(l)
			break
	var g: Array = gone.duplicate()
	g.append(i)
	after.append({"build": build, "_step": step, "_misses": misses + 1, "_gone": g})
	_resume(after)


# ── Typed parts ──────────────────────────────────────────────

func _typed(item: Dictionary, misses: int) -> void:
	_wait_for("typed", item, str(item.get("prompt", "")))
	_entry(func(text: String) -> void:
		var m := Lesson.mark_typed(item, text)
		if m.get("empty", false):
			return
		if m.right:
			_resume(item.get("right", []))
			return
		var after: Array = []
		var slip := reactions.slip(misses)
		if not slip.is_empty():
			var r := slip.duplicate()
			r["_from"] = "reactions"
			after.append(r)
		after.append_array(Lesson.not_yet_for(item.get("not_yet", []), m.misconception, misses))
		after.append({"typed": item, "_misses": misses + 1})
		_resume(after))


# ── Turns ────────────────────────────────────────────────────

## The question an engine turn serves: one of its cell's, made live.
func turn_question(t: Dictionary) -> Dictionary:
	var c: Dictionary = t.get("cell", {})
	var view := {"type": c.get("type", ""), "unknown": c.get("unknown", ""), "rep": c.get("rep", ""),
		"angle": c.get("angle", "any"), "format": c.get("format", "value")}
	for i in 20:
		view.seed = _rng.randi_range(1, VerifiedSeeds.LAST)
		var q := QuestionEngine.make(view)
		if not q.has("error"):
			return q
	return {}


## A your-turn. An engine turn asks one live question, a fallback turn its fixed parts in
## order. Right lights the mast and plays a right line; a slip gets static, the not-yet
## line for its misconception (or the neutral one), and the player goes again. After a
## slip, "Show me" writes the working and moves on.
func _turn(t: Dictionary, part: int, misses: int, q: Dictionary) -> void:
	var engine := str(t.get("serve", "fallback")) == "engine"
	var fb: Dictionary = t.get("fallback", {})
	if engine and q.is_empty():
		q = turn_question(t)
		if q.is_empty():
			engine = false
	var text := ""
	if engine:
		text = QuestionEngine.shown_prompt(q)
	else:
		var p: Dictionary = fb.parts[part]
		text = "%s\n%s%s" % [fb.get("setup", ""), "(%s) " % p.part if p.has("part") else "", p.get("text", "")]
	_wait_for("turn", {"turn": t, "part": part, "question": q, "engine": engine}, text)
	var on_send := func(typed: Variant) -> void:
		var right := false
		var mis := ""
		if engine:
			var r := QuestionEngine.mark(q, typed)
			if not r.complete:
				return
			right = r.correct
			mis = str(r.get("misconception", ""))
		else:
			var m := Lesson.mark_typed(Lesson.part_item(fb.parts[part]), str(typed))
			if m.get("empty", false):
				return
			right = m.right
			mis = m.misconception
		if right:
			if not engine and part + 1 < fb.parts.size():
				_resume([{"_lit": "Part copied.", "_good": true}, {"_turn": t, "_part": part + 1}])
				return
			_resume(_turn_done(t, fb, engine, q, true))
			return
		var after: Array = [{"_lit": "Static.", "_good": false}]
		after.append_array(Lesson.not_yet_for(t.get("not_yet", []), mis, misses + part))
		after.append({"_turn": t, "_part": part, "_misses": misses + 1, "_question": q})
		_resume(after)
	if engine:
		_slots(q, on_send)
	else:
		_entry(on_send)
	if misses > 0:
		var show := Button.new()
		show.name = "ShowMe"
		show.text = "Show me"
		show.custom_minimum_size.y = TOUCH * 0.8
		show.pressed.connect(func(): _resume(_turn_done(t, fb, engine, q, false)))
		actions.add_child(show)


## What plays when a turn ends: the signal goes out (or the working is shown), the
## working goes on the board, and a right line plays.
func _turn_done(t: Dictionary, fb: Dictionary, engine: bool, q: Dictionary, right: bool) -> Array:
	var out: Array = [{"_lit": "Signal's out." if right else "Here's the working.", "_good": true}]
	var steps: Array = []
	if engine and not q.get("solutions", []).is_empty():
		for st in q.solutions[0].steps:
			steps.append(Step.text(st))
	else:
		steps = fb.get("working", [])
	for s in steps:
		_write({"write": str(s), "kind": "step"}, false)
	if right:
		var r: Array = t.get("right", [])
		if not r.is_empty():
			out.append(r[_rng.randi_range(0, r.size() - 1)])
	return out


## What happened in the world, in the caption's place: teal when the signal goes out,
## rust for static or a sparked tile. The next line's caption puts the colour back.
func _show_banner(text: String, good: bool) -> void:
	_show_caption(text)
	caption.add_theme_color_override("font_color", Explainer.TEAL if good else Explainer.RUST)


# ── Controls ─────────────────────────────────────────────────

func toggle_pause() -> void:
	paused = not paused
	pause_button.text = "Play" if paused else "Pause"
	Audio.pause_voice(paused)


func next_speed() -> void:
	speed = SPEEDS[(SPEEDS.find(speed) + 1) % SPEEDS.size()]
	speed_button.text = Explainer.speed_text(speed)
	Audio.set_voice_speed(speed)


func set_captions(on: bool) -> void:
	captions = on
	cc_button.set_pressed_no_signal(on)
	caption_box.modulate.a = 1.0 if on else 0.0


func close() -> void:
	Audio.stop_voice()
	closed.emit()
	queue_free()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()


## A board line. One with a key can be tapped for a tap-line question, and struck out.
class Row extends PanelContainer:
	signal tapped
	var key := ""
	var struck := false:
		set(v):
			struck = v
			queue_redraw()
	var tappable := false:
		set(v):
			tappable = v
			mouse_filter = Control.MOUSE_FILTER_STOP if v else Control.MOUSE_FILTER_IGNORE
			custom_minimum_size.y = LessonPlayer.TOUCH * 0.7 if v else 0.0
			queue_redraw()

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_theme_stylebox_override("panel", StyleBoxEmpty.new())

	func _gui_input(e: InputEvent) -> void:
		if tappable and e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT and not e.pressed:
			accept_event()
			tapped.emit()

	func _draw() -> void:
		if tappable:
			draw_rect(Rect2(Vector2.ZERO, size), Color(Explainer.TEAL, 0.12))
			draw_rect(Rect2(Vector2.ZERO, size), Explainer.TEAL, false, 3.0)
		if struck:
			var y := size.y / 2.0
			draw_line(Vector2(0, y), Vector2(size.x, y), Explainer.RUST, 5.0)
