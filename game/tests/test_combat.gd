extends "res://tests/test_case.gd"
## Combat (FAL-413): the run loop, timers, outcomes and their stakes, glancing hits and
## the rounding trap, lifelines, "Another way", the modifiers step, the slot picker and
## the journey signals.

const NOW := 1_800_000_000
const REGION := "quadratics"


func _run(seed_no: int = 42, start_floor: int = 1, save: Dictionary = {}) -> Run:
	var r := Run.new(save if not save.is_empty() else SaveData.blank(), REGION, start_floor, seed_no)
	r.clock = func() -> int: return NOW
	return r


## The response that answers the open question right, or wrong (a wrong option).
static func respond(q: Dictionary, right: bool) -> Dictionary:
	var pick := -1
	for i in q.choices.size():
		if q.choices[i].correct == right and not q.choices[i].get("trap", false) and pick < 0:
			pick = i
	if q.format == "mcq":
		return {"choice": pick}
	var values: Dictionary = q.answer.values if right else q.choices[pick].values
	var out := {}
	for item in Answer.slots(q.answer):
		var id: String = item.get("slot", item.get("pick", ""))
		out[id] = Answer.export_values({id: values[id]})[id] if item.has("slot") else values[id]
	return out


## Plays a run to the end with a fixed script: by question number, right, wrong, right,
## timeout, then again. Quits after `most` questions.
static func play(r: Run, most: int = 60) -> void:
	r.start()
	var i := 0
	while r.state != "ended" and i < most:
		match i % 4:
			1:
				r.answer(respond(r.question, false))
			3:
				r.tick(r.time_total + 1.0)
			_:
				r.answer(respond(r.question, true))
		i += 1
		r.next()
	r.quit()


# ── The run loop ─────────────────────────────────────────────

func test_a_scripted_run_is_the_same_every_time() -> void:
	var a := _run()
	play(a)
	var b := _run()
	play(b)
	check(a.answers.size() > 4, "the run plays some questions")
	check_eq(b.answers, a.answers, "same fights and results")
	check_eq(b.summary, a.summary, "same summary")
	check_eq(JSON.stringify(b.save), JSON.stringify(a.save), "same save")
	check_eq(a.summary.reason, "dead", "the script loses")
	check_eq(a.hp, 0)
	var c := _run(43)
	play(c)
	check(c.answers.map(func(e): return e.cell) != a.answers.map(func(e): return e.cell), "another seed asks other questions")


func test_the_run_asks_its_region_only() -> void:
	var r := _run()
	play(r)
	for e in r.answers:
		check_eq(QuestionEngine.type_of(e.cell.split("|")[0]).region, REGION, e.cell)


func test_the_summary_pays_scrap_into_the_save() -> void:
	var save := SaveData.blank()
	save.scrap = 15
	var r := _run(42, 1, save)
	play(r)
	var earned := 0
	for e in r.answers:
		earned += e.scrap
	check(earned > 0, "some Scrap earned")
	check_eq(r.summary.scrap, earned)
	check_eq(save.scrap, 15 + earned, "banked in the save")
	check_eq(save.runs.played, 1)
	check_eq(r.summary.questions, r.answers.size())
	check_eq(r.summary.right, r.answers.filter(func(e): return e.outcome in ["right", "late", "glancing"]).size())
	check(not r.summary.missed.is_empty(), "the skills missed are listed")
	for m in r.summary.missed:
		check(m.contains(": "), m)


func test_the_enemy_falls_and_the_next_fight_starts() -> void:
	var r := _run()
	r.start()
	check_eq(r.fight, 1)
	var hits: int = Tuning.ENEMIES[r.tier].hits
	for i in hits:
		check_eq(r.fight, 1, "still fight 1 before hit %d" % (i + 1))
		var res := r.answer(respond(r.question, true))
		check_eq(res.defeated, i == hits - 1, "hit %d" % (i + 1))
		r.next()
	check_eq(r.fight, 2, "the next fight")
	check_eq(r.stats.fights_won, 1)
	check_eq(r.enemy.hp, r.enemy.max_hp, "a fresh enemy")


