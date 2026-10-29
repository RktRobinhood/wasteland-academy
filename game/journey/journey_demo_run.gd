class_name JourneyDemoRun
extends RefCounted
## A scripted run for the journey demo screen and the tests: the FAL-293 reel's script
## (three monsters, a weapon swap, the live-wire trap, the cache), then one encounter of
## each kind the reel didn't show. It keeps its own HP, Scrap and results, and tells a
## listener (a JourneyStage) what happened. It never reads anything back, so the results
## are the same with the strip on, off or broken: test_journey.gd checks that.

const REGION := "signal-tower"
## Per fight: tier, the encounter to force (the reel's, or {} to let JourneyBeats pick),
## and the questions as [question, options, correct index, picked index or outcome].
## A string pick is that outcome with the correct option shown (late, partial, timeout).
const SCRIPT := [
	{"fight": 1, "tier": 3, "encounter": {"kind": "fight", "group": ["d1-scavenger", "dishback", "d1-scavenger"], "hits": [1, 1, 1]},
		"questions": [
			["f(x) = 2x + 3.  Find f(4).", ["7", "11", "14", "8"], 1, 1],
			["g(x) = x² − 1.  Find g(−3).", ["−10", "−8", "8", "10"], 2, 2],
			["The domain of f(x) = √(x − 2) is", ["x > 0", "x ≥ 2", "x ≥ −2", "all real x"], 1, 0],
			["f(x) = 3x − 5.  Find f⁻¹(4).", ["7", "−1", "3", "1/3"], 2, 2]]},
	{"weapon": "neon-blade"},
	{"fight": 2, "tier": 2, "encounter": {"kind": "puzzle", "prop": "obstacle-livewire"},
		"questions": [["f(x) = x + 2, g(x) = 3x.  Find (f∘g)(1).", ["9", "5", "6", "3"], 1, 0]]},
	{"fight": 3, "tier": 1, "encounter": {"kind": "explore", "prop": "cache-vending"},
		"questions": [["The range of f(x) = x² + 1 is", ["y ≥ 1", "y > 0", "all real y", "y ≥ 0"], 0, 0]]},
	{"fight": 4, "tier": 1, "encounter": {"kind": "explore", "prop": "scrap-pile"},
		"questions": [
			["f(x) = 5 − x.  Find f(2).", ["3", "7", "−3", "2"], 0, 0],
			["h(x) = 2x².  Find h(3).", ["12", "18", "36", "6"], 1, 1]]},
	{"fight": 5, "tier": 2, "encounter": {"kind": "explore", "prop": "mud-stuck"},
		"questions": [
			["The y-intercept of y = 3x − 4 is", ["3", "−4", "4", "4/3"], 1, 0],
			["Solve 2x + 1 = 9.", ["4", "5", "3", "8"], 0, 0]]},
	{"fight": 6, "tier": 3, "encounter": {"kind": "puzzle", "prop": "vault-dials"},
		"questions": [
			["f(x) = x² − 4x.  The vertex is at x =", ["2", "−2", "4", "0"], 0, 0],
			["f(x) = 1/x.  The vertical asymptote is", ["y = 0", "x = 0", "x = 1", "y = 1"], 1, "late"],
			["The gradient of y = 7 − 2x is", ["7", "2", "−2", "−7"], 2, 2]]},
	{"weapon": "antenna-spear"},
	{"fight": 7, "tier": 4, "encounter": {"kind": "fight", "group": ["d2-raider", "d1-scavenger", "d4-warlord"], "hits": [1, 1, 1], "ambush": true},
		"questions": [
			["f(x) = eˣ.  f(0) =", ["0", "1", "e", "−1"], 1, 1],
			["log₂ 8 =", ["3", "4", "2", "8"], 0, "timeout"],
			["f(x) = 2ˣ.  f(3) =", ["6", "9", "8", "5"], 2, 2],
			["ln e² =", ["1", "e", "2", "2e"], 2, 2]]},
	{"fight": 10, "tier": 5, "encounter": {"kind": "boss", "group": ["d5-overseer"]},
		"questions": [
			["f(x) = (x − 1)(x + 3).  The roots are", ["1 and −3", "−1 and 3", "1 and 3", "−1 and −3"], 0, 0],
			["The inverse of f(x) = x + 4 is", ["x − 4", "4 − x", "1/(x + 4)", "x + 4"], 0, "partial"],
			["f(x) = x³.  f(−2) =", ["8", "−8", "−6", "6"], 1, 1],
			["The range of f(x) = −x² is", ["y ≤ 0", "y ≥ 0", "all real y", "y < 0"], 0, 3],
			["g(x) = |x|.  g(−5) =", ["−5", "5", "0", "25"], 1, 1]]},
]
## The reel's pacing: a question stays open this long, then its beat plays.
const OPEN := 2.0
const BEAT := 1.9
const LEAD_IN := JourneyStage.APPROACH + JourneyStage.ENTER
const OUTRO := 2.6
const MISS := {1: 8, 2: 15, 3: 25, 4: 35, 5: 50}
const SCRAP := {1: 30, 2: 22, 3: 15, 4: 10, 5: 5}

