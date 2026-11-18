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

var player: LessonPlayer


func _ready() -> void:
	theme = UiTheme.make()
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
