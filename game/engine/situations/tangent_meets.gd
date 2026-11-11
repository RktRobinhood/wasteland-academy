class_name TangentMeetsSituation
extends RefCounted
## The `tangent-meets-curve` situation (curriculum/question-types.json): a curve y = f(x), a
## point P on it where x = x₀, and the tangent or the normal there (SL5.4, FAL-754). The line
## is followed to where it meets the axes, to the triangle it cuts off with them, or to where it
## meets the curve again. Every bank part is Paper 2, so every question is.
##
## The curve is one of four families:
##   "quad"   ax² + bx + c                      exact: every value a fraction
##   "cubic"  ax³ + bx² + cx + d                exact: the tangent's double root gives Q
##   "recip"  px² + A/x + q, for x ≠ 0          exact for the tangent (x times it is a cubic)
##   "exp"    Ae^(kx) + px² + q                  a GDC curve: values are floats, to 3 s.f.
##
## need.ask is the unknown, need.rep the representation, need.fams the families it allows.
## generate() returns a Dictionary:
##   paper, ask, rep        2; the unknown; the representation
##   fam, f                 the family and its coefficients (Q)
##   exact                  P, the gradient and the line are Q (else floats)
##   sf                     the answer is to 3 s.f. (every "exp" curve, and every meets-again found
##                          by the GDC); else it is exact
##   line                   "tangent" or "normal"
##   x0, y0, m              P and f′(x₀)
##   lm, lc                 the line asked about: y = lm x + lc
##   xa, yb                 where it meets the x-axis and the y-axis
##   area                   the triangle OAB
##   qx, qy                 where it meets the curve again
##   slip                   (meets-again) the x of a slip, if any
##
## The clean limits below are the numbers behind the catalogue's `clean` text. The SymPy
## checker (tools/check_answers.py, E12NM_) holds its own copy and fails on any breach.

const TRIES := 6000
## The x-range a GDC scan of an e^(kx) curve covers: past it e^(kx) or the x² term rules.
const SCAN := 60.0
const SCAN_STEPS := 2400
## A point found is at least this far from P.
const GAP := 0.5
## For an intercept or an area, P is at least this far from the x-axis (and x₀ ≠ 0).
const P_OFF_AXIS := 0.5
## Every marked point is inside |x| ≤ X_MAX and |y| ≤ Y_MAX, so the figure stays readable.
const X_MAX := 12.0
const Y_MAX := 100.0
## |f′(x₀)| is at most this for a tangent, NORMAL_MAX for a normal (its gradient is −1/m).
const M_MAX := 12
const NORMAL_MAX := 8
## An e^(kx) curve's gradient at P is at least this in size.
const EXP_M_MIN := 0.2
const FAMS := {
	"tangent-x-intercept": ["quad", "cubic", "exp"], "tangent-y-intercept": ["quad", "cubic", "exp"],
	"normal-x-intercept": ["quad", "cubic", "exp"], "normal-y-intercept": ["quad", "cubic", "exp"],
	"tangent-triangle-area": ["quad", "cubic", "exp"], "normal-triangle-area": ["quad", "cubic", "exp"],
	"tangent-meets-again": ["cubic", "recip"], "tangent-meets-again-gdc": ["exp"], "normal-meets-again": ["quad", "exp"],
}


static func generate(rng: Seeded, need: Dictionary = {}) -> Dictionary:
	var ask: String = need.get("ask", "tangent-x-intercept")
	var rep: String = need.get("rep", "equation")
	var fams: Array = need.get("fams", FAMS.get(ask, ["quad"]))
	for i in TRIES:
		var fam: String = fams[rng.int_in(0, fams.size() - 1)]
		var s := {"paper": 2, "ask": ask, "rep": rep, "fam": fam, "exact": fam != "exp", "sf": fam == "exp",
			"line": "normal" if ask.begins_with("normal") else "tangent"}
		if _build(rng, s):
			return s
	push_error("TangentMeetsSituation: no clean situation for %s" % ask)
	return {}


# ── The curve ────────────────────────────────────────────────

## f at x, as a float (any family).
static func fv(s: Dictionary, x: float) -> float:
	var f: Dictionary = s.f
	match s.fam:
		"quad":
			return f.a.to_float() * x * x + f.b.to_float() * x + f.c.to_float()
		"cubic":
			return ((f.a.to_float() * x + f.b.to_float()) * x + f.c.to_float()) * x + f.d.to_float()
		"recip":
			return f.p.to_float() * x * x + f.A.to_float() / x + f.q.to_float()
	return f.A.to_float() * exp(f.k.to_float() * x) + f.p.to_float() * x * x + f.q.to_float()


