class_name Tuning
extends RefCounted
## Every number combat plays by, in one file: the timers (Q6 on the FAL-274 plan), the
## enemy tiers, Scrap, the default stakes table, the lifelines, "Another way" and the
## dungeon (G4: floors, levels, warm-ups, bosses and their chains). The Bazaar (G6)
## reads and tunes these too. Nothing else in the game writes a combat number down.
##
## Ported from the HTML game's js/combat.js unless the plan changed it. The changes:
##   - enemy HP is counted in HP, not hits (HIT per right answer), so a glancing hit
##     can take half a hit (Q7). The hits to beat each tier are the HTML game's.
##   - the timer comes from the question's marks and the floor (Q6), not the tier.
##   - the island rhythm (D3 every 3rd fight, D4 every 5th) is now a floor of 10: D1-D2,
##     the mini-boss D3 at fight 5 and the boss D5 at fight 10, raised on deeper floors.

# ── Player ───────────────────────────────────────────────────

const BASE_HP := 100

# ── Enemies (js/combat.js ENEMIES and SCRAP_REWARDS) ─────────

## Enemy HP one right answer takes.
const HIT := 10

## Tier -> the enemy: hits is how many right answers beat it, damage the HP a wrong
## answer costs, scrap what a right answer earns (harder gives less, to reward
## productive struggle), art its file in assets/enemies/.
const ENEMIES := {
	1: {"name": "Scavenger", "rank": "RECRUIT", "hits": 3, "damage": 20, "scrap": 40, "art": "d1-scavenger.png"},
	2: {"name": "Raider", "rank": "OPERATIVE", "hits": 4, "damage": 25, "scrap": 30, "art": "d2-raider.png"},
	3: {"name": "Enforcer", "rank": "SERGEANT", "hits": 5, "damage": 30, "scrap": 20, "art": "d3-enforcer.png"},
	4: {"name": "Warlord", "rank": "COMMANDER", "hits": 5, "damage": 35, "scrap": 15, "art": "d4-warlord.png"},
	5: {"name": "OVERSEER", "rank": "OVERSEER", "hits": 6, "damage": 45, "scrap": 10, "art": "d5-overseer.png"},
}

## The tier of a normal fight: D1 with chance LOW_TIER_D1, else D2 (js/combat.js
## island mode). The mini-boss and the boss have their own tiers; see the dungeon below.
const LOW_TIER_D1 := 0.6

# ── Timers (Q6) ──────────────────────────────────────────────

## Minutes per mark on floors 1, 2 and 3.
const MINUTES_PER_MARK := [1.5, 1.25, 1.0]
## From floor 4, this much less per floor, down to MINUTES_PER_MARK_MIN.
const MINUTES_PER_MARK_STEP := 0.1
const MINUTES_PER_MARK_MIN := 0.6
## Extra seconds for a typed answer.
const TYPED_BONUS := 15
## No question gets less.
const MIN_SECONDS := 45
## Marks for a type the exam bank has no parts for (extension types), when the view
## doesn't set its own.
const DEFAULT_MARKS := 2
## The last fifth of the bar: a right answer here is late (a hit, with chip damage).
const LATE_ZONE := 0.2
## The bar is green above this share of the time, orange down to LATE_ZONE, then red.
const BAR_ORANGE := 0.5
## How long Time Freeze stops the clock (js/combat.js).
const FREEZE_SECONDS := 15.0

# ── Stakes (FAL-347): what each outcome does ─────────────────

