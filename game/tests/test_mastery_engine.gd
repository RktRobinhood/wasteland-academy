extends "res://tests/test_case.gd"
## Per-skill mastery in MathsEngine (#268, FAL-1667, ADR-0002;
## docs/proposals/mastery-calibration.md §2-§5 and §9, accepted 2026-11-25 on FAL-1603).
## The tests follow the proposal's §11 checks 1-6 and 11-13; the numbers they expect are
## the ones the proposal prints.
##
##   godot --headless --path game --script res://tests/run_tests.gd -- --only=mastery_engine

const M := preload("res://tests/sim/mastery_calibration_model.gd")
const E := preload("res://engine/maths_engine.gd")


static func _rec(m: float, exam_ok: int = 0, cells: Array = []) -> Dictionary:
	return {"m": m, "n": 4, "exam_ok": exam_ok, "ok_cells": cells.duplicate(), "recent_ok": [], "last": 0, "migrated": false}


static func _near(a: float, b: float, eps: float = 0.005) -> bool:
	return absf(a - b) < eps


## The first cell of the course whose unknown lists exactly n skills, made into a question.
static func _question(n_skills: int, fmt: String = "value", seed: int = 1) -> Dictionary:
	for c in E.requests("aa-sl"):
		var skills: Array = QuestionEngine.unknown_of(QuestionEngine.type_of(c.type), c.unknown).get("skills", [])
		if skills.size() != n_skills:
			continue
		var q := E.generate({"type": c.type, "unknown": c.unknown, "rep": c.rep, "angle": c.angle, "format": fmt, "seed": seed})
		if not q.has("error") and q.format == fmt:
			return q
	return {}


# ── The engine uses the tested formulas ──────────────────────

func test_the_engine_agrees_with_the_simulated_model() -> void:
	# The model the proposal's simulation ran: the same answers give the same record.
	var cases := 0
	for m in [1.0, 2.5, 3.5, 4.5, 5.2, 6.2, 7.4]:
		for d in range(0, 6):
			for top in [3, 5]:
				for outcome in ["right", "late", "glancing", "wrong", "timeout"]:
					for assists in [[], ["mcq"], ["hint"], ["mcq", "fifty"], ["freeze"], ["migrated"]]:
						var base := _rec(m, 1, ["a", "b"])
						base.recent_ok = ["b"]
						for cell in ["b", "c"]:
							var got := E.mastery_update(base, d, top, outcome, assists, cell, 0.6, 5)
							var want := M.update(base, d, top, outcome, assists, cell, 0.6)
							cases += 1
							if not _near(float(got.m), float(want.m), 1e-9) or got.n != want.n or got.exam_ok != want.exam_ok \
									or got.ok_cells != want.ok_cells or got.recent_ok != want.recent_ok:
								fail("m %s d%d top %d %s %s %s: engine %s, model %s" % [m, d, top, outcome, assists, cell, got, want])
								return
							check_eq(E.mastery_level(got, 4), M.level(want, 4), "the same level")
	check(cases > 4000, "a wide grid: %d" % cases)
	check_eq(E.MASTERY_DAMP, M.DAMP)
	check_eq(E.MASTERY_CREDIT, M.CREDIT)
	check_eq(E.MASTERY_MISS, M.MISS)


# ── Check 1: harder success moves further; easy failure drops at once ─

func test_harder_success_moves_further() -> void:
	var steps: Array = []
	for d in [1, 2, 3, 4, 5]:
		steps.append(float(E.mastery_update(_rec(3.5), d, 5, "right").m) - 3.5)
	for i in range(1, steps.size()):
		check(steps[i] > steps[i - 1], "d%d moves further than d%d: %s" % [i + 1, i, steps])
	for pair in [[0, 0.18], [1, 0.38], [2, 0.62], [3, 0.82], [4, 0.92]]:
		check(_near(steps[pair[0]], pair[1]), "from m 3.5 at d%d: %s" % [pair[0] + 1, steps[pair[0]]])


