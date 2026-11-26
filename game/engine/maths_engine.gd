class_name MathsEngine
extends RefCounted
## The reusable mathematics engine's interface (#134, FAL-798; game/docs/MATHS-ENGINE.md).
## Every screen that asks, marks or explains a question goes through here: the game's
## practice and fight screens, and the academic study screen (ui/study.gd). Nothing in
## it, or in what it calls, knows about combat, characters, rewards, the map or a scene:
## tests/test_maths_engine.gd checks that.
##
##   Curriculum selection   courses(), topics(), types(course), requests(course)
##   Generation             generate(request)            the same request, the same question
##   Marking                mark(question, response)
##   Worked solutions       worked_solutions(question), answer_sentence(question)
##   Learning results       blank_evidence(), record(evidence, question, result, now,
##                          outcome, assists), results(evidence, course)
##   Mastery                mastery(evidence, skill), mastery_levels(evidence, course),
##                          mastery_target(evidence, skill)
##
## A request is a Dictionary: {"type", "unknown", "rep", "angle", "format", "seed"} and,
## optionally, "paper" (1 or 2). A concept probe is {"type", "probe": index, "format":
## "probe"}. Evidence is a Dictionary with "cells", "probes", "history" and "mastery" (the
## game's save is one, with its own fields beside them; until its v8 migration a save has
## no "mastery", and record() adds one).

## The interface's version. A change that breaks a caller bumps it.
const VERSION := 1


# ── Curriculum selection ─────────────────────────────────────

## The IB courses, in order: each {"id", "short", "name", "status"}.
static func courses() -> Array:
	return Courses.ids().map(func(id): return Courses.info(id))


## The syllabus topics: each {"n", "name"}.
static func topics() -> Array:
	return QuestionEngine.catalogue().get("topics", [])


## The question types the engine can make for a course ("" for every course), in
## catalogue order: each {"id", "name", "topic", "exam"}. exam_only keeps exam types.
static func types(course: String = "", exam_only: bool = false) -> Array:
	var out: Array = []
	for id in QuestionEngine.built_types(course):
		var t := QuestionEngine.type_of(id)
		if exam_only and t.source != "exam":
			continue
		out.append({"id": id, "name": t.name, "topic": int(t.get("topic", 0)), "exam": t.source == "exam"})
	return out


## Every request a course can make (one per coverage cell), each {"type", "unknown",
## "rep", "angle", "key", "level", "exam"}: add a "format" and a "seed" to generate one.
## type_ids narrows it to those types. Read-only, as QuestionEngine.cells() is.
static func requests(course: String = "", exam_only: bool = false, type_ids: Array = []) -> Array:
	return QuestionEngine.cells(exam_only, type_ids, course)


## The syllabus topic (its "n") of a question type, or 0.
static func topic_of(type_id: String) -> int:
	return int(QuestionEngine.type_of(type_id).get("topic", 0))


## What a request asks for, in words ("the vertex"), or the unknown's id.
static func asked(type_id: String, unknown: String) -> String:
	return QuestionEngine.unknown_of(QuestionEngine.type_of(type_id), unknown).get("asked", unknown)


## The name of a method (a request's angle) on a type.
static func method_name(type_id: String, unknown: String, angle: String) -> String:
	return QuestionEngine.angle_info(QuestionEngine.type_of(type_id), unknown, angle).get("name", angle)


## A skill's name from the curriculum, or its id.
static func skill_name(id: String) -> String:
	return String(QuestionEngine.catalogue().get("skills", {}).get(id, id))


# ── Generation ───────────────────────────────────────────────

## The question for a request, or {"error"}. The same request always gives the same
## question. What a screen reads from it: "prompt" (prompt()), "format", "lines",
## "table", "graph", "diagram", "graphs", "answer" (its "template" lays out the answer
## boxes), "choices" (each "text"), "paper", "marks", "level", "exam", "type_name" and
## "cell" (the evidence key). A probe has "options" for its choices and "reveal".
static func generate(request: Dictionary) -> Dictionary:
	if request.get("format") == "probe":
		return QuestionEngine.probe(request.get("type", ""), int(request.get("probe", 0)))
	return QuestionEngine.make(request)


## The question's words as the student reads them.
static func prompt(question: Dictionary) -> String:
	return QuestionEngine.shown_prompt(question)