func test_quit_ends_the_run() -> void:
	var r := _run()
	r.start()
	r.answer(respond(r.question, true))
	r.quit()
	check_eq(r.state, "ended")
	check_eq(r.summary.reason, "quit")
	check_eq(r.save.scrap, r.summary.scrap)


# ── Timers (Q6) ──────────────────────────────────────────────

func test_minutes_per_mark_by_floor() -> void:
	var want := [1.5, 1.25, 1.0, 0.9, 0.8, 0.7, 0.6, 0.6, 0.6]
	for f in want.size():
		check(is_equal_approx(Tuning.minutes_per_mark(f + 1), want[f]), "floor %d: %s" % [f + 1, Tuning.minutes_per_mark(f + 1)])


func test_timer_seconds() -> void:
	# marks, floor, typed -> seconds
	var cases := [
		[2, 1, false, 180], [2, 1, true, 195], [3, 2, false, 225], [3, 2, true, 240],
		[1, 3, false, 60], [1, 3, true, 75], [5, 4, false, 270], [2, 5, true, 111],
		[1, 4, false, 54], [1, 5, false, 48], [1, 6, false, 45], [1, 7, false, 45], [1, 7, true, 51],
		[1, 12, false, 45], [4, 12, false, 144], [4, 12, true, 159],
	]
	for c in cases:
		check_eq(Tuning.seconds_for(c[0], c[1], c[2]), c[3], "%d marks, floor %d, %s" % [c[0], c[1], "typed" if c[2] else "multiple choice"])
	for f in range(1, 20):
		for m in range(1, 6):
			for typed in [false, true]:
				check(Tuning.seconds_for(m, f, typed) >= Tuning.MIN_SECONDS, "never under 45 s")


func test_a_question_gets_its_types_marks() -> void:
	var t := QuestionEngine.type_of("fn-quadratic-from-conditions")
	check_eq(int(t.marks), 3, "the catalogue's median marks")
	var v := {"type": t.id, "unknown": "coefficients-from-roots", "rep": "words", "angle": "roots-to-factors", "format": "mcq", "seed": 3}
	check_eq(QuestionEngine.make(v).marks, 3)
	v.marks = 6
	check_eq(QuestionEngine.make(v).marks, 6, "the view sets its own")
	for f in [1, 3, 6]:
		var r := _run(42, f)
		r.start()
		var q := r.question
		var marks: int = q.marks if q.marks > 0 else Tuning.DEFAULT_MARKS
		check_eq(r.time_total, float(Tuning.seconds_for(marks, f, q.format == "value")), "floor %d" % f)


# ── Outcomes and stakes ──────────────────────────────────────

func test_each_outcome_by_tier() -> void:
	# tier -> outcome -> [enemy damage, player damage, Scrap]
	var want := {
		1: {"right": [10, 0, 40], "glancing": [5, 0, 20], "late": [10, 5, 24], "wrong": [0, 20, 0], "timeout": [0, 30, 0]},
		2: {"right": [10, 0, 30], "glancing": [5, 0, 15], "late": [10, 6, 18], "wrong": [0, 25, 0], "timeout": [0, 35, 0]},
		3: {"right": [10, 0, 20], "glancing": [5, 0, 10], "late": [10, 8, 12], "wrong": [0, 30, 0], "timeout": [0, 40, 0]},
		4: {"right": [10, 0, 15], "glancing": [5, 0, 8], "late": [10, 9, 9], "wrong": [0, 35, 0], "timeout": [0, 45, 0]},
		5: {"right": [10, 0, 10], "glancing": [5, 0, 5], "late": [10, 11, 6], "wrong": [0, 45, 0], "timeout": [0, 55, 0]},
	}
	for tier in want:
		for outcome in want[tier]:
			var fx := Run.resolve(outcome, Tuning.ENEMIES[tier])
			check_eq([fx.enemy_damage, fx.player_damage, fx.scrap], want[tier][outcome], "D%d %s" % [tier, outcome])


