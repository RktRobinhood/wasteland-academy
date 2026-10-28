extends "res://tests/test_case.gd"
## The audio the game ships (FAL-385): a loop per location, the accepted effects,
## two buses the sliders can move, and sound that starts off and stays saved.

const MUSIC_DIR := "res://assets/audio/music/"
const SETTINGS_PATH := "user://settings.cfg"
const HUD := "res://scenes/audio_hud.tscn"
const SETTINGS_SCENE := "res://scenes/settings.tscn"


func _audio() -> Node:
	var audio := tree.root.get_node_or_null("Audio")
	if audio == null:
		fail("the Audio autoload is not in the tree")
	return audio


## Back to a fresh install, so the next test starts where this one found things.
func _restore(audio: Node) -> void:
	audio.sound_enabled = false
	audio.reset_settings()


func test_bus_layout_carries_music_and_sfx() -> void:
	check_eq(ProjectSettings.get_setting("audio/buses/default_bus_layout"),
			"res://audio/bus_layout.tres")
	for bus in ["Music", "SFX"]:
		var idx := AudioServer.get_bus_index(bus)
		check(idx > 0, "no %s bus in the layout" % bus)
		if idx > 0:
			check_eq(String(AudioServer.get_bus_send(idx)), "Master", "%s send" % bus)


func test_every_location_has_its_loop() -> void:
	check_eq(MusicTracks.CUES.size(), 12, "location cues")
	for cue: String in MusicTracks.CUES:
		var path := MusicTracks.path(cue)
		if not ResourceLoader.exists(path):
			fail("%s: no loop at %s" % [cue, path])
			continue
		var stream := load(path) as AudioStream
		check(stream is AudioStreamOggVorbis, "%s: %s is not Ogg Vorbis" % [cue, path])
		var want := float(MusicTracks.CUES[cue]["seconds"])
		check(absf(stream.get_length() - want) < 0.02,
				"%s: %.6fs, the review measured %.6fs" % [cue, stream.get_length(), want])


func test_only_the_wired_in_loops_ship() -> void:
	var files := DirAccess.get_files_at(MUSIC_DIR)
	var oggs: Array[String] = []
	for f in files:
		if f.ends_with(".ogg"):
			oggs.append(MUSIC_DIR + f)
	var wanted: Array[String] = []
	for cue: String in MusicTracks.CUES:
		wanted.append(MusicTracks.path(cue))
	oggs.sort()
	wanted.sort()
	check_eq(oggs, wanted, "the music folder holds something other than the wired-in loops")


func test_each_cue_names_a_second_seed_for_the_listening_pass() -> void:
	for cue: String in MusicTracks.CUES:
		var entry: Dictionary = MusicTracks.CUES[cue]
		check(int(entry["alternate"]) != int(entry["seed"]),
				"%s: the alternate repeats the default seed" % cue)
		check(MusicTracks.alternate_path(cue) != MusicTracks.path(cue),
				"%s: the alternate resolves to the shipped file" % cue)


func test_every_effect_from_the_html_game_is_here() -> void:
	# The cue names mirror js/sfx.js, so gameplay code can be written once.
	var expected := ["clear", "confirm", "correct", "hint", "open", "retry", "reward"]
	var cues := SfxCues.CUES.keys()
	cues.sort()
	check_eq(cues, expected, "effect cues")
	for cue: String in SfxCues.CUES:
		var path := SfxCues.path(cue)
		check(ResourceLoader.exists(path), "%s: no effect at %s" % [cue, path])


