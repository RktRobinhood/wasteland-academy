extends "res://tests/test_case.gd"
## Art slots (FAL-470): each slot loads its file when it's there and falls back cleanly
## when it isn't, on fixture art (tests/fixtures/art/, tiny images) and fixture data
## (tests/fixtures/art-data/). A region with no art plays exactly as before. The art
## folders import lossy with mipmaps, so the web download stays small.

const ART := "res://tests/fixtures/art/"
const DATA := "res://tests/fixtures/art-data/"
## Neither folder exists: no art and no data.
const NONE := "res://tests/fixtures/no-art/"
const FIGHT := "res://scenes/fight.tscn"
const BAZAAR := "res://scenes/bazaar.tscn"
const MAIN := "res://scenes/main.tscn"
const SAVE := "user://test_art_save.json"
## The folders the art slots read, as game/README.md ("Art slots") lists them.
const SLOT_DIRS := ["title", "regions", "enemies", "bazaar", "ui/run"]
## The Functions regions (FAL-274 plan), each with a named mini-boss and boss.
const REGIONS := ["quadratics", "exp-log", "graphs-features", "composite-inverse", "rational",
	"function-basics", "lines", "transformations"]


func _use(root: String, data_dir: String) -> void:
	ArtSlots.root = root
	ArtSlots.data_dir = data_dir
	ArtSlots.reset()


func _restore() -> void:
	_use("res://assets/", "res://data/")


func _area(window: Vector2i) -> Vector2:
	var scale := minf(window.x / 1080.0, window.y / 1920.0)
	return Vector2(window) / scale


func _path(t: Texture2D) -> String:
	return t.resource_path if t != null else ""


# ── Slots ────────────────────────────────────────────────────

func test_each_slot_loads_its_file_or_nothing() -> void:
	_use(ART, DATA)
	check_eq(ArtSlots.find("regions/quadratics/boss"), ART + "regions/quadratics/boss.png")
	check_eq(ArtSlots.find("regions/quadratics/boss-hurt"), "", "no file, no path")
	check_eq(ArtSlots.find("regions/exp-log/boss"), "", "another region")
	check_eq(_path(ArtSlots.backdrop("quadratics")), ART + "regions/quadratics/backdrop.png")
	check(ArtSlots.backdrop("lines") == null, "no backdrop")
	check_eq(_path(ArtSlots.texture("title/key-art")), ART + "title/key-art.webp", "WebP as well as PNG")
	check(ArtSlots.texture("title/key-art-phone") == null)
	check_eq(_path(ArtSlots.medal(1)), ART + "ui/run/medal-floor-1.png")
	check(ArtSlots.medal(2) == null, "no medal for floor 2")
	check_eq(_path(ArtSlots.medal(9)), ART + "ui/run/medal-floor-4.png", "floor 4 and deeper share a medal")
	check(ArtSlots.medal(0) == null, "no floor, no medal")
	check_eq(_path(ArtSlots.bazaar_icon("scrap")), ART + "bazaar/scrap.png")
	check_eq(_path(ArtSlots.bazaar_icon("max_hp")), ART + "bazaar/upgrade-max-hp.png")
	check_eq(_path(ArtSlots.bazaar_icon("field_manual")), ART + "bazaar/perk-field-manual.png")
	check(ArtSlots.bazaar_icon("lifeline") == null and ArtSlots.bazaar_icon("second_wind") == null)
	_use(NONE, NONE)
	for slot in ["regions/quadratics/backdrop", "title/key-art", "bazaar/scrap", "ui/run/banner-run-over"]:
		check_eq(ArtSlots.find(slot), "", slot)
	check_eq(ArtSlots.data("bosses.json"), {}, "no data file")
	check_eq(ArtSlots.data("enemies.json"), [])
	_restore()


func test_bosses_take_their_region_art_name_and_taunt() -> void:
	_use(ART, DATA)
	var mini := ArtSlots.enemy("quadratics", "mini", 3, 7, 1, 5)
	check_eq(mini.name, "Fixture Gunner")
	check_eq(mini.taunt, "Fixture taunt.")
	check_eq(mini.art, ART + "regions/quadratics/miniboss.png")
	check_eq(mini.hurt, ART + "regions/quadratics/miniboss-hurt.png")
	check(mini.named)
	var boss := ArtSlots.enemy("quadratics", "boss", 5, 7, 1, 10)
	check_eq(boss.art, ART + "regions/quadratics/boss.png")
	check_eq(boss.hurt, "", "no hurt frame, no flash")
	# A region with no entry and no art: the tier, as before.
	var other := ArtSlots.enemy("exp-log", "boss", 5, 7, 1, 10)
	check_eq(other.name, Tuning.ENEMIES[5].name)
	check_eq(other.art, "res://assets/enemies/" + Tuning.ENEMIES[5].art)
	check(not other.named and other.taunt == "" and other.hurt == "")
	_restore()


