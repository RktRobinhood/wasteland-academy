extends "res://tests/test_case.gd"
## The Bazaar (FAL-416): upgrades stop at their caps, each perk changes only its own
## value through the modifiers step and is used up after one run, Scrap never goes
## negative and a failed purchase changes nothing, the save keeps what was bought (with
## the migration), and a simulated 70% player unlocks something every 2 or 3 runs. The
## screen shops, wears and fits a phone and a PC window.

const Combat := preload("res://tests/test_combat.gd")
const Sim := preload("res://tools/bazaar_sim.gd")
const BAZAAR := "res://scenes/bazaar.tscn"
const SAVE := "user://test_bazaar_save.json"
const NOW := 1_800_000_000


func _rich(scrap: int = 100_000) -> Dictionary:
	var s := SaveData.blank()
	s.scrap = scrap
	return s


## A run on save, with what the Bazaar sold, started.
func _run(save: Dictionary, seed_no: int = 42) -> Run:
	var r := Run.new(save, "quadratics", 1, seed_no)
	r.clock = func() -> int: return NOW
	Bazaar.equip(r, save)
	r.start()
	return r


func _snapshot(save: Dictionary) -> String:
	return JSON.stringify(save)


# ── Upgrades ─────────────────────────────────────────────────

func test_max_hp_stops_at_its_cap() -> void:
	var s := _rich()
	check_eq(_run(s.duplicate(true)).max_hp, 100, "no upgrade")
	for i in 3:
		check(Bazaar.buy(s, "max_hp").ok, "level %d" % (i + 1))
		check_eq(_run(s.duplicate(true)).max_hp, 110 + 10 * i)
	var before := _snapshot(s)
	var r := Bazaar.buy(s, "max_hp")
	check(not r.ok, "a fourth level")
	check_eq(r.reason, Bazaar.CAPPED)
	check_eq(_snapshot(s), before, "the capped buy changed nothing")
	check_eq(Bazaar.price(s, "max_hp"), -1)
	check_eq(_run(s).max_hp, 130, "100 to 130")


func test_lifeline_charges_stop_at_their_cap() -> void:
	var s := _rich()
	check(Bazaar.buy(s, "lifeline", "freeze").ok)
	check(Bazaar.buy(s, "lifeline", "freeze").ok, "the same lifeline twice")
	var before := _snapshot(s)
	for id in ["fifty", "hint", "freeze"]:
		var r := Bazaar.buy(s, "lifeline", id)
		check(not r.ok, "a third charge on %s" % id)
		check_eq(r.reason, Bazaar.CAPPED)
	check_eq(_snapshot(s), before)
	check_eq(_run(s).lifelines, {"fifty": 1, "hint": 1, "freeze": 3})
	var t := _rich()
	Bazaar.buy(t, "lifeline", "fifty")
	Bazaar.buy(t, "lifeline", "hint")
	check_eq(_run(t).lifelines, {"fifty": 2, "hint": 2, "freeze": 1}, "two lifelines, one each")


func test_the_lifeline_upgrade_needs_a_lifeline() -> void:
	var s := _rich()
	var before := _snapshot(s)
	for bad in ["", "shield"]:
		var r := Bazaar.buy(s, "lifeline", bad)
		check(not r.ok)
		check_eq(r.reason, Bazaar.PICK)
	check_eq(_snapshot(s), before)


func test_each_level_costs_its_price() -> void:
	var s := _rich(10_000)
	var paid := 0
	for item in ["max_hp", "lifeline"]:
		for i in Bazaar.cap(item):
			var want: int = Tuning.UPGRADES[item][i]
			check_eq(Bazaar.price(s, item), want, "%s level %d" % [item, i + 1])
			check_eq(Bazaar.buy(s, item, "hint").price, want)
			paid += want
	check_eq(int(s.scrap), 10_000 - paid)
	check_eq(int(s.bazaar.spent), paid)


# ── Perks ────────────────────────────────────────────────────

