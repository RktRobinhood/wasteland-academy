class_name SettingsPanel
extends Control
## The sound settings screen (FAL-385): all sound on or off, a level for the
## background music, a separate one for the effects, and one for Spark's voice in the
## explainers (FAL-429). Each of Music, Voice and Sound effects has an On/Off switch
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

var _showing := false


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
