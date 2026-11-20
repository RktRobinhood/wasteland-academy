class_name AiQuadraticModelViews
extends ExtensionViews
## The views on the `ai-quadratic-model` situation (FAL-1001): one builder per unknown of
## fn-ai-quadratic-model (AI-SL2.5.quadratic-model). A flight h(t) = at² + bt + c in metres and
## seconds: the start, the greatest height and when it happens, the landing time and the later
## time at a level. An arch y = ax² + bx + c over a canal or a road: its axis of symmetry and its
## width at a height. A path y = ax² + bx + c against horizontal distance: whether it clears an
## obstacle. A pen from a fixed length of fence: its area as a quadratic.
##
## Representations: "equation" (the model first, then a line on what it means), "words" (the
## story first, the model in it), "graph" (the model and its curve, axes named in context, a
## level drawn where one is asked) and "diagram" (the pen from above, its sides labelled).
##
## Every question is Paper 2, as every AI paper allows a GDC. A value that ends within 3 s.f. is
## exact, any other is to 3 s.f. with the rounding trap. A verdict is a picked `claim`.
## `given` holds the situation as plain data.

const SK := "AI-SL2.5.quadratic-model#"
const OWN := "fn-ai-quadratic-model#"
const R_TIME_FOR_TOP := SK + "0"
const R_NEGATIVE_ROOT := SK + "1"
const R_NO_MINUS := SK + "2"
const R_START_AS_TOP := SK + "3"
const R_TOP_FOR_TIME := OWN + "4"
const R_EARLIER := OWN + "5"
const R_HALF_WIDTH := OWN + "6"
const R_PEAK_OBSTACLE := OWN + "7"
const R_WRONG_SIDES := OWN + "8"
const R_TOP_FOR_START := OWN + "9"
const S := preload("res://engine/situations/ai_quadratic_model.gd")

const UNKNOWNS := ["initial-height", "vertex-value", "time-of-vertex", "axis-of-symmetry", "landing-time",
	"time-at-height", "clears-obstacle", "width-above-height", "build-area-model"]

## Flights launched above the ground: the story, the thing, what h is measured from, "after …",
## the start asked in words, and what the start is.
const FLIGHT := [
	{"line": "A lookout fires a flare upwards from the top of a watchtower.", "obj": "flare", "ground": "the ground",
		"after": "it is fired", "start": "How high is the top of the watchtower above the ground?", "base": "the top of the watchtower"},
	{"line": "A scavenger throws a rock upwards from the roof of a ruined mall.", "obj": "rock", "ground": "the car park",
		"after": "it is thrown", "start": "How high is the roof of the mall above the car park?", "base": "the roof of the mall"},
	{"line": "A signal rocket is launched from a cliff top over a dry lake bed.", "obj": "rocket", "ground": "the lake bed",
		"after": "it is launched", "start": "How high is the cliff top above the lake bed?", "base": "the cliff top"},
	{"line": "A raider lobs a smoke canister upwards from a bridge over a dry riverbed.", "obj": "canister", "ground": "the riverbed",
		"after": "it is lobbed", "start": "How high is the bridge above the riverbed?", "base": "the bridge"},
]
## Flights from the ground (c = 0).
const GROUND := [
	{"line": "A launcher on the ground fires a water bomb straight up.", "obj": "water bomb", "ground": "the ground", "after": "it is fired"},
	{"line": "A mutant frog leaps straight up from the ground.", "obj": "frog", "ground": "the ground", "after": "it leaps"},
]
## Arches: what it is, what y is measured from, and the post x is measured from (form 2).
const ARCH := [
	{"what": "the arch of a footbridge over a canal", "ground": "the water", "post": "a mooring post on the bank"},
	{"what": "the entrance of a tunnel through a slag heap", "ground": "the road", "post": "a marker post"},
	{"what": "a rusted steel arch over the old highway", "ground": "the road", "post": "a signpost"},
]
## Paths over an obstacle: the story, the thing, where x is measured from, the obstacle.
const PATH := [
	{"line": "A scout throws a supply pack towards a camp wall.", "obj": "pack", "from": "the scout", "obstacle": "wall"},
	{"line": "A guard aims a jet of water from a hose at a fence.", "obj": "water", "from": "the nozzle", "obstacle": "fence"},
	{"line": "A kid kicks a ball towards a wall at the edge of the yard.", "obj": "ball", "from": "where it is kicked", "obstacle": "wall"},
]
## Pens: who, the pen, what makes its fourth side (against a wall), that side's label.
const PEN := [
	["A farmer", "goat pen", "the wall of a ruined barn", "wall"],
	["A settler", "vegetable plot", "a straight river bank", "river"],
	["A trader", "dog run", "the side of a shipping container", "container"],
]


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
static func W(x: Variant) -> String:
	return Fmt.work(x.to_float() if x is Q else x, 6)


