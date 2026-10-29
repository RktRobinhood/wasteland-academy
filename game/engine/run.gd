class_name Run
extends RefCounted
## A run: a dungeon in one region (or Dungeon.ALL), floor after floor of fights, until
## the player's HP reaches 0 or they quit, then a summary that pays its Scrap into the
## save (FAL-413, FAL-415). It holds every rule and no UI, so a test can play a whole
## run with fixed answers; ui/fight.gd draws it.
##
## A floor is Tuning.FIGHTS_PER_FLOOR fights. Fight 5 is a mini-boss and fight 10 the
## boss: linked parts on one situation (Q9), see _open_boss(). Beating the boss opens
## the next floor and records the floor in the save (Dungeon.note_floor), so a later
## run can start on the next floor. Each floor serves its own cells (Dungeon.floor_cells), and
## every type of the floor appears on it at least once (Q14).
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
## fight slot is.
##
## The signals are for views only (the journey strip, FAL-331). Nothing in the run
## waits on them, so it plays the same with nothing connected.

signal run_started(region: String, avatar: String, seed: int)
signal question_opened(fight: int, tier: int)
signal answer_resolved(outcome: String)
signal run_ended(summary: Dictionary)
## A floor opens (the start floor, then each one after a boss falls).
signal floor_started(on_floor: int)
## The "boss beaten" event, after its heal has gone through the modifiers step.
## kind is "mini" or "boss".
signal boss_beaten(on_floor: int, kind: String)

## What a fight slot can be (FAL-347). Only "fight" is played until FAL-349.
const SLOT_KINDS := ["fight", "encounter", "cell"]

## The glancing hit's note (Q7).
const GLANCING_NOTE := "The IB needs 3 s.f."

var save: Dictionary
var region: String
var start_floor: int
## The floor being played, from start_floor down.
var floor_no: int
var run_seed: int
var avatar: String
var modifiers := Modifiers.new()
var stakes: Dictionary = Tuning.STAKES
## The clock for the planner's "got wrong recently" rule. Tests fix it.
var clock: Callable = func() -> int: return int(Time.get_unix_time_from_system())
## False for a run that jumped ahead (a screenshot link): it records no floors.
var records := true
## A screenshot link's jump: the first fight played is this one (1 = no jump).
var first_fight := 1

## "question" while a question is open, "result" after it is answered, "ended".
var state := ""
var hp := 0
var max_hp := 0
## The fight on this floor, 1 to FIGHTS_PER_FLOOR, and fights played in the run.
var fight := 0
var fights := 0
var slot := ""
## "fight", "mini" or "boss" (Dungeon.fight_kind).
var kind := "fight"
var tier := 0
## While a mini-boss or boss is on: {"kind", "type", "parts": [questions], "part",
## "link"} (link: the last part is a link question). {} in a normal fight, and in a
## boss fight whose region has no chain built yet (kind is still "mini" or "boss").
var boss: Dictionary = {}
## This floor's cells, and the types asked on it so far (Q14).
var floor_cells: Array = []
var floor_seen: Dictionary = {}
var warmups_left := 0
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
	"scrap": 0, "fights_won": 0, "another_way": 0, "minis": 0, "bosses": 0, "warmups": 0, "prior": 0}
## Skills missed, in the order they were first missed: "type name: what was asked".
var missed: Array = []
## One entry per answer: {"floor", "fight", "kind", "part", "tier", "cell", "rule",
## "outcome", "enemy_damage", "player_damage", "scrap"}. Tests compare runs by it.
var answers: Array = []
var summary: Dictionary = {}

var _followup: Dictionary = {}
## The prior-learning type to serve next, after a miss on a step that needs it.
var _prior := ""
## How the open question was picked: the planner's rule, "warm-up", "prior", "boss",
## "link" or "another-way".
var rule := ""


func _init(save_data: Dictionary, region_id: String, from_floor: int = 1, seed_no: int = 1, avatar_id: String = "learner") -> void:
	save = save_data
	region = region_id
	start_floor = maxi(1, from_floor)
	floor_no = start_floor
	run_seed = seed_no
	avatar = avatar_id


func start() -> void:
	max_hp = roundi(modifiers.apply("max_hp", Tuning.BASE_HP, {}))
	hp = max_hp
	lifelines = {}
	for id in Tuning.LIFELINES:
		lifelines[id] = maxi(0, roundi(modifiers.apply("lifelines", Tuning.LIFELINES[id], {"lifeline": id})))
	run_started.emit(region, avatar, run_seed)
	_enter_floor(start_floor)
	fight = clampi(first_fight, 1, Tuning.FIGHTS_PER_FLOOR) - 1
	_next_fight()


## What fight slot n on a floor is: a fight, an encounter or a cell (FAL-347), picked
## from the run seed. Always "fight" until encounters exist (FAL-349).
static func slot_kind(seed_no: int, on_floor: int, n: int) -> String:
	var _rng := Seeded.new("slot|%d|%d|%d" % [seed_no, on_floor, n])
	return "fight"


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
	var c := {"tier": tier, "floor": floor_no, "fight": fight}
	if not boss.is_empty():
		c.boss = boss.kind
	return c


