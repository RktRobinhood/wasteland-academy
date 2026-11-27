extends "res://tests/test_case.gd"
## The map (FAL-417): links for every region, the island and junk; coverage, accuracy
## and the weakest skills against hand counts on scripted saves; the world map, the
## Functions island and the region screen, "coming soon" for a region with nothing
## built, the music each screen asks for, the fit on a phone and a PC window, and the
## world map opening the Bazaar (FAL-416) from its place and leaving it going back there.
## The island as a hub (FAL-533): the plan's spots with no buttons overlapping, glyphs in
## place of numbers, and SPARK's pick (Progress.suggest()). The FAL-783 layers (FAL-790):
## no roads and no footer, names only on a card shown by hover, focus or a tap (two taps
## on touch), painted places on a fixture background, the zoom between layers and the
## region screen over its backdrop. Every island open (FAL-925): each region routes on its
## own island, island_of() for every region, each island's spots laid out with no overlap,
## the Thunderdome's screen and the Relic Library's card.
## The world map as a fast-travel map (FAL-988): zones from the painting with none
## overlapping, a pin and a revealable name per place, the pin states and the
## "you are here" marker.

const MAP := "res://scenes/map.tscn"
const FIGHT := "res://scenes/fight.tscn"
const MAIN := "res://scenes/main.tscn"
const BAZAAR := "res://scenes/bazaar.tscn"
const SAVE := "user://test_map_save.json"
const CATALOGUE := "res://data/catalogue.json"
## An island art folder with nothing in it: the coded look.
const NO_ART := "res://tests/fixtures/no-art/map/"
## The zones with a painting in assets/map/<island>/: the Signal Tower (FAL-1614), the
## Dry Flats (FAL-1034), the Radio Spires (FAL-1611), the Engine Core (FAL-1612) and the
## Scrap Fields (FAL-1613).
const PAINTED := ["functions", "geometry", "stats", "calculus", "algebra"]


func _area(window: Vector2i) -> Vector2:
	var base := Vector2(1080, 1920)
	var scale := minf(window.x / base.x, window.y / base.y)
	return Vector2(window) / scale


func _map(route: Dictionary, save: Dictionary = {}, area := Vector2(1080, 1920), art_dir := "") -> Array:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE))
	# A student who has picked their course: a blank save is asked first (test_first_run.gd).
	save = save if not save.is_empty() else SaveData.blank()
	save.intro = {"course": true, "cards": true}
	SaveData.store(save, SAVE)
	MapLink.current = route
	var frame := Control.new()
	frame.size = area
	tree.root.add_child(frame)
	var m: Control = (load(MAP) as PackedScene).instantiate()
	m.save_path = SAVE
	if art_dir != "":
		m.art_dir = art_dir
	frame.add_child(m)
	for i in 3:
		await tree.process_frame
	return [frame, m]


func _done(made: Array) -> void:
	made[0].free()
	MapLink.current = {}
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE))


## The Functions island's regions, in order: most tests play on its painted board.
func _fn() -> Array:
	return MapLink.region_ids("functions")


## A region with no built type, or "" once every region is built.
func _unbuilt_region() -> String:
	for id in MapLink.region_ids():
		if Dungeon.region_types(id).is_empty():
			return id
	return ""


# ── Links ────────────────────────────────────────────────────

func test_every_region_has_a_link() -> void:
	check_eq(_fn(), ["quadratics", "exp-log", "graphs-features", "composite-inverse", "rational",
		"function-basics", "lines", "transformations"], "the plan's 8 Functions regions in order")
	var raw: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(CATALOGUE))
	var ids := MapLink.region_ids()
	check_eq(ids.size(), (raw.regions as Array).size(), "every catalogue region")
	var on_islands := 0
	for island in MapLink.OPEN_ISLANDS:
		var here := MapLink.region_ids(island)
		check(here.size() >= 5, "%s has %d regions" % [island, here.size()])
		on_islands += here.size()
		for id in here + ["all"]:
			var region: String = Dungeon.all_of(island) if id == "all" else id
			var want := {"screen": "region", "island": island, "region": region}
			check_eq(MapLink.parse("#%s/%s" % [island, id]), want, id)
			check_eq(MapLink.parse("%s/%s/" % [island, id]), want, id + " without # and with a slash")
			check_eq(MapLink.to_hash(want), "#%s/%s" % [island, id], id + " back to a link")
			check_eq(MapLink.region_route(region), want, id + "'s route")
	check_eq(on_islands, ids.size(), "every region is on one island")
	check_eq(MapLink.parse("#algebra/quadratics"), {"screen": "world"}, "a region only on its own island")


func test_the_island_and_world_links() -> void:
	check_eq(MapLink.parse("#functions"), {"screen": "island", "island": "functions"})
	check_eq(MapLink.parse("#Functions/"), {"screen": "island", "island": "functions"}, "case and a slash")
	check_eq(MapLink.to_hash({"screen": "island", "island": "functions"}), "#functions")
	for island in MapLink.OPEN_ISLANDS:
		check_eq(MapLink.parse("#" + island), {"screen": "island", "island": island}, island)
		check_eq(MapLink.to_hash({"screen": "island", "island": island}), "#" + island)
	check_eq(MapLink.parse("#world"), {"screen": "world"})
	check_eq(MapLink.to_hash({"screen": "world"}), "#world")
	check_eq(MapLink.parse("#thunderdome"), MapLink.THUNDERDOME_ROUTE, "the Thunderdome")
	check_eq(MapLink.parse("#Thunderdome/"), MapLink.THUNDERDOME_ROUTE, "case and a slash")
	check_eq(MapLink.to_hash(MapLink.THUNDERDOME_ROUTE), "#thunderdome")
	check_eq(MapLink.region_route(Dungeon.THUNDERDOME), MapLink.THUNDERDOME_ROUTE)
	check_eq(MapLink.scene_for(MapLink.THUNDERDOME_ROUTE), MAP)
	check_eq(MapLink.scene_for({"screen": "world"}), MAP)
	check_eq(MapLink.scene_for(MapLink.region_route("quadratics")), MAP)


func test_the_bazaar_link() -> void:
	check_eq(MapLink.parse("#bazaar"), MapLink.BAZAAR_ROUTE)
	check_eq(MapLink.parse("#Bazaar/"), MapLink.BAZAAR_ROUTE, "case and a slash")
	check_eq(MapLink.to_hash(MapLink.BAZAAR_ROUTE), "#bazaar")
	check_eq(MapLink.scene_for(MapLink.BAZAAR_ROUTE), BAZAAR, "its own scene")
	check_eq(MapLink.parse("#functions/bazaar"), {"screen": "world"}, "not a region")


func test_junk_falls_back_to_the_world_map() -> void:
	for junk in ["", "#", "#/", "#nowhere", "#functions/nowhere", "#functions/quadratics/extra", "#maths",
			"#calculus/quadratics", "#../functions", "#functions//", "%20%20", "#?play=all", "#functions/QUADRATICS!",
			"#thunderdome/all", "#functions/all-algebra", "#functions/thunderdome"]:
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
		if exam_only and t.source != "exam" and str(t.get("examStyle", "")) == "":
			continue
		var exam_reps := {}
		# A type only catalogued so far has no views, so no cells.
		for r in t.get("representations", []):
			exam_reps[r.rep] = r.exam
		for u in t.get("unknowns", []):
			if exam_only and not u.exam:
				continue
			# The AI courses' own skills (AI-SL1.6 and 1.7, FAL-999) are on no AA course.
			if u.get("skills", []).any(func(sk): return str(sk).begins_with("AI-")):
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
	save.settings.exam_only = false
	if unbuilt != "":
		check_eq(Progress.coverage(save, unbuilt), {"checked": 0, "total": _hand_count(unbuilt, false)}, unbuilt)
	# An island: every region's cells, and the Thunderdome every island's. On AA HL, which
	# covers every type the hand count counts (the AA HL counting type too).
	SaveData.set_course(save, "aa-hl")
	var dome := 0
	for name in MapLink.OPEN_ISLANDS:
		var island := 0
		for id in MapLink.region_ids(name):
			island += _hand_count(id, false)
		check_eq(Progress.coverage(save, Dungeon.all_of(name)).total, island, "the %s all-regions total" % name)
		dome += island
	check_eq(Progress.coverage(save, Dungeon.THUNDERDOME).total, dome, "the Thunderdome's total")


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


## The Functions island's open (built) regions, most-examined first.
func _open_regions() -> Array:
	return _fn().filter(func(id): return Progress.is_built(id))


## Answers `right` of `seen` in the region's first cell.
func _answer(save: Dictionary, region: String, right: int, seen: int) -> void:
	var key: String = Progress.catalogue_cells(region, false)[0].key
	for i in seen:
		SaveData.record(save, key, i < right, 100)


