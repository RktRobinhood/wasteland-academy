class_name VariableKindViews
extends ExtensionViews
## The views on the `variable-kind` situation: one builder per unknown of t4-ext-data-type
## (FAL-778). Every answer is a picked `claim`: the kind with its reason, or the one variable of the
## asked kind among four. Wrong options are SL4.1.data-type's two misconceptions (decimals read as
## continuous, whole-unit records read as discrete) and the type's own two.
##
## Representations: "words" (the variable in a sentence) and "table" (a few of its recorded values).

const SK := "SL4.1.data-type#"
const R_DECIMAL := SK + "0"
const R_ROUNDED := SK + "1"
const R_MEAN := "t4-ext-data-type#2"
const R_FEW := "t4-ext-data-type#3"
const UNKNOWNS := ["classify-variable", "decimal-but-discrete", "rounded-but-continuous", "which-continuous", "which-discrete"]

## The bank: what is recorded, its kind ("d" or "c"), its trap ("" plain, "decimal", "rounded"),
## how it is found, the table's head, the values' steps (lo, hi, step, dp, trim) and two
## neighbouring values for the in-between test (a, b, and whether a value between them can occur).
const VARS := [
	{"what": "the number of goats each farmer keeps", "kind": "d", "trap": "", "how": "counted", "head": "goats", "lo": 0.0, "hi": 30.0, "step": 1.0, "dp": 0, "a": "4 goats", "b": "5 goats"},
	{"what": "the number of crates on each truck", "kind": "d", "trap": "", "how": "counted", "head": "crates", "lo": 2.0, "hi": 40.0, "step": 1.0, "dp": 0, "a": "12 crates", "b": "13 crates"},
	{"what": "the number of radio messages the tower receives each day", "kind": "d", "trap": "", "how": "counted", "head": "messages", "lo": 5.0, "hi": 60.0, "step": 1.0, "dp": 0, "a": "20 messages", "b": "21 messages"},
	{"what": "the number of people living in each shelter", "kind": "d", "trap": "", "how": "counted", "head": "people", "lo": 1.0, "hi": 25.0, "step": 1.0, "dp": 0, "a": "6 people", "b": "7 people"},
	{"what": "the number of eggs each hen lays in a week", "kind": "d", "trap": "", "how": "counted", "head": "eggs", "lo": 0.0, "hi": 7.0, "step": 1.0, "dp": 0, "a": "3 eggs", "b": "4 eggs"},
	{"what": "the number of punctures each bike gets in a month", "kind": "d", "trap": "", "how": "counted", "head": "punctures", "lo": 0.0, "hi": 12.0, "step": 1.0, "dp": 0, "a": "2 punctures", "b": "3 punctures"},
	{"what": "the shoe size of each scavenger", "kind": "d", "trap": "decimal", "how": "stepped", "head": "shoe size", "lo": 5.0, "hi": 12.0, "step": 0.5, "dp": 1, "trim": true, "a": "size 7", "b": "size 7.5", "unit": "half a size"},
	{"what": "the price of each water jar, in dollars and cents", "kind": "d", "trap": "decimal", "how": "stepped", "head": "price ($)", "lo": 1.0, "hi": 5.0, "step": 0.05, "dp": 2, "a": "$2.40", "b": "$2.41", "unit": "one cent"},
	{"what": "the score each judge gives a bike stunt, in half points", "kind": "d", "trap": "decimal", "how": "stepped", "head": "score", "lo": 4.0, "hi": 10.0, "step": 0.5, "dp": 1, "trim": true, "a": "a score of 8", "b": "a score of 8.5", "unit": "half a point"},
	{"what": "the cost of each fuel can, in dollars and cents", "kind": "d", "trap": "decimal", "how": "stepped", "head": "cost ($)", "lo": 3.0, "hi": 9.0, "step": 0.05, "dp": 2, "a": "$6.15", "b": "$6.16", "unit": "one cent"},
	{"what": "the mass of each sack of grain", "kind": "c", "trap": "", "how": "measured", "head": "mass (kg)", "lo": 20.0, "hi": 30.0, "step": 0.1, "dp": 1, "a": "24.3 kg", "b": "24.4 kg"},
	{"what": "the time each runner takes to cross the dunes", "kind": "c", "trap": "", "how": "measured", "head": "time (min)", "lo": 40.0, "hi": 60.0, "step": 0.1, "dp": 1, "a": "47.2 minutes", "b": "47.3 minutes"},
	{"what": "the length of each salvaged pipe", "kind": "c", "trap": "", "how": "measured", "head": "length (m)", "lo": 1.0, "hi": 4.0, "step": 0.01, "dp": 2, "a": "2.35 m", "b": "2.36 m"},
	{"what": "the volume of water in each barrel", "kind": "c", "trap": "", "how": "measured", "head": "volume (litres)", "lo": 60.0, "hi": 120.0, "step": 0.5, "dp": 1, "a": "88.5 litres", "b": "89 litres"},
	{"what": "the temperature in the camp at noon each day", "kind": "c", "trap": "", "how": "measured", "head": "temperature (°C)", "lo": 28.0, "hi": 44.0, "step": 0.1, "dp": 1, "a": "35.6°C", "b": "35.7°C"},
	{"what": "the distance each courier rides in a day", "kind": "c", "trap": "", "how": "measured", "head": "distance (km)", "lo": 30.0, "hi": 90.0, "step": 0.1, "dp": 1, "a": "61.4 km", "b": "61.5 km"},
	{"what": "the height of each settler, to the nearest cm", "kind": "c", "trap": "rounded", "how": "measured", "head": "height (cm)", "lo": 148.0, "hi": 192.0, "step": 1.0, "dp": 0, "a": "171 cm", "b": "172 cm"},
	{"what": "the mass of each goat, to the nearest kg", "kind": "c", "trap": "rounded", "how": "measured", "head": "mass (kg)", "lo": 20.0, "hi": 60.0, "step": 1.0, "dp": 0, "a": "38 kg", "b": "39 kg"},
	{"what": "the time each repair takes, to the nearest minute", "kind": "c", "trap": "rounded", "how": "measured", "head": "time (min)", "lo": 10.0, "hi": 90.0, "step": 1.0, "dp": 0, "a": "42 minutes", "b": "43 minutes"},
	{"what": "the temperature at the pump each morning, to the nearest degree", "kind": "c", "trap": "rounded", "how": "measured", "head": "temperature (°C)", "lo": 12.0, "hi": 30.0, "step": 1.0, "dp": 0, "a": "21°C", "b": "22°C"},
]