## Whether the question is answered by picking one option ({"choice": index}).
static func is_choice(question: Dictionary) -> bool:
	return question.get("format") == "probe" or QuestionEngine.is_choice(question)


# ── Marking ──────────────────────────────────────────────────

## Marks a response: {"choice": index} for a choice question or probe, else answer box
## id -> typed text (and pick id -> the option chosen). Returns {"correct", "complete",
## "glancing", "errors", "misconception"}; "errors" says what is missing when the
## response is not complete, and "misconception" is the ref of the mistake a wrong
## answer matches, or "".
static func mark(question: Dictionary, response: Dictionary) -> Dictionary:
	if question.get("format") != "probe":
		return QuestionEngine.mark(question, response)
	var i := int(response.get("choice", -1))
	if i < 0 or i >= question.options.size():
		return {"correct": false, "complete": false, "glancing": false, "errors": {"choice": "Choose one."}, "misconception": ""}
	var r := QuestionEngine.mark_probe(question, question.options[i])
	r.glancing = false
	r.errors = {}
	return r


## The response that answers the question right (or, with right = false, the way the
## commonest mistake does), as a student would type or pick it. Tests and demos use it.
static func model_response(question: Dictionary, right: bool = true) -> Dictionary:
	if is_choice(question):
		var items: Array = question.options if question.format == "probe" else question.choices
		var pick := -1
		for i in items.size():
			var ok: bool = (items[i] == question.verdict or (question.verdict == "" and i == 0)) if question.format == "probe" \
				else question.choices[i].correct
			if ok == right and pick < 0:
				pick = i
		# A wrong answer picks a misconception's option when there is one.
		if not right and question.format != "probe":
			for i in items.size():
				if question.choices[i].ref != "":
					pick = i
					break
		return {"choice": maxi(pick, 0)}
	var values: Dictionary = question.answer.values
	var boxes: Array = []
	var picks: Array = []
	for item in Answer.slots(question.answer):
		if item.has("slot"):
			boxes.append(item.slot)
		else:
			picks.append(item.pick)
	if not right:
		# A wrong option in another shape can be picked but not typed.
		for c in question.choices:
			if not c.correct and (boxes + picks).all(func(id): return c.values.has(id)):
				values = c.values
				if c.ref != "":
					break
	var out := {}
	for id in picks:
		out[id] = values[id]
	for id in boxes:
		# A measure is typed as a student would, to 3 s.f., and a decimal or money as written.
		if question.answer.kind in ["measure", "measures"]:
			out[id] = Fmt.sf(values[id]).replace("−", "-")
		elif question.answer.get("show", "") != "":
			out[id] = Answer.shown(question.answer, values[id]).replace("−", "-")
		else:
			out[id] = Answer.export_values({id: values[id]})[id]
	return out


# ── Worked solutions ─────────────────────────────────────────

## The worked solutions, the asked method first: each {"angle", "name", "steps": [text],
## "result"}. A probe's is its reveal, as one step.
static func worked_solutions(question: Dictionary) -> Array:
	if question.get("format") == "probe":
		return [{"angle": "any", "name": "Answer", "steps": [question.reveal], "result": ""}]
	return question.get("solutions", []).map(func(s): return {"angle": s.angle, "name": s.name,
		"steps": Step.texts(s.steps), "result": Answer.export_values(s.result) if s.result is Dictionary else s.result})


## "The answer is ...": the right answer as feedback names it.
static func answer_sentence(question: Dictionary) -> String:
	if question.get("format") == "probe":
		return "The answer is " + Fmt.stop(question.verdict if question.verdict != "" else question.reveal)
	return QuestionEngine.answer_sentence(question)


# ── Learning results ─────────────────────────────────────────

## How many answer keys the evidence keeps in "history", for spacing repeats.
const HISTORY := 20


## Evidence with nothing in it.
static func blank_evidence() -> Dictionary:
	return {"cells": {}, "probes": {}, "history": [], "mastery": blank_mastery()}