## A coefficient in a substitution, bracketed when negative: "(−4.9)".
static func B(v: Q) -> String:
	return "(%s)" % D(v) if v.sign() < 0 else D(v)


static func say(ans: Dictionary) -> String:
	return "So " + Answer.text(ans) + "."


## A value's answer: exact when it ends within 3 s.f., else to 3 s.f. (with the rounding trap).
static func num_ans(label: String, v: Q, unit: String = "") -> Dictionary:
	var ans := Answer.make("number", {"v": v}, {}, label, unit)
	if Answer.needs_rounding(v):
		ans.show = "sf"
	else:
		ans.show = "dec"
		ans.exact = true
	return ans


## A value as an option beside `ans`: to 3 s.f. beside an exact answer when it doesn't end.
static func opt(ans: Dictionary, v: Q) -> Dictionary:
	return {"v": v if ans.show == "sf" else S.short(v)}


static func model(s: Dictionary, letter: String) -> String:
	return Fmt.terms([s.a, s.b, s.c], [2, 1, 0], letter, true)


static func cap(t: String) -> String:
	return t.left(1).to_upper() + t.substr(1)


# ── Flights ──────────────────────────────────────────────────

static func story(s: Dictionary) -> Dictionary:
	return GROUND[s.ctx] if s.ground else FLIGHT[s.ctx]


static func model_sentence(s: Dictionary) -> String:
	var c := story(s)
	return "Its height above %s, h metres, t seconds after %s, is modelled by h(t) = %s." % [c.ground, c.after, model(s, "t")]


## The lines before a flight question, in the representation.
static func flight_lines(s: Dictionary, rep: String) -> Array:
	var c := story(s)
	match rep:
		"equation":
			return ["h(t) = " + model(s, "t"), "h(t) is the height above %s, in metres, of a %s t seconds after %s." % [c.ground, c.obj, c.after]]
		"graph":
			return [c.line, model_sentence(s), "The graph of h against t is shown."]
	return [c.line, model_sentence(s)]


## The flight drawn from launch to landing, h against t, with a level drawn if asked.
static func flight_graph(s: Dictionary, level: Variant = null) -> Dictionary:
	var land: float = S.crossings(s)[1]
	var H: float = S.vertex(s)[1].to_float()
	var top := ceili(H * 1.15 + 0.5)
	var hl: Array = [] if level == null else [[level.to_float(), "h = " + D(level)]]
	var g := Plot.spec([Plot.sample(func(t): return S.valuef(s, t), 0.0, land)], [], 0, ceili(land + 0.3), -maxi(1, roundi(top * 0.06)), top, hl)
	g.x_name = "t"
	g.y_name = "h"
	return g


## The GDC's graph and maximum tool on a flight or an arch, x for the input.
static func gdc_max(s: Dictionary, letter: String, out: String) -> Array:
	var v := S.vertex(s)
	return ["Graph y = %s on the GDC and use the maximum tool: x = %s, y = %s." % [model(s, "x"), W(v[0]), W(v[1])],
		"The vertex is the highest point: %s = %s, %s = %s." % [letter, W(v[0]), out, W(v[1])]]


## −b/(2a) worked out.
static func axis_step(s: Dictionary, letter: String) -> String:
	return "%s = −b/(2a) = −%s/(2 × %s) = %s" % [letter, B(s.b), B(s.a), W(S.vertex(s)[0])]


# ── The start ────────────────────────────────────────────────

