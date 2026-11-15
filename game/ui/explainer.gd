class_name Explainer
extends Control
## The explainer player (FAL-429): a worked solution played like a video on a wasteland
## chalkboard. One chapter per step: the chalk writes the step's board while Spark says
## its move's line (curriculum/moves.json), one of the move's two takes picked at random.
## A step with no move plays silent, its chalk line captioned. Play and pause, a scrub
## bar with a mark per step, replay this step, CC (on to start, as sound starts off), and
## 0.75×, 1× and 1.5×. "New numbers" redraws the same view on a new seed, so the recipe
## picks numbers its rules accept and the voice still fits; "Your turn" at the end asks
## the host to set the student the same view with new numbers.
##
## It is an overlay, so any screen can play one:
##   add_child(Explainer.make(question, 0))      # question from QuestionEngine.make
## The look is "Salvage Ink" (tools/explainer-clips/lib/salvage-ink.js), so the player and
## the explainer clips are one family. The frame and the board are drawn, as placeholders.

signal closed
## The student asked for a question like this one. Carries the view, with a new seed.
signal your_turn(view: Dictionary)

## Salvage Ink (tools/explainer-clips/lib/salvage-ink.js).
const INK := Color("#0a0d14")
const CHALK := Color("#f3e6c4")
const SLATE := Color("#1a2330")
const SLATE_DEEP := Color("#10161f")
const IRON := Color("#4a5568")
const IRON_SHADE := Color("#2a3242")
const IRON_GLOSS := Color("#aab6cc")
const RUST := Color("#faa261")
const RUST_SHADE := Color("#b35a3c")
const TEAL := Color("#22d3c5")
const MAGENTA := Color("#ff3da7")
const DUST := Color("#eacb74")
const MONO := preload("res://assets/fonts/share-tech-mono-latin.woff2")
const SPARK := preload("res://assets/avatars/avatar-spark.png")

const SPEEDS := [0.75, 1.0, 1.5]
## Seconds, at 1×: how long the chalk takes per character, and its least and most.
const WRITE_PER_CHAR := 0.045
const WRITE_MIN := 0.9
const WRITE_MAX := 3.6
## A silent step stays up long enough to read its caption.
const READ_PER_WORD := 0.32
const READ_MIN := 1.6
## The pause after each step before the next one starts.
const HOLD := 0.7
## How many seeds "New numbers" tries for one with something to watch.
const RETRIES := 12

var question: Dictionary
var solution := 0
## Whether the host can set a question for "Your turn".
var turn_enabled := true
## The chapters: {"move", "board", "caption", "stream", "start", "write", "length"}.
var chapters: Array = []
var time := 0.0
var total := 0.0
var playing := false
var speed := 1.0
var captions := true
var current := -1

var frame: PanelContainer
var title: Label
var asked: Label
var board_scroll: ScrollContainer
var lines: VBoxContainer
var spark: TextureRect
var caption_box: PanelContainer
var caption: Label
var scrub: Scrub
var time_label: Label
var play_button: Button
var replay_button: Button
var dice_button: Button
var speed_button: Button
var cc_button: Button
var turn_button: Button
var close_button: Button
var _rng := RandomNumberGenerator.new()
var _spark_home := Vector2.ZERO


## A player for one of the question's worked solutions, ready to play.
static func make(q: Dictionary, sol := 0, with_turn := true) -> Explainer:
	var e := Explainer.new()
	e.name = "Explainer"
	e.turn_enabled = with_turn
	e._rng.randomize()
	e.load_question(q, sol)
	return e


## Whether a worked solution has a move to watch.
static func can_play(sol: Dictionary) -> bool:
	return Moves.any_tagged(sol.get("steps", []))


func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build()


func _ready() -> void:
	theme = UiTheme.make()
	resized.connect(_fit)
	_fit()
	_render(true)
	play_button.grab_focus.call_deferred()


func _exit_tree() -> void:
	Audio.stop_voice()


