class_name Dungeon
extends RefCounted
## The dungeon (G4, Q4 and Q9 on the FAL-274 plan): which cells each floor serves, the
## enemy tier of each fight, the mini-boss and boss chains, and the floors a run may
## start on. No UI and no state: Run (engine/run.gd) plays it, and every number is in
## Tuning.
##
##   Dungeon.floor_cells("quadratics", 1)      # the coverage cells floor 1 serves
##   Dungeon.tier_for(seed, floor, fight)      # D1-D5
##   Dungeon.boss_plan(seed, "quadratics", floor, "boss")  # the chain steps of fight 10
##   Dungeon.start_floors(save, "quadratics")  # [1] plus the floor after each beaten boss
##
## A region is a catalogue region id, or ALL for the all-regions dungeon: every built
## type of the island (the Functions types, which have a region).

const ALL := "all"
const ALL_NAME := "All regions"


## The built types a run in this region plays, in catalogue order.
static func region_types(region: String) -> Array:
	var built := QuestionEngine.built_types()
	if region == ALL:
		return built.filter(func(id): return QuestionEngine.type_of(id).get("region") != null)
	return built.filter(func(id): return QuestionEngine.type_of(id).get("region") == region)


static func region_name(region: String) -> String:
	if region == ALL:
		return ALL_NAME
	for r in QuestionEngine.catalogue().get("regions", []):
		if r is Dictionary and r.get("id") == region:
			return r.get("name", region)
	return region.capitalize()


static func is_link(type_id: String) -> bool:
	return QuestionEngine.type_of(type_id).get("kind", "") == "link"


static func is_prior(type_id: String) -> bool:
	return QuestionEngine.type_of(type_id).get("kind", "") == "prior-learning"


## A cell's level in the dungeon: its unknown's level, or LINK_LEVEL for a link type.
static func level_of(cell: Dictionary) -> int:
	return Tuning.LINK_LEVEL if is_link(cell.type) else int(cell.level)


## [lowest, highest] level a floor serves.
static func floor_band(on_floor: int) -> Array:
	if on_floor >= Tuning.MIX_FROM_FLOOR:
		return [0, Tuning.LINK_LEVEL]
	return Tuning.FLOOR_LEVELS[maxi(1, on_floor)]


## Every coverage cell this floor serves, in the region's built types (or in `types`,
## for tests). exam_only is the save's "Exam-style only" switch.
static func floor_cells(region: String, on_floor: int, exam_only: bool = false, types: Array = []) -> Array:
	var ids: Array = types if not types.is_empty() else region_types(region)
	if ids.is_empty():
		return []
	return filter_floor(QuestionEngine.cells(exam_only, ids), region, on_floor)


## The cells of `cells` that belong on a floor: the floor table's types where the
## region has one (Tuning.FLOOR_TYPES), else every type, inside the floor's levels.
## Link types (level 5) only from MIX_FROM_FLOOR. Pure, so tests can hand it any cells.
static func filter_floor(cells: Array, region: String, on_floor: int) -> Array:
	var band := floor_band(on_floor)
	if on_floor >= Tuning.MIX_FROM_FLOOR:
		return cells.duplicate()
	var in_band := func(c: Dictionary, low: int) -> bool:
		var lv := level_of(c)
		return lv >= low and lv <= int(band[1])
	var table: Dictionary = Tuning.FLOOR_TYPES.get(region, {})
	if not table.is_empty():
		var here: Array = table.get(on_floor, [])
		var before: Array = table.get(on_floor - 1, [])
		var out := cells.filter(func(c):
			if on_floor == 1 and is_prior(c.type):
				return in_band.call(c, int(band[0]))
			if not here.has(c.type):
				return false
			# A type new on this floor brings its easier cells along.
			return in_band.call(c, int(band[0]) if before.has(c.type) else 0))
		# The table's types aren't built yet: the level rule, so the floor isn't empty.
		if not out.is_empty():
			return out
	return cells.filter(func(c): return in_band.call(c, int(band[0])))


