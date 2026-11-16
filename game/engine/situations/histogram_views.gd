class_name HistogramViews
extends ExtensionViews
## The views on the `histogram` situation: one builder per unknown of t4-ext-frequency-histogram
## (FAL-778). A count or a height is a whole number marked exactly; the class a boundary value goes
## in is a picked `claim`; which histogram shows a table is pick the graph. Wrong options are
## SL4.2.frequency-histogram's two misconceptions (a boundary value put in the class that ends
## there, gaps between the bars) and the type's own four.
##
## Representations: "table" (classes a ≤ x < b with their frequencies, one row each) and "graph"
## (the histogram: GraphView with each bar a shaded strip and its outline, the class boundaries
## marked on the across axis and the frequency up the side).

const SK := "SL4.2.frequency-histogram#"
const R_BOUNDARY := SK + "0"
const R_GAPS := SK + "1"
const R_DENSITY := "t4-ext-frequency-histogram#2"
const R_RUNNING := "t4-ext-frequency-histogram#3"
const R_ADDED := "t4-ext-frequency-histogram#4"
const R_BARS := "t4-ext-frequency-histogram#5"
const UNKNOWNS := ["missing-frequency", "bar-height", "count-in-range", "count-at-least", "class-of-value", "total-frequency", "pick-histogram"]
const H := preload("res://engine/situations/histogram.gd")

## What is measured, of whom, its letter and unit, and the class widths that suit it.
const STORIES := [
	{"what": "the time each driver takes to change a wheel", "who": "drivers", "x": "t", "unit": "minutes", "w": [5, 10]},
	{"what": "the mass of each salvaged battery", "who": "batteries", "x": "m", "unit": "kg", "w": [5, 10]},
	{"what": "the length of each salvaged pipe", "who": "pipes", "x": "l", "unit": "cm", "w": [10, 20]},
	{"what": "the distance each courier rides in a day", "who": "couriers", "x": "d", "unit": "km", "w": [10, 20]},
	{"what": "the time each runner takes to cross the dunes", "who": "runners", "x": "t", "unit": "minutes", "w": [10, 20]},
]


func needs() -> Dictionary:
	var out := {}
	for u in UNKNOWNS:
		out[u] = {"ask": u}
	return out


func papers(unknown: String, _rep: String, _angle: String) -> Array:
	return [1, 2] if has(unknown) else []


