class_name SettingsPanel
extends Control
## The sound settings screen (FAL-385): all sound on or off, a level for the
## background music and a separate one for the effects.
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
@onready var _hint: Label = %Hint
@onready var _close: Button = %Close

var _showing := false


func _ready() -> void:
	hide()
	_sound.toggled.connect(_on_sound_toggled)
	_music.value_changed.connect(_on_music_changed)
	_sfx.value_changed.connect(_on_sfx_changed)
	# One blip when the drag ends, so the level can be judged without a stutter.
	_sfx.drag_ended.connect(_on_sfx_drag_ended)
	_close.pressed.connect(close)
	Audio.settings_changed.connect(_show_current)
	_show_current()


func open() -> void:
	_show_current()
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
	_hint.visible = not Audio.sound_enabled
	_showing = false


func _on_sound_toggled(pressed: bool) -> void:
	Audio.sound_enabled = pressed
	if pressed:
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
