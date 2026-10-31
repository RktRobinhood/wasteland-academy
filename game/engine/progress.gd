class_name Progress
extends RefCounted
## What the map shows about a region (Q11 on the FAL-274 plan): accuracy, best floor,
## coverage and the player's weakest skills, all read from the save. No UI and no state.
##
##   Progress.coverage(save, "quadratics")       # {"checked": 34, "total": 52}
##   Progress.accuracy(save, "quadratics")       # {"right", "seen", "percent"}
##   Progress.weakest_skills(save, "quadratics") # up to 3 {"id", "name", "right", "seen", "percent"}
##   Progress.is_built("rational")               # false until a situation of the region is built
##   Progress.suggest(save)                      # SPARK's pick: {"region", "why"}, or {}
##
## A region is a catalogue region id, or Dungeon.ALL for the whole island. Coverage
## counts the cells the save has seen against the catalogue's cells for the region,
## built or not, so it reads "0 of 40" before a region is playable. Every number follows
## the save's "Exam-style only" switch: with it on, only exam cells count.

## How many weakest skills the region screen flags.
const WEAKEST := 3
## A skill needs this many answers before it can be called weak.
const MIN_ATTEMPTS := 3


## Every catalogue type of the region, built or not, in catalogue order.
static func catalogue_types(region: String) -> Array:
	var out: Array = []
	for t in QuestionEngine.catalogue().get("types", []):
		var r = t.get("region")
		if r == null:
			continue
		if region == Dungeon.ALL or r == region:
			out.append(t.id)
	return out


## The catalogue's coverage cells for the region, with the "Exam-style only" switch.
static func catalogue_cells(region: String, exam_only: bool = false) -> Array:
	var ids := catalogue_types(region)
	# cells() with no types means every built type, so an empty region stays empty.
	return QuestionEngine.cells(exam_only, ids) if not ids.is_empty() else []


static func _exam_only(save: Dictionary) -> bool:
	return bool(save.get("settings", {}).get("exam_only", false))


## {"checked": cells the save has seen, "total": the catalogue's cells}, for the region.
static func coverage(save: Dictionary, region: String) -> Dictionary:
	var pool := catalogue_cells(region, _exam_only(save))
	var checked := 0
	for c in pool:
		if int(save.cells.get(c.key, {}).get("seen", 0)) > 0:
			checked += 1
	return {"checked": checked, "total": pool.size()}


## {"right", "seen", "percent"} over every answer in the region's cells; percent is -1
## when nothing has been answered.
static func accuracy(save: Dictionary, region: String) -> Dictionary:
	var right := 0
	var seen := 0
	for c in catalogue_cells(region, _exam_only(save)):
		var r: Dictionary = save.cells.get(c.key, {})
		right += int(r.get("right", 0))
		seen += int(r.get("seen", 0))
	return {"right": right, "seen": seen, "percent": _percent(right, seen)}


## Skill id -> {"right", "seen"}: each answer in a cell counts for every skill its
## unknown lists.
static func skill_stats(save: Dictionary, region: String) -> Dictionary:
	var out := {}
	for c in catalogue_cells(region, _exam_only(save)):
		var r: Dictionary = save.cells.get(c.key, {})
		var seen := int(r.get("seen", 0))
		if seen == 0:
			continue
		var u := QuestionEngine.unknown_of(QuestionEngine.type_of(c.type), c.unknown)
		for s in u.get("skills", []):
			var st: Dictionary = out.get(s, {"right": 0, "seen": 0})
			st.right += int(r.get("right", 0))
			st.seen += seen
			out[s] = st
	return out


## The n skills with the lowest accuracy among those with at least MIN_ATTEMPTS
## answers, weakest first (ties: more answers first, then by id). Each is {"id", "name",
## "right", "seen", "percent"}.
static func weakest_skills(save: Dictionary, region: String, n: int = WEAKEST) -> Array:
	var stats := skill_stats(save, region)
	var out: Array = []
	for id in stats:
		var st: Dictionary = stats[id]
		if st.seen < MIN_ATTEMPTS:
			continue
		out.append({"id": id, "name": skill_name(id), "right": st.right, "seen": st.seen,
			"percent": _percent(st.right, st.seen)})
	out.sort_custom(func(a, b):
		var fa: float = float(a.right) / a.seen
		var fb: float = float(b.right) / b.seen
		if fa != fb:
			return fa < fb
		if a.seen != b.seen:
			return a.seen > b.seen
		return a.id < b.id)
	return out.slice(0, n)


## A skill's name from the catalogue (curriculum/aa-sl.json), or its id.
static func skill_name(id: String) -> String:
	return String(QuestionEngine.catalogue().get("skills", {}).get(id, id))


## The deepest floor reached in the region's dungeon, 0 before any run.
static func best_floor(save: Dictionary, region: String) -> int:
	return int(Dungeon.record(save, region).get("best", 0))


## True when the region has a built type, so a run can start there. The engine's built
## types decide, so a region lights up when its situations merge, with no map change.
static func is_built(region: String) -> bool:
	return not Dungeon.region_types(region).is_empty()


## SPARK's pick on the island map (FAL-531 plan): the open (built) region to suggest,
## and why, as {"region", "why"}; {} when no region is open. A suggestion, never a gate.
##   "untried":  the first the player hasn't tried, in MapLink.region_ids() order (most
##               examined first);
##   "accuracy": otherwise the lowest accuracy among regions with MIN_ATTEMPTS answers;
##   "coverage": otherwise the lowest share of the region's cells checked.
## Ties go to the earlier region in that order.
static func suggest(save: Dictionary, regions: Array = MapLink.region_ids()) -> Dictionary:
	var open := regions.filter(func(id): return is_built(id))
	for id in open:
		if accuracy(save, id).seen == 0 and best_floor(save, id) == 0:
			return {"region": id, "why": "untried"}
	var best := {}
	var low := INF
	for id in open:
		var acc := accuracy(save, id)
		if acc.seen >= MIN_ATTEMPTS and float(acc.right) / acc.seen < low:
			low = float(acc.right) / acc.seen
			best = {"region": id, "why": "accuracy"}
	if not best.is_empty():
		return best
	for id in open:
		var cov := coverage(save, id)
		var share: float = float(cov.checked) / cov.total if cov.total > 0 else 1.0
		if share < low:
			low = share
			best = {"region": id, "why": "coverage"}
	return best


## True once the player has beaten the boss of the last skill-tier floor (floor 3), the
## floor before everything mixes.
static func is_cleared(save: Dictionary, region: String) -> bool:
	var beaten: Array = Dungeon.record(save, region).get("beaten", [])
	return beaten.any(func(f): return int(f) >= Tuning.MIX_FROM_FLOOR - 1)


static func _percent(right: int, seen: int) -> int:
	return roundi(100.0 * right / seen) if seen > 0 else -1