func test_sparks_pick_is_the_first_untried_open_region() -> void:
	var open := _open_regions()
	check(open.size() >= 2, "two open regions to pick between: %s" % [open])
	if open.size() < 2:
		return
	var save := SaveData.blank()
	check_eq(Progress.suggest(save, _fn()), {"region": open[0], "why": "untried"}, "a new save: the most-examined")
	_answer(save, open[0], 0, 5)
	check_eq(Progress.suggest(save, _fn()), {"region": open[1], "why": "untried"}, "the next one not tried, however badly the first went")
	# A floor reached counts as tried too.
	var save2 := SaveData.blank()
	Dungeon.note_floor(save2, open[0], 1, false)
	check_eq(Progress.suggest(save2, _fn()).region, open[1], "a run with no answers is a try")
	var unbuilt := _unbuilt_region()
	if unbuilt != "":
		check(Progress.suggest(SaveData.blank(), _fn()).region != unbuilt, "never a region with nothing built")


func test_sparks_pick_is_the_lowest_accuracy_once_all_are_tried() -> void:
	var open := _open_regions()
	if open.size() < 2:
		return
	var save := SaveData.blank()
	for id in open:
		_answer(save, id, 3, 4)
	# The last region is the weakest at 1 of 4, and the first one has too few answers to
	# count even at 0 of 2.
	_answer(save, open[-1], 0, 4)
	save.cells.erase(Progress.catalogue_cells(open[0], false)[0].key)
	_answer(save, open[0], 0, Progress.MIN_ATTEMPTS - 1)
	check_eq(Progress.suggest(save, _fn()), {"region": open[-1], "why": "accuracy"})
	# A tie goes to the more-examined region.
	var tie := SaveData.blank()
	for id in open:
		_answer(tie, id, 1, 4)
	check_eq(Progress.suggest(tie, _fn()), {"region": open[0], "why": "accuracy"}, "a tie")


func test_sparks_pick_is_the_lowest_coverage_when_no_accuracy_counts() -> void:
	var open := _open_regions()
	if open.size() < 2:
		return
	var save := SaveData.blank()
	# Every region tried, each under MIN_ATTEMPTS answers; the first has more cells checked.
	for id in open:
		_answer(save, id, 1, 1)
	var second: String = Progress.catalogue_cells(open[0], false)[1].key
	SaveData.record(save, second, true, 100)
	var shares := open.map(func(id):
		var c := Progress.coverage(save, id)
		return float(c.checked) / c.total)
	var want: String = open[shares.find(shares.min())]
	check_eq(Progress.suggest(save, _fn()), {"region": want, "why": "coverage"}, "shares %s" % [shares])
	check(want != open[0], "the region with more checked is not the pick")


func test_no_pick_with_nothing_open() -> void:
	check_eq(Progress.suggest(SaveData.blank(), []), {}, "no regions")
	var unbuilt := _unbuilt_region()
	check_eq(Progress.suggest(SaveData.blank(), ["nowhere"] + ([unbuilt] if unbuilt != "" else [])), {},
		"only regions with nothing built")


func test_sparks_pick_excludes_regions_outside_the_students_course() -> void:
	var save := SaveData.blank()
	# Today's Functions regions all have shared material. Model a future HL-only
	# region with the counting type, then restore the catalogue after this test.
	var counting := QuestionEngine.type_of("t1-ahl-counting")
	counting.region = "hl-counting-test"
	check(Progress.is_built("hl-counting-test"), "the HL-only region is built")
	check(not Progress.is_built("hl-counting-test", Courses.of(save)), "AA SL cannot play it")
	check_eq(Progress.suggest(save, ["hl-counting-test"]), {}, "never suggest an unavailable region")
	check_eq(Progress.suggest(save, ["hl-counting-test", "quadratics"]),
		{"region": "quadratics", "why": "untried"}, "suggest an available region instead")
	counting.erase("region")


# ── Screens ──────────────────────────────────────────────────

func test_the_world_map() -> void:
	var made: Array = await _map({"screen": "world"})
	var m: Control = made[1]
	check_eq(m.screen, "world")
	check(m.world.visible and not m.island.visible and not m.region_view.visible, "only the world shows")
	var board: Control = m.world_board
	var fn := board.get_node("Island_functions") as Button
	check(not fn.disabled, "the Signal Tower is open")
	check_eq(_card_of(m, fn), "Signal Tower · Functions")
	var names := {"algebra": "Scrap Fields · Numbers and algebra", "geometry": "Dry Flats · Geometry and trigonometry",
		"stats": "Radio Spires · Statistics and probability", "calculus": "Engine Core · Calculus"}
	for id in names:
		var b := board.get_node("Island_" + id) as Button
		check(not b.disabled, id + " is open (FAL-925)")
		check_eq(_card_of(m, b), names[id], id)
	var td := board.get_node("Thunderdome") as Button
	check(not td.disabled, "the Thunderdome is open with every island")
	check_eq(_card_of(m, td), "Thunderdome · Questions from all over the Wasteland")
	var lib := board.get_node("RelicLibrary") as Button
	check(not lib.disabled, "the optional library opens before any play")
	check_eq(_card_of(m, lib), "Relic Library · Watch a worked example or try a question")
	var shop := board.get_node("Bazaar") as Button
	check(not shop.disabled, "the Bazaar is open")
	check_eq(_card_of(m, shop), "Bazaar · 0 Scrap to spend")
	check(shop.get_node_or_null("Marker") == null, "the painting has the Bazaar (FAL-791): no coded marker")
	check(m.world.get_node_or_null("Footer") == null, "no bar under the board")
	check_eq((m.world.get_node("Header").get_child(0).get_node("Scrap") as Label).text, "Scrap: 0", "the Scrap in the header")
	check_eq(Audio.location(), "overworld", "the overworld loop")
	_done(made)


func test_the_world_map_opens_the_bazaar_and_leaving_it_goes_back() -> void:
	var save := SaveData.blank()
	save.scrap = 1240
	var made: Array = await _map({"screen": "world"}, save)
	var m: Control = made[1]
	var shop := m.world_board.get_node("Bazaar") as Button
	check_eq(_card_of(m, shop), "Bazaar · 1240 Scrap to spend", "the Scrap to spend")
	check_eq(shop.accessibility_name, "Bazaar: 1240 Scrap to spend")
	check_eq((m.world.get_node("Header").get_child(0).get_node("Scrap") as Label).text, "Scrap: 1240")
	# The Bazaar's zone, the caravan on the FAL-986 painting, trimmed clear of the Engine Core.
	var zone: Rect2 = preload("res://ui/map.gd").BAZAAR_ZONE
	check_eq(zone, Rect2(22, 70.75, 40, 10.5))
	check(Rect2(Vector2.ZERO, m.BOARD).encloses(Rect2(shop.position, shop.size)), "the Bazaar is on the board")
	# A click goes in, zooming into the Bazaar first.
	shop.pressed.emit()
	check(m._zooming, "the board zooms into the Bazaar")
	await tree.create_timer(m.ZOOM_TIME + 0.1).timeout
	for i in 3:
		await tree.process_frame
	check_eq(MapLink.current, MapLink.BAZAAR_ROUTE, "the route")
	var bazaar := tree.current_scene
	check(bazaar != null and bazaar.scene_file_path == BAZAAR, "the Bazaar is on screen")
	if bazaar != null and bazaar.scene_file_path == BAZAAR:
		var back := bazaar.find_child("Back", true, false) as Button
		check_eq(back.text, "◂ The Wasteland")
		bazaar.leave(true)
		for i in 3:
			await tree.process_frame
		var map := tree.current_scene
		check(map != null and map.scene_file_path == MAP, "back on the map")
		if map != null and map.scene_file_path == MAP:
			check_eq(map.screen, "world", "on the world map")
	check_eq(MapLink.current, {"screen": "world"})
	tree.unload_current_scene()
	await tree.process_frame
	_done(made)


# ── The world map as a fast-travel map (FAL-988) ───────────

## Every world-map place's [button name, zone, pin], from map.gd.
func _world_places() -> Array:
	var map_script := preload("res://ui/map.gd")
	var out: Array = []
	for i in map_script.ISLANDS:
		out.append(["Island_" + i.id, i.zone, i.pin])
	out.append(["Thunderdome", map_script.THUNDERDOME_ZONE, map_script.THUNDERDOME_PIN])
	out.append(["RelicLibrary", map_script.RELIC_LIBRARY_ZONE, map_script.RELIC_LIBRARY_PIN])
	out.append(["Bazaar", map_script.BAZAAR_ZONE, map_script.BAZAAR_PIN])
	return out


## A zone (centre and size) as a Rect2 of its corner and size, in %.
func _rect(zone: Rect2) -> Rect2:
	return Rect2(zone.position - zone.size / 2.0, zone.size)


