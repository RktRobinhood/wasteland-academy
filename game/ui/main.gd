extends Control
## The title screen. "Play" opens the map (ui/map.gd), "Practice" opens the practice
## screen and "Engine" the engine explorer. On the first load only, ?explore (see
## explorer.gd) goes to the explorer, a deep link to the Bazaar (see bazaar.gd), a run
## (see fight.gd) or a question (see practice.gd) goes straight there, and a map link
## such as #functions/quadratics (see engine/map_link.gd) opens the map there.
##
## Key art (FAL-470): title/key-art behind the title on a PC (a landscape window) and
## title/key-art-phone on a phone (portrait). The title sits in the art's top band and
## the buttons at its foot, and Spark, who is in the art, steps aside. With no art for
## the window's shape, the title screen looks as it did before.

const PRACTICE := "res://scenes/practice.tscn"
const FIGHT := "res://scenes/fight.tscn"
const EXPLORER := "res://scenes/explorer.tscn"
const BAZAAR := "res://scenes/bazaar.tscn"

static var _routed := false

var key_art: TextureRect
## Pushes the buttons to the foot of the screen while key art shows.
var _gap: Control


func _ready() -> void:
	theme = UiTheme.make()
	key_art = UiTheme.backdrop(0.0)
	key_art.name = "KeyArt"
	add_child(key_art)
	move_child(key_art, $Background.get_index() + 1)
	_gap = Control.new()
	_gap.name = "Gap"
	_gap.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$Center/Column.add_child(_gap)
	$Center/Column.move_child(_gap, $Center/Column/Buttons.get_index())
	resized.connect(fit_art)
	fit_art()
	var play := get_node_or_null("Center/Column/Buttons/Play") as Button
	if play != null:
		play.pressed.connect(open_map)
		play.grab_focus.call_deferred()
	var start := get_node_or_null("Center/Column/Buttons/Practice") as Button
	if start != null:
		start.pressed.connect(open_practice)
	var engine := get_node_or_null("Center/Column/Engine") as Button
	if engine != null:
		engine.pressed.connect(open_explorer)
	MapLink.listen(get_tree())
	if _routed:
		return
	_routed = true
	var practice := preload("res://ui/practice.gd")
	if practice.url_args().has("explore"):
		open_explorer.call_deferred()
	elif preload("res://ui/bazaar.gd").deep_link() != "":
		open_bazaar.call_deferred()
	elif not preload("res://ui/fight.gd").deep_link().is_empty():
		open_fight.call_deferred()
	elif not practice.deep_link().is_empty():
		open_practice.call_deferred()
	elif MapLink.address() != "":
		get_tree().change_scene_to_file.call_deferred(MapLink.scene_for(MapLink.parse(MapLink.address())))


## The key art for the window's shape, and the layout around it.
func fit_art() -> void:
	var tex := ArtSlots.texture("title/key-art" if size.x > size.y else "title/key-art-phone")
	UiTheme.show_backdrop(key_art, tex)
	var column := $Center/Column as Control
	$Center/Column/Spark.visible = tex == null
	_gap.visible = tex != null
	column.custom_minimum_size.y = size.y * 0.9 if tex != null else 0.0


func open_practice() -> void:
	get_tree().change_scene_to_file(PRACTICE)


## The world map, as a history entry, so the browser's back button returns here.
func open_map() -> void:
	MapLink.go(get_tree(), MapLink.WORLD)


func open_fight() -> void:
	get_tree().change_scene_to_file(FIGHT)


func open_explorer() -> void:
	get_tree().change_scene_to_file(EXPLORER)


func open_bazaar() -> void:
	get_tree().change_scene_to_file(BAZAAR)
