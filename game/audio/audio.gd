extends Node
## All game sound: one music loop per location, the accepted one-shot effects,
## and the player's sound settings. Autoloaded as `Audio` (FAL-385).
##
## Sound starts OFF, because students play this in class. Nothing is decoded or
## heard until they turn it on with the speaker icon, which also means the first
## sound always follows a tap — what browsers require of a web build anyway.
##
##   Audio.play_location("signal-tower")  # the music for a place, crossfaded in
##   Audio.play_sfx("correct")            # a short one-shot
##   Audio.sound_enabled = true           # what the speaker icon switches
##   Audio.music_volume = 0.4             # 0.0-1.0, the settings sliders
##   Audio.voice_muted = true             # one channel off, its level kept (#235)
##   Audio.play_voice(stream)             # Spark's explainer line, the music ducked under it
##
## Which loop plays where is res://audio/music_tracks.gd; the effects are
## res://audio/sfx_cues.gd. Settings are saved to user://settings.cfg as soon as
## they change, so they survive a reload.

## Emitted after any of the seven settings changes, however it changed.
signal settings_changed

const SETTINGS_PATH := "user://settings.cfg"
const SETTINGS_SECTION := "audio"
const MUSIC_BUS := "Music"
const SFX_BUS := "SFX"
## Spark's explainer lines (FAL-429).
const VOICE_BUS := "Voice"
## How far the music drops while Spark talks, and how fast it goes and comes back.
const DUCK_DB := -12.0
const DUCK_SEC := 0.25
## Long enough that walking into a boss fight does not cut the region bed off.
const CROSSFADE_SEC := 1.2
const SILENT_DB := -60.0
## Every effect sits this far below its file level so a blip never jumps out
## over the music bed. The files themselves peak at -1.1 dBTP.
const SFX_HEADROOM_DB := -6.0
## Enough voices for an answer, a reward and a UI tap landing together.
const SFX_VOICES := 6

## Off on a fresh install. Starting volumes leave headroom for the effects and
## keep the bed quiet enough for a classroom.
const DEFAULT_SOUND_ENABLED := false
const DEFAULT_MUSIC_VOLUME := 0.6
const DEFAULT_SFX_VOLUME := 0.6
const DEFAULT_VOICE_VOLUME := 0.8

## Where the player is until a scene says otherwise. The boot screen is the
## overworld; drop this once the overworld scene calls play_location() itself.
const BOOT_LOCATION := "overworld"

## The speaker icon's switch. Turning it off stops everything; turning it back
## on resumes the current location.
var sound_enabled := DEFAULT_SOUND_ENABLED:
	set(value):
		if value == sound_enabled:
			return
		sound_enabled = value
		_apply_enabled()
		_changed()

## Music bus level, 0.0 (silent) to 1.0 (file level).
var music_volume := DEFAULT_MUSIC_VOLUME:
	set(value):
		value = clampf(value, 0.0, 1.0)
		if is_equal_approx(value, music_volume):
			return
		music_volume = value
		_apply_volumes()
		_changed()

## Each channel's own off switch, beside its slider (#235). Muting silences the bus
## and keeps the slider's level, so unmuting puts it back where it was.
var music_muted := false:
	set(value):
		if value == music_muted:
			return
		music_muted = value
		_apply_volumes()
		_changed()

var sfx_muted := false:
	set(value):
		if value == sfx_muted:
			return
		sfx_muted = value
		if sfx_muted:
			for player in _sfx:
				player.stop()
		_apply_volumes()
		_changed()

## Muting the voice also ends the line playing, so the music is not left ducked under
## a line nobody hears.
var voice_muted := false:
	set(value):
		if value == voice_muted:
			return
		voice_muted = value
		if voice_muted and _voice != null:
			stop_voice()
		_apply_volumes()
		_changed()

## Effects bus level, 0.0 (silent) to 1.0 (file level minus SFX_HEADROOM_DB).
var sfx_volume := DEFAULT_SFX_VOLUME:
	set(value):
		value = clampf(value, 0.0, 1.0)
		if is_equal_approx(value, sfx_volume):
			return
		sfx_volume = value
		_apply_volumes()
		_changed()

## Voice bus level, 0.0 (silent) to 1.0 (file level).
var voice_volume := DEFAULT_VOICE_VOLUME:
	set(value):
		value = clampf(value, 0.0, 1.0)
		if is_equal_approx(value, voice_volume):
			return
		voice_volume = value
		_apply_volumes()
		_changed()

## The last effect a scene asked for, heard or not (sound off still records it), so a
## test can tell what a screen would play.
var last_sfx := ""
## The file of the last voice line a scene asked for, heard or not, for tests.
var last_voice := ""

var _location := ""
var _music: Array[AudioStreamPlayer] = []
var _playing := 0
var _fade: Tween
var _sfx: Array[AudioStreamPlayer] = []
var _next_voice := 0
var _loading := false
var _voice: AudioStreamPlayer
## 0 (music at its level) to 1 (ducked by DUCK_DB), tweened while Spark talks.
var _duck := 0.0
var _duck_tween: Tween


