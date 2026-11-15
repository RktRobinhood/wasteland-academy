class_name CorrelationViews
extends ExtensionViews
## The views on the `correlation` situation: one builder per unknown of t4-ext-describe-correlation
## (FAL-778). A description or a reason is a picked `claim`; the scatter a value of r belongs to is
## pick the graph. Wrong options are SL4.4.describe-correlation's three misconceptions (a negative
## r read as weak, correlation taken as cause, r near 0 read as no relationship) and the type's own
## (any positive r called strong).
##
## Representations: "graph" (a scatter diagram, GraphView's points with no curve) and "words" (the
## two variables in a story and r).

const SK := "SL4.4.describe-correlation#"
const R_NEGATIVE_WEAK := SK + "0"
const R_CAUSE := SK + "1"
const R_NO_RELATION := SK + "2"
const R_POSITIVE_STRONG := "t4-ext-describe-correlation#3"
const UNKNOWNS := ["describe-scatter", "describe-r", "causation", "no-linear", "match-r", "strongest-r"]
const S := preload("res://engine/situations/correlation.gd")

## The stories: what x and y are, for whom, and for a cause question, the sign and the third thing
## both follow.
const STORIES := [
	{"x": "the number of fans sold in a day", "y": "the number of heatstroke cases that day", "who": "days", "sign": 1, "third": "the heat of the day"},
	{"x": "the number of water barrels a camp has", "y": "the number of goats it keeps", "who": "camps", "sign": 1, "third": "the size of the camp"},
	{"x": "the number of guards at a market", "y": "the number of thefts reported there", "who": "markets", "sign": 1, "third": "how busy the market is"},
	{"x": "the number of dust masks sold in a week", "y": "the number of people out walking that week", "who": "weeks", "sign": -1, "third": "how bad the dust storms are"},
	{"x": "the number of radio towers in a settlement", "y": "the number of traders there", "who": "settlements", "sign": 1, "third": "the size of the settlement"},
	{"x": "the hours a scavenger trains each week", "y": "her score in the trials", "who": "scavengers", "sign": 1, "third": ""},
	{"x": "the age of a water pump in years", "y": "the litres it pumps an hour", "who": "pumps", "sign": -1, "third": ""},
	{"x": "the distance a convoy travels", "y": "the fuel left in its tanks", "who": "convoys", "sign": -1, "third": ""},
]
## The stories a cause question may use: those with a third thing.
const CAUSAL := [0, 1, 2, 3, 4]
const STRENGTH := {"strong": "Strong", "moderate": "Moderate", "weak": "Weak"}


func needs() -> Dictionary:
	var out := {}
	for u in UNKNOWNS:
		out[u] = {"ask": u}
	return out


func extra() -> Dictionary:
	return {"describe-scatter": ["true-false-reason"], "describe-r": ["true-false-reason"], "causation": ["true-false-reason"],
		"no-linear": ["true-false-reason"], "strongest-r": ["true-false-reason"]}


func papers(unknown: String, _rep: String, _angle: String) -> Array:
	return [1, 2] if has(unknown) else []


