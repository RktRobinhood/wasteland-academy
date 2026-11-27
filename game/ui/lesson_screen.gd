extends Control
## A tutor lesson on its own (#218), at /?lesson, or res://scenes/lesson.tscn in the
## editor: the lesson player (ui/lesson/lesson_player.gd) over the whole screen. The
## lessons aren't approved, so nothing on the student map links here.
##
##   /?lesson                                    the exemplar, One In, One Out
##   /?lesson=ex.algebra.arithmetic-sequence     any script the game has a copy of
##   &recall=watched or &recall=not_watched      that recall version, whatever the record says
##   &auto                                       a scripted player answers every action (the capture)
##   &speed=1.5                                  start at that speed
##   --quit (command line)                       quit at the end and leave the save alone, for the capture
##
## Close goes back to the title screen.

const MAIN := "res://scenes/main.tscn"
const EXEMPLAR := "ex.functions.function-machine"

# Pilot exposure is explicit. Do not move unapproved lessons into normal maps.
const WATCH := "example-1"
const TRY := "turn-1"
static var open_preview := false

var player: LessonPlayer
var preview_menu: CenterContainer
var watch_button: Button
var try_button: Button


func _ready() -> void:
	theme = UiTheme.make()
	if open_preview:
		open_preview = false
		_build_preview()
		return
	var args := preload("res://ui/practice.gd").url_args()
	var id := str(args.get("lesson", ""))
	if id == "" or Lesson.load_id(id) == null:
		id = EXEMPLAR
	player = LessonPlayer.make(Lesson.load_id(id))
	player.recall = str(args.get("recall", ""))
	if args.has("auto"):
		var run := ScriptedRun.new()
		run.delay = 1.2
		run.call_value = str(args.get("call", ""))
		player.driver = run
	if args.has("speed"):
		player.speed = clampf(float(args.speed), 0.5, 2.0)
	if args.has("quit") and not OS.has_feature("web"):
		# A capture leaves the save alone.
		player.save = SaveData.blank()
		player.save_path = ""
		player.finished.connect(func() -> void:
			await get_tree().create_timer(3.0).timeout
			get_tree().quit())
	player.closed.connect(func() -> void: get_tree().change_scene_to_file.call_deferred(MAIN))
	add_child(player)


## Reuse the exact script parts in the lesson player. Watch and Try start independently;
## neither opens a run, reveals the Try answer up front, or writes a watched record.
func _build_preview() -> void:
	preview_menu = CenterContainer.new()
	preview_menu.name = "LessonPreview"
	preview_menu.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(preview_menu)
	var col := VBoxContainer.new()
	col.custom_minimum_size.x = 760
	col.add_theme_constant_override("separation", 32)
	preview_menu.add_child(col)
	col.add_child(UiTheme.label("SIGNAL TOWER  ·  LESSON PREVIEW", UiTheme.SMALL, Explainer.TEAL))
	col.add_child(UiTheme.label("Function notation", UiTheme.BIG, Explainer.DUST))
	var desc := UiTheme.label("Find the east mast relay's output.", UiTheme.BODY, Explainer.CHALK)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(desc)
	watch_button = _preview_choice(col, "WatchExample", "Watch worked example", func() -> void: _open_part(WATCH))
	try_button = _preview_choice(col, "TryExample", "Try a similar question", func() -> void: _open_part(TRY))
	_preview_choice(col, "Back", "Back to title", func() -> void: get_tree().change_scene_to_file.call_deferred(MAIN))
	watch_button.grab_focus.call_deferred()


func _preview_choice(col: VBoxContainer, key: String, label: String, action: Callable) -> Button:
	var button := Button.new()
	button.name = key
	button.text = label
	button.custom_minimum_size.y = LessonPlayer.TOUCH
	button.pressed.connect(action)
	col.add_child(button)
	return button


func _open_part(part: String) -> void:
	if player != null:
		return
	var whole := Lesson.load_id(EXEMPLAR)
	var excerpt := whole.excerpt(part) if whole != null else null
	if excerpt == null:
		return
	excerpt.data["title"] = "Worked example" if part == WATCH else "Your turn"
	player = LessonPlayer.make(excerpt, SaveData.load_from().duplicate(true))
	player.save_path = ""
	player.skip_button.hide()
	player.replay_button.text = "Restart"
	player.closed.connect(func() -> void:
		player = null
		preview_menu.show()
		(watch_button if part == WATCH else try_button).grab_focus.call_deferred())
	preview_menu.hide()
	add_child(player)
	player.close_button.grab_focus.call_deferred()