## Records a marked answer in the evidence: its cell (record_key) and the mastery of every
## skill the question tests (record_mastery).
##   outcome   "right", "late", "glancing", "wrong" or "timeout"; "" reads it from result
##   assists   any of "hint", "fifty", "freeze" (the fight's lifelines); the question's own
##             format adds "mcq", and a glancing result adds "glancing"
static func record(evidence: Dictionary, question: Dictionary, result: Dictionary, now: int,
		outcome: String = "", assists: Array = []) -> void:
	record_key(evidence, question.cell, result.correct, now, result.get("misconception", ""), question.get("format") == "probe")
	record_mastery(evidence, question, result, now, outcome, assists)


## Records one answer by key: a cell key (or a probe key with probe = true). Each cell
## keeps {"seen", "right", "wrong", "last", "last_result", "misconceptions": {ref:
## times}, "last_misconception"}; a probe the same, without misconceptions.
static func record_key(evidence: Dictionary, key: String, right: bool, now: int, misconception: String = "", probe: bool = false) -> void:
	var book: Dictionary = evidence.probes if probe else evidence.cells
	var r: Dictionary = book.get(key, {"seen": 0, "right": 0, "wrong": 0, "last": 0, "last_result": ""})
	r.seen = int(r.seen) + 1
	if right:
		r.right = int(r.right) + 1
	else:
		r.wrong = int(r.wrong) + 1
	r.last = now
	r.last_result = "right" if right else "wrong"
	if not probe:
		var mis: Dictionary = r.get("misconceptions", {})
		if misconception != "":
			mis[misconception] = int(mis.get(misconception, 0)) + 1
		r.misconceptions = mis
		r.last_misconception = misconception
	book[key] = r
	var hist: Array = evidence.history
	hist.append(key)
	while hist.size() > HISTORY:
		hist.pop_front()


## A skill needs this many answers before it can be called weak.
const MIN_ATTEMPTS := 3
## How many weakest skills results() lists.
const WEAKEST := 3


## What the evidence says about a course (or about type_ids of it): {"coverage":
## {"checked", "total"}, "accuracy": {"right", "seen", "percent"}, "skills": {id:
## {"right", "seen"}}, "weakest": up to WEAKEST {"id", "name", "right", "seen",
## "percent"}}. percent is -1 when nothing has been answered.
static func results(evidence: Dictionary, course: String = "", exam_only: bool = false, type_ids: Array = []) -> Dictionary:
	var pool := requests(course, exam_only, type_ids)
	return {"coverage": coverage(evidence, pool), "accuracy": accuracy(evidence, pool), "skills": skill_stats(evidence, pool),
		"weakest": weakest_skills(evidence, pool)}


## {"checked": cells of the pool the evidence has seen, "total": the pool's cells}.
static func coverage(evidence: Dictionary, pool: Array) -> Dictionary:
	var checked := 0
	for c in pool:
		if int(evidence.cells.get(c.key, {}).get("seen", 0)) > 0:
			checked += 1
	return {"checked": checked, "total": pool.size()}


## {"right", "seen", "percent"} over every answer in the pool's cells.
static func accuracy(evidence: Dictionary, pool: Array) -> Dictionary:
	var right := 0
	var seen := 0
	for c in pool:
		var r: Dictionary = evidence.cells.get(c.key, {})
		right += int(r.get("right", 0))
		seen += int(r.get("seen", 0))
	return {"right": right, "seen": seen, "percent": percent(right, seen)}


## Skill id -> {"right", "seen"}: each answer in a cell counts for every skill its
## unknown lists.
static func skill_stats(evidence: Dictionary, pool: Array) -> Dictionary:
	var out := {}
	for c in pool:
		var r: Dictionary = evidence.cells.get(c.key, {})
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
## answers, weakest first (ties: more answers first, then by id).
static func weakest_skills(evidence: Dictionary, pool: Array, n: int = WEAKEST) -> Array:
	var stats := skill_stats(evidence, pool)
	var out: Array = []
	for id in stats:
		var st: Dictionary = stats[id]
		if st.seen < MIN_ATTEMPTS:
			continue
		out.append({"id": id, "name": skill_name(id), "right": st.right, "seen": st.seen,
			"percent": percent(st.right, st.seen)})
	out.sort_custom(func(a, b):
		var fa: float = float(a.right) / a.seen
		var fb: float = float(b.right) / b.seen
		if fa != fb:
			return fa < fb
		if a.seen != b.seen:
			return a.seen > b.seen
		return a.id < b.id)
	return out.slice(0, n)


