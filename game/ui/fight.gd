extends "res://ui/practice.gd"
## The fight screen (FAL-413): a run (engine/run.gd) drawn as fights. The enemy and the
## player's HP, the draining timer, the lifelines and Scrap sit above the practice
## screen's question card, which this screen reuses. A wrong answer or a timeout shows
## the worked solution before the next question; the run ends in a summary.
##
## Room is kept for two later pieces: the journey strip (FAL-331) above the card, and
## the Paper 1 or 2 badge (C1, FAL-419) in the lifeline row.
##
## Deep links, for screenshots and tests:
##   web:      /next/?play=quadratics&seed=3&floor=1&autoplay=wrong
##   desktop:  -- --play=quadratics --seed=3 --autoplay=wrong
## autoplay=right or wrong answers the first question at once; autoplay=lose plays
## wrong answers until the run ends, to show the summary.

const MAIN := "res://scenes/main.tscn"
const MONO := preload("res://assets/fonts/share-tech-mono-latin.woff2")
const GREEN := Color(0.36, 0.8, 0.42)
const ORANGE := Color(0.95, 0.6, 0.2)
const RED := Color(0.93, 0.26, 0.3)
## Height kept above the card for the journey strip (FAL-331), in base units.
const STRIP_HEIGHT := 150
const LIFELINE_NAMES := {"fifty": "50-50", "hint": "Hint", "freeze": "Freeze"}

var run: Run
var region := "quadratics"
var start_floor := 1
var run_seed := 0
var result: Dictionary = {}

var title: Label
var quit_button: Button
var strip: Control
var enemy_art: TextureRect
var enemy_name: Label
var enemy_bar: ProgressBar
var enemy_hp: Label
var player_bar: ProgressBar
var player_hp: Label
var scrap_label: Label
var timer_bar: ProgressBar
var timer_label: Label
var timer_fill: StyleBoxFlat
var lifeline_buttons := {}
var badge: Control
var hint_label: Label
var summary_box: VBoxContainer
## The rows that only mean something while a question is open.
var _question_rows: Array = []


func _ready() -> void:
	theme = UiTheme.make()
	_build()
	resized.connect(_fit)
	_fit()
	var deep := deep_link()
	if not deep.is_empty():
		region = deep.region
		start_floor = deep.floor
		run_seed = deep.seed
	save = SaveData.load_from(save_path)
	start_run()
	match deep.get("autoplay", ""):
		"right", "wrong":
			autoplay(deep.autoplay == "right")
		"lose":
			lose()


## Starts a run with this screen's region, floor and seed (a fresh seed if 0).
func start_run() -> void:
	if run_seed == 0:
		run_seed = int(Time.get_unix_time_from_system()) % 1000000 + 1
	run = Run.new(save, region, start_floor, run_seed)
	run.question_opened.connect(func(_f, _t): _show_question())
	run.run_ended.connect(_show_summary)
	summary_box.visible = false
	scroll.visible = true
	for c in _question_rows:
		c.visible = true
	run.start()


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
	col.add_theme_constant_override("separation", 16)
	margin.add_child(col)

	var head := HBoxContainer.new()
	head.name = "Head"
	title = UiTheme.label("Fight", 72, UiTheme.TEAL)
	title.name = "Title"
	title.autowrap_mode = TextServer.AUTOWRAP_OFF
	title.add_theme_font_override("font", UiTheme.TITLE_FONT)
	head.add_child(title)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(spacer)
	quit_button = Button.new()
	quit_button.name = "Quit"
	quit_button.text = "Quit"
	quit_button.add_theme_font_size_override("font_size", UiTheme.SMALL)
	quit_button.pressed.connect(func(): if run != null: run.quit())
	head.add_child(quit_button)
	hud_gap = Control.new()
	hud_gap.name = "HudGap"
	hud_gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	head.add_child(hud_gap)
	col.add_child(head)

	# The journey strip (FAL-331) goes here, above the card.
	strip = Control.new()
	strip.name = "JourneyStrip"
	strip.custom_minimum_size.y = STRIP_HEIGHT
	strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(strip)

	col.add_child(_status())
	col.add_child(_timer())
	col.add_child(_lifelines())
	# _update_progress() writes here; the fight shows the fight and question number.
	progress = UiTheme.label("", UiTheme.SMALL, UiTheme.DIM)
	progress.name = "Progress"
	col.add_child(progress)
	_question_rows = [col.get_node("Timer"), col.get_node("Lifelines"), progress]

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

	summary_box = VBoxContainer.new()
	summary_box.name = "Summary"
	summary_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	summary_box.add_theme_constant_override("separation", 22)
	summary_box.visible = false
	col.add_child(summary_box)