## A run's outcome for the first question, answered right or wrong after `wait`
## seconds, with or without Time Freeze used first.
func _outcome_after(wait: float, right: bool, freeze: bool) -> Dictionary:
	var r := _run()
	r.start()
	if freeze:
		check(r.use_freeze() > 0.0, "freeze used")
	var res := r.tick(wait)
	if res.is_empty():
		res = r.answer(respond(r.question, right))
	var fx := Run.resolve(res.outcome, Tuning.ENEMIES[r.tier])
	check_eq([res.enemy_damage, res.player_damage, res.scrap], [fx.enemy_damage, fx.player_damage, fx.scrap], res.outcome)
	check_eq(r.enemy.max_hp - r.enemy.hp, fx.enemy_damage, "enemy HP")
	check_eq(r.max_hp - r.hp, fx.player_damage, "player HP")
	check_eq(r.stats.scrap, fx.scrap, "Scrap")
	return res


func test_outcomes_in_a_run_with_and_without_time_freeze() -> void:
	var r := _run()
	r.start()
	var total := r.time_total
	# In the late zone by 5 s; Time Freeze's 15 s keeps it 10 s out.
	var late_wait := total * (1.0 - Tuning.LATE_ZONE) + 5.0
	check_eq(_outcome_after(1.0, true, false).outcome, "right")
	check_eq(_outcome_after(1.0, true, true).outcome, "right")
	check_eq(_outcome_after(late_wait, true, false).outcome, "late", "a right answer in the last 20% is late")
	check_eq(_outcome_after(late_wait, true, true).outcome, "right", "Time Freeze held the clock out of the late zone")
	check_eq(_outcome_after(1.0, false, false).outcome, "wrong")
	check_eq(_outcome_after(1.0, false, true).outcome, "wrong")
	check_eq(_outcome_after(total, true, false).outcome, "timeout")
	check_eq(_outcome_after(total, true, true).outcome, "late", "frozen time doesn't run out")
	check_eq(_outcome_after(total + Tuning.FREEZE_SECONDS, true, true).outcome, "timeout")
	var wrong := _outcome_after(1.0, false, false)
	check(not wrong.solution.is_empty() and wrong.solution.steps.size() >= 2, "a wrong answer shows the worked solution")
	check(not _outcome_after(total, true, false).solution.is_empty(), "a timeout shows the worked solution")
	check(_outcome_after(1.0, true, false).solution.is_empty(), "a right answer doesn't")


func test_a_glancing_hit() -> void:
	var r := _run()
	r.start()
	# A measure to 3 s.f. typed to 2 s.f. Quadratics' answers are all exact, so the
	# test asks a triangle question in the same fight.
	r.question = QuestionEngine.make({"type": "t3-sine-cosine-rule", "unknown": "side-cosine-rule", "rep": "words",
		"angle": "cosine-rule", "format": "value", "seed": 7})
	var v: Q = r.question.answer.values.v
	var res := r.answer({"v": Fmt.sf(v, 2)})
	check_eq(res.outcome, "glancing", "%s for %s" % [Fmt.sf(v, 2), Fmt.sf(v)])
	check_eq(res.note, "The IB needs 3 s.f.")
	check_eq(res.enemy_damage, Tuning.HIT / 2, "half damage")
	check_eq(res.player_damage, 0)
	check(res.solution.is_empty(), "no worked solution for a glancing hit")


func test_glancing_marking() -> void:
	var cases := [
		# typed, exact, glancing
		["2.3", Q.new(2347, 1000), true],
		["2", Q.new(2347, 1000), true],
		["2.35", Q.new(2347, 1000), false],   # right
		["2.4", Q.new(2347, 1000), false],    # wrong rounding
		["0.67", Q.new(2, 3), true],
		["0.7", Q.new(2, 3), true],
		["0.6", Q.new(2, 3), false],
		["1", Q.new(1, 2), false],            # 1/2 needs no rounding
		["2.3", Q.new(23, 10), false],        # right, exact
		["12", Q.new(123456, 10000), true],
	]
	for c in cases:
		var typed: Q = Answer.parse_number(c[0]).q
		check_eq(Answer.number_glancing(typed, c[1]), c[2], "%s for %s" % [c[0], c[1].key()])
	var ans := Answer.make("xval", {"v": Q.new(2, 3)})
	var m := Answer.mark(ans, {"v": "0.67"})
	check(not m.correct and m.glancing, "0.67 for 2/3 is a glancing hit")
	check(Answer.mark(ans, {"v": "0.667"}).correct, "0.667 is right")
	ans.exact = true
	check(not Answer.mark(ans, {"v": "0.67"}).glancing, "an exact-only answer has no glancing hit")


