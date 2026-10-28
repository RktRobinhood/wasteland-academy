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
##
## Which loop plays where is res://audio/music_tracks.gd; the effects are
## res://audio/sfx_cues.gd. Settings are saved to user://settings.cfg as soon as
## they change, so they survive a reload.

## Emitted after any of the three settings changes, however it changed.
signal settings_changed

const SETTINGS_PATH := "user://settings.cfg"
const SETTINGS_SECTION := "audio"
const MUSIC_BUS := "Music"
const SFX_BUS := "SFX"
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

## Effects bus level, 0.0 (silent) to 1.0 (file level minus SFX_HEADROOM_DB).
var sfx_volume := DEFAULT_SFX_VOLUME:
	set(value):
		value = clampf(value, 0.0, 1.0)
		if is_equal_approx(value, sfx_volume):
			return
		sfx_volume = value
		_apply_volumes()
		_changed()

var _location := ""
var _music: Array[AudioStreamPlayer] = []
var _playing := 0
var _fade: Tween
var _sfx: Array[AudioStreamPlayer] = []
var _next_voice := 0
var _loading := false


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


## Play one short effect. Does nothing when sound is off.
func play_sfx(cue: String) -> void:
	if not SfxCues.CUES.has(cue):
		push_warning("Audio: no effect named '%s'" % cue)
		return
	if not sound_enabled or sfx_volume <= 0.0:
		return
	var path := SfxCues.path(cue)
	if not ResourceLoader.exists(path):
		push_warning("Audio: missing effect %s" % path)
		return
	var player := _free_voice()
	player.stream = load(path)
	player.volume_db = SFX_HEADROOM_DB + float(SfxCues.CUES[cue]["db"])
	player.play()


## True while a music loop is audible. For tests and for the settings screen.
func music_playing() -> bool:
	return _music.any(func(player: AudioStreamPlayer) -> bool: return player.playing)


## Put the three settings back to a fresh install and save that.
func reset_settings() -> void:
	sound_enabled = DEFAULT_SOUND_ENABLED
	music_volume = DEFAULT_MUSIC_VOLUME
	sfx_volume = DEFAULT_SFX_VOLUME


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


func _apply_volumes() -> void:
	_set_bus_level(MUSIC_BUS, music_volume)
	_set_bus_level(SFX_BUS, sfx_volume)


func _set_bus_level(bus: String, level: float) -> void:
	var idx := _bus_index(bus)
	# linear_to_db(0.0) is -inf, so mute instead of sending that to the server.
	AudioServer.set_bus_volume_db(idx, linear_to_db(maxf(level, 0.0001)))
	AudioServer.set_bus_mute(idx, not sound_enabled or level <= 0.0)


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
	_loading = false


func _save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.load(SETTINGS_PATH)  # Keep any other section a later screen adds.
	cfg.set_value(SETTINGS_SECTION, "sound_enabled", sound_enabled)
	cfg.set_value(SETTINGS_SECTION, "music_volume", music_volume)
	cfg.set_value(SETTINGS_SECTION, "sfx_volume", sfx_volume)
	var err := cfg.save(SETTINGS_PATH)
	if err != OK:
		push_warning("Audio: could not save %s (error %d)" % [SETTINGS_PATH, err])