func _enter_floor(f: int) -> void:
	floor_no = f
	fight = 0
	floor_cells = Dungeon.floor_cells(region, f, _exam_only())
	floor_seen = {}
	warmups_left = Tuning.WARMUPS if f == 1 else 0
	if records:
		Dungeon.note_floor(save, region, f, false)
	floor_started.emit(f)


func _exam_only() -> bool:
	return bool(save.get("settings", {}).get("exam_only", false))


func _next_fight() -> void:
	if fight >= Tuning.FIGHTS_PER_FLOOR:
		_enter_floor(floor_no + 1)
	fight += 1
	fights += 1
	slot = Run.slot_kind(run_seed, floor_no, fight)
	kind = Dungeon.fight_kind(fight)
	tier = Dungeon.tier_for(run_seed, floor_no, fight)
	var e: Dictionary = Tuning.ENEMIES[tier]
	enemy = {"name": e.name, "rank": e.rank, "art": e.art, "damage": Tuning.damage_on(int(e.damage), floor_no),
		"scrap": e.scrap, "hp": int(e.hits) * Tuning.HIT, "max_hp": int(e.hits) * Tuning.HIT}
	boss = {}
	if kind != "fight":
		boss = _make_boss()
		# With no chain built here yet, the boss is a normal fight at its tier; beating
		# it still clears the floor.
		if not boss.is_empty():
			_followup = {}
			enemy.hp = boss.parts.size() * Tuning.HIT
			enemy.max_hp = enemy.hp
			enemy.name = ("Mini-boss " if kind == "mini" else "Boss ") + enemy.name
	_open_question()


## The mini-boss or boss of this fight (Q9): the chain's parts made on one situation,
## plus a link question to end a boss where the region has one. {} if none can be made.
func _make_boss() -> Dictionary:
	var plan := Dungeon.boss_plan(run_seed, region, floor_no, kind, floor_cells)
	if plan.is_empty():
		return {}
	var chain := QuestionEngine.make_chain(plan.steps, plan.seed)
	if chain.has("error"):
		push_warning("Run: no %s on floor %d: %s" % [kind, floor_no, chain.error])
		return {}
	var parts: Array = chain.parts
	var link := false
	# A link type is extension material, so "Exam-style only" leaves the link part out.
	if not plan.link.is_empty() and not _exam_only():
		var lq := QuestionEngine.make(plan.link)
		if not lq.has("error"):
			lq.part = parts.size()
			parts.append(lq)
			link = true
	return {"kind": kind, "type": plan.type, "parts": parts, "part": 0, "link": link}


func _open_question() -> void:
	question_no += 1
	another_way = false
	if not boss.is_empty():
		question = boss.parts[boss.part]
		rule = "link" if boss.link and boss.part == boss.parts.size() - 1 else "boss"
	else:
		var view := _plan()
		question = QuestionEngine.make(view) if not view.has("error") else view
		if question.has("error"):
			push_error("Run: %s" % question.error)
			_end("no-questions")
			return
	floor_seen[question.view.type] = true
	removed = []
	hint = ""
	var marks: int = question.marks if question.marks > 0 else Tuning.DEFAULT_MARKS
	time_total = modifiers.apply("time", Tuning.seconds_for(marks, floor_no, question.format == "value"), _ctx())
	time_left = time_total
	frozen_left = 0.0
	state = "question"
	question_opened.emit(fight, tier)


