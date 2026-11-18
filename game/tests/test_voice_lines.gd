extends "res://tests/test_case.gd"
## Lines said on screen play their recorded take (FAL-1134): Bodge in the bazaar and the
## bosses' taunts, each found by the SHA-1 of its text, on the Voice bus.

const VOICE := "res://tests/fixtures/voice/"
const DATA := "res://tests/fixtures/art-data/"
const ART := "res://tests/fixtures/art/"
const BAZAAR := "res://scenes/bazaar.tscn"
const FIGHT := "res://scenes/fight.tscn"
const SAVE := "user://test_voice_lines_save.json"
const SETTINGS_PATH := "user://settings.cfg"

var _settings := PackedByteArray()


## Fixture takes and data, with sound on; the player's settings file is put back after.
func _use_fixtures() -> void:
	_settings = FileAccess.get_file_as_bytes(SETTINGS_PATH)
	VoiceLines.root = VOICE
	ArtSlots.root = ART
	ArtSlots.data_dir = DATA
	ArtSlots.reset()
	Audio.sound_enabled = true
	Audio.voice_volume = 1.0
	Audio.stop_voice()
	Audio.last_voice = ""


func _restore() -> void:
	Audio.stop_voice()
	Audio.sound_enabled = false
	Audio.reset_settings()
	if not _settings.is_empty():
		var file := FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
		file.store_buffer(_settings)
		file.close()
	VoiceLines.root = VoiceLines.ROOT
	ArtSlots.root = "res://assets/"
	ArtSlots.data_dir = "res://data/"
	ArtSlots.reset()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE))


func test_a_take_is_named_by_the_sha1_of_its_text() -> void:
	# printf '%s' 'First visit A.' | sha1sum
	check_eq(VoiceLines.path("bodge", "First visit A."), VoiceLines.ROOT + "bodge/lines/e42a9ac0176e.ogg")
	check_eq(VoiceLines.path("quadratics-boss", "Ünïcode — and “quotes”."),
		VoiceLines.ROOT + "quadratics-boss/lines/%s.ogg" % "Ünïcode — and “quotes”.".sha1_text().left(12))


func test_a_line_with_a_take_plays_it() -> void:
	_use_fixtures()
	var played := VoiceLines.say("bodge", "Enter A.")
	check_eq(played, VOICE + "bodge/lines/%s.ogg" % "Enter A.".sha1_text().left(12))
	check_eq(Audio.last_voice, played)
	check(Audio.voice_playing(), "the take plays on the Voice bus")
	_restore()


func test_a_line_without_a_take_stays_text_only() -> void:
	_use_fixtures()
	check_eq(VoiceLines.say("bodge", "Enter B."), "")
	check_eq(Audio.last_voice, "", "nothing asked to play")
	check(not Audio.voice_playing())
	_restore()


func test_an_edited_line_does_not_play_the_old_take() -> void:
	_use_fixtures()
	check(VoiceLines.take("bodge", "Enter A.") != null, "the recorded line has its take")
	check_eq(VoiceLines.say("bodge", "Enter A!"), "", "one character changed, no take")
	check(not Audio.voice_playing())
	_restore()


func test_nothing_plays_with_the_voice_at_zero() -> void:
	_use_fixtures()
	Audio.voice_volume = 0.0
	VoiceLines.say("bodge", "Enter A.")
	check(not Audio.voice_playing(), "voice volume zero")
	_restore()


func test_a_new_line_stops_the_one_before() -> void:
	_use_fixtures()
	VoiceLines.say("bodge", "First visit A.")
	VoiceLines.say("bodge", "Enter A.")
	check_eq(Audio.last_voice, VoiceLines.path("bodge", "Enter A."))
	check(Audio.voice_playing())
	_restore()


func test_bodge_says_his_lines_in_the_bazaar() -> void:
	_use_fixtures()
	var frame := Control.new()
	frame.size = Vector2(1080, 2340)
	tree.root.add_child(frame)
	var b: Control = (load(BAZAAR) as PackedScene).instantiate()
	b.save_path = SAVE
	b.save = SaveData.blank()
	frame.add_child(b)
	await tree.process_frame
	# Both first-visit fixture lines have a take.
	check(b.line.text.begins_with("First visit"), b.line.text)
	check_eq(Audio.last_voice, VoiceLines.path("bodge", b.line.text), "the greeting plays its take")
	Audio.last_voice = ""
	check_eq(b.say("capped"), "Capped only.")
	check_eq(Audio.last_voice, "", "a line with no take is text only")
	frame.free()
	_restore()


func test_a_boss_taunt_plays_its_take() -> void:
	_use_fixtures()
	check_eq(ArtSlots.enemy("quadratics", "mini", 3, 7, 1, 5).speaker, "quadratics-miniboss")
	check_eq(ArtSlots.enemy("quadratics", "boss", 5, 7, 1, 10).speaker, "quadratics-boss")
	check_eq(ArtSlots.enemy("quadratics", "fight", 1, 7, 1, 2).speaker, "", "regular enemies don't taunt")
	var frame := Control.new()
	frame.size = Vector2(1080, 2340)
	tree.root.add_child(frame)
	var f: Control = (load(FIGHT) as PackedScene).instantiate()
	f.save_path = SAVE
	f.run_seed = 3
	f.select_first = false
	f.first_fight = 5
	frame.add_child(f)
	await tree.process_frame
	check_eq(f.run.kind, "mini")
	check(f.card.get_node_or_null("Taunt") != null, "the taunt shows")
	check_eq(Audio.last_voice, VOICE + "quadratics-miniboss/lines/%s.ogg" % "Fixture taunt.".sha1_text().left(12))
	frame.free()
	_restore()


func test_a_region_with_its_islands_taunt_speaks_as_the_island() -> void:
	var bosses: Dictionary = ArtSlots.data("bosses.json")
	var region := ""
	for r in QuestionEngine.catalogue().get("regions", []):
		var id := str(r.id)
		if not bosses.has(id) and bosses.has(MapLink.island_of(id)):
			region = id
			break
	if region == "":
		fail("no region borrows its island's bosses")
		return
	var island := MapLink.island_of(region)
	var e := ArtSlots.enemy(region, "boss", 5, 7, 1, 10)
	check_eq(e.taunt, str(bosses[island].boss.taunt))
	check_eq(e.speaker, island + "-boss", "the take is the island boss's, recorded once")