func test_harder_failure_costs_less_and_an_easy_miss_drops_a_level() -> void:
	var l4 := _rec(4.5, 2, ["a"])
	check_eq(E.mastery_level(l4), 4)
	var costs := {}
	for d in [1, 3, 5]:
		costs[d] = 4.5 - float(E.mastery_update(l4, d, 5, "wrong").m)
	check(_near(costs[5], 0.18) and _near(costs[3], 0.62) and _near(costs[1], 0.92), str(costs))
	check(costs[5] < costs[3] and costs[3] < costs[1], "a harder miss costs less")
	for d in range(0, 4):
		check_eq(E.mastery_level(E.mastery_update(l4, d, 5, "wrong")), 3, "one d%d miss drops L4 to L3" % d)
	# From L6, two d1 misses fall to L4 (6.2 -> 5.22 -> 4.25).
	var r := _rec(6.2, 3, ["a", "b", "c"])
	r = E.mastery_update(r, 1, 5, "wrong")
	check(_near(float(r.m), 5.22, 0.01), str(r.m))
	r = E.mastery_update(r, 1, 5, "wrong")
	check(_near(float(r.m), 4.25, 0.01), str(r.m))
	check_eq(E.mastery_level(r), 4)


# ── Check 2: a matched success moves 0.5 x damping ───────────

func test_a_matched_success_moves_half_a_level_times_damping() -> void:
	for m in [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0]:
		var d := int(m) - 1
		var after := float(E.mastery_update(_rec(m), d, 5, "right").m)
		check(_near(after - m, 0.5 * E.mastery_damp(m), 1e-6), "m %s at d%d: %s" % [m, d, after - m])
	check_eq([E.mastery_damp(4.9), E.mastery_damp(5.0), E.mastery_damp(6.0), E.mastery_damp(7.0)], [1.0, 0.5, 0.25, 0.125])
	# At an exact match (p = 0.5) the step is 0.5 x damping: two per level up to L5.
	var m := E.MASTERY_START
	var per_level: Array = []
	for target in [2.0, 3.0, 4.0, 5.0, 6.0, 7.0]:
		var n := 0
		while m < target - 1e-9:
			m += E.MASTERY_K * (1.0 - E.mastery_expect(m, m)) * E.mastery_damp(m)
			n += 1
		per_level.append(n)
	check_eq(per_level.slice(0, 4), [2, 2, 2, 2], "two matched successes per level up to L5")
	check(per_level[4] > per_level[3] and per_level[5] > per_level[4], "L6 and L7 need more: %s" % [per_level])


func test_a_varied_all_right_run_reaches_each_level_when_the_proposal_says() -> void:
	# The planner's whole-number difficulties, a new cell each time: L4 at 7, L5 at 8,
	# L6 at 12, L7 at 19 (proposal §3).
	var rec := {}
	var first := {}
	for i in range(1, 40):
		var m: float = rec.m if not rec.is_empty() else E.MASTERY_START
		rec = E.mastery_update(rec, clampi(roundi(m - 1.0), 0, 5), 5, "right", [], "cell-%d" % i)
		var lv := E.mastery_level(rec)
		if not first.has(lv):
			first[lv] = i
	check_eq([first.get(4), first.get(5), first.get(6), first.get(7)], [7, 8, 12, 19], str(first))


# ── Check 3: assists and outcomes ────────────────────────────

func test_hint_and_fifty_reduce_credit_freeze_and_late_do_not() -> void:
	var up := func(outcome: String, assists: Array) -> float:
		return float(E.mastery_update(_rec(2.0), 1, 5, outcome, assists).m) - 2.0
	var full: float = up.call("right", [])
	check_eq(up.call("late", []), full, "late is full credit")
	check_eq(up.call("right", ["freeze"]), full, "Time Freeze is full credit")
	check(_near(up.call("right", ["hint"]), full * 0.5, 1e-9), "hint halves it")
	check(_near(up.call("right", ["mcq"]), full * 0.75, 1e-9), "multiple choice")
	check(_near(up.call("glancing", []), full * 0.75, 1e-9), "glancing")
	check(_near(up.call("right", ["mcq", "fifty"]), full * 0.4, 1e-9), "50-50 replaces the MCQ credit")
	check(_near(up.call("right", ["mcq", "fifty", "hint"]), full * 0.2, 1e-9), "hint + 50-50 multiply")
	var wrong := 2.0 - float(E.mastery_update(_rec(2.0), 1, 5, "wrong").m)
	var timeout := 2.0 - float(E.mastery_update(_rec(2.0), 1, 5, "timeout").m)
	check(_near(timeout, wrong * 0.5, 1e-9), "a timeout is half a miss")