func u_initial_height(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var c := story(s)
	var H: Q = S.vertex(s)[1]
	var ans := num_ans("height = ", s.c, " m")
	var asked: String = c.start if rep == "words" else "Write down the height from which the %s is %s." % [c.obj, c.after.trim_prefix("it is ")]
	var first: String = "The %s leaves %s when t = 0, so the height of %s above %s is h(0)." % [c.obj, c.base, c.base, c.ground] if rep == "words" \
		else "The %s starts when t = 0, so its starting height is h(0)." % c.obj
	var steps := [first, "h(0) = %s × 0² + %s × 0 + %s = %s" % [B(s.a), B(s.b), D(s.c), D(s.c)], say(ans)]
	var out := {"lines": flight_lines(s, rep), "asked": asked, "answer": ans,
		"wrongs": [wrong(opt(ans, H), R_TOP_FOR_START)],
		"fillers": rng.shuffled([opt(ans, s.b), opt(ans, S.value(s, Q.new(1)))]),
		"methods": {"any": method(steps, ans.values)}}
	return out


# ── The top ──────────────────────────────────────────────────

func u_vertex_value(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var c := story(s)
	var v := S.vertex(s)
	var T: Q = v[0]
	var H: Q = v[1]
	var ans := num_ans("maximum height = ", H, " m")
	var steps := {
		"gdc-max-zero": gdc_max(s, "t", "h") + [say(ans)],
		"axis-formula": ["The top is at the vertex, as a < 0: " + axis_step(s, "t"),
			"h(%s) = %s × %s² + %s × %s + %s = %s" % [W(T), B(s.a), W(T), B(s.b), W(T), D(s.c), W(H)], say(ans)],
	}
	var out := {"lines": flight_lines(s, rep), "asked": "Find the maximum height of the %s." % c.obj, "answer": ans,
		"wrongs": rng.shuffled([wrong(opt(ans, T), R_TIME_FOR_TOP), wrong(opt(ans, S.value(s, T.neg())), R_NO_MINUS),
			wrong(opt(ans, s.c), R_START_AS_TOP)]),
		"fillers": [opt(ans, H.mul(2))], "methods": {}, "graph": flight_graph(s) if rep == "graph" else null}
	for m in steps:
		out.methods[m] = method(steps[m], ans.values)
	return out


func u_time_of_vertex(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var c := story(s)
	var v := S.vertex(s)
	var T: Q = v[0]
	var H: Q = v[1]
	var ans := num_ans("t = ", T, " s")
	var steps := {
		"gdc-max-zero": gdc_max(s, "t", "h") + [say(ans)],
		"axis-formula": ["The top is at the vertex, as a < 0: " + axis_step(s, "t"), say(ans)],
	}
	# The midpoint of the zeros is a time in the story only when both zeros are: from the ground.
	if s.ground:
		var z: Q = s.b.neg().div(s.a)
		steps["midpoint-of-roots"] = ["h(t) = 0 when t(%st + %s) = 0: t = 0 or t = %s, the launch and the landing." % [GdcKit.lead(s.a), D(s.b), W(z)],
			"The top is halfway between the zeros: t = (0 + %s)/2 = %s" % [W(z), W(T)], say(ans)]
	var out := {"lines": flight_lines(s, rep), "asked": "Find the time at which the %s reaches its maximum height." % c.obj, "answer": ans,
		"wrongs": rng.shuffled([wrong(opt(ans, H), R_TOP_FOR_TIME), wrong(opt(ans, T.neg()), R_NO_MINUS)]),
		"fillers": [opt(ans, T.mul(2)), opt(ans, T.div(2))], "methods": {}, "graph": flight_graph(s) if rep == "graph" else null}
	for m in steps:
		out.methods[m] = method(steps[m], ans.values)
	return out


# ── The landing ──────────────────────────────────────────────

func u_landing_time(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var c := story(s)
	var z := S.crossings(s)
	var land: float = z[1]
	var neg: float = z[0]
	var T: Q = S.vertex(s)[0]
	var ans := Answer.make("number", {"v": GdcKit.qf(land)}, {}, "t = ", " s")
	ans.show = "sf"
	var steps := {
		"gdc-max-zero": ["Graph y = %s on the GDC for x ≥ 0 and use the zero tool: x = %s." % [model(s, "x"), W(land)],
			"The %s hits %s when h(t) = 0 with t > 0: t = %s." % [c.obj, c.ground, W(land)], say(ans)],
		"gdc-poly-solver": ["h(t) = 0: enter a = %s, b = %s, c = %s in the polynomial solver." % [D(s.a), D(s.b), D(s.c)],
			"It gives t = %s or t = %s." % [W(land), W(neg)],
			"t = %s is before the %s is %s, so it is rejected." % [W(neg), c.obj, c.after.trim_prefix("it is ")], say(ans)],
	}
	if c.after == "it leaps":
		steps["gdc-poly-solver"][2] = "t = %s is before the jump, so it is rejected." % W(neg)
	var out := {"lines": flight_lines(s, rep), "asked": "Find the time when the %s hits %s." % [c.obj, c.ground], "answer": ans,
		"wrongs": [wrong({"v": GdcKit.qf(neg)}, R_NEGATIVE_ROOT)],
		"fillers": [{"v": S.short(T)}, {"v": S.short(T.mul(2))}], "methods": {}}
	for m in steps:
		out.methods[m] = method(steps[m], ans.values)
	return out


func u_time_at_height(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var c := story(s)
	var k: Q = s.level
	var z := S.crossings(s, k.to_float())
	var land: float = S.crossings(s)[1]
	var T: Q = S.vertex(s)[0]
	var ans := Answer.make("number", {"v": GdcKit.qf(z[1])}, {}, "t = ", " s")
	ans.show = "sf"
	var moved := Fmt.terms([s.a, s.b, s.c.sub(k)], [2, 1, 0], "t", true)
	var lines := flight_lines(s, rep)
	if rep == "graph":
		lines[2] = "The graph of h against t is shown, with the line h = %s." % D(k)
	var out := {"lines": lines, "asked": "Find the later time at which the %s is %s m above %s." % [c.obj, D(k), c.ground], "answer": ans,
		"wrongs": [wrong({"v": GdcKit.qf(z[0])}, R_EARLIER)],
		"fillers": [{"v": S.short(T)}, {"v": GdcKit.qf(land)}],
		"methods": {"gdc-poly-solver": method([
			"h(t) = %s: %s = %s, so %s = 0." % [D(k), model(s, "t"), D(k), moved],
			"Enter a = %s, b = %s, c = %s in the polynomial solver: t = %s or t = %s." % [D(s.a), D(s.b), D(s.c.sub(k)), W(z[0]), W(z[1])],
			"It is %s m up on the way up and again on the way down; the later time is t = %s." % [D(k), W(z[1])], say(ans)], ans.values)},
		"graph": flight_graph(s, k) if rep == "graph" else null}
	return out


# ── Arches ───────────────────────────────────────────────────

static func arch_ref(s: Dictionary) -> String:
	match s.form:
		0:
			return "its left foot"
		1:
			return "the point under its top"
	return ARCH[s.ctx].post


static func arch_sentence(s: Dictionary) -> String:
	var a: Dictionary = ARCH[s.ctx]
	return "%s is modelled by y = %s, where y m is the height above %s and x m is the horizontal distance from %s." % [
		cap(a.what), model(s, "x"), a.ground, arch_ref(s)]


static func arch_lines(s: Dictionary, rep: String) -> Array:
	var a: Dictionary = ARCH[s.ctx]
	if rep == "equation":
		return ["y = " + model(s, "x"), "This models %s, where y m is the height above %s and x m is the horizontal distance from %s." % [
			a.what, a.ground, arch_ref(s)]]
	return [arch_sentence(s)]


static func arch_graph(s: Dictionary, level: Q) -> Dictionary:
	var H: float = S.vertex(s)[1].to_float()
	var top := ceili(H * 1.15 + 0.5)
	var g := Plot.spec([Plot.sample(func(x): return S.valuef(s, x), float(s.p), float(s.q))], [],
		mini(0, s.p) - 1, s.q + 1, -maxi(1, roundi(top * 0.06)), top, [[level.to_float(), "y = " + D(level)]])
	g.x_name = "x"
	g.y_name = "y"
	return g


func u_axis_of_symmetry(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var a: Dictionary = ARCH[s.ctx]
	var m := Q.new(s.p + s.q, 2)
	var H: Q = S.vertex(s)[1]
	var ans := num_ans("x = ", m)
	var lines := arch_lines(s, rep)
	var mid: Array
	if rep == "words":
		if s.pts == "feet":
			lines.append("It meets %s at x = %d and at x = %d." % [a.ground, s.p, s.q])
			mid = ["The arch meets %s at x = %d and x = %d, two points at the same height." % [a.ground, s.p, s.q],
				"The axis is halfway between them: x = (%d + %d)/2 = %s" % [s.p, s.q, D(m)]]
		else:
			lines.append("It is %s m above %s at x = %d and at x = %d." % [D(s.level), a.ground, s.u, s.v])
			mid = ["The arch is %s m high at x = %d and at x = %d, two points at the same height." % [D(s.level), s.u, s.v],
				"The axis is halfway between them: x = (%d + %d)/2 = %s" % [s.u, s.v, D(m)]]
	else:
		mid = ["Solve y = 0 on the GDC's polynomial solver: x = %d or x = %d, the feet of the arch." % [s.p, s.q],
			"The axis is halfway between the zeros: x = (%d + %d)/2 = %s" % [s.p, s.q, D(m)]]
	var steps := {
		"axis-formula": ["In y = ax² + bx + c, a = %s and b = %s." % [D(s.a), D(s.b)], axis_step(s, "x"), say(ans)],
		"midpoint-of-roots": mid + [say(ans)],
	}
	var out := {"lines": lines, "asked": "Write down the equation of the arch's axis of symmetry.", "answer": ans,
		"wrongs": [wrong(opt(ans, m.neg()), R_NO_MINUS)],
		"fillers": [opt(ans, H), opt(ans, Q.new(s.q - s.p))], "methods": {}}
	for k in steps:
		out.methods[k] = method(steps[k], ans.values)
	return out


func u_width_above_height(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var a: Dictionary = ARCH[s.ctx]
	var k: Q = s.level
	var z := S.crossings(s, k.to_float())
	var wd: float = z[1] - z[0]
	var ans := Answer.make("number", {"v": GdcKit.qf(wd)}, {}, "width = ", " m")
	ans.show = "sf"
	var others := S.width_slips(s)
	var lines := arch_lines(s, rep)
	if rep == "graph":
		lines.append("The graph of the arch is shown, with the line y = %s." % D(k))
	var moved := Fmt.terms([s.a, s.b, s.c.sub(k)], [2, 1, 0], "x", true)
	return {"lines": lines, "asked": "Find the width of the arch at a height of %s m above %s." % [D(k), a.ground], "answer": ans,
		"wrongs": [wrong({"v": others[0]}, R_HALF_WIDTH)],
		"fillers": rng.shuffled(others.slice(1).map(func(v): return {"v": v})),
		"methods": {"gdc-poly-solver": method([
			"y = %s: %s = %s, so %s = 0." % [D(k), model(s, "x"), D(k), moved],
			"Enter a = %s, b = %s, c = %s in the polynomial solver: x = %s or x = %s." % [D(s.a), D(s.b), D(s.c.sub(k)), W(z[0]), W(z[1])],
			"The arch is %s m high at both, so the width there is %s − %s = %s." % [D(k), W(z[1]), "(%s)" % W(z[0]) if z[0] < 0.0 else W(z[0]), W(wd)], say(ans)], ans.values)},
		"graph": arch_graph(s, k) if rep == "graph" else null}


# ── An obstacle ──────────────────────────────────────────────

func u_clears_obstacle(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var c: Dictionary = PATH[s.ctx]
	var H: Q = S.vertex(s)[1]
	var at := S.value(s, Q.new(s.d))
	var land: float = S.crossings(s)[1]
	var over: bool = at.to_float() > s.w.to_float()
	var obs: String = c.obstacle
	var right := ("Yes: when x = %d, y = %s m, above the %s m %s." if over else "No: when x = %d, y = %s m, below the %s m %s.") % [s.d, D(at), D(s.w), obs]
	var start := "it starts at ground level" if s.c.is_zero() else "it starts %s m up" % D(s.c)
	var starts_over: bool = s.c.to_float() > s.w.to_float()
	var built := SamplingViews.claims(right, [
		["Yes: the %s's greatest height, %s m, is above the %s m %s." % [c.obj, S.reads(H, true) if Answer.needs_rounding(H) else D(H), D(s.w), obs], R_PEAK_OBSTACLE],
		["Yes: the %s comes down at x = %s m, beyond the %s." % [c.obj, Fmt.sf(land), obs], ""],
		[("Yes: %s, above the %s m %s." if starts_over else "No: %s, below the %s m %s.") % [start, D(s.w), obs], ""]])
	var lines: Array
	if rep == "equation":
		lines = ["y = " + model(s, "x"), "This models the height, y m, of the %s at a horizontal distance of x m from %s." % [c.obj, c.from],
			"A %s %s m high stands %d m from %s." % [obs, D(s.w), s.d, c.from]]
	else:
		lines = [c.line, "Its height, y m, at a horizontal distance of x m from %s, is modelled by y = %s." % [c.from, model(s, "x")],
			"The %s is %s m high and %d m from %s." % [obs, D(s.w), s.d, c.from]]
	var steps := ["When x = %d: y = %s × %d² + %s × %d + %s = %s" % [s.d, B(s.a), s.d, B(s.b), s.d, D(s.c), D(at)],
		("%s > %s, so the %s passes over the %s." if over else "%s < %s, so the %s hits the %s.") % [D(at), D(s.w), c.obj, obs],
		"So: " + right]
	return {"lines": lines, "asked": "Find the height of the %s when x = %d, and decide whether it clears the %s." % [c.obj, s.d, obs],
		"answer": built.answer, "wrongs": built.wrongs, "fillers": built.fillers,
		"methods": {"any": method(steps, built.answer.values)}}


# ── An area from a constraint ────────────────────────────────

static func pen_figure(s: Dictionary) -> Dictionary:
	var deep := 4.0
	var wide := 7.0
	var pts := {"_a": [0.0, 0.0], "_b": [wide, 0.0], "_c": [wide, deep], "_d": [0.0, deep]}
	var lines: Array
	if s.wall:
		pts["_w0"] = [-1.0, deep]
		pts["_w1"] = [wide + 1.0, deep]
		lines = [OptimisationViews.L("_w0", "_w1", PEN[s.ctx][3], true), OptimisationViews.L("_d", "_a", "x m"),
			OptimisationViews.L("_a", "_b", "y m"), OptimisationViews.L("_b", "_c", "x m")]
	else:
		lines = [OptimisationViews.L("_d", "_a", "x m"), OptimisationViews.L("_a", "_b", "y m"), OptimisationViews.L("_b", "_c", "x m"),
			OptimisationViews.L("_c", "_d", "y m")]
	return OptimisationViews.sketch(pts, lines)


func u_build_area_model(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var p: Array = PEN[s.ctx]
	var F: int = s.F
	var co := S.pen_area(s)
	var ans := Answer.make("poly", {"c0": co[0], "c1": co[1]}, {"powers": [2, 1], "var": "x"}, "A(x) = ")
	ans.show = "dec"
	var lines: Array
	var steps: Array
	var fillers: Array = [{"c0": Q.new(-1), "c1": Q.new(F)}]
	var slip: Dictionary
	if s.wall:
		if rep == "diagram":
			lines = ["%s fences the rectangular %s in the diagram against %s, using %d m of fence for its other three sides." % [p[0], p[1], p[2], F],
				"The sides at right angles to the %s are x m long, and the side parallel to it is y m long." % p[3]]
		else:
			lines = ["%s fences a rectangular %s against %s, using %d m of fence for its other three sides." % [p[0], p[1], p[2], F],
				"The two sides at right angles to the %s are each x m long, and the side parallel to it is y m long." % p[3]]
		steps = ["The fence is two sides of x m and one of y m: 2x + y = %d, so y = %d − 2x." % [F, F],
			"A(x) = xy = x(%d − 2x)" % F, say(ans)]
		slip = {"c0": Q.new(-1), "c1": Q.new(F / 2)}
		fillers.append({"c0": Q.new(-2), "c1": Q.new(F / 2)})
	else:
		if rep == "diagram":
			lines = ["%s fences the rectangular %s in the diagram with %d m of fence all the way round." % [p[0], p[1], F],
				"Its sides are x m and y m long."]
		else:
			lines = ["%s fences a rectangular %s with %d m of fence all the way round." % [p[0], p[1], F],
				"It is x m wide and y m long."]
		steps = ["The fence is two sides of x m and two of y m: 2x + 2y = %d, so y = %d − x." % [F, F / 2],
			"A(x) = xy = x(%d − x)" % (F / 2), say(ans)]
		slip = {"c0": Q.new(-2), "c1": Q.new(F)}
		fillers.append({"c0": Q.new(-1), "c1": Q.new(F / 4)})
	return {"lines": lines, "asked": "Write down a model for the area, A(x) m², of the %s in terms of x." % p[1], "answer": ans,
		"wrongs": [wrong(slip, R_WRONG_SIDES)], "fillers": rng.shuffled(fillers),
		"methods": {"build-from-context": method(steps, ans.values)},
		"graph": pen_figure(s) if rep == "diagram" else null}
