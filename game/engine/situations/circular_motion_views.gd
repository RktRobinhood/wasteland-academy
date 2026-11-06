class_name CircularMotionViews
extends ExtensionViews
## The views on the `circular-motion` situation: one builder per unknown of t3-circular-motion
## (FAL-753). Every question is Paper 2, as the bank's three parts are. An answer the question
## wants exact is a `form` (a multiple of π, or a whole number of degrees or seconds), and every
## other answer is a number to 3 s.f. with the rounding trap.
##
## Representations: "words" (a story), "equation" (the angle as a function of time, θ = wt) and
## "diagram" (a chord: the circle, the line, A and B, drawn by RegionPlot's `sweep`; a turn with no
## line: the angle drawn to size on the circle, by PlotView's `sector`).

const SK := "SL3.4.convert#"
const R_FACTOR := SK + "0"
const R_RAD_AS_DEG := SK + "1"
const R_DECIMAL := SK + "2"
const R_PI_TURN := SK + "3"
const R_FLIPPED := SK + "4"
const R_FACTOR_BACK := SK + "5"
const R_PER_MINUTE := SK + "6"
const R_MIXED := SK + "7"
const R_HALF := SK + "8"
const R_WHOLE := SK + "9"
const R_SINE := SK + "10"
const R_REST := SK + "11"
const R_TIMES := SK + "12"
const R_NO_TIME := SK + "13"
const R_DEG_AS_RAD := SK + "14"

## What turns, what it sends out, and the straight line beside it.
const SWEEPS := [
	{"thing": "The watchtower's searchlight", "ray": "beam", "line": "fence"},
	{"thing": "The salvage yard's rotating beacon", "ray": "light", "line": "haul road"},
	{"thing": "The depot's radar dish", "ray": "signal", "line": "fence line"},
	{"thing": "The ridge camp's scanner", "ray": "beam", "line": "pipeline"},
	{"thing": "The old mast's lamp", "ray": "light", "line": "rail track"},
]
## What turns, and its arm.
const ROTORS := [
	{"thing": "A wind turbine at the bean farm", "arm": "Each blade", "tip": "the tip of a blade"},
	{"thing": "A wind pump on the flats", "arm": "Each sail", "tip": "the tip of a sail"},
	{"thing": "A water wheel at the dam", "arm": "Each spoke", "tip": "the end of a spoke"},
	{"thing": "A rotor on the old mill", "arm": "Each vane", "tip": "the tip of a vane"},
	{"thing": "A crane in the scrapyard", "arm": "Its jib", "tip": "the end of the jib"},
]

const UNKNOWNS := ["rate-from-period", "angle-expression", "angle-after-time", "rate-from-rpm", "rate-from-degrees",
	"sweep-to-radians", "sweep-to-degrees", "chord-angle-exact", "chord-time-exact", "rate-to-degrees", "period-from-rate",
	"time-to-turn", "time-from-period", "half-angle", "chord-angle", "chord-time", "chord-time-rpm", "chord-time-degrees",
	"dark-time", "fraction-in-view", "arc-past-line", "distance-from-time", "arc-in-time", "rim-speed", "rim-speed-rpm"]
const EXACT := " Give your answer as an exact multiple of π."
const SF := " Give your answer to 3 significant figures."
const RS := " rad/s"

## Every value the working has landed on, as it was worked from the figures shown.
var chains: Array = []


func needs() -> Dictionary:
	var out := {}
	for u in UNKNOWNS:
		out[u] = {"ask": u}
	return out


func papers(unknown: String, _rep: String, _angle: String) -> Array:
	return [2] if has(unknown) else []


