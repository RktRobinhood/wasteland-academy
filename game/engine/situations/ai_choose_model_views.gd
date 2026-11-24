class_name AiChooseModelViews
extends ExtensionViews
## The views on the `ai-choose-model` situation (FAL-1001): one builder per unknown of
## fn-ai-choose-model (AI-SL2.6.choose-model and reasonable-domain). The family a table fits, from
## its differences and ratios; the family a scatter fits, from its shape (one scatter and four
## families, or pick which of four scatters suits a family); the family a story suits, from its
## features; why a proposed family does not suit a story (in words, or with its data drawn); and
## a sensible domain: a flight or a draining tank to the model's zero, a card's or a pen's lengths
## with both ends left out, and a count as whole numbers.
##
## Every question is Paper 2, as every AI paper allows a GDC. A family or a reason is a picked
## `claim`, and so is a domain whose wrong options are not intervals (every real t, whole numbers);
## the domain from a shape's lengths is a typed interval (range2), exact. `given` holds the
## situation as plain data.

const CM := "AI-SL2.6.choose-model#"
const RD := "AI-SL2.6.reasonable-domain#"
const R_EXP_FOR_LINEAR := CM + "0"
const R_EXP_FOR_QUAD := CM + "1"
const R_ONLY_FITS := CM + "2"
const R_ALL_REAL := RD + "0"
const R_WHOLE_SIDE := RD + "1"
const R_CONTINUOUS := RD + "2"
const R_LINEAR_CURVE := "fn-ai-choose-model#6"
const R_PEAK := "fn-ai-choose-model#7"
const R_END_IN := "fn-ai-choose-model#8"
const S := preload("res://engine/situations/ai_choose_model.gd")

const WHO := ["Juno", "Ash", "Vex", "Mara", "Rook", "Tess"]
const UNKNOWNS := ["family-from-table", "family-from-graph", "family-from-context", "reason-against", "domain-from-zero",
	"domain-from-dimensions", "domain-whole-numbers"]
const NAME := {"linear": "Linear", "quadratic": "Quadratic", "exponential": "Exponential", "sinusoidal": "Sinusoidal"}

## What a scatter's points do, by shape (growth and decay are both exponential).
const SHAPE := {"linear": "lie close to a straight line", "quadratic": "rise to a single peak and then fall",
	"growth": "rise ever more steeply", "decay": "fall ever more slowly, levelling off",
	"sinusoidal": "rise and fall in a repeating cycle"}
## The same, after "would".
const SKETCH := {"linear": "be a straight line", "quadratic": "rise to a single peak and then fall",
	"growth": "rise ever more steeply", "decay": "fall ever more slowly, levelling off",
	"sinusoidal": "rise and fall in a repeating cycle"}
## A proposed family, in a story and as a graph.
const PROP_STORY := {"linear": "changes by the same amount in each equal step of time: it rises or falls at a steady rate and never turns",
	"quadratic": "turns exactly once: it rises to a single highest point and falls, or falls to a single lowest point and rises",
	"exponential": "changes by the same percentage in each equal step of time: it only rises or only falls, and never turns"}
const PROP_GRAPH := {"linear": "is a straight line: it never turns and keeps the same steepness",
	"quadratic": "is a parabola, which turns exactly once", "exponential": "only rises or only falls, and never turns"}


## A claim's question can also be asked as a student's answer to judge (true-false-reason); the
## scatter question is not, as its pick-the-graph view has no claims to quote.
func extra() -> Dictionary:
	var out := {}
	for u in UNKNOWNS:
		if u != "family-from-graph":
			out[u] = ["true-false-reason"]
	return out


func needs() -> Dictionary:
	var out := {}
	for u in UNKNOWNS:
		out[u] = {"ask": u}
	return out


## Every AI paper allows a GDC: every cell is Paper 2.
func papers(unknown: String, _rep: String, _angle: String) -> Array:
	return [2] if has(unknown) else []


