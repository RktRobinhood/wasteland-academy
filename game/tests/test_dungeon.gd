extends "res://tests/test_case.gd"
## The dungeon (FAL-415): floors by level and the Quadratics floor table, warm-ups and
## prior learning after a miss, the mix (every type on every floor it belongs to),
## enemy tiers, timers by floor, mini-bosses and bosses with follow-through, the start
## floor and the save, the all-regions dungeon, the "boss beaten" event, and a first
## balance check.

const NOW := 1_800_000_000
const REGION := "quadratics"
const Combat := preload("res://tests/test_combat.gd")


func _run(seed_no: int = 42, start_floor: int = 1, save: Dictionary = {}, region: String = REGION) -> Run:
	var r := Run.new(save if not save.is_empty() else SaveData.blank(), region, start_floor, seed_no)
	r.clock = func() -> int: return NOW
	return r


## A player who can't lose HP, so a simulation sees whole floors.
static func immortal(r: Run) -> void:
	r.modifiers.add(func(kind: String, v: float, _ctx: Dictionary) -> float: return 0.0 if kind == "player_damage" else v)


## Plays until the run ends, `floors` floors are done or `most` answers are given.
## Answers right with chance `p` (by the seed), or by `script` (answer index -> right).
static func sim(r: Run, p: float, floors: int = 99, most: int = 2000, script: Callable = Callable()) -> void:
	var rng := Seeded.new("sim|%d|%s" % [r.run_seed, p])
	r.start()
	var i := 0
	while r.state != "ended" and i < most and r.floor_no < r.start_floor + floors:
		var right: bool = script.call(i, r) if script.is_valid() else rng.chance(p)
		r.answer(Combat.respond(r.question, right))
		r.next()
		i += 1
	r.quit()


## Every catalogue cell of the region's types, built or not (for the pure floor rules).
static func catalogue_cells(region: String) -> Array:
	var ids: Array = []
	for t in QuestionEngine.catalogue().types:
		if t.get("region") == region:
			ids.append(t.id)
	return QuestionEngine.cells(false, ids)


static func types_of(cells: Array) -> Array:
	return Dungeon.floor_types(cells)


# ── Floors by level (Q4, FAL-310 "Levels") ───────────────────

func test_floor_bands() -> void:
	check_eq(Dungeon.floor_band(1), [0, 2])
	check_eq(Dungeon.floor_band(2), [2, 3])
	check_eq(Dungeon.floor_band(3), [3, 4])
	for f in [4, 5, 9]:
		check_eq(Dungeon.floor_band(f), [0, 5], "floor %d serves every level" % f)


func test_quadratics_floors_follow_q4() -> void:
	var all := catalogue_cells(REGION)
	var f1 := types_of(Dungeon.filter_floor(all, REGION, 1))
	var f2 := types_of(Dungeon.filter_floor(all, REGION, 2))
	var f3 := types_of(Dungeon.filter_floor(all, REGION, 3))
	# Floor 1: axis and vertex (the features type), plus the level-0 warm-ups.
	check(f1.has("fn-quadratic-features"), "floor 1 has features")
	for id in ["fn-pre-expand", "fn-pre-factorise", "fn-pre-surds", "fn-pre-linear-inequalities"]:
		check(f1.has(id), "floor 1 warms up with %s" % id)
	for id in ["fn-discriminant", "fn-quadratic-inequality", "fn-solve-quadratic", "fn-quadratic-from-conditions"]:
		check(not f1.has(id), "%s is not on floor 1" % id)
	# Floor 2: the three forms and solving.
	for id in ["fn-quadratic-features", "fn-quadratic-from-conditions", "fn-solve-quadratic"]:
		check(f2.has(id), "floor 2 has %s" % id)
	check(not f2.has("fn-discriminant"), "the discriminant waits for floor 3")
	# Floor 3: the discriminant and inequalities.
	for id in ["fn-discriminant", "fn-quadratic-inequality"]:
		check(f3.has(id), "floor 3 has %s" % id)
	# A type new on floor 3 brings its easy cells: "how many roots" is level 1.
	check(Dungeon.filter_floor(all, REGION, 3).any(func(c): return c.unknown == "nature-from-equation"),
		"floor 3 asks how many roots")
	# Floor 4 mixes every type of the region, links included.
	var f4 := types_of(Dungeon.filter_floor(all, REGION, 4))
	check_eq(f4.size(), types_of(all).size(), "floor 4 mixes all")
	check(f4.has("fn-link-symmetry"), "links from floor 4")