## Load a question's solution into the player, at the start, playing.
func load_question(q: Dictionary, sol := 0) -> void:
	question = q
	solution = clampi(sol, 0, maxi(0, q.get("solutions", []).size() - 1))
	_make_chapters()
	time = 0.0
	current = -1
	playing = not chapters.is_empty()
	if lines != null:
		_fill_board()
		_render(true)


func _make_chapters() -> void:
	chapters = []
	var at := 0.0
	var sols: Array = question.get("solutions", [])
	if sols.is_empty():
		total = 0.0
		return
	for st in sols[solution].steps:
		var move := Step.move(st)
		var board := Step.text(st)
		var line := Moves.say(move) if move != "" else board
		var stream: AudioStream = null
		if move != "":
			var path := Moves.voice(move, _rng.randi_range(1, Moves.TAKES))
			if ResourceLoader.exists(path):
				stream = load(path) as AudioStream
		var write := clampf(board.length() * WRITE_PER_CHAR, WRITE_MIN, WRITE_MAX)
		var read := maxf(READ_MIN, line.split(" ", false).size() * READ_PER_WORD)
		var voice := stream.get_length() if stream != null else 0.0
		var length := maxf(write, maxf(read, voice)) + HOLD
		chapters.append({"move": move, "board": board, "caption": line, "stream": stream,
			"start": at, "write": write, "length": length})
		at += length
	total = at


func _build() -> void:
	var dim := ColorRect.new()
	dim.name = "Dim"
	dim.color = Color(INK, 0.94)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	frame = Frame.new()
	frame.name = "Frame"
	var fs := StyleBoxFlat.new()
	fs.bg_color = IRON
	fs.border_color = IRON_SHADE
	fs.set_border_width_all(10)
	fs.set_corner_radius_all(14)
	fs.set_content_margin_all(40)
	fs.shadow_color = Color(0, 0, 0, 0.5)
	fs.shadow_size = 18
	frame.add_theme_stylebox_override("panel", fs)
	add_child(frame)
	var col := VBoxContainer.new()
	col.name = "Column"
	col.add_theme_constant_override("separation", 18)
	frame.add_child(col)

	var head := HBoxContainer.new()
	head.name = "Head"
	head.add_theme_constant_override("separation", 20)
	title = UiTheme.label("", 64, DUST)
	title.name = "Title"
	title.add_theme_font_override("font", UiTheme.TITLE_FONT)
	title.add_theme_color_override("font_outline_color", INK)
	title.add_theme_constant_override("outline_size", 12)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(title)
	close_button = _button("Close", "Close")
	close_button.pressed.connect(close)
	head.add_child(close_button)
	col.add_child(head)

	# The board, with Spark over its corner (a plain Control, so he keeps his size).
	var holder := Control.new()
	holder.name = "BoardHolder"
	holder.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(holder)
	var board := Board.new()
	board.name = "Board"
	board.set_anchors_preset(Control.PRESET_FULL_RECT)
	board.clip_contents = true
	var bs := StyleBoxFlat.new()
	bs.bg_color = SLATE
	bs.border_color = SLATE_DEEP
	bs.set_border_width_all(8)
	bs.set_corner_radius_all(6)
	bs.set_content_margin_all(36)
	board.add_theme_stylebox_override("panel", bs)
	holder.add_child(board)
	var inner := VBoxContainer.new()
	inner.add_theme_constant_override("separation", 18)
	board.add_child(inner)
	asked = UiTheme.label("", UiTheme.SMALL, Color(CHALK, 0.6))
	asked.name = "Asked"
	asked.add_theme_font_override("font", MONO)
	inner.add_child(asked)
	board_scroll = ScrollContainer.new()
	board_scroll.name = "Scroll"
	board_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	board_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	inner.add_child(board_scroll)
	lines = VBoxContainer.new()
	lines.name = "Lines"
	lines.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lines.add_theme_constant_override("separation", 22)
	board_scroll.add_child(lines)
	# Spark, in the board's corner, bobs while he has something to say.
	spark = TextureRect.new()
	spark.name = "Spark"
	spark.texture = SPARK
	spark.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	spark.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	spark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	spark.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	holder.add_child(spark)

	caption_box = PanelContainer.new()
	caption_box.name = "Captions"
	var cs := StyleBoxFlat.new()
	cs.bg_color = Color(INK, 0.9)
	cs.set_corner_radius_all(8)
	cs.set_content_margin_all(18)
	caption_box.add_theme_stylebox_override("panel", cs)
	caption = UiTheme.label("", UiTheme.BODY, CHALK)
	caption.name = "Caption"
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.custom_minimum_size.y = 110
	caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	caption_box.add_child(caption)
	col.add_child(caption_box)

	var bar := HBoxContainer.new()
	bar.name = "Bar"
	bar.add_theme_constant_override("separation", 20)
	scrub = Scrub.new()
	scrub.name = "Scrub"
	scrub.player = self
	scrub.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scrub.custom_minimum_size.y = 72
	bar.add_child(scrub)
	time_label = UiTheme.label("0:00 / 0:00", UiTheme.SMALL, CHALK)
	time_label.name = "Time"
	time_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	time_label.add_theme_font_override("font", MONO)
	bar.add_child(time_label)
	col.add_child(bar)

	var controls := HFlowContainer.new()
	controls.name = "Controls"
	controls.add_theme_constant_override("h_separation", 16)
	controls.add_theme_constant_override("v_separation", 16)
	play_button = _button("Play", "Pause")
	play_button.pressed.connect(toggle_play)
	controls.add_child(play_button)
	replay_button = _button("Replay", "Replay step")
	replay_button.pressed.connect(replay_step)
	controls.add_child(replay_button)
	speed_button = _button("Speed", "1×")
	speed_button.pressed.connect(next_speed)
	controls.add_child(speed_button)
	cc_button = _button("CC", "CC")
	cc_button.toggle_mode = true
	cc_button.button_pressed = true
	cc_button.toggled.connect(set_captions)
	controls.add_child(cc_button)
	dice_button = _button("Dice", "New numbers")
	dice_button.pressed.connect(new_numbers)
	controls.add_child(dice_button)
	turn_button = _button("YourTurn", "Your turn")
	turn_button.add_theme_color_override("font_color", INK)
	var ts := StyleBoxFlat.new()
	ts.bg_color = TEAL
	ts.set_corner_radius_all(10)
	ts.set_content_margin_all(18)
	turn_button.add_theme_stylebox_override("normal", ts)
	turn_button.add_theme_stylebox_override("hover", ts)
	turn_button.pressed.connect(_on_turn)
	turn_button.visible = false
	controls.add_child(turn_button)
	col.add_child(controls)