func build(unknown: String, rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var out := super.build(unknown, rep, s, rng)
	out.given = S.export(s)
	return out


static func st(s: Dictionary) -> Dictionary:
	return STORIES[s.story]


## r as the question writes it: "r = −0.91".
static func r_text(r: float) -> String:
	var v := snappedf(r, 0.01)
	return "r = %s%.2f" % ["−" if v < 0.0 else "", absf(v)]


static func describe(band: String, dir: int) -> String:
	if band in ["none", "curve"]:
		return "No linear correlation"
	return "%s %s correlation" % [STRENGTH[band], "positive" if dir > 0 else "negative"]


## The scatter of xs and ys, on a window from 0 that holds them.
static func scatter(xs: Array, ys: Array, card: bool = false) -> Dictionary:
	var pts: Array = []
	for i in xs.size():
		pts.append([xs[i], ys[i], ""])
	var g := Plot.spec([], pts, 0, 21, 0, 100)
	if card:
		g.card = true
	return g


static func intro(s: Dictionary) -> String:
	return "For %d %s, x is %s and y is %s." % [s.n, st(s).who, st(s).x, st(s).y]


## The other descriptions offered beside the right one: the other direction, another strength,
## and no correlation (or two strengths, when the right one is none).
static func others(band: String, dir: int) -> Array:
	if dir == 0:
		return [describe("strong", 1), describe("weak", -1), describe("moderate", 1)]
	var out: Array = [describe(band, -dir)]
	for b in ["strong", "moderate", "weak"]:
		if b != band and out.size() < 2:
			out.append(describe(b, dir))
	out.append(describe("none", 0))
	return out


## Direction and strength from the scatter, in two lines.
static func scatter_steps(band: String, dir: int) -> Array:
	if dir == 0:
		return ["The points show no upward or downward trend from left to right.", "So there is no straight-line pattern to describe."]
	var way := "rise" if dir > 0 else "fall"
	var how: String = {"strong": "close to a straight line", "moderate": "around a straight line, but spread out", "weak": "only loosely around a straight line"}[band]
	return ["Direction: the points %s from left to right, so the correlation is %s." % [way, "positive" if dir > 0 else "negative"],
		"Strength: they lie %s, so it is %s." % [how, band]]


## Direction and strength from r, in two lines.
static func r_steps(r: float, band: String) -> Array:
	var v := absf(snappedf(r, 0.01))
	var dir := "r > 0, so the correlation is positive." if r > 0.0 else "r < 0, so the correlation is negative."
	var size: String = {"strong": "close to 1, so it is strong", "moderate": "about halfway to 1, so it is moderate", "weak": "small, so it is weak", "none": "close to 0, so there is no linear correlation", "curve": "close to 0, so there is no linear correlation"}[band]
	if band in ["none", "curve"]:
		return ["The size of r gives the strength, whatever its sign.", "|r| = %.2f is %s." % [v, size]]
	return ["The sign of r gives the direction: %s" % dir, "The size gives the strength: |r| = %.2f is %s." % [v, size]]


func _claim(lines: Array, graph: Variant, asked: String, right: String, wrongs: Array, steps: Dictionary) -> Dictionary:
	var built := SamplingViews.claims(right, wrongs)
	var out := {"lines": lines, "graph": graph, "table": null, "asked": asked, "answer": built.answer, "wrongs": built.wrongs, "fillers": built.fillers, "methods": {}}
	for m in steps:
		out.methods[m] = method(steps[m] + [right], built.answer.values)
	return out


func u_describe_scatter(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var right := describe(s.band, s.dir)
	var wrongs: Array = []
	for o in others(s.band, s.dir):
		var weak_negative: bool = s.dir < 0 and s.band == "strong" and o == describe("weak", -1)
		wrongs.append([o, R_NEGATIVE_WEAK if weak_negative else ""])
	if s.dir < 0 and s.band == "strong":
		wrongs = [[describe("weak", -1), R_NEGATIVE_WEAK], [describe("strong", 1), ""], [describe("moderate", -1), ""], [describe("none", 0), ""]]
	return _claim(["The scatter diagram shows %s (x) and %s (y) for %d %s." % [st(s).x, st(s).y, s.n, st(s).who]], scatter(s.xs, s.ys),
		"Describe the correlation.", right, wrongs.slice(0, 3), {"read-scatter": scatter_steps(s.band, s.dir)})


func u_describe_r(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var right := describe(s.band, s.dir)
	var wrongs: Array
	if s.dir < 0 and s.band == "strong":
		wrongs = [[describe("weak", -1), R_NEGATIVE_WEAK], [describe("strong", 1), ""], [describe("none", 0), ""]]
	elif s.dir > 0 and s.band != "strong":
		wrongs = [[describe("strong", 1), R_POSITIVE_STRONG], [describe(s.band, -1), ""], [describe("none", 0), ""]]
	else:
		wrongs = others(s.band, s.dir).map(func(o): return [o, ""])
	return _claim([intro(s), "%s." % r_text(s.r)], null, "Describe the correlation.", right, wrongs, {"read-r": r_steps(s.r, s.band)})


func u_causation(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var e := st(s)
	var right := "No: correlation alone doesn't show cause; both could follow %s." % e.third
	var near := "1" if s.r > 0.0 else "−1"
	var wrongs := [["Yes: r is close to %s, so a change in x causes the change in y." % near, R_CAUSE],
		["Yes: the points lie close to a straight line, so x causes y.", R_CAUSE],
		["No: r would have to be exactly %s to show cause." % near, ""]]
	var lines := [intro(s), "%s." % r_text(s.r)]
	var graph: Variant = null
	if rep == "graph":
		lines = ["The scatter diagram shows %s (x) and %s (y) for %d %s, with %s." % [e.x, e.y, s.n, e.who, r_text(s.r)]]
		graph = scatter(s.xs, s.ys)
	var shows := "strong %s correlation" % ("positive" if s.r > 0.0 else "negative")
	return _claim(lines, graph, "Does this show that a change in x causes the change in y?", right, wrongs,
		{"read-r": ["%s shows %s." % [r_text(s.r), shows], "Correlation says the two change together, not that one makes the other change.",
			"Here both could follow %s." % e.third]})


func u_no_linear(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var e := st(s)
	var right := "There is no linear correlation, but the points follow a curve, so x and y are related."
	var wrongs := [["x and y are not related at all.", R_NO_RELATION],
		["There is strong negative correlation.", ""], ["r is close to 0, so the data must be wrong.", ""]]
	var shape := "rise and then fall" if s.ys[s.n / 2] > (s.ys[0] + s.ys[-1]) / 2.0 else "fall and then rise"
	return _claim(["The scatter diagram shows %s (x) and %s (y) for %d %s, with %s." % [e.x, e.y, s.n, e.who, r_text(s.r)]], scatter(s.xs, s.ys),
		"What can you say about x and y?", right, wrongs,
		{"read-scatter": ["The points %s: they follow a curve." % shape, "r measures only a straight-line pattern, so a curve like this gives r near 0."],
			"read-r": ["%s is close to 0, so there is no linear correlation." % r_text(s.r), "But the scatter shows the points on a curve, so x and y are related."]})


func u_match_r(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var e := st(s)
	var wrongs: Array = []
	for c in s.cards:
		var ref := R_NEGATIVE_WEAK if c[4] == "weak" and s.dir < 0 and s.band == "strong" else ""
		var why: String = {"sign": "its points %s, so its r has the other sign" % ("fall" if s.dir > 0 else "rise"), "weak": "its points are only loosely around a line, so its r is small",
			"none": "its points show no trend, so its r is near 0"}[c[4]]
		wrongs.append({"graph": scatter(c[2], c[3], true), "mistake": c[4], "ref": ref, "why": why})
	var pk := GdcKit.pick(scatter(s.xs, s.ys, true), wrongs, rng)
	var ans: Dictionary = pk.answer
	var steps := r_steps(s.r, s.band)
	var picture := "So the points %s from left to right, %s: %s." % ["rise" if s.dir > 0 else "fall",
		"close to a straight line" if s.band == "strong" else "around a straight line but spread out", Answer.text(ans)]
	return {"lines": [intro(s), "%s." % r_text(s.r)], "graph": null, "table": null, "asked": "Which scatter diagram shows these data?", "answer": ans, "graphs": pk.graphs,
		"methods": {"read-r": method(steps + [picture], ans.values),
			"read-scatter": method(["Look at each scatter's direction and how close its points are to a line.", picture], ans.values)}}


func u_strongest_r(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var rs: Array = s.rs
	var texts: Array = rs.map(func(r): return r_text(r))
	var tagged := R_NEGATIVE_WEAK if rs[0] < 0.0 and rs[1] > 0.0 else ""
	var lines := ["Four sets of data give these values of r:"]
	for i in rng.shuffled(range(4)):
		lines.append("%s." % texts[i])
	return _claim(lines, null, "Which value of r shows the strongest correlation?", texts[0], [[texts[1], tagged], [texts[2], ""], [texts[3], ""]],
		{"read-r": ["The strength is the size of r, whatever its sign.", "The sizes are %s." % ", ".join(rs.map(func(r): return "%.2f" % absf(r))),
			"The largest size is %.2f." % absf(rs[0])]})