func test_the_world_zones_come_from_the_painting_with_no_two_overlapping() -> void:
	var places := _world_places()
	check_eq(places.size(), 8)
	for p in places:
		var r := _rect(p[1])
		check(Rect2(0, 0, 100, 100).encloses(r), "%s: its zone %s is on the board" % [p[0], r])
		check(r.has_point(p[2]) and p[2].x < r.end.x and p[2].y < r.end.y, "%s: its pin %s inside its zone %s" % [p[0], p[2], r])
		for q in places:
			if q[0] != p[0]:
				check(not r.intersects(_rect(q[1])), "%s and %s overlap" % [p[0], q[0]])
	var made: Array = await _map({"screen": "world"})
	var m: Control = made[1]
	for p in places:
		var b := m.world_board.get_node(p[0]) as Button
		var pin := b.get_node("Pin") as Control
		check((b.position + pin.position + pin.size / 2.0).distance_to(p[2] * m.BOARD / 100.0) < 0.5, "%s: the pin at its point" % p[0])
	check(m.world_board.find_children("*", "Line2D", true, false).is_empty(), "no route lines on the world map")
	_done(made)


func test_the_world_map_uses_visible_pins_without_names_at_rest() -> void:
	var made: Array = await _map({"screen": "world"})
	var m: Control = made[1]
	var board: Control = m.world_board
	for p in _world_places():
		var b := board.get_node(p[0]) as Button
		var name := (b.get_meta("card") as Array)[0] as String
		var pin := b.get_node_or_null("Pin") as Control
		check(pin != null and pin.is_visible_in_tree(), "%s: visible pin" % name)
		check(b.get_node_or_null("Banner") == null, "%s: no permanent name plate" % name)
		check(b.accessibility_name.begins_with(name + ": "), "%s: accessible identity" % name)
		check_eq(b.tooltip_text, "", "%s: the game card is the only hover label" % name)
	check(_board_text(board).is_empty(), "the world board has no resting name text")
	var dome := board.get_node("Thunderdome") as Button
	check_eq(_card_of(m, dome), "Thunderdome · Questions from all over the Wasteland")
	check(not (board.get_node("Card") as Control).visible, "no card until a place is looked at")
	_done(made)


func test_the_world_map_pin_uses_its_button_for_a_single_desktop_click() -> void:
	var save := SaveData.blank()
	save.settings.reduced_motion = true
	var made: Array = await _map({"screen": "world"}, save)
	var m: Control = made[1]
	var b := m.world_board.get_node("Island_calculus") as Button
	var pin := b.get_node("Pin") as Control
	check_eq(pin.mouse_filter, Control.MOUSE_FILTER_IGNORE, "marker art must not intercept input")
	b.pressed.emit()
	check_eq(MapLink.current, {"screen": "island", "island": "calculus"}, "the Engine Core opens")
	_done(made)


func test_each_world_pin_shows_its_state() -> void:
	var map_script := preload("res://ui/map.gd")
	var save := SaveData.blank()
	Dungeon.note_floor(save, Dungeon.all_of("calculus"), Tuning.MIX_FROM_FLOOR - 1, true)
	var made: Array = await _map({"screen": "world"}, save)
	var m: Control = made[1]
	var want := {"Island_algebra": "open", "Island_functions": "open", "Island_geometry": "open", "Island_stats": "open",
		"Island_calculus": "cleared", "Thunderdome": "open", "RelicLibrary": "open", "Bazaar": "open"}
	for n in want:
		var pin := m.world_board.get_node(n + "/Pin") as Control
		check_eq(pin.kind, want[n], n)
		check(map_script.STATE_COLOR.has(pin.kind), n)
	check(not m.world_board.get_node("RelicLibrary").disabled, "optional worked examples stay available")
	check(map_script.thunderdome_open() == (MapLink.OPEN_ISLANDS.size() >= 2), "the Thunderdome waits for a second island")
	_done(made)


func test_last_travel_location_is_saved_without_an_overworld_marker() -> void:
	check_eq(SaveData.blank().here, "bazaar", "a new save starts at the Bazaar")
	var save := SaveData.blank()
	save.settings.reduced_motion = true
	var made: Array = await _map({"screen": "world"}, save)
	var m: Control = made[1]
	check(m.world_board.find_children("Here", "", true, false).is_empty())
	var b := m.world_board.get_node("Island_geometry") as Button
	b.pressed.emit()
	check_eq(MapLink.current, {"screen": "island", "island": "geometry"})
	check_eq(SaveData.load_from(SAVE).here, "geometry", "the save still records travel")
	MapLink.go(m.get_tree(), MapLink.WORLD)
	await tree.process_frame
	m.show_route(MapLink.WORLD)
	check(m.world_board.find_children("Here", "", true, false).is_empty(), "no replacement marker")
	check(not m.world_board.get_node("Island_geometry").accessibility_name.contains("You are here"))
	_done(made)


func test_a_save_from_before_last_travel_keeps_the_bazaar_default() -> void:
	var v5 := SaveData.blank()
	v5.version = 5
	v5.erase("here")
	var s := SaveData.migrate(v5)
	check_eq(s.version, SaveData.VERSION)
	check_eq(s.here, "bazaar")
	var made: Array = await _map({"screen": "world"}, {"version": 6, "here": "relic_library", "settings": {}})
	check_eq(made[1].here(), "bazaar", "an invalid travel location still falls back")
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
	check_eq(spots, _fn() + ["all", "relic"], "8 regions in order, the all-regions dungeon, the Relic device")
	var buttons := _spot_buttons(m)
	check(buttons.relic.disabled, "the Relic device is locked")
	check_eq(_card_of(m, buttons.relic), "Relic device · Closed for now")
	check_eq(_card_of(m, buttons.quadratics), "Quadratics · Mile 2 · 100% right")
	for id in _fn():
		var line := _card_of(m, buttons[id]).trim_prefix(Dungeon.region_name(id) + " · ")
		check_eq(line == "Coming soon", not Progress.is_built(id), "%s: %s" % [id, line])
		check_eq(m.spot_state(id) == "locked", not Progress.is_built(id), id)
	# The accepted painting (FAL-791): the art, no coded ground, no rings.
	check_eq(m.background_path(), "res://assets/map/functions/background.webp")
	check(board.get_node_or_null("Art") != null and board.get_node_or_null("Ground") == null, "the painting")
	check(board.get_node_or_null("Spot_quadratics/Landmark") == null, "no ring over the painting")
	check_eq(Audio.location(), "signal-tower", "the island's loop")
	_done(made)
	# With no painting in its folder, the coded ground and coded landmarks.
	made = await _map({"screen": "island", "island": "functions"}, save, Vector2(1080, 1920), NO_ART)
	board = made[1].island_board
	check(board.get_node_or_null("Ground") != null, "the coded ground")
	check(board.get_node_or_null("Spot_quadratics/Landmark/Coded") != null, "the coded landmark")
	_done(made)


## The island's buttons by spot id.
func _spot_buttons(m: Control) -> Dictionary:
	var out := {}
	for c in m.island_board.get_children():
		if c is Button and c.name.begins_with("Spot_"):
			out[String(c.name).trim_prefix("Spot_")] = c
	return out


## What a place's card says, "Name · line", shown by hovering it (then put away).
func _card_of(m: Control, b: Button) -> String:
	m.show_card(b)
	var card := b.get_parent().get_node("Card") as Control
	var said := "%s · %s" % [(card.get_node("Box/Name") as Label).text, (card.get_node("Box/Line") as Label).text]
	m._hide_card()
	return said


## The board's labels a player can see, other than the card's.
func _board_text(board: Control) -> Array:
	return board.find_children("*", "Label", true, false).filter(func(l): return l.is_visible_in_tree() \
		and not board.get_node("Card").is_ancestor_of(l)).map(func(l): return (l as Label).text)


func test_the_island_is_a_hub_laid_out_as_the_plan() -> void:
	var map_script := preload("res://ui/map.gd")
	check_eq(map_script.SPOTS.functions, {
		"quadratics": Vector2(20, 65.7), "exp-log": Vector2(78.6, 62.6), "function-basics": Vector2(15, 41.4),
		"graphs-features": Vector2(85, 43.8), "lines": Vector2(50, 25.8), "rational": Vector2(50, 68.8),
		"composite-inverse": Vector2(20, 25.5), "transformations": Vector2(81, 28), "all": Vector2(50.4, 49.1),
		"relic": Vector2(9.8, 53.6)}, "the table measured from Matt's board (FAL-1614)")
	var made: Array = await _map({"screen": "island", "island": "functions"})
	var m: Control = made[1]
	var buttons := _spot_buttons(m)
	check_eq(buttons.size(), map_script.SPOTS.functions.size(), "a button per spot")
	var board := Rect2(Vector2.ZERO, map_script.BOARD)
	for id in buttons:
		var b: Button = buttons[id]
		var r := Rect2(b.position, b.size)
		var side: float = map_script.RELIC_HIT if id == "relic" else map_script.HIT
		var centre: Vector2 = map_script.SPOTS.functions[id] * map_script.BOARD / 100.0
		check(r.get_center().distance_to(centre) < 0.5, "%s's square is centred on its spot" % id)
		check(r.size.is_equal_approx(Vector2(side, side)), "%s's square: %s" % [id, r.size])
		check(board.encloses(r), "%s %s is on the board" % [id, r])
		for other in buttons:
			if other < id:
				var o: Button = buttons[other]
				check(not r.intersects(Rect2(o.position, o.size)), "%s and %s overlap" % [id, other])
	_done(made)