func test_sound_is_off_on_a_fresh_install() -> void:
	var script := load("res://audio/audio.gd") as GDScript
	var defaults := script.get_script_constant_map()
	check_eq(defaults["DEFAULT_SOUND_ENABLED"], false,
			"sound must start off: students play this in class")
	check(defaults["DEFAULT_MUSIC_VOLUME"] > 0.0 and defaults["DEFAULT_MUSIC_VOLUME"] <= 1.0,
			"music default")
	check(defaults["DEFAULT_SFX_VOLUME"] > 0.0 and defaults["DEFAULT_SFX_VOLUME"] <= 1.0,
			"effects default")
	# With no settings file, a fresh copy of the singleton must come up silent.
	var saved := FileAccess.get_file_as_bytes(SETTINGS_PATH)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SETTINGS_PATH))
	var fresh: Node = script.new()
	tree.root.add_child(fresh)
	await tree.process_frame
	check_eq(fresh.sound_enabled, false, "a fresh install came up with sound on")
	check_eq(fresh.music_playing(), false, "a fresh install started playing")
	check_eq(fresh.location(), defaults["BOOT_LOCATION"], "a fresh install knows where it is")
	fresh.free()
	if not saved.is_empty():
		var file := FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
		if file != null:
			file.store_buffer(saved)
			file.close()


func test_nothing_plays_while_sound_is_off() -> void:
	var audio := _audio()
	if audio == null:
		return
	audio.sound_enabled = false
	audio.play_location("signal-tower")
	audio.play_sfx("confirm")
	await tree.process_frame
	check_eq(audio.location(), "signal-tower", "the location is still remembered")
	check_eq(audio.music_playing(), false, "music played with sound off")
	_restore(audio)


func test_turning_sound_on_starts_the_location_music() -> void:
	var audio := _audio()
	if audio == null:
		return
	audio.sound_enabled = false
	audio.play_location("thunderdome")
	audio.sound_enabled = true
	await tree.process_frame
	check_eq(audio.music_playing(), true, "sound went on but no music started")
	audio.sound_enabled = false
	await tree.process_frame
	check_eq(audio.music_playing(), false, "sound went off but music kept playing")
	_restore(audio)


func test_an_unknown_location_is_refused() -> void:
	var audio := _audio()
	if audio == null:
		return
	audio.sound_enabled = false
	audio.play_location("signal-tower")
	audio.play_location("no-such-place")
	check_eq(audio.location(), "signal-tower", "an unknown cue replaced the location")
	_restore(audio)


func test_the_sliders_move_their_own_bus() -> void:
	var audio := _audio()
	if audio == null:
		return
	audio.sound_enabled = true
	audio.music_volume = 0.5
	audio.sfx_volume = 1.0
	var music := AudioServer.get_bus_index("Music")
	var sfx := AudioServer.get_bus_index("SFX")
	check(absf(AudioServer.get_bus_volume_db(music) - linear_to_db(0.5)) < 0.01, "music level")
	check(absf(AudioServer.get_bus_volume_db(sfx) - linear_to_db(1.0)) < 0.01, "effects level")
	audio.music_volume = 0.0
	check_eq(AudioServer.is_bus_mute(music), true, "music at zero must mute")
	check_eq(AudioServer.is_bus_mute(sfx), false, "the effects bus followed the music slider")
	audio.sound_enabled = false
	check_eq(AudioServer.is_bus_mute(sfx), true, "sound off must mute the effects bus")
	_restore(audio)


func test_settings_survive_a_reload() -> void:
	var audio := _audio()
	if audio == null:
		return
	audio.sound_enabled = true
	audio.music_volume = 0.25
	audio.sfx_volume = 0.35
	var cfg := ConfigFile.new()
	check_eq(cfg.load(SETTINGS_PATH), OK, "load %s" % SETTINGS_PATH)
	check_eq(cfg.get_value("audio", "sound_enabled"), true, "saved sound_enabled")
	check_eq(cfg.get_value("audio", "music_volume"), 0.25, "saved music_volume")
	check_eq(cfg.get_value("audio", "sfx_volume"), 0.35, "saved sfx_volume")
	# What a restart does: a fresh copy of the singleton reads the file.
	var fresh: Node = (load("res://audio/audio.gd") as GDScript).new()
	tree.root.add_child(fresh)
	await tree.process_frame
	check_eq(fresh.sound_enabled, true, "reloaded sound_enabled")
	check(absf(fresh.music_volume - 0.25) < 0.001, "reloaded music_volume")
	check(absf(fresh.sfx_volume - 0.35) < 0.001, "reloaded sfx_volume")
	fresh.sound_enabled = false
	fresh.free()
	_restore(audio)