func test_regular_fights_draw_from_the_pool() -> void:
	_use(ART, DATA)
	var seen := {}
	for s in range(1, 60):
		var e := ArtSlots.enemy("quadratics", "fight", 1, s, 1, 2)
		seen[e.name] = e.art
		check_eq(ArtSlots.enemy("quadratics", "fight", 1, s, 1, 2), e, "the same seed, the same enemy")
		check(e.taunt == "", "regular enemies don't taunt")
	check_eq(seen.keys().size(), 2, "both pool enemies with art: %s" % [seen.keys()])
	check_eq(seen.get("Dust Runner", ""), ART + "enemies/dust-runner.png")
	check(not seen.has("Ghost"), "a pool enemy with no art is left out")
	check_eq(ArtSlots.enemy("quadratics", "fight", 1, 4, 1, 2).hurt in ["", ART + "enemies/dust-runner-hurt.png"], true)
	# Tier 2's only pool enemy has no art: the tier's own enemy, as before.
	var t2 := ArtSlots.enemy("quadratics", "fight", 2, 1, 1, 2)
	check_eq(t2.name, Tuning.ENEMIES[2].name)
	check_eq(t2.art, "res://assets/enemies/" + Tuning.ENEMIES[2].art)
	_restore()


func test_the_shipped_pool_is_the_five_tier_enemies() -> void:
	_restore()
	for tier in Tuning.ENEMIES:
		for s in range(1, 20):
			var e := ArtSlots.enemy("quadratics", "fight", tier, s, 1, 3)
			check_eq(e.name, Tuning.ENEMIES[tier].name)
			check_eq(e.art, "res://assets/enemies/" + Tuning.ENEMIES[tier].art)
	var named := ArtSlots.data("bosses.json") as Dictionary
	for region in REGIONS:
		check(named.has(region), "%s has boss names" % region)
	for region in named:
		for slot in ["miniboss", "boss"]:
			check(str(named[region][slot].get("name", "")) != "" and str(named[region][slot].get("taunt", "")) != "",
				"%s %s has a name and a taunt" % [region, slot])


# ── A region with no art ─────────────────────────────────────

## Plays a run with every answer right, then wrong ones to the end, and lists who each
## fight was against.
func _fights(seed_no: int) -> Array:
	var r := Run.new(SaveData.blank(), "quadratics", 1, seed_no)
	r.clock = func() -> int: return 1_800_000_000
	var out := []
	r.question_opened.connect(func(_f, _t): out.append([r.fight, r.kind, r.enemy.duplicate(), r.tier]))
	r.start()
	var i := 0
	while r.state != "ended" and i < 80:
		r.answer(preload("res://tests/test_combat.gd").respond(r.question, i < 40))
		r.next()
		i += 1
	r.quit()
	return [out, r.answers, r.summary, JSON.stringify(r.save)]


func test_a_region_with_no_art_plays_as_before() -> void:
	_use(NONE, NONE)
	var plain := _fights(11)
	check(plain[0].size() > 12, "the run reaches the mini-boss and the boss")
	var bosses := 0
	for f in plain[0]:
		var e: Dictionary = f[2]
		var tier: Dictionary = Tuning.ENEMIES[f[3]]
		check_eq(e.art, "res://assets/enemies/" + tier.art, "the tier's art")
		check_eq(e.hurt, "", "no hurt frame")
		check_eq(e.taunt, "", "no taunt")
		if f[1] == "fight":
			check_eq(e.name, tier.name)
		else:
			bosses += 1
			check(e.name.begins_with("Mini-boss " if f[1] == "mini" else "Boss "), e.name)
	check(bosses > 0, "a boss was played")
	# Art changes looks only: the same seed with art plays the same questions and results.
	_use(ART, DATA)
	var art := _fights(11)
	check_eq(art[1], plain[1], "the same answers and outcomes")
	check_eq(art[2], plain[2], "the same summary")
	check_eq(art[3], plain[3], "the same save")
	check(art[0].any(func(f): return f[2].name == "Fixture Gunner"), "the art run met the fixture mini-boss")
	_restore()


# ── The screens ──────────────────────────────────────────────

func _fight(fight_no: int, seed_no: int = 3) -> Array:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE))
	var frame := Control.new()
	frame.size = _area(Vector2i(390, 844))
	tree.root.add_child(frame)
	var f: Control = (load(FIGHT) as PackedScene).instantiate()
	f.save_path = SAVE
	f.run_seed = seed_no
	f.select_first = false
	f.first_fight = fight_no
	frame.add_child(f)
	await tree.process_frame
	return [frame, f]


