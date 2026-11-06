class_name ProveIdentitySituation
extends RefCounted
## The `prove-identity` situation (curriculum/question-types.json): one trig identity to prove,
## for t3-prove-identity (FAL-753). Every question is Paper 1, as every bank part is. A proof
## can't be marked as free text, so each unknown asks one thing a proof turns on, and code works
## that out: ProveIdentityViews builds every line of the proof from the numbers here. The SymPy
## checker proves each line again. Only SL identities are used: sin²x + cos²x = 1, tan x = sin x/cos x,
## sin 2x and the three forms of cos 2x. So no sec, cosec or cot, and no sin 3x.
##
## need.ask is the unknown, need.rep the representation and need.angle the method. The shape of
## the statement, `fam`, is drawn from what they allow (ASKS), and is, with u = wx:
##   half-tan       k(1 − cos 2u)/sin 2u ≡ k tan u
##   half-tan-plus  k sin 2u/(1 + cos 2u) ≡ k tan u
##   product        n sin u cos u ≡ (n/2) sin 2u                        n, not k
##   double-twice   4k sin u cos u cos 2u ≡ k sin 4u
##   square         k(sin u ± cos u)² ≡ k(1 ± sin 2u)                   minus
##   quartic-diff   k(cos⁴u − sin⁴u) ≡ k cos 2u                         flip swaps sin and cos
##   quartic-sin    4k(sin²u − sin⁴u) ≡ k sin²2u                        base
##   reciprocal-sum k(sin u/cos u + cos u/sin u) ≡ 2k/sin 2u
##   tan-diff       k cos²u(1 − tan²u) ≡ k cos 2u
##   tan-ratio      k(1 − tan²u)/(1 + tan²u) ≡ k cos 2u
##   tan-double     k tan u(1 + cos 2u) ≡ k sin 2u
##   factor-sum     k(sin 2u + 1 ∓ cos 2u) ≡ 2k sin u(cos u + sin u)    base
##   perfect-square k(1 ∓ 2 cos 2u + cos²2u) ≡ 4k sin⁴u                 base
##   split          k(sin 2u + 2 sin²u)/(2 sin u) ≡ k(cos u + sin u)    base
## base is "sin" for the forms above, "cos" for the same with sin and cos swapped and the ∓ a plus.
##
## generate() returns those with paper, ask, rep, fam, k, w and letter, and for some asks:
##   t        identity-value: x = tπ
##   r        value-from-ratio: the ratio given, of `given` (tan u, sin 2u or cos 2u)
##   want, c  greatest-value: "greatest" or "least", and a number added
##   swap     start-side: the statement is written with its sides swapped
## No statement here is an exam's or the map's example: see exam_like().

const TRIES := 400
## w: x, 2x or 4x inside, so 2u is 2x, 4x or 8x. 3x would look like it wants sin 3x.
const MULTS := [1, 2, 4]
const LETTERS := ["x", "x", "θ"]
const KS := [1, 6]
const NS := [3, 9]
## Angles x where sin, cos or tan of a multiple of x is a landmark.
const TIMES := [[1, 6], [1, 4], [1, 3], [2, 3], [3, 4], [5, 6]]
const RATIOS := [[1, 2], [1, 3], [2, 3], [1, 4], [3, 4], [1, 5], [2, 5], [3, 5], [4, 5], [5, 6], [2, 7], [3, 7]]
const TANS := [[1, 2], [2, 3], [3, 2], [3, 4], [4, 3], [2, 5], [5, 2], [1, 3], [3, 1], [2, 1], [5, 3]]

