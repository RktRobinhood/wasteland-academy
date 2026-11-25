extends "res://tests/test_case.gd"
## Deterministic learner trajectories for the PROPOSED mastery calibration (#268,
## FAL-1603, ADR-0002; docs/proposals/mastery-calibration.md). Design evidence only:
## the model lives in tests/sim and the game does not use it.
##
##   ./test.sh  or  godot --headless --path game --script res://tests/run_tests.gd -- --only=mastery_calibration
##
## Each test prints its trajectory ("sim| ..." lines) and checks the ADR-0002 property it
## illustrates. Passing shows the proposal behaves as described; it is not approval.

const M := preload("res://tests/sim/mastery_calibration_model.gd")


func _say(line: String) -> void:
	print("sim| " + line)


func _row(label: String, rec: Dictionary) -> String:
	return "%-34s m=%.3f  L%d" % [label, float(rec.m), M.level(rec)]


## Matched successes: each question chosen at the learner's own rating, every answer
## right, unassisted, a new cell each time. About two per level up to L5, then more.
func test_matched_successes() -> void:
	_say("== matched successes (difficulty chosen from the rating; top tier 5) ==")
	var rec := {}
	var reached := {}
	var i := 0
	while M.level(rec) < 7 and i < 60:
		i += 1
		var m: float = rec.m if not rec.is_empty() else M.START
		var d := M.difficulty_for(m, 0, 5)
		rec = M.update(rec, d, 5, "right", [], "cell-%d" % i)
		_say(_row("success %d at d%d" % [i, d], rec))
		if not reached.has(M.level(rec)):
			reached[M.level(rec)] = i
	_say("first reached (level: success no.): %s" % str(reached))
	check(M.level(rec) == 7, "L7 is reachable in one long varied run")
	# The ideal match (question rating = learner rating) moves exactly K/2 per success.
	var ideal := []
	var m2 := M.START
	var count := 0
	for target in [2.0, 3.0, 4.0, 5.0, 6.0, 7.0]:
		var n := 0
		while m2 < target:
			m2 += M.K * 0.5 * M.damp(m2)
			n += 1
		ideal.append(n)
		count += n
	_say("ideal-match successes per level L1->L2..L6->L7: %s (total %d)" % [str(ideal), count])
	check_eq(ideal.slice(0, 4), [2, 2, 2, 2], "two matched successes per level up to L5")
	check(ideal[4] > ideal[3] and ideal[5] > ideal[4], "L6 and L7 need progressively more evidence")


## Above-level success moves further than a matched one.
func test_above_level_success() -> void:
	_say("== above-level success (start m=3.5, L3) ==")
	var base := {"m": 3.5, "n": 4, "exam_ok": 0, "ok_cells": [], "recent_ok": []}
	var steps := {}
	for d in [1, 2, 3, 4, 5]:
		var r := M.update(base, d, 5, "right", [], "c")
		steps[d] = float(r.m) - 3.5
		_say("success at d%d (rating %.0f): step %+.3f -> %s" % [d, M.rating_of(d), steps[d], _row("", r)])
	check(steps[5] > steps[4] and steps[4] > steps[3] and steps[3] > steps[2], "harder success moves further")
	check(steps[1] < 0.2, "success well below the rating moves under 40% of a matched step")


## Above-level failure costs less than a matched or below-level failure.
func test_above_and_below_level_failure() -> void:
	_say("== failures (start m=4.5, L4) ==")
	var base := {"m": 4.5, "n": 10, "exam_ok": 3, "ok_cells": ["a", "b", "c"], "recent_ok": []}
	var drops := {}
	for d in [0, 1, 2, 3, 4, 5]:
		var r := M.update(base, d, 5, "wrong")
		drops[d] = 4.5 - float(r.m)
		_say("miss at d%d: drop %.3f -> %s" % [d, drops[d], _row("", r)])
	check(drops[5] < drops[3] and drops[3] < drops[1], "a hard miss costs less than an easy one")
	check(drops[5] < 0.25, "a miss well above the rating is nonpunitive")
	var low := M.update(base, 1, 5, "wrong")
	check(M.level(low) < 4, "one miss far below the rating drops the level at once")