static func dfv(s: Dictionary, x: float) -> float:
	var f: Dictionary = s.f
	match s.fam:
		"quad":
			return 2.0 * f.a.to_float() * x + f.b.to_float()
		"cubic":
			return 3.0 * f.a.to_float() * x * x + 2.0 * f.b.to_float() * x + f.c.to_float()
		"recip":
			return 2.0 * f.p.to_float() * x - f.A.to_float() / (x * x)
	return f.A.to_float() * f.k.to_float() * exp(f.k.to_float() * x) + 2.0 * f.p.to_float() * x


## f at x, exactly (not "exp").
static func fq(s: Dictionary, x: Variant) -> Q:
	var f: Dictionary = s.f
	var X := Q.of(x)
	match s.fam:
		"quad":
			return f.a.mul(X).mul(X).add(f.b.mul(X)).add(f.c)
		"cubic":
			return f.a.mul(X).add(f.b).mul(X).add(f.c).mul(X).add(f.d)
	return f.p.mul(X).mul(X).add(f.A.div(X)).add(f.q)


static func dfq(s: Dictionary, x: Variant) -> Q:
	var f: Dictionary = s.f
	var X := Q.of(x)
	match s.fam:
		"quad":
			return f.a.mul(2).mul(X).add(f.b)
		"cubic":
			return f.a.mul(3).mul(X).mul(X).add(f.b.mul(2).mul(X)).add(f.c)
	return f.p.mul(2).mul(X).sub(f.A.div(X.mul(X)))


## A value as a float, whether it is a Q or a float.
static func fl(v: Variant) -> float:
	return v.to_float() if v is Q else float(v)


static func _coeffs(rng: Seeded, s: Dictionary) -> void:
	match s.fam:
		"quad":
			s.f = {"a": Q.new(rng.pick([-3, -2, -1, 1, 2, 3])), "b": Q.new(rng.int_in(-8, 8)), "c": Q.new(rng.int_in(-9, 9))}
			s.x0 = rng.int_in(-4, 4)
		"cubic":
			s.f = {"a": Q.new(rng.pick([-2, -1, 1, 2])), "b": Q.new(rng.int_in(-6, 6)), "c": Q.new(rng.int_in(-12, 12)), "d": Q.new(rng.int_in(-9, 9))}
			s.x0 = rng.int_in(-3, 3)
		"exp":
			var k: int = rng.int_in(2, 10) * rng.pick([1, -1])
			s.f = {"A": Q.new(rng.pick([-3, -2, -1, 1, 2, 3])), "k": Q.new(k, 10), "p": Q.new(rng.pick([-4, -2, -1, 1, 2, 4]), 2),
				"q": Q.new(rng.int_in(-9, 9))}
			s.x0 = rng.int_in(-3, 3)


## The cubic or reciprocal curve built backwards from P and Q, so that the tangent at P meets
## it again at a whole-number Q: (x − x₀)²(x − Q) is a factor of the curve minus the tangent.
static func _backwards(rng: Seeded, s: Dictionary) -> bool:
	var x0 := rng.int_in(-3, 3)
	var xq := rng.int_in(-5, 5)
	if s.fam == "recip":
		x0 = rng.pick([-3, -2, -1, 1, 2, 3])
		xq = rng.int_in(-4, 4)
		var p: int = rng.pick([-2, -1, 1, 2])
		var A := -p * x0 * x0 * xq
		# The slip's x, x₀ + Q, is a point of the curve too.
		if xq == 0 or xq == x0 or x0 + xq == 0 or absi(A) > 54:
			return false
		s.f = {"p": Q.new(p), "A": Q.new(A), "q": Q.new(rng.int_in(-9, 9))}
	else:
		var a: int = rng.pick([-2, -1, 1, 2])
		var b := -a * (2 * x0 + xq)
		if xq == x0 or absi(b) > 12:
			return false
		s.f = {"a": Q.new(a), "b": Q.new(b), "c": Q.new(rng.int_in(-12, 12)), "d": Q.new(rng.int_in(-9, 9))}
	s.x0 = x0
	s.qx = Q.new(xq)
	return true


static func _build(rng: Seeded, s: Dictionary) -> bool:
	if s.ask == "tangent-meets-again":
		if not _backwards(rng, s):
			return false
	else:
		_coeffs(rng, s)
	if not _line(s):
		return false
	match s.ask:
		"tangent-x-intercept", "tangent-y-intercept", "normal-x-intercept", "normal-y-intercept":
			return _intercepts(s, false)
		"tangent-triangle-area", "normal-triangle-area":
			return _intercepts(s, true)
	return _again(s)


