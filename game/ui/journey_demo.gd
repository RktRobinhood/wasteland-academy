extends Control
## The journey demo (FAL-331): a debug screen that replays the FAL-293 reel's script,
## then one encounter of each kind the reel didn't show, with a dummy question card
## under the strip. It loops.
##
##   web:      /next/?journey=demo            add &motion=reduced, &avatar=learner-male, &t=12.5
##   desktop:  -- --journey=demo
##
## t= jumps the script to that second (for screenshots).

const COLUMN := 1000
const COLUMN_WIDE := 1500

var run: JourneyDemoRun
var stage: JourneyStage
var avatar := "learner-female"

var head: HBoxContainer
var margin: MarginContainer
var question: Label
var options: Array[PanelContainer] = []
var status: Label
var motion_button: Button


func _ready() -> void:
	theme = UiTheme.make()
	_build()
	var args := url_args()
	avatar = args.get("avatar", avatar)
	stage.reduced_motion = args.get("motion", "") == "reduced"
	_motion_label()
	resized.connect(_fit)
	_fit()
	restart()
	if args.has("t"):
		seek(float(args.t))


func _build() -> void:
	var bg := ColorRect.new()
	bg.color = UiTheme.BG
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	var col := VBoxContainer.new()
	col.name = "Column"
	col.set_anchors_preset(Control.PRESET_FULL_RECT)
	col.add_theme_constant_override("separation", 0)
	add_child(col)
	var hm := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		hm.add_theme_constant_override("margin_" + side, 24)
	col.add_child(hm)
	head = HBoxContainer.new()
	head.add_theme_constant_override("separation", 20)
	hm.add_child(head)
	var title := UiTheme.label("Journey demo", 72, UiTheme.TEAL)
	title.autowrap_mode = TextServer.AUTOWRAP_OFF
	title.add_theme_font_override("font", UiTheme.TITLE_FONT)
	head.add_child(title)
	var gap := Control.new()
	gap.custom_minimum_size.x = AudioHud.RESERVED_RIGHT
	gap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(gap)

	stage = (load("res://scenes/journey_stage.tscn") as PackedScene).instantiate()
	stage.name = "Strip"
	stage.auto_clock = false
	col.add_child(stage)

	margin = MarginContainer.new()
	margin.name = "Margin"
	margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(margin)
	var inner := VBoxContainer.new()
	inner.add_theme_constant_override("separation", 24)
	margin.add_child(inner)
	var card := PanelContainer.new()
	card.name = "Card"
	card.add_theme_stylebox_override("panel", UiTheme.panel())
	inner.add_child(card)
	var cv := VBoxContainer.new()
	cv.add_theme_constant_override("separation", 22)
	card.add_child(cv)
	question = UiTheme.label("", UiTheme.BIG)
	question.name = "Question"
	question.custom_minimum_size.y = 130
	cv.add_child(question)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 18)
	grid.add_theme_constant_override("v_separation", 18)
	cv.add_child(grid)
	for i in 4:
		var p := PanelContainer.new()
		p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var l := UiTheme.label("", UiTheme.BODY)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		p.add_child(l)
		grid.add_child(p)
		options.append(p)
	status = UiTheme.label("", UiTheme.SMALL, UiTheme.SAND)
	status.name = "Status"
	inner.add_child(status)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 20)
	inner.add_child(row)
	motion_button = Button.new()
	motion_button.name = "Motion"
	motion_button.add_theme_font_size_override("font_size", UiTheme.SMALL)
	motion_button.pressed.connect(func():
		stage.reduced_motion = not stage.reduced_motion
		_motion_label())
	row.add_child(motion_button)
	var again := Button.new()
	again.name = "Restart"
	again.text = "Restart"
	again.add_theme_font_size_override("font_size", UiTheme.SMALL)
	again.pressed.connect(restart)
	row.add_child(again)
	var note := UiTheme.label("Debug screen (FAL-331). The strip replays the FAL-293 reel's script, then one Explore, Puzzle, ambush and boss beat. It only shows what the run did, and loops.", UiTheme.SMALL, UiTheme.DIM)
	inner.add_child(note)


func _motion_label() -> void:
	motion_button.text = "Motion: " + ("reduced" if stage.reduced_motion else "full")


func _fit() -> void:
	var wide := size.x > size.y
	var col := COLUMN_WIDE if wide else COLUMN
	var side := maxf(36.0, (size.x - col) / 2.0)
	margin.add_theme_constant_override("margin_left", int(side))
	margin.add_theme_constant_override("margin_right", int(side))
	margin.add_theme_constant_override("margin_top", 30)
	margin.add_theme_constant_override("margin_bottom", 30)
	# Tall enough to read, but never so tall the 360-unit action window doesn't fit.
	var h := minf(size.x * JourneyStage.H / 380.0, size.y * (0.32 if wide else 0.27))
	stage.custom_minimum_size.y = maxf(240.0, h)


func restart() -> void:
	run = JourneyDemoRun.new()
	run.listener = stage
	stage.start_run(JourneyDemoRun.REGION, avatar, "rebar", run.run_seed)
	run.step(0.0)
	_show()


## Plays the script up to second t at once, frame by frame, so the strip is where it
## would be.
func seek(t: float) -> void:
	run.direct = true
	while run.clock < t - 1e-6:
		var dt := minf(1.0 / 60.0, t - run.clock)
		run.step(dt)
		stage.advance(dt)
	run.direct = false
	_show()


func _process(delta: float) -> void:
	run.step(delta)
	stage.advance(delta)
	if run.done:
		restart()
	_show()


func _show() -> void:
	var c := run.card
	question.text = c.get("question", "…")
	var opts: Array = c.get("options", ["", "", "", ""])
	for i in 4:
		var p := options[i]
		(p.get_child(0) as Label).text = opts[i] if i < opts.size() else ""
		var sb := UiTheme.panel(UiTheme.PANEL_HI)
		sb.set_corner_radius_all(14)
		if not c.get("open", true):
			if i == int(c.correct):
				sb.border_color = UiTheme.TEAL
				sb.set_border_width_all(6)
			elif i == int(c.picked):
				sb.border_color = UiTheme.PINK
				sb.set_border_width_all(6)
		p.add_theme_stylebox_override("panel", sb)
	var what := ""
	if c.has("fight"):
		what = "   fight %d · question %d" % [c.fight, int(c.index) + 1]
		if not c.open:
			what += " · " + str(c.outcome)
	status.text = "HP %d   Scrap %d%s" % [run.hp, run.scrap, what]


## Query (web) or -- --key=value (desktop) arguments.
static func url_args() -> Dictionary:
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
	return args