## Every island's board (FAL-925): a place per region in its order, its all-regions
## dungeon and the Relic device, each square on its SPOTS point, on the board and clear
## of every other; with no painting in its folder, the coded ground and a ring each.
func test_every_island_is_laid_out_with_no_place_overlapping() -> void:
	var map_script := preload("res://ui/map.gd")
	var board := Rect2(Vector2.ZERO, map_script.BOARD)
	for island in MapLink.OPEN_ISLANDS:
		var made: Array = await _map({"screen": "island", "island": island})
		var m: Control = made[1]
		var buttons := _spot_buttons(m)
		var spots: Array = m.island_board.get_children().filter(func(c): return c.name.begins_with("Spot_")).map(
			func(c): return String(c.name).trim_prefix("Spot_"))
		check_eq(spots, MapLink.region_ids(island) + ["all", "relic"], island + ": its regions in order, all, relic")
		check_eq(buttons.size(), (map_script.SPOTS[island] as Dictionary).size(), island + ": a place per spot")
		var painted: bool = island in PAINTED
		check_eq(m.background_path() != "", painted, island + ": painted only where its painting has landed")
		if not painted:
			check(m.island_board.get_node_or_null("Ground") != null, island + ": the coded ground")
		check_eq((m.island.get_node("Header").get_child(0).get_node("Title") as Label).text, m.island_info(island).name)
		for id in buttons:
			var b: Button = buttons[id]
			var r := Rect2(b.position, b.size)
			var centre: Vector2 = map_script.SPOTS[island][id] * map_script.BOARD / 100.0
			check(r.get_center().distance_to(centre) < 0.5, "%s %s is on its spot" % [island, id])
			check(board.encloses(r), "%s %s %s is on the board" % [island, id, r])
			if not painted and id != "relic":
				var mark := b.get_node_or_null("Landmark/Coded/Mark") as Label
				check(mark != null and mark.text == map_script.GLYPHS[id], "%s %s: its glyph" % [island, id])
			for other in buttons:
				if other < id:
					var o: Button = buttons[other]
					check(not r.intersects(Rect2(o.position, o.size)), "%s: %s and %s overlap" % [island, id, other])
		check_eq(Audio.location(), MapLink.MUSIC[island], island + "'s loop")
		_done(made)


func test_no_roads_on_the_island() -> void:
	var map_script := preload("res://ui/map.gd")
	check(not (map_script as GDScript).get_script_method_list().any(func(f): return f.name == "roads"), "no roads()")
	var made: Array = await _map({"screen": "island", "island": "functions"}, {}, Vector2(1080, 1920), NO_ART)
	var board: Control = made[1].island_board
	check(board.find_child("Roads", true, false) == null, "no road node")
	check(board.get_node_or_null("Ground/Jetty") != null, "the jetty dot stays")
	_done(made)


## Both boards reveal a single card using the same hover and focus behavior.
func test_names_hide_until_a_place_is_hovered_focused_or_tapped() -> void:
	var save := SaveData.blank()
	save.scrap = 75
	for r in [{"screen": "world"}, {"screen": "island", "island": "functions"}]:
		var made: Array = await _map(r, save)
		var m: Control = made[1]
		var board: Control = m.world_board if r.screen == "world" else m.island_board
		var card := board.get_node("Card") as Control
		var places: Array = board.get_children().filter(func(c): return c is Button)
		var names: Array = places.map(func(b): return (b.get_meta("card") as Array)[0])
		check(not card.visible, "%s: no card at first" % r.screen)
		check(m.get_viewport().gui_get_focus_owner() in places, "%s: first focus on a place" % r.screen)
		for t in _board_text(board):
			check(not t in names and not t.to_lower() in names.map(func(n): return String(n).to_lower()), "%s: '%s' shows on the board" % [r.screen, t])
			check(not t.contains("Coming") and not t.contains("Locked") and not t.contains("Scrap"), "%s: '%s' on the board" % [r.screen, t])
		for b in places:
			check(b.accessibility_name.begins_with((b.get_meta("card") as Array)[0] + ": "), "%s: %s's name for screen readers" % [r.screen, b.name])
			check_eq(b.tooltip_text, "", "%s: no second tooltip for %s" % [r.screen, b.name])
		# The mouse: hovering shows the card by the place, and leaving puts it away.
		m._input(_mouse_motion())
		var b: Button = places[1]
		b.mouse_entered.emit()
		check(card.visible, "%s: hover shows the card" % r.screen)
		check_eq((card.get_node("Box/Name") as Label).text, (b.get_meta("card") as Array)[0])
		check((b.get_node("Glow") as Control).visible, "the place lights up")
		check(Rect2(Vector2.ZERO, m.BOARD).encloses(Rect2(card.position, card.size)), "%s: the card is on the board" % r.screen)
		b.mouse_exited.emit()
		check(not card.visible, "%s: leaving puts it away" % r.screen)
		# The keyboard: focus shows it, and Tab moves between places.
		var k: Button = places[2]
		m._input(_key(KEY_TAB))
		k.grab_focus()
		check(card.visible and card.get_node("Box/Name").text == (k.get_meta("card") as Array)[0], "%s: focus shows the card" % r.screen)
		check(k.find_next_valid_focus() in places, "%s: Tab moves to another place" % r.screen)
		check(card.focus_mode == Control.FOCUS_NONE, "the card never takes focus")
		_done(made)


## The island's columns sit closer than a card is tall (FAL-925), so a place's card goes
## beside it, on the side with more room, on the board and clear of the place itself. On the
## Signal Tower (FAL-1614) the lines and rational places share the middle column with the
## all-regions dungeon, so their cards only have to clear them.
func test_a_card_sits_beside_its_place_on_the_island() -> void:
	var map_script := preload("res://ui/map.gd")
	var made: Array = await _map({"screen": "island", "island": "functions"})
	var m: Control = made[1]
	var card := m.island_board.get_node("Card") as Control
	var board := Rect2(Vector2.ZERO, map_script.BOARD)
	for id in ["composite-inverse", "transformations", "function-basics", "graphs-features", "quadratics", "exp-log", "relic"]:
		var b: Button = _spot_buttons(m)[id]
		m.show_card(b)
		var c := Rect2(card.position, card.size)
		var r := Rect2(b.position, b.size)
		check(board.encloses(c), "%s: the card %s is on the board" % [id, c])
		check(not c.intersects(r), "%s: the card %s covers its place %s" % [id, c, r])
		check(absf(c.get_center().y - r.get_center().y) < 1.0, "%s: the card is beside its place" % id)
		var left := r.get_center().x < map_script.BOARD.x / 2.0
		check_eq(c.position.x > r.end.x, left, "%s: the card on the side with more room" % id)
		m._hide_card()
	for id in ["all", "lines", "rational"]:
		var mid: Button = _spot_buttons(m)[id]
		m.show_card(mid)
		var c := Rect2(card.position, card.size)
		check(board.encloses(c) and not c.intersects(Rect2(mid.position, mid.size)), "%s: the middle place's card clears it" % id)
		m._hide_card()
	_done(made)


func test_a_touch_shows_the_card_then_a_second_tap_goes_in() -> void:
	var save := SaveData.blank()
	save.settings.reduced_motion = true
	var made: Array = await _map({"screen": "island", "island": "functions"}, save)
	var m: Control = made[1]
	var was := tree.current_scene
	m.reparent(tree.root)
	tree.current_scene = m
	var open := _open_regions()
	var b: Button = _spot_buttons(m)[open[0]]
	m._input(_touch())
	check(m.touch, "a finger")
	b.pressed.emit()
	check_eq(m.screen, "island", "the first tap stays on the island")
	var card := m.island_board.get_node("Card") as Control
	check(card.visible and m.card_for == b, "the first tap shows the card")
	check((b.get_node("Glow") as Control).visible, "and lights the place")
	# A tap on another place moves the card there; it doesn't go in either.
	var other: Button = _spot_buttons(m)["all"]
	other.pressed.emit()
	check_eq(m.screen, "island")
	check(m.card_for == other, "the card moves")
	check(not (b.get_node("Glow") as Control).visible, "the first place goes dark")
	other.pressed.emit()
	check_eq(m.route.get("region"), "all", "the second tap on the place goes in")
	m.show_route({"screen": "island", "island": "functions"})
	await tree.process_frame
	# A tap on the card goes in too.
	b = _spot_buttons(m)[open[0]]
	b.pressed.emit()
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.pressed = false
	(m.island_board.get_node("Card") as Control).gui_input.emit(release)
	check_eq(m.route.get("region"), open[0], "a tap on the card goes in")
	m.show_route({"screen": "island", "island": "functions"})
	await tree.process_frame
	# A closed place shows its card on a tap and never goes in.
	var relic: Button = _spot_buttons(m).relic
	var tap := InputEventMouseButton.new()
	tap.button_index = MOUSE_BUTTON_LEFT
	tap.pressed = true
	relic.gui_input.emit(tap)
	check(m.card_for == relic and m.island_board.get_node("Card").visible, "the Relic device's card")
	m.press_card()
	check_eq(m.screen, "island", "the Relic device stays shut")
	# A mouse again: one click goes in.
	m._input(_mouse_motion())
	check(not m.touch, "a mouse")
	_spot_buttons(m)[open[0]].pressed.emit()
	check_eq(m.route.get("region"), open[0], "a click goes in")
	tree.current_scene = was
	m.free()
	_done(made)