func test_floor_1_serves_levels_0_to_2_only() -> void:
	for region in [REGION, "exp-log", "lines"]:
		for c in Dungeon.filter_floor(catalogue_cells(region), region, 1):
			check(Dungeon.level_of(c) <= 2, "%s is level %d on floor 1" % [c.key, Dungeon.level_of(c)])
	# And in play.
	var r := _run(7)
	immortal(r)
	sim(r, 0.8, 1)
	for e in r.answers:
		if e.floor == 1 and e.part < 0:
			check(Dungeon.level_of(_cell(e.cell)) <= 2, "%s on floor 1" % e.cell)


func test_floors_2_and_3_keep_their_top_level() -> void:
	for region in [REGION, "exp-log", "graphs-features"]:
		for f in [2, 3]:
			for c in Dungeon.filter_floor(catalogue_cells(region), region, f):
				check(Dungeon.level_of(c) <= int(Dungeon.floor_band(f)[1]), "%s on floor %d" % [c.key, f])


func test_links_are_level_5_and_only_from_floor_4() -> void:
	var all := catalogue_cells(REGION)
	var links := all.filter(func(c): return Dungeon.is_link(c.type))
	check(not links.is_empty(), "the region has link types")
	for c in links:
		check_eq(Dungeon.level_of(c), 5, c.key)
	for f in [1, 2, 3]:
		check(not Dungeon.filter_floor(all, REGION, f).any(func(c): return Dungeon.is_link(c.type)), "no links on floor %d" % f)
	for f in [4, 6]:
		var lv: Array = Dungeon.filter_floor(all, REGION, f).map(func(c): return Dungeon.level_of(c))
		check(lv.has(5), "floor %d includes level 5" % f)
		check(lv.has(0), "and level 0")


func test_a_region_without_a_table_uses_levels() -> void:
	var all := catalogue_cells("exp-log")
	check(not Tuning.FLOOR_TYPES.has("exp-log"))
	for f in [1, 2, 3]:
		var band := Dungeon.floor_band(f)
		for c in Dungeon.filter_floor(all, "exp-log", f):
			check(Dungeon.level_of(c) >= int(band[0]) and Dungeon.level_of(c) <= int(band[1]), c.key)


func test_built_floors_are_never_empty() -> void:
	for f in range(1, 8):
		check(not Dungeon.floor_cells(REGION, f).is_empty(), "floor %d has questions" % f)


# ── Warm-ups and prior learning (FAL-310) ────────────────────

func test_a_miss_serves_the_prior_learning_it_needs() -> void:
	var ids: Array = []
	for t in QuestionEngine.catalogue().types:
		if t.get("region") == REGION:
			ids.append(t.id)
	var p := Dungeon.prior_for(REGION, "fn-quadratic-features|roots-from-factorised|equation|factorise", "1", ids)
	check(p in ["fn-pre-expand", "fn-pre-factorise"], "factorised form needs expanding or factorising: %s" % p)
	check_eq(Dungeon.prior_for(REGION, "fn-quadratic-features|axis-from-roots|equation|midpoint-of-roots", "1", ids), "",
		"the axis needs no prior learning")
	check_eq(Dungeon.prior_for(REGION, "fn-pre-factorise|monic-trinomial|equation|product-sum", "1", ids), "",
		"not after prior learning itself")
	check_eq(Dungeon.prior_for(REGION, "fn-solve-quadratic|solve-hidden-log|equation|any", "1", ids), "fn-pre-factorise")


## Warm-ups and prior learning in play, where the region has prior-learning types built
## (FAL-414 builds Quadratics'). Until then the first fight is the planner's.
func test_floor_1_opens_with_warm_ups() -> void:
	var r := _run(3)
	immortal(r)
	sim(r, 0.0, 1, 30)
	var prior := Dungeon.prior_cells(REGION)
	if prior.is_empty():
		check(r.answers.all(func(e): return e.rule != "warm-up"), "no warm-ups without prior learning built")
		return
	for i in Tuning.WARMUPS:
		check_eq(r.answers[i].rule, "warm-up")
		check(Dungeon.is_prior(_cell(r.answers[i].cell).type), r.answers[i].cell)
	check(r.answers.any(func(e): return e.rule == "prior"), "a miss brings prior learning back")