## The types a floor belongs to: every type with a cell on it. Q14: each one appears
## at least once on the floor.
static func floor_types(cells: Array) -> Array:
	var out: Array = []
	for c in cells:
		if not out.has(c.type):
			out.append(c.type)
	return out


## Level-0 cells (prior learning) of the region, for warm-ups and after a miss.
static func prior_cells(region: String, exam_only: bool = false) -> Array:
	var ids := region_types(region).filter(func(id): return is_prior(id))
	return QuestionEngine.cells(exam_only, ids) if not ids.is_empty() else []


## The prior-learning type to serve after a miss on this cell: one of the region's
## (or `types`') prior-learning types whose `supports` lists a skill of the missed
## unknown, picked by `salt`; "" if none does or the miss was prior learning itself.
static func prior_for(region: String, cell_key: String, salt: String = "", types: Array = []) -> String:
	var bits := cell_key.split("|")
	if bits.size() < 2 or is_prior(bits[0]):
		return ""
	var skills: Array = QuestionEngine.unknown_of(QuestionEngine.type_of(bits[0]), bits[1]).get("skills", [])
	var ids: Array = types if not types.is_empty() else region_types(region)
	var fits: Array = ids.filter(func(id):
		if not is_prior(id):
			return false
		for s in QuestionEngine.type_of(id).get("supports", []):
			if s in skills:
				return true
		return false)
	if fits.is_empty():
		return ""
	return fits[Seeded.new("prior|%s|%s" % [cell_key, salt]).int_in(0, fits.size() - 1)]


# ── Fights ───────────────────────────────────────────────────

## "fight", "mini" (the mini-boss) or "boss" for fight n of a floor.
static func fight_kind(n: int) -> String:
	if n == Tuning.FIGHTS_PER_FLOOR:
		return "boss"
	if n == Tuning.MINI_BOSS_AT:
		return "mini"
	return "fight"


## The enemy tier of fight n on a floor, the same for the same seed: D1-D2 (D1 with
## chance LOW_TIER_D1), the mini-boss D3 and the boss D5, all raised on deeper floors.
static func tier_for(seed_no: int, on_floor: int, n: int) -> int:
	var base := 0
	match fight_kind(n):
		"boss":
			base = Tuning.BOSS_TIER
		"mini":
			base = Tuning.MINI_BOSS_TIER
		_:
			base = 1 if Seeded.new("tier|%d|%d|%d" % [seed_no, on_floor, n]).chance(Tuning.LOW_TIER_D1) else 2
	return mini(5, base + Tuning.raise_for(on_floor))


## A type's chain as steps [{"type", "unknown"}], only if every step is built.
static func chain_steps(type_id: String) -> Array:
	var out: Array = []
	for step in Tuning.CHAINS.get(type_id, []):
		var bits: PackedStringArray = (step as String).split(":")
		var t := type_id if bits.size() == 1 else bits[0]
		var u := bits[-1]
		var views = QuestionEngine.views_for(QuestionEngine.type_of(t))
		if views == null or not views.has(u):
			return []
		out.append({"type": t, "unknown": u})
	return out


## Every run of steps a mini-boss or boss can ask from a type's chain: each start, at
## each part count Tuning allows. For the answer checker and the seed sweep.
static func chain_windows(type_id: String) -> Array:
	var chain := chain_steps(type_id)
	var sizes: Array = []
	for n in Tuning.MINI_BOSS_PARTS + Tuning.BOSS_PARTS:
		if not sizes.has(n):
			sizes.append(n)
	var out: Array = []
	for n in sizes:
		for at in chain.size() - n + 1:
			out.append(chain.slice(at, at + n))
	return out


## How many chained parts a mini-boss ("mini") or boss ("boss") asks, by the seed.
static func parts_for(seed_no: int, on_floor: int, kind: String) -> int:
	var options: Array = Tuning.BOSS_PARTS if kind == "boss" else Tuning.MINI_BOSS_PARTS
	return options[Seeded.new("parts|%d|%d|%s" % [seed_no, on_floor, kind]).int_in(0, options.size() - 1)]


