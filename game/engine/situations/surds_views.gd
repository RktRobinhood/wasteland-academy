class_name SurdsViews
extends ExtensionViews
## The views on the `fn-pre-surds` situation: one builder per unknown of fn-pre-surds
## (FAL-459). Answers are in simplest surd form, the surd kind m√r (r with no square
## factor) or h ± m√r, and a surd written as one root is √n.

const REF_SUM_UNDER_ROOT := "fn-pre-surds#0"
const REF_ONE_TERM := "fn-pre-surds#1"
const REF_STOPS_EARLY := "fn-pre-surds#2"


func needs() -> Dictionary:
	return {
		"simplify-root": {"form": "simplify"},
		"add-like-surds": {"form": "add"},
		"multiply-surds": {"form": "multiply"},
		"formula-fraction": {"form": "fraction"},
		"surd-to-root": {"form": "toroot"},
	}


func extra() -> Dictionary:
	return {"simplify-root": ["error-spot"]}


# ── Helpers ──────────────────────────────────────────────────

static func root(n: Variant) -> String:
	return "√" + N(n)


static func surd(m: Variant, r: Variant) -> String:
	return Answer.surd_text(m, r)


## √n in simplest form, as surd values {m, r}.
static func simplest(n: int) -> Dictionary:
	var sq := SurdsSituation.largest_square(n)
	return {"m": Q.new(roundi(sqrt(float(sq)))), "r": Q.new(n / sq)}


static func surd_answer(a: Q, b: Q) -> Dictionary:
	return Answer.make("surd", {"m": a, "r": b})


## "48 = 16 × 3, so √48 = √16 × √3 = 4√3"
static func lsf_step(n: int) -> String:
	var sq := SurdsSituation.largest_square(n)
	var v := simplest(n)
	return "The largest square factor of %d is %d: √%d = √%d × √%s = %s" % [n, sq, n, sq, N(v.r), surd(v.m, v.r)]


## "48 = 2 × 2 × 2 × 2 × 3: two pairs of 2 come out as 2 × 2 = 4, so √48 = 4√3"
static func prime_step(n: int) -> String:
	var ps := SurdsSituation.primes(n)
	var out: Array = []
	var inside: Array = []
	var i := 0
	while i < ps.size():
		if i + 1 < ps.size() and ps[i] == ps[i + 1]:
			out.append(ps[i])
			i += 2
		else:
			inside.append(ps[i])
			i += 1
	var v := simplest(n)
	var pairs := "each pair comes out once, as %s = %s" % [" × ".join(out.map(func(p): return str(p))), N(v.m)] if out.size() > 1 else "the pair of %ds comes out as %d" % [out[0], out[0]]
	return "%d = %s: %s, so √%d = %s" % [n, " × ".join(ps.map(func(p): return str(p))), pairs, n, surd(v.m, v.r)]


static func surd_generic(a: Q, b: Q) -> Array:
	return [{"m": a.add(1), "r": b}, {"m": a, "r": b.mul(2)}, {"m": a.mul(a), "r": b}, {"m": b, "r": a}, {"m": a.sub(1), "r": b}]


# ── fn-pre-surds ─────────────────────────────────────────────

