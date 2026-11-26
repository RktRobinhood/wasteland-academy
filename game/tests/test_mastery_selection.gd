extends "res://tests/test_case.gd"
## Overworld selection aims at each skill's mastery (#268, FAL-1669, ADR-0002 §6;
## docs/proposals/mastery-calibration.md §6 and §9). The proposal's §11 checks 8 and 9:
## the target difficulty follows the skill's rating, every question asked is in the
## course's syllabus, and a skill keeps one record across course switches.
##
##   godot --headless --path game --script res://tests/run_tests.gd -- --only=mastery_selection

const NOW := 1_800_000_000
const COURSES := ["aa-sl", "aa-hl", "ai-sl", "ai-hl"]


static func _rec(m: float) -> Dictionary:
	return {"m": m, "n": 4, "exam_ok": 0, "ok_cells": [], "recent_ok": [], "last": 0, "migrated": false}


static func _set_rating(save: Dictionary, skill: String, m: float) -> void:
	if not (save.get("mastery") is Dictionary):
		save.mastery = MathsEngine.blank_mastery()
	save.mastery.skills[skill] = _rec(m)


## A skill of the course whose one-skill cells span at least three difficulties, and
## those cells: {"skill", "cells"}.
static func _spread_skill(course: String) -> Dictionary:
	var by_skill := {}
	for c in QuestionEngine.cells(false, [], course):
		var skills := MathsEngine.request_skills(c)
		if skills.size() == 1:
			var list: Array = by_skill.get(skills[0], [])
			list.append(c)
			by_skill[skills[0]] = list
	var ids := by_skill.keys()
	ids.sort()
	for s in ids:
		var levels := {}
		for c in by_skill[s]:
			levels[int(c.level)] = true
		if levels.size() >= 3:
			return {"skill": s, "cells": by_skill[s]}
	return {}


static func _levels(cells: Array) -> Array:
	var seen := {}
	for c in cells:
		seen[int(c.level)] = true
	var out := seen.keys()
	out.sort()
	return out


## The level of the pool nearest target.
static func _nearest(levels: Array, target: int) -> int:
	var best: int = levels[0]
	for l in levels:
		if absi(int(l) - target) < absi(best - target):
			best = int(l)
	return best


static func _level_of(cells: Array, v: Dictionary) -> int:
	var key := QuestionEngine.cell_key(v.type, v.unknown, v.rep, v.angle)
	for c in cells:
		if c.key == key:
			return int(c.level)
	return -1


# ── §11 check 8: the target follows the rating ───────────────

func test_the_target_is_round_m_minus_one_within_the_skills_range() -> void:
	var pick := _spread_skill("aa-sl")
	check(not pick.is_empty(), "a skill spans three difficulties")
	var s: String = pick.skill
	var lo := MathsEngine.skill_bottom(s)
	var hi := MathsEngine.skill_top(s)
	check(lo < hi, "%s has a range" % s)
	var save := SaveData.blank()
	check_eq(MathsEngine.mastery_target(save, s), lo, "Not Yet Attempted aims at the lowest tier")
	check(not save.mastery.skills.has(s), "reading the target creates no record")
	for m in [1.0, 1.49, 1.5, 2.0, 2.6, 3.5, 4.0, 4.49, 5.2, 6.0, 7.999]:
		_set_rating(save, s, m)
		check_eq(MathsEngine.mastery_target(save, s), clampi(roundi(m - 1.0), lo, hi), "%s at m = %s" % [s, m])


func test_a_first_visit_asks_the_skills_lowest_tier_first() -> void:
	var pick := _spread_skill("aa-sl")
	var cells: Array = pick.cells
	var lo: int = _levels(cells)[0]
	var save := SaveData.blank()
	var asked_lo := 0
	for i in mini(20, cells.size()):
		var v := Planner.next(save, NOW, {"cells": cells, "probes": false})
		check_eq(v.rule, "unseen")
		var level := _level_of(cells, v)
		# The lowest tier until its cells are used up, then the next one up.
		var left := cells.filter(func(c): return not save.cells.has(c.key) and int(c.level) == lo)
		if not left.is_empty():
			check_eq(level, lo, "an unattempted skill starts at its lowest tier")
			asked_lo += 1
		SaveData.record(save, QuestionEngine.cell_key(v.type, v.unknown, v.rep, v.angle), true, NOW - 10 * Planner.RECENT)
	check(asked_lo > 0, "the lowest tier was asked")


func test_the_asked_difficulty_follows_the_rating() -> void:
	var pick := _spread_skill("aa-sl")
	var s: String = pick.skill
	var cells: Array = pick.cells
	var levels := _levels(cells)
	var save := SaveData.blank()
	# Every cell seen and right long ago, so the frequency rule picks.
	for c in cells:
		SaveData.record(save, c.key, true, NOW - 10 * Planner.RECENT)
	var asked_at := {}
	for m in [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.5]:
		_set_rating(save, s, m)
		var want := _nearest(levels, MathsEngine.mastery_target(save, s))
		for i in 12:
			var v := Planner.next(save, NOW, {"cells": cells, "probes": false})
			check_eq(v.rule, "frequency")
			check_eq(_level_of(cells, v), want, "%s at m = %s asks d%d" % [s, m, want])
		asked_at[m] = want
	check(int(asked_at[7.5]) > int(asked_at[1.0]), "a higher rating asks harder questions")


