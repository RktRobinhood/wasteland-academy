extends Control
## The title screen. "Play" opens the Quadratics floor select (the map, G5, replaces it);
## "Practice" opens the practice screen. A deep link to a question (see practice.gd) or
## a run (see fight.gd) goes straight there.

const PRACTICE := "res://scenes/practice.tscn"
const FIGHT := "res://scenes/fight.tscn"


func _ready() -> void:
	theme = UiTheme.make()
	var play := get_node_or_null("Center/Column/Buttons/Play") as Button
	if play != null:
		play.pressed.connect(open_fight)
		play.grab_focus.call_deferred()
	var practice := get_node_or_null("Center/Column/Buttons/Practice") as Button
	if practice != null:
		practice.pressed.connect(open_practice)
	if not preload("res://ui/fight.gd").deep_link().is_empty():
		open_fight.call_deferred()
	elif not preload("res://ui/practice.gd").deep_link().is_empty():
		open_practice.call_deferred()


func open_practice() -> void:
	get_tree().change_scene_to_file(PRACTICE)


func open_fight() -> void:
	get_tree().change_scene_to_file(FIGHT)
