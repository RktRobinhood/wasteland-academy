extends "res://tests/test_case.gd"
## The student's IB course in the engine (FAL-397): the four courses, which unknowns and
## methods each covers, the save and its migration, and that the planner, the dungeon
## (floors, warm-ups, prior learning, mini-bosses, bosses and link parts) and the map's
## progress only ever use cells the save's course covers. AA SL and AA HL cover every
## built question, so for them nothing changes.

const Dungeon_tests := preload("res://tests/test_dungeon.gd")
const COURSES := ["aa-sl", "aa-hl", "ai-sl", "ai-hl"]
const NOW := 1_800_000_000


func _save(course: String) -> Dictionary:
	var s := SaveData.blank()
	check(SaveData.set_course(s, course), "%s is a course" % course)
	return s


## The keys of the cells a course covers: every skill of the cell's unknown and the skill
## of its method are in the course.
func _keys(course: String) -> Dictionary:
	var out := {}
	for c in QuestionEngine.cells(false, [], course):
		out[c.key] = true
	return out


# ── The courses and what they cover ──────────────────────────

func test_the_four_courses_are_listed_in_order() -> void:
	check_eq(Courses.ids(), COURSES)
	check_eq(Courses.info("ai-sl").short, "AI SL")
	check_eq(Courses.info("no-such-course"), {})
	check(Courses.has("aa-hl") and not Courses.has("ib"), "has")


func test_a_save_is_on_aa_sl_until_it_picks_another() -> void:
	check_eq(Courses.of(SaveData.blank()), "aa-sl")
	check_eq(Courses.of({}), "aa-sl", "a save without a course")
	check_eq(Courses.of({"course": "from-a-newer-game"}), "aa-sl", "a course this game doesn't list")
	for c in COURSES:
		check_eq(Courses.of(_save(c)), c)


func test_a_skill_is_in_the_subtopic_of_its_first_two_parts() -> void:
	check_eq(Courses.subtopic_of("SL2.6.complete-square"), "SL2.6")
	check_eq(Courses.subtopic_of("AHL1.10.binomial"), "AHL1.10")
	check_eq(Courses.subtopic_of("AI-SL1.6.round-accuracy"), "AI-SL1.6")


func test_which_course_covers_which_skill() -> void:
	# SL1.1 is shared by all four; SL2.6 is AA's (SL and HL); AHL1.10 is AA HL's alone;
	# AI-SL1.6 is AI's; AI-AHL is AI HL's.
	var rows := [
		["SL1.1.convert", [true, true, true, true]],
		["SL2.6.vertex", [true, true, false, false]],
		["AHL1.10.binomial", [false, true, false, false]],
		["AI-SL1.6.bounds", [false, false, true, true]],
		["AI-AHL1.9.anything", [false, false, false, true]],
	]
	for row in rows:
		for i in COURSES.size():
			check_eq(Courses.covers_skill(COURSES[i], row[0]), row[1][i], "%s on %s" % [row[0], COURSES[i]])
	check(Courses.covers_skill("", "AHL1.10.binomial"), "no course, no filter")
	check(not Courses.covers_skill("no-such-course", "SL1.1.convert"), "a course nobody lists covers nothing")


func test_an_unknown_needs_every_one_of_its_skills() -> void:
	check(Courses.covers("aa-sl", {"skills": ["SL2.6.vertex", "SL2.7.x"]}), "all in AA SL")
	check(not Courses.covers("aa-sl", {"skills": ["SL2.6.vertex", "AHL1.10.binomial"]}), "one AA HL skill")
	check(Courses.covers("aa-hl", {"skills": ["SL2.6.vertex", "AHL1.10.binomial"]}), "both in AA HL")
	check(Courses.covers("ai-sl", {}), "prior learning lists no skills: every course assumes it")
	check(Courses.covers("ai-sl", {"skills": []}))
	check(not Courses.covers("no-such-course", {}), "a course nobody lists covers nothing, not even prior learning")
	check(Courses.covers("", {"skills": ["AHL1.10.binomial"]}), "no course, no filter")


## The built types that are on AA HL's list and no other course's (AHL subtopics).
const HL_ONLY := ["t1-ahl-counting"]


func test_aa_hl_covers_every_built_question_and_aa_sl_every_one_but_the_hl_only_types() -> void:
	var all := QuestionEngine.cells().size()
	check(all > 1000, "the game has %d cells" % all)
	var hl_only_cells := QuestionEngine.cells(false, HL_ONLY).size()
	var hl_only_probes := QuestionEngine.probes().filter(func(p): return p.type in HL_ONLY).size()
	check_eq(QuestionEngine.cells(false, [], "aa-hl").size(), all, "AA HL has every cell")
	check_eq(QuestionEngine.built_types("aa-hl"), QuestionEngine.built_types(), "AA HL has every built type")
	check_eq(QuestionEngine.probes(false, "aa-hl").size(), QuestionEngine.probes().size(), "AA HL has every probe")
	check_eq(QuestionEngine.cells(false, [], "aa-sl").size(), all - hl_only_cells, "AA SL has every cell but the HL-only types'")
	check_eq(QuestionEngine.built_types("aa-sl"), QuestionEngine.built_types().filter(func(id): return not id in HL_ONLY), "AA SL has every other built type")
	check_eq(QuestionEngine.probes(false, "aa-sl").size(), QuestionEngine.probes().size() - hl_only_probes, "AA SL has every other probe")
	for id in HL_ONLY:
		check(QuestionEngine.cells(false, [id], "aa-sl").is_empty(), "AA SL has none of %s" % id)
		check(not QuestionEngine.cells(false, [id], "aa-hl").is_empty(), "AA HL has %s" % id)