func _bar(color: Color, height: int) -> ProgressBar:
	var b := ProgressBar.new()
	b.show_percentage = false
	b.custom_minimum_size.y = height
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var back := StyleBoxFlat.new()
	back.bg_color = Color(0.08, 0.1, 0.14)
	back.set_corner_radius_all(10)
	var fill := StyleBoxFlat.new()
	fill.bg_color = color
	fill.set_corner_radius_all(10)
	b.add_theme_stylebox_override("background", back)
	b.add_theme_stylebox_override("fill", fill)
	return b


func _mono(text: String, size: int, color: Color = UiTheme.TEXT) -> Label:
	var l := UiTheme.label(text, size, color)
	l.autowrap_mode = TextServer.AUTOWRAP_OFF
	l.add_theme_font_override("font", MONO)
	return l


## The enemy (portrait, name, HP) and the player (HP, Scrap).
func _status() -> Control:
	var box := PanelContainer.new()
	box.name = "Status"
	box.add_theme_stylebox_override("panel", UiTheme.panel())
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 24)
	box.add_child(row)
	enemy_art = TextureRect.new()
	enemy_art.name = "EnemyArt"
	enemy_art.custom_minimum_size = Vector2(190, 190)
	enemy_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	enemy_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	enemy_art.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	row.add_child(enemy_art)
	var bars := VBoxContainer.new()
	bars.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bars.add_theme_constant_override("separation", 8)
	row.add_child(bars)
	enemy_name = UiTheme.label("", 54, UiTheme.PINK)
	enemy_name.name = "EnemyName"
	enemy_name.autowrap_mode = TextServer.AUTOWRAP_OFF
	enemy_name.add_theme_font_override("font", UiTheme.TITLE_FONT)
	bars.add_child(enemy_name)
	var erow := HBoxContainer.new()
	enemy_bar = _bar(UiTheme.PINK, 34)
	enemy_bar.name = "EnemyHP"
	enemy_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	erow.add_child(enemy_bar)
	enemy_hp = _mono("", UiTheme.SMALL)
	enemy_hp.custom_minimum_size.x = 120
	enemy_hp.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	erow.add_child(enemy_hp)
	bars.add_child(erow)
	var you := _mono("YOU", UiTheme.SMALL, UiTheme.TEAL)
	bars.add_child(you)
	var prow := HBoxContainer.new()
	player_bar = _bar(UiTheme.TEAL, 34)
	player_bar.name = "PlayerHP"
	player_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	prow.add_child(player_bar)
	player_hp = _mono("", UiTheme.SMALL)
	player_hp.custom_minimum_size.x = 120
	player_hp.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	prow.add_child(player_hp)
	bars.add_child(prow)
	scrap_label = _mono("", UiTheme.SMALL, UiTheme.SAND)
	scrap_label.name = "Scrap"
	bars.add_child(scrap_label)
	return box


func _timer() -> Control:
	var row := HBoxContainer.new()
	row.name = "Timer"
	row.add_theme_constant_override("separation", 16)
	timer_bar = _bar(GREEN, 40)
	timer_bar.name = "TimerBar"
	timer_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	timer_fill = timer_bar.get_theme_stylebox("fill") as StyleBoxFlat
	row.add_child(timer_bar)
	timer_label = _mono("", UiTheme.BODY)
	timer_label.name = "TimerText"
	timer_label.custom_minimum_size.x = 150
	timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(timer_label)
	return row


func _lifelines() -> Control:
	var row := HBoxContainer.new()
	row.name = "Lifelines"
	row.add_theme_constant_override("separation", 16)
	for id in ["fifty", "hint", "freeze"]:
		var b := Button.new()
		b.name = "Lifeline_" + id
		b.text = LIFELINE_NAMES[id]
		b.icon = load("res://assets/ui/lifeline-%s-on.png" % id)
		b.expand_icon = true
		b.custom_minimum_size = Vector2(230, 110)
		b.add_theme_constant_override("icon_max_width", 72)
		b.add_theme_font_size_override("font_size", UiTheme.SMALL)
		b.pressed.connect(use_lifeline.bind(id))
		row.add_child(b)
		lifeline_buttons[id] = b
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spacer)
	# The Paper 1 or 2 badge (C1, FAL-419) goes here.
	badge = Control.new()
	badge.name = "PaperBadge"
	badge.custom_minimum_size = Vector2(150, 0)
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(badge)
	return row