## The claims a question picks from.
const DISCRETE := "Discrete: it is counted, so it takes separate values with gaps between them."
const STEPS := "Discrete: it goes up in fixed steps, with no values in between."
const CONTINUOUS := "Continuous: it is measured, so it can take any value in a range."
const STILL_CONTINUOUS := "Continuous: it is measured, so it can take any value in a range; rounding only changes how it is written."
const HAS_DECIMALS := "Continuous: its values have decimals."
const WHOLE_VALUES := "Discrete: its values are whole numbers."
const MEAN_DECIMAL := "Continuous: an average of it can be a decimal."
const FEW_VALUES := "Discrete: only a few separate values were recorded."
const MEASURED_WHOLE := "Discrete: it is measured, so it can only take whole values."
const COUNTED_ANY := "Continuous: it is counted, so it can take any value."


func needs() -> Dictionary:
	var out := {}
	for u in UNKNOWNS:
		out[u] = {"ask": u}
	return out


func extra() -> Dictionary:
	var out := {}
	for u in UNKNOWNS:
		out[u] = ["true-false-reason"]
	return out


func papers(unknown: String, _rep: String, _angle: String) -> Array:
	return [1, 2] if has(unknown) else []


func build(unknown: String, rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var out := super.build(unknown, rep, s, rng)
	out.given = VariableKindSituation.export(s)
	return out


static func v(s: Dictionary) -> Dictionary:
	return VARS[s.v]


## A phrase in the middle of a sentence: one with a comma of its own is closed with another.
static func mid(t: String) -> String:
	return t + "," if t.contains(",") else t


static func cap(t: String) -> String:
	return t[0].to_upper() + t.substr(1)


## "A study records the mass of each sack of grain.", with a table of values where asked.
static func shown(rep: String, s: Dictionary) -> Dictionary:
	var e := v(s)
	if rep == "table":
		return {"lines": ["A study records %s. Some of its values are in the table." % e.what], "table": {"rows": [[e.head, s.vals]]}}
	return {"lines": ["A study records %s." % e.what], "table": null}


## The working of each method for one variable, ending with `last`.
static func kind_steps(e: Dictionary, method: String, last: String) -> Array:
	if method == "counted-or-measured":
		match e.how:
			"counted":
				return ["Ask how each value is found: by counting, or by measuring.", "Each value is found by counting.", last]
			"stepped":
				return ["Ask how each value is found: by counting, or by measuring.",
					"Each value is not measured on a scale: it goes up in steps of %s, like a count." % e.unit, last]
		return ["Ask how each value is found: by counting, or by measuring.", "Each value is found by measuring.", last]
	var between: String
	match e.how:
		"counted":
			between = "No value can come between %s and %s." % [e.a, e.b]
		"stepped":
			between = "No value can come between %s and %s: the steps are %s." % [e.a, e.b, e.unit]
		_:
			between = "A value between %s and %s can occur, however close they are." % [e.a, e.b]
	return ["Take two values it could have that are next to each other: %s and %s." % [e.a, e.b], between, last]


func _claim(rep: String, s: Dictionary, right: String, wrongs: Array) -> Dictionary:
	var built := SamplingViews.claims(right, wrongs)
	var out := shown(rep, s)
	out.merge({"asked": "Is this variable discrete or continuous?", "answer": built.answer, "wrongs": built.wrongs, "fillers": built.fillers,
		"methods": {}})
	for m in ["counted-or-measured", "in-between-test"]:
		out.methods[m] = method(kind_steps(v(s), m, right), built.answer.values)
	return out


func u_classify_variable(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	if v(s).kind == "d":
		return _claim(rep, s, DISCRETE, [[MEAN_DECIMAL, R_MEAN], [CONTINUOUS, ""], [MEASURED_WHOLE, ""]])
	return _claim(rep, s, CONTINUOUS, [[FEW_VALUES, R_FEW], [DISCRETE, ""], [COUNTED_ANY, ""]])


func u_decimal_but_discrete(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	return _claim(rep, s, STEPS, [[HAS_DECIMALS, R_DECIMAL], [CONTINUOUS, ""], [WHOLE_VALUES, ""]])


func u_rounded_but_continuous(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	return _claim(rep, s, STILL_CONTINUOUS, [[WHOLE_VALUES, R_ROUNDED], [STEPS, ""], [HAS_DECIMALS, ""]])


## One variable of the asked kind among four: the trap is tagged, the other two are fillers.
func _which(s: Dictionary, kind: String, ref: String, rng: Seeded) -> Dictionary:
	var names: Array = s.four.map(func(i): return cap(VARS[i].what) + ".")
	var built := SamplingViews.claims(names[0], [[names[1], ref], [names[2], ""], [names[3], ""]])
	var word := "continuous" if kind == "c" else "discrete"
	var lines: Array = ["A study records four variables:"]
	for i in rng.shuffled(range(4)):
		lines.append(cap(VARS[s.four[i]].what) + ".")
	var e := v(s)
	var counted := func(m: String) -> Array:
		if m == "counted-or-measured":
			var rest := "the other three are counts or go up in fixed steps" if kind == "c" else "the other three are measured, even where they are rounded"
			var only := "is found by measuring" if kind == "c" else ("goes up in fixed steps, like a count" if e.how == "stepped" else "is found by counting")
			return ["Ask how each value is found: by counting, or by measuring.", "Only %s %s; %s." % [mid(e.what), only, rest], "So the %s one is: %s" % [word, names[0]]]
		var gap := "a value between %s and %s can occur" % [e.a, e.b] if kind == "c" else "no value can come between %s and %s" % [e.a, e.b]
		return ["For each, take two neighbouring values and ask whether a value between them can occur.",
			"For %s, %s." % [e.what, gap], "The other three go the other way, so the %s one is: %s" % [word, names[0]]]
	return {"lines": lines, "asked": "Which of these variables is %s?" % word, "answer": built.answer, "wrongs": built.wrongs, "fillers": built.fillers,
		"methods": {"counted-or-measured": method(counted.call("counted-or-measured"), built.answer.values),
			"in-between-test": method(counted.call("in-between-test"), built.answer.values)}}


func u_which_continuous(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	return _which(s, "c", R_DECIMAL, rng)


func u_which_discrete(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	return _which(s, "d", R_ROUNDED, rng)