## Below-level failure from high up: an L6 learner missing a d1 question.
func test_below_level_failure_from_l6() -> void:
	_say("== below-level failure (start m=6.2, L6) ==")
	var rec := {"m": 6.2, "n": 30, "exam_ok": 6, "ok_cells": ["a", "b", "c", "d"], "recent_ok": []}
	_say(_row("start", rec))
	for d in [1, 1]:
		rec = M.update(rec, d, 5, "wrong")
		_say(_row("miss at d%d" % d, rec))
	check(M.level(rec) <= 4, "two basic misses take an L6 back to Exam Ready or below")


## Assists: the same success from m=3.5 at d3 under each assist and format.
func test_assist_credit() -> void:
	_say("== assist credit (success at d3 from m=3.5) ==")
	var base := {"m": 3.5, "n": 4, "exam_ok": 0, "ok_cells": [], "recent_ok": []}
	var plain := float(M.update(base, 3, 5, "right").m) - 3.5
	var cases := [["value, unassisted", "right", []], ["late (slow but right)", "late", []],
		["Time Freeze", "right", ["freeze"]], ["multiple choice", "right", ["mcq"]],
		["glancing (accuracy)", "glancing", []], ["hint", "right", ["hint"]],
		["multiple choice + 50-50", "right", ["mcq", "fifty"]], ["hint + 50-50", "right", ["mcq", "fifty", "hint"]],
		["v7 answer replayed by migration", "right", ["migrated"]]]
	for c in cases:
		var r := M.update(base, 3, 5, c[1], c[2])
		_say("%-34s step %+.3f  counts for Exam Ready: %s" % [c[0], float(r.m) - 3.5, str(int(r.exam_ok) > 0)])
	check(float(M.update(base, 3, 5, "right", ["hint"]).m) - 3.5 < plain, "a hint reduces credit")
	check(float(M.update(base, 3, 5, "right", ["freeze"]).m) - 3.5 == plain, "Time Freeze is not a maths assist")
	# Assisted-only evidence can never show Exam Ready.
	var rec := {}
	for i in 30:
		rec = M.update(rec, 3, 5, "right", ["hint"], "cell-%d" % i)
	_say(_row("30 hinted d3 successes", rec))
	check(float(rec.m) < 4.0, "assisted successes stop at the edge of Exam Ready")
	check(M.level(rec) == 3, "assisted-only evidence stops at L3 until unassisted exam-tier successes")
	rec = M.update(rec, 3, 5, "right", [], "u1")
	rec = M.update(rec, 3, 5, "right", [], "u2")
	_say(_row("+ 2 unassisted d3 successes", rec))
	check(M.level(rec) >= 4, "two unassisted exam-tier successes open Exam Ready")


## Multi-skill uncertainty: a two-skill d3 question; A is strong, B is weak.
func test_multi_skill_uncertainty() -> void:
	_say("== multi-skill question at d3: A m=5.0, B m=2.5 ==")
	var recs := {"A": {"m": 5.0, "n": 12, "exam_ok": 4, "ok_cells": ["a", "b", "c"], "recent_ok": []},
		"B": {"m": 2.5, "n": 5, "exam_ok": 0, "ok_cells": ["x"], "recent_ok": []}}
	var share := M.blame(recs, ["A", "B"], 3)
	_say("miss, no misconception: blame A %.3f, B %.3f" % [share.A, share.B])
	for s in ["A", "B"]:
		_say(_row("  after miss: " + s, M.update(recs[s], 3, 5, "wrong", [], "", share[s])))
	check(share.B > share.A, "the weaker skill takes most of the blame")
	check(absf(share.A + share.B - 1.0) < 1e-9, "blame shares sum to one answer's worth")
	var named := M.blame(recs, ["A", "B"], 3, "A")
	_say("miss whose misconception names A: blame A %.1f, B %.1f" % [named.A, named.B])
	check_eq(named.A, 1.0, "a skill-specific misconception takes all the blame")
	for s in ["A", "B"]:
		_say(_row("  after success: " + s, M.update(recs[s], 3, 5, "right", [], "q")))
	var fresh := M.blame({"A": recs.A}, ["A", "N"], 3)
	_say("miss with an unattempted skill N: blame A %.3f, N %.3f (N then starts at %.1f)" % [fresh.A, fresh.N, M.START])


