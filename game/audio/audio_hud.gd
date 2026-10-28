extends CanvasLayer
## The sound control that follows the player everywhere (FAL-385). Autoloaded as
## `AudioHud`, so it sits above whatever scene is running: a speaker icon that
## turns all sound on and off, and a gear that opens the settings screen.
##
## The speaker shows the state it is in, not the state it would switch to: a lit
## teal speaker means sound is on, a grey one crossed in magenta means off. Off
## is where a fresh install starts.
##
## It parks in the top-right corner, 24px in, and ignores pointer events
## everywhere else, so it never covers an answer or a navigation button.

## How far in from the screen's right edge the speaker and gear reach (24px inset,
## two 112px buttons, a 16px gap), plus 16px of air. A screen with controls along
## its top edge keeps this much clear so the icons never cover one.
const RESERVED_RIGHT := 280.0

const ICON_ON := preload("res://assets/icons/speaker-on.svg")
const ICON_OFF := preload("res://assets/icons/speaker-off.svg")

@onready var _controls: Control = %Controls
@onready var _toggle: Button = %SoundToggle
@onready var _settings_button: Button = %SettingsButton
@onready var _settings: SettingsPanel = %Settings


func _ready() -> void:
	_toggle.toggled.connect(_on_toggled)
	_settings_button.pressed.connect(_settings.open)
	# The settings screen carries its own switch, so step out of its way.
	_settings.visibility_changed.connect(_follow_settings)
	Audio.settings_changed.connect(_show_state)
	_show_state()


## Open the settings screen from code, for a pause menu or a keyboard shortcut.
func open_settings() -> void:
	_settings.open()


func _on_toggled(pressed: bool) -> void:
	Audio.sound_enabled = pressed
	if pressed:
		# One quiet blip, so turning sound on proves itself straight away.
		Audio.play_sfx("confirm")


func _follow_settings() -> void:
	_controls.visible = not _settings.visible


func _show_state() -> void:
	_toggle.set_pressed_no_signal(Audio.sound_enabled)
	_toggle.icon = ICON_ON if Audio.sound_enabled else ICON_OFF
	_toggle.tooltip_text = ("Sound is on — tap to turn it off" if Audio.sound_enabled
			else "Sound is off — tap to turn it on")