func _mouse_motion() -> InputEventMouseMotion:
	var e := InputEventMouseMotion.new()
	e.device = 0
	return e


func _touch() -> InputEventScreenTouch:
	var e := InputEventScreenTouch.new()
	e.pressed = true
	return e


func _key(code: Key) -> InputEventKey:
	var e := InputEventKey.new()
	e.keycode = code
	e.pressed = true
	return e


func test_painted_places_on_a_background() -> void:
	var save := SaveData.blank()
	var open := _open_regions()
	for f in [1, 2, 3]:
		Dungeon.note_floor(save, open[0], f, true)
	_answer(save, open[0], 3, 3)
	var made: Array = await _map({"screen": "island", "island": "functions"}, save, Vector2(1080, 1920),
		"res://tests/fixtures/art/map/painted/")
	var m: Control = made[1]
	check_eq(m.background_path(), "res://tests/fixtures/art/map/painted/background.png")
	var board: Control = m.island_board
	check(board.get_node_or_null("Art") != null and board.get_node_or_null("Ground") == null, "the painting, no coded ground")
	var buttons := _spot_buttons(m)
	for id in buttons:
		var b: Button = buttons[id]
		check(b.get_node_or_null("Landmark") == null, id + ": no ring over the painting")
		var state: String = "locked" if id == "relic" else m.spot_state(id)
		check_eq(b.get_node_or_null("Padlock") != null, state == "locked", id + ": a padlock when locked")
		check_eq(b.get_node_or_null("Wash") != null, state == "locked", id + ": a dark wash when locked")
		check_eq(b.get_node_or_null("Flag") != null, state == "cleared", id + ": a flag when cleared")
		var pin := b.get_node_or_null("Pin") as Control
		check_eq(pin != null, state == "open", id + ": a pin when the painting needs an open marker")
		if pin != null:
			check(pin.is_visible_in_tree() and pin.size.x >= 72.0, id + ": visible pin")
			check_eq(pin.mouse_filter, Control.MOUSE_FILTER_IGNORE, id + ": pin cannot swallow a tap")
		check(b.flat and b.text == "", id + ": an unlabelled hit area")
	check_eq(m.spot_state(open[0]), "cleared", "a cleared region to flag")
	check(buttons[open[0]].size.is_equal_approx(Vector2(300, 300)), "a region's square")
	check(buttons.relic.size.is_equal_approx(Vector2(160, 160)), "the relic's square")
	check(_board_text(board).is_empty(), "no text on the painting: %s" % [_board_text(board)])
	_done(made)
	# A landmark PNG still draws over a painting, as on the coded look.
	made = await _map({"screen": "island", "island": "functions"}, {}, Vector2(1080, 1920),
		"res://tests/fixtures/art/map/functions/")
	check(_spot_buttons(made[1]).quadratics.get_node_or_null("Landmark/Art") != null, "the fixture's landmark art")
	_done(made)


func test_the_coded_landmarks_show_glyphs_not_numbers() -> void:
	var map_script := preload("res://ui/map.gd")
	var made: Array = await _map({"screen": "island", "island": "functions"}, {}, Vector2(1080, 1920), NO_ART)
	var buttons := _spot_buttons(made[1])
	for id in buttons:
		var mark := buttons[id].get_node("Landmark/Coded/Mark") as Label
		check_eq(mark.text, map_script.GLYPHS[id], id + "'s glyph, not its initials")
		check(not mark.text.is_valid_int(), "%s: no number (%s)" % [id, mark.text])
		for i in mark.text.length():
			check(UiTheme.TITLE_FONT.has_char(mark.text.unicode_at(i)), "%s: the title font draws '%s'" % [id, mark.text[i]])
		var ring := mark.get_parent() as Control
		check(mark.get_minimum_size().x <= ring.custom_minimum_size.x - 20.0, "%s's glyph fits its ring" % id)
		if id != "relic":
			check(ring.custom_minimum_size.x >= 240.0, "%s's ring is bigger with no label under it" % id)
	_done(made)
	# A glyph the font can't draw falls back to the region's initials.
	check_eq(map_script.mark("graphs-features", "f⁻¹"), "GKF", "superscript letters fall back")
	check_eq(map_script.mark("exp-log", "eˣ"), "EL")


func test_sparks_pick_gets_the_beacon_its_line_and_first_focus() -> void:
	var open := _open_regions()
	if open.size() < 2:
		return
	# One region tried, the next one not: the beacon is on the untried one.
	var save := SaveData.blank()
	_answer(save, open[0], 2, 3)
	var made: Array = await _map({"screen": "island", "island": "functions"}, save)
	var m: Control = made[1]
	check_eq(m.pick, {"region": open[1], "why": "untried"})
	var buttons := _spot_buttons(m)
	for id in buttons:
		check_eq(buttons[id].get_node_or_null("Beacon") != null, id == open[1], id + ": a beacon only on the pick")
	check(buttons[open[1]].get_node("Beacon").visible, "the beacon is on all the time")
	check_eq(_card_of(m, buttons[open[1]]), Dungeon.region_name(open[1]) + " · Not tried yet · Spark's pick")
	check_eq(_card_of(m, buttons[open[0]]), Dungeon.region_name(open[0]) + " · 67% right", "the tried region's line has no pick")
	check_eq(m.get_viewport().gui_get_focus_owner(), buttons[open[1]], "first focus on the pick")
	check(not m.island_board.get_node("Card").visible, "the first focus shows no card")
	check(not buttons[open[0]].disabled, "the region tried stays open: a pick is never a gate")
	_done(made)


func test_the_beacon_shows_over_landmark_art() -> void:
	var open := _open_regions()
	var made: Array = await _map({"screen": "island", "island": "functions"}, {}, Vector2(1080, 1920),
		"res://tests/fixtures/art/map/functions/")
	var b: Button = _spot_buttons(made[1])[open[0]]
	check(b.get_node_or_null("Landmark/Art") != null, "the fixture's landmark art")
	var beacon := b.get_node_or_null("Beacon")
	check(beacon != null and beacon.get_index() > b.get_node("Landmark").get_index(), "the beacon, drawn over the art")
	_done(made)


func test_every_open_region_still_opens_its_screen() -> void:
	var save := SaveData.blank()
	save.settings.reduced_motion = true
	var made: Array = await _map({"screen": "island", "island": "functions"}, save)
	var m: Control = made[1]
	# The map as the scene on screen, so a press shows the route in it.
	var was := tree.current_scene
	m.reparent(tree.root)
	tree.current_scene = m
	for island in MapLink.OPEN_ISLANDS:
		m.show_route({"screen": "island", "island": island})
		await tree.process_frame
		var buttons := _spot_buttons(m)
		for id in MapLink.region_ids(island) + ["all"]:
			var b: Button = buttons[id]
			var region: String = Dungeon.all_of(island) if id == "all" else id
			check(not b.disabled, "%s %s is enabled" % [island, id])
			check_eq(m.spot_state(region), "open", "%s %s has questions" % [island, id])
			b.pressed.emit()
			check_eq(m.screen, "region", id + ": reduced motion cuts straight in")
			check_eq(m.route, {"screen": "region", "island": island, "region": region}, id + "'s screen")
			check(m.region_col.get_node_or_null("Start/Floor1") != null, id + ": a run can start")
			check_eq(Audio.location(), MapLink.MUSIC[island], id + ": the island's loop")
			m.show_route({"screen": "island", "island": island})
			await tree.process_frame
			buttons = _spot_buttons(m)
	tree.current_scene = was
	m.free()
	_done(made)


