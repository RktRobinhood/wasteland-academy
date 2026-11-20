class_name LessonToy
extends Control
## What every explainer toy is to the lesson player (#217, game/docs/TOYS.md): a Control
## the player sizes and shows, set up from the script's toy item, given one task at a
## time, and heard through two signals. The player never asks which toy it is: a new toy
## extends this, registers its id in Toys.IDS, and plugs in with no change to the player.
##
##   var toy := Toys.make({"toy": "relay", "rule": "x^2 - 4", "dial": [-5, 5]})
##   toy.acted.connect(on_act)          # every action: a hit plays on, a miss gets a reaction
##   toy.task_done.connect(on_done)     # the task is met: the lesson moves on
##   toy.start({"kind": "find", "output": 12})
##
## A toy has no fail state and keeps no score. A miss still happens in the world (the
## toy shows what it costs) and the player goes again.

## One player action. {"kind": the task kind, "hit": true, false, or null on a free
## task, "board": the line the toy wrote, and the toy's own fields}.
signal acted(action: Dictionary)
## The task in hand is met. {"kind", "actions": how many it took, "misses", and the
## toy's own fields}.
signal task_done(result: Dictionary)

## The script's toy item, as set up.
var spec: Dictionary = {}
## The task in hand, or {} between tasks (the toy still answers, as a free play).
var task: Dictionary = {}
## Cut instead of animating: the host sets it from LessonToy.reduce_motion(save).
var reduced_motion := false
## The lines this toy has written on the board, oldest first.
var board: PackedStringArray = []
var _actions := 0
var _misses := 0


## Errors in a toy item, as sentences; empty when the toy can be built from it. The base
## knows nothing about any one toy: each toy adds its own checks.
static func check_spec(_spec: Dictionary) -> PackedStringArray:
	return []


## Whether the game should cut instead of animating: the save's reduced-motion setting
## (save_data.gd; its switch on the settings screen is #196), or the browser's
## prefers-reduced-motion on the web. The same rule as the map's (ui/map.gd).
static func reduce_motion(save: Dictionary = {}) -> bool:
	if bool(save.get("settings", {}).get("reduced_motion", false)):
		return true
	if OS.has_feature("web"):
		return JavaScriptBridge.eval("window.matchMedia('(prefers-reduced-motion: reduce)').matches", true) == true
	return false


## Set the toy up from the script's toy item. Called once, before start.
func setup(item: Dictionary) -> void:
	spec = item


## Give the toy a task from the item's list. A toy that doesn't know the kind treats it
## as free play, so a script can't strand the player.
func start(t: Dictionary) -> void:
	task = t
	_actions = 0
	_misses = 0


## The task kinds this toy supports.
func kinds() -> PackedStringArray:
	return ["free"]


## The actions that would meet a task, for scripted runs and tests: each one is what
## perform takes. The first is a miss when the task has one to show, so a run sees the cost.
func script_for(_t: Dictionary, _with_miss := false) -> Array:
	return []


## Do one action as the player would, by the same path a tap takes.
func perform(_action: Dictionary) -> void:
	pass


## Toys call this for every action, so the counts and the signals stay the same everywhere.
func _report(action: Dictionary) -> void:
	_actions += 1
	if action.get("hit") == false:
		_misses += 1
	if action.has("board"):
		board.append(action.board)
	action["kind"] = task.get("kind", "free")
	acted.emit(action)


func _finish(extra: Dictionary = {}) -> void:
	var result := {"kind": task.get("kind", "free"), "actions": _actions, "misses": _misses}
	result.merge(extra)
	task = {}
	task_done.emit(result)
