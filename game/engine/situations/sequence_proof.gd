class_name SequenceProofSituation
extends RefCounted
## The `sequence-proof` situation (curriculum/question-types.json): one claim about arithmetic and
## geometric terms, for t1-sequence-proof (FAL-753). A proof can't be marked as free text, so each
## unknown asks one thing a proof turns on, and SequenceProofViews builds every line of the proof
## from the numbers here. The SymPy checker proves each claim again, for general n.
##
## need.ask is the unknown, need.rep the representation and need.angle the method. The shape of
## the claim, `fam`, is drawn from what they allow (ASKS), and is:
##   ap-three     x, y, z are terms 1, 2 and e + 2 of an arithmetic sequence        e, l1, l2, l3
##   gp-three     x, y, z are terms 1, 1 + g and 1 + g + h of a geometric one       g, h, l1, l2, l3
##   shared-end   b, m, … and b, c, … reach w at term e + 2 and term 3              e, w
##   k-terms      three terms in k are geometric at k = k0                          k0, t1, r, c1, c2, c3
##   linked       a, a + id, a + jd are consecutive geometric terms                 i, j
##   log-geo      uₙ is geometric, A = b^p and ratio b^q, and vₙ = log_b uₙ          b, p, q
##   ap-term      uₙ = pn + q                                                       p, q
##   cubic        uₙ = (n − 1)(n − 2)(n − 3) + pn + q, equal gaps at the start only  p, q
##   sum-term     Sₙ = An² + Bn, so uₙ = Sₙ − Sₙ₋₁ = 2An + B − A                    A, B
##   sum-list     the sum of an arithmetic sequence uₙ = pn + q                     p, q
##   dot-layers   n rows of pn + q dots, built from L-shaped layers                 p, q, thing
##   dot-stairs   two staircases of m rows make a rectangle                         p, q, m, thing
##
## generate() returns those, with paper, ask, rep and fam. The clean limits are the numbers
## behind the catalogue's `clean` text. No claim here is an exam's: ap-three and gp-three never
## have evenly spaced terms, shared-end leaves out e = 1 with w = 1, and the bank's k-terms are
## left out. The checker holds its own copy of the limits.

const TRIES := 400
## Chains of lines, by the method that writes them.
const BY_DIFFERENCE := ["ap-term", "sum-term", "log-geo"]
const BY_FORMULA := ["sum-list", "linked"]
const ON_SUM := ["sum-list"]
const LINE_ASKS := {"general-difference": BY_DIFFERENCE, "series-formula": BY_FORMULA, "forwards-backwards": ON_SUM}
## ask -> method -> the claims it can be asked on.
const ASKS := {
	"arithmetic-relation": {"general-difference": ["ap-three"]},
	"geometric-relation": {"general-difference": ["gp-three"]},
	"second-term-bound": {"series-formula": ["shared-end"]},
	"common-ratio-check": {"general-difference": ["k-terms"]},
	"difference-in-a": {"series-formula": ["linked"]},
	"linked-ratio": {"series-formula": ["linked"]},
	"log-difference": {"general-difference": ["log-geo"]},
	"log-general-term": {"series-formula": ["log-geo"]},
	"constant-difference": {"general-difference": ["ap-term"]},
	"particular-terms": {"general-difference": ["cubic"]},
	"term-from-sum": {"general-difference": ["sum-term"]},
	"difference-from-sum": {"general-difference": ["sum-term"]},
	"sum-by-formula": {"series-formula": ON_SUM, "forwards-backwards": ON_SUM},
	"pair-sum": {"forwards-backwards": ON_SUM},
	"dot-total": {"dot-diagram": ["dot-layers"], "series-formula": ["dot-layers"]},
	"dot-layer": {"dot-diagram": ["dot-layers"]},
	"dot-rectangle": {"dot-diagram": ["dot-stairs"]},
	"missing-line": LINE_ASKS,
	"next-line": LINE_ASKS,
	"flawed-line": LINE_ASKS,
	"valid-proof": {"general-difference": ["ap-term", "sum-term"], "series-formula": ON_SUM, "forwards-backwards": ON_SUM},
}
const LETTERS := [["a", "b", "c"], ["x", "y", "z"], ["f", "g", "h"]]
## Steps g and h between the geometric terms. Equal steps are the exam's result.
const STEPS := [[1, 2], [1, 3], [1, 4], [2, 1], [2, 3], [3, 1], [3, 2], [4, 1]]
## Places i and j of a linked claim where d is a whole multiple of a.
const LINKS := [[1, 3], [1, 4], [1, 5], [1, 6], [2, 8], [2, 12], [3, 15]]
const BASES := {2: 4, 3: 3, 5: 2}
const RATIOS := [[2, 1], [3, 1], [4, 1], [-2, 1], [-3, 1], [1, 2], [1, 3], [-1, 2]]
const THINGS := ["rivets", "bolts", "bottle caps", "washers", "fuses"]
## The exam's three terms, left out: the coefficients and the numbers.
const KTERM_SKIP := [1, -5, -2, 3, 5, 3]