## L6/L7 diminishing returns: simulated learners of fixed true ability answer questions
## chosen at their rating; their answers come from a seeded stream (Seeded), so the run
## is the same every time. Where each settles after 80 questions, and when L6/L7 first show.
func test_l6_l7_diminishing_returns() -> void:
	_say("== simulated learners, 80 questions, top tier 5, seeded ==")
	var finals := {}
	for theta in [3.0, 4.5, 6.0, 7.0, 8.0]:
		var rng := Seeded.new("mastery-sim|%.1f" % theta)
		var rec := {}
		var first := {}
		var right := 0
		for i in 80:
			var m: float = rec.m if not rec.is_empty() else M.START
			var d := M.difficulty_for(m, 0, 5)
			var ok := rng.chance(M.expect(theta, M.rating_of(d)))
			right += 1 if ok else 0
			rec = M.update(rec, d, 5, "right" if ok else "wrong", [], "cell-%d" % (i % 12))
			var lv := M.level(rec)
			if lv >= 6 and not first.has(6):
				first[6] = i + 1
			if lv >= 7 and not first.has(7):
				first[7] = i + 1
		finals[theta] = rec.m
		_say("ability %.1f: final m=%.3f L%d, %d/80 right, first L6 at q%s, first L7 at q%s" % [theta, float(rec.m),
			M.level(rec), right, str(first.get(6, "-")), str(first.get(7, "-"))])
	check(float(finals[3.0]) < 4.0, "a learner below exam standard does not show Exam Ready")
	check(float(finals[8.0]) >= 6.0, "a very strong learner reaches L6 or above in one long run")
	check(float(finals[6.0]) < 6.0 + 0.5, "damping keeps the rating from overshooting ability")


## What it takes to hold each level: the success rate at which the rating stays put,
## with questions at the difficulty the planner would choose (top tier 5, and a skill
## whose top tier is 3), for the recommended damping and the softer alternative.
func test_holding_rates() -> void:
	_say("== success rate that holds a rating (questions chosen at the rating) ==")
	for top in [5, 3]:
		for t in [["recommended", M.DAMP], ["softer alternative", M.DAMP_SOFT]]:
			var parts := []
			for m in [2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 7.5]:
				var d := M.difficulty_for(m, 0, top)
				parts.append("m%.1f@d%d %d%%" % [m, d, roundi(100.0 * M.holding_rate(m, d, top, t[1]))])
			_say("top d%d, %-18s %s" % [top, t[0], ", ".join(parts)])
	check(M.holding_rate(7.0, 5, 5) > M.holding_rate(6.0, 5, 5), "holding L7 needs more consistency than L6")


## Low-ceiling skill: its hardest catalogue tier is d3. Past that tier, top-tier
## successes count as matched, so L6/L7 stay reachable through consistency and variety.
func test_low_ceiling_skill() -> void:
	_say("== skill whose top tier is d3 (catalogue difficulty [1, 3]), 6 cells ==")
	var rec := {}
	var i := 0
	while M.level(rec, 6) < 7 and i < 60:
		i += 1
		var m: float = rec.m if not rec.is_empty() else M.START
		var d := M.difficulty_for(m, 1, 3)
		rec = M.update(rec, d, 3, "right", [], "cell-%d" % (i % 6))
		if i <= 6 or i % 4 == 0 or M.level(rec, 6) == 7:
			_say(_row("success %d at d%d" % [i, d], rec))
	check(M.level(rec, 6) == 7, "a d3-ceiling skill can still reach L7")
	_say("successes to L7: %d" % i)
	var drop := M.update(rec, 3, 3, "wrong")
	_say(_row("then one miss at its top tier", drop))