const COMPLEX := ["half-tan", "half-tan-plus", "product", "double-twice", "square", "factor-sum"]
const CONVERT := ["half-tan", "half-tan-plus", "reciprocal-sum", "tan-diff", "tan-ratio", "tan-double"]
const FACTOR := ["quartic-diff", "quartic-sin", "perfect-square", "factor-sum", "split"]
const TYPED_FACTOR := ["quartic-diff", "quartic-sin", "perfect-square"]
const WAVES := ["half-tan", "half-tan-plus", "product", "double-twice", "quartic-diff", "tan-diff", "tan-ratio", "tan-double"]
## ask -> method -> the statements it can be asked on.
const ASKS := {
	"simplified-result": {"complex-side": ["half-tan", "half-tan-plus", "product", "double-twice", "square"], "sin-cos-convert": CONVERT, "factorise-structure": TYPED_FACTOR},
	"next-line": {"complex-side": COMPLEX, "sin-cos-convert": CONVERT, "factorise-structure": FACTOR},
	"missing-line": {"complex-side": COMPLEX, "sin-cos-convert": CONVERT, "factorise-structure": FACTOR},
	"flawed-line": {"complex-side": COMPLEX, "sin-cos-convert": CONVERT, "factorise-structure": FACTOR},
	"valid-argument": {"complex-side": ["half-tan", "half-tan-plus", "product", "double-twice", "square", "factor-sum", "reciprocal-sum", "tan-diff", "tan-ratio",
		"tan-double", "quartic-diff", "quartic-sin", "perfect-square", "split"]},
	"start-side": {"complex-side": ["half-tan", "half-tan-plus", "product", "double-twice", "square", "reciprocal-sum", "tan-diff", "tan-ratio",
		"tan-double", "quartic-diff", "quartic-sin", "perfect-square", "split"]},
	"true-identity": {"complex-side": COMPLEX, "sin-cos-convert": CONVERT},
	"cos2-form": {"sin-cos-convert": ["half-tan", "half-tan-plus", "factor-sum", "perfect-square"]},
	"half-form": {"sin-cos-convert": ["half-tan", "half-tan-plus"]},
	"sin2-multiple": {"sin-cos-convert": ["product"]},
	"cancel-fraction": {"factorise-structure": ["split"]},
	"factor-structure": {"factorise-structure": TYPED_FACTOR},
	"identity-value": {"complex-side": WAVES + ["square"]},
	"value-from-ratio": {"complex-side": ["square"], "sin-cos-convert": ["half-tan", "half-tan-plus", "reciprocal-sum"], "factorise-structure": ["quartic-diff", "quartic-sin"]},
	"greatest-value": {"complex-side": ["product", "double-twice", "square"], "factorise-structure": ["quartic-diff", "quartic-sin"]},
	"common-expression": {"complex-side": ["quartic-diff", "tan-diff"]},
}
## The statements that read as a sentence.
const IN_WORDS := ["product", "square", "quartic-diff", "tan-double"]


static func generate(rng: Seeded, need: Dictionary = {}) -> Dictionary:
	var ask: String = need.get("ask", "simplified-result")
	var rep: String = need.get("rep", "equation")
	var fams := allowed(ask, rep, need.get("angle", ""))
	for i in TRIES:
		var s := {"paper": 1, "ask": ask, "rep": rep, "fam": rng.pick(fams)}
		if _draw(rng, s):
			return s
	return {}


## The statements an ask can be on. With no method (a family's shared situation) they are
## those of every method of the ask.
static func allowed(ask: String, rep: String, angle: String) -> Array:
	var by_method: Dictionary = ASKS[ask]
	var out: Array = []
	if by_method.has(angle):
		out = by_method[angle].duplicate()
	else:
		for list in by_method.values():
			out.append_array(list.filter(func(f): return not f in out))
	return out.filter(func(f): return rep != "words" or f in IN_WORDS)


## Whether a method's chain is the one a statement takes.
static func suits(ask: String, angle: String, fam: String) -> bool:
	return fam in ASKS[ask].get(angle, [])


static func _draw(rng: Seeded, s: Dictionary) -> bool:
	s.k = rng.int_in(KS[0], KS[1])
	s.w = rng.pick(MULTS)
	s.letter = rng.pick(LETTERS)
	match s.fam:
		"product":
			s.n = rng.int_in(NS[0], NS[1])
		"double-twice":
			s.w = rng.pick([1, 2])
		"square":
			s.minus = rng.chance(0.5)
		"quartic-diff":
			s.flip = s.ask != "common-expression" and rng.chance(0.3)
		"quartic-sin", "factor-sum", "perfect-square", "split":
			s.base = rng.pick(["sin", "cos"])
	if exam_like(s):
		return false
	match s.ask:
		"start-side":
			s.swap = rng.chance(0.5)
		"identity-value":
			return _identity_value(rng, s)
		"value-from-ratio":
			_value_from_ratio(rng, s)
		"greatest-value":
			s.want = rng.pick(["greatest", "least"])
			s.c = rng.int_in(-5, 9)
	return true


## The exam's or the map's own statements, left out: k = 1 and w = 1 on these shapes.
static func exam_like(s: Dictionary) -> bool:
	if s.k != 1 or s.w != 1:
		return false
	return s.fam in ["half-tan", "half-tan-plus"] or (s.fam == "quartic-diff" and not s.flip)


static func _identity_value(rng: Seeded, s: Dictionary) -> bool:
	var at: Array = rng.pick(TIMES)
	s.t = Q.new(at[0], at[1])
	var v := ProveIdentityViews.right_value(s, s.t)
	return not v.is_empty() and not TrigKit.is_zero(v) and ProveIdentityViews.defined(s, s.t)


static func _value_from_ratio(rng: Seeded, s: Dictionary) -> void:
	var pair: Array = rng.pick(RATIOS)
	s.given = "sin"
	match s.fam:
		"half-tan", "half-tan-plus":
			s.given = "tan"
			pair = rng.pick(TANS)
		"quartic-diff":
			s.given = "cos"
	s.r = Q.new(pair[0], pair[1]) if rng.chance(0.75) else Q.new(-pair[0], pair[1])


static func export(s: Dictionary) -> Dictionary:
	return ExtensionViews.export(s)