func test_a_recent_wrong_cell_still_comes_back_whatever_its_level() -> void:
	# Rule 2 is unchanged: the oldest recent miss returns, even off the target.
	var pick := _spread_skill("aa-sl")
	var s: String = pick.skill
	var cells: Array = pick.cells
	var save := SaveData.blank()
	for c in cells:
		SaveData.record(save, c.key, true, NOW - 10 * Planner.RECENT)
	var top_cell: Dictionary = cells.filter(func(c): return int(c.level) == int(_levels(cells)[-1]))[0]
	SaveData.record(save, top_cell.key, false, NOW - 60)
	# Three other answers since, so the miss is outside the spacing window.
	for c in cells.filter(func(c): return c.key != top_cell.key).slice(0, Planner.SPACING):
		SaveData.record(save, c.key, true, NOW - 10 * Planner.RECENT)
	_set_rating(save, s, 1.0)
	var v := {}
	for i in 10:
		v = Planner.next(save, NOW, {"cells": cells, "probes": false})
		if v.rule != "probe":
			break
	check_eq(v.rule, "wrong")
	check_eq(QuestionEngine.cell_key(v.type, v.unknown, v.rep, v.angle), top_cell.key)


func test_every_type_keeps_its_share_and_targeting_draws_no_extra_numbers() -> void:
	# The same save with and without ratings: the planner's stream gives the same seeds,
	# formats and rules, and the types asked still cover the pool's types.
	var plain := SaveData.blank()
	var rated := SaveData.blank()
	var course := Courses.of(plain)
	var pool := QuestionEngine.cells(false, [], course)
	for c in pool:
		SaveData.record(plain, c.key, true, NOW - 10 * Planner.RECENT)
		SaveData.record(rated, c.key, true, NOW - 10 * Planner.RECENT)
	for c in pool:
		for s in MathsEngine.request_skills(c):
			_set_rating(rated, s, 6.0)
	var types := {}
	for i in 300:
		var a := Planner.next(plain, NOW, {"probes": false})
		var b := Planner.next(rated, NOW, {"probes": false})
		check_eq(b.seed, a.seed, "the question's seed comes from the same draw")
		check_eq(b.rule, a.rule)
		check_eq(plain.seed, rated.seed)
		types[b.type] = true
	check(types.size() > 10, "a rated save still asks many types (%d)" % types.size())


func test_the_thunderdome_keeps_its_own_selection() -> void:
	# Proposal §7 is a separate slice: ratings do not change a Thunderdome question.
	var plain := SaveData.blank()
	var rated := SaveData.blank()
	var course := Courses.of(plain)
	var cells := Dungeon.floor_cells(Dungeon.THUNDERDOME, 3, false, [], course)
	check(not cells.is_empty(), "the Thunderdome has a floor")
	for c in cells:
		for s in MathsEngine.request_skills(c):
			_set_rating(rated, s, 7.0)
	for i in 30:
		var opts := {"cells": cells, "probes": false, "region": Dungeon.THUNDERDOME}
		check_eq(Planner.next(rated, NOW, opts.duplicate()), Planner.next(plain, NOW, opts.duplicate()))


# ── §11 check 9: the course's syllabus, one record per skill ──

func test_every_question_is_in_the_courses_syllabus_with_ratings() -> void:
	for course in COURSES:
		var s := SaveData.blank()
		check(SaveData.set_course(s, course), "%s is a course" % course)
		var keys := {}
		for c in QuestionEngine.cells(false, [], course):
			keys[c.key] = true
		# Ratings on every skill of every course, the other courses' skills too.
		var i := 0
		for c in QuestionEngine.cells():
			for sk in MathsEngine.request_skills(c):
				_set_rating(s, sk, 1.0 + float(i % 7))
				i += 1
		var book_size: int = s.mastery.skills.size()
		for n in 200:
			var v := Planner.next(s, NOW)
			if v.rule == "probe":
				continue
			var key := QuestionEngine.cell_key(v.type, v.unknown, v.rep, v.angle)
			check(keys.has(key), "%s asked %s" % [course, key])
			SaveData.record(s, key, n % 3 != 0, NOW)
		check_eq(s.mastery.skills.size(), book_size, "%s: planning adds no record" % course)


func test_a_skill_keeps_one_record_and_one_target_across_course_switches() -> void:
	var shared := ""
	for c in QuestionEngine.cells(false, [], "aa-sl"):
		for sk in MathsEngine.request_skills(c):
			if COURSES.all(func(course): return Courses.covers_skill(course, sk)):
				shared = sk
				break
		if shared != "":
			break
	check(shared != "", "a skill every course covers")
	var save := SaveData.blank()
	_set_rating(save, shared, 4.3)
	var before: Dictionary = save.mastery.skills[shared].duplicate(true)
	var target := MathsEngine.mastery_target(save, shared)
	for course in COURSES + ["aa-sl"]:
		check(SaveData.set_course(save, course), course)
		for n in 30:
			Planner.next(save, NOW)
		check_eq(save.mastery.skills.size(), 1, "%s: still one record" % course)
		check_eq(save.mastery.skills[shared], before, "%s: the record is untouched" % course)
		check_eq(MathsEngine.mastery_target(save, shared), target, "%s: the same target" % course)