func _button(id: String, text: String) -> Button:
	var b := Button.new()
	b.name = id
	b.text = text
	b.add_theme_font_size_override("font_size", UiTheme.SMALL)
	return b


func _fit() -> void:
	var wide := size.x > size.y
	var w := minf(size.x - 48.0, 1900.0 if wide else 1040.0)
	var h := minf(size.y - 48.0, 1200.0 if wide else 1780.0)
	# Anchored offsets, not a set size: a size set while the chalk lines had no width yet
	# (and wrapped a word to a line) would stay that tall once they had.
	frame.set_anchors_preset(Control.PRESET_CENTER)
	frame.offset_left = -w / 2.0
	frame.offset_right = w / 2.0
	frame.offset_top = -h / 2.0
	frame.offset_bottom = h / 2.0
	var side := 220.0 if wide else 170.0
	spark.offset_left = -side - 22.0
	spark.offset_top = -side - 26.0
	spark.offset_right = -22.0
	spark.offset_bottom = -26.0


func _fill_board() -> void:
	for c in lines.get_children():
		lines.remove_child(c)
		c.queue_free()
	var sols: Array = question.get("solutions", [])
	title.text = sols[solution].name if not sols.is_empty() else "Worked solution"
	asked.text = str(question.get("asked", ""))
	for i in chapters.size():
		var l := UiTheme.math(chapters[i].board, UiTheme.BIG, CHALK)
		l.name = "Line%d" % i
		# Written by hand: each line sits a touch off level.
		l.rotation_degrees = _rng.randf_range(-0.5, 0.5)
		lines.add_child(l)
	scrub.queue_redraw()