## Every kind the modifiers step has, in every context a run gives it.
func _probe_values(m: Callable) -> Dictionary:
	var mods := Modifiers.new()
	mods.add(m)
	var out := {}
	var ctxs := [{}, {"freeze": true}, {"boss": "mini"}, {"boss": "boss"}]
	for o in Tuning.OUTCOMES:
		ctxs.append({"outcome": o, "tier": 2, "floor": 1, "fight": 3})
	for l in Bazaar.LIFELINE_NAMES:
		ctxs.append({"lifeline": l})
	for kind in Modifiers.KINDS:
		for ctx in ctxs:
			for base in [0.0, 1.0, 20.0, 100.0]:
				out["%s %s %s" % [kind, JSON.stringify(ctx), base]] = mods.apply(kind, base, ctx)
	return out


func test_each_perk_changes_exactly_its_own_value() -> void:
	var rec := SaveData.blank_bazaar()
	var plain := _probe_values(Bazaar.modifier(rec, {}))
	# kind and context of every value each perk may change, and by how much.
	var expect := {
		"field_manual": func(kind, ctx, base): return 0.0 if kind == "lifeline_cost" and ctx.get("lifeline") == "hint" else base,
		"scrap_armour": func(kind, _ctx, base): return base + 20.0 if kind == "max_hp" else base,
		"lucky_find": func(kind, ctx, base): return base + 1.0 if kind == "lifelines" and ctx.get("lifeline") == "freeze" else base,
		"second_wind": func(kind, ctx, base): return base + 20.0 if kind == "boss_heal" and ctx.get("boss") == "boss" else base,
		"field_watch": func(kind, ctx, base): return base + 10.0 if kind == "time" and not ctx.get("freeze", false) else base,
	}
	for id in Bazaar.PERKS:
		var got := _probe_values(Bazaar.modifier(rec, {"id": id, "lifeline": "freeze" if id == "lucky_find" else ""}))
		var changed := 0
		for key in got:
			var parts: PackedStringArray = key.split(" ", true, 1)
			var rest := parts[1]
			var cut := rest.rfind(" ")
			var ctx: Dictionary = JSON.parse_string(rest.substr(0, cut))
			var base := float(rest.substr(cut + 1))
			var want: float = expect[id].call(parts[0], ctx, base)
			check_eq(got[key], want, "%s: %s" % [id, key])
			if got[key] != plain[key]:
				changed += 1
		check(changed > 0, "%s changes something" % id)


func test_each_perk_in_a_run() -> void:
	var plain := _run(SaveData.blank())
	for id in Bazaar.PERKS:
		var s := _rich()
		check(Bazaar.buy(s, id, "hint" if id in Bazaar.PICK_LIFELINE else "").ok, id)
		var r := _run(s)
		match id:
			"scrap_armour":
				check_eq([r.max_hp, r.hp], [120, 120], "Scrap Armour")
			"lucky_find":
				check_eq(r.lifelines, {"fifty": 1, "hint": 2, "freeze": 1}, "Lucky Find on Hint")
			"field_watch":
				check_eq(r.time_total, plain.time_total + 10.0, "Field Watch")
				check_eq(r.use_freeze(), Tuning.FREEZE_SECONDS, "Field Watch leaves Time Freeze alone")
			"field_manual":
				check_eq(r.lifeline_cost("hint"), 0)
				check(r.use_hint() != "", "a free hint")
				check_eq(r.lifelines.hint, 1, "it spent no charge")
				check_eq(r.lifeline_cost("fifty"), 1, "other lifelines still cost")
			"second_wind":
				# G4's "boss beaten" event sends its heal through boss_heal.
				check_eq(r.modifiers.apply("boss_heal", 0, {"boss": "boss"}), 20.0, "Second Wind")
				check_eq(r.modifiers.apply("boss_heal", 0, {"boss": "mini"}), 0.0, "not after a mini-boss")
		if id != "scrap_armour":
			check_eq(r.max_hp, 100, id)
		if id != "field_watch":
			check_eq(r.time_total, plain.time_total, id)


