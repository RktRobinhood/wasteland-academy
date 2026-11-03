class_name JourneyLink
extends RefCounted
## Drives a JourneyStage from a Run's view signals (engine/run.gd), for the fight
## screen (ui/fight.gd). It only listens: every call reaches the stage deferred, so
## nothing it does can delay the run, and the run plays the same with no link at all.
##
##   JourneyLink.attach(run, stage, save)   before run.start(); the stage keeps the link
##
## The run's regions map to a journey region through their island (MapLink.island_of),
## and the avatar is the save's profile.avatar, "female" when there is none, as the HTML
## game does (js/router.js). A run region whose island has no journey art yet, or an
## avatar with no sheet, hides the strip (JourneyStage.start_run()).

## Island -> the journey region folder in assets/journey/.
const ISLAND_REGION := {"functions": "signal-tower"}
## The run's outcomes -> the strip's. A glancing hit is the strip's partial.
const OUTCOME := {"glancing": "partial"}

var run: Run
## A JourneyStage, or anything with its methods (tests use a recorder).
var stage: Control
var avatar := "learner-female"
## run.fights when the open encounter started; -1 while none is open.
var _fight := -1


static func attach(p_run: Run, p_stage: Control, save: Dictionary = {}) -> JourneyLink:
	var link := JourneyLink.new()
	link.run = p_run
	link.stage = p_stage
	link.avatar = avatar_for(save)
	p_run.run_started.connect(link._on_started)
	p_run.question_opened.connect(link._on_opened)
	p_run.answer_resolved.connect(link._on_resolved)
	p_run.run_ended.connect(link._on_ended)
	# The stage keeps its link alive (the run's signals don't), and drops the last one.
	p_stage.set_meta("journey_link", link)
	return link


## The journey sheet for the save's avatar: "learner-female" or "learner-male".
static func avatar_for(save: Dictionary) -> String:
	var profile = save.get("profile", {})
	var id := String(profile.get("avatar", "")) if profile is Dictionary else ""
	return "learner-" + (id if id != "" else "female")


static func region_for(run_region: String) -> String:
	return String(ISLAND_REGION.get(MapLink.island_of(run_region), ""))


func _on_started(region: String, _avatar: String, run_seed: int) -> void:
	_fight = -1
	_call("start_run", [region_for(region), avatar, "rebar", run_seed])


func _on_opened(fight: int, tier: int) -> void:
	if _fight != run.fights:
		if _fight >= 0:
			_call("fight_ended", [])
		_fight = run.fights
		var questions: int = run.boss.parts.size() if not run.boss.is_empty() else ceili(float(run.enemy.max_hp) / Tuning.HIT)
		_call("fight_started", [fight, tier, maxi(1, questions)])
	_call("question_opened", [run.question_no])


func _on_resolved(outcome: String) -> void:
	var info := {}
	if not run.answers.is_empty():
		info.damage = int(run.answers[-1].player_damage)
	_call("answer_resolved", [String(OUTCOME.get(outcome, outcome)), info])
	if int(run.enemy.hp) <= 0:
		_call("fight_ended", [])
		_fight = -2


func _on_ended(_summary: Dictionary) -> void:
	if _fight >= 0:
		_call("fight_ended", [])
	_fight = -1
	_call("run_ended", [])


func _call(method: String, args: Array) -> void:
	if stage != null and is_instance_valid(stage) and stage.has_method(method):
		stage.callv.call_deferred(method, args)