## right ÷ seen as a whole percent, or -1 when seen is 0.
static func percent(right: int, seen: int) -> int:
	return -1 if seen == 0 else roundi(100.0 * right / seen)


# ── Mastery ──────────────────────────────────────────────────
#
# Per-skill mastery (ADR-0002; docs/proposals/mastery-calibration.md §2-§5 and §9,
# accepted 2026-11-25 on FAL-1603). Every constant here is a value the proposal sets.
# The formulas are the ones the proposal's simulation tested
# (tests/sim/mastery_calibration_model.gd); tests/test_mastery_engine.gd checks the two
# agree. Pure arithmetic: no random numbers and no clock, so seeds still reproduce. No
# decay: a rating moves only when an answer is marked.
#
# evidence.mastery = {"version": 1, "skills": {skill id: record}}. A record is
# {"m": rating, "n": answers counted, "exam_ok": unassisted exam-tier successes,
# "ok_cells": distinct cells answered right, "recent_ok": the last cells answered right,
# "last": time of the last answer, "migrated": false}. A skill with no record is Not Yet
# Attempted: no rating, no level. Records are keyed by skill id only, never by course.

## The mastery record's format.
const MASTERY_VERSION := 1
## First evidence starts at the bottom of Level 1.
const MASTERY_START := 1.0
const MASTERY_FLOOR := 1.0
## The top of Level 7, so one miss does not drop a hard-won L7.
const MASTERY_CAP := 7.999
## Elo step: a matched success moves the rating K / 2.
const MASTERY_K := 1.0
## One rating point is one level.
const MASTERY_SCALE := 1.0
## A question of difficulty d (0-5) has rating d + 1: d3 sits at Level 4.
const MASTERY_OFFSET := 1.0
## Credit on a success, multiplied together. A 50-50 replaces the multiple-choice credit.
const MASTERY_CREDIT := {"none": 1.0, "mcq": 0.75, "fifty": 0.4, "hint": 0.5, "glancing": 0.75,
	"late": 1.0, "freeze": 1.0, "migrated": 0.75}
## Weight of a miss.
const MASTERY_MISS := {"wrong": 1.0, "timeout": 0.5}
## Upward damping by band: [below this rating, factor].
const MASTERY_DAMP := [[5.0, 1.0], [6.0, 0.5], [7.0, 0.25], [99.0, 0.125]]
## Assisted (hint, 50-50) and migrated successes stop at the edge of Exam Ready.
const MASTERY_ASSISTED_CAP := 3.999
## A success on one of the skill's last MASTERY_REPEAT_WINDOW cells answered right counts half.
const MASTERY_REPEAT_WINDOW := 3
const MASTERY_REPEAT_FACTOR := 0.5
## Distinct cells a record keeps: the gates need at most 5, and the save stays small.
const MASTERY_CELLS_KEPT := 16
## Exam Ready (L4+) needs this many unassisted successes at the exam tier: difficulty 3,
## or the skill's top difficulty when that is lower.
const MASTERY_EXAM_READY := 2
const MASTERY_EXAM_TIER := 3
## L6 needs right answers on this many distinct cells, L7 on MASTERY_L7_CELLS (or every
## cell of the skill, when it has fewer).
const MASTERY_L6_CELLS := 3
const MASTERY_L7_CELLS := 5
## The outcomes that are successes.
const MASTERY_SUCCESSES := ["right", "late", "glancing"]

## skill id -> the difficulty of its hardest question, skill id -> its easiest, and
## course -> {skill id: cells}.
static var _skill_tops: Dictionary = {}
static var _skill_bottoms: Dictionary = {}
static var _skill_counts: Dictionary = {}


## Mastery with nothing in it.
static func blank_mastery() -> Dictionary:
	return {"version": MASTERY_VERSION, "skills": {}}


## The skill ids a question tests (its unknown's "skills"), or [] for a probe.
static func question_skills(question: Dictionary) -> Array:
	if question.get("format") == "probe":
		return []
	var view: Dictionary = question.get("view", {})
	return QuestionEngine.unknown_of(QuestionEngine.type_of(view.get("type", "")), view.get("unknown", "")).get("skills", [])