func test_second_wind_heals_after_the_boss_in_a_run() -> void:
	var s := _rich()
	Bazaar.buy(s, "second_wind")
	var r := Run.new(s, "quadratics", 1, 8)
	r.clock = func() -> int: return NOW
	Bazaar.equip(r, s)
	r.start()
	var healed := {}
	var guard := 0
	while r.state != "ended" and guard < 300 and r.floor_no == 1:
		if not r.boss.is_empty() and r.boss.part == r.boss.parts.size() - 1:
			r.hp = 50
		var res := r.answer(Combat.respond(r.question, true))
		if res.defeated and res.part >= 0:
			healed[r.kind] = res.healed
			check_eq(r.hp, 50 + res.healed, r.kind)
		r.next()
		guard += 1
	check_eq(healed, {"mini": 0, "boss": Tuning.PERK_SECOND_WIND_HP}, "after the boss, not the mini-boss")


func test_a_perk_is_used_up_after_one_run() -> void:
	for id in Bazaar.PERKS:
		var s := _rich()
		Bazaar.buy(s, id, "freeze")
		var first := Run.new(s, "quadratics", 1, 7)
		var perk := Bazaar.equip(first, s)
		check_eq(perk.id, id)
		check(s.bazaar.perk.is_empty(), "%s: the slot empties when the run starts" % id)
		first.clock = func() -> int: return NOW
		Combat.play(first)
		var second := Run.new(s, "quadratics", 1, 7)
		check(Bazaar.equip(second, s).is_empty(), "%s: no perk on the next run" % id)
		var plain := Modifiers.new()
		plain.add(Bazaar.modifier(SaveData.blank_bazaar(), {}))
		check_eq(_probe_values(func(k, v, c): return second.modifiers.apply(k, v, c)),
				_probe_values(func(k, v, c): return plain.apply(k, v, c)), "%s: the next run plays plain" % id)


func test_a_run_that_records_nothing_keeps_the_perk() -> void:
	var s := _rich()
	Bazaar.buy(s, "scrap_armour")
	var link := Run.new(s, "quadratics", 1, 7)
	link.records = false
	check_eq(Bazaar.equip(link, s).id, "scrap_armour", "the linked run plays with it")
	check_eq(s.bazaar.perk.id, "scrap_armour", "and leaves it in the slot")
	check_eq(Bazaar.equip(Run.new(s, "quadratics", 1, 7), s).id, "scrap_armour", "a real run gets it")
	check(s.bazaar.perk.is_empty(), "and uses it up")


func test_one_perk_slot() -> void:
	var s := _rich()
	check(Bazaar.buy(s, "field_watch").ok)
	var before := _snapshot(s)
	for id in Bazaar.PERKS:
		var r := Bazaar.buy(s, id, "hint")
		check(not r.ok, id)
		check_eq(r.reason, Bazaar.SLOT_FULL)
	check_eq(_snapshot(s), before)
	check_eq(Bazaar.buy(s, "lucky_find").reason, Bazaar.SLOT_FULL)
	var t := _rich()
	check_eq(Bazaar.buy(t, "lucky_find").reason, Bazaar.PICK, "Lucky Find needs a lifeline")


func test_upgrades_and_a_perk_together() -> void:
	var s := _rich()
	Bazaar.buy(s, "max_hp")
	Bazaar.buy(s, "max_hp")
	Bazaar.buy(s, "lifeline", "hint")
	Bazaar.buy(s, "scrap_armour")
	var r := _run(s)
	check_eq(r.max_hp, 140, "100 + 2 levels + Scrap Armour")
	check_eq(r.lifelines.hint, 2)
	var next := _run(s)
	check_eq(next.max_hp, 120, "the upgrades stay, the perk is gone")


# ── Scrap ────────────────────────────────────────────────────