func _ready() -> void:
	# Sound must not stop because something paused the game.
	process_mode = Node.PROCESS_MODE_ALWAYS
	for _i in 2:
		var player := AudioStreamPlayer.new()
		player.bus = MUSIC_BUS
		player.volume_db = SILENT_DB
		add_child(player)
		_music.append(player)
	for _i in SFX_VOICES:
		var player := AudioStreamPlayer.new()
		player.bus = SFX_BUS
		add_child(player)
		_sfx.append(player)
	_voice = AudioStreamPlayer.new()
	_voice.bus = VOICE_BUS
	_voice.finished.connect(_set_ducked.bind(false))
	add_child(_voice)
	_load_settings()
	_apply_volumes()
	play_location(BOOT_LOCATION)


## The location whose music is current, or "" before anywhere has been entered.
func location() -> String:
	return _location


## Play the loop for a location, crossfading out whatever was playing. Silently
## remembers the location when sound is off, and starts there when it goes on.
func play_location(cue: String) -> void:
	if not MusicTracks.CUES.has(cue):
		push_warning("Audio: no music cue named '%s'" % cue)
		return
	if cue == _location:
		return
	_location = cue
	if sound_enabled:
		_start_music(cue)


## Stop the music and forget where we were.
func stop_music() -> void:
	_location = ""
	_kill_fade()
	for player in _music:
		player.stop()


## Play one short effect. Does nothing when sound or the effects are off.
func play_sfx(cue: String) -> void:
	if not SfxCues.CUES.has(cue):
		push_warning("Audio: no effect named '%s'" % cue)
		return
	last_sfx = cue
	if not sound_enabled or sfx_muted or sfx_volume <= 0.0:
		return
	var path := SfxCues.path(cue)
	if not ResourceLoader.exists(path):
		push_warning("Audio: missing effect %s" % path)
		return
	var player := _free_voice()
	player.stream = load(path)
	player.volume_db = SFX_HEADROOM_DB + float(SfxCues.CUES[cue]["db"])
	player.play()


## Play one voice line on the Voice bus, stopping the one before, with the music ducked
## under it. `speed` plays it faster or slower at the same pitch. `from` is a position in
## the line, in seconds. Does nothing, and returns false, when sound or the voice is off.
func play_voice(stream: AudioStream, speed := 1.0, from := 0.0) -> bool:
	_voice.stop()
	last_voice = stream.resource_path if stream != null else ""
	if stream == null or not sound_enabled or voice_muted or voice_volume <= 0.0:
		_set_ducked(false)
		return false
	_voice.stream = stream
	set_voice_speed(speed)
	_voice.play(from)
	_set_ducked(true)
	return true


## Stop Spark's line and bring the music back up.
func stop_voice() -> void:
	_voice.stop()
	_set_ducked(false)


## True while a voice line is playing.
func voice_playing() -> bool:
	return _voice.playing


## The speed of the line playing now and the next ones: the pitch shift on the Voice bus
## undoes what pitch_scale does to the pitch.
func set_voice_speed(speed: float) -> void:
	_voice.pitch_scale = speed
	var idx := _bus_index(VOICE_BUS)
	var at := -1
	for i in AudioServer.get_bus_effect_count(idx):
		if AudioServer.get_bus_effect(idx, i) is AudioEffectPitchShift:
			at = i
	if at == -1:
		if is_equal_approx(speed, 1.0):
			return
		AudioServer.add_bus_effect(idx, AudioEffectPitchShift.new())
		at = AudioServer.get_bus_effect_count(idx) - 1
	(AudioServer.get_bus_effect(idx, at) as AudioEffectPitchShift).pitch_scale = 1.0 / speed
	AudioServer.set_bus_effect_enabled(idx, at, not is_equal_approx(speed, 1.0))


## Whether the music is ducked for Spark now (for tests).
func ducked() -> bool:
	return _duck > 0.0


func _set_ducked(on: bool) -> void:
	if _duck_tween != null and _duck_tween.is_valid():
		_duck_tween.kill()
	_duck_tween = create_tween()
	_duck_tween.tween_method(func(d: float) -> void:
		_duck = d
		_apply_volumes(), _duck, 1.0 if on else 0.0, DUCK_SEC)


## True while a music loop is audible. For tests and for the settings screen.
func music_playing() -> bool:
	return _music.any(func(player: AudioStreamPlayer) -> bool: return player.playing)


## Put the seven settings back to a fresh install and save that.
func reset_settings() -> void:
	sound_enabled = DEFAULT_SOUND_ENABLED
	music_volume = DEFAULT_MUSIC_VOLUME
	sfx_volume = DEFAULT_SFX_VOLUME
	voice_volume = DEFAULT_VOICE_VOLUME
	music_muted = false
	sfx_muted = false
	voice_muted = false


func _changed() -> void:
	if not _loading:
		_save_settings()
	settings_changed.emit()


