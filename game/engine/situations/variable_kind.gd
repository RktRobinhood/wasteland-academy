class_name VariableKindSituation
extends RefCounted
## The `variable-kind` situation (curriculum/question-types.json): a variable from a study, counted
## or measured, for t4-ext-data-type (FAL-778). The bank is VariableKindViews.VARS; each entry has
## its kind (discrete or continuous) and its trap: "" for a plain count or measurement, "decimal"
## for a count in steps that have decimals (half shoe sizes, cents), "rounded" for a measurement
## recorded to the nearest whole unit.
##
## generate() returns ask, paper, v (the variable asked about, an index into VARS), vals (recorded
## values for a table, as text) and, for which-continuous and which-discrete, four (four indices,
## the answer first, then the trap, then two plain ones of the other kind).

const PLAIN_D := [0, 1, 2, 3, 4, 5]
const STEPPED := [6, 7, 8, 9]
const PLAIN_C := [10, 11, 12, 13, 14, 15]
const ROUNDED := [16, 17, 18, 19]


static func generate(rng: Seeded, need: Dictionary = {}) -> Dictionary:
	var ask: String = need.get("ask", "classify-variable")
	var s := {"ask": ask, "paper": int(need.get("paper", 1)), "four": []}
	match ask:
		"classify-variable":
			s.v = rng.pick(PLAIN_D if rng.chance(0.5) else PLAIN_C)
		"decimal-but-discrete":
			s.v = rng.pick(STEPPED)
		"rounded-but-continuous":
			s.v = rng.pick(ROUNDED)
		"which-continuous":
			s.v = rng.pick(PLAIN_C + ROUNDED)
			s.four = [s.v, rng.pick(STEPPED)] + rng.shuffled(PLAIN_D).slice(0, 2)
		"which-discrete":
			s.v = rng.pick(PLAIN_D + STEPPED)
			s.four = [s.v, rng.pick(ROUNDED)] + rng.shuffled(PLAIN_C).slice(0, 2)
	s.vals = values(rng, s.v)
	return s


## Five to seven different recorded values of a variable, in its own steps, as text.
static func values(rng: Seeded, v: int) -> Array:
	var e: Dictionary = VariableKindViews.VARS[v]
	var steps: int = roundi((e.hi - e.lo) / e.step)
	var picks: Array = rng.shuffled(range(steps + 1)).slice(0, rng.int_in(5, 7))
	return picks.map(func(i): return _text(e.lo + i * e.step, e))


## A value as the study writes it: whole sizes and scores lose their ".0" (7, 7.5), cents keep both
## places (2.40).
static func _text(x: float, e: Dictionary) -> String:
	if e.dp == 0 or (e.get("trim", false) and is_equal_approx(x, roundf(x))):
		return str(roundi(x))
	return ("%." + str(e.dp) + "f") % x


static func export(s: Dictionary) -> Dictionary:
	return ExtensionViews.export(s)