func test_a_purchase_without_the_scrap_changes_nothing() -> void:
	var items := ["max_hp", "frame:signal", "tint:rust"] + Bazaar.PERKS.keys()
	for item in items:
		var s := _rich(Bazaar.price(SaveData.blank(), item) - 1)
		var before := _snapshot(s)
		var r := Bazaar.buy(s, item, "hint")
		check(not r.ok, item)
		check_eq(r.reason, Bazaar.NOT_ENOUGH, item)
		check_eq(_snapshot(s), before, item)
		s.scrap = int(s.scrap) + 1
		check(Bazaar.buy(s, item, "hint").ok, "%s with exactly enough" % item)
		check_eq(int(s.scrap), 0)


func test_scrap_never_goes_negative() -> void:
	var rng := Seeded.new("bazaar-fuzz")
	var items: Array = ["max_hp", "lifeline", "nonsense", "frame:", "tint:gold"] + Bazaar.PERKS.keys() + Bazaar.cosmetics()
	var lifelines := ["", "fifty", "hint", "freeze", "nope"]
	var s := _rich(0)
	for i in 2000:
		if i % 7 == 0:
			s.scrap = int(s.scrap) + rng.int_in(0, 600)
		if i % 50 == 0:
			Bazaar.equip(Run.new(s, "quadratics", 1, i), s)
		var before := _snapshot(s)
		var r := Bazaar.buy(s, rng.pick(items), rng.pick(lifelines))
		check(int(s.scrap) >= 0, "Scrap %d after try %d" % [int(s.scrap), i])
		if not r.ok:
			check_eq(_snapshot(s), before, "a failed purchase on try %d" % i)
	check(Bazaar.level(s, "max_hp") <= 3)
	check(Bazaar.level(s, "lifeline") <= 2)


func test_cosmetics_are_bought_once_and_worn() -> void:
	var s := _rich(Tuning.COSMETIC_PRICE * 2)
	check(not Bazaar.wear(s, "frame:brass"), "not owned yet")
	check_eq(s.bazaar.frame, "")
	check(Bazaar.buy(s, "frame:brass").ok)
	check_eq(s.bazaar.frame, "brass", "bought is worn")
	var r := Bazaar.buy(s, "frame:brass")
	check_eq(r.reason, Bazaar.OWNED)
	check(Bazaar.buy(s, "tint:chrome").ok)
	check(Bazaar.wear(s, "frame:"), "back to plain")
	check_eq([s.bazaar.frame, s.bazaar.tint], ["", "chrome"])
	check_eq(int(s.scrap), 0)
	check_eq(Bazaar.buy(s, "frame:gold").reason, Bazaar.UNKNOWN)
	var plain := _run(_rich())
	var dressed := _run(s)
	check_eq(dressed.max_hp, plain.max_hp, "cosmetics are looks only")
	check_eq(dressed.lifelines, plain.lifelines)


# ── The save ─────────────────────────────────────────────────

func test_the_save_keeps_what_was_bought() -> void:
	var path := "user://test_bazaar_roundtrip.json"
	var s := _rich(5000)
	Bazaar.buy(s, "max_hp")
	Bazaar.buy(s, "lifeline", "fifty")
	Bazaar.buy(s, "lucky_find", "freeze")
	Bazaar.buy(s, "tint:magenta")
	check(SaveData.store(s, path))
	var back := SaveData.load_from(path)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	check_eq(int(back.version), SaveData.VERSION)
	check_eq(int(back.scrap), int(s.scrap))
	check_eq(Bazaar.level(back, "max_hp"), 1)
	check_eq(Bazaar.level(back, "lifeline"), 1)
	check_eq(back.bazaar.perk, {"id": "lucky_find", "lifeline": "freeze"})
	check_eq(back.bazaar.owned, ["tint:magenta"])
	check_eq(back.bazaar.tint, "magenta")
	var r := _run(back)
	check_eq(r.max_hp, 110)
	check_eq(r.lifelines, {"fifty": 2, "hint": 1, "freeze": 2})