func _process(delta: float) -> void:
	if not playing or chapters.is_empty():
		_bob(false, delta)
		return
	time = minf(total, time + delta * speed)
	if time >= total:
		playing = false
		Audio.stop_voice()
	_render(false)
	_bob(true, delta)


func _bob(on: bool, _delta: float) -> void:
	if spark == null:
		return
	var talking: bool = on and current >= 0 and chapters[current].move != ""
	var t := Time.get_ticks_msec() / 1000.0
	spark.pivot_offset = spark.size / 2.0
	spark.rotation_degrees = sin(t * 9.0) * 3.0 if talking else 0.0
	spark.scale = Vector2.ONE * (1.0 + (0.03 * sin(t * 14.0) if talking else 0.0))


## The chapter playing at a time.
func chapter_at(t: float) -> int:
	for i in range(chapters.size() - 1, -1, -1):
		if t >= chapters[i].start:
			return i
	return 0


## Draw the board, the caption and the bar for the current time. A new chapter starts
## its voice line (from where the time is in it, after a seek).
func _render(seeked: bool) -> void:
	if lines == null:
		return
	var at := chapter_at(time) if not chapters.is_empty() else -1
	var entered := at != current
	current = at
	for i in lines.get_child_count():
		var l: Control = lines.get_child(i)
		var ch: Dictionary = chapters[i]
		var ratio := 1.0 if i < at else (clampf((time - ch.start) / ch.write, 0.0, 1.0) if i == at else 0.0)
		l.set("visible_ratio", ratio)
		l.modulate.a = 0.0 if ratio <= 0.0 else 1.0
	if at >= 0:
		caption.text = chapters[at].caption
		if entered:
			board_scroll.ensure_control_visible.call_deferred(lines.get_child(at))
		if (entered or seeked) and playing:
			_voice_from(time - chapters[at].start)
	caption_box.visible = captions and at >= 0
	var done := total > 0.0 and time >= total
	play_button.text = "Watch again" if done else ("Pause" if playing else "Play")
	turn_button.visible = done and turn_enabled and not question.get("view", {}).is_empty()
	time_label.text = "%s / %s" % [_clock(time), _clock(total)]
	scrub.queue_redraw()


func _voice_from(offset: float) -> void:
	var stream: AudioStream = chapters[current].stream
	if stream == null or offset >= stream.get_length():
		Audio.stop_voice()
		return
	Audio.play_voice(stream, speed, maxf(0.0, offset))


static func speed_text(s: float) -> String:
	return "%s×" % (str(s) if not is_equal_approx(s, roundf(s)) else str(int(s)))


static func _clock(t: float) -> String:
	var s := int(t)
	return "%d:%02d" % [s / 60, s % 60]


func toggle_play() -> void:
	if total > 0.0 and time >= total:
		seek(0.0)
		playing = true
	else:
		playing = not playing
	if not playing:
		Audio.stop_voice()
	_render(true)


func play() -> void:
	if not playing:
		toggle_play()


func pause() -> void:
	if playing:
		toggle_play()


## Jump to a time, in seconds at 1×.
func seek(t: float) -> void:
	time = clampf(t, 0.0, total)
	Audio.stop_voice()
	_render(true)


## Back to the start of the step playing, and play it.
func replay_step() -> void:
	if chapters.is_empty():
		return
	playing = true
	seek(chapters[maxi(current, 0)].start)


func next_speed() -> void:
	speed = SPEEDS[(SPEEDS.find(speed) + 1) % SPEEDS.size()]
	speed_button.text = speed_text(speed)
	Audio.set_voice_speed(speed)


func set_captions(on: bool) -> void:
	captions = on
	cc_button.set_pressed_no_signal(on)
	_render(false)