func build(unknown: String, rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var out := super.build(unknown, rep, s, rng)
	out.given = S.export(s)
	return out


# ── Writing things ───────────────────────────────────────────

static func D(v: Variant) -> String:
	return Fmt.dec(v)


## A GDC's screen: 6 significant figures.
static func W(x: float) -> String:
	return Fmt.work(x, 6)


static func say(text: String) -> String:
	return "So: " + text


## "a linear", "an exponential".
static func an(fam: String) -> String:
	return ("an " if fam == "exponential" else "a ") + fam


static func cap(t: String) -> String:
	return t.left(1).to_upper() + t.substr(1)


static func pack(lines: Array, asked: String, built: Dictionary, steps: Dictionary, graph: Variant = null, table: Variant = null) -> Dictionary:
	var out := {"lines": lines, "asked": asked, "answer": built.answer, "wrongs": built.wrongs, "fillers": built.fillers,
		"methods": {}, "graph": graph, "table": table}
	for m in steps:
		out.methods[m] = method(steps[m], built.answer.values)
	return out


## A claim and its other options: tagged slips first, then fillers (ref ""), in the order given.
static func claims(right: String, slips: Array, fillers: Array) -> Dictionary:
	var others: Array = slips.duplicate()
	for f in fillers:
		others.append([f, ""])
	return SamplingViews.claims(right, others)


## A scatter on a window from 0 that holds it, with the axes named.
static func scatter_graph(pts: Array, x_name: String = "x", y_name: String = "y", card: bool = false) -> Dictionary:
	var xmax := 0.0
	var ymax := 0.0
	for p in pts:
		xmax = maxf(xmax, p[0])
		ymax = maxf(ymax, p[1])
	var top := ceili(ymax * 1.1 / 10.0) * 10
	var g := Plot.spec([], pts.map(func(p): return [p[0], p[1], ""]), 0, ceili(xmax + xmax / 12.0), 0, top)
	g.x_name = x_name
	g.y_name = y_name
	if card:
		g.card = true
	return g


# ── The family a table fits ──────────────────────────────────

static func listed(qs: Array) -> String:
	return ", ".join(qs.map(func(q): return D(q)))


func u_family_from_table(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var ys: Array = s.ys
	var ds := S.diffs(ys)
	var d2 := S.diffs(ds)
	var ratios: Array = []
	for i in ys.size() - 1:
		ratios.append(ys[i + 1].div(ys[i]))
	var x_letter: String = s.names[0].split(" ")[0]
	var y_letter: String = s.names[1]
	var table := {"rows": [[s.names[0], s.xs.map(func(x): return D(x))], [y_letter, ys.map(func(y): return D(y))]]}
	var lines: Array = ["The table shows values of %s at equally spaced values of %s." % [y_letter, x_letter]]
	var fd := "First differences: " + listed(ds)
	var sd := "Second differences: " + listed(d2)
	var rt := "Ratios of consecutive values: "
	if s.fam == "exponential":
		rt += listed(ratios)
	else:
		rt = "Ratios of consecutive values (to 3 s.f.): " + ", ".join(ratios.map(func(r): return Fmt.sf(r)))
	var right: String
	var slips: Array = []
	var pool: Array
	var steps: Array
	match s.fam:
		"linear":
			right = "Linear: the first differences are all %s." % D(s.d)
			slips = [["Exponential: the values increase.", R_EXP_FOR_LINEAR]]
			pool = ["Quadratic: the values rise to a single highest value and then fall.", "Sinusoidal: the values rise and fall in a repeating cycle.",
				"Exponential: the ratios of consecutive values are constant."]
			steps = [fd + ": all the same, %s." % D(s.d), "Each equal step in %s adds the same amount, the mark of a linear model." % x_letter, say(right)]
		"quadratic":
			right = "Quadratic: the second differences are all %s." % D(s.a2)
			slips = [["Exponential: the second differences are all %s." % D(s.a2), R_EXP_FOR_QUAD]]
			pool = ["Linear: the first differences are constant.", "Sinusoidal: the values rise and fall in a repeating cycle.",
				"Exponential: the ratios of consecutive values are constant."]
			steps = [fd + ": not constant, so not linear.", sd + ": all the same, %s." % D(s.a2), rt + ": not constant, so not exponential.", say(right)]
		_:
			right = "Exponential: each value is %s times the one before." % D(s.r)
			pool = ["Linear: the first differences are constant.", "Quadratic: the second differences are constant.",
				"Sinusoidal: the values rise and fall in a repeating cycle."]
			steps = [fd + ": not constant, so not linear.", rt + ": all the same, %s." % D(s.r),
				"Each equal step in %s multiplies by the same factor, the mark of an exponential model." % x_letter, say(right)]
	var built := claims(right, slips, rng.shuffled(pool).slice(0, 3 - slips.size()))
	return pack(lines, "Which type of model fits these data? Give a reason.", built, {"differences-ratios": steps}, null, table)


# ── The family a scatter fits ────────────────────────────────

static func shape_claim(fam: String) -> String:
	return "%s: the points %s." % [NAME[fam], SHAPE["growth" if fam == "exponential" else fam]]


func u_family_from_graph(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var fams := ["linear", "quadratic", "exponential", "sinusoidal"]
	if s.mode == "pick":
		return _pick_scatter(s, rng)
	var right := shape_claim(s.fam)
	var slips: Array = []
	var pool: Array = []
	for f in fams:
		if f != s.fam:
			pool.append(shape_claim(f))
	if s.fam == "exponential":
		slips = [["Linear: the points rise.", R_LINEAR_CURVE]]
		pool = rng.shuffled(pool.filter(func(t): return not t.begins_with("Linear"))).slice(0, 2)
	else:
		pool = rng.shuffled(pool)
	var built := claims(right, slips, pool)
	var mark := {"linear": "a fixed change in y for each step in x, the shape of a linear model's straight line",
		"quadratic": "a single turning point, the shape of a quadratic model's parabola",
		"exponential": "growth by the same factor for each step in x, the shape of an exponential model's curve",
		"sinusoidal": "a cycle that repeats, the shape of a sinusoidal model's wave"}
	var steps := ["The points %s." % SHAPE["growth" if s.fam == "exponential" else s.fam],
		"That is %s." % mark[s.fam], say(right)]
	return pack(["The scatter shows measured values of y against x."], "Which type of model best fits these data? Give a reason.", built,
		{"shape-of-data": steps}, scatter_graph(s.pts))


func _pick_scatter(s: Dictionary, rng: Seeded) -> Dictionary:
	var right: Dictionary
	var wrongs: Array = []
	for c in s.cards:
		var g := scatter_graph(c.pts, "x", "y", true)
		if c.fam == s.target:
			right = g
			continue
		var shape: String = SHAPE["growth" if c.fam == "exponential" else c.fam]
		var ref := R_LINEAR_CURVE if s.target == "linear" and c.fam == "exponential" else ""
		var why := "its points %s, so %s model suits them" % [shape, an(c.fam)]
		if ref != "":
			why = "its points rise, but ever more steeply: they curve, so an exponential model suits them, not a straight line"
		wrongs.append({"graph": g, "mistake": c.fam, "ref": ref, "why": why})
	var pk := GdcKit.pick(right, wrongs, rng)
	var ans: Dictionary = pk.answer
	var target_shape: String = SHAPE["growth" if s.target == "exponential" else s.target]
	return {"asked": "Which graph shows data that %s model suits?" % an(s.target),
		"lines": ["Each graph shows a scatter of measured values of y against x."],
		"answer": ans, "graphs": pk.graphs,
		"methods": {"shape-of-data": method([
			"%s model's data %s." % [cap(an(s.target)), target_shape],
			"The points of %s %s; on the other graphs they don't." % [pk.letter, target_shape],
			"So %s." % Answer.text(ans)], ans.values)}}


# ── Stories ──────────────────────────────────────────────────

static func unit(st: Dictionary) -> String:
	return {"tank": "minute", "rover": "hour", "beetles": "week", "moss": "day", "isotope": "hour", "tide": "hour",
		"wheel": "minute", "flare": "second", "ball": "second"}[st.kind]


static func quantity(st: Dictionary) -> String:
	return {"tank": "volume of water in the tank", "rover": "rover's distance from its base", "beetles": "number of beetles",
		"moss": "area of the moss", "isotope": "mass of the isotope", "tide": "depth of the water", "wheel": "height of the seat",
		"flare": "height of the flare", "ball": "height of the ball"}[st.kind]


static func story_line(st: Dictionary) -> String:
	match st.kind:
		"tank":
			return "A pump fills a water tank. The tank holds %d litres at the start, and the pump adds %d litres every minute." % [st.a, st.r]
		"rover":
			return "A rover starts %d km from its base and drives straight away from it, covering %d km every hour." % [st.a, st.r]
		"beetles":
			return "A colony of %d glow-beetles grows by %d%% every week." % [st.a, st.p]
		"moss":
			return "Rad-moss covers %d m² of a bunker wall, and its area grows by %d%% every day." % [st.a, st.p]
		"isotope":
			return "A %d g sample of an isotope decays, losing %d%% of what is left every hour." % [st.a, st.p]
		"tide":
			return "The depth of water in a harbour rises and falls with the tide, from %d m at low tide to %d m at high tide and back, every %s hours." % [st.lo, st.hi, D(st.T)]
		"wheel":
			return "A seat on a Ferris wheel turns at a steady speed, rising from %d m above the ground to %d m and back down, once every %s minutes." % [st.lo, st.hi, D(st.T)]
	var what := "A flare is fired" if st.kind == "flare" else "A ball is kicked"
	return "%s straight up from the ground. It rises to a single highest point, about %s m up after %s seconds, then falls back to the ground." % [what, Fmt.sf(st.H), D(st.tp)]


## What the story says the quantity does: the feature that names the family.
static func feature(st: Dictionary) -> String:
	match st.kind:
		"tank":
			return "goes up by the same %d litres every minute" % st.r
		"rover":
			return "goes up by the same %d km every hour" % st.r
		"beetles", "moss":
			return "grows by the same %d%% every %s" % [st.p, unit(st)]
		"isotope":
			return "falls by %d%% of what is left every hour" % st.p
		"tide", "wheel":
			return "rises and falls between %d m and %d m, the cycle repeating every %s %ss" % [st.lo, st.hi, D(st.T), unit(st)]
	return "rises to a single highest point after %s seconds, then falls" % D(st.tp)


const FAMILY_MARK := {"linear": "a fixed change per unit of time is the mark of a linear model",
	"exponential": "a fixed percentage change per unit of time is the mark of an exponential model",
	"sinusoidal": "a cycle that repeats is the mark of a sinusoidal model",
	"quadratic": "a single turning point is the mark of a quadratic model"}


static func context_claim(fam: String, st: Dictionary) -> String:
	match fam:
		"linear":
			return "Linear: it changes by the same amount every %s." % unit(st)
		"exponential":
			return "Exponential: it changes by the same percentage every %s." % unit(st)
		"sinusoidal":
			return "Sinusoidal: it rises and falls in a cycle that repeats."
	return "Quadratic: it rises to a single highest point and then falls."


func u_family_from_context(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var st: Dictionary = s.story
	var right := context_claim(st.fam, st)
	var slips: Array = []
	var pool: Array = []
	for f in ["linear", "exponential", "sinusoidal", "quadratic"]:
		if f != st.fam:
			pool.append(context_claim(f, st))
	if st.fam == "linear":
		slips = [["Exponential: it increases.", R_EXP_FOR_LINEAR]]
		pool = rng.shuffled(pool.filter(func(t): return not t.begins_with("Exponential"))).slice(0, 2)
	else:
		pool = rng.shuffled(pool)
	var built := claims(right, slips, pool)
	var steps := ["The %s %s." % [quantity(st), feature(st)], cap(FAMILY_MARK[st.fam]) + ".", say(right)]
	return pack([story_line(st)], "Which type of model suits the %s? Give a reason." % quantity(st), built, {"context-features": steps})


# ── Why a family does not suit ───────────────────────────────

static func against(st: Dictionary, prop: String) -> String:
	var q := "The " + quantity(st)
	var u := unit(st)
	match [st.shape, prop]:
		["sinusoidal", "linear"]:
			return "%s rises and falls in a repeating cycle, but a linear model only rises or only falls." % q
		["sinusoidal", "quadratic"]:
			return "%s rises and falls again and again, but a quadratic model turns only once." % q
		["sinusoidal", "exponential"]:
			return "%s rises and falls in a repeating cycle, but an exponential model only rises or only falls." % q
		["quadratic", "linear"]:
			return "%s rises to a highest point and then falls, but a linear model never turns." % q
		["quadratic", "exponential"]:
			return "%s rises to a highest point and then falls, but an exponential model never turns." % q
		["growth", "linear"]:
			return "%s grows by the same percentage each %s, ever faster, but a linear model grows by the same amount each %s." % [q, u, u]
		["decay", "linear"]:
			return "%s falls ever more slowly and never reaches 0, but a linear model falls at a steady rate and goes below 0." % q
		["decay", "quadratic"]:
			return "%s keeps falling, ever more slowly, but a quadratic model turns and rises again." % q
		["linear", "exponential"]:
			return "%s changes by the same amount each %s, but an exponential model changes by the same percentage, ever faster." % [q, u]
	return "%s changes at a steady rate and never turns, but a quadratic model turns." % q


func u_reason_against(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var st: Dictionary = s.story
	var prop: String = s.prop
	var right := against(st, prop)
	var graph: Variant = null
	var lines: Array = [story_line(st)]
	var fits := "%s model does not fit the situation." % cap(an(prop))
	if rep == "graph":
		var letter: String = {"tank": "V", "rover": "d", "beetles": "N", "moss": "A", "isotope": "m", "tide": "d", "wheel": "h", "flare": "h", "ball": "h"}[st.kind]
		lines.append("The graph shows measurements of the %s, %s, against the time t in %ss." % [quantity(st), letter, unit(st)])
		graph = scatter_graph(s.pts, "t", letter)
		fits = "%s model does not fit the points." % cap(an(prop))
	var pool: Array = rng.shuffled(["%s model can't be used for values greater than 100." % cap(an(prop)),
		"%s model can only be used for whole-number inputs." % cap(an(prop)),
		"%s model can't start from a value above 0." % cap(an(prop))]).slice(0, 2)
	var built := claims(right, [[fits, R_ONLY_FITS]], pool)
	var asked := "%s proposes %s model for the %s. Explain why %s model is not suitable." % [WHO[s.ctx], an(prop), quantity(st), an(prop)]
	var looks := "The points %s." % SHAPE[st.shape] if rep == "graph" else "Sketch the %s against time: its graph would %s." % [quantity(st), SKETCH[st.shape]]
	return pack(lines, asked, built, {
		"context-features": ["The story: the %s %s." % [quantity(st), feature(st)], "%s model %s." % [cap(an(prop)), PROP_STORY[prop]], say(right)],
		"shape-of-data": [looks, "%s model's graph %s." % [cap(an(prop)), PROP_GRAPH[prop]], say(right)],
	}, graph)


# ── A domain that ends at a zero ─────────────────────────────

static func model_text(s: Dictionary) -> String:
	if s.kind == "flight":
		return "−4.9t² + %st + %s" % [D(s.v), D(s.h0)]
	return "%s − %st" % [D(s.V0), D(s.r)]


static func thing(s: Dictionary) -> String:
	return "flare" if s.tower else "ball"


func u_domain_from_zero(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var T: float = s.T
	var right := "0 ≤ t ≤ " + Fmt.sf(T)
	var lines: Array
	var slips: Array = []
	var pool: Array
	var data_end := "0 ≤ t ≤ " + D(s.td)
	var steps := {}
	var fn := model_text(s)
	if s.kind == "flight":
		var th := thing(s)
		var from := "from the top of a %s m tower" % D(s.h0) if s.tower else "from a height of %s m" % D(s.h0)
		var act := "fired" if s.tower else "thrown"
		if rep == "equation":
			lines = ["h(t) = " + fn, "h(t) is the height in metres of a %s t seconds after it is %s upwards %s, until it lands on the ground." % [th, act, from]]
		else:
			lines = ["A %s is %s upwards at %s m/s %s, and lands on the ground. Its height t seconds after it is %s is modelled by h = %s metres." % [th, act, D(s.v), from, act, fn]]
		if s.angle == "data-range":
			lines.append("The model was fitted to heights measured from t = 0 to t = %s." % D(s.td))
		slips = [["t can be any real number", R_ALL_REAL], ["0 ≤ t ≤ " + Fmt.sf(s.tp), R_PEAK]]
		pool = ["t ≥ 0", "%s ≤ t ≤ %s" % [Fmt.sf(s.neg), Fmt.sf(T)]]
		if s.angle == "data-range":
			pool.append(data_end)
		var hd: float = -4.9 * s.td.to_float() * s.td.to_float() + s.v.to_float() * s.td.to_float() + s.h0.to_float()
		steps["zeros-as-endpoints"] = ["Time starts when the %s is %s: t = 0." % [th, act],
			"On the GDC, the zeros of h(t) = %s are t = %s and t = %s." % [fn, W(s.neg), W(T)],
			"The negative zero is before the %s is %s; it lands at t = %s, where h = 0." % [th, act, W(T)], "So the domain is %s." % right]
		steps["physical-limits"] = ["t is the time since the %s was %s, so t ≥ 0." % [th, act],
			"The height can't be negative, so the model holds until the %s lands, where %s = 0." % [th, fn],
			"The formula: t = (%s + √(%s² + 4 × 4.9 × %s)) ÷ 9.8 = %s, the positive root." % [D(s.v), D(s.v), D(s.h0), W(T)],
			"So the domain is %s." % right]
		steps["data-range"] = ["The heights were measured from t = 0 to t = %s, so the data's range would end the domain at t = %s." % [D(s.td), D(s.td)],
			"But h(%s) = %s > 0: the %s is still in the air, so this method fails here; the flight goes on past the data until h = 0." % [D(s.td), W(hd), th],
			"The GDC's zero of h after t = 0 is t = %s." % W(T), "So the domain is %s." % right]
	else:
		if rep == "equation":
			lines = ["V(t) = " + fn, "V(t) is the volume in litres of fuel left in a tank t minutes after it starts to drain."]
		else:
			lines = ["A full tank holds %s litres of fuel. It drains at a steady %s litres per minute, so the volume left t minutes after it starts to drain is modelled by V = %s litres." % [D(s.V0), D(s.r), fn]]
		if s.angle == "data-range":
			lines.append("The model was fitted to readings taken from t = 0 to t = %s." % D(s.td))
		pool = ["t can be any real number", "t ≥ 0", "0 ≤ t ≤ " + D(s.V0)]
		if s.angle == "data-range":
			pool.append(data_end)
		var vd: Q = s.V0.sub(s.r.mul(s.td))
		steps["zeros-as-endpoints"] = ["Time starts when the tank starts to drain: t = 0.",
			"On the GDC, the zero of V(t) = %s is t = %s." % [fn, W(T)],
			"The tank is empty at t = %s, so the model ends there." % W(T), "So the domain is %s." % right]
		steps["physical-limits"] = ["t is the time since the tank started to drain, so t ≥ 0.",
			"The volume can't be negative: %s ≥ 0 gives t ≤ %s ÷ %s = %s." % [fn, D(s.V0), D(s.r), W(T)], "So the domain is %s." % right]
		steps["data-range"] = ["The readings were taken from t = 0 to t = %s, so the data's range would end the domain at t = %s." % [D(s.td), D(s.td)],
			"But V(%s) = %s > 0: fuel is still left, so this method fails here; the tank drains on past the data until V = 0." % [D(s.td), D(vd)],
			"%s = 0 gives t = %s ÷ %s = %s." % [fn, D(s.V0), D(s.r), W(T)], "So the domain is %s." % right]
	var asked := "Write down a suitable domain for %s." % ("h" if s.kind == "flight" else "V") if rep == "equation" else "State a suitable domain for the model."
	var built := claims(right, slips, rng.shuffled(pool).slice(0, 3 - slips.size()))
	return pack(lines, asked, built, steps)


# ── A domain from a shape's lengths ──────────────────────────

static func span(top: Q, closed: bool = false) -> Dictionary:
	var rel := "≤" if closed else "<"
	return {"lo": Q.new(0), "r1": rel, "r2": rel, "hi": top}


func u_domain_from_dimensions(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var top: Q = s.top
	var ans := Answer.make("range2", span(top), {"var": "x"})
	ans.exact = true
	ans.show = "dec"
	var wr: Array
	var fill: Array
	var lines: Array
	var graph: Variant = null
	var steps: Array
	var fig: bool = rep == "diagram"
	if s.kind == "card":
		var V := "Its volume is V = x(%d − 2x)(%d − 2x) cm³." % [s.a, s.b]
		if fig:
			lines = ["A square of side x cm is cut from each corner of the card in the diagram, and the sides are folded up to make an open box.", V]
			graph = OptimisationViews.new()._sheet_figure({"w": s.a, "h": s.b})
		else:
			lines = ["A square of side x cm is cut from each corner of %s %d cm by %d cm card, and the sides are folded up to make an open box." % ["an" if s.a in [11, 18] else "a", s.a, s.b], V]
		wr = [wrong(span(Q.new(s.a)), R_WHOLE_SIDE), wrong(span(top, true), R_END_IN)]
		fill = [span(Q.new(s.b, 2)), span(Q.new(s.b))]
		steps = ["x is the side of a square cut from each corner, so x > 0.",
			"The base is (%d − 2x) cm by (%d − 2x) cm, and both must be positive: %d − 2x > 0 gives x < %s, the shorter side's limit, as %d − 2x > 0 only needs x < %s." % [s.a, s.b, s.a, D(top), s.b, D(Q.new(s.b, 2))],
			"At x = 0 and at x = %s the box has no volume, so both ends are left out." % D(top)]
	else:
		var A := "Its area is A = x(%d − 2x) m²." % s.F
		if fig:
			lines = ["The rectangular pen in the diagram is fenced against a long wall with %d m of fence; the wall needs no fence." % s.F, A]
			graph = OptimisationViews.new()._fence_figure({"n": 2})
		else:
			lines = ["A rectangular pen is fenced against a long wall with %d m of fence. The two sides at right angles to the wall are x m each, the side along the wall is y m, and the wall needs no fence." % s.F, A]
		wr = [wrong(span(top, true), R_END_IN)]
		fill = [span(Q.new(s.F)), span(Q.new(s.F, 4))]
		steps = ["x is a length of fence, so x > 0.",
			"The side along the wall is y = %d − 2x m, which must be positive: x < %s." % [s.F, D(top)],
			"At x = 0 and at x = %s the pen has no area, so both ends are left out." % D(top)]
	steps.append("So the possible values are %s." % Answer.text(ans))
	return {"lines": lines, "asked": "Write down the possible values of x.", "answer": ans, "wrongs": wr, "fillers": fill,
		"methods": {"physical-limits": method(steps, ans.values)}, "graph": graph, "table": null}


# ── A count ──────────────────────────────────────────────────

func u_domain_whole_numbers(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var N: int = s.N
	var line: String
	var fn: String
	var counts: String
	var full: String
	match s.kind:
		"tickets":
			line = "A hall has %d seats. The profit from selling n tickets for a show is P(n) = %dn − %d dollars, where n can be anything from no tickets up to a full hall." % [N, s.m, s.c]
			fn = "P"
			counts = "tickets, so it is a whole number: there is no part of a ticket"
			full = "no tickets, n = 0, up to a full hall, n = %d" % N
		"crates":
			line = "A truck can carry at most %d crates. With n crates loaded, its total mass is M(n) = %d + %dn kg, where n can be anything from no crates up to a full load." % [N, s.c, s.m]
			fn = "M"
			counts = "crates, so it is a whole number: there is no part of a crate"
			full = "no crates, n = 0, up to a full load, n = %d" % N
		_:
			line = "A tray has room for %d seedlings. The cost of planting n seedlings in it is C(n) = %d + %dn dollars, where n can be anything from no seedlings up to a full tray." % [N, s.c, s.m]
			fn = "C"
			counts = "seedlings, so it is a whole number: there is no part of a seedling"
			full = "no seedlings, n = 0, up to a full tray, n = %d" % N
	var right := "n = 0, 1, 2, …, %d" % N
	var pool: Array = rng.shuffled(["n = 0, 1, 2, 3, …", "n = 1, 2, 3, …, %d" % N, "n ≥ 0"]).slice(0, 2)
	var built := claims(right, [["0 ≤ n ≤ %d" % N, R_CONTINUOUS]], pool)
	return pack([line], "Write down the domain of %s." % fn, built, {"physical-limits": [
		"n counts %s." % counts, "It runs from %s." % full, "So the domain is %s." % right]})