func _apply_enabled() -> void:
	_apply_volumes()
	if sound_enabled:
		if _location != "":
			_start_music(_location)
		return
	_kill_fade()
	for player in _music:
		player.stop()
	for player in _sfx:
		player.stop()
	stop_voice()


func _apply_volumes() -> void:
	_set_bus_level(MUSIC_BUS, music_volume, music_muted, DUCK_DB * _duck)
	_set_bus_level(SFX_BUS, sfx_volume, sfx_muted)
	_set_bus_level(VOICE_BUS, voice_volume, voice_muted)


func _set_bus_level(bus: String, level: float, muted: bool, offset_db := 0.0) -> void:
	var idx := _bus_index(bus)
	# linear_to_db(0.0) is -inf, so mute instead of sending that to the server.
	AudioServer.set_bus_volume_db(idx, linear_to_db(maxf(level, 0.0001)) + offset_db)
	AudioServer.set_bus_mute(idx, not sound_enabled or muted or level <= 0.0)


## The project's bus layout provides Music and SFX; add them if it ever does not,
## so a missing layout costs the player volume control, not all sound.
func _bus_index(bus: String) -> int:
	var idx := AudioServer.get_bus_index(bus)
	if idx != -1:
		return idx
	AudioServer.add_bus()
	idx = AudioServer.bus_count - 1
	AudioServer.set_bus_name(idx, bus)
	AudioServer.set_bus_send(idx, "Master")
	push_warning("Audio: bus '%s' was missing from the layout; added it" % bus)
	return idx


func _start_music(cue: String) -> void:
	var stream := _music_stream(cue)
	if stream == null:
		return
	var outgoing := _music[_playing]
	_playing = 1 - _playing
	var incoming := _music[_playing]
	_kill_fade()
	incoming.stop()
	incoming.stream = stream
	incoming.volume_db = SILENT_DB
	incoming.play()
	_fade = create_tween().set_parallel(true)
	_fade.tween_property(incoming, "volume_db", 0.0, CROSSFADE_SEC)
	if outgoing.playing:
		_fade.tween_property(outgoing, "volume_db", SILENT_DB, CROSSFADE_SEC)
		_fade.chain().tween_callback(outgoing.stop)


func _music_stream(cue: String) -> AudioStream:
	var path := MusicTracks.path(cue)
	if not ResourceLoader.exists(path):
		push_warning("Audio: missing loop %s" % path)
		return null
	var stream := load(path) as AudioStream
	# The loops were edited to join end to start, so repeat them whole.
	if stream is AudioStreamOggVorbis:
		var ogg := stream as AudioStreamOggVorbis
		ogg.loop = true
		ogg.loop_offset = 0.0
	return stream


func _free_voice() -> AudioStreamPlayer:
	for player in _sfx:
		if not player.playing:
			return player
	# Everything is busy: take the oldest voice in turn rather than drop the cue.
	var player := _sfx[_next_voice]
	_next_voice = (_next_voice + 1) % _sfx.size()
	return player


func _kill_fade() -> void:
	if _fade != null and _fade.is_valid():
		_fade.kill()
	_fade = null


func _load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) != OK:
		return
	_loading = true
	sound_enabled = bool(cfg.get_value(SETTINGS_SECTION, "sound_enabled", DEFAULT_SOUND_ENABLED))
	music_volume = float(cfg.get_value(SETTINGS_SECTION, "music_volume", DEFAULT_MUSIC_VOLUME))
	sfx_volume = float(cfg.get_value(SETTINGS_SECTION, "sfx_volume", DEFAULT_SFX_VOLUME))
	voice_volume = float(cfg.get_value(SETTINGS_SECTION, "voice_volume", DEFAULT_VOICE_VOLUME))
	# Files saved before #235 have no mutes; they load as unmuted.
	music_muted = bool(cfg.get_value(SETTINGS_SECTION, "music_muted", false))
	sfx_muted = bool(cfg.get_value(SETTINGS_SECTION, "sfx_muted", false))
	voice_muted = bool(cfg.get_value(SETTINGS_SECTION, "voice_muted", false))
	_loading = false


func _save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.load(SETTINGS_PATH)  # Keep any other section a later screen adds.
	cfg.set_value(SETTINGS_SECTION, "sound_enabled", sound_enabled)
	cfg.set_value(SETTINGS_SECTION, "music_volume", music_volume)
	cfg.set_value(SETTINGS_SECTION, "sfx_volume", sfx_volume)
	cfg.set_value(SETTINGS_SECTION, "voice_volume", voice_volume)
	cfg.set_value(SETTINGS_SECTION, "music_muted", music_muted)
	cfg.set_value(SETTINGS_SECTION, "sfx_muted", sfx_muted)
	cfg.set_value(SETTINGS_SECTION, "voice_muted", voice_muted)
	var err := cfg.save(SETTINGS_PATH)
	if err != OK:
		push_warning("Audio: could not save %s (error %d)" % [SETTINGS_PATH, err])
