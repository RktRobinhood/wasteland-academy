extends "res://tests/test_case.gd"
## The journey strip (FAL-331): the sheet loader, the beat picker, the view-only rule,
## the calm rule, the flash limit, reduced motion, a missing avatar sheet, and the demo
## screen at phone and PC sizes.

const DEMO := "res://scenes/journey_demo.tscn"
const STAGE := "res://scenes/journey_stage.tscn"
const DT := 1.0 / 60.0


func _stage() -> JourneyStage:
	var s: JourneyStage = (load(STAGE) as PackedScene).instantiate()
	s.auto_clock = false
	s.size = Vector2(1080, 600)
	return s


## Plays the whole demo script with this listener (or none), frame by frame. Calls
## each(frame) after every frame if given.
func _play(listener: JourneyStage, each: Callable = Callable()) -> JourneyDemoRun:
	var run := JourneyDemoRun.new()
	run.direct = true
	run.listener = listener
	while not run.done:
		run.step(DT)
		if listener != null:
			listener.advance(DT)
		if each.is_valid():
			each.call(run)
	return run


func _json_files(path: String) -> Array:
	var out: Array = []
	for d in DirAccess.get_directories_at(path):
		out += _json_files(path.path_join(d))
	for f in DirAccess.get_files_at(path):
		if f.ends_with(".json"):
			out.append(path.path_join(f))
	return out


# ------------------------------------------------------------------ the loader

func test_loader_reads_every_sheet() -> void:
	var a := JourneyAssets.scan()
	var files := _json_files(JourneyAssets.ROOT)
	check(files.size() >= 30, "found %d journey JSON files; is assets/journey synced? (scripts/godot-env.sh)" % files.size())
	var layers := files.filter(func(f): return f.get_file() == "layers.json").size()
	check_eq(a.sheets.size() + a.weapons.size() + layers, files.size(), "every JSON file is a sheet, weapon or layer list")
	check_eq(a.validate(), PackedStringArray(), "every frame and overlay inside its atlas, every anim frame exists")


func test_loader_finds_sheets_by_folder() -> void:
	var a := JourneyAssets.scan()
	for avatar in ["learner-female", "learner-male"]:
		check(avatar in a.avatars, "avatar %s" % avatar)
	check_eq(a.spark, "spark", "Spark")
	for tier in [1, 2, 3, 4, 5]:
		check(a.enemies.has(tier), "enemy D%d" % tier)
	var r := a.roster("signal-tower")
	check(not r.explore.is_empty() and not r.puzzle.is_empty(), "Explore and Puzzle props: %s" % r)
	check("dishback" in r.creatures, "the region's creature")
	check_eq(r.bosses, {3: 2, 4: 2, 5: 3}, "boss stages")
	check_eq(a.regions["signal-tower"].layers.size(), 3, "three parallax layers")
	for w in ["rebar", "neon-blade", "antenna-spear"]:
		check(a.weapons.has(w), "weapon %s" % w)


## A prop JSON with no `beat` or `states` (before FAL-346): cache-* is Explore,
## obstacle-* is Puzzle, start is the first frame and cleared the second.
func test_props_without_beat_fields() -> void:
	var dir := "user://test_journey_assets"
	DirAccess.make_dir_recursive_absolute(dir + "/test-island")
	var src := JourneyAssets.scan()
	for name in ["cache-vending", "obstacle-livewire"]:
		var data = JSON.parse_string(FileAccess.get_file_as_string(src.sheets[name].json))
		data.erase("beat")
		data.erase("states")
		data.image = ProjectSettings.globalize_path(src.sheets[name].image)
		var f := FileAccess.open(dir + "/test-island/%s.json" % name, FileAccess.WRITE)
		f.store_string(JSON.stringify(data))
		f.close()
	var a := JourneyAssets.scan(dir)
	check_eq(a.sheets["cache-vending"].beat, "explore")
	check_eq(a.sheets["obstacle-livewire"].beat, "puzzle")
	check_eq(a.sheets["cache-vending"].states.start, "closed")
	check_eq(a.sheets["cache-vending"].states.cleared, "open")
	check_eq(a.roster("test-island").explore, ["cache-vending"])
	for name in ["cache-vending", "obstacle-livewire"]:
		DirAccess.remove_absolute(dir + "/test-island/%s.json" % name)
	DirAccess.remove_absolute(dir + "/test-island")
	DirAccess.remove_absolute(dir)