func test_the_rounding_trap() -> void:
	var ans := Answer.make("xval", {"v": Q.new(2, 3)})
	var trap := Answer.rounding_trap(ans)
	check(not trap.is_empty() and trap.v.eq(Q.new(67, 100)), str(trap))
	check_eq(Answer.trap_text(ans, trap), "x = 0.67")
	check(Answer.rounding_trap(Answer.make("xval", {"v": Q.new(5, 2)})).is_empty(), "no trap where nothing needs rounding")
	check(Answer.rounding_trap(Answer.make("point", {"x": Q.new(2, 3), "y": Q.new(1)})).is_empty(), "one number only")
	var choices := QuestionEngine._choices(ans, {"wrongs": [], "generic": [], "trap": trap}, Seeded.new("trap"))
	var traps := choices.filter(func(c): return c.get("trap", false))
	check_eq(traps.size(), 1, "one rounding trap among the options")
	if traps.size() == 1:
		check_eq(traps[0].text, "x = 0.67")
		var q := {"format": "mcq", "choices": choices}
		var m := QuestionEngine.mark(q, {"choice": choices.find(traps[0])})
		check(not m.correct and m.glancing, "picking the trap is a glancing hit")
	# The quadratic views offer it wherever their answer needs rounding.
	var b: Dictionary = QuadraticViews.new().build("vertex-from-general", "equation", QuadraticSituation.generate(Seeded.new("t"), {"mode": "any", "even": true}), Seeded.new("t"))
	check(b.has("trap"), "the quadratic views set trap")


func test_an_incomplete_answer_changes_nothing() -> void:
	var r := _run()
	r.start()
	if r.question.format == "mcq":
		check_eq(r.answer({"choice": -1}).complete, false)
	else:
		check_eq(r.answer({}).complete, false)
	check_eq(r.state, "question")
	check_eq(r.stats.questions, 0)


# ── Lifelines ────────────────────────────────────────────────

func test_lifelines() -> void:
	var r := _run()
	r.start()
	var steps: Array = r.question.solutions[0].steps
	check_eq(r.use_hint(), steps[0], "Hint shows the first step")
	check_eq(r.use_hint(), "", "once")
	check(r.use_freeze() == Tuning.FREEZE_SECONDS)
	check_eq(r.use_freeze(), 0.0, "once")
	# 50-50 on a multiple-choice question.
	var m := _run(7)
	m.start()
	var guard := 0
	while m.question.format != "mcq" and guard < 20:
		m.answer(respond(m.question, true))
		m.next()
		guard += 1
	var gone := m.use_fifty()
	check_eq(gone.size(), 2, "two options go")
	for i in gone:
		check(not m.question.choices[i].correct, "only wrong ones")
	check_eq(m.use_fifty(), [], "once")


# ── "Another way" ────────────────────────────────────────────

func test_another_way_on_floor_2() -> void:
	var r := _run(5, 2)
	r.start()
	var seen := 0
	var prev: Dictionary = {}
	for i in 80:
		if r.state != "question":
			break
		if r.another_way:
			seen += 1
			check_eq(r.question.situation, prev.situation, "the same numbers")
			check(r.question.view.angle != prev.view.angle, "another angle")
			check_eq(r.question.answer_text, prev.answer_text)
			var res := r.answer(respond(r.question, true))
			check_eq(res.bonus, roundi(Tuning.ANOTHER_WAY_BONUS * float(r.enemy.scrap)), "bonus Scrap")
		else:
			prev = r.question
			var res := r.answer(respond(r.question, true))
			var angles := QuestionEngine.angles_for(QuestionEngine.type_of(prev.view.type), prev.view.unknown)
			if angles.size() < 2:
				check(not res.another_way, "%s has one angle" % prev.cell)
		r.next()
	check(seen > 0, "a follow-up came")
	check(seen < 40, "only now and then")