## The same view on a new seed: the recipe draws numbers its rules accept, so the steps
## and the voice still fit. Keeps this solution's method where the new question has it.
func new_numbers() -> void:
	var view: Dictionary = question.get("view", {})
	if view.is_empty():
		return
	var angle: String = question.solutions[solution].angle
	for i in RETRIES:
		var v := view.duplicate()
		v.seed = int(view.get("seed", 0)) + 1 + _rng.randi_range(0, 9999)
		var q := QuestionEngine.make(v)
		if q.has("error"):
			continue
		var at := -1
		for j in q.solutions.size():
			if q.solutions[j].angle == angle and can_play(q.solutions[j]):
				at = j
		if at >= 0:
			load_question(q, at)
			return


func _on_turn() -> void:
	var view: Dictionary = question.get("view", {}).duplicate()
	view.seed = int(view.get("seed", 0)) + 1 + _rng.randi_range(0, 9999)
	view.erase("same_angle")
	view.erase("shared")
	your_turn.emit(view)
	close()


func close() -> void:
	Audio.stop_voice()
	closed.emit()
	queue_free()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()


## The scrap-metal frame: an iron panel with a bolt in each corner.
class Frame extends PanelContainer:
	func _draw() -> void:
		var r := 11.0
		for p in [Vector2(22, 22), Vector2(size.x - 22, 22), Vector2(22, size.y - 22), Vector2(size.x - 22, size.y - 22)]:
			draw_circle(p + Vector2(2, 3), r, Color(0, 0, 0, 0.45))
			draw_circle(p, r, Explainer.IRON_GLOSS)
			draw_circle(p, r * 0.62, Explainer.IRON_SHADE)
			draw_line(p - Vector2(r * 0.5, 0), p + Vector2(r * 0.5, 0), Explainer.IRON_GLOSS, 3.0)
		# A rust streak down from the top bolts.
		draw_rect(Rect2(18, 34, 7, 46), Color(Explainer.RUST_SHADE, 0.45))
		draw_rect(Rect2(size.x - 25, 34, 6, 30), Color(Explainer.RUST_SHADE, 0.35))


## The slate: chalk dust and old smudges under the writing.
class Board extends PanelContainer:
	func _draw() -> void:
		var rng := RandomNumberGenerator.new()
		rng.seed = 7
		for i in 9:
			var c := Vector2(rng.randf() * size.x, rng.randf() * size.y)
			draw_circle(c, rng.randf_range(60, 180), Color(Explainer.CHALK, 0.025))
		for i in 260:
			draw_circle(Vector2(rng.randf() * size.x, rng.randf() * size.y), rng.randf_range(1.0, 2.6), Color(Explainer.CHALK, rng.randf_range(0.03, 0.09)))
		# The chalk ledge.
		draw_rect(Rect2(0, size.y - 14, size.x, 14), Explainer.SLATE_DEEP)


## The scrub bar: a track, the played part, a mark at the start of every step, and the
## knob. Tap or drag to seek.
class Scrub extends Control:
	var player: Explainer

	func _gui_input(event: InputEvent) -> void:
		var press: bool = event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT
		var drag: bool = event is InputEventMouseMotion and (event.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0
		if (press or drag or event is InputEventScreenDrag or (event is InputEventScreenTouch and event.pressed)) and player.total > 0.0:
			player.seek(clampf(event.position.x / size.x, 0.0, 1.0) * player.total)
			accept_event()

	func _draw() -> void:
		var y := size.y / 2.0
		var h := 14.0
		draw_rect(Rect2(0, y - h / 2, size.x, h), Explainer.IRON_SHADE)
		if player == null or player.total <= 0.0:
			return
		var x := size.x * player.time / player.total
		draw_rect(Rect2(0, y - h / 2, x, h), Explainer.MAGENTA)
		for ch in player.chapters:
			var cx: float = size.x * ch.start / player.total
			draw_rect(Rect2(cx - 2, y - h, 5, h * 2), Explainer.DUST if ch.move != "" else Explainer.IRON_GLOSS)
		draw_circle(Vector2(x, y), 20.0, Explainer.CHALK)
		draw_circle(Vector2(x, y), 9.0, Explainer.MAGENTA)