func test_going_in_zooms_into_the_place_and_back_zooms_out() -> void:
	var made: Array = await _map({"screen": "world"})
	var m: Control = made[1]
	var was := tree.current_scene
	m.reparent(tree.root)
	tree.current_scene = m
	var fitted: Vector2 = m.world_board.scale
	(m.world_board.get_node("Island_functions") as Button).pressed.emit()
	check_eq(m.screen, "world", "the world stays while the board zooms")
	await tree.create_timer(m.ZOOM_TIME / 2.0).timeout
	check(m.world_board.scale.x > fitted.x * 1.05, "the board scales up: %s" % m.world_board.scale)
	await tree.create_timer(m.ZOOM_TIME / 2.0 + 0.1).timeout
	check_eq(m.screen, "island", "then the island")
	check(m.island.modulate.a < 1.0, "fading in")
	await tree.create_timer(m.FADE_TIME + 0.1).timeout
	check(is_equal_approx(m.island.modulate.a, 1.0), "faded in")
	# Back (the header, or the browser through MapLink) zooms the world out of the island.
	m.show_route(MapLink.WORLD)
	check(m.world_board.scale.x > fitted.x * 1.5, "the world starts zoomed in on the island")
	await tree.create_timer(m.ZOOM_TIME + 0.1).timeout
	check(m.world_board.scale.is_equal_approx(fitted), "and zooms out: %s" % m.world_board.scale)
	# Reduced motion cuts.
	m.save.settings.reduced_motion = true
	m.show_route({"screen": "island", "island": "functions"})
	check(is_equal_approx(m.island.modulate.a, 1.0), "no fade with reduced motion")
	m.show_route(MapLink.WORLD)
	check(m.world_board.scale.is_equal_approx(fitted), "no zoom with reduced motion")
	tree.current_scene = was
	m.free()
	_done(made)


func test_the_region_screen_sits_over_its_backdrop() -> void:
	ArtSlots.root = "res://tests/fixtures/art/"
	var made: Array = await _map(MapLink.region_route("quadratics"))
	var m: Control = made[1]
	var art: TextureRect = m.region_backdrop
	check(art.visible and art.texture.resource_path == "res://tests/fixtures/art/regions/quadratics/backdrop.png", "the region's backdrop")
	check_eq(art.stretch_mode, TextureRect.STRETCH_KEEP_ASPECT_COVERED, "cover-fitted")
	check(art.get_index() < m.region_margin.get_index(), "behind the screen")
	check((art.get_node("Wash") as ColorRect).color.a >= 0.69, "washed so the text keeps 4.5:1")
	_done(made)
	ArtSlots.root = "res://assets/"
	made = await _map(MapLink.region_route("quadratics"))
	check(made[1].region_backdrop.visible, "the game's own backdrop")
	_done(made)
	ArtSlots.root = "res://tests/fixtures/no-art/"
	made = await _map(MapLink.region_route("quadratics"))
	var closeup = made[1].region_backdrop.texture
	check(made[1].region_backdrop.visible and closeup is AtlasTexture and closeup.atlas == made[1].OVERWORLD,
		"no backdrop: a close-up of the island on the world map (FAL-925)")
	_done(made)
	ArtSlots.root = "res://assets/"


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
	check_eq((col.get_node("Stats/Rows/BestFloor") as Label).text, "Furthest mile: 2")
	check_eq((col.get_node("Stats/Rows/Tried") as Label).text,
		"Different questions tried: 2 of %d" % _hand_count("quadratics", false))
	var start: Control = col.get_node("Start")
	check_eq(start.get_children().map(func(b): return String(b.name)), ["Floor1", "Floor2", "Floor3", "Practice"])
	# The switch changes the count and is saved.
	(col.find_child("ExamOnly", true, false) as Button).button_pressed = true
	await tree.process_frame
	check_eq((m.region_col.get_node("Stats/Rows/Tried") as Label).text,
		"Different questions tried: %d of %d" % [Progress.coverage(m.save, "quadratics").checked, _hand_count("quadratics", true)])
	check_eq(SaveData.load_from(SAVE).settings.exam_only, true, "the switch is saved")
	_done(made)


func test_the_region_screen_picks_the_course_and_keeps_the_progress() -> void:
	var save := SaveData.blank()
	var shared: Dictionary = Progress.catalogue_cells("quadratics", false, "ai-sl")[0]
	SaveData.record(save, shared.key, true, 100)
	var made: Array = await _map(MapLink.parse("#functions/quadratics"), save)
	var m: Control = made[1]
	var row: Control = m.region_col.get_node("Course")
	check_eq(row.get_children().filter(func(c): return c is Button).map(func(b): return String(b.name)), Courses.ids(), "a button per course")
	check((row.get_node("aa-sl") as Button).button_pressed, "the save is on AA SL")
	check_eq((row.get_node("ai-sl") as Button).text, "AI SL")
	var aa_total: int = Progress.coverage(m.save, "quadratics").total
	(row.get_node("ai-sl") as Button).button_pressed = true
	(row.get_node("ai-sl") as Button).pressed.emit()
	await tree.process_frame
	check_eq(m.save.course, "ai-sl", "the map's save")
	var stored := SaveData.load_from(SAVE)
	check_eq(stored.course, "ai-sl", "the course is saved")
	check_eq(stored.cells[shared.key].seen, 1, "the record on a shared cell stays")
	var row2: Control = m.region_col.get_node("Course")
	check((row2.get_node("ai-sl") as Button).button_pressed and not (row2.get_node("aa-sl") as Button).button_pressed, "the row shows AI SL")
	var ai_total: int = Progress.coverage(m.save, "quadratics").total
	check(ai_total < aa_total, "AI SL's Quadratics has fewer cells (%d) than AA SL's (%d)" % [ai_total, aa_total])
	check(m.region_col.get_node_or_null("Start") != null, "AI SL still has questions here")
	check_eq(m.set_course("no-such-course"), false, "an unknown course is refused")
	check_eq(SaveData.load_from(SAVE).course, "ai-sl", "and nothing changes")
	_done(made)


func test_a_coming_soon_region_still_offers_the_picker_and_says_why() -> void:
	var id := _unbuilt_region()
	if id == "":
		return  # Every region is built: nothing left to be "coming soon".
	var made: Array = await _map(MapLink.region_route(id))
	var m: Control = made[1]
	check(m.region_col.get_node_or_null("ComingSoon") != null, "says coming soon")
	check(m.region_col.get_node_or_null("Course") != null, "a student on another course can switch from here")
	var said: Array = m.region_col.find_children("*", "Label", true, false).map(func(l): return (l as Label).text)
	check(said.any(func(t: String): return t.contains("aren't built yet")), "nothing is built in any course: %s" % [said])
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
	save.intro = {"course": true, "cards": true}
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
	check(main.find_child("Bazaar", true, false) == null, "the Bazaar is on the map, not the title")
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
		var routes: Array = [{"screen": "world"}, MapLink.region_route("quadratics"), MapLink.THUNDERDOME_ROUTE]
		for island in MapLink.OPEN_ISLANDS:
			routes.append({"screen": "island", "island": island})
			routes.append(MapLink.region_route(MapLink.region_ids(island)[0]))
		for r in routes:
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
				var frame: Rect2 = m._map_frames[board]
				var painted := board.get_global_transform_with_canvas() * frame
				check(screen.grow(1).encloses(painted), "%s: visible painting %s outside %s" % [what, painted, screen])
				for b in board.get_children():
					if b is Button:
						check(screen.encloses((b as Control).get_global_rect()), "%s: %s outside" % [what, b.name])
				var head: Control = (m.world if r.screen == "world" else m.island).get_node("Header")
				check(head.get_global_rect().end.y <= painted.position.y + 1.0, "%s: the header overlaps the board" % what)
				if r.screen == "world":
					check(m.world.get_node_or_null("Footer") == null, "%s: no bar under the board" % what)
					var scrap := m.world.get_node("Header").get_child(0).get_node("Scrap") as Control
					check(screen.encloses(scrap.get_global_rect()), "%s: the Scrap count outside" % what)
			_done(made)


# ── Every island (FAL-925) ───────────────────────────────────

## Each region is on the island of its types' topic, and an all-regions dungeon on its own.
func test_island_of_is_right_for_every_region() -> void:
	var topic_island := {}
	for island in MapLink.OPEN_ISLANDS:
		topic_island[int(MapLink.OPEN_ISLANDS[island])] = island
	check_eq(topic_island.size(), 5, "five islands, one per topic")
	var placed := 0
	for t in QuestionEngine.catalogue().types:
		if t.get("region") == null:
			continue
		placed += 1
		check_eq(MapLink.island_of(t.region), topic_island[int(t.topic)], "%s (%s)" % [t.region, t.id])
	check(placed > 140, "types with a region: %d" % placed)
	for island in MapLink.OPEN_ISLANDS:
		check_eq(MapLink.island_of(Dungeon.all_of(island)), island, island + "'s all-regions dungeon")
	check_eq(Dungeon.all_of("functions"), "all", "the Functions dungeon keeps its id")
	check_eq(MapLink.island_of(Dungeon.THUNDERDOME), Dungeon.THUNDERDOME)
	# Every built type of topics 1 to 5 has a region, so the map and the runs reach it.
	for id in QuestionEngine.built_types():
		check(QuestionEngine.type_of(id).get("region") != null, id + " has a region")