## Updates the mastery of every skill a marked question tests (see record() for outcome
## and assists). Nothing changes for a probe (not counted in v1), or for an incomplete
## response that is not a timeout (nothing was marked).
static func record_mastery(evidence: Dictionary, question: Dictionary, result: Dictionary, now: int,
		outcome: String = "", assists: Array = []) -> void:
	var skills := question_skills(question)
	if skills.is_empty():
		return
	if outcome == "":
		if not bool(result.get("complete", true)):
			return
		outcome = ("glancing" if result.get("glancing", false) else "right") if result.correct else "wrong"
	var used := assists.duplicate()
	if is_choice(question) and not used.has("mcq"):
		used.append("mcq")
	if result.get("glancing", false) and not used.has("glancing"):
		used.append("glancing")
	if not (evidence.get("mastery") is Dictionary):
		evidence.mastery = blank_mastery()
	var book: Dictionary = evidence.mastery.get("skills", {})
	evidence.mastery.skills = book
	var d := int(question.get("level", 0))
	var shares := {}
	if not outcome in MASTERY_SUCCESSES:
		shares = mastery_blame(book, skills, d, misconception_skill(result.get("misconception", ""), skills))
	for s in skills:
		book[s] = mastery_update(book.get(s, {}), d, skill_top(s), outcome, used, question.cell,
			float(shares.get(s, 1.0)), now)


## The skill a misconception names, when it is one of skills, else "". A misconception's
## ref is "<skill id>#<index>" when the catalogue files it under a skill.
static func misconception_skill(ref: String, skills: Array) -> String:
	var named := ref.get_slice("#", 0)
	return named if ref != "" and skills.has(named) else ""


## The rating of a question of difficulty d.
static func question_rating(difficulty: int) -> float:
	return float(difficulty) + MASTERY_OFFSET


## The expected chance of success at rating m on a question rated e.
static func mastery_expect(m: float, e: float) -> float:
	return 1.0 / (1.0 + exp(-(m - e) / MASTERY_SCALE))


## The upward damping at rating m.
static func mastery_damp(m: float) -> float:
	for band in MASTERY_DAMP:
		if m < band[0]:
			return band[1]
	return MASTERY_DAMP[-1][1]


## The credit for a success with these assists, multiplied together.
static func mastery_credit(assists: Array) -> float:
	var c := 1.0
	for a in assists:
		if a == "mcq" and assists.has("fifty"):
			continue
		c *= float(MASTERY_CREDIT.get(a, 1.0))
	return c


## Whether a success with these assists is the learner's own work.
static func mastery_unassisted(assists: Array) -> bool:
	return not (assists.has("hint") or assists.has("fifty") or assists.has("migrated"))


## Blame shares for a miss on a question testing skills: (1 - p) / sum(1 - p), summing to
## one; or all of it on named, the skill a misconception names. book: skill id -> record
## (a skill without one is rated MASTERY_START). Writes nothing.
static func mastery_blame(book: Dictionary, skills: Array, difficulty: int, named: String = "") -> Dictionary:
	var out := {}
	if named != "" and skills.has(named):
		for s in skills:
			out[s] = 1.0 if s == named else 0.0
		return out
	var e := question_rating(difficulty)
	var total := 0.0
	for s in skills:
		total += 1.0 - mastery_expect(float(book.get(s, {}).get("m", MASTERY_START)), e)
	for s in skills:
		out[s] = (1.0 - mastery_expect(float(book.get(s, {}).get("m", MASTERY_START)), e)) / total
	return out


