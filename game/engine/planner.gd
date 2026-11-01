class_name Planner
extends RefCounted
## Picks the next question (FAL-310 plan, "The planner"):
##   1. a coverage cell the student has never seen
##   2. a cell they got wrong recently (spaced: not one of the last SPACING asked)
##   3. otherwise a cell weighted by how often the IB asks its type
## Rules 1 and 3 weight by exam frequency too, so the exam's favourite types come
## first. With "Exam-style only" on, only exam cells are in the pool and rule 3 is the
## only rule, so the mix follows exam frequency.
##
## Concept probes come in about one question in PROBE_EVERY, never-seen ones first.
## They are extension material, so "Exam-style only" leaves them out.
##
## next() advances the save's seed counter; the caller stores the save.

const SPACING := 3
const RECENT := 7 * 24 * 3600
const PROBE_EVERY := 6
## Planner weight of an extension type, against an exam type's count of bank parts.
const EXTENSION_WEIGHT := 2


## Returns a view for QuestionEngine.make() (or a probe view, with "probe"), plus
## "rule": unseen, wrong, frequency or probe. opts (all optional):
##   region  plan from this catalogue region's built types only (a run's region)
##   cells   plan from these coverage cells only (a dungeon floor, Dungeon.floor_cells)
##   prefer_types  types still to appear on this floor (Q14): while any of them has a
##           cell in the pool, the pool is those cells, and the three rules pick inside
##           it. "Exam-style only" ignores it: exam frequency is then the only rule.
##   probes  false leaves concept probes out (a fight asks questions with answers)
##   salt    mixed into the stream, so a run's seed changes its questions
## The pool is only what the save's course covers (Courses.of), the probes too.
static func next(save: Dictionary, now: int, opts: Dictionary = {}) -> Dictionary:
	var salt: String = opts.get("salt", "")
	var rng := Seeded.new("planner|%d" % int(save.seed) + ("|" + salt if salt != "" else ""))
	save.seed = int(save.seed) + 1
	var exam_only: bool = save.settings.get("exam_only", false)
	var course := Courses.of(save)
	var region: String = opts.get("region", "")
	var pool: Array
	if opts.has("cells"):
		pool = opts.cells
	else:
		var types: Array = region_types(region, course) if region != "" else []
		pool = QuestionEngine.cells(exam_only, types, course)
		if region != "" and types.is_empty():
			pool = []
	if pool.is_empty():
		return {"error": "no questions to plan in region %s" % region}
	var prefer: Array = opts.get("prefer_types", [])
	if not exam_only and not prefer.is_empty():
		var wanted := pool.filter(func(c): return prefer.has(c.type))
		if not wanted.is_empty():
			pool = wanted
	var recent: Array = (save.history as Array).slice(-SPACING)
	var seed := rng.int_in(1, 999999)
	var fmt: String = "mcq" if rng.chance(0.5) else "value"

	if not exam_only:
		var probes := QuestionEngine.probes(false, course) if opts.get("probes", true) else []
		if not probes.is_empty() and rng.int_in(1, PROBE_EVERY) == 1:
			var unseen := probes.filter(func(p): return not save.probes.has(p.key))
			var from: Array = unseen if not unseen.is_empty() else probes.filter(func(p): return not recent.has(p.key))
			if not from.is_empty():
				var p: Dictionary = from[rng.int_in(0, from.size() - 1)]
				return {"type": p.type, "probe": p.index, "format": "probe", "rule": "probe"}

		var unseen_cells := pool.filter(func(c): return not save.cells.has(c.key))
		if not unseen_cells.is_empty():
			return _view(_weighted(unseen_cells, rng), seed, fmt, "unseen", rng)

		var wrong := pool.filter(func(c):
			var r: Dictionary = save.cells.get(c.key, {})
			return r.get("last_result") == "wrong" and now - int(r.get("last", 0)) <= RECENT and not recent.has(c.key))
		if not wrong.is_empty():
			wrong.sort_custom(func(x, y): return int(save.cells[x.key].last) < int(save.cells[y.key].last))
			return _view(wrong[0], seed, fmt, "wrong", rng)

	var fresh := pool.filter(func(c): return not recent.has(c.key))
	return _view(_weighted(fresh if not fresh.is_empty() else pool, rng), seed, fmt, "frequency", rng)


## The built types of a catalogue region (or Dungeon.ALL), in catalogue order.
static func region_types(region: String, course: String = "") -> Array:
	return Dungeon.region_types(region, course)


static func type_weight(type_id: String) -> float:
	var t := QuestionEngine.type_of(type_id)
	if t.get("source") == "exam":
		return maxf(1.0, float(t.get("frequency", 1)))
	return EXTENSION_WEIGHT


## A cell picked with its type's weight shared out over the type's cells in the pool,
## so the mix of types follows exam frequency whatever their cell counts.
static func _weighted(cells: Array, rng: Seeded) -> Dictionary:
	var per_type := {}
	for c in cells:
		per_type[c.type] = int(per_type.get(c.type, 0)) + 1
	var weights: Array = cells.map(func(c): return type_weight(c.type) / per_type[c.type])
	return cells[rng.weighted(weights)]


## The view for a cell. A cell with extra formats (error-spot, method-pick,
## true-false-reason) is asked in one of them some of the time.
static func _view(c: Dictionary, seed: int, fmt: String, rule: String, rng: Seeded) -> Dictionary:
	return {"type": c.type, "unknown": c.unknown, "rep": c.rep, "angle": c.angle, "format": QuestionEngine.upgrade_format(c, fmt, rng),
		"seed": seed, "rule": rule}