func test_assisted_only_evidence_never_shows_exam_ready() -> void:
	for assists in [["hint"], ["mcq", "fifty"], ["migrated"]]:
		var rec := {}
		for i in 60:
			rec = E.mastery_update(rec, 3, 5, "right", assists, "c%d" % i)
		check(float(rec.m) <= E.MASTERY_ASSISTED_CAP, "%s stops at 3.999: %s" % [assists, rec.m])
		check_eq(int(rec.exam_ok), 0, "%s never counts for Exam Ready" % [assists])
		check_eq(E.mastery_level(rec), 3, str(assists))
	# Glancing and below-tier successes do not count for Exam Ready either.
	var g := E.mastery_update(E.mastery_update({}, 3, 5, "glancing"), 3, 5, "right", ["glancing"])
	check_eq(int(g.exam_ok), 0, "glancing is not exam-tier evidence")
	var low := {}
	for i in 30:
		low = E.mastery_update(low, 2, 5, "right", [], "c%d" % i)
	check_eq(int(low.exam_ok), 0, "d2 is below the exam tier")
	check_eq(E.mastery_level(low), 3, "rating past 4 without exam-tier work stays L3: m %s" % low.m)
	# Two unassisted d3 successes open L4.
	low = E.mastery_update(low, 3, 5, "right", [], "x")
	check_eq(E.mastery_level(low), 3, "one is not enough")
	low = E.mastery_update(low, 3, 5, "right", [], "y")
	check(float(low.m) >= 5.0, "the d2 work had already lifted the rating: %s" % low.m)
	check_eq(E.mastery_level(low), 5, "the gate opens to the rating's own level")
	# A skill whose hardest question is d2 has d2 as its exam tier.
	check_eq(int(E.mastery_update({}, 2, 2, "right").exam_ok), 1, "the skill's top tier when below d3")
	# An assisted success above the cap does not pull the rating down.
	check_eq(float(E.mastery_update(_rec(4.6, 2), 3, 5, "right", ["hint"]).m), 4.6)


func test_record_reads_the_format_and_the_result() -> void:
	var q := _question(1, "value")
	var mcq := _question(1, "mcq")
	check(not q.is_empty() and not mcq.is_empty(), "questions to answer")
	var skill: String = E.question_skills(q)[0]
	var ev := E.blank_evidence()
	E.record(ev, q, E.mark(q, E.model_response(q, true)), 100)
	var typed := float(ev.mastery.skills[skill].m) - 1.0
	check_eq(int(ev.mastery.skills[skill].last), 100)
	var ev2 := E.blank_evidence()
	E.record(ev2, mcq, E.mark(mcq, E.model_response(mcq, true)), 100)
	var mskill: String = E.question_skills(mcq)[0]
	var picked := float(ev2.mastery.skills[mskill].m) - 1.0
	var expect_typed := float(E.mastery_update({}, int(q.level), E.skill_top(skill), "right").m) - 1.0
	var expect_mcq := float(E.mastery_update({}, int(mcq.level), E.skill_top(mskill), "right", ["mcq"]).m) - 1.0
	check(_near(typed, expect_typed, 1e-9), "typed: %s vs %s" % [typed, expect_typed])
	check(_near(picked, expect_mcq, 1e-9), "a choice question takes the MCQ credit: %s vs %s" % [picked, expect_mcq])
	# The fight's own outcome and lifelines.
	var ev3 := E.blank_evidence()
	E.record(ev3, q, {"correct": false, "complete": false}, 100, "timeout")
	check(ev3.mastery.skills.has(skill), "a timeout is marked")
	check(float(ev3.mastery.skills[skill].m) == 1.0, "and floors at 1")
	var ev4 := E.blank_evidence()
	E.record(ev4, q, E.mark(q, E.model_response(q, true)), 100, "", ["hint"])
	check(_near(float(ev4.mastery.skills[skill].m) - 1.0, expect_typed * 0.5, 1e-9), "a hint halves it")