func test_the_ai_courses_are_smaller_and_ai_hl_holds_ai_sl() -> void:
	var all := QuestionEngine.cells().size()
	var sl := _keys("ai-sl")
	var hl := _keys("ai-hl")
	check(sl.size() > 0 and sl.size() < all, "AI SL has %d of %d cells" % [sl.size(), all])
	check(hl.size() >= sl.size() and hl.size() < all, "AI HL has %d cells" % hl.size())
	for k in sl:
		check(hl.has(k), "%s is in AI SL but not AI HL" % k)
	check(QuestionEngine.built_types("ai-sl").size() < QuestionEngine.built_types().size(), "AI SL has fewer types")


func test_every_cell_of_a_course_uses_only_skills_the_course_covers() -> void:
	for course in COURSES:
		for c in QuestionEngine.cells(false, [], course):
			var t := QuestionEngine.type_of(c.type)
			var u := QuestionEngine.unknown_of(t, c.unknown)
			for s in u.get("skills", []):
				check(Courses.covers_skill(course, s), "%s on %s: skill %s" % [c.key, course, s])
			var m := QuestionEngine.angle_info(t, c.unknown, c.angle)
			check(Courses.covers_method(course, m), "%s on %s: method %s" % [c.key, course, c.angle])


func test_a_method_the_course_does_not_cover_is_not_offered() -> void:
	# Some shared unknowns have a method that teaches a skill AI does not cover.
	var dropped := 0
	for course in ["ai-sl", "ai-hl"]:
		for t in QuestionEngine.catalogue().types:
			for u in t.get("unknowns", []):
				if not Courses.covers(course, u):
					continue
				var all := QuestionEngine.angles_for(t, u.id)
				var mine := QuestionEngine.angles_for(t, u.id, course)
				for a in mine:
					check(a in all, "%s: %s is one of its methods" % [u.id, a])
				dropped += all.size() - mine.size() if not mine.is_empty() else 0
	check(dropped > 0, "AI drops some methods")


# ── The save ─────────────────────────────────────────────────

func test_the_save_keeps_the_course() -> void:
	var s := SaveData.blank()
	check_eq(s.course, "aa-sl")
	check_eq(s.version, 5)
	check(SaveData.set_course(s, "ai-hl"))
	check_eq(SaveData.migrate(JSON.parse_string(JSON.stringify(s))).course, "ai-hl", "it survives the JSON round trip")


func test_a_save_from_before_courses_is_aa_sl() -> void:
	var v4 := {"version": 4, "settings": {"exam_only": false}, "cells": {"c1": {"seen": 2, "right": 1, "wrong": 1, "last": 5, "last_result": "wrong"}},
		"probes": {}, "history": [], "seed": 9, "class": null, "trees": {}, "lessons": {}, "scrap": 4,
		"runs": {"played": 1, "best_fights": 2, "questions": 5, "right": 3}, "dungeon": {}, "bazaar": SaveData.blank_bazaar()}
	var s := SaveData.migrate(v4)
	check_eq(s.version, SaveData.VERSION)
	check_eq(s.course, "aa-sl")
	check_eq(s.cells.c1.seen, 2, "what was done is kept")
	check_eq(s.scrap, 4)


func test_changing_course_keeps_the_progress_on_shared_cells() -> void:
	var s := _save("aa-hl")
	var shared: Dictionary = QuestionEngine.cells(false, [], "ai-sl")[0]
	SaveData.record(s, shared.key, true, NOW)
	check(SaveData.set_course(s, "ai-sl"))
	check_eq(s.cells[shared.key].seen, 1, "the record stays")
	check_eq(Courses.of(s), "ai-sl")
	check(SaveData.set_course(s, "aa-hl"))
	check_eq(s.cells[shared.key].right, 1, "and is there when the student goes back")


func test_a_course_that_is_not_listed_is_refused() -> void:
	var s := _save("ai-sl")
	check(not SaveData.set_course(s, "ib-diploma"))
	check(not SaveData.set_course(s, ""))
	check_eq(s.course, "ai-sl", "nothing changed")


# ── The planner, the dungeon and the map ─────────────────────

