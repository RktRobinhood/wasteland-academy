extends RefCounted
## PROPOSAL ONLY (#268, FAL-1603, ADR-0002). Not used by the game.
##
## The mastery update function proposed in docs/proposals/mastery-calibration.md, written
## as plain static functions so the deterministic simulation in
## tests/test_mastery_calibration_sim.gd can print learner trajectories. Every constant
## below is PROPOSED and needs the owner's acceptance before any of it moves into
## MathsEngine. tests/* is excluded from every export preset, so nothing here ships.
##
## A skill record: {"m": rating 1.0..CAP, "n": answers counted, "exam_ok": unassisted
## successes at the skill's exam tier, "ok_cells": distinct cell keys answered right,
## "recent_ok": the last REPEAT_WINDOW cells answered right}. A missing record is Not Yet
## Attempted: no rating at all.

## PROPOSED. First evidence starts at the bottom of Foundations: no faked certainty.
const START := 1.0
## PROPOSED. The top of Level 7, so L7 has headroom to absorb one bad miss.
const CAP := 7.999
## PROPOSED. Elo step. With K = 1 a matched success moves the rating 0.5: two per level.
const K := 1.0
## PROPOSED. One rating point = one level. A one-level gap gives p = 0.73.
const SCALE := 1.0
## PROPOSED. Question difficulty d (0-5) sits at rating d + 1: d3 is Level 4.
const DIFFICULTY_OFFSET := 1.0

## PROPOSED credit for a success (multiplies the upward step). See the proposal's table.
const CREDIT := {
	"none": 1.0,
	"mcq": 0.75,       # four options: a guess lands one time in four
	"fifty": 0.4,      # 50-50 leaves two options: a guess lands one time in two
	"hint": 0.5,       # the first worked step was shown
	"glancing": 0.75,  # right value, wrong accuracy
	"late": 1.0,       # speed is not the chief objective
	"freeze": 1.0,     # Time Freeze changes the clock, not the maths
	"migrated": 0.75,  # a v7 answer replayed by the migration: format and assists unknown
}
## PROPOSED weight for a miss (multiplies the downward step).
const MISS := {"wrong": 1.0, "timeout": 0.5}

## PROPOSED. Upward steps shrink from Level 5: L5->L6 needs ~4 matched successes,
## L6->L7 ~8, and gains inside L7 are a buffer, not a target.
const DAMP := [[5.0, 1.0], [6.0, 0.5], [7.0, 0.25], [99.0, 0.125]]
## The softer alternative the proposal compares against (not recommended).
const DAMP_SOFT := [[5.0, 1.0], [6.0, 0.75], [7.0, 0.5], [99.0, 0.25]]
## PROPOSED. Assisted (hint, 50-50) and migrated successes can lift the rating to the
## edge of Exam Ready but not past it: L4 needs the learner's own work.
const ASSISTED_CAP := 3.999
## PROPOSED. A success on a cell among the skill's last REPEAT_WINDOW successes counts half.
const REPEAT_WINDOW := 3
const REPEAT_FACTOR := 0.5
## PROPOSED. Exam Ready (L4+) needs this many unassisted successes at the exam tier.
const EXAM_READY_UNASSISTED := 2
## PROPOSED. The exam tier: difficulty 3, or the skill's top difficulty if that is lower.
const EXAM_TIER := 3
## PROPOSED. L6 needs right answers on this many distinct cells, L7 on L7_CELLS (or every
## cell of the skill when it has fewer).
const L6_CELLS := 3
const L7_CELLS := 5
## PROPOSED. Thunderdome floor when no eligible skill has any evidence: Level 2.
const NO_ATTEMPT_FLOOR := 2.0


static func rating_of(difficulty: int) -> float:
	return float(difficulty) + DIFFICULTY_OFFSET


## Expected chance of success at rating m on a question at rating e.
static func expect(m: float, e: float) -> float:
	return 1.0 / (1.0 + exp(-(m - e) / SCALE))


static func damp(m: float, table: Array = DAMP) -> float:
	for band in table:
		if m < band[0]:
			return band[1]
	return table[-1][1]


static func blank() -> Dictionary:
	return {"m": START, "n": 0, "exam_ok": 0, "ok_cells": [], "recent_ok": []}


## The product of the credits for the assists and format on a success.
## assists: any of "mcq", "fifty", "hint", "glancing", "late", "freeze".
## A 50-50 replaces the multiple-choice credit rather than stacking with it.
static func credit(assists: Array) -> float:
	var c := 1.0
	for a in assists:
		if a == "mcq" and assists.has("fifty"):
			continue
		c *= float(CREDIT.get(a, 1.0))
	return c


static func is_unassisted(assists: Array) -> bool:
	return not (assists.has("hint") or assists.has("fifty") or assists.has("migrated"))