func test_incomplete_responses_and_probes_do_not_move_mastery() -> void:
	var q := _question(1)
	var ev := E.blank_evidence()
	E.record(ev, q, E.mark(q, {}), 100)
	check(ev.mastery.skills.is_empty(), "an incomplete response is not marked")
	var p := E.generate({"type": "fn-quadratic-features", "probe": 2, "format": "probe"})
	E.record(ev, p, E.mark(p, E.model_response(p, true)), 100)
	check(ev.mastery.skills.is_empty(), "probes are not counted in v1")
	check_eq(ev.probes.size(), 1, "the probe itself is still recorded")


func test_repeated_cells_count_half() -> void:
	var one := {}
	var ten := {}
	for i in 10:
		one = E.mastery_update(one, 3, 5, "right", [], "same")
		ten = E.mastery_update(ten, 3, 5, "right", [], "c%d" % i)
	check(_near(float(one.m), 4.74, 0.01), "one repeated cell: %s" % one.m)
	check(_near(float(ten.m), 5.57, 0.01), "ten cells: %s" % ten.m)
	check_eq((one.recent_ok as Array).size(), 3, "the window keeps the last 3")
	var many := {}
	for i in 40:
		many = E.mastery_update(many, 3, 5, "right", [], "c%d" % i)
	check_eq((many.ok_cells as Array).size(), E.MASTERY_CELLS_KEPT, "distinct cells stop at 16")


# ── Check 4: multi-skill questions ───────────────────────────

func test_shared_blame_sums_to_one_answer() -> void:
	var book := {"A": _rec(5.0), "B": _rec(2.5)}
	var shares := E.mastery_blame(book, ["A", "B"], 3)
	check(_near(float(shares.A), 0.25, 0.01) and _near(float(shares.B), 0.75, 0.01), str(shares))
	check(_near(float(shares.A) + float(shares.B), 1.0, 1e-9), "sums to one")
	var three := E.mastery_blame({"A": _rec(5.0)}, ["A", "B", "C"], 2)
	check(_near(float(three.A) + float(three.B) + float(three.C), 1.0, 1e-9), "three skills, one miss")
	check_eq(E.mastery_blame(book, ["A", "B"], 3, "B"), {"A": 0.0, "B": 1.0}, "a named misconception takes it all")
	check_eq(E.misconception_skill("SL2.1.gradient#0", ["SL2.1.gradient", "SL2.1.intercepts"]), "SL2.1.gradient")
	check_eq(E.misconception_skill("fn-line-from-conditions#3", ["SL2.1.gradient"]), "", "a type's own ref names no skill")
	check_eq(E.misconception_skill("SL5.1.limit#0", ["SL2.1.gradient"]), "", "a skill the question does not test")
	check_eq(E.misconception_skill("", ["SL2.1.gradient"]), "")


func test_record_credits_every_skill_and_shares_a_miss() -> void:
	var q := _question(2)
	check(not q.is_empty(), "a two-skill question")
	var skills := E.question_skills(q)
	var ev := E.blank_evidence()
	E.record(ev, q, E.mark(q, E.model_response(q, true)), 100)
	for s in skills:
		check(ev.mastery.skills.has(s) and float(ev.mastery.skills[s].m) > 1.0, "%s gets the full success" % s)
	check_eq(float(ev.mastery.skills[skills[0]].m), float(ev.mastery.skills[skills[1]].m), "the same step each")
	# A miss with no named misconception: each skill takes its share.
	var ev2 := E.blank_evidence()
	ev2.mastery.skills[skills[0]] = _rec(5.0, 2, ["a"])
	ev2.mastery.skills[skills[1]] = _rec(2.5)
	var shares := E.mastery_blame(ev2.mastery.skills, skills, int(q.level))
	E.record(ev2, q, {"correct": false, "complete": true, "glancing": false, "misconception": ""}, 100)
	for s in skills:
		var want := float(E.mastery_update(_rec(5.0, 2, ["a"]) if s == skills[0] else _rec(2.5), int(q.level),
			E.skill_top(s), "wrong", [], "", float(shares[s])).m)
		check(_near(float(ev2.mastery.skills[s].m), want, 1e-9), "%s takes its share" % s)
	# A misconception filed under one skill takes the whole miss.
	var ev3 := E.blank_evidence()
	ev3.mastery.skills[skills[0]] = _rec(4.5, 2, ["a"])
	ev3.mastery.skills[skills[1]] = _rec(4.5, 2, ["a"])
	E.record(ev3, q, {"correct": false, "complete": true, "glancing": false, "misconception": skills[1] + "#0"}, 100)
	check_eq(float(ev3.mastery.skills[skills[0]].m), 4.5, "the other skill is not blamed")
	check(float(ev3.mastery.skills[skills[1]].m) < 4.5, "the named skill takes the miss")


