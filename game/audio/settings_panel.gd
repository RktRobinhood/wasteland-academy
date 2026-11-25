class_name SettingsPanel
extends Control
## The settings screen: sound (FAL-385), the course (#186) and access (#196). Sound:
## all sound on or off, a level for the background music, a separate one for the
## effects, and one for Spark's voice in the explainers (FAL-429). Each of Music, Voice and Sound effects has an On/Off switch
## beside its slider (#235): Off silences that channel and keeps the slider where it is.
##
## It lives in the AudioHud autoload, so the gear icon opens it from anywhere.
## Changes reach Audio as the player drags, and Audio saves them.
##
## The map and the runs choose the music themselves (Audio.play_location, FAL-417).

@onready var _sound: Button = %SoundToggle
@onready var _music: HSlider = %MusicSlider
@onready var _music_value: Label = %MusicValue
@onready var _sfx: HSlider = %SfxSlider
@onready var _sfx_value: Label = %SfxValue
@onready var _voice: HSlider = %VoiceSlider
@onready var _voice_value: Label = %VoiceValue
@onready var _music_on: Button = %MusicToggle
@onready var _voice_on: Button = %VoiceToggle
@onready var _sfx_on: Button = %SfxToggle
@onready var _hint: Label = %Hint
@onready var _close: Button = %Close
@onready var _save_button: Button = %SaveButton

var _transfer: SaveTransferPanel

## The save used when no open screen holds one. Tests point it elsewhere.
var fallback_path := SaveData.PATH

var _showing := false
var _group: ButtonGroup
var _timer_group: ButtonGroup
var _motion: Button
var _text: Button


func _ready() -> void:
	hide()
	_sound.toggled.connect(_on_sound_toggled)
	_music.value_changed.connect(_on_music_changed)
	_sfx.value_changed.connect(_on_sfx_changed)
	# One blip when the drag ends, so the level can be judged without a stutter.
	_sfx.drag_ended.connect(_on_sfx_drag_ended)
	_voice.value_changed.connect(func(value: float) -> void: Audio.voice_volume = value)
	# Pressed means the channel is heard, as with the All sound switch above them.
	_music_on.toggled.connect(func(on: bool) -> void: Audio.music_muted = not on)
	_voice_on.toggled.connect(func(on: bool) -> void: Audio.voice_muted = not on)
	_sfx_on.toggled.connect(_on_sfx_on_toggled)
	_close.pressed.connect(close)
	_transfer = SaveTransferPanel.new()
	add_child(_transfer)
	_save_button.pressed.connect(_transfer.open)
	_add_play_settings()
	_add_access_settings()
	UiTheme.set_larger_text(UiTheme.larger_text(SaveData.load_from(fallback_path)))
	Audio.settings_changed.connect(_show_current)
	_show_current()


## The student's course and the first-run cards, above the save button (#186): the
## course picked on first launch must be easy to change later (string audit ST9).
func _add_play_settings() -> void:
	var column := _save_button.get_parent()
	var at := _save_button.get_index()
	var label := Label.new()
	label.name = "CourseLabel"
	label.text = "Your course"
	var row := HBoxContainer.new()
	row.name = "CourseRow"
	row.add_theme_constant_override("separation", 12)
	_group = ButtonGroup.new()
	for id in Courses.ids():
		var b := Button.new()
		b.name = id
		b.text = Courses.info(id).short
		b.tooltip_text = Courses.info(id).name
		b.toggle_mode = true
		b.button_group = _group
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.custom_minimum_size.y = 96
		b.pressed.connect(_set_course.bind(id))
		row.add_child(b)
	var cards := Button.new()
	cards.name = "CardsButton"
	cards.text = "How a fight works"
	cards.pressed.connect(func() -> void: add_child(FirstRun.fight_cards()))
	for n in [label, row, cards]:
		column.add_child(n)
		column.move_child(n, at)
		at += 1


## Access settings (#196), above the save button: the timer for students with extra
## time, a reduced-motion switch and larger text. They live in the save's settings, so
## they go wherever the save goes (web, PC and phone builds, and an exported save).
func _add_access_settings() -> void:
	var column := _save_button.get_parent()
	var at := _save_button.get_index()
	var label := Label.new()
	label.name = "TimerLabel"
	label.text = "Timer"
	var row := HBoxContainer.new()
	row.name = "TimerRow"
	row.add_theme_constant_override("separation", 12)
	_timer_group = ButtonGroup.new()
	for m in Tuning.TIMER_CHOICES:
		var b := Button.new()
		b.name = "Off" if m == 0.0 else "x" + _times(m).replace(".", "_")
		b.text = timer_name(m)
		b.tooltip_text = "No timer: no question runs out of time" if m == 0.0 else "Time on each question ×%s" % _times(m)
		b.toggle_mode = true
		b.button_group = _timer_group
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.custom_minimum_size.y = 96
		b.set_meta("timer", m)
		b.pressed.connect(_set_setting.bind("timer", m))
		row.add_child(b)
	_motion = _switch_row(column, "Motion", "Reduced motion", func(on: bool) -> void: _set_setting("reduced_motion", on))
	_text = _switch_row(column, "Text", "Larger text", func(on: bool) -> void:
		_set_setting("larger_text", on)
		UiTheme.set_larger_text(on))
	var motion_row := _motion.get_parent()
	var text_row := _text.get_parent()
	for n in [label, row, motion_row, text_row]:
		if n.get_parent() == null:
			column.add_child(n)
		column.move_child(n, at)
		at += 1


