class_name JourneyBeats
extends RefCounted
## Which beat the journey strip plays: a pure function of (run seed, fight number,
## question index, tier) and the sheets that exist (FAL-289 plan, "Three kinds of beat").
## The same run always gives the same beats, so a fight screen can call it too to label
## an encounter without the strip sending anything back.
##
##   D1  explore                    small jobs on the road
##   D2  explore or puzzle
##   D3  fight (1-2 monsters, the Enforcer leading), now and then a puzzle
##   D4  fight (2-3 monsters or a bandit ambush, the Warlord leading)
##   D5  boss
##   fight 5 is a mini-boss and fight 10 the boss, whatever the tier
##
## Tier 0 means the run has no tier yet: it is taken as D1 or D2, seeded.
##
## One encounter covers one fight's questions, and each right answer clears one step:
## one hit on a monster, one heave, one pin or one dial. In a group the others go down
## in one hit each and the lead, at the back, takes the hits that are left.

const MINI_BOSS_FIGHT := 5
const BOSS_FIGHT := 10
const PUZZLE_ON_D2 := 0.5
const PUZZLE_ON_D3 := 0.25
const AMBUSH_ON_D4 := 0.4

## HP a miss costs, by tier (SPEC 5.2). The strip shows it unless the run says otherwise.
const MISS_COST := {1: 8, 2: 15, 3: 25, 4: 35, 5: 50}


## The beat for one question: the fight's encounter plus `step` (the question index).
static func pick(run_seed: int, fight: int, question: int, tier: int, roster: Dictionary, questions: int = 3) -> Dictionary:
	var b := encounter(run_seed, fight, tier, roster, questions)
	b.step = question
	return b


## The encounter for one fight. roster is JourneyAssets.roster(region):
## {explore: [prop], puzzle: [prop], creatures: [sheet], enemies: {tier: sheet},
## bosses: {tier: stage count}}.
##
## Returns {kind: "explore" | "puzzle" | "fight" | "boss" | "travel", tier, assumed_tier,
## fight, questions, prop, group: [sheet, ...] front to back, hits: [int, ...],
## ambush, stages}. "travel" means no sheet fits, so the party just walks on.
static func encounter(run_seed: int, fight: int, tier: int, roster: Dictionary, questions: int = 3) -> Dictionary:
	var rng := Seeded.new("journey:%d:%d:%d" % [run_seed, fight, tier])
	rng.rng.randi()   # the first draw barely changes with the seed, so skip it
	questions = maxi(1, questions)
	var e := {"kind": "travel", "tier": tier, "assumed_tier": tier <= 0, "fight": fight, "questions": questions,
			"prop": "", "group": [], "hits": [], "ambush": false, "stages": 1}
	if tier <= 0:
		e.tier = rng.int_in(1, 2)
	tier = clampi(e.tier, 1, 5)
	e.tier = tier
	var enemies: Dictionary = roster.get("enemies", {})
	var bosses: Dictionary = roster.get("bosses", {})
	if fight == BOSS_FIGHT or tier == 5:
		var boss := _top_boss(bosses, 5)
		if boss > 0:
			return _boss(e, enemies[boss], bosses[boss])
	if fight == MINI_BOSS_FIGHT:
		var minis: Array = bosses.keys().filter(func(t): return t < 5)
		minis.sort()
		if not minis.is_empty():
			var t: int = rng.pick(minis)
			return _boss(e, enemies[t], bosses[t])
	var kind := "explore"
	match tier:
		2:
			kind = "puzzle" if rng.chance(PUZZLE_ON_D2) else "explore"
		3:
			kind = "puzzle" if rng.chance(PUZZLE_ON_D3) else "fight"
		4, 5:
			kind = "fight"
	if kind == "fight":
		var group := _group(rng, tier, enemies, roster.get("creatures", []), questions)
		if not group.is_empty():
			e.kind = "fight"
			e.ambush = group.pop_back() as bool
			e.group = group
			e.hits = _hits(group.size(), questions)
			return e
		kind = "puzzle"   # no monster sheets: the hardest non-fight beat
	var props: Array = roster.get(kind, [])
	if props.is_empty():
		kind = "puzzle" if kind == "explore" else "explore"
		props = roster.get(kind, [])
	if props.is_empty():
		return e
	e.kind = kind
	e.prop = rng.pick(props)
	return e


## Monsters front to back with the lead last, then whether it's an ambush.
static func _group(rng: Seeded, tier: int, enemies: Dictionary, creatures: Array, questions: int) -> Array:
	var lead := ""
	for t in range(tier, 0, -1):
		if enemies.has(t):
			lead = enemies[t]
			break
	if lead == "" and creatures.is_empty():
		return []
	if lead == "":
		lead = rng.pick(creatures)
	var bandits: Array = []
	for t in [1, 2]:
		if enemies.has(t) and enemies[t] != lead:
			bandits.append(enemies[t])
	var fill: Array = bandits + creatures
	var ambush := tier >= 4 and not bandits.is_empty() and rng.chance(AMBUSH_ON_D4)
	var extra := 0
	if tier == 3:
		extra = rng.int_in(0, 1)
	elif tier >= 4:
		extra = rng.int_in(1, 2)
	extra = mini(extra, questions - 1)
	var pool := bandits if ambush else fill
	var group: Array = []
	for i in extra:
		if not pool.is_empty():
			group.append(rng.pick(pool))
	group.append(lead)
	group.append(ambush)
	return group


## Hits each monster takes: one for the others, the rest for the lead.
static func _hits(n: int, questions: int) -> Array:
	var out: Array = []
	for i in n - 1:
		out.append(1)
	out.append(maxi(1, questions - (n - 1)))
	return out


static func _top_boss(bosses: Dictionary, below_or_at: int) -> int:
	var best := 0
	for t in bosses:
		if t <= below_or_at and t > best:
			best = t
	return best


static func _boss(e: Dictionary, sheet: String, stages: int) -> Dictionary:
	e.kind = "boss"
	e.group = [sheet]
	e.hits = [e.questions]
	e.stages = stages
	return e


## True if the beat puts a monster on screen.
static func has_monster(b: Dictionary) -> bool:
	return b.kind in ["fight", "boss"]