func build(unknown: String, rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var out := super.build(unknown, rep, s, rng)
	out.given = H.export(s)
	return out


static func st(s: Dictionary) -> Dictionary:
	return STORIES[s.story]


## Class c as the table writes it: "10 ≤ t < 20".
static func cls(s: Dictionary, c: int) -> String:
	return "%d ≤ %s < %d" % [c * s.w, st(s).x, (c + 1) * s.w]


## The frequency table, one row per class, with "?" for a hidden class and the total if asked.
static func table(s: Dictionary, hide: int = -1, with_total: bool = false) -> Dictionary:
	var rows: Array = [["%s (%s)" % [st(s).x, st(s).unit], ["frequency"]]]
	for c in s.k:
		rows.append([cls(s, c), ["?" if c == hide else str(s.f[c])]])
	if with_total:
		rows.append(["Total", [str(s.T)]])
	return {"rows": rows}


## The histogram: one shaded bar per class with its outline, touching unless `gaps`, from the
## heights `f` (the situation's own unless given), with bar `hide` left out.
static func figure(s: Dictionary, f: Array = [], hide: int = -1, gaps: bool = false, card: bool = false) -> Dictionary:
	if f.is_empty():
		f = s.f
	var w: float = s.w
	var top: int = int(f.max()) + 3
	top += top % 2
	var curves: Array = []
	var shade: Array = []
	for c in s.k:
		if c == hide:
			continue
		var l: float = c * w + (0.15 * w if gaps else 0.0)
		var r: float = (c + 1) * w - (0.15 * w if gaps else 0.0)
		var h := float(f[c])
		curves.append([[l, 0.0], [l, h], [r, h], [r, 0.0]])
		shade.append([[l, 0.0, h], [r, 0.0, h]])
	var g := Plot.spec(curves, [], 0, s.k * s.w, 0, top)
	g.shade = shade
	g.x_ticks = range(s.k + 1).map(func(c): return [float(c * s.w), str(c * s.w)])
	g.x_name = st(s).x
	g.y_name = "f"
	g.one_colour = true
	if hide >= 0:
		g.points.append({"x": (hide + 0.5) * w, "y": 1.0, "label": "?", "name": true})
	if card:
		g.card = true
	return g


static func count(v: int) -> Dictionary:
	return {"v": Q.new(v)}


static func plus(xs: Array) -> String:
	return " + ".join(xs.map(func(x): return str(x)))


## The story and the data: the table, or the histogram.
static func shown(rep: String, s: Dictionary, hide: int = -1, with_total: bool = false) -> Dictionary:
	if rep == "graph":
		return {"lines": ["The histogram shows %s, for %d %s (%s in %s)." % [st(s).what, s.T, st(s).who, st(s).x, st(s).unit]] if hide < 0 or with_total else
			["The histogram shows %s (%s in %s)." % [st(s).what, st(s).x, st(s).unit]], "graph": figure(s, [], hide), "table": null}
	return {"lines": ["The table shows %s, for %d %s." % [st(s).what, s.T, st(s).who]] if hide < 0 or with_total else
		["The table shows %s." % st(s).what], "graph": null, "table": table(s, hide, with_total)}


func _pack(sh: Dictionary, asked: String, ans: Dictionary, wrongs: Array, fillers: Array, steps: Dictionary) -> Dictionary:
	var out := sh.duplicate()
	out.merge({"asked": asked, "answer": ans, "wrongs": wrongs, "fillers": fillers.filter(func(x): return x.v.to_float() > 0), "methods": {}})
	for m in steps:
		out.methods[m] = method(steps[m], ans.values)
	return out


## "So number = 19."
static func so(ans: Dictionary) -> String:
	return "So %s." % Answer.text(ans)


func u_missing_frequency(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var i: int = s.i
	var p: int = s.f[i]
	var known: Array = []
	for c in s.k:
		if c != i:
			known.append(s.f[c])
	var sum: int = s.T - p
	var ans := SamplingViews.count_ans("frequency = ", p)
	var sh := shown(rep, s, i, rep == "table")
	var asked := "Find the missing frequency."
	if rep == "graph":
		sh.lines.append("The bar for %s is missing, and %d %s are measured in all." % [cls(s, i), s.T, st(s).who])
		asked = "Find the frequency of the class %s." % cls(s, i)
	var first := "Reading the bars, the other classes have frequencies %s." % ", ".join(known.map(func(x): return str(x))) if rep == "graph" \
		else "The other frequencies add to %s = %d." % [plus(known), sum]
	var steps := {"total-minus-known": [first, "The frequencies add to %d in all." % s.T, "%d − %d = %d" % [s.T, sum, p], so(ans)]}
	if rep == "graph":
		steps["total-minus-known"] = [first, "They add to %s = %d, and all the frequencies add to %d." % [plus(known), sum, s.T], "%d − %d = %d" % [s.T, sum, p], so(ans)]
	return _pack(sh, asked, ans, [wrong(count(sum), R_ADDED)], [count(p + 1), count(p - 1), count(p + 2), count(s.T)], steps)


func u_bar_height(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var i: int = s.i
	var f: int = s.f[i]
	var ans := SamplingViews.count_ans("height = ", f)
	ans.show = "dec"
	var run := H.total(s, 0, i + 1)
	var steps := {"read-bars": ["The classes all have width %d, so each bar's height is its class's frequency." % s.w,
		"The class %s has frequency %d." % [cls(s, i), f], so(ans)]}
	return _pack(shown("table", s), "A histogram is drawn from this table. Find the height of the bar for %s." % cls(s, i), ans,
		[wrong({"v": Q.new(f, s.w)}, R_DENSITY), wrong(count(run), R_RUNNING)], [count(f + 1), count(f - 1), count(s.f[i - 1])], steps)


func u_count_in_range(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var a: int = s.i
	var b: int = s.j
	var v := H.total(s, a, b)
	var ans := SamplingViews.count_ans("number = ", v)
	var hs: Array = s.f.slice(a, b)
	var steps := {"read-bars": ["Each bar's height is its class's frequency.", "The bars from %d to %d have heights %s." % [a * s.w, b * s.w, ", ".join(hs.map(func(x): return str(x)))],
		"%s = %d" % [plus(hs), v], so(ans)]}
	return _pack(shown(rep, s), "Find how many %s have %d ≤ %s < %d." % [st(s).who, a * s.w, st(s).x, b * s.w], ans,
		[wrong(count(H.total(s, a - 1, b)), R_BOUNDARY)], [count(v - s.f[b - 1]), count(v + 1), count(v - 1), count(H.total(s, a, mini(b + 1, s.k)) + (0 if b < s.k else 2))], steps)


func u_count_at_least(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var j: int = s.j
	var v := H.total(s, j, s.k)
	var ans := SamplingViews.count_ans("number = ", v)
	var up: Array = s.f.slice(j)
	var below: Array = s.f.slice(0, j)
	var word := "bars" if rep == "graph" else "classes"
	var steps := {
		"read-bars": ["Values of at least %d are in the classes from %d up, since each class includes its lower boundary." % [j * s.w, j * s.w],
			"Those %s have %s %s." % [word, "heights" if rep == "graph" else "frequencies", ", ".join(up.map(func(x): return str(x)))], "%s = %d" % [plus(up), v], so(ans)],
		"total-minus-known": ["All the frequencies add to %d." % s.T, "The classes below %d add to %s = %d." % [j * s.w, plus(below), s.T - v], "%d − %d = %d" % [s.T, s.T - v, v], so(ans)],
	}
	if rep == "graph":
		steps["total-minus-known"][0] = "The bars' heights add to %s = %d in all." % [plus(s.f), s.T]
	return _pack(shown(rep, s), "Find how many %s have %s ≥ %d." % [st(s).who, st(s).x, j * s.w], ans,
		[wrong(count(H.total(s, j - 1, s.k)), R_BOUNDARY)], [count(v - s.f[j]), count(s.T - v), count(v + 1), count(v - 1)], steps)


func u_class_of_value(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var j: int = s.j
	var right := cls(s, j)
	var e := st(s)
	var other := cls(s, j + 1) if j + 1 < s.k else "It is left out, because it lies on a boundary."
	var built := SamplingViews.claims(right, [[cls(s, j - 1), R_BOUNDARY], [other, ""], ["It can go in either class.", ""]])
	var sh := shown("table", s)
	sh.lines.append("One more of the %s is measured: its value is exactly %d %s." % [e.who, j * s.w, e.unit])
	return {"lines": sh.lines, "table": sh.table, "graph": null, "asked": "Which class does it go in?", "answer": built.answer, "wrongs": built.wrongs,
		"fillers": built.fillers, "methods": {"any": method(["A class a ≤ %s < b includes its lower boundary a and leaves out its upper boundary b." % e.x,
			"So %d goes in the class that starts at %d: %s" % [j * s.w, j * s.w, right]], built.answer.values)}}


func u_total_frequency(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var ans := SamplingViews.count_ans("number = ", s.T)
	var steps := {"read-bars": ["Each bar's height is its class's frequency.", "The heights are %s." % ", ".join(s.f.map(func(x): return str(x))),
		"%s = %d" % [plus(s.f), s.T], so(ans)]}
	var sh := shown(rep, s)
	sh.lines = ["The histogram shows %s (%s in %s)." % [st(s).what, st(s).x, st(s).unit]]
	return _pack(sh, "Find how many %s the histogram shows." % st(s).who, ans,
		[wrong(count(s.k), R_BARS)], [count(s.T - s.f[0]), count(s.T + s.f[-1]), count(s.T + 1), count(s.f.max())], steps)


func u_pick_histogram(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var i: int = s.i
	var swapped: Array = s.f.duplicate()
	swapped[i] = s.f[i + 1]
	swapped[i + 1] = s.f[i]
	var taller: Array = s.f.duplicate()
	var t: int = (i + 1 + rng.int_in(0, s.k - 2)) % s.k
	taller[t] = s.f[t] + 2
	var wrongs := [
		{"graph": figure(s, [], -1, true, true), "mistake": "gaps", "ref": R_GAPS, "why": "it leaves gaps between the bars, as a bar chart does"},
		{"graph": figure(s, swapped, -1, false, true), "mistake": "swap", "ref": "", "why": "the bars for %s and %s are the wrong way round" % [cls(s, i), cls(s, i + 1)]},
		{"graph": figure(s, taller, -1, false, true), "mistake": "height", "ref": "", "why": "the bar for %s is %d high, not %d" % [cls(s, t), taller[t], s.f[t]]},
	]
	var pk := GdcKit.pick(figure(s, [], -1, false, true), wrongs, rng)
	var ans: Dictionary = pk.answer
	var sh := shown("table", s)
	return {"lines": sh.lines, "table": sh.table, "graph": null, "asked": "Which histogram shows the data in the table?", "answer": ans, "graphs": pk.graphs,
		"methods": {"read-bars": method(["With equal widths, each bar's height is its class's frequency, and the bars touch, with no gaps.",
			"From left to right the heights must be %s: %s." % [", ".join(s.f.map(func(x): return str(x))), Answer.text(ans)]], ans.values)}}