func test_the_speaker_icon_has_an_on_and_an_off_face() -> void:
	for path in ["res://assets/icons/speaker-on.svg", "res://assets/icons/speaker-off.svg",
			"res://assets/icons/settings-gear.svg"]:
		check(ResourceLoader.exists(path), "no icon at %s" % path)
		check(load(path) is Texture2D, "%s did not import as a texture" % path)


func test_the_hud_is_autoloaded_with_the_speaker_and_the_gear() -> void:
	check_eq(ProjectSettings.get_setting("autoload/Audio"), "*res://audio/audio.gd")
	check_eq(ProjectSettings.get_setting("autoload/AudioHud"), "*res://scenes/audio_hud.tscn")
	var hud := tree.root.get_node_or_null("AudioHud")
	check(hud != null, "the AudioHud autoload is not in the tree")
	if hud == null:
		return
	check(hud.get_node_or_null("Overlay/Controls/SoundToggle") != null, "no speaker button")
	check(hud.get_node_or_null("Overlay/Controls/SettingsButton") != null, "no settings button")


## The practice screen's Exam-style toggle sits in the same top-right corner, so
## the speaker and gear must leave it free to tap.
func test_the_hud_never_covers_the_practice_header() -> void:
	var hud := tree.root.get_node_or_null("AudioHud")
	if hud == null:
		fail("the AudioHud autoload is not in the tree")
		return
	var controls := hud.get_node("Overlay/Controls") as Control
	# A phone, where the header runs the full width. Headless starts square.
	var window_size := tree.root.size
	tree.root.size = Vector2i(390, 844)
	await tree.process_frame
	var frame := Control.new()
	frame.size = tree.root.get_visible_rect().size
	tree.root.add_child(frame)
	var p: Control = (load("res://scenes/practice.tscn") as PackedScene).instantiate()
	p.save_path = "user://test_audio_practice_save.json"
	frame.add_child(p)
	for i in 3:
		await tree.process_frame
	var toggle := p.find_child("ExamOnly", true, false) as Control
	check(toggle != null, "no Exam-style toggle on the practice screen")
	if toggle != null:
		check(not toggle.get_global_rect().intersects(controls.get_global_rect()),
				"Exam-style toggle %s under the speaker and gear %s"
				% [toggle.get_global_rect(), controls.get_global_rect()])
	frame.free()
	tree.root.size = window_size
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://test_audio_practice_save.json"))


func test_the_settings_screen_shows_every_level_and_location() -> void:
	var audio := _audio()
	if audio == null:
		return
	audio.sound_enabled = false
	audio.music_volume = 0.4
	var panel := (load(SETTINGS_SCENE) as PackedScene).instantiate()
	tree.root.add_child(panel)
	await tree.process_frame
	check_eq(panel.visible, false, "the settings screen must start closed")
	panel.open()
	await tree.process_frame
	check_eq(panel.visible, true, "open() did not show the settings screen")
	var picker := panel.get_node("Center/Panel/Pad/Column/LocationPicker") as OptionButton
	check_eq(picker.item_count, MusicTracks.CUES.size(), "locations in the picker")
	var checks := panel.get_node("Center/Panel/Pad/Column/CheckGrid") as GridContainer
	check_eq(checks.get_child_count(), SfxCues.CUES.size(), "buttons in the sound check")
	var music_value := panel.get_node("Center/Panel/Pad/Column/MusicRow/MusicValue") as Label
	check_eq(music_value.text, "40%", "the music level on screen")
	var hint := panel.get_node("Center/Panel/Pad/Column/Hint") as Label
	check_eq(hint.visible, true, "sound is off, so the screen should say so")
	panel.close()
	check_eq(panel.visible, false, "close() did not hide the settings screen")
	panel.queue_free()
	await tree.process_frame
	_restore(audio)