func test_no_warm_ups_from_a_deeper_floor() -> void:
	var save := SaveData.blank()
	var r := _run(3, 2, save)
	immortal(r)
	sim(r, 1.0, 1, 10)
	check(r.answers.all(func(e): return e.rule != "warm-up"))


# ── The mix (Q14) ────────────────────────────────────────────

func test_every_type_appears_on_every_floor_it_belongs_to() -> void:
	var floors := 0
	var seed_no := 1
	while floors < 200:
		var r := _run(seed_no, 1 + seed_no % 4)
		immortal(r)
		sim(r, 0.7, 2)
		for f in [r.start_floor, r.start_floor + 1]:
			var want := types_of(Dungeon.floor_cells(REGION, f))
			var got: Array = r.answers.filter(func(e): return e.floor == f).map(func(e): return _cell(e.cell).type)
			for t in want:
				check(got.has(t), "seed %d floor %d: %s never came up" % [seed_no, f, t])
			floors += 1
		seed_no += 1


func test_exam_only_keeps_exam_cells_on_floors() -> void:
	var save := SaveData.blank()
	save.settings.exam_only = true
	var r := _run(9, 1, save)
	immortal(r)
	sim(r, 0.7, 1)
	for e in r.answers:
		check(QuestionEngine.cells(true).any(func(c): return c.key == e.cell), "%s is an exam cell" % e.cell)


# ── Enemy tiers and timers ───────────────────────────────────

func test_tiers_by_fight_and_floor() -> void:
	for s in [1, 42, 999]:
		for f in [1, 2, 3]:
			for n in range(1, 11):
				var t := Dungeon.tier_for(s, f, n)
				check_eq(t, Dungeon.tier_for(s, f, n), "deterministic")
				match n:
					5:
						check_eq(t, 3, "the mini-boss is D3")
					10:
						check_eq(t, 5, "the boss is D5")
					_:
						check(t in [1, 2], "floor %d fight %d: D%d" % [f, n, t])
		check(range(1, 11).map(func(n): return Dungeon.tier_for(s, 4, n)).all(func(t): return t >= 2), "floor 4 raises D1")
		check_eq(Dungeon.tier_for(s, 4, 5), 4, "floor 4's mini-boss is D4")
		check(range(1, 11).map(func(n): return Dungeon.tier_for(s, 8, n)).all(func(t): return t >= 4), "floor 8 is D4-D5")
		for n in range(1, 11):
			check(Dungeon.tier_for(s, 30, n) <= 5, "never past D5")
	check_eq(Tuning.damage_on(25, 3), 25)
	check_eq(Tuning.damage_on(25, 4), 28)
	check(Tuning.damage_on(45, 9) > Tuning.damage_on(45, 6), "deeper hurts more")


func test_the_run_uses_the_floor_tier_and_timer() -> void:
	var r := _run(11, 3)
	immortal(r)
	r.start()
	var seen := {}
	var i := 0
	while r.state != "ended" and i < 200 and r.floor_no <= 4:
		check_eq(r.tier, Dungeon.tier_for(11, r.floor_no, r.fight), "floor %d fight %d" % [r.floor_no, r.fight])
		var marks: int = r.question.marks if r.question.marks > 0 else Tuning.DEFAULT_MARKS
		check_eq(r.time_total, float(Tuning.seconds_for(marks, r.floor_no, r.question.format == "value")),
			"floor %d timer" % r.floor_no)
		check_eq(r.slot, Run.slot_kind(11, r.floor_no, r.fight), "the slot picker for every slot")
		seen[r.floor_no] = true
		r.answer(Combat.respond(r.question, true))
		r.next()
		i += 1
	check(seen.has(3) and seen.has(4), "played floors 3 and 4")


# ── Mini-bosses and bosses (Q9) ──────────────────────────────