## Each island's loop on its map and in its runs, its boss loop in a boss fight, and the
## Thunderdome's own: with the overworld, every one of the twelve loops is reachable.
func test_every_island_plays_its_own_loop() -> void:
	var heard := {"overworld": true}
	for island in MapLink.OPEN_ISLANDS:
		for region in MapLink.region_ids(island) + [Dungeon.all_of(island)]:
			check_eq(MapLink.music_for(region), MapLink.MUSIC[island], region)
			check_eq(MapLink.music_for(region, true), MapLink.MUSIC[island] + "-boss", region + " boss")
			heard[MapLink.music_for(region)] = true
			heard[MapLink.music_for(region, true)] = true
	check_eq(MapLink.music_for(Dungeon.THUNDERDOME), "thunderdome")
	check_eq(MapLink.music_for(Dungeon.THUNDERDOME, true), "thunderdome", "the Thunderdome keeps one loop")
	heard["thunderdome"] = true
	var want: Array = MusicTracks.CUES.keys()
	want.sort()
	var got: Array = heard.keys()
	got.sort()
	check_eq(got, want, "every loop is reachable")
	for cue in got:
		check(ResourceLoader.exists(MusicTracks.path(cue)), cue + "'s file")


## The Thunderdome on the world map opens its screen: every island's types, its own loop,
## a run to start, and back to the world map.
func test_the_thunderdome_opens_a_mixed_screen() -> void:
	var save := SaveData.blank()
	save.settings.reduced_motion = true
	var made: Array = await _map({"screen": "world"}, save)
	var m: Control = made[1]
	var was := tree.current_scene
	m.reparent(tree.root)
	tree.current_scene = m
	(m.world_board.get_node("Thunderdome") as Button).pressed.emit()
	check_eq(m.route, MapLink.THUNDERDOME_ROUTE, "its screen")
	check_eq((m.region_col.get_node("Head/Title") as Label).text, "Thunderdome")
	check_eq((m.region_col.get_node("Head/Back") as Button).text, "◂ The Wasteland")
	check(m.region_col.get_node_or_null("Start/Floor1") != null, "a run can start")
	check_eq(Audio.location(), "thunderdome", "its own loop")
	var islands := {}
	for id in Dungeon.region_types(Dungeon.THUNDERDOME):
		islands[MapLink.island_of(QuestionEngine.type_of(id).region)] = true
	check_eq(islands.size(), 5, "every island's types: %s" % [islands.keys()])
	(m.region_col.get_node("Head/Back") as Button).pressed.emit()
	check_eq(m.screen, "world", "back to the world map")
	tree.current_scene = was
	m.free()
	_done(made)


## A run starts from the map in a region of every island, the island's all-regions
## dungeon and the Thunderdome, plays that place's questions and loop, and its boss loop.
func test_a_run_starts_on_every_island_and_in_the_thunderdome() -> void:
	var fight_script := preload("res://ui/fight.gd")
	var places: Array = [Dungeon.THUNDERDOME]
	for island in MapLink.OPEN_ISLANDS:
		places.append(MapLink.region_ids(island)[0])
		places.append(Dungeon.all_of(island))
	var seen := SaveData.blank()
	seen.intro = {"course": true, "cards": true}
	SaveData.store(seen, SAVE)
	for region in places:
		for fight_no in [1, Tuning.FIGHTS_PER_FLOOR]:
			fight_script.launch = {"region": region, "floor": 1}
			var frame := Control.new()
			frame.size = Vector2(1080, 1920)
			tree.root.add_child(frame)
			var f: Control = (load(FIGHT) as PackedScene).instantiate()
			f.save_path = SAVE
			f.first_fight = fight_no
			frame.add_child(f)
			await tree.process_frame
			check(f.run != null and f.run.state == "question", "%s: a run started" % region)
			if f.run != null:
				check_eq(f.run.region, region)
				check(Dungeon.region_types(region).has(f.run.question.view.type), "%s asks its own: %s" % [region, f.run.question.view.type])
				check_eq(Audio.location(), MapLink.music_for(region, fight_no > 1), "%s fight %d's loop" % [region, fight_no])
				check(f.backdrop.visible, region + ": a backdrop or the island's close-up behind it")
			frame.free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE))


## The ambient layer (FAL-1075): data/ambient.json's pieces between the painting and the
## buttons, holding still with reduced motion, and taking no taps.
func test_the_ambient_pieces_come_from_the_data_file() -> void:
	var list := AmbientLayer.entries("res://data/ambient.json", "map")
	check(list.size() >= 5, "the pack's pieces: %d" % list.size())
	var problems := AmbientLayer.check(list, Vector2(1080, 1920), "ambient.json")
	check(problems.is_empty(), "\n".join(problems))
	var made: Array = await _map({"screen": "world"})
	var m: Control = made[1]
	var layer := m.world_board.get_node("Ambient") as AmbientLayer
	check_eq(layer.get_index(), m.world_board.get_node("Art").get_index() + 1, "just over the painting")
	for b in m.world_board.get_children():
		if b is Button:
			check(b.get_index() > layer.get_index(), "%s over the layer" % b.name)
	check_eq(layer.things.size(), list.size(), "one piece per entry")
	for i in list.size():
		var t: Dictionary = layer.things[i]
		check_eq(t["id"], list[i].id, "in the file's order")
		check_eq(t["frames"].size(), AmbientLayer.frames(list[i].sheet).size(), "%s: its sheet's frames" % t["id"])
		check(t["frames"].size() > 1, "%s: cut from its sheet" % t["id"])
		check(t["holder"].visible, "%s shows" % t["id"])
	var crow: Node2D = layer.thing("crow")["holder"]
	var beacon: Dictionary = layer.thing("signal-beacon")
	var was := crow.position
	var frame: int = beacon["frame"]
	await tree.create_timer(0.5).timeout
	check(crow.position.distance_to(was) > 5.0, "the crow flies: %s to %s" % [was, crow.position])
	check(beacon["frame"] != frame, "the beacon cycles")
	_done(made)


func test_reduced_motion_holds_the_ambient_pieces_still() -> void:
	var save := SaveData.blank()
	save.settings.reduced_motion = true
	var made: Array = await _map({"screen": "world"}, save)
	var m: Control = made[1]
	var layer := m.world_board.get_node("Ambient") as AmbientLayer
	var list := AmbientLayer.entries("res://data/ambient.json", "map")
	var before := {}
	for e in list:
		var t: Dictionary = layer.thing(e.id)
		check_eq(t["holder"].visible, e.has("still"), "%s: shown only with a still frame" % e.id)
		if e.has("still"):
			check_eq(t["frame"], int(e.still), "%s: its still frame" % e.id)
		before[e.id] = [t["holder"].position, t["sprite"].texture]
	await tree.create_timer(0.5).timeout
	for e in list:
		var t: Dictionary = layer.thing(e.id)
		check_eq([t["holder"].position, t["sprite"].texture], before[e.id], "%s holds still" % e.id)
	_done(made)


## A real click on the Thunderdome, where the dome's neon sits over its button.
func test_taps_reach_the_zone_buttons_through_the_ambient_layer() -> void:
	var save := SaveData.blank()
	save.settings.reduced_motion = true
	var made: Array = await _map({"screen": "world"}, save)
	var m: Control = made[1]
	var layer := m.world_board.get_node("Ambient") as AmbientLayer
	check_eq(layer.mouse_filter, Control.MOUSE_FILTER_IGNORE, "the layer takes no taps")
	check(layer.find_children("*", "Control", true, false).is_empty(), "nothing in it takes taps either")
	var dome := m.world_board.get_node("Thunderdome") as Button
	var neon: Dictionary = layer.thing("dome-neon")
	var under: Vector2 = neon["holder"].position + Vector2(165, 70)
	check(Rect2(dome.position, dome.size).has_point(under), "the neon is over the Thunderdome's button")
	var at: Vector2 = m.world_board.get_global_transform_with_canvas() * under
	var hit := []
	dome.gui_input.connect(func(e): if e is InputEventMouseButton: hit.append(e))
	for down in [true, false]:
		var click := InputEventMouseButton.new()
		click.button_index = MOUSE_BUTTON_LEFT
		click.pressed = down
		click.position = tree.root.get_final_transform() * at
		click.global_position = click.position
		Input.parse_input_event(click)
		Input.flush_buffered_events()
		await tree.process_frame
	check_eq(hit.size(), 2, "the button gets the press and the release")
	_done(made)