## P, the gradient there and the line asked about.
static func _line(s: Dictionary) -> bool:
	var x0: int = s.x0
	if s.exact:
		s.y0 = fq(s, x0)
		s.m = dfq(s, x0)
		var m: Q = s.m
		if m.is_zero() or absf(m.to_float()) > (NORMAL_MAX if s.line == "normal" else M_MAX):
			return false
		s.lm = m if s.line == "tangent" else Q.new(-1).div(m)
		s.lc = s.y0.sub(s.lm.mul(x0))
		return absf(fl(s.y0)) <= Y_MAX
	s.y0 = fv(s, x0)
	s.m = dfv(s, x0)
	var mf: float = s.m
	if absf(mf) < EXP_M_MIN or absf(mf) > M_MAX or not GdcKit.fair(s.y0) or absf(s.y0) > Y_MAX:
		return false
	s.lm = mf if s.line == "tangent" else -1.0 / mf
	s.lc = s.y0 - s.lm * x0
	return true


## The line's intercepts, both off the origin, and for an area on opposite sides of it, so
## that one length comes from a negative number.
static func _intercepts(s: Dictionary, area: bool) -> bool:
	# P is off both axes, so it is never A or B itself.
	if s.x0 == 0 or absf(fl(s.y0)) < P_OFF_AXIS:
		return false
	if s.exact:
		s.yb = s.lc
		if s.yb.is_zero():
			return false
		s.xa = s.lc.neg().div(s.lm)
		s.area = s.xa.mul(s.yb).abs_q().div(2)
	else:
		s.yb = s.lc
		if absf(s.yb) < 0.05:
			return false
		s.xa = -s.lc / s.lm
		s.area = absf(s.xa * s.yb) / 2.0
	var xa := fl(s.xa)
	var yb := fl(s.yb)
	if absf(xa) < 0.05 or absf(xa) > X_MAX or absf(yb) > Y_MAX:
		return false
	if area and xa * yb > 0.0:
		return false
	if not s.exact:
		var asked: float = s.area if area else (xa if s.ask.ends_with("x-intercept") else yb)
		if not GdcKit.fair(asked):
			return false
	return true


## Where the line meets the curve again, and the x of the double-root slip.
static func _again(s: Dictionary) -> bool:
	var x0: int = s.x0
	if s.ask == "tangent-meets-again":
		# Built backwards: Q is a whole number.
		var g := fq(s, s.qx).sub(s.lm.mul(s.qx).add(s.lc))
		assert(g.is_zero(), "Q is not on the tangent")
		s.qy = fq(s, s.qx)
		s.slip = s.qx.add(x0)
		if absf(fl(s.qy)) > Y_MAX or absf(fl(fq(s, s.slip))) > 4.0 * Y_MAX:
			return false
		return true
	var others := meets(s, fl(s.lm), fl(s.lc))
	if others.size() != 1:
		return false
	var xq: float = others[0]
	if absf(xq - x0) < GAP or absf(xq) > X_MAX:
		return false
	var yq := fv(s, xq)
	if absf(yq) > Y_MAX or not GdcKit.fair(xq) or not GdcKit.fair(yq):
		return false
	s.qx = xq
	s.qy = yq
	s.sf = true
	return Fmt.sf(xq) != Fmt.sf(float(x0)) or Fmt.sf(yq) != Fmt.sf(fl(s.y0))


## The x-values other than P's where the line y = lm x + lc meets the curve, in order. A
## parabola's comes from the sum of the roots; an e^(kx) curve's from a scan for sign changes.
## Curve minus line then has a third derivative Ak³e^(kx) that is never 0, so it has at most
## three roots, counted with their multiplicity: the signs at the scan's two ends must agree with
## the number of crossings found (an odd number of roots changes the sign end to end).
static func meets(s: Dictionary, lm: float, lc: float) -> Array:
	var x0: int = s.x0
	if s.fam == "quad":
		var f: Dictionary = s.f
		var a: float = f.a.to_float()
		var other: float = -(f.b.to_float() - lm) / a - x0
		return [] if absf(other - x0) < 1e-9 else [other]
	var g := func(x: float) -> float: return fv(s, x) - (lm * x + lc)
	var out: Array = []
	for r in GdcKit.zeros(g, -SCAN, SCAN, SCAN_STEPS):
		if absf(r - x0) > 1e-6:
			out.append(r)
	# The tangent touches at P, so curve minus tangent doesn't change sign there; the normal
	# crosses there.
	var touching: bool = absf(lm - dfv(s, x0)) < 1e-12
	var crossings := out.size() + (0 if touching else 1)
	var ends_differ: bool = signf(g.call(-SCAN)) != signf(g.call(SCAN))
	if ends_differ != (crossings % 2 == 1):
		return [-INF, INF]
	return out


static func export(s: Dictionary) -> Dictionary:
	return ExtensionViews.export(s)