## The boss of a floor: {"kind", "type", "steps", "link"} where steps are consecutive
## chain steps on one situation, each with a rep and format, and link is a link view
## for the boss's last part ({} if none is built). {} if no type on the floor (or, failing
## that, in the region) has a chain long enough.
##   cells   the floor's cells (Dungeon.floor_cells), for the floor's types
static func boss_plan(seed_no: int, region: String, on_floor: int, kind: String, cells: Array = []) -> Dictionary:
	var rng := Seeded.new("boss|%d|%d|%s|%s" % [seed_no, on_floor, kind, region])
	var n := parts_for(seed_no, on_floor, kind)
	var floor_ids := floor_types(cells if not cells.is_empty() else floor_cells(region, on_floor))
	var pick := _boss_type(floor_ids, n, rng)
	if pick == "":
		pick = _boss_type(region_types(region), n, rng)
	if pick == "":
		return {}
	var chain := chain_steps(pick)
	var at := rng.int_in(0, chain.size() - n)
	var steps: Array = []
	for i in n:
		var st: Dictionary = chain[at + i].duplicate()
		var u := QuestionEngine.unknown_of(QuestionEngine.type_of(st.type), st.unknown)
		st.rep = u.reps[0]
		st.angle = QuestionEngine.angles_for(QuestionEngine.type_of(st.type), st.unknown)[0]
		st.format = "mcq" if rng.chance(0.5) else "value"
		steps.append(st)
	var link := {}
	if kind == "boss" and Tuning.BOSS_LINK_PART:
		var links := region_types(region).filter(func(id): return is_link(id))
		if not links.is_empty():
			var lc := QuestionEngine.cells(false, [links[rng.int_in(0, links.size() - 1)]])
			var c: Dictionary = lc[rng.int_in(0, lc.size() - 1)]
			var fmt := QuestionEngine.upgrade_format(c, "mcq" if rng.chance(0.5) else "value", rng)
			link = {"type": c.type, "unknown": c.unknown, "rep": c.rep, "angle": c.angle, "format": fmt, "seed": rng.int_in(1, 999999)}
	return {"kind": kind, "type": pick, "steps": steps, "seed": rng.int_in(1, 999999), "link": link}


## A type with a chain of at least n built steps, weighted by how often Section B
## chains it (stats.section.B, plus 1 so a Section A type can still come up).
static func _boss_type(ids: Array, n: int, rng: Seeded) -> String:
	var ok: Array = ids.filter(func(id): return chain_steps(id).size() >= n)
	if ok.is_empty():
		return ""
	var weights: Array = ok.map(func(id):
		return 1.0 + float(QuestionEngine.type_of(id).get("section", {}).get("B", 0)))
	return ok[rng.weighted(weights)]


# ── Start floors and the save ────────────────────────────────

## The floors a run in this region may start on: floor 1, and floor N + 1 for every
## floor N whose boss the player has beaten (Q4). Beating floor 1's boss opens floor 2.
static func start_floors(save: Dictionary, region: String) -> Array:
	var out: Array = [1]
	for f in record(save, region).get("beaten", []):
		if not out.has(int(f) + 1):
			out.append(int(f) + 1)
	out.sort()
	return out


## The save's record for a region: {"best": deepest floor reached, "beaten": [floors
## whose boss fell]}.
static func record(save: Dictionary, region: String) -> Dictionary:
	return (save.get("dungeon", {}) as Dictionary).get(region, {"best": 0, "beaten": []})


static func note_floor(save: Dictionary, region: String, on_floor: int, boss_beaten: bool) -> void:
	if not save.has("dungeon"):
		save.dungeon = {}
	var r: Dictionary = record(save, region).duplicate(true)
	r.best = maxi(int(r.get("best", 0)), on_floor)
	# A save read back from JSON has floats; floors are whole numbers.
	var beaten: Array = (r.get("beaten", []) as Array).map(func(f): return int(f))
	if boss_beaten and not beaten.has(on_floor):
		beaten.append(on_floor)
		beaten.sort()
	r.beaten = beaten
	save.dungeon[region] = r