func _process(delta: float) -> void:
	if run == null or run.state != "question":
		return
	var r := run.tick(delta)
	if not r.is_empty():
		_show_result(r)
	_update_timer()


## Draws the run's open question, with the practice screen's card.
func _show_question() -> void:
	question = run.question
	result = {}
	render_question()
	check_button.text = "Attack"
	next_button.text = "Next question"
	if run.another_way:
		var tag := UiTheme.label("Another way: the same question, by this method. Bonus Scrap if you get it.", UiTheme.SMALL, UiTheme.SAND)
		tag.name = "AnotherWay"
		card.add_child(tag)
		card.move_child(tag, 0)
	hint_label = UiTheme.label("", UiTheme.BODY, UiTheme.SAND)
	hint_label.name = "Hint"
	hint_label.visible = false
	card.add_child(hint_label)
	card.move_child(hint_label, card.get_node("Prompt").get_index() + 1)
	_update_hud()


func _update_progress() -> void:
	if run == null or progress == null:
		return
	progress.text = "Fight %d · question %d · floor %d" % [run.fight, run.question_no, run.floor_no]


func _update_hud() -> void:
	title.text = "%s · Fight %d" % [_region_name(), run.fight]
	enemy_name.text = "%s · D%d" % [run.enemy.name, run.tier]
	enemy_art.texture = load("res://assets/enemies/" + run.enemy.art)
	enemy_bar.max_value = run.enemy.max_hp
	enemy_bar.value = run.enemy.hp
	enemy_hp.text = "%d/%d" % [run.enemy.hp, run.enemy.max_hp]
	player_bar.max_value = run.max_hp
	player_bar.value = run.hp
	player_hp.text = "%d/%d" % [run.hp, run.max_hp]
	scrap_label.text = "Scrap +%d · a miss costs %d HP" % [run.stats.scrap, run.enemy.damage]
	for id in lifeline_buttons:
		var b: Button = lifeline_buttons[id]
		var n := int(run.lifelines.get(id, 0))
		b.disabled = not run.can_use(id)
		b.icon = load("res://assets/ui/lifeline-%s-%s.png" % [id, "on" if not b.disabled else "off"])
		b.text = "%s ×%d" % [LIFELINE_NAMES[id], n]
	_update_progress()
	_update_timer()


func _update_timer() -> void:
	timer_bar.max_value = run.time_total
	timer_bar.value = run.time_left
	var share := run.time_share()
	timer_fill.bg_color = GREEN if share >= Tuning.BAR_ORANGE else (ORANGE if share >= Tuning.LATE_ZONE else RED)
	timer_label.text = ("❚❚ " if run.frozen_left > 0.0 else "") + "%ds" % ceili(run.time_left)
	timer_label.add_theme_color_override("font_color", UiTheme.TEAL if run.frozen_left > 0.0 else UiTheme.TEXT)


func _region_name() -> String:
	for r in QuestionEngine.catalogue().get("regions", []):
		if r is Dictionary and r.get("id") == region:
			return r.get("name", region)
	return region.capitalize()


func use_lifeline(id: String) -> void:
	if run == null:
		return
	match id:
		"fifty":
			for i in run.use_fifty():
				var b: Button = _choice_buttons[i]
				b.disabled = true
				b.button_pressed = false
				b.add_theme_color_override("font_disabled_color", Color(UiTheme.DIM, 0.4))
				if _choice == i:
					_choice = -1
		"hint":
			var step := run.use_hint()
			if step != "":
				hint_label.text = "Hint: " + step
				hint_label.visible = true
		"freeze":
			run.use_freeze()
	_update_hud()


## Marks the answer through the run.
func check_answer() -> void:
	if answered or run == null or run.state != "question":
		return
	var response := {}
	if question.format == "mcq":
		response = {"choice": _choice}
	else:
		for id in _slots:
			response[id] = _slots[id].text
		for id in _picks:
			response[id] = _picks[id]
	var r := run.answer(response)
	if not r.get("complete", false):
		var msgs: Array = r.get("errors", {}).values()
		feedback.visible = true
		feedback.text = msgs[0] if msgs.size() == 1 else "Fill in every box."
		feedback.add_theme_color_override("font_color", UiTheme.SAND)
		return
	_show_result(r)