static func generate(rng: Seeded, need: Dictionary = {}) -> Dictionary:
	var ask: String = need.get("ask", "constant-difference")
	var fams := allowed(ask, need.get("angle", ""))
	for i in TRIES:
		var s := {"paper": 1, "ask": ask, "rep": need.get("rep", "equation"), "fam": rng.pick(fams)}
		if new().call("_" + str(s.fam).replace("-", "_"), rng, s):
			return s
	return {}


## The claims an ask can be on. With no method (a family's shared situation), the first method's.
static func allowed(ask: String, angle: String) -> Array:
	var by_method: Dictionary = ASKS[ask]
	return by_method.get(angle, by_method.values()[0])


## Whether a method's proof is written for a claim.
static func suits(ask: String, angle: String, fam: String) -> bool:
	return fam in ASKS[ask].get(angle, [])


static func _ap_three(rng: Seeded, s: Dictionary) -> bool:
	_letters(rng, s)
	s.e = rng.int_in(2, 5)
	return true


static func _gp_three(rng: Seeded, s: Dictionary) -> bool:
	_letters(rng, s)
	var steps: Array = rng.pick(STEPS)
	s.g = steps[0]
	s.h = steps[1]
	return true


static func _letters(rng: Seeded, s: Dictionary) -> void:
	var names: Array = rng.pick(LETTERS)
	s.l1 = names[0]
	s.l2 = names[1]
	s.l3 = names[2]


static func _shared_end(rng: Seeded, s: Dictionary) -> bool:
	s.e = rng.int_in(1, 3)
	s.w = rng.int_in(2, 12)
	return true


## Three terms in k. At k0 they are t1, t1·r and t1·r².
static func _k_terms(rng: Seeded, s: Dictionary) -> bool:
	var ratio: Array = rng.pick(RATIOS)
	var den: int = ratio[1]
	s.t1 = rng.pick([-1, 1]) * rng.int_in(1, 5) * den * den
	s.r_top = ratio[0]
	s.r_den = den
	s.k0 = rng.int_in(2, 15)
	s.c1 = ExtensionViews.nonzero(rng, -5, 5)
	s.c2 = ExtensionViews.nonzero(rng, -5, 5)
	s.c3 = ExtensionViews.nonzero(rng, -5, 5)
	var t2: int = s.t1 * s.r_top / den
	var t3: int = t2 * s.r_top / den
	s.d1 = s.t1 - s.c1 * s.k0
	s.d2 = t2 - s.c2 * s.k0
	s.d3 = t3 - s.c3 * s.k0
	if s.d1 == 0 or s.d2 == 0 or s.d3 == 0:
		return false
	return [s.c1, s.d1, s.c2, s.d2, s.c3, s.d3] != KTERM_SKIP


static func _linked(rng: Seeded, s: Dictionary) -> bool:
	var pair: Array = rng.pick(LINKS)
	s.i = pair[0]
	s.j = pair[1]
	return true


static func _log_geo(rng: Seeded, s: Dictionary) -> bool:
	s.b = rng.pick(BASES.keys())
	s.p = rng.int_in(1, 4 if s.b != 5 else 2)
	s.q = ExtensionViews.nonzero(rng, -BASES[s.b], BASES[s.b])
	return s.p != s.q


static func _ap_term(rng: Seeded, s: Dictionary) -> bool:
	s.p = ExtensionViews.nonzero(rng, -9, 9)
	s.q = ExtensionViews.nonzero(rng, -9, 9)
	return absi(s.p) >= 2 and s.p + 2 * s.q != 0


static func _cubic(rng: Seeded, s: Dictionary) -> bool:
	s.p = ExtensionViews.nonzero(rng, -6, 6)
	s.q = rng.int_in(-6, 5)
	return s.p != -6 and s.p + s.q != 0 and 2 * s.p + s.q != 0


static func _sum_term(rng: Seeded, s: Dictionary) -> bool:
	s.A = rng.int_in(1, 6)
	s.B = ExtensionViews.nonzero(rng, -9, 9)
	return s.A != s.B


static func _sum_list(rng: Seeded, s: Dictionary) -> bool:
	s.p = rng.int_in(2, 7)
	var first := rng.int_in(1, 9)
	s.q = first - s.p
	return s.q != 0 and 2 * first != s.p


static func _dot_layers(rng: Seeded, s: Dictionary) -> bool:
	s.p = rng.int_in(1, 2)
	s.q = rng.int_in(1 - s.p, 3)
	s.thing = rng.pick(THINGS)
	return true


static func _dot_stairs(rng: Seeded, s: Dictionary) -> bool:
	s.p = rng.int_in(1, 3)
	s.q = rng.int_in(1, 3) - s.p
	s.m = rng.int_in(4, 5)
	s.thing = rng.pick(THINGS)
	return true


static func export(s: Dictionary) -> Dictionary:
	return ExtensionViews.export(s)
