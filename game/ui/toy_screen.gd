extends Control
## A toy on its own (#217), at /?toy=relay, or res://scenes/toy.tscn in the editor: the
## relay set up as the exemplar sets it, with a button per task kind, the broken relay
## (oupa's radio), and a stock reaction captioned on a miss, as the lesson player plays
## one. It is a test bench, not a screen students reach: nothing links to it.

const MAIN := "res://scenes/main.tscn"
const ITEM := {"toy": "relay", "rule": "x² − 4", "dial": [-5, 5], "places": {"12": "Scrap Fields"}}
const BROKEN := "x² + 4"
const TASKS := [
	["Free sends", {"kind": "free", "count": 3}],
	["Send −3", {"kind": "send", "input": -3}],
	["Find 12", {"kind": "find", "output": 12, "place": "Scrap Fields"}],
]
## Rook's stock reactions from the exemplar, until the script's set is read (#220).
const REACTIONS := ["Static. Come in again.", "Eish. That one's gone to the wrong settlement. They'll cope.",
	"Shame. The relay didn't like that.", "Hold on. Something's smoking up there. Go again."]

var toy: LessonToy
var holder: Control
var caption: Label
var broken := false
var _reaction := 0


func _ready() -> void:
	theme = UiTheme.make()
	var bg := ColorRect.new()
	bg.color = Explainer.INK
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var col := VBoxContainer.new()
	col.set_anchors_preset(Control.PRESET_FULL_RECT)
	col.offset_left = 30
	col.offset_right = -30
	col.offset_top = 150
	col.offset_bottom = -40
	col.add_theme_constant_override("separation", 20)
	add_child(col)
	var tasks := HFlowContainer.new()
	tasks.name = "Tasks"
	tasks.add_theme_constant_override("h_separation", 14)
	tasks.add_theme_constant_override("v_separation", 14)
	for t in TASKS:
		var b := Button.new()
		b.text = t[0]
		b.name = t[0].replace(" ", "")
		b.pressed.connect(func() -> void: give(t[1]))
		tasks.add_child(b)
	var radio := Button.new()
	radio.name = "Radio"
	radio.text = "Oupa's radio"
	radio.toggle_mode = true
	radio.toggled.connect(func(on: bool) -> void:
		broken = on
		build())
	tasks.add_child(radio)
	var close := Button.new()
	close.text = "Close"
	close.pressed.connect(func() -> void: get_tree().change_scene_to_file.call_deferred(MAIN))
	tasks.add_child(close)
	col.add_child(tasks)
	holder = PanelContainer.new()
	holder.name = "Board"
	var bs := StyleBoxFlat.new()
	bs.bg_color = Explainer.SLATE
	bs.border_color = Explainer.IRON
	bs.set_border_width_all(10)
	bs.set_corner_radius_all(10)
	bs.set_content_margin_all(28)
	holder.add_theme_stylebox_override("panel", bs)
	holder.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(holder)
	caption = UiTheme.label("", UiTheme.BODY, Explainer.CHALK)
	caption.name = "Caption"
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.custom_minimum_size.y = 120
	col.add_child(caption)
	build()


func build() -> void:
	if toy != null:
		toy.queue_free()
	var item := ITEM.duplicate()
	if broken:
		item.broken = BROKEN
	toy = Toys.make(item)
	toy.reduced_motion = LessonToy.reduce_motion(SaveData.load_from())
	toy.acted.connect(_on_act)
	toy.task_done.connect(func(_r: Dictionary) -> void: caption.text = "Task met. Pick another.")
	holder.add_child(toy)
	var arg := str(preload("res://ui/practice.gd").url_args().get("task", ""))
	give(TASKS[clampi(int(arg), 0, TASKS.size() - 1)][1] if arg != "" else TASKS[0][1])


func give(t: Dictionary) -> void:
	toy.start(t)
	caption.text = ""


func _on_act(a: Dictionary) -> void:
	if a.hit == false:
		caption.text = REACTIONS[_reaction % REACTIONS.size()]
		_reaction += 1
	else:
		caption.text = "Copy." if a.hit == null else "Sent."