func test_the_same_seed_gives_the_same_floors_fights_and_bosses() -> void:
	var a := _run(21)
	immortal(a)
	sim(a, 0.6, 2)
	var b := _run(21)
	immortal(b)
	sim(b, 0.6, 2)
	check(a.answers.size() > 40, "two floors played")
	check_eq(b.answers, a.answers, "same floors, fights, parts and results")
	check_eq(JSON.stringify(b.save), JSON.stringify(a.save), "same save")
	var c := _run(22)
	immortal(c)
	sim(c, 0.6, 2)
	check(c.answers.map(func(e): return e.cell) != a.answers.map(func(e): return e.cell), "another seed, another dungeon")


func test_fight_5_is_a_mini_boss_and_fight_10_a_boss() -> void:
	var sizes := {}
	for s in range(1, 16):
		var r := _run(s, 1 + s % 2)
		immortal(r)
		r.start()
		var guard := 0
		while r.state != "ended" and guard < 300 and r.floor_no == r.start_floor:
			if r.kind != "fight":
				check(not r.boss.is_empty(), "Quadratics has chains: fight %d is a real boss" % r.fight)
			if r.question.has("part") and r.question.part == 0:
				check(r.kind in ["mini", "boss"], "parts only in a boss fight")
				check_eq(r.fight, Tuning.MINI_BOSS_AT if r.kind == "mini" else Tuning.FIGHTS_PER_FLOOR)
				_check_boss(r)
				var chained: int = r.boss.parts.size() - (1 if r.boss.link else 0)
				if r.kind == "mini":
					check_eq(chained, 2, "a mini-boss asks 2 parts")
				else:
					check(chained in [3, 4], "a boss asks 3 or 4 parts: %d" % chained)
					sizes[chained] = true
			r.answer(Combat.respond(r.question, true))
			r.next()
			guard += 1
		check(r.floor_no > r.start_floor, "seed %d cleared the floor" % s)
	check(sizes.has(3) and sizes.has(4), "bosses of 3 and of 4 parts")


## The open boss's parts: one situation, consecutive steps of its type's chain.
func _check_boss(r: Run) -> void:
	var parts: Array = r.boss.parts.slice(0, r.boss.parts.size() - (1 if r.boss.link else 0))
	var chain: Array = Dungeon.chain_steps(r.boss.type).map(func(st): return "%s:%s" % [st.type, st.unknown])
	var steps: Array = parts.map(func(q): return "%s:%s" % [q.view.type, q.view.unknown])
	var at := chain.find(steps[0])
	check(at >= 0, "%s starts the chain of %s" % [steps[0], r.boss.type])
	check_eq(steps, chain.slice(at, at + steps.size()), "the parts follow the chain")
	for q in parts:
		check_eq(q.situation, parts[0].situation, "one situation")
		check_eq(q.situation_id, parts[0].situation_id)


func test_every_chain_makes_on_one_situation() -> void:
	for id in Tuning.CHAINS:
		var chain := Dungeon.chain_steps(id)
		if chain.is_empty():
			continue
		check(chain.size() >= 2, "%s chains at least 2 parts" % id)
		for seed_no in range(1, 41):
			for at in chain.size() - 1:
				var n := mini(4, chain.size() - at)
				var steps: Array = chain.slice(at, at + n).map(func(st): return st.merged({"format": "mcq" if seed_no % 2 else "value"}))
				var c := QuestionEngine.make_chain(steps, seed_no)
				check(not c.has("error"), "%s from %d seed %d: %s" % [id, at, seed_no, c.get("error", "")])


func test_follow_through_after_a_wrong_part() -> void:
	var checked := 0
	for s in range(1, 13):
		var r := _run(s)
		immortal(r)
		r.start()
		var guard := 0
		while r.state != "ended" and guard < 300 and r.floor_no == 1:
			var in_boss := not r.boss.is_empty()
			var q := r.question
			var res := r.answer(Combat.respond(q, not in_boss))
			if in_boss and res.part < r.boss.parts.size() - 1 and r.boss.parts[res.part + 1].has("carried"):
				var nxt: Dictionary = r.boss.parts[res.part + 1]
				check_eq(res.outcome, "wrong")
				check(not res.solution.is_empty(), "the right working shows")
				check_eq(res.carry, q.answer_text, "the right value is what carries")
				check_eq(nxt.carried.values, q.answer.values, "the next part's given value is the right one")
				check_eq(nxt.carried.part, QuestionEngine.part_letter(res.part))
				check_eq(nxt.situation, q.situation, "on the same situation")
				checked += 1
			check(not (in_boss and res.dead), "immortal")
			r.next()
			guard += 1
		check(r.stats.minis == 1 and r.stats.bosses == 1, "seed %d: surviving every part beats them, even all wrong" % s)
	check(checked > 20, "follow-through checked %d times" % checked)