func test_relic_library_uses_one_address_and_does_not_gate_a_new_player() -> void:
	var route := MapLink.RELIC_LIBRARY_ROUTE
	check_eq(MapLink.parse("#Relic-Library/"), route)
	check_eq(MapLink.to_hash(route), "#relic-library")
	check_eq(MapLink.scene_for(route), "res://scenes/lesson.tscn")
	var made: Array = await _map(MapLink.WORLD)
	var m: Control = made[1]
	var library := m.world_board.get_node("RelicLibrary") as Button
	check(not library.disabled)
	check_eq(m.world_state("relic_library"), "open")
	check_eq(m.here(), "bazaar", "study does not become a travel location")
	_done(made)


func test_responsive_art_uses_authored_world_registration_and_keeps_every_target() -> void:
	var map_script := preload("res://ui/map.gd")
	var save := SaveData.blank()
	save.settings.reduced_motion = true
	for window in [Vector2i(320, 568), Vector2i(390, 844), Vector2i(900, 650), Vector2i(1440, 900), Vector2i(1920, 1080)]:
		var area := _area(window)
		var wide: bool = window.x > window.y
		var made: Array = await _map(MapLink.WORLD, save, area)
		var m: Control = made[1]
		var board: Control = m.world_board
		var art := board.get_node("Art") as TextureRect
		var frame: Rect2 = m._map_frames[board]
		var active_width: float = (board.get_global_transform_with_canvas() * frame).size.x / area.x
		check(active_width >= (0.895 if wide else 0.98), "uses the width: " + str(window))
		check_eq(art.size, art.texture.get_size(), "never stretches map paint")
		check_eq(m._wide_world, wide, str(window))
		check_eq(m.world_board.find_children("Here", "", true, false).size(), 0)
		var nodes := {"algebra": "Island_algebra", "functions": "Island_functions", "geometry": "Island_geometry",
			"stats": "Island_stats", "calculus": "Island_calculus", "thunderdome": "Thunderdome",
			"relic-library": "RelicLibrary", "bazaar": "Bazaar"}
		for id in nodes:
			var button := board.get_node(nodes[id]) as Button
			var pin := button.get_node("Pin") as Control
			var at := button.position + pin.position + pin.size * 0.5
			check(frame.grow(0.5).encloses(Rect2(button.position, button.size)), id + " target in frame")
			if wide:
				var registered: Vector2 = map_script.WIDE_WORLD[id][1]
				check(at.distance_to(frame.position + frame.size * registered / 100.0) < 0.01, id + " pinned to wide art")
			m.show_card(button)
			var card := board.get_node("Card") as Control
			check(frame.grow(1.0).encloses(Rect2(card.position, card.size)), id + " card fits")
		var ambient := board.get_node("Ambient") as AmbientLayer
		check_eq(ambient.things.size(), 3 if wide else 5)
		check_eq(ambient.thing("engine-smoke").base, Vector2(1058, 677) if wide else Vector2(554, 1003))
		check(not (ambient.thing("engine-smoke").holder as Node2D).visible, "moving smoke is hidden for reduced motion")
		_done(made)


func test_wide_map_ambient_animates_while_the_reduced_motion_map_stays_still() -> void:
	var size := Vector2(2600, 1920)
	for reduce in [false, true]:
		var save := SaveData.blank()
		save.settings.reduced_motion = reduce
		var made: Array = await _map(MapLink.WORLD, save, size)
		var m: Control = made[1]
		var ambient := m.world_board.get_node("Ambient") as AmbientLayer
		var expected := Vector2(1920, 1080)
		check_eq(ambient.size, expected)
		check_eq(AmbientLayer.check(AmbientLayer.entries(m.AMBIENT, "map_wide"), expected), PackedStringArray())
		var smoke := ambient.thing("engine-smoke")
		var crow := ambient.thing("crow")
		check_eq(smoke.base, Vector2(1058, 677))
		var from: Vector2 = crow.holder.position
		var first: int = smoke.frame
		ambient._process(1.0)
		if reduce:
			check_eq(crow.holder.position, from)
			check(not (smoke.holder as Node2D).visible)
		else:
			check((smoke.holder as Node2D).visible and (crow.holder as Node2D).visible)
			check(crow.holder.position.distance_to(from) > 10.0, "crow moved through registered sky")
			check(smoke.frame != first, "stack smoke advances its animation")
			m.save.settings.reduced_motion = true
			m.apply_settings()
			check(ambient.reduced_motion and not (ambient.thing("engine-smoke").holder as Node2D).visible)
		_done(made)


func test_all_five_wide_islands_keep_registered_targets_and_cards_inside() -> void:
	var save := SaveData.blank()
	save.settings.reduced_motion = true
	for window in [Vector2i(900, 650), Vector2i(1440, 900), Vector2i(1920, 1080)]:
		var area := _area(window)
		for id in MapLink.OPEN_ISLANDS:
			var made: Array = await _map({"screen": "island", "island": id}, save, area)
			var m: Control = made[1]
			var board: Control = m.island_board
			var art := board.get_node("Art") as TextureRect
			check_eq(art.texture.resource_path, "res://assets/map/%s/background-wide.webp" % id)
			var frame: Rect2 = m._map_frames[board]
			var playable := 0
			for node in board.get_children():
				if not node is Button or not node.name.begins_with("Spot_"):
					continue
				var b: Button = node
				var center := b.position + b.size / 2.0
				var spot_id := String(b.name).trim_prefix("Spot_")
				check(center.distance_to(m._spot_point(id, spot_id)) < 0.01, str([id, spot_id, "native landmark anchor is unchanged"]))
				check(frame.grow(0.5).encloses(Rect2(b.position, b.size)), str([id, spot_id, "hit target is inside the painting"]))
				m.show_card(b)
				var card := board.get_node("Card") as Control
				check(frame.grow(1.0).encloses(Rect2(card.position, card.size)), str([id, spot_id, "card fits"]))
				if not b.disabled:
					var hit := b.get_global_rect().size * Vector2(window) / area
					check(minf(hit.x, hit.y) >= 44.0, str([id, spot_id, hit]))
					playable += 1
			check_eq(playable, MapLink.region_ids(id).size() + 1, id + " all normal regions plus the island run")
			_done(made)


func test_optional_wide_web_assets_reject_wrong_or_stale_responses() -> void:
	var script := preload("res://ui/map.gd")
	var headers := PackedStringArray(["Content-Type: image/webp"])
	var html := PackedStringArray(["Content-Type: text/html"])
	var ok := HTTPRequest.RESULT_SUCCESS
	check_eq(script.wide_web_path("geometry", "v1.2.0"), "map-art/v1.2.0/geometry.webp")
	check_eq(script.wide_web_path("../outside", "v1.2.0"), "")
	var raw := FileAccess.get_file_as_bytes("res://assets/map/geometry/background-wide.webp")
	var portrait := FileAccess.get_file_as_bytes("res://assets/map/geometry/background.webp")
	var im: Image = script.read_wide_web_image(ok, 200, headers, raw)
	check(im != null and im.get_size() == Vector2i(1920, 1080), "exact optional source")
	check_eq(script.read_wide_web_image(ok, 200, html, raw), null, "do not accept HTML fallback")
	check_eq(script.read_wide_web_image(ok, 404, headers, raw), null)
	check_eq(script.read_wide_web_image(ok, 200, headers, portrait), null, "wrong asset dimensions")
	var large := PackedByteArray()
	large.resize(script.WIDE_ART_LIMIT + 1)
	check_eq(script.read_wide_web_image(ok, 200, headers, large), null, "oversized reply rejected")


func test_layout_completion_waits_until_a_touch_target_is_no_longer_armed() -> void:
	var save := SaveData.blank()
	save.settings.reduced_motion = true
	var made: Array = await _map(MapLink.WORLD, save, _area(Vector2i(900, 650)))
	var m: Control = made[1]
	m.touch = true
	var b := m.world_board.get_node("Island_geometry") as Button
	m.press(b)
	check(m.armed == b and m.card_for == b)
	m._active_touch[7] = true
	m._refresh_on_wide_load()
	check(m._wide_update_waiting and m.armed == b and m.card_for == b)
	m._active_touch.clear()
	m._hide_card()
	await tree.create_timer(0.30).timeout
	check(not m._wide_update_waiting, "a late load resolved after the gesture")
	check(m._wide_world and m.screen == "world")
	_done(made)


func test_landscape_rebuild_preserves_focused_destination_and_card() -> void:
	var save := SaveData.blank()
	save.settings.reduced_motion = true
	var made: Array = await _map(MapLink.WORLD, save, _area(Vector2i(1440, 900)))
	var m: Control = made[1]
	var prior := m.world_board.get_node("Island_geometry") as Button
	prior.grab_focus()
	m.show_card(prior)
	m._rebuild_framed_controls(m.world_board)
	await tree.process_frame
	var restored := m.world_board.get_node("Island_geometry") as Button
	check(restored != prior and restored.has_focus(), "same destination remains focused")
	check(m.card_for == restored and m.world_board.get_node("Card").visible)
	_done(made)