func build(unknown: String, rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var out := super.build(unknown, rep, s, rng)
	if rng != null:
		out.wrongs = rng.shuffled(out.wrongs)
	out.given = CircularMotionSituation.export(s)
	return out


# ── Writing things ───────────────────────────────────────────

static func D(v: Variant) -> String:
	return Fmt.dec(v)


## A value in the working, to 5 figures.
static func w(x: float) -> String:
	return Fmt.work(x, 5)


## That value as a number, so the next step works from what is on the page.
static func rd(x: float) -> float:
	return float(w(x))


## The value the working lands on, kept so the situation can hold it to the answer.
func end(x: float) -> String:
	chains.append(x)
	return w(x)


## An exact question's options are all there, and no two read the same.
func exact_ok(out: Dictionary) -> bool:
	var seen := {out.answer.values.text: true}
	for o in out.wrongs:
		seen[o.values.text] = true
	return seen.size() == out.wrongs.size() + 1


static func sweep(s: Dictionary) -> Dictionary:
	return SWEEPS[s.ctx]


static func rotor(s: Dictionary) -> Dictionary:
	return ROTORS[s.ctx]


## "π/8", or with a letter after the π, "3πt/8".
static func pi_text(b: Q, letter: String = "") -> String:
	return Fmt.pi(b).replace("π", "π" + letter)


## The line's distance as it is written: "14 m", or "3√2 m" on an exact chord.
static func d_text(s: Dictionary) -> String:
	if not s.has("ratio"):
		return D(s.d)
	var root: String = CircularMotionSituation.LANDMARK[s.ratio].root
	return "%d%s" % [s.dk, root]


static func metres(t: String) -> String:
	return t + " m"


## The rate as the story gives it, where the question needs one.
static func rate_lines(rep: String, s: Dictionary) -> Array:
	match s.src:
		"T":
			return ["It makes one full turn every %d seconds." % s.T] if s.has("T") else []
		"n":
			return ["It turns at %d revolutions per minute." % s.n]
		"k":
			return ["It turns at %d degrees per second." % s.k]
	if rep == "equation":
		return ["After t seconds it has turned through θ = %st radians." % D(s.w)]
	return ["It turns at %s radians per second." % D(s.w)]


## The chord, drawn: the circle, the line, A and B. `mark` picks the angle that is marked.
static func chord_figure(s: Dictionary, over: Dictionary = {}) -> Dictionary:
	var out := {"kind": "region", "shape": "sweep", "r": s.r.to_float(), "d": CircularMotionSituation.dist(s),
		"r_label": metres(D(s.r)), "d_label": metres(d_text(s)), "line": sweep(s).line, "mark": "", "angle_label": "", "nearest": false}
	out.merge(over, true)
	return out


## An angle drawn to size on the circle.
static func turn_figure(th: float, angle_label: String, over: Dictionary = {}) -> Dictionary:
	var out := {"kind": "sector", "theta": th, "shade": "minor", "names": ["O", "A", "B"], "r_label": "", "angle_label": angle_label, "arc_label": "", "circle": true}
	out.merge(over, true)
	return out


## The story with its chord, in words or drawn, and the rate. The figure's `over` is its marks.
static func chord_stem(rep: String, s: Dictionary, over: Dictionary = {}) -> Dictionary:
	var c := sweep(s)
	if rep == "diagram":
		return {"lines": ["%s at O turns steadily. The diagram shows the circle its %s reaches and a straight %s, which meets the circle at A and B." % [c.thing, c.ray, c.line]] + rate_lines(rep, s),
			"graph": chord_figure(s, over)}
	return {"lines": ["%s at O turns steadily. Its %s reaches %s, and a straight %s passes %s from O, meeting the edge of that circle at A and B." % [c.thing, c.ray, metres(D(s.r)), c.line, metres(d_text(s))]] + rate_lines(rep, s),
		"graph": null}


## The story with no line in it.
static func plain_stem(rep: String, s: Dictionary) -> Dictionary:
	return {"lines": ["%s at O turns steadily." % sweep(s).thing] + rate_lines(rep, s), "graph": null}


static func rotor_stem(rep: String, s: Dictionary) -> Dictionary:
	var c := rotor(s)
	return {"lines": ["%s turns about O. %s is %s long." % [c.thing, c.arm, metres(D(s.r))]] + rate_lines(rep, s), "graph": null}


static func frame(v: Dictionary, asked: String, ans: Dictionary) -> Dictionary:
	return {"lines": v.lines, "graph": v.graph, "table": null, "answer": ans, "asked": asked, "wrongs": [], "generic": []}


static func say(ans: Dictionary) -> String:
	return "So " + Answer.text(ans) + "."


# ── Answers ──────────────────────────────────────────────────

static func num(label: String, x: float, tail: String) -> Dictionary:
	var ans := Answer.make("number", {"v": GdcKit.qf(x)}, {}, label, tail)
	ans.show = "sf"
	return ans


## A multiple of π, exact: the student types the multiple.
static func pi_ans(label: String, b: Q, tail: String = "", letter: String = "") -> Dictionary:
	var ans := DifferentiationViews.form(label + pi_text(b, letter) + tail, [label, {"slot": "b"}, "π" + letter + tail], {"b": b})
	ans.head = label
	ans.tail = tail
	ans.letter = letter
	return ans


## A whole number of degrees or seconds, exact.
static func whole_ans(label: String, v: Q, tail: String) -> Dictionary:
	var ans := DifferentiationViews.form(label + D(v) + tail, [label, {"slot": "v"}, tail], {"v": v})
	ans.head = label
	ans.tail = tail
	return ans


## A wrong value in the answer's own terms.
static func slip(x: float, ref: String = "") -> Array:
	return [wrong({"v": GdcKit.qf(x)}, ref)] if x > 0.0 else []


## Numbers with no misconception behind them, for `generic`.
static func rest(xs: Array) -> Array:
	return xs.filter(func(x): return x > 0.0).map(func(x): return {"v": GdcKit.qf(x)})


## A wrong multiple of π, which can be typed.
static func pi_slip(ans: Dictionary, b: Q, ref: String = "") -> Dictionary:
	return DifferentiationViews.alt(ans.head + pi_text(b, ans.letter) + ans.tail, ref, {"b": b})


## A wrong option in another shape, which can only be picked.
static func other(ans: Dictionary, body: String, ref: String) -> Dictionary:
	return DifferentiationViews.alt(ans.head + body + ans.tail, ref)


## A wrong whole answer, which can be typed.
static func whole_slip(ans: Dictionary, v: Q, ref: String = "") -> Dictionary:
	return DifferentiationViews.alt(ans.head + D(v) + ans.tail, ref, {"v": v})


## Multiples of π close by, for `generic`, as option values.
static func pi_rest(ans: Dictionary, bs: Array) -> Array:
	return bs.filter(func(b): return not b.eq(ans.values.b) and b.sign() > 0).map(func(b): return pi_slip(ans, b).values)


# ── Working: a chord ─────────────────────────────────────────

static func half_line(s: Dictionary) -> String:
	return "Half of angle AOB is φ, with cos φ = %s/%s, so φ = %s°." % [D(s.d), D(s.r), w(rad_to_deg(CircularMotionSituation.phi(s)))]


## φ in degrees, angle AOB in degrees, and the same in radians, each from the one before.
static func chord_figures(s: Dictionary) -> Dictionary:
	var phi_d := rd(rad_to_deg(CircularMotionSituation.phi(s)))
	var whole := rd(2.0 * phi_d)
	var radians := rd(deg_to_rad(whole))
	return {"phi": phi_d, "whole": whole, "rad": radians, "share": rd(whole / 360.0)}


## Multiply by π/180: angle AOB in radians.
static func rad_line(f: Dictionary) -> String:
	return "Angle AOB = 2φ = %s°, and %s × π/180 = %s radians." % [w(f.whole), w(f.whole), w(f.rad)]


## Angle AOB as a share of a turn.
static func share_line(f: Dictionary) -> String:
	return "Angle AOB = 2φ = %s°, which is %s/360 = %s of a turn." % [w(f.whole), w(f.whole), w(f.share)]


## The rate as the working gets it in radians per second, exact.
static func rate_rad(s: Dictionary) -> String:
	match s.src:
		"T":
			return pi_text(Q.new(2, s.T))
		"n":
			return pi_text(Q.new(s.n, 30))
		"k":
			return pi_text(Q.new(s.k, 180))
	return D(s.w)


static func rate_step(s: Dictionary) -> String:
	match s.src:
		"T":
			return "It turns 360 ÷ %d × π/180 = %s radians per second." % [s.T, rate_rad(s)]
		"n":
			return "It turns %d × 360 ÷ 60 × π/180 = %s radians per second." % [s.n, rate_rad(s)]
		"k":
			return "It turns %d × π/180 = %s radians per second." % [s.k, rate_rad(s)]
	return ""


## The time for one turn, where the story doesn't give it.
static func period_step(s: Dictionary) -> Array:
	match s.src:
		"n":
			return ["One turn takes 60 ÷ %d = %s seconds." % [s.n, w(60.0 / s.n)]]
		"k":
			return ["One turn takes 360 ÷ %d = %s seconds." % [s.k, w(360.0 / s.k)]]
	return []


## The time for one turn as the working last showed it.
static func period_shown(s: Dictionary) -> float:
	return float(s.T) if s.src == "T" else rd(CircularMotionSituation.period(s))


## The time AB is swept, by each method, from the figures shown.
func sweep_time(s: Dictionary) -> Dictionary:
	var f := chord_figures(s)
	var rate := CircularMotionSituation.rate(s)
	return {"f": f, "by_rad": rd(f.rad / rate), "by_share": rd(f.share * period_shown(s))}


# ── Rates and angles, exact ──────────────────────────────────

func u_rate_from_period(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var b := Q.new(2, s.T)
	var ans := pi_ans("rate = ", b, RS)
	var v := chord_stem(rep, s) if rep == "diagram" else plain_stem(rep, s)
	var out := frame(v, "Find the angle it turns through in one second, in radians." + EXACT, ans)
	out.wrongs = [other(ans, Fmt.sf(b.to_float() * PI), R_DECIMAL), pi_slip(ans, Q.new(1, s.T), R_PI_TURN),
		other(ans, Fmt.sf(360.0 / s.T), R_DEG_AS_RAD), other(ans, "%s/π" % D(Q.new(s.T, 2)), R_FLIPPED)]
	out.generic = pi_rest(ans, [b.mul(2), b.mul(3), Q.new(4, s.T), b.add(Q.new(1, 2)), b.add(Q.new(1, 4))])
	out.methods = {"multiply-factor": method(["In one second it turns 360° ÷ %d." % s.T, "Multiply by π/180: 360 ÷ %d × π/180 = %s" % [s.T, Fmt.pi(b)], say(ans)], ans.values),
		"fraction-of-turn": method(["One second is 1/%d of a turn." % s.T, "A full turn is 2π: 1/%d × 2π = %s" % [s.T, Fmt.pi(b)], say(ans)], ans.values)}
	return out


func u_angle_expression(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var b := Q.new(2, s.T)
	var ans := pi_ans("θ = ", b, "", "t")
	var c := sweep(s)
	var v := chord_stem(rep, s, {"mark": "moving", "angle_label": "θ"}) if rep == "diagram" else plain_stem(rep, s)
	if rep == "diagram":
		v.lines = v.lines + ["At t = 0 its %s points at A. After t seconds it points at D, on the way to B, and has turned through θ radians." % c.ray]
	else:
		v.lines = v.lines + ["After t seconds its %s has turned through θ radians from where it started." % c.ray]
	var out := frame(v, "Write θ in terms of t, as an exact multiple of π.", ans)
	out.wrongs = [other(ans, Fmt.sf(b.to_float() * PI) + "t", R_DECIMAL), pi_slip(ans, Q.new(1, s.T), R_PI_TURN),
		other(ans, Fmt.sf(360.0 / s.T) + "t", R_DEG_AS_RAD), other(ans, "%st/π" % D(Q.new(s.T, 2)), R_FLIPPED)]
	out.generic = pi_rest(ans, [b.mul(2), b.mul(3), Q.new(4, s.T), b.add(Q.new(1, 2)), b.add(Q.new(1, 4))])
	var bt := pi_text(b, "t")
	out.methods = {"multiply-factor": method(["In one second it turns 360° ÷ %d, so in t seconds 360t ÷ %d degrees." % [s.T, s.T], "Multiply by π/180: 360t ÷ %d × π/180 = %s" % [s.T, bt], say(ans)], ans.values),
		"fraction-of-turn": method(["After t seconds it has made t/%d of a turn." % s.T, "A full turn is 2π: t/%d × 2π = %s" % [s.T, bt], say(ans)], ans.values)}
	return out


func u_angle_after_time(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var b: Q = s.tau.mul(2).div(s.T)
	var ans := pi_ans("θ = ", b)
	var tau := D(s.tau)
	var v := plain_stem(rep, s)
	if rep == "diagram":
		v.lines = v.lines + ["The diagram shows the angle θ, in radians, that it turns through from A to B in %s seconds." % tau]
		v.graph = turn_figure(b.to_float() * PI, "θ")
	var out := frame(v, "Find the angle θ it turns through in %s seconds, in radians." % tau + EXACT if rep == "words" else "Find θ." + EXACT, ans)
	var half: Q = s.tau.div(s.T)
	var deg: float = s.tau.to_float() * 360.0 / s.T
	out.wrongs = [other(ans, Fmt.sf(b.to_float() * PI), R_DECIMAL), pi_slip(ans, half, R_PI_TURN), other(ans, Fmt.sf(deg), R_DEG_AS_RAD)]
	out.generic = pi_rest(ans, [b.mul(2), b.mul(3), b.add(Q.new(1, 2)), b.add(Q.new(1, 4)), b.add(1)])
	out.methods = {"multiply-factor": method(["In %s seconds it turns %s × 360 ÷ %d = %s°." % [tau, tau, s.T, w(deg)], "Multiply by π/180: %s ÷ %d × 360 × π/180 = %s" % [tau, s.T, Fmt.pi(b)], say(ans)], ans.values),
		"fraction-of-turn": method(["%s seconds is %s/%d of a turn." % [tau, tau, s.T], "A full turn is 2π: %s/%d × 2π = %s" % [tau, s.T, Fmt.pi(b)], say(ans)], ans.values)}
	return out


func u_rate_from_rpm(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var b := Q.new(s.n, 30)
	var ans := pi_ans("rate = ", b, RS)
	var out := frame(plain_stem(rep, s), "Find its rate of turning in radians per second." + EXACT, ans)
	out.wrongs = [other(ans, Fmt.sf(b.to_float() * PI), R_DECIMAL), pi_slip(ans, Q.new(s.n, 60), R_PI_TURN),
		other(ans, D(Q.new(6 * s.n)), R_DEG_AS_RAD), pi_slip(ans, Q.new(2 * s.n), R_PER_MINUTE)]
	out.generic = pi_rest(ans, [b.mul(3), b.mul(4), b.add(Q.new(1, 2)), b.add(Q.new(1, 4)), b.add(1)])
	out.methods = {"multiply-factor": method(["%d turns is %d × 360 = %d° in a minute, which is %d° per second." % [s.n, s.n, 360 * s.n, 6 * s.n], "Multiply by π/180: %d × π/180 = %s" % [6 * s.n, Fmt.pi(b)], say(ans)], ans.values),
		"fraction-of-turn": method(["Each second it makes %d/60 of a turn." % s.n, "A full turn is 2π: %d/60 × 2π = %s" % [s.n, Fmt.pi(b)], say(ans)], ans.values)}
	return out


## "150° = 5 lots of 30°": the landmark an angle in degrees counts in.
static func landmark_steps(deg: int, b: Q) -> Array:
	var base := 30 if deg % 30 == 0 else (45 if deg % 45 == 0 else 15)
	var one := Q.new(base, 180)
	var lots := deg / base
	if lots == 1:
		return ["%d° is itself a landmark angle: %s." % [deg, Fmt.pi(one)]]
	return ["%d° = %s, and %d° is %d lots of %d°." % [base, Fmt.pi(one), deg, lots, base], "%d × %s = %s" % [lots, Fmt.pi(one), Fmt.pi(b)]]


func u_rate_from_degrees(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var b := Q.new(s.k, 180)
	var ans := pi_ans("rate = ", b, RS)
	var out := frame(plain_stem(rep, s), "Find its rate of turning in radians per second." + EXACT, ans)
	out.wrongs = [other(ans, Fmt.sf(float(s.k) * 180.0 / PI), R_FACTOR), other(ans, Fmt.sf(b.to_float() * PI), R_DECIMAL), pi_slip(ans, Q.new(s.k, 360), R_PI_TURN)]
	out.generic = pi_rest(ans, [b.mul(2), b.mul(3), b.add(Q.new(1, 2)), b.add(Q.new(1, 4)), b.add(1)])
	out.methods = {"multiply-factor": method(["Multiply by π/180: %d × π/180 = %s" % [s.k, Fmt.pi(b)], say(ans)], ans.values),
		"fraction-of-turn": method(["%d° is %d/360 of a turn." % [s.k, s.k], "A full turn is 2π: %d/360 × 2π = %s" % [s.k, Fmt.pi(b)], say(ans)], ans.values),
		"landmarks": method(landmark_steps(s.k, b) + [say(ans)], ans.values)}
	return out


func u_sweep_to_radians(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var b := Q.new(s.deg, 180)
	var ans := pi_ans("θ = ", b)
	var c := sweep(s)
	var v := {"lines": ["%s at O swings its %s from A to B through %d°." % [c.thing, c.ray, s.deg]], "graph": null}
	if rep == "diagram":
		v.lines = ["%s at O swings its %s from A to B, through the angle in the diagram." % [c.thing, c.ray]]
		v.graph = turn_figure(b.to_float() * PI, "%d°" % s.deg)
	var out := frame(v, "Write this angle θ in radians." + EXACT, ans)
	out.wrongs = [other(ans, Fmt.sf(float(s.deg) * 180.0 / PI), R_FACTOR), other(ans, Fmt.sf(b.to_float() * PI), R_DECIMAL), pi_slip(ans, Q.new(s.deg, 360), R_PI_TURN)]
	out.generic = pi_rest(ans, [b.mul(2), b.mul(3), b.add(Q.new(1, 2)), b.add(Q.new(1, 4)), b.add(1)])
	out.methods = {"multiply-factor": method(["Multiply by π/180: %d × π/180 = %s" % [s.deg, Fmt.pi(b)], say(ans)], ans.values),
		"fraction-of-turn": method(["%d° is %d/360 of a turn." % [s.deg, s.deg], "A full turn is 2π: %d/360 × 2π = %s" % [s.deg, Fmt.pi(b)], say(ans)], ans.values),
		"landmarks": method(landmark_steps(s.deg, b) + [say(ans)], ans.values)}
	return out


func u_sweep_to_degrees(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var deg: Q = s.pk.mul(180)
	var ans := whole_ans("θ = ", deg, "°")
	var c := sweep(s)
	var p: String = Fmt.pi(s.pk)
	var v := {"lines": ["%s at O swings its %s from A to B through %s radians." % [c.thing, c.ray, p]], "graph": null}
	if rep == "diagram":
		v.lines = ["%s at O swings its %s from A to B, through the angle in the diagram, which is in radians." % [c.thing, c.ray]]
		v.graph = turn_figure(s.pk.to_float() * PI, p)
	var out := frame(v, "Write this angle θ in degrees.", ans)
	out.wrongs = [other(ans, Fmt.sf(s.pk.to_float() * PI), R_RAD_AS_DEG), other(ans, Fmt.sf(s.pk.to_float() * PI * PI / 180.0), R_FACTOR_BACK), whole_slip(ans, s.pk.mul(360), R_PI_TURN)]
	var gen: Array = [deg.mul(Q.new(1, 2)), deg.add(30), deg.add(45), deg.add(60), deg.add(90)]
	out.generic = gen.map(func(g): return whole_slip(ans, g).values)
	var one := Q.new(1, s.pk.d)
	var unit_d: Q = one.mul(180)
	var turn: Q = s.pk.div(2)
	out.methods = {"multiply-factor": method(["Multiply by 180/π: %s × 180/π = %s" % [p, D(deg)], say(ans)], ans.values),
		"fraction-of-turn": method(["%s is %s of a full turn of 2π." % [p, Fmt.num(turn)], "%s × 360° = %s°" % [Fmt.num(turn), D(deg)], say(ans)], ans.values),
		"landmarks": method(["%s is itself a landmark angle: %s°." % [p, D(deg)], say(ans)] if s.pk.n == 1 else
			["%s is %s°, and %s is %d lots of that." % [Fmt.pi(one), D(unit_d), p, s.pk.n], "%d × %s° = %s°" % [s.pk.n, D(unit_d), D(deg)], say(ans)], ans.values)}
	return out


# ── An exact chord ───────────────────────────────────────────

## cos φ on the page: "cos φ = 3√2/6 = √2/2".
static func exact_cos(s: Dictionary) -> String:
	return "cos φ = %s/%s = %s" % [d_text(s), D(s.r), CircularMotionSituation.LANDMARK[s.ratio].text]


## Angle AOB as a multiple of π, and half of it.
static func exact_whole(s: Dictionary) -> Q:
	var p: Array = CircularMotionSituation.LANDMARK[s.ratio].phi
	return Q.new(2 * p[0], p[1])


func u_chord_angle_exact(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var b := exact_whole(s)
	var ans := pi_ans("angle AOB = ", b)
	var over := {"mark": "whole", "angle_label": "?"}
	var out := frame(chord_stem(rep, s, over), "Find angle AOB, in radians." + EXACT, ans)
	out.wrongs = [pi_slip(ans, b.div(2), R_HALF), other(ans, Fmt.sf(b.to_float() * PI), R_DECIMAL), other(ans, D(b.mul(180)), R_DEG_AS_RAD)]
	# The sine's slip is its own value only with cos φ = √3/2: else it is the half angle, or right.
	if s.ratio == 2:
		out.wrongs.append(pi_slip(ans, b.mul(2), R_SINE))
	out.generic = pi_rest(ans, [b.mul(Q.new(3, 2)), Q.new(2).sub(b), Q.new(1).sub(b), b.add(Q.new(1, 2))])
	var half: Q = b.div(2)
	var deg: Q = b.mul(180)
	var phi_d: Q = half.mul(180)
	out.methods = {"multiply-factor": method([exact_cos(s) + ", so φ = %s°." % D(phi_d), "Angle AOB = 2φ = %s°." % D(deg), "Multiply by π/180: %s × π/180 = %s" % [D(deg), Fmt.pi(b)], say(ans)], ans.values),
		"fraction-of-turn": method([exact_cos(s) + ", so φ = %s°." % D(phi_d), "Angle AOB = 2φ = %s°, which is %s of a turn." % [D(deg), Fmt.num(b.div(2))], "A full turn is 2π: %s × 2π = %s" % [Fmt.num(b.div(2)), Fmt.pi(b)], say(ans)], ans.values),
		"landmarks": method([exact_cos(s) + ", a landmark: φ = %s." % Fmt.pi(half), "Angle AOB = 2φ = 2 × %s = %s" % [Fmt.pi(half), Fmt.pi(b)], say(ans)], ans.values)}
	return out


func u_chord_time_exact(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var b := exact_whole(s)
	var share: Q = b.div(2)
	var t: Q = share.mul(s.T)
	var ans := whole_ans("time = ", t, " s")
	var c := sweep(s)
	var v := chord_stem(rep, s)
	var out := frame(v, "For how many seconds is its %s on the stretch AB of the %s in each turn? Give the exact value." % [c.ray, c.line], ans)
	out.wrongs = [whole_slip(ans, t.div(2), R_HALF), whole_slip(ans, Q.new(s.T).sub(t), R_REST),
		other(ans, Fmt.sf(b.mul(180).to_float() / CircularMotionSituation.rate(s)), R_MIXED)]
	if s.ratio == 2:
		out.wrongs.append(whole_slip(ans, t.mul(2), R_SINE))
	var gen: Array = [t.mul(3), t.mul(4), t.add(1), t.add(2)]
	out.generic = gen.map(func(g): return whole_slip(ans, g).values)
	var half: Q = b.div(2)
	var deg: Q = b.mul(180)
	var phi_d: Q = half.mul(180)
	var p: String = Fmt.pi(b)
	var rr := rate_rad(s)
	out.methods = {"multiply-factor": method([exact_cos(s) + ", so φ = %s°." % D(phi_d), "Angle AOB = 2φ = %s°, and %s × π/180 = %s radians." % [D(deg), D(deg), p], rate_step(s), "Time = %s ÷ (%s) = %s" % [p, rr, D(t)], say(ans)], ans.values),
		"fraction-of-turn": method([exact_cos(s) + ", so φ = %s°." % D(phi_d), "Angle AOB = 2φ = %s°, which is %s of a turn." % [D(deg), Fmt.num(share)], "%s × %d = %s" % [Fmt.num(share), s.T, D(t)], say(ans)], ans.values),
		"landmarks": method([exact_cos(s) + ", a landmark: φ = %s." % Fmt.pi(half), "Angle AOB = 2φ = %s, and it turns 2π ÷ %d = %s radians per second." % [p, s.T, rr], "Time = %s ÷ (%s) = %s" % [p, rr, D(t)], say(ans)], ans.values)}
	return out


# ── Rates and times, to 3 s.f. ───────────────────────────────

func u_rate_to_degrees(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var om: float = s.w.to_float()
	var x := rad_to_deg(om)
	var ans := num("rate = ", x, "°/s")
	var out := frame(plain_stem(rep, s), "Find its rate of turning in degrees per second." + SF, ans)
	out.wrongs = slip(om, R_RAD_AS_DEG) + slip(deg_to_rad(om), R_FACTOR_BACK) + slip(om / PI * 360.0, R_PI_TURN)
	out.generic = rest([x * 2.0, x / 2.0, x * 3.0, x / 3.0])
	var t := D(s.w)
	out.methods = {"multiply-factor": method(["Multiply by 180/π: %s × 180/π = %s" % [t, end(x)], say(ans)], ans.values),
		"fraction-of-turn": method(["Each second it makes %s/2π of a turn." % t, "A full turn is 360°: %s/2π × 360 = %s" % [t, end(x)], say(ans)], ans.values)}
	return out


func u_period_from_rate(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var om: float = s.w.to_float()
	var x := TAU / om
	var ans := num("time = ", x, " s")
	var out := frame(plain_stem(rep, s), "Find the time it takes to make one full turn." + SF, ans)
	out.wrongs = slip(PI / om, R_PI_TURN) + slip(om / TAU, R_FLIPPED) + slip(TAU * om, R_TIMES) + slip(360.0 / om, R_MIXED)
	out.generic = rest([x * 2.0, x / 2.0, x * 3.0])
	var t := D(s.w)
	var per_s := rd(rad_to_deg(om))
	out.methods = {"multiply-factor": method(["Multiply by 180/π: %s × 180/π = %s° per second." % [t, w(per_s)], "A full turn is 360°: 360 ÷ %s = %s" % [w(per_s), end(360.0 / per_s)], say(ans)], ans.values),
		"fraction-of-turn": method(["Each second it makes %s/2π of a turn." % t, "So a full turn takes 2π ÷ %s = %s" % [t, end(x)], say(ans)], ans.values)}
	return out


func u_time_to_turn(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var om: float = s.w.to_float()
	var th := deg_to_rad(float(s.deg))
	var x := th / om
	var ans := num("time = ", x, " s")
	var out := frame(plain_stem(rep, s), "Find the time it takes to turn through %d°." % s.deg + SF, ans)
	out.wrongs = slip(float(s.deg) / om, R_MIXED) + slip(th * om, R_TIMES) + slip(float(s.deg) * 180.0 / PI / om, R_FACTOR)
	out.generic = rest([x * 2.0, x / 2.0, x * 3.0])
	var t := D(s.w)
	var rad_s := rd(th)
	var turn := rd(TAU / om)
	out.methods = {"multiply-factor": method(["Multiply by π/180: %d × π/180 = %s radians." % [s.deg, w(rad_s)], "Time = %s ÷ %s = %s" % [w(rad_s), t, end(rad_s / om)], say(ans)], ans.values),
		"fraction-of-turn": method(["One turn takes 2π ÷ %s = %s seconds." % [t, w(turn)], "%d° is %d/360 of a turn." % [s.deg, s.deg], "%d/360 × %s = %s" % [s.deg, w(turn), end(float(s.deg) / 360.0 * turn)], say(ans)], ans.values)}
	return out


func u_time_from_period(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var th: float = s.th.to_float()
	var x: float = th * s.T / TAU
	var ans := num("time = ", x, " s")
	var v := plain_stem(rep, s)
	var t := D(s.th)
	if rep == "diagram":
		v.lines = v.lines + ["The diagram shows the angle it turns through from A to B, in radians."]
		v.graph = turn_figure(th, t)
	var out := frame(v, ("Find the time it takes to turn from A to B." if rep == "diagram" else "Find the time it takes to turn through %s radians." % t) + SF, ans)
	out.wrongs = slip(th * s.T / PI, R_PI_TURN) + slip(th * TAU / s.T, R_TIMES) + slip(th * s.T / 360.0, R_MIXED)
	out.generic = rest([x * 2.0, x / 2.0, x * 3.0])
	var share := rd(th / TAU)
	out.methods = {"multiply-factor": method([rate_step(s), "Time = %s ÷ (%s) = %s" % [t, rate_rad(s), end(x)], say(ans)], ans.values),
		"fraction-of-turn": method(["%s radians is %s/2π = %s of a turn." % [t, t, w(share)], "%s × %d = %s" % [w(share), s.T, end(share * s.T)], say(ans)], ans.values)}
	return out


# ── A chord, to 3 s.f. ───────────────────────────────────────

func u_half_angle(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var ph := CircularMotionSituation.phi(s)
	var ans := num("angle AOM = ", ph, " radians")
	var c := sweep(s)
	var v := chord_stem(rep, s, {"mark": "half", "angle_label": "?", "nearest": true})
	v.lines = v.lines + ["M is the point of the %s nearest to O." % c.line]
	var out := frame(v, "Find angle AOM, in radians." + SF, ans)
	out.wrongs = slip(2.0 * ph, R_WHOLE) + slip(rad_to_deg(ph), R_DEG_AS_RAD) + slip(CircularMotionSituation.phi_sin(s), R_SINE)
	out.generic = rest([ph / 2.0, ph * 3.0, ph * PI, atan(s.d.to_float() / s.r.to_float())])
	var f := chord_figures(s)
	var line := "OM and AM meet at a right angle, so cos(angle AOM) = %s/%s, and the angle is %s°." % [D(s.d), D(s.r), w(f.phi)]
	var share := rd(f.phi / 360.0)
	out.methods = {"multiply-factor": method([line, "Multiply by π/180: %s × π/180 = %s" % [w(f.phi), end(deg_to_rad(f.phi))], say(ans)], ans.values),
		"fraction-of-turn": method([line, "%s/360 = %s of a turn, and a full turn is 2π: %s × 2π = %s" % [w(f.phi), w(share), w(share), end(share * TAU)], say(ans)], ans.values)}
	return out


func u_chord_angle(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var ph := CircularMotionSituation.phi(s)
	var x := 2.0 * ph
	var ans := num("angle AOB = ", x, " radians")
	var out := frame(chord_stem(rep, s, {"mark": "whole", "angle_label": "?"}), "Find angle AOB, in radians." + SF, ans)
	out.wrongs = slip(ph, R_HALF) + slip(rad_to_deg(x), R_DEG_AS_RAD) + slip(2.0 * CircularMotionSituation.phi_sin(s), R_SINE)
	out.generic = rest([x * 2.0, TAU - x, x * 3.0, x * 1.5])
	var f := chord_figures(s)
	chains.append(f.rad)
	out.methods = {"multiply-factor": method([half_line(s), rad_line(f), say(ans)], ans.values),
		"fraction-of-turn": method([half_line(s), share_line(f), "A full turn is 2π: %s × 2π = %s" % [w(f.share), end(f.share * TAU)], say(ans)], ans.values)}
	return out


## The time on AB, and its slips, whichever way the rate is given. Each slip is a time.
func sweep_slips(s: Dictionary) -> Dictionary:
	var ph := CircularMotionSituation.phi(s)
	var om := CircularMotionSituation.rate(s)
	return {"t": 2.0 * ph / om, "half": ph / om, "sine": 2.0 * CircularMotionSituation.phi_sin(s) / om, "deg": rad_to_deg(2.0 * ph) / om}


## The two routes to the time on AB. With `whole`, a turn's length, they go on to the rest of it.
func time_methods(s: Dictionary, ans: Dictionary, whole: float = 0.0) -> Dictionary:
	var st := sweep_time(s)
	var f: Dictionary = st.f
	var out := {}
	var routes := {"multiply-factor": [[half_line(s), rad_line(f), "%s Time = %s ÷ (%s) = " % [rate_step(s), w(f.rad), rate_rad(s)]], st.by_rad],
		"fraction-of-turn": [[half_line(s), share_line(f)] + period_step(s) + ["%s × %s = " % [w(f.share), w(period_shown(s))]], st.by_share]}
	for name in routes:
		var steps: Array = routes[name][0]
		var x: float = routes[name][1]
		if whole > 0.0:
			steps[-1] += w(x)
			steps.append("The rest of the turn: %s − %s = %s" % [w(whole), w(x), end(whole - x)])
		else:
			steps[-1] += end(x)
		out[name] = method(steps + [say(ans)], ans.values)
	return out


func u_chord_time(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var sl := sweep_slips(s)
	var ans := num("time = ", sl.t, " s")
	var c := sweep(s)
	var out := frame(chord_stem(rep, s), "Find the time its %s spends on the stretch AB of the %s in each turn." % [c.ray, c.line] + SF, ans)
	out.wrongs = slip(sl.half, R_HALF) + slip(sl.sine, R_SINE) + slip(sl.deg, R_MIXED)
	out.generic = rest([sl.t * 2.0, sl.t * 3.0, sl.t * 1.5])
	out.methods = time_methods(s, ans)
	return out


func u_chord_time_rpm(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var sl := sweep_slips(s)
	var ans := num("time = ", sl.t, " s")
	var c := sweep(s)
	var out := frame(chord_stem(rep, s), "Find the time its %s spends on the stretch AB of the %s in each turn, in seconds." % [c.ray, c.line] + SF, ans)
	out.wrongs = slip(sl.half, R_HALF) + slip(sl.sine, R_SINE) + slip(sl.t / 60.0, R_PER_MINUTE)
	out.generic = rest([sl.t * 2.0, sl.t * 3.0, sl.t * 1.5])
	out.methods = time_methods(s, ans)
	return out


func u_chord_time_degrees(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var sl := sweep_slips(s)
	var ans := num("time = ", sl.t, " s")
	var c := sweep(s)
	var out := frame(chord_stem(rep, s), "Find the time its %s spends on the stretch AB of the %s in each turn." % [c.ray, c.line] + SF, ans)
	out.wrongs = slip(sl.half, R_HALF) + slip(sl.sine, R_SINE) + slip(2.0 * CircularMotionSituation.phi(s) / s.k, R_MIXED)
	out.generic = rest([sl.t * 2.0, sl.t * 3.0, sl.t * 1.5])
	out.methods = time_methods(s, ans)
	return out


func u_dark_time(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var sl := sweep_slips(s)
	var T := float(s.T)
	var x: float = T - sl.t
	var ans := num("time = ", x, " s")
	var c := sweep(s)
	var out := frame(chord_stem(rep, s), "Find the time in each turn for which its %s is not on the stretch AB of the %s." % [c.ray, c.line] + SF, ans)
	out.wrongs = slip(sl.t, R_REST) + slip(T - sl.half, R_HALF) + slip(T - sl.sine, R_SINE)
	out.generic = rest([x / 2.0, T + sl.t, x * 1.5])
	out.methods = time_methods(s, ans, T)
	return out


func u_fraction_in_view(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var ph := CircularMotionSituation.phi(s)
	var x := ph / PI
	var ans := num("fraction = ", x, "")
	var c := sweep(s)
	var out := frame(chord_stem(rep, s), "Find the fraction of each turn for which its %s is on the stretch AB of the %s." % [c.ray, c.line] + SF, ans)
	out.wrongs = slip(2.0 * ph / PI, R_PI_TURN) + slip(ph / TAU, R_HALF) + slip(2.0 * ph / 360.0, R_MIXED) + slip(CircularMotionSituation.phi_sin(s) / PI, R_SINE)
	out.generic = rest([1.0 - x, x * 3.0, x * 1.5])
	var f := chord_figures(s)
	chains.append(f.share)
	out.methods = {"multiply-factor": method([half_line(s), rad_line(f), "Fraction = %s ÷ 2π = %s" % [w(f.rad), end(f.rad / TAU)], say(ans)], ans.values),
		"fraction-of-turn": method([half_line(s), share_line(f), say(ans)], ans.values)}
	return out


func u_arc_past_line(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var ph := CircularMotionSituation.phi(s)
	var rr: float = s.r.to_float()
	var x := 2.0 * rr * ph
	var ans := num("arc = ", x, " m")
	var c := sweep(s)
	var out := frame(chord_stem(rep, s), "Find the length of the shorter arc AB, on the far side of the %s from O." % c.line + SF, ans)
	out.wrongs = slip(rr * rad_to_deg(2.0 * ph), R_MIXED) + slip(rr * ph, R_HALF) + slip(2.0 * rr * CircularMotionSituation.phi_sin(s), R_SINE)
	out.generic = rest([x * 2.0, TAU * rr - x, x * 1.5])
	var f := chord_figures(s)
	var r := D(s.r)
	var whole := rd(TAU * rr)
	out.methods = {"multiply-factor": method([half_line(s), rad_line(f), "l = rθ = %s × %s = %s" % [r, w(f.rad), end(rr * f.rad)], say(ans)], ans.values),
		"fraction-of-turn": method([half_line(s), share_line(f), "The whole circle is 2π × %s = %s m." % [r, w(whole)], "%s × %s = %s" % [w(f.share), w(whole), end(f.share * whole)], say(ans)], ans.values)}
	return out


func u_distance_from_time(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var tau: float = s.tau.to_float()
	var T := float(s.T)
	var half := PI * tau / T
	var rr: float = s.r.to_float()
	var x := rr * cos(half)
	var ans := num("distance = ", x, " m")
	var c := sweep(s)
	var t := D(s.tau)
	var lines: Array
	var graph: Variant = null
	if rep == "diagram":
		lines = ["%s at O turns steadily. The diagram shows the circle its %s reaches and a straight %s, which meets the circle at A and B." % [c.thing, c.ray, c.line]]
		graph = {"kind": "region", "shape": "sweep", "r": rr, "d": x, "r_label": metres(D(s.r)), "d_label": "?", "line": c.line, "mark": "", "angle_label": "", "nearest": false}
	else:
		lines = ["%s at O turns steadily. Its %s reaches %s, and a straight %s meets the edge of that circle at A and B." % [c.thing, c.ray, metres(D(s.r)), c.line]]
	lines.append("It makes one full turn every %d seconds, and its %s is on the stretch AB for %s seconds in each turn." % [s.T, c.ray, t])
	var out := frame({"lines": lines, "graph": graph}, "Find the distance from O to the %s." % c.line + SF, ans)
	out.wrongs = slip(rr * cos(2.0 * half), R_WHOLE) + slip(rr * sin(half), R_SINE) + slip(rr * cos(deg_to_rad(half)), R_MIXED)
	out.generic = rest([x / 2.0, x * 1.5, rr - x])
	var deg := rd(tau * 360.0 / T)
	var radians := rd(deg_to_rad(deg))
	var share := rd(tau / T)
	var ang := rd(share * TAU)
	var r := D(s.r)
	out.methods = {"multiply-factor": method(["Angle AOB = %s ÷ %d × 360 = %s°." % [t, s.T, w(deg)], "Multiply by π/180: %s × π/180 = %s radians." % [w(deg), w(radians)],
		"The perpendicular halves it, so the distance is %s cos(%s ÷ 2) = %s" % [r, w(radians), end(rr * cos(radians / 2.0))], say(ans)], ans.values),
		"fraction-of-turn": method(["%s seconds is %s/%d = %s of a turn." % [t, t, s.T, w(share)], "A full turn is 2π: %s × 2π = %s radians." % [w(share), w(ang)],
			"The perpendicular halves it, so the distance is %s cos(%s ÷ 2) = %s" % [r, w(ang), end(rr * cos(ang / 2.0))], say(ans)], ans.values)}
	return out


# ── A rotor ──────────────────────────────────────────────────

func u_arc_in_time(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var tau: float = s.tau.to_float()
	var T := float(s.T)
	var rr: float = s.r.to_float()
	var th := TAU * tau / T
	var x := rr * th
	var ans := num("distance = ", x, " m")
	var c := rotor(s)
	var t := D(s.tau)
	var v := rotor_stem(rep, s)
	var tip: String = c.tip
	if rep == "diagram":
		v.lines = v.lines + ["The diagram shows %s moving from A to B along the circle in %s seconds." % [tip, t]]
		v.graph = turn_figure(th, "", {"r_label": metres(D(s.r))})
	var out := frame(v, "Find the distance %s moves in %s seconds." % [tip, t] + SF, ans)
	out.wrongs = slip(rr * rad_to_deg(th), R_MIXED) + slip(x / 2.0, R_PI_TURN) + slip(TAU * rr, R_NO_TIME)
	out.generic = rest([x * 2.0, x * 1.5, th])
	var deg := rd(tau * 360.0 / T)
	var radians := rd(deg_to_rad(deg))
	var whole := rd(TAU * rr)
	var r := D(s.r)
	out.methods = {"multiply-factor": method(["In %s seconds it turns %s × 360 ÷ %d = %s°." % [t, t, s.T, w(deg)], "Multiply by π/180: %s × π/180 = %s radians." % [w(deg), w(radians)], "l = rθ = %s × %s = %s" % [r, w(radians), end(rr * radians)], say(ans)], ans.values),
		"fraction-of-turn": method(["A full turn is 2π × %s = %s m." % [r, w(whole)], "%s seconds is %s/%d of a turn: %s/%d × %s = %s" % [t, t, s.T, t, s.T, w(whole), end(tau / T * whole)], say(ans)], ans.values)}
	return out


func u_rim_speed(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var T := float(s.T)
	var rr: float = s.r.to_float()
	var x := TAU * rr / T
	var ans := num("speed = ", x, " m/s")
	var c := rotor(s)
	var out := frame(rotor_stem(rep, s), "Find the speed of %s." % c.tip + SF, ans)
	out.wrongs = slip(TAU * rr, R_NO_TIME) + slip(PI * rr / T, R_PI_TURN) + slip(rr * 360.0 / T, R_MIXED)
	out.generic = rest([x * 2.0, x * 1.5, TAU * T / rr])
	var r := D(s.r)
	var whole := rd(TAU * rr)
	out.methods = {"multiply-factor": method([rate_step(s), "In one second it moves l = rθ = %s × %s = %s" % [r, rate_rad(s), end(x)], say(ans)], ans.values),
		"fraction-of-turn": method(["A full turn is 2π × %s = %s m." % [r, w(whole)], "One second is 1/%d of a turn: %s ÷ %d = %s" % [s.T, w(whole), s.T, end(whole / T)], say(ans)], ans.values)}
	return out


func u_rim_speed_rpm(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var rr: float = s.r.to_float()
	var x: float = TAU * rr * s.n / 60.0
	var ans := num("speed = ", x, " m/s")
	var c := rotor(s)
	var out := frame(rotor_stem(rep, s), "Find the speed of %s, in metres per second." % c.tip + SF, ans)
	out.wrongs = slip(TAU * rr * s.n, R_PER_MINUTE) + slip(PI * rr * s.n / 60.0, R_PI_TURN) + slip(TAU * rr, R_NO_TIME)
	out.generic = rest([x * 2.0, x * 1.5, rr * 6.0 * s.n])
	var r := D(s.r)
	var whole := rd(TAU * rr)
	out.methods = {"multiply-factor": method([rate_step(s), "In one second it moves l = rθ = %s × %s = %s" % [r, rate_rad(s), end(x)], say(ans)], ans.values),
		"fraction-of-turn": method(["A full turn is 2π × %s = %s m." % [r, w(whole)], "Each second it makes %d/60 of a turn: %d/60 × %s = %s" % [s.n, s.n, w(whole), end(float(s.n) / 60.0 * whole)], say(ans)], ans.values)}
	return out