## Repeating the same cell earns less than varied cells.
func test_repeat_cell_counts_less() -> void:
	var same := {}
	var varied := {}
	for i in 10:
		same = M.update(same, 3, 5, "right", [], "one-cell")
		varied = M.update(varied, 3, 5, "right", [], "cell-%d" % i)
	_say("== 10 d3 successes: same cell m=%.3f L%d, varied cells m=%.3f L%d ==" % [float(same.m),
		M.level(same), float(varied.m), M.level(varied)])
	check(float(same.m) < float(varied.m), "repetition of one cell earns less")


## Thunderdome: the floor is the mean of attempted eligible skills, fixed for the run.
func test_thunderdome_floor() -> void:
	_say("== Thunderdome floor ==")
	var recs := {"A": {"m": 5.2, "n": 9, "exam_ok": 3, "ok_cells": ["a", "b"], "recent_ok": []},
		"B": {"m": 2.4, "n": 4, "exam_ok": 0, "ok_cells": ["a"], "recent_ok": []},
		"C": {"m": 3.4, "n": 6, "exam_ok": 1, "ok_cells": ["a"], "recent_ok": []}}
	var eligible := ["A", "B", "C", "D"]
	var floor_rating := M.thunderdome_floor(recs, eligible)
	_say("attempted A 5.2, B 2.4, C 3.4; D Not Yet Attempted -> floor %.3f" % floor_rating)
	check(absf(floor_rating - 11.0 / 3.0) < 1e-9, "the floor is the mean of attempted skills only")
	for s in eligible:
		var r := M.selection_rating(recs, s, floor_rating)
		_say("  %s asks at rating %.3f -> d%d" % [s, r, M.difficulty_for(r, 0, 5)])
	check(M.selection_rating(recs, "A", floor_rating) == 5.2, "a higher skill keeps its own level")
	check(not recs.has("D"), "selection writes no rating for an unattempted skill")
	# Mid-run misses lower B's mastery; the run's floor does not move.
	for i in 3:
		recs.B = M.update(recs.B, M.difficulty_for(floor_rating, 0, 5), 5, "wrong")
	_say("  after 3 misses B m=%.3f; run floor still %.3f; B still asks at d%d" % [float(recs.B.m), floor_rating,
		M.difficulty_for(M.selection_rating(recs, "B", floor_rating), 0, 5)])
	check(M.selection_rating(recs, "B", floor_rating) == floor_rating, "the floor holds for the run")
	var none := M.thunderdome_floor({}, eligible)
	_say("no attempted skill -> fallback floor %.1f (asks d%d)" % [none, M.difficulty_for(none, 0, 5)])
	check_eq(none, M.NO_ATTEMPT_FLOOR, "no-attempt fallback")


## Migration replay: a v7 cell's counts become an ordered, deterministic replay with
## migrated credit; it never counts toward Exam Ready.
func test_migration_replay() -> void:
	_say("== migration replay of v7 counts ==")
	var cells := [{"key": "t|u1|r|a", "level": 2, "right": 6, "wrong": 2},
		{"key": "t|u2|r|a", "level": 3, "right": 5, "wrong": 1}]
	var rec := {}
	for c in cells:
		for outcome in interleave(int(c.right), int(c.wrong)):
			rec = M.update(rec, int(c.level), 4, outcome, ["migrated"], c.key)
	_say(_row("12 right / 3 wrong replayed", rec))
	check(M.level(rec) <= 3, "migrated evidence alone cannot show Exam Ready")
	var again := {}
	for c in cells:
		for outcome in interleave(int(c.right), int(c.wrong)):
			again = M.update(again, int(c.level), 4, outcome, ["migrated"], c.key)
	check_eq(again.m, rec.m, "the replay is deterministic")


## right/wrong spread evenly (Bresenham), misses first on a tie: no order is invented
## in the learner's favour.
static func interleave(right: int, wrong: int) -> Array:
	var out := []
	var total := right + wrong
	var placed_wrong := 0
	for i in total:
		if placed_wrong < wrong and float(placed_wrong) <= float(i) * wrong / total:
			out.append("wrong")
			placed_wrong += 1
		else:
			out.append("right")
	return out
