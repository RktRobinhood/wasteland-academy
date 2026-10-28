class_name Run
extends RefCounted
## A run: fights in a row in one region until the player's HP reaches 0 or they quit,
## then a summary that pays its Scrap into the save (FAL-413). It holds every rule and
## no UI, so a test can play a whole run with fixed answers; ui/fight.gd draws it.
##
##   var run := Run.new(save, "quadratics", 1, 42)
##   run.start()                       # opens fight 1's first question: run.question
##   run.tick(delta)                   # the clock; runs out into a timeout
##   var r := run.answer({"choice": 2})  # or slot id -> typed text; see resolve()
##   run.next()                        # after the result: next question, fight or the end
##
## Every number comes from Tuning (engine/tuning.gd). Every damage, heal, Scrap and time
## value passes through `modifiers` (engine/modifiers.gd). Every outcome goes through
## resolve() with `stakes`, the table encounters change. slot_kind() says what each
## fight slot is. G4 adds floors, mini-bosses and bosses on top.
##
## The signals are for views only (the journey strip, FAL-331). Nothing in the run
## waits on them, so it plays the same with nothing connected.

signal run_started(region: String, avatar: String, seed: int)
signal question_opened(fight: int, tier: int)
signal answer_resolved(outcome: String)
signal run_ended(summary: Dictionary)

## What a fight slot can be (FAL-347). Only "fight" is played until FAL-349.
const SLOT_KINDS := ["fight", "encounter", "cell"]

## The glancing hit's note (Q7).
const GLANCING_NOTE := "The IB needs 3 s.f."

var save: Dictionary
var region: String
var floor_no: int
var run_seed: int
var avatar: String
var modifiers := Modifiers.new()
var stakes: Dictionary = Tuning.STAKES
## The clock for the planner's "got wrong recently" rule. Tests fix it.
var clock: Callable = func() -> int: return int(Time.get_unix_time_from_system())

## "question" while a question is open, "result" after it is answered, "ended".
var state := ""
var hp := 0
var max_hp := 0
var fight := 0
var slot := ""
var tier := 0
## {"name", "rank", "art", "damage", "scrap", "hp", "max_hp"}
var enemy: Dictionary = {}
var question: Dictionary = {}
var question_no := 0
## True while the open question is an "Another way" follow-up.
var another_way := false
var time_total := 0.0
var time_left := 0.0
var frozen_left := 0.0
var lifelines: Dictionary = {}
## Options 50-50 took away, by index.
var removed: Array = []
var hint := ""
var stats := {"questions": 0, "right": 0, "glancing": 0, "late": 0, "wrong": 0, "timeout": 0,
	"scrap": 0, "fights_won": 0, "another_way": 0}
## Skills missed, in the order they were first missed: "type name: what was asked".
var missed: Array = []
## One entry per answer: {"fight", "tier", "cell", "outcome", "enemy_damage",
## "player_damage", "scrap"}. Tests compare runs by it.
var answers: Array = []
var summary: Dictionary = {}

var _followup: Dictionary = {}


func _init(save_data: Dictionary, region_id: String, start_floor: int = 1, seed_no: int = 1, avatar_id: String = "learner") -> void:
	save = save_data
	region = region_id
	floor_no = maxi(1, start_floor)
	run_seed = seed_no
	avatar = avatar_id


func start() -> void:
	max_hp = roundi(modifiers.apply("max_hp", Tuning.BASE_HP, {}))
	hp = max_hp
	lifelines = Tuning.LIFELINES.duplicate()
	run_started.emit(region, avatar, run_seed)
	_next_fight()


## What fight slot n on a floor is: a fight, an encounter or a cell (FAL-347), picked
## from the run seed. Always "fight" until encounters exist (FAL-349).
static func slot_kind(seed_no: int, on_floor: int, n: int) -> String:
	var _rng := Seeded.new("slot|%d|%d|%d" % [seed_no, on_floor, n])
	return "fight"


## The enemy tier of fight n (Tuning.TIER_EVERY), the same for the same seed.
static func tier_for(seed_no: int, on_floor: int, n: int) -> int:
	for rule in Tuning.TIER_EVERY:
		if n % int(rule.every) == 0:
			return int(rule.tier)
	return 1 if Seeded.new("tier|%d|%d|%d" % [seed_no, on_floor, n]).chance(Tuning.LOW_TIER_D1) else 2