func _done(made: Array) -> void:
	made[0].free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE))


func test_the_fight_screen_with_art() -> void:
	_use(ART, DATA)
	var made: Array = await _fight(5)
	var f: Control = made[1]
	check(f.backdrop.visible and _path(f.backdrop.texture) == ART + "regions/quadratics/backdrop.png", "the region's backdrop")
	check_eq(f.run.kind, "mini")
	check_eq(_path(f.enemy_art.texture), ART + "regions/quadratics/miniboss.png")
	check(f.enemy_name.text.begins_with("Fixture Gunner"), f.enemy_name.text)
	var taunt: Label = f.card.get_node_or_null("Taunt")
	check(taunt != null and taunt.text.contains("Fixture taunt."), "the taunt on the card")
	f.autoplay(true)
	check_eq(_path(f.enemy_art.texture), ART + "regions/quadratics/miniboss-hurt.png", "a hit flashes the hurt frame")
	await tree.create_timer(f.HURT_FLASH + 0.05).timeout
	check_eq(_path(f.enemy_art.texture), ART + "regions/quadratics/miniboss.png", "and back")
	var guard := 0
	while f.run.kind == "mini" and not f.result.get("defeated", false) and guard < 10:
		f.next_question()
		f.autoplay(true)
		guard += 1
	check(f.result.get("defeated", false), "the mini-boss falls")
	var banner: Control = f.card.get_node_or_null("Banner")
	check(banner != null and (banner.get_node("Text") as Label).text == "Mini-boss beaten", "the boss-beaten banner")
	f.next_question()
	check(f.card.get_node_or_null("Taunt") == null, "a regular fight has no taunt")
	f.lose()
	var head = f.summary_box.find_child("Heading", true, false)
	check(head is Label and head.get_parent().name == "Banner", "the run-over banner carries the heading")
	_done(made)
	_restore()


func test_the_fight_screen_with_no_art() -> void:
	_use(NONE, NONE)
	var made: Array = await _fight(5)
	var f: Control = made[1]
	check(not f.backdrop.visible, "no backdrop")
	check_eq(_path(f.enemy_art.texture), "res://assets/enemies/" + Tuning.ENEMIES[f.run.tier].art)
	check(f.card.get_node_or_null("Taunt") == null, "no taunt")
	f.autoplay(true)
	check_eq(_path(f.enemy_art.texture), "res://assets/enemies/" + Tuning.ENEMIES[f.run.tier].art, "no hurt frame")
	check(f.card.get_node_or_null("Banner") == null)
	f.lose()
	check(f.summary_box.get_node_or_null("Heading") is Label, "the text-only heading")
	check(f.summary_box.find_child("Medal", true, false) == null)
	_done(made)
	_restore()


func test_the_floor_cleared_banner_and_medal() -> void:
	_use(ART, DATA)
	var made: Array = await _fight(10)
	var f: Control = made[1]
	check_eq(_path(f.enemy_art.texture), ART + "regions/quadratics/boss.png")
	var guard := 0
	f.autoplay(true)
	check_eq(_path(f.enemy_art.texture), ART + "regions/quadratics/boss.png", "no boss-hurt file: no flash")
	while not f.result.get("defeated", false) and guard < 10:
		f.next_question()
		f.autoplay(true)
		guard += 1
	check(f.result.get("floor_cleared", false), "floor 1 cleared")
	var banner: Control = f.card.get_node_or_null("Banner")
	check(banner != null and (banner.get_node("Text") as Label).text == "Floor 1 cleared", "the floor-cleared banner")
	_done(made)
	# A save whose best floor is 1 shows floor 1's medal on the floor select.
	var save := SaveData.blank()
	save.dungeon = {"quadratics": {"best": 1, "beaten": []}}
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE))
	SaveData.store(save, SAVE)
	var frame := Control.new()
	frame.size = _area(Vector2i(390, 844))
	tree.root.add_child(frame)
	var s: Control = (load(FIGHT) as PackedScene).instantiate()
	s.save_path = SAVE
	frame.add_child(s)
	await tree.process_frame
	var medal = s.floor_box.find_child("Medal", true, false)
	check(medal is TextureRect and _path(medal.texture) == ART + "ui/run/medal-floor-1.png", "the best-floor medal")
	_done([frame])
	_restore()


func _main(window: Vector2i) -> Array:
	var frame := Control.new()
	frame.size = _area(window)
	tree.root.add_child(frame)
	var main := (load(MAIN) as PackedScene).instantiate() as Control
	frame.add_child(main)
	for i in 3:
		await tree.process_frame
	return [frame, main]