## Whatever listens: a JourneyStage, or null. Told everything with call_deferred.
var listener: Object
var run_seed := 7
var hp := 100
var scrap := 0
var results: Array = []
var clock := 0.0
## What the card shows: {fight, index, question, options, correct, picked, outcome, open}.
var card := {}
var done := false
## Call the listener at once instead of deferred (seeking and tests step many frames
## with no idle time between them).
var direct := false

var _events: Array = []     # [time, method, args]
var _next := 0


func _init(p_seed: int = 7) -> void:
	run_seed = p_seed
	_plan()


func _plan() -> void:
	var t := 0.0
	_events.append([t, "start_run", [REGION, "learner-female", "rebar", run_seed]])
	for f in SCRIPT:
		if f.has("weapon"):
			_events.append([t, "set_weapon", [f.weapon]])
			t += BEAT
			continue
		var qs: Array = f.questions
		_events.append([t, "fight_started", [f.fight, f.tier, qs.size(), f.encounter]])
		t += LEAD_IN if f.encounter.get("kind") in ["fight", "boss"] else JourneyStage.APPROACH
		for i in qs.size():
			_events.append([t, "question_opened", [f.fight, i, qs[i]]])
			t += OPEN
			_events.append([t, "answer_resolved", [f.fight, f.tier, i, qs[i]]])
			t += BEAT
		_events.append([t, "fight_ended", []])
		t += 2.3
	_events.append([t, "run_ended", []])
	_events.append([t + OUTRO, "finish", []])


## The length of the whole script in seconds.
func length() -> float:
	return _events[-1][0]


static func outcome_of(q: Array) -> String:
	if q[3] is String:
		return q[3]
	return "right" if int(q[3]) == int(q[2]) else "wrong"


func step(dt: float) -> void:
	clock += dt
	while _next < _events.size() and _events[_next][0] <= clock:
		_fire(_events[_next])
		_next += 1


func _fire(ev: Array) -> void:
	var args: Array = ev[2]
	match ev[1]:
		"question_opened":
			var q: Array = args[2]
			card = {"fight": args[0], "index": args[1], "question": q[0], "options": q[1], "correct": q[2],
					"picked": -1, "outcome": "", "open": true}
			notify("question_opened", [args[1]])
		"answer_resolved":
			var q: Array = args[3]
			var outcome := outcome_of(q)
			var tier: int = args[1]
			var lost := 0
			if outcome in ["wrong", "timeout"]:
				lost = MISS[tier]
			elif outcome in ["late", "partial"]:
				scrap += SCRAP[tier] / 2
			else:
				scrap += SCRAP[tier]
			hp = maxi(0, hp - lost)
			results.append({"fight": args[0], "question": args[2], "outcome": outcome, "hp": hp})
			card.picked = q[3] if q[3] is int else int(q[2])
			card.outcome = outcome
			card.open = false
			notify("answer_resolved", [outcome, {"damage": lost}])
		"finish":
			done = true
		_:
			notify(ev[1], args)


## Fire and forget: the listener's errors can't reach the run.
func notify(method: String, args: Array) -> void:
	if listener == null or not is_instance_valid(listener) or not listener.has_method(method):
		return
	if direct:
		listener.callv(method, args)
	else:
		listener.callv.call_deferred(method, args)


## What a save would hold.
func save_data() -> Dictionary:
	return {"hp": hp, "scrap": scrap, "results": results.duplicate(true)}