## One answer's effect on one skill's record ({} for Not Yet Attempted). Returns a new
## record and leaves rec alone.
##   difficulty   the question's 0-5 level
##   top          the skill's top difficulty (skill_top)
##   outcome      "right", "late", "glancing", "wrong" or "timeout"
##   assists      see mastery_credit
##   cell         the question's cell key
##   share        this skill's blame share on a miss (mastery_blame)
static func mastery_update(rec: Dictionary, difficulty: int, top: int, outcome: String, assists: Array = [],
		cell: String = "", share: float = 1.0, now: int = 0) -> Dictionary:
	var r: Dictionary = rec.duplicate(true) if not rec.is_empty() else \
		{"m": MASTERY_START, "n": 0, "exam_ok": 0, "ok_cells": [], "recent_ok": [], "last": 0, "migrated": false}
	var m := float(r.m)
	var e := question_rating(difficulty)
	r.n = int(r.n) + 1
	r.last = now
	# Migrated while it holds only replayed v7 evidence: one live answer ends that.
	r.migrated = assists.has("migrated") and (rec.is_empty() or bool(rec.get("migrated", false)))
	if outcome in MASTERY_SUCCESSES:
		var used: Array = assists.duplicate()
		if outcome != "right" and not used.has(outcome):
			used.append(outcome)
		# At or past the skill's hardest tier, a success counts as matched, not as easy.
		if difficulty >= top and m >= e:
			e = m
		var step := MASTERY_K * (1.0 - mastery_expect(m, e)) * mastery_credit(used) * mastery_damp(m)
		var recent: Array = r.recent_ok
		if cell != "" and recent.has(cell):
			step *= MASTERY_REPEAT_FACTOR
		var own := mastery_unassisted(used)
		var ceiling := MASTERY_CAP if own else maxf(m, MASTERY_ASSISTED_CAP)
		r.m = minf(ceiling, m + step)
		if own and not used.has("glancing") and difficulty >= mini(MASTERY_EXAM_TIER, top):
			r.exam_ok = int(r.exam_ok) + 1
		if cell != "":
			var cells: Array = r.ok_cells
			if not cells.has(cell) and cells.size() < MASTERY_CELLS_KEPT:
				cells.append(cell)
			recent.append(cell)
			while recent.size() > MASTERY_REPEAT_WINDOW:
				recent.pop_front()
	else:
		r.m = maxf(MASTERY_FLOOR, m - MASTERY_K * mastery_expect(m, e) * float(MASTERY_MISS.get(outcome, 1.0)) * share)
	return r


## Rebuilds mastery from v7 evidence, which kept only per-cell counts (save v7 -> v8,
## proposal §8). Cells are replayed in sorted key order; each cell's rights and wrongs
## are spread evenly with misses first on a tie (migration_order), at the cell's catalogue
## level, for every skill its unknown lists. Each success carries the "migrated" assist:
## credit 0.75, capped below Exam Ready and never counted toward it. v7 kept no order of
## which miss matched which misconception, so a multi-skill miss uses shared blame. A cell
## the catalogue no longer has is skipped. Pure: the same cells give the same records.
## Returns a mastery dictionary ({"version", "skills"}); evidence is not changed.
static func backfill_mastery(evidence: Dictionary) -> Dictionary:
	var out := blank_mastery()
	var cells = evidence.get("cells")
	if not (cells is Dictionary) or cells.is_empty():
		return out
	var catalogue := {}
	for c in requests():
		catalogue[c.key] = c
	var book: Dictionary = out.skills
	var keys: Array = cells.keys()
	keys.sort()
	for key in keys:
		if not catalogue.has(key) or not (cells[key] is Dictionary):
			continue
		var c: Dictionary = catalogue[key]
		var skills: Array = QuestionEngine.unknown_of(QuestionEngine.type_of(c.type), c.unknown).get("skills", [])
		if skills.is_empty():
			continue
		var rec: Dictionary = cells[key]
		var d := int(c.level)
		var when := int(rec.get("last", 0))
		for outcome in migration_order(int(rec.get("right", 0)), int(rec.get("wrong", 0))):
			var shares := {}
			if outcome == "wrong":
				shares = mastery_blame(book, skills, d)
			for s in skills:
				var before: Dictionary = book.get(s, {})
				var after := mastery_update(before, d, skill_top(s), outcome, ["migrated"], key,
					float(shares.get(s, 1.0)), when)
				after.last = maxi(when, int(before.get("last", 0)))
				book[s] = after
	return out


## A v7 cell's rights and wrongs as a replay order: spread evenly (Bresenham), a miss first
## whenever the two are tied, so the replay invents no order in the learner's favour.
static func migration_order(right: int, wrong: int) -> Array:
	var out := []
	var total := right + wrong
	var placed := 0
	for i in total:
		if placed < wrong and float(placed) <= float(i) * wrong / total:
			out.append("wrong")
			placed += 1
		else:
			out.append("right")
	return out


