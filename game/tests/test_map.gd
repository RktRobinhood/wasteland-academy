extends "res://tests/test_case.gd"
## The map (FAL-417): links for every region, the island and junk; coverage, accuracy
## and the weakest skills against hand counts on scripted saves; the world map, the
## Functions island and the region screen, "coming soon" for a region with nothing
## built, the music each screen asks for, and the fit on a phone and a PC window.

const MAP := "res://scenes/map.tscn"
const FIGHT := "res://scenes/fight.tscn"
const MAIN := "res://scenes/main.tscn"
const SAVE := "user://test_map_save.json"
const CATALOGUE := "res://data/catalogue.json"


func _area(window: Vector2i) -> Vector2:
	var base := Vector2(1080, 1920)
	var scale := minf(window.x / base.x, window.y / base.y)
	return Vector2(window) / scale


func _map(route: Dictionary, save: Dictionary = {}, area := Vector2(1080, 1920)) -> Array:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE))
	if not save.is_empty():
		SaveData.store(save, SAVE)
	MapLink.current = route
	var frame := Control.new()
	frame.size = area
	tree.root.add_child(frame)
	var m: Control = (load(MAP) as PackedScene).instantiate()
	m.save_path = SAVE
	frame.add_child(m)
	for i in 3:
		await tree.process_frame
	return [frame, m]


func _done(made: Array) -> void:
	made[0].free()
	MapLink.current = {}
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE))


## A region with no built type, or "" once every region is built.
func _unbuilt_region() -> String:
	for id in MapLink.region_ids():
		if Dungeon.region_types(id).is_empty():
			return id
	return ""


# ── Links ────────────────────────────────────────────────────

func test_every_region_has_a_link() -> void:
	var ids := MapLink.region_ids()
	check_eq(ids, ["quadratics", "exp-log", "graphs-features", "composite-inverse", "rational",
		"function-basics", "lines", "transformations"], "the plan's 8 regions in order")
	var raw: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(CATALOGUE))
	check_eq(ids.size(), (raw.regions as Array).size(), "every catalogue region")
	for id in ids + ["all"]:
		var want := {"screen": "region", "island": "functions", "region": id}
		check_eq(MapLink.parse("#functions/" + id), want, id)
		check_eq(MapLink.parse("functions/%s/" % id), want, id + " without # and with a slash")
		check_eq(MapLink.to_hash(want), "#functions/" + id, id + " back to a link")


func test_the_island_and_world_links() -> void:
	check_eq(MapLink.parse("#functions"), {"screen": "island", "island": "functions"})
	check_eq(MapLink.parse("#Functions/"), {"screen": "island", "island": "functions"}, "case and a slash")
	check_eq(MapLink.to_hash({"screen": "island", "island": "functions"}), "#functions")
	check_eq(MapLink.parse("#world"), {"screen": "world"})
	check_eq(MapLink.to_hash({"screen": "world"}), "#world")


func test_junk_falls_back_to_the_world_map() -> void:
	for junk in ["", "#", "#/", "#nowhere", "#functions/nowhere", "#functions/quadratics/extra", "#calculus",
			"#calculus/quadratics", "#../functions", "#functions//", "%20%20", "#?play=all", "#functions/QUADRATICS!"]:
		check_eq(MapLink.parse(junk), {"screen": "world"}, "'%s'" % junk)


# ── Progress ─────────────────────────────────────────────────

## The region's cells counted straight from the catalogue file, apart from the engine:
## every unknown × representation × distinct method of every type in the region.
func _hand_count(region: String, exam_only: bool) -> int:
	var raw: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(CATALOGUE))
	var n := 0
	for t in raw.types:
		if t.get("region") != region:
			continue
		if exam_only and t.source != "exam":
			continue
		var exam_reps := {}
		for r in t.representations:
			exam_reps[r.rep] = r.exam
		for u in t.unknowns:
			if exam_only and not u.exam:
				continue
			var methods := {}
			for a in t.get("angles", []):
				if u.id in a.suits:
					methods[a.method] = true
			for rep in u.reps:
				if exam_only and not exam_reps.get(rep, false):
					continue
				n += maxi(1, methods.size())
	return n