## The next normal question's view: an "Another way" follow-up, a warm-up, the prior
## learning a miss called for, or the planner's pick from this floor's cells, types not
## yet asked on the floor first.
func _plan() -> Dictionary:
	var salt := "run|%d|%d" % [run_seed, question_no]
	if not _followup.is_empty():
		var v := _followup
		_followup = {}
		another_way = true
		rule = "another-way"
		return v
	var opts := {"probes": false, "salt": salt}
	var why := ""
	if warmups_left > 0:
		warmups_left -= 1
		opts.cells = Dungeon.prior_cells(region, _exam_only())
		why = "warm-up"
	elif _prior != "":
		opts.cells = QuestionEngine.cells(_exam_only(), [_prior])
		why = "prior"
	_prior = ""
	if opts.get("cells", []).is_empty():
		why = ""
		opts.cells = floor_cells
		opts.prefer_types = Dungeon.floor_types(floor_cells).filter(func(t): return not floor_seen.has(t))
	if opts.cells.is_empty():
		opts.erase("cells")
		opts.region = region
	var view := Planner.next(save, clock.call(), opts)
	rule = why if why != "" else view.get("rule", "")
	if why == "warm-up":
		stats.warmups += 1
	elif why == "prior":
		stats.prior += 1
	return view


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
	# A boss part is done whatever the answer: surviving every part beats the boss (Q9).
	if not boss.is_empty():
		fx.enemy_damage = Tuning.HIT
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
	answers.append({"floor": floor_no, "fight": fight, "kind": kind, "part": int(question.get("part", -1)), "tier": tier,
		"cell": question.cell, "seed": int(question.view.seed), "rule": rule, "outcome": outcome,
		"enemy_damage": fx.enemy_damage, "player_damage": fx.player_damage, "scrap": fx.scrap + bonus})
	var defeated: bool = enemy.hp <= 0 and (boss.is_empty() or hp > 0)
	var part := -1
	var carry := ""
	var healed := 0
	_followup = {}
	if not boss.is_empty():
		part = boss.part
		boss.part += 1
		if not defeated and boss.part < boss.parts.size() and boss.parts[boss.part].has("carried"):
			carry = boss.parts[boss.part].carried.text
	elif outcome == "right" and hp > 0 and not another_way:
		_followup = _another_way_view()
	# A missed step that needs prior learning brings it next (after a boss, once it falls).
	if not right and _prior == "":
		_prior = Dungeon.prior_for(region, question.cell, "%d|%d" % [run_seed, question_no])
	if defeated:
		stats.fights_won += 1
		if kind != "fight":
			healed = _boss_down()
	answer_resolved.emit(outcome)
	return {"complete": true, "outcome": outcome, "enemy_damage": fx.enemy_damage, "player_damage": fx.player_damage,
		"scrap": fx.scrap, "bonus": bonus, "note": GLANCING_NOTE if outcome == "glancing" else "",
		"solution": question.solutions[0] if outcome in ["wrong", "timeout"] else {},
		"misconception": m.get("misconception", ""), "defeated": defeated, "dead": hp <= 0,
		"another_way": not _followup.is_empty(), "part": part, "carry": carry, "healed": healed,
		"floor_cleared": defeated and kind == "boss"}


## The "boss beaten" event: the heal goes through the modifiers step (Second Wind, G6),
## then the save records the floor if it was the floor's boss. Returns the HP healed.
func _boss_down() -> int:
	stats.minis += 1 if kind == "mini" else 0
	stats.bosses += 1 if kind == "boss" else 0
	var c := _ctx()
	c.boss = kind
	var healed := heal(modifiers.apply("boss_heal", Tuning.BOSS_HEAL, c))
	if kind == "boss" and records:
		Dungeon.note_floor(save, region, floor_no, true)
	boss_beaten.emit(floor_no, kind)
	return healed


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

## Charges one use of a lifeline spends, through the modifiers (0 when it's free).
func lifeline_cost(lifeline: String) -> int:
	return maxi(0, roundi(modifiers.apply("lifeline_cost", 1, {"lifeline": lifeline})))


func can_use(lifeline: String) -> bool:
	if state != "question" or int(lifelines.get(lifeline, 0)) < lifeline_cost(lifeline):
		return false
	match lifeline:
		"fifty":
			return QuestionEngine.is_choice(question) and removed.is_empty()
		"hint":
			return hint == "" and not question.solutions.is_empty()
		"freeze":
			return frozen_left <= 0.0
	return false


## 50-50: takes away two wrong options. Returns their indices.
func use_fifty() -> Array:
	if not can_use("fifty"):
		return []
	lifelines.fifty -= lifeline_cost("fifty")
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
	lifelines.hint -= lifeline_cost("hint")
	hint = question.solutions[0].steps[0]
	return hint


## Time Freeze: the clock stops for FREEZE_SECONDS.
func use_freeze() -> float:
	if not can_use("freeze"):
		return 0.0
	lifelines.freeze -= lifeline_cost("freeze")
	var c := _ctx()
	c.freeze = true
	frozen_left = modifiers.apply("time", Tuning.FREEZE_SECONDS, c)
	return frozen_left


# ── The end ──────────────────────────────────────────────────

func _end(reason: String) -> void:
	state = "ended"
	save.scrap = int(save.get("scrap", 0)) + int(stats.scrap)
	var totals: Dictionary = save.get("runs", {})
	totals.played = int(totals.get("played", 0)) + 1
	totals.best_fights = maxi(int(totals.get("best_fights", 0)), int(stats.fights_won))
	totals.best_floor = maxi(int(totals.get("best_floor", 0)), floor_no)
	totals.questions = int(totals.get("questions", 0)) + int(stats.questions)
	totals.right = int(totals.get("right", 0)) + int(stats.right) + int(stats.late) + int(stats.glancing)
	save.runs = totals
	summary = {"reason": reason, "region": region, "seed": run_seed, "start_floor": start_floor, "floor": floor_no,
		"fight": fight, "fights": fights, "floors_cleared": stats.bosses, "bosses": stats.bosses, "minis": stats.minis,
		"fights_won": stats.fights_won, "questions": stats.questions,
		"right": int(stats.right) + int(stats.late) + int(stats.glancing),
		"scrap": stats.scrap, "missed": missed.duplicate(), "stats": stats.duplicate(), "banked": save.scrap}
	run_ended.emit(summary)