func test_the_title_screen_key_art() -> void:
	_use(ART, DATA)
	var made: Array = await _main(Vector2i(1280, 800))
	var main: Control = made[1]
	check(main.key_art.visible and _path(main.key_art.texture) == ART + "title/key-art.webp", "landscape key art on a PC")
	check(not main.get_node("Center/Column/Spark").visible, "Spark is in the art")
	var column := main.get_node("Center/Column") as Control
	check(Rect2(Vector2.ZERO, _area(Vector2i(1280, 800))).encloses(column.get_global_rect()), "the column fits")
	made[0].free()
	# No phone version: the phone keeps the look from before.
	made = await _main(Vector2i(390, 844))
	main = made[1]
	check(not main.key_art.visible, "no portrait art")
	check(main.get_node("Center/Column/Spark").visible)
	made[0].free()
	_restore()


func _bazaar() -> Array:
	var frame := Control.new()
	frame.size = _area(Vector2i(390, 844))
	tree.root.add_child(frame)
	var b: Control = (load(BAZAAR) as PackedScene).instantiate()
	b.save_path = ""
	var save := SaveData.blank()
	save.scrap = 5000
	b.save = save
	frame.add_child(b)
	await tree.process_frame
	return [frame, b]


func test_the_bazaar_with_art() -> void:
	_use(ART, DATA)
	var made: Array = await _bazaar()
	var b: Control = made[1]
	var stall: TextureRect = b.get_node("Backdrop")
	check(stall.visible and _path(stall.texture) == ART + "bazaar/stall.png", "the stall")
	check(b.shopkeeper != null and _path(b.shopkeeper.texture) == ART + "bazaar/shopkeeper.png", "the shopkeeper")
	b._process(b.IDLE_EVERY - b.IDLE_FOR / 2.0)
	check_eq(_path(b.shopkeeper.texture), ART + "bazaar/shopkeeper-idle.png", "the idle frame now and then")
	b._process(b.IDLE_FOR)
	check_eq(_path(b.shopkeeper.texture), ART + "bazaar/shopkeeper.png")
	check(b.bank.get_parent().name == "BankRow", "the Scrap icon by the Scrap count")
	var icons := b.find_children("Icon", "TextureRect", true, false).map(func(n): return _path(n.texture))
	check(ART + "bazaar/upgrade-max-hp.png" in icons, "Max HP's icon")
	check(ART + "bazaar/perk-field-manual.png" in icons, "Field Manual's icon")
	check_eq(Bazaar.frames().keys(), ["rivet"], "frames from the data file, with art")
	check(b.buttons.has("frame:rivet"), "a new frame is on sale")
	made[0].free()
	_restore()


func test_the_bazaar_with_no_art() -> void:
	_use(NONE, "res://data/")
	var made: Array = await _bazaar()
	var b: Control = made[1]
	check(not b.get_node("Backdrop").visible, "no stall")
	check(b.shopkeeper == null, "no shopkeeper")
	check(b.bank.get_parent().name == "Column", "the Scrap count as before")
	check(b.find_children("Icon", "TextureRect", true, false).is_empty(), "no icons")
	check(Bazaar.frames().is_empty(), "frames whose art isn't there are left out")
	made[0].free()
	_restore()
	check_eq(Bazaar.frames().keys(), ["field_note", "signal", "brass"], "the shipped frames")


# ── Download size ────────────────────────────────────────────

func _images(dir: String, out: Array) -> void:
	var d := DirAccess.open(dir)
	if d == null:
		return
	for f in d.get_files():
		if f.get_extension() in ArtSlots.EXTENSIONS:
			out.append(dir.path_join(f))
	for sub in d.get_directories():
		_images(dir.path_join(sub), out)


func test_art_imports_lossy_with_mipmaps() -> void:
	var defaults: Dictionary = ProjectSettings.get_setting("importer_defaults/texture", {})
	check_eq(int(defaults.get("compress/mode", 0)), 1, "new art imports lossy (project.godot [importer_defaults])")
	check_eq(defaults.get("mipmaps/generate", false), true, "with mipmaps")
	var found := []
	for dir in SLOT_DIRS:
		_images("res://assets/" + dir, found)
	for path in found:
		# The share card is a file beside the web page, not in the game.
		if path.get_file().begins_with("share-card."):
			continue
		var cfg := ConfigFile.new()
		if cfg.load(path + ".import") != OK:
			fail("%s has no .import file" % path)
			continue
		check_eq(int(cfg.get_value("params", "compress/mode", 0)), 1,
			"%s: set compress/mode=1 (lossy) in its .import" % path)
		check_eq(cfg.get_value("params", "mipmaps/generate", false), true,
			"%s: set mipmaps/generate=true in its .import" % path)