func test_the_planner_only_plans_cells_the_course_covers() -> void:
	for course in COURSES:
		var keys := _keys(course)
		var s := _save(course)
		var rules := {}
		for i in 150:
			var v := Planner.next(s, NOW)
			rules[v.rule] = true
			if v.rule == "probe":
				check(QuestionEngine.probes(false, course).any(func(p): return p.type == v.type and p.index == v.probe), "%s: probe %s" % [course, v.type])
				continue
			var key := QuestionEngine.cell_key(v.type, v.unknown, v.rep, v.angle)
			check(keys.has(key), "%s planned %s" % [course, key])
			var q := QuestionEngine.make(v)
			check(not q.has("error"), "%s: %s" % [course, q.get("error", "")])
		check(rules.has("unseen"), "%s: unseen cells come first" % course)


func test_the_planner_plans_a_region_from_the_courses_types() -> void:
	for course in COURSES:
		var s := _save(course)
		for region in MapLink.region_ids():
			if not Progress.is_built(region, course):
				check(Planner.next(s, NOW, {"region": region}).has("error"), "%s has nothing in %s" % [course, region])
				continue
			var types := Dungeon.region_types(region, course)
			for i in 20:
				var v := Planner.next(s, NOW, {"region": region, "probes": false})
				check(v.type in types, "%s in %s: %s" % [course, region, v.type])


func test_a_run_only_asks_cells_the_course_covers() -> void:
	# Every answered cell: floors, warm-ups, prior learning, mini-bosses, bosses and links.
	# Floor 4 serves every level and every type of the region.
	for course in COURSES:
		var keys := _keys(course)
		var asked := 0
		for start in [1, 4]:
			var r := Run.new(_save(course), Dungeon.ALL, start, 11 + start)
			r.clock = func() -> int: return NOW
			Dungeon_tests.immortal(r)
			Dungeon_tests.sim(r, 0.6, 2)
			check(r.state == "ended" and r.summary.get("reason", "") != "no-questions", "%s from floor %d ended on %s" % [course, start, r.summary.get("reason", "")])
			for e in r.answers:
				asked += 1
				check(keys.has(e.cell), "%s asked %s" % [course, e.cell])
		check(asked > 30, "%s: only %d answers" % [course, asked])


func test_bosses_chain_only_steps_the_course_covers() -> void:
	for course in COURSES:
		var keys := _keys(course)
		for kind in ["mini", "boss"]:
			for seed_no in range(1, 31):
				var plan := Dungeon.boss_plan(seed_no, Dungeon.ALL, 4, kind, [], course)
				if plan.is_empty():
					continue
				for st in plan.steps:
					var t := QuestionEngine.type_of(st.type)
					check(QuestionEngine.covered(course, t, QuestionEngine.unknown_of(t, st.unknown)), "%s %s: %s %s" % [course, kind, st.type, st.unknown])
					check(keys.has(QuestionEngine.cell_key(st.type, st.unknown, st.rep, st.angle)), "%s %s: step cell" % [course, kind])
				if not plan.link.is_empty():
					check(keys.has(QuestionEngine.cell_key(plan.link.type, plan.link.unknown, plan.link.rep, plan.link.angle)), "%s: link cell" % course)


func test_warm_ups_and_prior_learning_follow_the_course() -> void:
	for course in COURSES:
		var keys := _keys(course)
		for c in Dungeon.prior_cells("quadratics", false, course):
			check(keys.has(c.key), "%s warm-up %s" % [course, c.key])
		check(not Dungeon.prior_cells("quadratics", false, course).is_empty(), "%s has prior learning" % course)
		for cell in QuestionEngine.cells(false, ["fn-solve-quadratic"], "aa-sl").slice(0, 8):
			var p := Dungeon.prior_for("quadratics", cell.key, "s", [], course)
			if p != "":
				check(QuestionEngine.built_types(course).has(p), "%s: prior type %s" % [course, p])


func test_the_map_counts_only_the_courses_cells() -> void:
	for course in COURSES:
		var s := _save(course)
		for region in ["quadratics", "exp-log", Dungeon.ALL]:
			var want := 0
			for c in Progress.catalogue_cells(region, false, course):
				want += 1
			check_eq(Progress.coverage(s, region).total, want, "%s: %s total" % [course, region])
			check(want <= Progress.catalogue_cells(region).size(), "%s: %s is a subset" % [course, region])
	var aa: int = Progress.coverage(_save("aa-sl"), Dungeon.ALL).total
	var ai: int = Progress.coverage(_save("ai-sl"), Dungeon.ALL).total
	check(ai < aa, "AI SL's island has fewer cells (%d) than AA SL's (%d)" % [ai, aa])
	# A region lights up for a course when the course covers a built type of it.
	for course in COURSES:
		for region in MapLink.region_ids():
			var m: bool = Progress.is_built(region, course)
			check_eq(m, not Dungeon.region_types(region, course).is_empty(), "%s %s" % [course, region])
			if course in ["aa-sl", "aa-hl"]:
				check_eq(m, Progress.is_built(region), "%s lights up what the game has" % course)