## A row with a label and an On/Off switch, like All sound's. Returns the switch.
func _switch_row(column: Node, id: String, text: String, on_toggle: Callable) -> Button:
	var row := HBoxContainer.new()
	row.name = id + "Row"
	row.add_theme_constant_override("separation", 20)
	var l := Label.new()
	l.text = text
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(l)
	var b := Button.new()
	b.name = id + "Toggle"
	b.toggle_mode = true
	b.custom_minimum_size = Vector2(240, 0)
	b.add_theme_color_override("font_pressed_color", UiTheme.TEAL)
	b.add_theme_stylebox_override("pressed", _sound.get_theme_stylebox("pressed"))
	b.toggled.connect(func(on: bool) -> void:
		b.text = "On" if on else "Off"
		on_toggle.call(on))
	row.add_child(b)
	column.add_child(row)
	return b


## A timer button's name: ×1, ×1.25, ×1.5 or Off.
static func timer_name(m: float) -> String:
	return "Off" if m == 0.0 else "×" + _times(m)


static func _times(m: float) -> String:
	return str(m).trim_suffix(".0")


## The timer, motion and text switches as the save has them. With the device asking
## for less motion, motion is reduced whatever the switch says, so the switch shows On
## and can't be turned off here.
func _show_access() -> void:
	if _timer_group == null:
		return
	var data := _current_save()
	var m := Tuning.timer_multiplier(data)
	for b in _timer_group.get_buttons():
		b.set_pressed_no_signal(is_equal_approx(float(b.get_meta("timer")), m))
	var device := AmbientLayer.motion_reduced({})
	var reduced := AmbientLayer.motion_reduced(data)
	_motion.set_pressed_no_signal(reduced)
	_motion.text = "On" if reduced else "Off"
	_motion.disabled = device
	_motion.tooltip_text = "Your device asks for reduced motion" if device else ""
	var larger := UiTheme.larger_text(data)
	_text.set_pressed_no_signal(larger)
	_text.text = "On" if larger else "Off"


## Sets one of the save's settings. A screen that holds the save gets it too (as with
## the course), and one that can apply it at once (a fight's journey scene) does.
func _set_setting(key: String, value: Variant) -> void:
	var scene := get_tree().current_scene
	var data := _current_save()
	if not data.has("settings"):
		data["settings"] = {}
	data.settings[key] = value
	SaveData.store(data, scene.get("save_path") if scene != null and scene.get("save_path") is String else fallback_path)
	if scene != null and scene.has_method("apply_settings"):
		scene.call("apply_settings")


## The course on the buttons: the open screen's save, or the saved file's.
func _show_course() -> void:
	if _group == null:
		return
	var id := Courses.of(_current_save())
	for b in _group.get_buttons():
		b.set_pressed_no_signal(b.name == id)


func _current_save() -> Dictionary:
	var scene := get_tree().current_scene if is_inside_tree() else null
	if scene != null and scene.get("save") is Dictionary and not (scene.get("save") as Dictionary).is_empty():
		return scene.get("save")
	return SaveData.load_from(fallback_path)


## Puts the student on a course. A screen that holds the save (the map, a run, Practice)
## gets it too, so it doesn't write the old course back.
func _set_course(id: String) -> void:
	var scene := get_tree().current_scene
	if scene != null and scene.has_method("set_course"):
		scene.call("set_course", id)
		return
	var data := _current_save()
	if SaveData.set_course(data, id):
		SaveData.store(data, scene.get("save_path") if scene != null and scene.get("save_path") is String else fallback_path)


func open() -> void:
	_show_current()
	_show_course()
	_show_access()
	show()
	_close.grab_focus()
	Audio.play_sfx("confirm")


func close() -> void:
	hide()


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()


## Put what Audio holds on screen, without sending it straight back.
func _show_current() -> void:
	if _showing:
		return
	_showing = true
	_sound.set_pressed_no_signal(Audio.sound_enabled)
	_sound.text = "On" if Audio.sound_enabled else "Off"
	_music.set_value_no_signal(Audio.music_volume)
	_music_value.text = _percent(Audio.music_volume)
	_sfx.set_value_no_signal(Audio.sfx_volume)
	_sfx_value.text = _percent(Audio.sfx_volume)
	_voice.set_value_no_signal(Audio.voice_volume)
	_voice_value.text = _percent(Audio.voice_volume)
	_show_channel(_music_on, not Audio.music_muted)
	_show_channel(_voice_on, not Audio.voice_muted)
	_show_channel(_sfx_on, not Audio.sfx_muted)
	_hint.visible = not Audio.sound_enabled
	_showing = false


func _on_sound_toggled(pressed: bool) -> void:
	Audio.sound_enabled = pressed
	if pressed:
		Audio.play_sfx("confirm")


static func _show_channel(button: Button, on: bool) -> void:
	button.set_pressed_no_signal(on)
	button.text = "On" if on else "Off"


func _on_sfx_on_toggled(on: bool) -> void:
	Audio.sfx_muted = not on
	if on:
		Audio.play_sfx("confirm")


func _on_music_changed(value: float) -> void:
	Audio.music_volume = value


func _on_sfx_changed(value: float) -> void:
	Audio.sfx_volume = value


func _on_sfx_drag_ended(changed: bool) -> void:
	if changed:
		Audio.play_sfx("confirm")


static func _percent(level: float) -> String:
	return "%d%%" % roundi(level * 100.0)