func test_no_another_way_on_floor_1() -> void:
	var r := _run(5, 1)
	r.start()
	for i in 60:
		# An all-right run clears floor 1's boss; floor 2 may ask one.
		if r.state != "question" or r.floor_no > 1:
			break
		check(not r.another_way)
		r.answer(respond(r.question, true))
		r.next()


# ── The hooks ────────────────────────────────────────────────

func test_no_modifiers_change_nothing() -> void:
	var mods := Modifiers.new()
	for kind in Modifiers.KINDS:
		check_eq(mods.apply(kind, 17.5), 17.5, kind)
	var a := _run()
	play(a)
	var b := _run()
	b.modifiers.add(func(_kind: String, v: float, _ctx: Dictionary) -> float: return v)
	play(b)
	check_eq(b.answers, a.answers, "an identity modifier changes nothing")


func test_a_modifier_that_doubles_scrap() -> void:
	var a := _run()
	play(a)
	var b := _run()
	b.modifiers.add(func(kind: String, v: float, _ctx: Dictionary) -> float: return v * 2.0 if kind == "scrap" else v)
	play(b)
	check_eq(b.answers.size(), a.answers.size(), "the same run")
	for i in mini(a.answers.size(), b.answers.size()):
		check_eq(b.answers[i].scrap, a.answers[i].scrap * 2, "answer %d" % i)
		check_eq(b.answers[i].player_damage, a.answers[i].player_damage)
	check(a.summary.scrap > 0)
	check_eq(b.summary.scrap, a.summary.scrap * 2, "the payout doubles")
	check_eq(b.save.scrap, a.save.scrap * 2)


func test_a_stakes_table_changes_the_outcome() -> void:
	var table := Tuning.STAKES.duplicate(true)
	table.wrong.player = 0.5
	check_eq(Run.resolve("wrong", Tuning.ENEMIES[2], table).player_damage, 13)
	check_eq(Run.resolve("wrong", Tuning.ENEMIES[2]).player_damage, 25, "the default table")


func test_the_slot_picker() -> void:
	for s in [1, 42, 99999]:
		for f in [1, 2, 7]:
			for n in range(1, 11):
				var k := Run.slot_kind(s, f, n)
				check_eq(k, "fight")
				check_eq(Run.slot_kind(s, f, n), k, "deterministic")


class Recorder:
	var events: Array = []

	func started(region: String, avatar: String, seed_no: int) -> void:
		events.append(["started", region, avatar, seed_no])

	func opened(fight: int, tier: int) -> void:
		events.append(["opened", fight, tier])

	func resolved(outcome: String) -> void:
		events.append(["resolved", outcome])

	func ended(summary: Dictionary) -> void:
		events.append(["ended", summary.reason])


func test_journey_signals_are_view_only() -> void:
	var quiet := _run()
	play(quiet)
	var heard := _run()
	var rec := Recorder.new()
	heard.run_started.connect(rec.started)
	heard.question_opened.connect(rec.opened)
	heard.answer_resolved.connect(rec.resolved)
	heard.run_ended.connect(rec.ended)
	play(heard)
	check_eq(heard.answers, quiet.answers, "the run plays the same with or without listeners")
	check_eq(heard.summary, quiet.summary)
	check_eq(rec.events[0], ["started", REGION, "learner", 42])
	check_eq(rec.events[-1], ["ended", "dead"])
	var opened := rec.events.filter(func(e): return e[0] == "opened")
	var resolved := rec.events.filter(func(e): return e[0] == "resolved")
	check_eq(resolved.size(), quiet.answers.size())
	check_eq(opened.size(), quiet.answers.size(), "one per question")
	check_eq(resolved.map(func(e): return e[1]), quiet.answers.map(func(e): return e.outcome))
	check_eq(opened[0], ["opened", 1, quiet.answers[0].tier])