## The displayed level of a record: clamp(floor(m), 1, 7) after the evidence gates, or 0
## for Not Yet Attempted ({}). cells: how many cells the skill has (for the L6/L7 gates).
static func mastery_level(rec: Dictionary, cells: int = MASTERY_CELLS_KEPT) -> int:
	if rec.is_empty():
		return 0
	var lv := clampi(floori(float(rec.m)), 1, 7)
	var distinct := (rec.ok_cells as Array).size()
	if lv >= 7 and distinct < mini(MASTERY_L7_CELLS, cells):
		lv = 6
	if lv >= 6 and distinct < mini(MASTERY_L6_CELLS, cells):
		lv = 5
	if lv >= 4 and int(rec.exam_ok) < MASTERY_EXAM_READY:
		lv = 3
	return lv


## Skill id -> how many of the course's cells test it.
static func _cell_counts(course: String) -> Dictionary:
	if not _skill_counts.has(course):
		var counts := {}
		for c in requests(course):
			for s in QuestionEngine.unknown_of(QuestionEngine.type_of(c.type), c.unknown).get("skills", []):
				counts[s] = int(counts.get(s, 0)) + 1
		_skill_counts[course] = counts
	return _skill_counts[course]


## The difficulty of the hardest question the engine can ask on a skill, in any course
## (a record is shared by every course, so its top tier is too).
static func skill_top(skill: String) -> int:
	_skill_range()
	return int(_skill_tops.get(skill, 0))


## The difficulty of the easiest question the engine can ask on a skill, in any course.
static func skill_bottom(skill: String) -> int:
	_skill_range()
	return int(_skill_bottoms.get(skill, 0))


static func _skill_range() -> void:
	if not _skill_tops.is_empty():
		return
	for c in requests():
		for s in request_skills(c):
			_skill_tops[s] = maxi(int(_skill_tops.get(s, 0)), int(c.level))
			_skill_bottoms[s] = mini(int(_skill_bottoms.get(s, c.level)), int(c.level))


## The skill ids a request (or coverage cell) tests: its unknown's "skills".
static func request_skills(request: Dictionary) -> Array:
	return QuestionEngine.unknown_of(QuestionEngine.type_of(request.get("type", "")), request.get("unknown", "")).get("skills", [])


## The difficulty the overworld aims at for a skill (proposal §6, ADR-0002 §6):
## round(m - 1) within the skill's range, so a question sits where the learner is
## expected to succeed about half the time. A Not Yet Attempted skill gets its lowest
## tier, which is the first-visit scaffolding. Reading never creates a record.
static func mastery_target(evidence: Dictionary, skill: String) -> int:
	var rec: Dictionary = _book(evidence).get(skill, {})
	if rec.is_empty():
		return skill_bottom(skill)
	return clampi(roundi(float(rec.m) - 1.0), skill_bottom(skill), skill_top(skill))


## How many cells test a skill in a course ("" for every course).
static func skill_cells(skill: String, course: String = "") -> int:
	return int(_cell_counts(course).get(skill, 0))


## What the evidence says about one skill. Not Yet Attempted is {"skill", "attempted":
## false} and nothing more: no rating and no level to average or show as L1. Otherwise
## {"skill", "attempted": true, "level" 1-7, "rating", "progress" through the level
## (rating - floor(rating), for a bar), "exam_ready" (level 4+), "answers"}. course sets
## which cells count for the L6/L7 gates. Reading never creates a record.
static func mastery(evidence: Dictionary, skill: String, course: String = "") -> Dictionary:
	var rec: Dictionary = _book(evidence).get(skill, {})
	if rec.is_empty():
		return {"skill": skill, "attempted": false}
	var lv := mastery_level(rec, skill_cells(skill, course))
	var m := float(rec.m)
	return {"skill": skill, "attempted": true, "level": lv, "rating": m, "progress": m - floorf(m),
		"exam_ready": lv >= 4, "answers": int(rec.n)}


## mastery() for every skill a course can ask about, by skill id, attempted or not. The
## course filters what is read; it never copies, splits or resets a record.
static func mastery_levels(evidence: Dictionary, course: String = "") -> Dictionary:
	var out := {}
	for s in _cell_counts(course):
		out[s] = mastery(evidence, s, course)
	return out


## The evidence's skill records, or {} when it has none. Read-only use: it may be a copy.
static func _book(evidence: Dictionary) -> Dictionary:
	var mastery_data = evidence.get("mastery")
	if not (mastery_data is Dictionary) or not (mastery_data.get("skills") is Dictionary):
		return {}
	return mastery_data.skills