## Blame shares for a miss on a multi-skill question: each skill's share is its chance of
## being the one that failed, (1 - p) / sum(1 - p). A misconception that names one of the
## skills puts all the blame there. records: skill id -> record (blank() if unattempted).
static func blame(records: Dictionary, skills: Array, difficulty: int, misconception_skill: String = "") -> Dictionary:
	var out := {}
	if misconception_skill != "" and skills.has(misconception_skill):
		for s in skills:
			out[s] = 1.0 if s == misconception_skill else 0.0
		return out
	var e := rating_of(difficulty)
	var total := 0.0
	for s in skills:
		total += 1.0 - expect(float(records.get(s, blank()).m), e)
	for s in skills:
		out[s] = (1.0 - expect(float(records.get(s, blank()).m), e)) / total
	return out


## One answer's effect on one skill. Returns a new record.
##   difficulty   the question's 0-5 level (the unknown's catalogue "level")
##   top          the skill's top catalogue difficulty
##   outcome      "right", "glancing", "late", "wrong" or "timeout"
##   assists      see credit()
##   share        this skill's blame share on a miss (1.0 for a single-skill question)
static func update(rec: Dictionary, difficulty: int, top: int, outcome: String, assists: Array = [],
		cell: String = "", share: float = 1.0) -> Dictionary:
	var r := rec.duplicate(true) if not rec.is_empty() else blank()
	var m: float = r.m
	var e := rating_of(difficulty)
	r.n = int(r.n) + 1
	if outcome in ["right", "glancing", "late"]:
		var used: Array = assists.duplicate()
		if outcome != "right" and not used.has(outcome):
			used.append(outcome)
		# Past the skill's hardest tier, a top-tier success counts as matched, not as easy.
		if difficulty >= top and m >= e:
			e = m
		var step := K * (1.0 - expect(m, e)) * credit(used) * damp(m)
		if cell != "" and (r.recent_ok as Array).has(cell):
			step *= REPEAT_FACTOR
		var ceiling := CAP if is_unassisted(used) else maxf(m, ASSISTED_CAP)
		r.m = minf(ceiling, m + step)
		if is_unassisted(used) and outcome != "glancing" and difficulty >= mini(EXAM_TIER, top):
			r.exam_ok = int(r.exam_ok) + 1
		if cell != "":
			if not (r.ok_cells as Array).has(cell):
				(r.ok_cells as Array).append(cell)
			(r.recent_ok as Array).append(cell)
			while (r.recent_ok as Array).size() > REPEAT_WINDOW:
				(r.recent_ok as Array).pop_front()
	else:
		var w: float = MISS.get(outcome, 1.0)
		r.m = maxf(1.0, m - K * expect(m, e) * w * share)
	return r


## The success rate that holds a rating steady when every question is asked at
## difficulty d (on a skill whose top tier is top): the rate s where s x (upward step) =
## (1 - s) x (downward step).
static func holding_rate(m: float, d: int, top: int, table: Array = DAMP) -> float:
	var e := rating_of(d)
	var up_e := m if d >= top and m >= e else e
	var up := K * (1.0 - expect(m, up_e)) * damp(m, table)
	var down := K * expect(m, e)
	return down / (up + down)


## The displayed level: 0 for Not Yet Attempted, else 1-7 after the evidence gates.
## cells: how many cells the skill has in the course (for the L6/L7 variety gates).
static func level(rec: Dictionary, cells: int = 99) -> int:
	if rec.is_empty():
		return 0
	var lv := clampi(floori(float(rec.m)), 1, 7)
	var distinct := (rec.ok_cells as Array).size()
	if lv >= 7 and distinct < mini(L7_CELLS, cells):
		lv = 6
	if lv >= 6 and distinct < mini(L6_CELLS, cells):
		lv = 5
	if lv >= 4 and int(rec.exam_ok) < EXAM_READY_UNASSISTED:
		lv = 3
	return lv


## The Thunderdome floor, taken once at the start of a run: the mean rating of the
## eligible skills that have evidence, or NO_ATTEMPT_FLOOR when none has.
static func thunderdome_floor(records: Dictionary, eligible: Array) -> float:
	var total := 0.0
	var count := 0
	for s in eligible:
		if records.has(s):
			total += float(records[s].m)
			count += 1
	return total / count if count > 0 else NO_ATTEMPT_FLOOR


## The rating a Thunderdome question for skill s is chosen at: the fixed floor, or the
## skill's own rating when that is higher. Never writes a rating for an unattempted skill.
static func selection_rating(records: Dictionary, skill: String, floor_rating: float) -> float:
	return maxf(floor_rating, float(records[skill].m)) if records.has(skill) else floor_rating


## The difficulty a rating asks for, inside the skill's catalogue range.
static func difficulty_for(rating: float, lo: int, hi: int) -> int:
	return clampi(roundi(rating - DIFFICULTY_OFFSET), lo, hi)