func u_simplify_root(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var n: int = s.n.n
	var ans := surd_answer(s.a, s.b)
	var final := "So %s." % Answer.text(ans)
	# A smaller square factor than the largest (the slow first pass).
	var small: Array = []
	for f in range(2, s.a.n):
		if s.a.n % f == 0:
			small.append(f)
	var f: int = small[0]
	return {"asked": "Write in simplest surd form.", "lines": [root(n)], "given": {"form": "simplify", "n": s.n.key()}, "answer": ans,
		"wrongs": [wrong({"m": Q.new(f), "r": Q.new(n / (f * f))}, REF_STOPS_EARLY)],
		"generic": surd_generic(s.a, s.b),
		"methods": {
			"largest-square-factor": method([lsf_step(n), "%s has no square factor, so it is done" % N(s.b), final], ans.values),
			"prime-factorise": method([prime_step(n), final], ans.values),
			"square-check": method([lsf_step(n), "Check: (%s)² = %s × %s = %d, and %s has no square factor" % [surd(s.a, s.b), N(s.a.sq()), N(s.b), n, N(s.b)], final], ans.values),
		},
		"spot": _spot_stops_early(s, rng.pick(small))}


## A student's working that takes out a smaller square and stops (fn-pre-surds#2).
static func _spot_stops_early(s: Dictionary, f: int) -> Dictionary:
	var n: int = s.n.n
	var rest := n / (f * f)
	var part := "%s√%d" % [str(f), rest]
	var lines: Array
	var bad: int
	match (n + f) % 3:
		0:
			lines = ["√%d = √(%d × %d)" % [n, f * f, rest], "√(%d × %d) = √%d × √%d" % [f * f, rest, f * f, rest],
				"√%d × √%d = %s" % [f * f, rest, part], "So √%d in simplest form is %s" % [n, part]]
			bad = 3
		1:
			lines = ["√%d = √(%d × %d)" % [n, f * f, rest], "√(%d × %d) = %s" % [f * f, rest, part],
				"%d has no square factor" % rest, "So √%d in simplest form is %s" % [n, part]]
			bad = 2
		_:
			lines = ["√%d = √(%d × %d) = %s" % [n, f * f, rest, part], "%d has no square factor, so %s is simplest" % [rest, part],
				"So √%d = %s" % [n, part], "Check: (%s)² = %d × %d = %d" % [part, f * f, rest, n]]
			bad = 1
	return {"lines": lines, "bad": bad, "ref": REF_STOPS_EARLY,
		"why": "%d = %d × %d still has the square factor %d, so %s simplifies again to %s" % [
			rest, (s.a.n / f) * (s.a.n / f), s.b.n, (s.a.n / f) * (s.a.n / f), part, surd(s.a, s.b)]}


func u_add_like_surds(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var ans := surd_answer(s.a, s.b)
	var sum_under := simplest(s.n1.n + s.n2.n)
	var steps := ["%s = %s and %s = %s" % [root(s.n1), surd(s.a1, s.b), root(s.n2), surd(s.a2, s.b)],
		"%s + %s = (%s + %s)√%s = %s" % [surd(s.a1, s.b), surd(s.a2, s.b), N(s.a1), N(s.a2), N(s.b), surd(s.a, s.b)],
		"So %s." % Answer.text(ans)]
	return {"asked": "Simplify, giving one surd in simplest form.", "lines": ["%s + %s" % [root(s.n1), root(s.n2)]],
		"given": {"form": "add", "n1": s.n1.key(), "n2": s.n2.key()}, "answer": ans,
		"wrongs": [wrong(sum_under, REF_SUM_UNDER_ROOT)],
		"generic": [{"m": s.a1.mul(s.a2), "r": s.b}, {"m": s.a, "r": s.b.mul(2)}, {"m": Q.new(1), "r": s.n1.add(s.n2)}, {"m": s.a.add(1), "r": s.b}],
		"methods": {"largest-square-factor": method(steps, ans.values)}}


func u_multiply_surds(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var total: int = s.m.n * s.n.n
	var ans := surd_answer(s.a, s.b)
	var final := "So %s." % Answer.text(ans)
	var join := "%s × %s = √(%s × %s) = √%d" % [root(s.m), root(s.n), N(s.m), N(s.n), total]
	return {"asked": "Simplify, giving one surd in simplest form.", "lines": ["%s × %s" % [root(s.m), root(s.n)]],
		"given": {"form": "multiply", "m": s.m.key(), "n": s.n.key()}, "answer": ans,
		"generic": [{"m": Q.new(1), "r": Q.new(total)}, {"m": Q.new(1), "r": s.m.add(s.n)}] + surd_generic(s.a, s.b),
		"methods": {
			"largest-square-factor": method([join, lsf_step(total), final], ans.values),
			"prime-factorise": method([join, prime_step(total), final], ans.values),
		}}


func u_formula_fraction(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var ans := Answer.make("pm_surd", {"h": s.h, "m": s.a, "r": s.b})
	var dk: Q = s.d.mul(s.a)
	var steps := ["%s = √(%s × %s) = %s" % [root(s.n), N(dk.sq()), N(s.b), surd(dk, s.b)],
		"(%s ± %s)/%s = %s/%s ± %s/%s = %s ± %s" % [N(s.m0), surd(dk, s.b), N(s.d), N(s.m0), N(s.d), surd(dk, s.b), N(s.d), N(s.h), surd(s.a, s.b)],
		"So %s." % Answer.text(ans)]
	return {"asked": "Write in its simplest form.", "lines": ["(%s ± %s)/%s" % [N(s.m0), root(s.n), N(s.d)]],
		"given": {"form": "fraction", "m0": s.m0.key(), "n": s.n.key(), "d": s.d.key()}, "answer": ans,
		"wrongs": [wrong({"h": s.m0, "m": s.a, "r": s.b}, REF_ONE_TERM)],
		"generic": [{"h": s.h, "m": dk, "r": s.b}, {"h": s.h.neg(), "m": s.a, "r": s.b}, {"h": s.h, "m": s.a.mul(s.a), "r": s.b}, {"h": s.h, "m": s.a, "r": s.b.mul(s.d)}],
		"methods": {"largest-square-factor": method(steps, ans.values)}}


func u_surd_to_root(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var ans := Answer.make("number", {"v": s.n}, {}, "√")
	ans.exact = true
	var steps := ["%s = √%s × √%s = √(%s × %s)" % [surd(s.a, s.b), N(s.a.sq()), N(s.b), N(s.a.sq()), N(s.b)],
		"%s × %s = %s" % [N(s.a.sq()), N(s.b), N(s.n)],
		"Check: (%s)² = %s × %s = %s, the same as (%s)²" % [surd(s.a, s.b), N(s.a.sq()), N(s.b), N(s.n), root(s.n)],
		"So %s." % Answer.text(ans)]
	return {"asked": "Write as the square root of one whole number.", "lines": [surd(s.a, s.b)],
		"given": {"form": "toroot", "a": s.a.key(), "b": s.b.key()}, "answer": ans,
		"generic": [{"v": s.a.mul(s.b)}, {"v": s.a.mul(s.b.sq())}, {"v": s.a.mul(2).mul(s.b)}, {"v": s.a.add(s.b).sq()}],
		"methods": {"square-check": method(steps, ans.values)}}