## The one resolve step (FAL-347): what an outcome does to the enemy, the player and
## the Scrap, from a stakes table, through the modifiers.
## Returns {"enemy_damage", "player_damage", "scrap"}.
static func resolve(outcome: String, foe: Dictionary, table: Dictionary = Tuning.STAKES,
		mods: Modifiers = null, ctx: Dictionary = {}) -> Dictionary:
	var row: Dictionary = table[outcome]
	var c := ctx.duplicate()
	c.outcome = outcome
	var e := float(row.enemy) * Tuning.HIT
	var p := float(row.player) * float(foe.damage) + float(row.get("plus", 0))
	var s := float(row.scrap) * float(foe.scrap)
	if mods != null:
		e = mods.apply("enemy_damage", e, c)
		p = mods.apply("player_damage", p, c)
		s = mods.apply("scrap", s, c)
	return {"enemy_damage": maxi(0, roundi(e)), "player_damage": maxi(0, roundi(p)), "scrap": maxi(0, roundi(s))}


func _ctx() -> Dictionary:
	return {"tier": tier, "floor": floor_no, "fight": fight}


func _next_fight() -> void:
	fight += 1
	slot = Run.slot_kind(run_seed, floor_no, fight)
	tier = Run.tier_for(run_seed, floor_no, fight)
	var e: Dictionary = Tuning.ENEMIES[tier]
	enemy = {"name": e.name, "rank": e.rank, "art": e.art, "damage": e.damage, "scrap": e.scrap,
		"hp": int(e.hits) * Tuning.HIT, "max_hp": int(e.hits) * Tuning.HIT}
	_open_question()


func _open_question() -> void:
	question_no += 1
	var view: Dictionary
	another_way = not _followup.is_empty()
	if another_way:
		view = _followup
		_followup = {}
	else:
		view = Planner.next(save, clock.call(), {"region": region, "probes": false, "salt": "run|%d|%d" % [run_seed, question_no]})
	question = QuestionEngine.make(view) if not view.has("error") else view
	if question.has("error"):
		push_error("Run: %s" % question.error)
		_end("no-questions")
		return
	removed = []
	hint = ""
	var marks: int = question.marks if question.marks > 0 else Tuning.DEFAULT_MARKS
	time_total = modifiers.apply("time", Tuning.seconds_for(marks, floor_no, question.format == "value"), _ctx())
	time_left = time_total
	frozen_left = 0.0
	state = "question"
	question_opened.emit(fight, tier)


## The clock. Time Freeze holds it; when it runs out the question is a timeout.
## Returns the result when this tick timed the question out, else {}.
func tick(delta: float) -> Dictionary:
	if state != "question":
		return {}
	var d := delta
	if frozen_left > 0.0:
		var held := minf(d, frozen_left)
		frozen_left -= held
		d -= held
	time_left = maxf(0.0, time_left - d)
	if time_left <= 0.0:
		return _resolve("timeout", {})
	return {}


## The share of the clock left, 0 to 1.
func time_share() -> float:
	return time_left / time_total if time_total > 0.0 else 0.0


func in_late_zone() -> bool:
	return time_share() < Tuning.LATE_ZONE


## Marks a response (as QuestionEngine.mark takes it) and resolves it. An incomplete
## response changes nothing and comes back with complete false and its errors.
func answer(response: Dictionary) -> Dictionary:
	if state != "question":
		return {}
	var m := QuestionEngine.mark(question, response)
	if not m.complete:
		return {"complete": false, "errors": m.errors}
	var outcome := "wrong"
	if m.correct:
		outcome = "late" if in_late_zone() else "right"
	elif m.get("glancing", false):
		outcome = "glancing"
	return _resolve(outcome, m)


## Applies an outcome. Returns {"complete": true, "outcome", "enemy_damage",
## "player_damage", "scrap", "bonus", "note", "solution", "misconception",
## "defeated", "dead", "another_way"}: solution is the worked solution to show (after a
## wrong answer or a timeout), another_way whether the next question is a follow-up.
func _resolve(outcome: String, m: Dictionary) -> Dictionary:
	state = "result"
	var fx := Run.resolve(outcome, enemy, stakes, modifiers, _ctx())
	var bonus := 0
	if another_way and outcome == "right":
		bonus = maxi(0, roundi(modifiers.apply("scrap", Tuning.ANOTHER_WAY_BONUS * float(enemy.scrap), _ctx())))
		stats.another_way += 1
	enemy.hp = maxi(0, int(enemy.hp) - fx.enemy_damage)
	hp = maxi(0, hp - fx.player_damage)
	stats.scrap += fx.scrap + bonus
	stats.questions += 1
	stats[outcome] += 1
	var right := outcome in ["right", "late", "glancing"]
	SaveData.record(save, question.cell, right, clock.call(), m.get("misconception", ""))
	if not right:
		var t := QuestionEngine.type_of(question.view.type)
		var asked: String = QuestionEngine.unknown_of(t, question.view.unknown).get("asked", question.view.unknown)
		var skill := "%s: %s" % [question.type_name, asked]
		if not missed.has(skill):
			missed.append(skill)
	answers.append({"fight": fight, "tier": tier, "cell": question.cell, "seed": int(question.view.seed), "outcome": outcome,
		"enemy_damage": fx.enemy_damage, "player_damage": fx.player_damage, "scrap": fx.scrap + bonus})
	var defeated: bool = enemy.hp <= 0
	if defeated:
		stats.fights_won += 1
	_followup = {}
	if outcome == "right" and hp > 0 and not another_way:
		_followup = _another_way_view()
	answer_resolved.emit(outcome)
	return {"complete": true, "outcome": outcome, "enemy_damage": fx.enemy_damage, "player_damage": fx.player_damage,
		"scrap": fx.scrap, "bonus": bonus, "note": GLANCING_NOTE if outcome == "glancing" else "",
		"solution": question.solutions[0] if outcome in ["wrong", "timeout"] else {},
		"misconception": m.get("misconception", ""), "defeated": defeated, "dead": hp <= 0,
		"another_way": not _followup.is_empty()}