## The default stakes table. For each outcome:
##   enemy   hits taken off the enemy (HIT each)
##   player  share of the enemy's damage the player takes
##   plus    flat extra damage to the player
##   scrap   share of the tier's Scrap earned
## Encounters (FAL-349) pass their own table to the same resolve step.
const STAKES := {
	"right": {"enemy": 1.0, "player": 0.0, "plus": 0, "scrap": 1.0},
	"glancing": {"enemy": 0.5, "player": 0.0, "plus": 0, "scrap": 0.5},
	"late": {"enemy": 1.0, "player": 0.25, "plus": 0, "scrap": 0.6},
	"wrong": {"enemy": 0.0, "player": 1.0, "plus": 0, "scrap": 0.0},
	"timeout": {"enemy": 0.0, "player": 1.0, "plus": 10, "scrap": 0.0},
}
const OUTCOMES := ["right", "glancing", "late", "wrong", "timeout"]

# ── Lifelines ────────────────────────────────────────────────

## Charges of each lifeline a run starts with (the Bazaar adds to these).
const LIFELINES := {"fifty": 1, "hint": 1, "freeze": 1}

# ── "Another way" (FAL-310) ──────────────────────────────────

## After a right answer on this floor or deeper, a follow-up asks the same question by
## another method, with this chance, where the type lists more than one angle.
const ANOTHER_WAY_FLOOR := 2
const ANOTHER_WAY_CHANCE := 0.25
## Bonus Scrap for getting the follow-up right, as a share of the tier's Scrap.
const ANOTHER_WAY_BONUS := 0.5


# ── The dungeon (G4, Q4 and Q9) ──────────────────────────────

## A floor is FIGHTS_PER_FLOOR fights: the mini-boss at MINI_BOSS_AT, the boss at the end.
const FIGHTS_PER_FLOOR := 10
const MINI_BOSS_AT := 5
## Tiers before the raise: a normal fight is D1-D2 (LOW_TIER_D1), the mini-boss D3 and
## the boss D5 (js/combat.js: "D1-D2 normally, D3 mini-boss every 5th, D5 boss").
const MINI_BOSS_TIER := 3
const BOSS_TIER := 5
## From RAISE_FROM_FLOOR, every tier goes up 1 each RAISE_EVERY floors, to D5 at most:
## floors 4-5 +1, 6-7 +2, 8 and deeper +3 (normal fights D4-D5).
const RAISE_FROM_FLOOR := 4
const RAISE_EVERY := 2
## Past the tiers' cap, deeper floors still get harder: from RAISE_FROM_FLOOR an enemy's
## damage grows by DEEP_DAMAGE_STEP of itself per floor (floor 4 ×1.1, floor 8 ×1.5).
const DEEP_DAMAGE_STEP := 0.1

## The levels each floor serves (FAL-310 plan, "Levels"). Floor MIX_FROM_FLOOR and
## deeper serve every level, 0 to 5, and every type of the region (Q14).
const FLOOR_LEVELS := {1: [0, 2], 2: [2, 3], 3: [3, 4]}
const MIX_FROM_FLOOR := 4
## A link question (kind "link", the fn-link-* types) plays as level 5, synoptic,
## whatever its unknowns' levels say: on bosses and from MIX_FROM_FLOOR only.
const LINK_LEVEL := 5

## Floor tables, where a region's levels alone don't give Q4's floors. Floor -> the
## types it serves. A type serves its cells up to the floor's top level, and from the
## floor's bottom level, except on the first floor the table lists it, where its easier
## cells come along too (so floor 3's discriminant still starts at "how many roots").
## Prior-learning types (kind "prior-learning", level 0) always join floor 1. A floor
## with none of its types built falls back to the level rule, so nothing is empty while
## a region is half built. Quadratics checked on FAL-415: by levels alone every one of
## its exam types lands on floors 1, 2 and 3, so Q4 needs this table.
const FLOOR_TYPES := {
	"quadratics": {
		1: ["fn-quadratic-features"],
		2: ["fn-quadratic-features", "fn-quadratic-from-conditions", "fn-solve-quadratic", "fn-concept-quadratic-forms",
			"fn-ext-quadratic-model"],
		3: ["fn-discriminant", "fn-quadratic-inequality", "fn-curve-intersection-quadratic", "fn-ext-quadratic-model"],
	},
}