func test_an_unattempted_skill_in_a_question_starts_at_one() -> void:
	var q := _question(2)
	var skills := E.question_skills(q)
	var ev := E.blank_evidence()
	ev.mastery.skills[skills[0]] = _rec(5.0, 2, ["a"])
	E.record(ev, q, {"correct": false, "complete": true, "glancing": false, "misconception": ""}, 100)
	check(ev.mastery.skills.has(skills[1]), "the question tested it, so it has a record now")
	check_eq(float(ev.mastery.skills[skills[1]].m), 1.0, "starts at 1.0 and floors there")
	check_eq(int(ev.mastery.skills[skills[1]].n), 1)


# ── Check 5: L6/L7 damping and the distinct-cell gates ───────

func test_l6_and_l7_need_distinct_cells() -> void:
	var rec := _rec(7.5, 5, ["a", "b"])
	check_eq(E.mastery_level(rec), 5, "2 cells: held at L5")
	rec.ok_cells = ["a", "b", "c"]
	check_eq(E.mastery_level(rec), 6, "3 cells: L6")
	rec.ok_cells = ["a", "b", "c", "d", "e"]
	check_eq(E.mastery_level(rec), 7, "5 cells: L7")
	# Capped at the skill's own cell count, so a small skill is not locked out.
	rec.ok_cells = ["a", "b"]
	check_eq(E.mastery_level(rec, 2), 7, "a two-cell skill with both cells right")
	check_eq(E.mastery_level(_rec(7.999, 5, ["a", "b", "c", "d", "e"])), 7, "the cap is inside L7")
	check_eq(E.mastery_update(_rec(7.99, 5), 5, 5, "right").m, E.MASTERY_CAP, "never past 7.999")


func test_a_skill_whose_top_tier_is_d3_still_reaches_l7() -> void:
	var rec := {}
	var reached := 0
	for i in range(1, 60):
		var m: float = rec.m if not rec.is_empty() else E.MASTERY_START
		rec = E.mastery_update(rec, clampi(roundi(m - 1.0), 1, 3), 3, "right", [], "c%d" % (i % 6))
		if E.mastery_level(rec, 6) == 7:
			reached = i
			break
	check_eq(reached, 19, "L7 after 19 straight successes over 6 cells")
	check_eq(E.mastery_level(E.mastery_update(rec, 3, 3, "wrong"), 6), 6, "one top-tier miss drops it to L6")


func test_skill_tops_and_cells_come_from_the_questions_the_engine_can_ask() -> void:
	var q := _question(1)
	var skill: String = E.question_skills(q)[0]
	check(E.skill_top(skill) >= int(q.level), "the top tier is at least this question's")
	check(E.skill_cells(skill, "aa-sl") > 0, "the skill has cells in AA SL")
	check(E.skill_cells(skill, "") >= E.skill_cells(skill, "aa-sl"), "every course has at least as many")
	check_eq(E.skill_top("no-such-skill"), 0)


# ── Check 6: Not Yet Attempted is a missing record ───────────

func test_not_yet_attempted_is_a_missing_record_and_reads_create_none() -> void:
	var ev := E.blank_evidence()
	var levels := E.mastery_levels(ev, "aa-sl")
	check(levels.size() > 200, "every AA SL skill is listed: %d" % levels.size())
	for s in levels:
		check_eq(levels[s], {"skill": s, "attempted": false}, "no rating, no level, not L1")
	check(ev.mastery.skills.is_empty(), "reading created no record")
	check_eq(E.mastery(ev, "SL2.1.gradient"), {"skill": "SL2.1.gradient", "attempted": false})
	check(ev.mastery.skills.is_empty(), "nor did one read")
	# Evidence from before mastery existed (a v7 save) reads as all unattempted, untouched.
	var old := {"cells": {}, "probes": {}, "history": []}
	check_eq(E.mastery(old, "SL2.1.gradient").attempted, false)
	check(not old.has("mastery"), "reading an old save adds nothing")
	check_eq(E.mastery({"mastery": "junk"}, "SL2.1.gradient").attempted, false, "a damaged field reads as nothing")
	# An answer makes one record per skill it tests, and only those.
	var q := _question(1)
	E.record(old, q, E.mark(q, E.model_response(q, true)), 100)
	check_eq(old.mastery.skills.keys(), E.question_skills(q), "record adds the field to old evidence")
	var read := E.mastery(old, E.question_skills(q)[0], "aa-sl")
	check(read.attempted and read.level == 1 and read.answers == 1 and not read.exam_ready, str(read))
	# No unattempted skill carries a rating a floor or mean could average in.
	var after := E.mastery_levels(old, "aa-sl")
	var rated := 0
	for s in after:
		if after[s].has("rating"):
			rated += 1
			check(after[s].attempted, s)
	check_eq(rated, 1, "only the answered skill has a rating")