func _show_result(r: Dictionary) -> void:
	result = r
	answered = true
	SaveData.store(save, save_path)
	feedback.visible = true
	var color := UiTheme.TEAL
	match r.outcome:
		"right":
			feedback.text = "Hit! −%d enemy HP · +%d Scrap" % [r.enemy_damage, r.scrap + r.bonus]
		"glancing":
			feedback.text = "Glancing hit: half damage. %s The answer is %s." % [r.note, question.answer_text]
			color = UiTheme.SAND
		"late":
			feedback.text = "Late hit! It lands, but you take %d damage · +%d Scrap" % [r.player_damage, r.scrap]
			color = UiTheme.SAND
		"wrong":
			feedback.text = "Missed. −%d HP. The answer is %s." % [r.player_damage, question.answer_text]
			color = UiTheme.PINK
		"timeout":
			feedback.text = "Time's up. −%d HP. The answer is %s." % [r.player_damage, question.answer_text]
			color = UiTheme.PINK
	if r.bonus > 0:
		feedback.text += " Another way: +%d bonus Scrap." % r.bonus
	var ref: String = r.get("misconception", "")
	if ref != "" and r.outcome == "wrong":
		for m in QuestionEngine.type_of(question.view.type).get("misconceptions", []):
			if m.ref == ref:
				feedback.text += "\nWatch out: " + m.text + "."
				break
	if r.defeated:
		feedback.text += "\nThe %s falls." % run.enemy.name
	feedback.add_theme_color_override("font_color", color)
	if question.format == "mcq":
		for i in _choice_buttons.size():
			if question.choices[i].correct:
				_choice_buttons[i].add_theme_color_override("font_disabled_color", UiTheme.TEAL)
			elif i == _choice:
				_choice_buttons[i].add_theme_color_override("font_disabled_color", UiTheme.PINK)
	# Q5: the worked solution shows after a wrong answer or a timeout.
	if not r.solution.is_empty():
		_show_working()
	check_button.visible = false
	next_button.visible = true
	next_button.text = "See the summary" if r.dead else ("Next fight" if r.defeated else "Next question")
	for e in _slots.values():
		e.editable = false
	for b in _choice_buttons:
		b.disabled = true
	for bs in _pick_buttons.values():
		for b in bs:
			b.disabled = true
	_update_hud()


func next_question() -> void:
	if run != null and run.state == "result":
		run.next()


func _show_summary(s: Dictionary) -> void:
	SaveData.store(save, save_path)
	scroll.visible = false
	for c in _question_rows:
		c.visible = false
	summary_box.visible = true
	for c in summary_box.get_children():
		summary_box.remove_child(c)
		c.queue_free()
	var head := UiTheme.label("Run over" if s.reason == "quit" else "You're down", 96, UiTheme.PINK)
	head.name = "Heading"
	head.add_theme_font_override("font", UiTheme.TITLE_FONT)
	summary_box.add_child(head)
	var lines := [
		"Questions right: %d of %d" % [s.right, s.questions],
		"Fights won: %d" % s.fights_won,
		"Scrap earned: %d" % s.scrap,
		"Scrap in the bank: %d" % s.banked,
	]
	for line in lines:
		summary_box.add_child(_mono(line, UiTheme.BIG, UiTheme.SAND if line.begins_with("Scrap") else UiTheme.TEXT))
	summary_box.add_child(UiTheme.label("Skills missed" if not s.missed.is_empty() else "No skills missed.", UiTheme.BIG, UiTheme.TEAL))
	var list := VBoxContainer.new()
	list.name = "Missed"
	list.add_theme_constant_override("separation", 8)
	for m in s.missed:
		list.add_child(UiTheme.label("• " + m, UiTheme.BODY))
	summary_box.add_child(list)
	var again := Button.new()
	again.name = "PlayAgain"
	again.text = "Play again"
	again.add_theme_font_size_override("font_size", UiTheme.BIG)
	again.pressed.connect(func():
		run_seed = 0
		start_run())
	summary_box.add_child(again)
	var back := Button.new()
	back.name = "Title"
	back.text = "Back to the title"
	back.add_theme_font_size_override("font_size", UiTheme.BIG)
	back.pressed.connect(func(): get_tree().change_scene_to_file(MAIN))
	summary_box.add_child(back)
	_update_hud()


## Plays wrong answers until the run ends (screenshots of the summary).
func lose() -> void:
	var guard := 0
	while run.state != "ended" and guard < 200:
		autoplay(false)
		next_question()
		guard += 1


## A run asked for in the URL (web) or on the command line, or {}.
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
	if not args.has("play"):
		return {}
	return {"region": args.play, "seed": int(args.get("seed", "1")), "floor": maxi(1, int(args.get("floor", "1"))),
		"autoplay": args.get("autoplay", "")}