func test_an_older_save_is_migrated() -> void:
	var v2 := {"version": 2, "settings": {"exam_only": true}, "cells": {}, "probes": {}, "history": [], "seed": 3,
		"class": null, "trees": {}, "lessons": {}, "scrap": 640, "runs": {"played": 2, "best_fights": 3, "questions": 30, "right": 20}}
	var m := SaveData.migrate(v2)
	check_eq(int(m.version), SaveData.VERSION)
	check_eq(m.bazaar, SaveData.blank_bazaar(), "nothing bought yet")
	check_eq(int(m.scrap), 640, "the Scrap banked is kept to spend")
	check_eq(m.settings.exam_only, true)
	var v0 := SaveData.migrate({"cells": {}})
	check_eq(v0.bazaar, SaveData.blank_bazaar(), "from a version 0 save too")
	check_eq(int(v0.scrap), 0)
	# A record missing fields (hand-edited, or from a newer build) is filled in.
	var odd := SaveData.blank()
	odd.bazaar = {"max_hp": 2, "lifelines": {"hint": 1}}
	var rec := Bazaar.record(odd)
	check_eq(rec.lifelines, {"hint": 1, "fifty": 0, "freeze": 0})
	check_eq(rec.perk, {})
	check_eq(_run(odd).max_hp, 120)


# ── Balance ──────────────────────────────────────────────────

func test_a_70_percent_player_unlocks_something_every_2_or_3_runs() -> void:
	var r: Dictionary = Sim.simulate(4, 0.7)
	check_eq(r.unlocked, 4 * Sim.unlocks().size(), "every unlock is reached")
	check(r.runs_per_unlock >= 2.0 and r.runs_per_unlock <= 3.0, "%.2f runs per unlock" % r.runs_per_unlock)
	for item in r.by_item:
		check(r.by_item[item] <= 3.5, "%s took %.2f runs" % [item, r.by_item[item]])
	# The figure the prices were set from is still near what a run pays.
	check(absf(r.scrap_per_run - Tuning.SCRAP_PER_RUN_70) / Tuning.SCRAP_PER_RUN_70 < 0.25,
			"Scrap per run %.0f against Tuning.SCRAP_PER_RUN_70 %d" % [r.scrap_per_run, Tuning.SCRAP_PER_RUN_70])


func test_every_permanent_price_is_2_to_3_runs_of_scrap() -> void:
	var prices := [Tuning.COSMETIC_PRICE]
	for item in Tuning.UPGRADES:
		prices.append_array(Tuning.UPGRADES[item])
	for p in prices:
		var runs := float(p) / Tuning.SCRAP_PER_RUN_70
		check(runs >= 2.0 and runs <= 3.0, "%d is %.2f runs" % [p, runs])
	for id in Tuning.PERKS:
		check(Tuning.PERKS[id] < Tuning.SCRAP_PER_RUN_70, "%s costs under a run" % id)


# ── The screen ───────────────────────────────────────────────

func _area(window: Vector2i) -> Vector2:
	var base := Vector2(1080, 1920)
	var scale := minf(window.x / base.x, window.y / base.y)
	return Vector2(window) / scale


func _screen(area: Vector2, save: Dictionary) -> Array:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE))
	var frame := Control.new()
	frame.size = area
	tree.root.add_child(frame)
	var b: Control = (load(BAZAAR) as PackedScene).instantiate()
	b.save_path = SAVE
	b.save = save
	frame.add_child(b)
	await tree.process_frame
	return [frame, b]


func _done(made: Array) -> void:
	made[0].free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE))


func test_the_screen_buys_and_stores() -> void:
	var made: Array = await _screen(_area(Vector2i(390, 844)), _rich(1900))
	var b: Control = made[1]
	check(b.buttons.has("max_hp"), "a Max HP button")
	check(not (b.buttons.max_hp as Button).disabled)
	(b.buttons.max_hp as Button).pressed.emit()
	await tree.process_frame
	check_eq(Bazaar.level(b.save, "max_hp"), 1)
	check_eq(int(SaveData.load_from(SAVE).bazaar.max_hp), 1, "stored")
	check(b.bank.text.contains(str(1900 - Tuning.UPGRADES.max_hp[0])), b.bank.text)
	(b.buttons["lucky_find|hint"] as Button).pressed.emit()
	await tree.process_frame
	check_eq(b.save.bazaar.perk, {"id": "lucky_find", "lifeline": "hint"})
	check((b.buttons.field_watch as Button).disabled, "the slot is full")
	check(b.find_child("Slot", true, false).text.contains("Lucky Find (Hint)"))
	var r: Dictionary = b.buy("max_hp")
	check(not r.ok, "can't afford a second level")
	check_eq(b.message.text, Bazaar.NOT_ENOUGH)
	check((b.buttons.max_hp as Button).disabled)
	_done(made)