## The "Another way" follow-up for the question just answered right (FAL-310 plan): the
## same numbers, asked by the next angle the type lists for that unknown. {} unless the
## floor is deep enough, the type lists more than one angle and the chance comes up.
func _another_way_view() -> Dictionary:
	if floor_no < Tuning.ANOTHER_WAY_FLOOR:
		return {}
	var v: Dictionary = question.view
	var angles := QuestionEngine.angles_for(QuestionEngine.type_of(v.type), v.unknown)
	if angles.size() < 2 or not v.angle in angles:
		return {}
	if not Seeded.new("another|%d|%d" % [run_seed, question_no]).chance(Tuning.ANOTHER_WAY_CHANCE):
		return {}
	var other: String = angles[(angles.find(v.angle) + 1) % angles.size()]
	return {"type": v.type, "unknown": v.unknown, "rep": v.rep, "angle": other, "format": v.format,
		"seed": v.seed, "same_angle": v.get("same_angle", v.angle)}


## After a result: the end if the player is out of HP, the next fight if the enemy is
## beaten, else the next question.
func next() -> void:
	if state != "result":
		return
	if hp <= 0:
		_end("dead")
	elif int(enemy.hp) <= 0:
		_next_fight()
	else:
		_open_question()


func quit() -> void:
	if state != "ended":
		_end("quit")


## HP back, through the modifiers, up to max_hp. Nothing heals in G3; perks (G6) and
## encounter prizes (FAL-349) will.
func heal(amount: float) -> int:
	var before := hp
	hp = mini(max_hp, hp + maxi(0, roundi(modifiers.apply("heal", amount, _ctx()))))
	return hp - before


# ── Lifelines ────────────────────────────────────────────────

func can_use(lifeline: String) -> bool:
	if state != "question" or int(lifelines.get(lifeline, 0)) <= 0:
		return false
	match lifeline:
		"fifty":
			return question.format == "mcq" and removed.is_empty()
		"hint":
			return hint == "" and not question.solutions.is_empty()
		"freeze":
			return frozen_left <= 0.0
	return false


## 50-50: takes away two wrong options. Returns their indices.
func use_fifty() -> Array:
	if not can_use("fifty"):
		return []
	lifelines.fifty -= 1
	var wrong: Array = []
	for i in question.choices.size():
		if not question.choices[i].correct:
			wrong.append(i)
	removed = Seeded.new("fifty|%d|%d" % [run_seed, question_no]).shuffled(wrong).slice(0, 2)
	removed.sort()
	return removed


## Hint: the first step of the worked solution (Q5).
func use_hint() -> String:
	if not can_use("hint"):
		return ""
	lifelines.hint -= 1
	hint = question.solutions[0].steps[0]
	return hint


## Time Freeze: the clock stops for FREEZE_SECONDS.
func use_freeze() -> float:
	if not can_use("freeze"):
		return 0.0
	lifelines.freeze -= 1
	frozen_left = modifiers.apply("time", Tuning.FREEZE_SECONDS, _ctx())
	return frozen_left


# ── The end ──────────────────────────────────────────────────

func _end(reason: String) -> void:
	state = "ended"
	save.scrap = int(save.get("scrap", 0)) + int(stats.scrap)
	var totals: Dictionary = save.get("runs", {})
	totals.played = int(totals.get("played", 0)) + 1
	totals.best_fights = maxi(int(totals.get("best_fights", 0)), int(stats.fights_won))
	totals.questions = int(totals.get("questions", 0)) + int(stats.questions)
	totals.right = int(totals.get("right", 0)) + int(stats.right) + int(stats.late) + int(stats.glancing)
	save.runs = totals
	summary = {"reason": reason, "region": region, "seed": run_seed, "floor": floor_no, "fights": fight,
		"fights_won": stats.fights_won, "questions": stats.questions,
		"right": int(stats.right) + int(stats.late) + int(stats.glancing),
		"scrap": stats.scrap, "missed": missed.duplicate(), "stats": stats.duplicate(), "banked": save.scrap}
	run_ended.emit(summary)
