extends Control
## The explainer on its own, at /?explain (FAL-429): the player (ui/explainer.gd) over
## the whole screen, on a question with a move to watch. Add a view, as the practice
## screen takes one, to choose it:
##   /?explain&view=fn-quadratic-features/vertex-from-general/equation/complete-square&seed=3
## &t=4.5 starts paused at that many seconds in (for screenshots). "Your turn" opens the
## practice screen on the same view with new numbers, and "Close" the title screen.

const MAIN := "res://scenes/main.tscn"
const PRACTICE := "res://scenes/practice.tscn"
## Asked when the link names no view.
const DEFAULT_VIEW := {"type": "fn-quadratic-features", "unknown": "vertex-from-general", "rep": "equation",
	"angle": "complete-square", "format": "value", "seed": 0}
const TRIES := 20

var player: Explainer
var _turn_view: Dictionary = {}
var _demo := false


func _ready() -> void:
	theme = UiTheme.make()
	var bg := ColorRect.new()
	bg.color = Explainer.INK
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var args := preload("res://ui/practice.gd").url_args()
	var deep := preload("res://ui/practice.gd").view_from(args)
	_demo = str(args.get("autoplay", "")) != ""
	var view: Dictionary = deep.get("view", {})
	if view.is_empty() or view.get("format") == "probe":
		view = DEFAULT_VIEW.duplicate()
		view.seed = int(args.get("seed", randi_range(1, 999)))
	var q := question_for(view)
	player = Explainer.make(q, 0)
	player.your_turn.connect(func(v: Dictionary) -> void: _turn_view = v)
	player.closed.connect(_leave, CONNECT_ONE_SHOT)
	add_child(player)
	if args.has("t"):
		player.pause()
		player.seek(float(args.t))


## Your turn emits its new view, then closes the player just like the Close button.
## Use that one close signal for either destination, never queue both scene changes.
func _leave() -> void:
	if _turn_view.is_empty():
		get_tree().change_scene_to_file.call_deferred(MAIN)
		return
	var practice := preload("res://ui/practice.gd")
	practice.launch_view = _turn_view
	practice.launch_view_demo = _demo
	get_tree().change_scene_to_file.call_deferred(PRACTICE)


## The question for a view, moving on through the seeds until one has a move to watch.
static func question_for(view: Dictionary) -> Dictionary:
	var q := {}
	for i in TRIES:
		var v := view.duplicate()
		v.seed = int(view.get("seed", 0)) + i
		q = QuestionEngine.make(v)
		if not q.has("error") and not q.solutions.is_empty() and Explainer.can_play(q.solutions[0]):
			return q
	return q