## Level-0 warm-ups: the first fight of floor 1 opens with this many prior-learning
## questions. After a missed question whose skills a prior-learning type `supports`,
## the next question is one of that type's (FAL-310 plan).
const WARMUPS := 2

## Mini-bosses and bosses (Q9): one situation, parts in the order of the type's chain.
## A mini-boss asks MINI_BOSS_PARTS parts, a boss BOSS_PARTS (one of them, by the run
## seed). Each part has its own clock from its own marks. A wrong part costs HP, shows
## the right value, and the next part carries on from it. Surviving every part beats it.
const MINI_BOSS_PARTS := [2]
const BOSS_PARTS := [3, 4]
## A boss ends with one link question when its region has one built (Q9's level 5).
const BOSS_LINK_PART := true
## HP back when a boss falls, before the modifiers (Second Wind, G6, adds 20 there).
const BOSS_HEAL := 0

## Each type's `chain` (curriculum/question-types.json) as unknowns, in chain order.
## A step is an unknown of the type, or "type:unknown" for a type on the same
## situation (the chain's "expand to general form" is a features unknown). Parts are
## consecutive steps, so each part carries on from the one before. A type with no
## entry here (or whose steps' situations can't be one) has no boss.
const CHAINS := {
	# intercepts, the axis as their midpoint, the vertex, vertex form, the y-intercept
	"fn-quadratic-features": ["roots-from-factorised", "axis-from-roots", "vertex-from-factorised",
		"vertex-form-from-factorised", "y-intercept-from-vertex-form"],
	# a from a further point, expand to general form, factorise, the range from the vertex
	"fn-quadratic-from-conditions": ["a-from-vertex-and-point", "fn-quadratic-features:general-from-vertex-form",
		"fn-quadratic-features:factorised-from-general", "range-after-finding"],
	# equate and rearrange, solve, the coordinates, the distance between them
	"fn-curve-intersection-quadratic": ["equate-to-quadratic", "meeting-x", "meeting-points", "chord-length"],
	# Δ in k, then Δ = 0, then the interval of k
	"fn-discriminant": ["delta-in-k", "k-for-equal-roots", "k-interval"],
	# the substitution, then solve and reject the impossible root
	"fn-solve-quadratic": ["choose-substitution", "solve-hidden-exponential"],
	# k from a second reading, predict, the time to a level, then whole time units. The
	# chain's opener (the initial value) and closer (the long-run value) are on a limited
	# growth model, which these four parts can't share, so they stay single questions.
	"fn-exponential-model": ["k-from-data-point", "predict-from-data-point", "time-to-level", "whole-units-inequality"],
	# evaluate g, find g⁻¹, evaluate g⁻¹: all on one log function. The chain's composite
	# and transformation parts need a second function, so they stay single questions.
	"fn-exp-log-inverse-composite": ["evaluate-log-function", "inverse-of-log", "evaluate-inverse"],
	# the roots and the domain, the asymptotes at the roots, the zeros from g(x) = 1, the maximum
	"fn-log-of-quadratic": ["argument-roots", "domain-from-inequality", "asymptotes", "zeros", "max-value"],
	# the asymptote opens, then the domain, where it crosses the x-axis, and an inequality
	"fn-log-function-features": ["asymptote-from-equation", "domain-from-equation", "x-intercept", "log-inequality"],
	# the sketch, then its labelled zeros and turning point, then how many solutions f(x) = k has
	"fn-sketch-gdc": ["sketch-on-domain", "label-zeros", "label-turning-point", "count-solutions-from-sketch"],
	# the y-intercept and the zeros, the distance between the stored zeros, the turning point
	"fn-gdc-features": ["y-intercept", "zeros-gdc", "use-stored-zeros", "turning-point-coordinates"],
	# the meeting points, the one in an interval, then the distance between them
	"fn-gdc-intersection": ["intersection-points", "crossing-in-interval", "distance-between-crossings"],
	# form D(t), find its greatest value and when, then say what the time means
	"fn-gdc-optimise-combined": ["form-difference", "max-difference", "interpret-extreme"],
	# solve on the GDC, then reject the root the context can't have
	"fn-gdc-solve-equation": ["root-in-interval", "reject-a-root"],
}