func test_coverage_matches_a_hand_count_with_the_switch_off_and_on() -> void:
	var all := Progress.catalogue_cells("quadratics", false)
	var exam := all.filter(func(c): return c.exam)
	var ext := all.filter(func(c): return not c.exam)
	var unbuilt := _unbuilt_region()
	var other: Dictionary = Progress.catalogue_cells("all", false).filter(func(c):
		var r = QuestionEngine.type_of(c.type).get("region")
		return r != "quadratics" and r != unbuilt)[0]
	var save := SaveData.blank()
	# Two exam cells, one extension cell, a cell of another region, one asked but never
	# answered and a key that isn't a cell: 3 checked, 2 with the switch on.
	for c in [exam[0], exam[5], ext[0]]:
		SaveData.record(save, c.key, true, 100)
	SaveData.record(save, other.key, false, 100)
	save.cells[exam[1].key] = {"seen": 0, "right": 0, "wrong": 0}
	save.cells["fn-nothing|x|y|z"] = {"seen": 4, "right": 4, "wrong": 0}
	var off := Progress.coverage(save, "quadratics")
	check_eq(off, {"checked": 3, "total": _hand_count("quadratics", false)}, "switch off")
	save.settings.exam_only = true
	var on := Progress.coverage(save, "quadratics")
	check_eq(on, {"checked": 2, "total": _hand_count("quadratics", true)}, "switch on")
	check(on.total < off.total, "the switch drops the extension cells")
	# A region with nothing built still counts its catalogue cells.
	if unbuilt != "":
		save.settings.exam_only = false
		check_eq(Progress.coverage(save, unbuilt), {"checked": 0, "total": _hand_count(unbuilt, false)}, unbuilt)
	# The island: every region's cells.
	var island := 0
	for id in MapLink.region_ids():
		island += _hand_count(id, false)
	check_eq(Progress.coverage(save, "all").total, island, "the all-regions total")


func test_accuracy_and_best_floor() -> void:
	var cells := Progress.catalogue_cells("quadratics", false)
	var save := SaveData.blank()
	check_eq(Progress.accuracy(save, "quadratics"), {"right": 0, "seen": 0, "percent": -1}, "nothing answered")
	for i in 3:
		SaveData.record(save, cells[0].key, true, 100 + i)
	SaveData.record(save, cells[1].key, false, 200)
	check_eq(Progress.accuracy(save, "quadratics"), {"right": 3, "seen": 4, "percent": 75})
	check_eq(Progress.best_floor(save, "quadratics"), 0)
	Dungeon.note_floor(save, "quadratics", 2, true)
	Dungeon.note_floor(save, "quadratics", 3, false)
	check_eq(Progress.best_floor(save, "quadratics"), 3)
	check(not Progress.is_cleared(save, "quadratics"), "floor 3's boss still stands")
	Dungeon.note_floor(save, "quadratics", 3, true)
	check(Progress.is_cleared(save, "quadratics"), "cleared once floor 3's boss falls")


## Quadratics cells whose unknown lists exactly one skill, each skill once.
func _one_skill_cells(n: int) -> Array:
	var out: Array = []
	var used := {}
	for c in Progress.catalogue_cells("quadratics", false):
		var skills: Array = QuestionEngine.unknown_of(QuestionEngine.type_of(c.type), c.unknown).get("skills", [])
		if skills.size() == 1 and not used.has(skills[0]):
			used[skills[0]] = true
			out.append({"cell": c, "skill": skills[0]})
		if out.size() == n:
			break
	return out


func test_the_weakest_skills_ignore_skills_with_fewer_than_3_answers() -> void:
	var picks := _one_skill_cells(5)
	check_eq(picks.size(), 5, "five quadratics skills to script")
	var save := SaveData.blank()
	# [right, wrong]: 0% on 2 answers (too few), 33% on 3, 75% on 4, 50% on 10, 100% on 5.
	var answers := [[0, 2], [1, 2], [3, 1], [5, 5], [5, 0]]
	for i in picks.size():
		for r in answers[i][0]:
			SaveData.record(save, picks[i].cell.key, true, 100)
		for w in answers[i][1]:
			SaveData.record(save, picks[i].cell.key, false, 100)
	var weak := Progress.weakest_skills(save, "quadratics")
	check_eq(weak.map(func(w): return w.id), [picks[1].skill, picks[3].skill, picks[2].skill], "weakest first, 2-answer skill left out")
	check_eq(weak.map(func(w): return w.percent), [33, 50, 75])
	check_eq(weak[0].seen, 3)
	check(weak[0].name != weak[0].id, "a skill shows its name: " + weak[0].name)
	check_eq(Progress.skill_stats(save, "quadratics")[picks[0].skill], {"right": 0, "seen": 2}, "still counted, just not flagged")


