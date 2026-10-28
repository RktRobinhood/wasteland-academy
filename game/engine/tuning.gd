class_name Tuning
extends RefCounted
## Every number combat plays by, in one file: the timers (Q6 on the FAL-274 plan), the
## enemy tiers, Scrap, the default stakes table, the lifelines and "Another way". The
## dungeon (G4) and the Bazaar (G6) read and tune these too. Nothing else in the game
## writes a combat number down.
##
## Ported from the HTML game's js/combat.js unless the plan changed it. The changes:
##   - enemy HP is counted in HP, not hits (HIT per right answer), so a glancing hit
##     can take half a hit (Q7). The hits to beat each tier are the HTML game's.
##   - the timer comes from the question's marks and the floor (Q6), not the tier.

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

## The tier of fight n (js/combat.js island mode): the first rule whose `every` divides
## n wins, else D1 with chance LOW_TIER_D1 and D2 otherwise. G4's floors replace this.
const TIER_EVERY := [{"every": 10, "tier": 5}, {"every": 5, "tier": 4}, {"every": 3, "tier": 3}]
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