func test_the_screen_wears_cosmetics() -> void:
	var s := _rich(Tuning.COSMETIC_PRICE)
	var made: Array = await _screen(_area(Vector2i(390, 844)), s)
	var b: Control = made[1]
	(b.buttons["frame:signal"] as Button).pressed.emit()
	await tree.process_frame
	check_eq(b.save.bazaar.frame, "signal")
	check(b.buttons.has("frame:|wear"), "plain can be worn again")
	(b.buttons["frame:|wear"] as Button).pressed.emit()
	await tree.process_frame
	check_eq(b.save.bazaar.frame, "")
	check((b.buttons["tint:rust"] as Button).disabled, "no Scrap left")
	_done(made)


func test_the_demo_stores_nothing() -> void:
	var d: Dictionary = load("res://ui/bazaar.gd").demo_save()
	check(int(d.scrap) > 0)
	check_eq(Bazaar.level(d, "max_hp"), 1)
	check(not d.bazaar.perk.is_empty())


func test_fits_a_390_phone() -> void:
	await _check_fits(Vector2i(390, 844))


func test_fits_a_360_phone() -> void:
	await _check_fits(Vector2i(360, 780))


func test_fits_a_pc_window() -> void:
	await _check_fits(Vector2i(1280, 800))


func _check_fits(window: Vector2i) -> void:
	var area := _area(window)
	var made: Array = await _screen(area, load("res://ui/bazaar.gd").demo_save())
	var b: Control = made[1]
	for i in 3:
		await tree.process_frame
	var screen := Rect2(Vector2.ZERO, area)
	var col := b.get_node("Margin/Column") as Control
	check(screen.encloses(col.get_global_rect()), "%s: column %s outside %s" % [window, col.get_global_rect(), screen])
	for c in col.find_children("*", "Control", true, false):
		if c.is_visible_in_tree() and not c is ScrollBar:
			var r: Rect2 = c.get_global_rect()
			check(r.end.x <= col.get_global_rect().end.x + 1 and r.position.x >= col.get_global_rect().position.x - 1,
					"%s: %s sticks out (%s)" % [window, c.name, r])
	check(b.scroll.size.y >= 600, "%s: room for the shelves (%s)" % [window, b.scroll.size.y])
	_done(made)


func test_the_fight_screen_wears_the_plate_and_shows_the_perk() -> void:
	var s := _rich(5000)
	Bazaar.buy(s, "tint:magenta")
	Bazaar.buy(s, "frame:field_note")
	Bazaar.buy(s, "field_manual")
	var path := "user://test_bazaar_fight.json"
	SaveData.store(s, path)
	var frame := Control.new()
	frame.size = _area(Vector2i(390, 844))
	tree.root.add_child(frame)
	var f: Control = (load("res://scenes/fight.tscn") as PackedScene).instantiate()
	f.save_path = path
	f.run_seed = 3
	f.select_first = false
	frame.add_child(f)
	await tree.process_frame
	var plate := f.find_child("NamePlate", true, false) as PanelContainer
	check(plate != null, "a name plate")
	check((plate.get_theme_stylebox("panel") as StyleBoxTexture) != null, "in the Field Note frame")
	check_eq((plate.get_node("Text") as Label).get_theme_color("font_color"), Bazaar.TINTS.magenta.color)
	check((f.find_child("Perk", true, false) as Label).text.contains("Field Manual"))
	check((f.lifeline_buttons.hint as Button).text.contains("free"))
	check(SaveData.load_from(path).bazaar.perk.is_empty(), "the perk is used up as the run starts")
	frame.free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