# ------------------------------------------------------------------ beats

func test_beat_choice_is_seeded() -> void:
	var r := JourneyAssets.scan().roster("signal-tower")
	for s in range(1, 40):
		for fight in range(1, 11):
			for tier in range(0, 6):
				check_eq(JourneyBeats.pick(s, fight, 1, tier, r), JourneyBeats.pick(s, fight, 1, tier, r),
						"seed %d fight %d tier %d" % [s, fight, tier])
	var differ := false
	for s in range(2, 40):
		if JourneyBeats.encounter(s, 3, 2, r) != JourneyBeats.encounter(1, 3, 2, r):
			differ = true
	check(differ, "different seeds give different beats")


func test_mini_boss_at_5_boss_at_10() -> void:
	var a := JourneyAssets.scan()
	var r := a.roster("signal-tower")
	for s in range(1, 60):
		for tier in range(0, 6):
			var mini := JourneyBeats.encounter(s, 5, tier, r)
			if tier == 5:
				check_eq(mini.group, ["d5-overseer"], "D5 at fight 5 is the boss")
				continue
			check_eq(mini.kind, "boss", "fight 5 tier %d" % tier)
			check(mini.group[0] in ["d3-enforcer", "d4-warlord"], "mini-boss %s" % mini.group)
			check_eq(mini.stages, 2, "a mini-boss has 2 stages")
			var boss := JourneyBeats.encounter(s, 10, tier, r)
			check_eq(boss.kind, "boss")
			check_eq(boss.group, ["d5-overseer"])
			check_eq(boss.stages, 3)


func test_tier_picks_the_kind() -> void:
	var r := JourneyAssets.scan().roster("signal-tower")
	var seen := {}
	for s in range(1, 300):
		for fight in [1, 2, 3, 4, 6, 7, 8, 9]:
			var d1 := JourneyBeats.encounter(s, fight, 1, r)
			check(not JourneyBeats.has_monster(d1), "a D1 fight shows no monster (seed %d)" % s)
			check_eq(d1.kind, "explore", "D1 is Explore")
			var d2 := JourneyBeats.encounter(s, fight, 2, r)
			check(d2.kind in ["explore", "puzzle"], "D2 is Explore or Puzzle")
			var d4 := JourneyBeats.encounter(s, fight, 4, r)
			check(JourneyBeats.has_monster(d4), "a D4 fight always shows a monster (seed %d)" % s)
			check_eq(d4.group[-1], "d4-warlord", "the Warlord leads D4")
			check(d4.group.size() >= 2 and d4.group.size() <= 3, "D4 has 2-3 monsters")
			var d3 := JourneyBeats.encounter(s, fight, 3, r)
			if d3.kind == "fight":
				check_eq(d3.group[-1], "d3-enforcer", "the Enforcer leads D3")
				check(d3.group.size() <= 2, "D3 has 1-2 monsters")
				var total := 0
				for h in d3.hits:
					total += h
				check_eq(total, 3, "one hit per question")
			var d0 := JourneyBeats.encounter(s, fight, 0, r)
			check(d0.assumed_tier and d0.tier in [1, 2], "no tier is taken as D1 or D2")
			for e in [d1, d2, d3, d4]:
				seen[e.kind + ("-ambush" if e.ambush else "")] = true
	for k in ["explore", "puzzle", "fight", "fight-ambush"]:
		check(seen.has(k), "%s happens" % k)