func test_a_wrong_part_costs_hp_and_each_part_has_its_own_clock() -> void:
	var r := _run(4)
	r.start()
	var guard := 0
	while r.boss.is_empty() and guard < 100:
		r.answer(Combat.respond(r.question, true))
		r.next()
		guard += 1
	check_eq(r.kind, "mini")
	check_eq(r.enemy.max_hp, r.boss.parts.size() * Tuning.HIT, "the bar counts parts")
	var before := r.hp
	var q := r.question
	var marks: int = q.marks if q.marks > 0 else Tuning.DEFAULT_MARKS
	check_eq(r.time_total, float(Tuning.seconds_for(marks, 1, q.format == "value")), "part (a)'s clock")
	r.tick(r.time_total * 0.5)
	var res := r.answer(Combat.respond(q, false))
	check_eq(res.player_damage, r.enemy.damage, "a wrong part costs the tier's damage")
	check_eq(r.hp, before - r.enemy.damage)
	check(not res.defeated)
	r.next()
	check_eq(r.boss.part, 1)
	var q2 := r.question
	var marks2: int = q2.marks if q2.marks > 0 else Tuning.DEFAULT_MARKS
	check_eq(r.time_left, float(Tuning.seconds_for(marks2, 1, q2.format == "value")), "part (b) starts a full clock")
	res = r.answer(Combat.respond(q2, true))
	check(res.defeated, "survived both parts")
	check(res.scrap > 0, "a right part earns Scrap")


func test_dying_on_a_part_does_not_beat_the_boss() -> void:
	var r := _run(4)
	r.start()
	var guard := 0
	while r.boss.is_empty() and guard < 100:
		r.answer(Combat.respond(r.question, true))
		r.next()
		guard += 1
	r.hp = 1
	r.answer(Combat.respond(r.question, false))
	r.next()
	check_eq(r.state, "ended")
	check_eq(r.stats.minis, 0)


# ── The start floor and the save ─────────────────────────────

func test_the_start_floor_rule() -> void:
	var save := SaveData.blank()
	check_eq(Dungeon.start_floors(save, REGION), [1], "a fresh save starts on floor 1")
	var r := _run(31, 1, save)
	immortal(r)
	sim(r, 1.0, 2)
	check_eq(Dungeon.start_floors(save, REGION), [1, 2], "floors whose boss fell")
	check_eq(Dungeon.record(save, REGION).best, 3, "the best floor reached")
	check_eq(Dungeon.start_floors(save, "exp-log"), [1], "per region")
	# Reaching a floor without beating its boss offers nothing more.
	var r2 := _run(32, 2, save)
	r2.start()
	while r2.state != "ended":
		r2.answer(Combat.respond(r2.question, false))
		r2.next()
	check_eq(Dungeon.start_floors(save, REGION), [1, 2])
	# It survives a store and load, with JSON's floats.
	var path := "user://test_dungeon_save.json"
	SaveData.store(save, path)
	var back := SaveData.load_from(path)
	check_eq(Dungeon.start_floors(back, REGION), [1, 2])
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	Dungeon.note_floor(back, REGION, 2, true)
	check_eq(Dungeon.record(back, REGION).beaten, [1, 2], "no repeats")


func test_a_jumped_run_records_nothing() -> void:
	var save := SaveData.blank()
	var r := _run(33, 1, save)
	r.records = false
	r.first_fight = 10
	immortal(r)
	sim(r, 1.0, 1)
	check(r.stats.bosses == 1, "the boss fell")
	check_eq(Dungeon.start_floors(save, REGION), [1], "but unlocked nothing")


func test_a_version_2_save_gets_a_dungeon_record() -> void:
	var v2 := {"version": 2, "settings": {"exam_only": false}, "cells": {}, "probes": {}, "history": [], "seed": 4,
		"class": null, "trees": {}, "lessons": {}, "scrap": 70, "runs": {"played": 2}}
	var s := SaveData.migrate(v2)
	check_eq(s.version, SaveData.VERSION)
	check_eq(s.dungeon, {})
	check_eq(s.scrap, 70)
	check_eq(Dungeon.start_floors(s, REGION), [1])