## How many tiers a floor raises every enemy by (before the D5 cap).
static func raise_for(on_floor: int) -> int:
	if on_floor < RAISE_FROM_FLOOR:
		return 0
	return 1 + floori(float(on_floor - RAISE_FROM_FLOOR) / RAISE_EVERY)


## An enemy's damage on a floor: its tier's damage, grown on deep floors.
static func damage_on(base: int, on_floor: int) -> int:
	if on_floor < RAISE_FROM_FLOOR:
		return base
	return roundi(base * (1.0 + DEEP_DAMAGE_STEP * (on_floor - RAISE_FROM_FLOOR + 1)))


## Minutes per mark on a floor (Q6).
static func minutes_per_mark(on_floor: int) -> float:
	if on_floor <= MINUTES_PER_MARK.size():
		return MINUTES_PER_MARK[maxi(on_floor, 1) - 1]
	var m: float = MINUTES_PER_MARK[-1] - MINUTES_PER_MARK_STEP * (on_floor - MINUTES_PER_MARK.size())
	return maxf(MINUTES_PER_MARK_MIN, snappedf(m, 0.001))


## Seconds a question gets: marks × minutes per mark, plus TYPED_BONUS for a typed
## answer, never under MIN_SECONDS.
static func seconds_for(marks: int, on_floor: int, typed: bool) -> int:
	var s := roundi(maxi(marks, 1) * minutes_per_mark(on_floor) * 60.0) + (TYPED_BONUS if typed else 0)
	return maxi(MIN_SECONDS, s)


# ── The Bazaar (G6, Q10) ─────────────────────────────────────
#
# Prices are set from the Scrap a typical student banks in a run: a simulated player
# who answers 70% right earns about SCRAP_PER_RUN_70 (FAL-416; G4's balance check on
# the dungeon run measured 520). A permanent unlock (an upgrade level or a cosmetic)
# costs 2 to 3 runs of that, so they unlock something every 2 or 3 runs (test_bazaar.gd
# plays it). A perk costs
# under one run, the HTML game's prices (175 to 250 at about 300 Scrap a run) scaled
# to this game's Scrap. Q10: rebalance once there's play data.

## Scrap a 70%-right player banks per run, the figure the prices below are set from.
const SCRAP_PER_RUN_70 := 520

## Permanent upgrades: one price per level, so the cap is the number of prices.
##   max_hp    +MAX_HP_STEP max HP a level (100 to 130)
##   lifeline  +1 charge of a lifeline the player picks when buying
const UPGRADES := {
	"max_hp": [1150, 1300, 1425],
	"lifeline": [1225, 1350],
}
const MAX_HP_STEP := 10

## Perks: one slot, bought for the next run only, used up when it starts.
const PERKS := {
	"field_manual": 400,   # hints are free (a Hint spends no charge)
	"scrap_armour": 350,   # +PERK_ARMOUR_HP HP
	"lucky_find": 275,     # +1 charge on a lifeline the player picks
	"second_wind": 375,    # heal PERK_SECOND_WIND_HP after each boss
	"field_watch": 300,    # +PERK_WATCH_SECONDS on every question's clock
}
const PERK_ARMOUR_HP := 20
const PERK_SECOND_WIND_HP := 20
## The boss kinds Second Wind heals after ("mini" is the mini-boss at fight 5).
const PERK_SECOND_WIND_AFTER := ["boss"]
const PERK_WATCH_SECONDS := 10

## Cosmetics: every name-plate frame and colour tint costs the same.
const COSMETIC_PRICE := 1100