## The HTML game's island run: D1-D2 for most nodes, D3 every 5th, D5 for the boss.
func test_beat_mix_is_mostly_explore_and_puzzle() -> void:
	var r := JourneyAssets.scan().roster("signal-tower")
	var calm := 0
	var all := 0
	var rng := Seeded.new("beat-mix")
	for run in 1000:
		var run_seed := rng.int_in(1, 1 << 30)
		for fight in range(1, 11):
			var tier := 5 if fight == 10 else (3 if fight % 5 == 0 else rng.int_in(1, 2))
			for q in 3:
				var b := JourneyBeats.pick(run_seed, fight, q, tier, r)
				all += 1
				if b.kind in ["explore", "puzzle"]:
					calm += 1
	check(calm >= 0.7 * all, "%d of %d beats are Explore or Puzzle" % [calm, all])


func test_only_sheets_that_exist() -> void:
	var r := {"explore": ["cache-vending"], "puzzle": [], "creatures": [], "enemies": {1: "d1-scavenger"}, "bosses": {}}
	for s in range(1, 50):
		for fight in range(1, 11):
			for tier in range(0, 6):
				var e := JourneyBeats.encounter(s, fight, tier, r)
				check(e.kind != "boss", "no boss sheet, no boss")
				for m in e.group:
					check_eq(m, "d1-scavenger")
				if e.prop != "":
					check_eq(e.prop, "cache-vending")


# ------------------------------------------------------------------ the rules

func test_view_only() -> void:
	var off := _play(null).save_data()
	var on_stage := _stage()
	tree.root.add_child(on_stage)
	var on := _play(on_stage).save_data()
	var broken_stage := _stage()
	broken_stage.fail_animations = true
	tree.root.add_child(broken_stage)
	var broken := _play(broken_stage).save_data()
	check(off.results.size() >= 20, "the script ran")
	check_eq(on, off, "strip on")
	check_eq(broken, off, "animations failing")
	check(on_stage.flashes.size() > 0, "the strip played")
	check(broken_stage.flashes.is_empty() and not broken_stage.active, "the broken strip played nothing")
	on_stage.free()
	broken_stage.free()


func test_calm_while_a_question_is_open() -> void:
	var s := _stage()
	tree.root.add_child(s)
	var open_frames := [0]
	_play(s, func(run: JourneyDemoRun):
		if not run.card.get("open", false):
			return
		open_frames[0] += 1
		var snap := s.snapshot()
		for a in snap.anims:
			if not a in ["idle", "state"]:
				fail("%.2f s: %s plays while a question is open" % [s.clock, a])
				return
		if snap.flash:
			fail("%.2f s: a flash while a question is open" % s.clock)
		for k in snap.fx:
			if not k in ["ticks", "dials"]:
				fail("%.2f s: effect %s while a question is open" % [s.clock, k]))
	check(open_frames[0] > 1000, "questions were open for %d frames" % open_frames[0])
	s.free()


func test_no_more_than_3_flashes_a_second() -> void:
	var s := _stage()
	tree.root.add_child(s)
	_play(s)
	var f := s.flashes
	check(f.size() >= 10, "the demo flashes on hits (%d)" % f.size())
	for i in f.size():
		var n := 0
		for j in range(i, f.size()):
			if f[j] - f[i] < 1.0:
				n += 1
		check(n <= 3, "%d flashes in the second from %.2f s" % [n, f[i]])
	s.free()


func test_reduced_motion() -> void:
	var s := _stage()
	s.reduced_motion = true
	tree.root.add_child(s)
	var moves := [0]
	var last := [0.0]
	_play(s, func(_run):
		var snap := s.snapshot()
		if absf(snap.cam - last[0]) > 0.001:
			moves[0] += 1
		last[0] = snap.cam
		for sp in snap.sprites:
			if sp.x != sp.home or sp.dy != 0.0 or sp.scale != 1.0:
				fail("%.2f s: %s moves (x %.1f home %.1f dy %.1f scale %.3f)" % [s.clock, sp.sheet, sp.x, sp.home, sp.dy, sp.scale])
				return
			if sp.a != 0.0 and sp.a != 1.0:
				fail("%.2f s: %s fades" % [s.clock, sp.sheet])
				return
		for k in snap.fx:
			if not k in ["ticks", "dials", "banner", "dmg"]:
				fail("%.2f s: effect %s with reduced motion" % [s.clock, k])
				return)
	check(s.flashes.is_empty(), "no flashes with reduced motion")
	# the camera only jumps when an encounter swaps in, it never scrolls
	check(moves[0] <= 12, "the camera moved on %d frames" % moves[0])
	s.free()


