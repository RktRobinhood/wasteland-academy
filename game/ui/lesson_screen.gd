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
## The generated archive is an explicit shortlist. Installed draft lessons never
## appear here unless their reviewed worked section is listed.
static var open_preview := false

var player: LessonPlayer
var preview_menu: CenterContainer
var archive_mode := false
var entries: Array = []
var selected: Dictionary = {}
var archive_title: Label
var archive_prompt: Label
var watch_button: Button
var try_button: Button


func _ready() -> void:
	theme = UiTheme.make()
	archive_mode = MapLink.current == MapLink.RELIC_LIBRARY_ROUTE or (
		MapLink.current.is_empty() and MapLink.parse(MapLink.address()) == MapLink.RELIC_LIBRARY_ROUTE)
	if open_preview or archive_mode:
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
	col.add_child(UiTheme.label("Relic Library" if archive_mode else "Lesson preview", UiTheme.SMALL, Explainer.TEAL))
	var course := Courses.of(SaveData.load_from())
	for entry in Lesson.shared("archive").get("entries", []):
		if entry.get("courses", []).has(course):
			entries.append(entry)
	archive_title = UiTheme.label("", UiTheme.BIG, Explainer.DUST)
	archive_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(archive_title)
	if entries.size() > 1:
		var choose := OptionButton.new()
		choose.accessibility_name = "Choose a lesson"
		choose.custom_minimum_size.y = LessonPlayer.TOUCH
		for entry in entries:
			choose.add_item(str(entry.title))
		choose.item_selected.connect(_select_entry)
		col.add_child(choose)
	archive_prompt = UiTheme.label("", UiTheme.BODY, Explainer.CHALK)
	archive_prompt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(archive_prompt)
	watch_button = _preview_choice(col, "WatchExample", "Work through an example", func() -> void: _open_part(false))
	try_button = _preview_choice(col, "TryExample", "Try a similar question", func() -> void: _open_part(true))
	var back := _preview_choice(col, "Back", "Back to map" if archive_mode else "Back to title", _back_to_entry)
	if entries.is_empty():
		archive_title.text = "No lessons for this course yet"
		watch_button.hide()
		try_button.hide()
		back.grab_focus.call_deferred()
	else:
		_select_entry(0)
		watch_button.grab_focus.call_deferred()


func _select_entry(index: int) -> void:
	selected = entries[index]
	archive_title.text = str(selected.title)
	archive_prompt.text = "%s: %s" % [selected.zone, selected.prompt]

func _preview_choice(col: VBoxContainer, key: String, label: String, action: Callable) -> Button:
	var button := Button.new()
	button.name = key
	button.text = label
	button.custom_minimum_size.y = LessonPlayer.TOUCH
	button.pressed.connect(action)
	col.add_child(button)
	return button


func _back_to_entry() -> void:
	if archive_mode:
		MapLink.go(get_tree(), MapLink.WORLD, true)
	else:
		get_tree().change_scene_to_file.call_deferred(MAIN)


func _open_part(practice: bool) -> void:
	if player != null or selected.is_empty():
		return
	var whole := Lesson.load_id(str(selected.lesson))
	var part := str(selected.practice if practice else selected.worked)
	var excerpt := whole.excerpt(part) if whole != null else null
	if excerpt == null:
		return
	excerpt.data["title"] = "Your turn" if practice else "Worked example"
	if practice and selected.practice_mode == "authored-twin":
		# The authored twin holds the same curriculum demand as the worked problem.
		excerpt.data.sections[0].turn["serve"] = "fallback"
	player = LessonPlayer.make(excerpt, SaveData.load_from().duplicate(true))
	player.save_path = ""
	player.allow_why_help = true
	if practice:
		player.activity = selected.get("activity", {})
	player.skip_button.hide()
	player.replay_button.text = "Restart"
	player.closed.connect(func() -> void:
		player = null
		preview_menu.show()
		(try_button if practice else watch_button).grab_focus.call_deferred())
	preview_menu.hide()
	add_child(player)
	player.close_button.grab_focus.call_deferred()
