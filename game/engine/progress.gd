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
## the save's "Exam-style only" switch: with it on, only exam cells count. They follow its
## course too (Courses.of): the cells that course covers.

## How many weakest skills the region screen flags.
const WEAKEST := 3
## A skill needs this many answers before it can be called weak.
const MIN_ATTEMPTS := MathsEngine.MIN_ATTEMPTS


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


## The catalogue's coverage cells for the region, with the "Exam-style only" switch and
## the course's cells only (Courses; "" for every cell).
static func catalogue_cells(region: String, exam_only: bool = false, course: String = "") -> Array:
	var ids := catalogue_types(region)
	# cells() with no types means every built type, so an empty region stays empty.
	return QuestionEngine.cells(exam_only, ids, course) if not ids.is_empty() else []


static func _exam_only(save: Dictionary) -> bool:
	return bool(save.get("settings", {}).get("exam_only", false))


## The region's cells as the save sees them: its "Exam-style only" switch and its course.
static func _cells(save: Dictionary, region: String) -> Array:
	return catalogue_cells(region, _exam_only(save), Courses.of(save))


## {"checked": cells the save has seen, "total": the catalogue's cells}, for the region.
## The counting is the engine's learning results (MathsEngine), over the region's cells.
static func coverage(save: Dictionary, region: String) -> Dictionary:
	return MathsEngine.coverage(save, _cells(save, region))


## {"right", "seen", "percent"} over every answer in the region's cells; percent is -1
## when nothing has been answered.
static func accuracy(save: Dictionary, region: String) -> Dictionary:
	return MathsEngine.accuracy(save, _cells(save, region))


## Skill id -> {"right", "seen"}: each answer in a cell counts for every skill its
## unknown lists.
static func skill_stats(save: Dictionary, region: String) -> Dictionary:
	return MathsEngine.skill_stats(save, _cells(save, region))


## The n skills with the lowest accuracy among those with at least MIN_ATTEMPTS
## answers, weakest first (ties: more answers first, then by id). Each is {"id", "name",
## "right", "seen", "percent"}.
static func weakest_skills(save: Dictionary, region: String, n: int = WEAKEST) -> Array:
	return MathsEngine.weakest_skills(save, _cells(save, region), n)


## A skill's name from the catalogue (curriculum/aa-sl.json), or its id.
static func skill_name(id: String) -> String:
	return MathsEngine.skill_name(id)


## The deepest floor reached in the region's dungeon, 0 before any run.
static func best_floor(save: Dictionary, region: String) -> int:
	return int(Dungeon.record(save, region).get("best", 0))


## True when the region has a built type (that the course covers, with one), so a run can
## start there. The engine's built types decide, so a region lights up when its
## situations merge, with no map change.
static func is_built(region: String, course: String = "") -> bool:
	return not Dungeon.region_types(region, course).is_empty()


## SPARK's pick on the island map (FAL-531 plan): the open (built) region to suggest,
## and why, as {"region", "why"}; {} when no region is open. A suggestion, never a gate.
##   "untried":  the first the player hasn't tried, in MapLink.region_ids() order (most
##               examined first);
##   "accuracy": otherwise the lowest accuracy among regions with MIN_ATTEMPTS answers;
##   "coverage": otherwise the lowest share of the region's cells checked.
## Ties go to the earlier region in that order.
static func suggest(save: Dictionary, regions: Array = MapLink.region_ids()) -> Dictionary:
	var open := regions.filter(func(id): return is_built(id, Courses.of(save)))
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