func test_no_sheet_for_the_avatar_hides_the_strip() -> void:
	var s := _stage()
	tree.root.add_child(s)
	s.start_run("signal-tower", "learner-nobody", "rebar", 1)
	check(not s.active and not s.visible, "hidden")
	s.fight_started(1, 3, 3)
	s.question_opened(0)
	s.answer_resolved("right")
	s.advance(0.5)
	check(s.snapshot().anims.is_empty(), "plays nothing")
	s.start_run("signal-tower", "learner-male", "rebar", 1)
	check(s.active and s.visible, "shown for an avatar with a sheet")
	s.free()


## Every kind of beat and outcome plays for both Learners with no script errors, and
## each kind shows what it should.
func test_every_beat_plays() -> void:
	for avatar in ["learner-female", "learner-male"]:
		var s := _stage()
		tree.root.add_child(s)
		s.start_run("signal-tower", avatar, "rebar", 3)
		var anims := {}
		var fx := {}
		var fight := 0
		for tier in [1, 2, 3, 4, 5, 0]:
			for kind in ["explore", "puzzle", "fight", "boss"]:
				fight += 1
				var enc := {"kind": kind}
				match kind:
					"explore":
						enc.prop = ["scrap-pile", "mud-stuck", "hatch-locked", "cache-vending"][tier % 4]
					"puzzle":
						enc.prop = ["obstacle-livewire", "vault-dials"][tier % 2]
					"fight":
						enc.group = ["d1-scavenger", "dishback", "d3-enforcer"]
						enc.ambush = tier == 4
					"boss":
						enc.group = ["d5-overseer"]
				s.fight_started(fight, tier, 5, enc)
				for outcome in ["right", "wrong", "timeout", "late", "partial"]:
					s.question_opened(0)
					s.advance(0.1)
					s.answer_resolved(outcome)
					for i in 130:
						s.advance(DT)
						var snap := s.snapshot()
						for a in snap.anims:
							anims[a] = true
						for k in snap.fx:
							fx[k] = true
				s.fight_ended()
				for i in 200:
					s.advance(DT)
					for a in s.snapshot().anims:
						anims[a] = true
		for a in ["walk", "attack", "hurt", "defeated", "victory", "work", "heave", "zap"]:
			check(anims.has(a), "%s: %s pose played" % [avatar, a])
		for k in ["slash", "impact", "zap", "beam", "dust", "loot", "dmg", "ticks", "dials"]:
			check(fx.has(k), "%s: %s effect drawn" % [avatar, k])
		s.free()


# ------------------------------------------------------------------ the demo screen

func _area(window: Vector2i) -> Vector2:
	var base := Vector2(1080, 1920)
	var scale := minf(window.x / base.x, window.y / base.y)
	return Vector2(window) / scale


func test_demo_fits_a_phone_and_a_pc_window() -> void:
	for window in [Vector2i(360, 740), Vector2i(390, 844), Vector2i(1280, 800)]:
		var area := _area(window)
		var frame := Control.new()
		frame.size = area
		tree.root.add_child(frame)
		var demo: Control = (load(DEMO) as PackedScene).instantiate()
		frame.add_child(demo)
		for i in 3:
			await tree.process_frame
		demo.seek(9.0)
		await tree.process_frame
		var strip: JourneyStage = demo.stage
		var screen := Rect2(Vector2.ZERO, area)
		check(strip.active, "%s: strip shown" % window)
		check(strip._width() >= JourneyStage.ACTION_W, "%s: the strip is %.0f units wide" % [window, strip._width()])
		var card := demo.get_node("Column/Margin").get_child(0).get_child(0) as Control
		check(screen.encloses(card.get_global_rect()), "%s: card %s outside %s" % [window, card.get_global_rect(), screen])
		check(screen.encloses(strip.get_global_rect()), "%s: strip outside the screen" % window)
		check(demo.question.text != "…", "%s: a question shows" % window)
		frame.free()