# ── Screens ──────────────────────────────────────────────────

func test_the_world_map() -> void:
	var made: Array = await _map({"screen": "world"})
	var m: Control = made[1]
	check_eq(m.screen, "world")
	check(m.world.visible and not m.island.visible and not m.region_view.visible, "only the world shows")
	var board: Control = m.world_board
	var fn := board.get_node("Island_functions") as Button
	check(not fn.disabled, "the Signal Tower is open")
	for id in ["algebra", "geometry", "stats", "calculus"]:
		var b := board.get_node("Island_" + id) as Button
		check(b.disabled, id + " is closed")
		check_eq((b.get_node("Label/State") as Label).text, "Coming later", id)
	check((board.get_node("Thunderdome") as Button).disabled, "the Thunderdome waits for a second island")
	check((board.get_node("RelicLibrary") as Button).disabled, "the Relic Library spot is locked")
	check_eq(Audio.location(), "overworld", "the overworld loop")
	_done(made)


func test_the_functions_island() -> void:
	var save := SaveData.blank()
	SaveData.record(save, Progress.catalogue_cells("quadratics", false)[0].key, true, 100)
	Dungeon.note_floor(save, "quadratics", 2, false)
	var made: Array = await _map({"screen": "island", "island": "functions"}, save)
	var m: Control = made[1]
	check_eq(m.screen, "island")
	var board: Control = m.island_board
	var spots: Array = []
	for c in board.get_children():
		if c.name.begins_with("Spot_"):
			spots.append(String(c.name).trim_prefix("Spot_"))
	check_eq(spots, MapLink.region_ids() + ["all", "relic"], "8 regions in order, the all-regions dungeon, the Relic device")
	check((board.get_node("Spot_relic") as Button).disabled, "the Relic device is locked")
	check_eq((board.get_node("Spot_quadratics/Box/State") as Label).text, "Floor 2 · 100%")
	for id in MapLink.region_ids():
		var line := (board.get_node("Spot_%s/Box/State" % id) as Label).text
		check_eq(line == "Coming soon", not Progress.is_built(id), "%s: %s" % [id, line])
		check_eq(m.spot_state(id) == "locked", not Progress.is_built(id), id)
	# No island art yet: the coded ground and coded landmarks.
	check(board.get_node_or_null("Ground") != null, "the coded ground")
	check(board.get_node_or_null("Spot_quadratics/Box/Landmark/Coded") != null, "the coded landmark")
	check_eq(Audio.location(), "signal-tower", "the island's loop")
	_done(made)


func test_a_region_screen_shows_progress_and_its_start_buttons() -> void:
	var save := SaveData.blank()
	var cells := Progress.catalogue_cells("quadratics", false)
	SaveData.record(save, cells[0].key, true, 100)
	SaveData.record(save, cells[1].key, false, 100)
	Dungeon.note_floor(save, "quadratics", 1, true)
	Dungeon.note_floor(save, "quadratics", 2, true)
	var made: Array = await _map(MapLink.parse("#functions/quadratics"), save)
	var m: Control = made[1]
	check_eq(m.screen, "region")
	var col: Control = m.region_col
	check_eq((col.get_node("Head/Title") as Label).text, "Quadratics")
	check(col.get_node_or_null("ComingSoon") == null, "Quadratics is built")
	check_eq((col.get_node("Stats/Rows/Accuracy") as Label).text, "Accuracy: 50% · 1 of 2 right")
	check_eq((col.get_node("Stats/Rows/BestFloor") as Label).text, "Best floor: 2")
	check_eq((col.get_node("Stats/Rows/Coverage") as Label).text,
		"Coverage: 2 of %d checked" % _hand_count("quadratics", false))
	var start: Control = col.get_node("Start")
	check_eq(start.get_children().map(func(b): return String(b.name)), ["Floor1", "Floor2", "Floor3", "Practice"])
	# The switch changes the count and is saved.
	(col.get_node("ExamOnly") as Button).button_pressed = true
	await tree.process_frame
	check_eq((m.region_col.get_node("Stats/Rows/Coverage") as Label).text,
		"Coverage: %d of %d checked" % [Progress.coverage(m.save, "quadratics").checked, _hand_count("quadratics", true)])
	check_eq(SaveData.load_from(SAVE).settings.exam_only, true, "the switch is saved")
	_done(made)