func test_one_record_per_skill_whatever_the_course() -> void:
	var q := _question(1)
	var skill: String = E.question_skills(q)[0]
	var ev := E.blank_evidence()
	for i in 6:
		E.record(ev, q, E.mark(q, E.model_response(q, true)), 100 + i)
	var sl := E.mastery_levels(ev, "aa-sl")
	var hl := E.mastery_levels(ev, "aa-hl")
	check(hl.has(skill), "AA HL has the AA SL skill")
	check_eq(sl[skill].rating, hl[skill].rating, "the same rating on both courses")
	check_eq(ev.mastery.skills.size(), 1, "one record, keyed by skill id only")
	check(not ev.mastery.skills.has("aa-sl") and not ev.mastery.skills.has("aa-hl"), "no course keys")
	check_eq(ev.mastery.version, E.MASTERY_VERSION)


# ── Check 11: the engine boundary ────────────────────────────

func test_mastery_lives_in_the_engine_not_in_the_game() -> void:
	# test_maths_engine.gd checks MathsEngine reaches no game code; here, that the game's
	# run does not hold its own copy of the mastery rules.
	var run := FileAccess.get_file_as_string("res://engine/run.gd")
	check(not run.contains("mastery_expect") and not run.contains("MASTERY_"), "run.gd has no mastery rules")
	check(FileAccess.get_file_as_string("res://engine/maths_engine.gd").contains("static func mastery_update"))


# ── Check 12: no random numbers, so seeds still reproduce ────

func test_the_update_draws_no_random_numbers() -> void:
	var src := FileAccess.get_file_as_string("res://engine/maths_engine.gd")
	var section := src.substr(src.find("# ── Mastery"))
	for word in ["randf", "randi", "Seeded", "RandomNumberGenerator", "Time.", "OS."]:
		check(not section.contains(word), "the mastery code uses no %s" % word)
	var r := {"type": "fn-quadratic-features", "unknown": "vertex-form-from-general", "rep": "equation",
		"angle": "complete-square", "format": "value", "seed": 2}
	var before := E.generate(r)
	var ev := E.blank_evidence()
	for right in [true, false, true]:
		E.record(ev, before, E.mark(before, E.model_response(before, right)), 100)
	var after := E.generate(r)
	check_eq(E.prompt(after), E.prompt(before), "the same request, the same question after recording")
	check_eq(E.answer_sentence(after), E.answer_sentence(before))
	var a := E.mastery_update({}, 3, 5, "right", ["mcq"], "c", 1.0, 7)
	check_eq(E.mastery_update({}, 3, 5, "right", ["mcq"], "c", 1.0, 7), a, "a pure function")


# ── Check 13: the coverage report has no mastery percentage ──

func test_coverage_and_results_keep_their_counts_apart_from_mastery() -> void:
	var ev := E.blank_evidence()
	var q := _question(1)
	E.record(ev, q, E.mark(q, E.model_response(q, true)), 100)
	var res := E.results(ev, "aa-sl")
	check_eq(res.keys(), ["coverage", "accuracy", "skills", "weakest"], "results() is unchanged")
	check_eq(res.coverage.keys(), ["checked", "total"], "coverage is counts")
	var report := FileAccess.get_file_as_string("res://tools/course_report.gd")
	check(report != "", "the coverage report's source")
	check(not report.to_lower().contains("mastery"), "the coverage report reads no mastery")
	for s in E.mastery_levels(ev, "aa-sl").values():
		check(not s.has("percent"), "a mastery read is a level, not a percentage")