# ── The all-regions dungeon ──────────────────────────────────

func test_the_all_regions_dungeon_mixes_every_built_region() -> void:
	var all := Dungeon.region_types(Dungeon.ALL)
	var regions := {}
	for id in all:
		var reg = QuestionEngine.type_of(id).get("region")
		check(reg != null, "%s is on the island" % id)
		regions[reg] = true
	for r in QuestionEngine.catalogue().regions:
		for id in Dungeon.region_types(r.id):
			check(all.has(id), "%s is in the all-regions dungeon" % id)
	check(not all.has("t1-arithmetic-sequence"), "other topics stay out")
	var run := _run(5, 1, {}, Dungeon.ALL)
	immortal(run)
	sim(run, 0.8, 1)
	check(run.stats.bosses == 1, "it has a boss")
	for e in run.answers:
		check(all.has(_cell(e.cell).type), e.cell)
	check_eq(Dungeon.region_name(Dungeon.ALL), "All regions")


# ── The "boss beaten" event ──────────────────────────────────

func test_boss_beaten_goes_through_the_modifiers() -> void:
	var r := _run(8)
	var events: Array = []
	r.boss_beaten.connect(func(f, k): events.append([f, k, r.hp]))
	var calls: Array = []
	# Second Wind (G6): heal 20 after each boss.
	r.modifiers.add(func(kind: String, v: float, ctx: Dictionary) -> float:
		if kind == "boss_heal":
			calls.append(ctx.duplicate())
			return v + 20.0
		return v)
	r.start()
	var guard := 0
	var hp_before := 0
	while r.state != "ended" and guard < 300 and r.floor_no == 1:
		if not r.boss.is_empty() and r.boss.part == r.boss.parts.size() - 1:
			r.hp = 50
			hp_before = r.hp
		var res := r.answer(Combat.respond(r.question, true))
		if res.defeated and res.part >= 0:
			check_eq(res.healed, 20, "Second Wind heals 20")
			check_eq(r.hp, hp_before + 20)
		r.next()
		guard += 1
	check_eq(events.map(func(e): return [e[0], e[1]]), [[1, "mini"], [1, "boss"]], "the event fires for each")
	check_eq(calls.map(func(c): return c.boss), ["mini", "boss"])
	check_eq(calls[1].floor, 1)
	var plain := _run(8)
	plain.start()
	check_eq(plain.modifiers.apply("boss_heal", Tuning.BOSS_HEAL, {}), 0.0, "no heal without a perk")


# ── A first balance check ────────────────────────────────────

## Simulated players who answer 50%, 70% and 90% right, from floor 1 with a fresh save,
## until they die. Prints the average floor reached and the Scrap per run; the Bazaar
## (G6) prices from the 70% figure.
func test_balance_check() -> void:
	var runs := 100
	var out := {}
	for p in [0.5, 0.7, 0.9]:
		var floors := 0.0
		var scrap := 0.0
		var fights := 0.0
		var cleared := 0
		for i in runs:
			var r := _run(1000 + i)
			sim(r, p)
			floors += r.summary.floor
			scrap += r.summary.scrap
			fights += r.summary.fights_won
			cleared += r.summary.bosses
		out[p] = {"floor": floors / runs, "scrap": scrap / runs, "fights": fights / runs, "bosses": float(cleared) / runs}
		print("balance: %d%% right: average floor %.2f, fights won %.1f, floors cleared %.2f, Scrap per run %.0f (%d runs)" %
			[roundi(p * 100), out[p].floor, out[p].fights, out[p].bosses, out[p].scrap, runs])
	check(out[0.5].fights <= out[0.7].fights and out[0.7].fights <= out[0.9].fights, "better players get further")
	check(out[0.7].scrap > 0, "a 70% player earns Scrap")


static func _cell(key: String) -> Dictionary:
	var b := key.split("|")
	var t := QuestionEngine.type_of(b[0])
	return {"key": key, "type": b[0], "unknown": b[1], "level": int(QuestionEngine.unknown_of(t, b[1]).get("level", 0))}