func test_a_region_with_nothing_built_shows_coming_soon_and_cannot_start() -> void:
	var id := _unbuilt_region()
	if id == "":
		return  # Every region is built: nothing left to be "coming soon".
	var made: Array = await _map(MapLink.region_route(id))
	var m: Control = made[1]
	check(m.region_col.get_node_or_null("ComingSoon") != null, "says coming soon")
	check(m.region_col.get_node_or_null("Start") == null, "no start buttons")
	check(not m.can_start(id), "can_start")
	check_eq(m.start_run(id, 1), false, "start_run refuses")
	check_eq(m.open_practice(id), false, "Practice refuses")
	check(preload("res://ui/fight.gd").launch.is_empty(), "no run was queued")
	_done(made)


func test_the_fight_screen_starts_the_run_the_map_asked_for() -> void:
	var fight_script := preload("res://ui/fight.gd")
	var save := SaveData.blank()
	Dungeon.note_floor(save, "quadratics", 1, true)
	SaveData.store(save, SAVE)
	for ask in [[2, 2], [5, 1]]:
		fight_script.launch = {"region": "quadratics", "floor": ask[0]}
		var frame := Control.new()
		frame.size = Vector2(1080, 1920)
		tree.root.add_child(frame)
		var f: Control = (load(FIGHT) as PackedScene).instantiate()
		f.save_path = SAVE
		frame.add_child(f)
		await tree.process_frame
		check(f.run != null, "a run started")
		check_eq(f.run.region, "quadratics")
		check_eq(f.run.start_floor, ask[1], "floor %d asked" % ask[0])
		check(fight_script.launch.is_empty(), "launch is read once")
		check_eq(Audio.location(), "signal-tower", "the island's loop in a run")
		frame.free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE))


func test_a_boss_plays_the_boss_loop() -> void:
	var frame := Control.new()
	frame.size = Vector2(1080, 1920)
	tree.root.add_child(frame)
	var f: Control = (load(FIGHT) as PackedScene).instantiate()
	f.save_path = SAVE
	f.select_first = false
	f.run_seed = 3
	f.first_fight = Tuning.FIGHTS_PER_FLOOR
	frame.add_child(f)
	await tree.process_frame
	check_eq(f.run.kind, "boss")
	check_eq(Audio.location(), "signal-tower-boss")
	frame.free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE))


func test_play_on_the_title_opens_the_map() -> void:
	var main := (load(MAIN) as PackedScene).instantiate()
	tree.root.add_child(main)
	var play := main.get_node("Center/Column/Buttons/Play") as Button
	check(play.pressed.is_connected(main.open_map), "Play opens the map")
	main.free()


func test_every_screen_fits_a_phone_and_a_pc_window() -> void:
	var save := SaveData.blank()
	for c in Progress.catalogue_cells("quadratics", false).slice(0, 12):
		for i in 3:
			SaveData.record(save, c.key, i != 1, 100)
	Dungeon.note_floor(save, "quadratics", 1, true)
	for window in [Vector2i(390, 844), Vector2i(1280, 800)]:
		var area := _area(window)
		var screen := Rect2(Vector2.ZERO, area)
		for r in [{"screen": "world"}, {"screen": "island", "island": "functions"}, MapLink.region_route("quadratics")]:
			var made: Array = await _map(r, save, area)
			var m: Control = made[1]
			var what := "%s %s" % [window, r.screen]
			if r.screen == "region":
				for c in m.region_col.get_children():
					check(screen.encloses((c as Control).get_global_rect()), "%s: %s outside" % [what, c.name])
				for l in m.region_col.find_children("*", "Label", true, false):
					check((l as Label).get_visible_line_count() == (l as Label).get_line_count(), "%s: %s clips" % [what, l.name])
			else:
				var board: Control = m.world_board if r.screen == "world" else m.island_board
				check(screen.encloses(board.get_global_rect()), "%s: board %s outside %s" % [what, board.get_global_rect(), screen])
				for b in board.get_children():
					if b is Button:
						check(screen.encloses((b as Control).get_global_rect()), "%s: %s outside" % [what, b.name])
				var head: Control = (m.world if r.screen == "world" else m.island).get_node("Header")
				check(head.get_global_rect().end.y <= board.get_global_rect().position.y + 1.0, "%s: the header overlaps the board" % what)
			_done(made)
