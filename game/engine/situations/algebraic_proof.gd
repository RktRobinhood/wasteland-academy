class_name AlgebraicProofSituation
extends RefCounted
## The `algebraic-proof` situation (curriculum/question-types.json): one statement to prove,
## for t1-algebraic-proof (FAL-728). A proof can't be marked as free text, so each unknown
## asks one thing a proof turns on, and code works that out: AlgebraicProofViews builds every
## line of the proof from the numbers here. The SymPy checker proves each claim again.
##
## need.ask is the unknown, need.rep the representation and need.angle the method. The
## shape of the statement, `fam`, is drawn from what they allow (ASKS), and is:
##   square-diff  (n + d)² − n² ≡ d(2n + d)                                d
##   sym          (px + q)² − (px − q)² ≡ 4pqx                             p, q
##   shift        (x − a)² + b ≡ x² − 2ax + a² + b                         a, b
##   combine      px + q − c/(x − d) as one fraction                       p, q, c, d
##   split        (x − a)²/x ≡ x − 2a + a²/x                               a
##   triple       x² + ((x² − k²)/(2k))² ≡ ((x² + k²)/(2k))²               k
##   reciprocal   a/n − a/(n + d) ≡ ad/(n(n + d))                          a, d
##   sym-mult     (pn + q)² − (pn − q)² is a multiple of m                 p, q, m
##   ap           the sum of c terms of an arithmetic list is a multiple of m
##                kind (integers, evens, odds, steps), c, u, v, w: the terms are un + v + iw
##                big, the sum's coefficient of n, and tail, its number; m their hcf
##   even-quad    n² + an + b is always even, for a odd and b even         a, b, part
##   product-quad n² + (2m + 1)n + m(m + 1) = (n + m)(n + m + 1)           m
##   never        a sum of squares never divisible by m                    shape, d, m, q0, r
##   pair-form    two integers each of the form mk + r                     m, r, claim, l1, l2
##
## generate() returns those, with paper, ask, rep, fam and letter (the variable). The clean
## limits are the numbers behind the catalogue's `clean` text. No statement here is an
## exam's: square-diff has d from 2, triple k from 2, and the exam's numbers for sym,
## sym-mult, combine and split are left out. The checker holds its own copy of the limits.

const TRIES := 400
const IDENTITY := ["square-diff", "sym", "shift", "combine", "split", "triple", "reciprocal"]
const FACTOR := ["square-diff", "sym"]
const COMMON := ["square-diff", "shift", "split", "triple"]
const WHOLE := ["square-diff", "sym", "shift"]
const FLAWED := ["square-diff", "sym", "shift", "combine", "split", "triple", "reciprocal", "sym-mult"]
## ask -> method -> the statements it can be asked on.
const ASKS := {
	"simplify-left-side": {"expand-simplify": IDENTITY, "factorise": FACTOR},
	"common-expression": {"common-form": COMMON},
	"missing-line": {"expand-simplify": IDENTITY, "factorise": FACTOR},
	"next-step": {"expand-simplify": IDENTITY, "factorise": FACTOR},
	"valid-proof": {"expand-simplify": WHOLE},
	"flawed-step": {"expand-simplify": FLAWED, "algebraic-form": ["sym-mult", "ap"]},
	"multiple-k": {"algebraic-form": ["sym-mult"], "factorise": ["sym-mult"]},
	"consecutive-sum": {"algebraic-form": ["ap"]},
	"greatest-divisor": {"algebraic-form": ["ap"]},
	"finish-divisibility": {"algebraic-form": ["ap"]},
	"represent-integers": {"algebraic-form": ["pair-form"]},
	"case-bracket": {"cases": ["even-quad"]},
	"consecutive-factors": {"consecutive-product": ["product-quad"]},
	"remainder-form": {"algebraic-form": ["never"]},
}
## The statements that read as a sentence about numbers.
const IN_WORDS := ["square-diff", "sym", "sym-mult", "ap", "even-quad", "product-quad", "never", "pair-form"]
## Asks whose wrong options need a leading number bigger than the sum's hcf.
const NEEDS_GAP := ["greatest-divisor", "finish-divisibility"]
## Divisors kept for sym-mult come from 4pq, without 1 and 4pq itself.
const SYM_MAX := 7
const AP_KINDS := {"integers": [3, 4, 5, 6, 7], "evens": [2, 3, 4, 5], "odds": [2, 3, 4, 5], "steps": [3, 4, 5, 6]}
const AP_STEPS := [3, 4, 5]
const NEVER_GAPS := [2, 4, 5, 7]
const PAIR_GAPS := [3, 5, 7]
const CLAIMS_ODD := ["sum-even", "product-odd"]
const CLAIMS_EVEN := ["sum-even", "product-four"]
const LETTERS := [["a", "b"], ["p", "q"], ["j", "k"], ["u", "v"]]
## The exam's own statements, left out.
const SYM_SKIP := [[2, 5], [3, 2]]


static func generate(rng: Seeded, need: Dictionary = {}) -> Dictionary:
	var ask: String = need.get("ask", "simplify-left-side")
	var rep: String = need.get("rep", "equation")
	var fams := allowed(ask, rep, need.get("angle", ""))
	for i in TRIES:
		var s := {"paper": int(need.get("paper", 1)), "ask": ask, "rep": rep, "fam": rng.pick(fams)}
		if new().call("_" + str(s.fam).replace("-", "_"), rng, s):
			return s
	return {}


## The statements an ask can be on. With no method (a family's shared situation) they
## are the ones every method of the ask works on, so each can be asked of it.
static func allowed(ask: String, rep: String, angle: String) -> Array:
	var by_method: Dictionary = ASKS[ask]
	var out: Array = []
	if by_method.has(angle):
		out = by_method[angle].duplicate()
	else:
		out = by_method.values()[0].duplicate()
		for list in by_method.values():
			out = out.filter(func(f): return f in list)
	return out.filter(func(f): return rep != "words" or f in IN_WORDS)


## Whether a method's proof is written for a statement.
static func suits(ask: String, angle: String, fam: String) -> bool:
	return fam in ASKS[ask].get(angle, [])


static func _square_diff(rng: Seeded, s: Dictionary) -> bool:
	s.letter = "n"
	s.d = rng.int_in(2, 9)
	return true


static func _sym(rng: Seeded, s: Dictionary) -> bool:
	s.letter = "x"
	s.p = rng.int_in(2, SYM_MAX)
	s.q = rng.int_in(1, SYM_MAX)
	return s.p != s.q and not [s.p, s.q] in SYM_SKIP


static func _sym_mult(rng: Seeded, s: Dictionary) -> bool:
	if not _sym(rng, s):
		return false
	s.letter = "n"
	var total: int = 4 * s.p * s.q
	var ds: Array = []
	for m in range(3, total):
		if total % m == 0:
			ds.append(m)
	if ds.is_empty():
		return false
	s.m = rng.pick(ds)
	return true


static func _shift(rng: Seeded, s: Dictionary) -> bool:
	s.letter = "x"
	s.a = rng.int_in(-8, 8)
	s.b = rng.int_in(-9, 9)
	return s.a != 0 and s.b != 0 and s.a * s.a + s.b != 0


static func _combine(rng: Seeded, s: Dictionary) -> bool:
	s.letter = "x"
	s.p = rng.int_in(1, 6)
	s.q = rng.int_in(-9, 9)
	s.c = rng.int_in(1, 15)
	s.d = rng.int_in(-6, 6)
	if s.q == 0 or s.d == 0 or (s.p == 2 and s.q == -3 and s.c == 6 and s.d == 1):
		return false
	# Every term of the single fraction is there to see.
	return s.q - s.p * s.d != 0 and s.q * s.d + s.c != 0 and s.q * s.d != s.c


static func _split(rng: Seeded, s: Dictionary) -> bool:
	s.letter = "x"
	s.a = rng.int_in(-9, 9)
	return s.a != 0 and s.a != 1


static func _triple(rng: Seeded, s: Dictionary) -> bool:
	s.letter = "x"
	s.k = rng.int_in(2, 6)
	return true


static func _reciprocal(rng: Seeded, s: Dictionary) -> bool:
	s.letter = "n"
	s.a = rng.int_in(2, 7)
	s.d = rng.int_in(2, 9)
	return true


## The sum's two numbers, with gaps counted to c − 1 (or to c, the slip).
static func ap_tail(s: Dictionary, one_more: bool = false) -> int:
	var c: int = s.c
	return c * int(s.v) + int(s.w) * (c * (c + 1) if one_more else c * (c - 1)) / 2


static func _ap(rng: Seeded, s: Dictionary) -> bool:
	s.letter = "n"
	s.kind = rng.pick(AP_KINDS.keys())
	s.c = rng.pick(AP_KINDS[s.kind])
	match s.kind:
		"integers":
			s.u = 1
			s.v = 0
		"evens":
			s.u = 2
			s.v = 0
		"odds":
			s.u = 2
			s.v = 1
		"steps":
			s.u = rng.pick(AP_STEPS)
			s.v = rng.int_in(1, s.u - 1)
	s.w = s.u
	s.big = s.c * s.u
	s.tail = ap_tail(s)
	s.m = Q.gcd(s.big, s.tail)
	return s.m > 1 and (s.m < s.big or not s.ask in NEEDS_GAP)


static func _even_quad(rng: Seeded, s: Dictionary) -> bool:
	s.letter = "n"
	s.a = rng.pick([-7, -5, -3, -1, 1, 3, 5, 7, 9])
	s.b = 2 * rng.int_in(-4, 6)
	s.part = rng.pick(["even", "odd"])
	return true


static func _product_quad(rng: Seeded, s: Dictionary) -> bool:
	s.letter = "n"
	s.m = rng.int_in(-8, 8)
	return s.m != 0 and s.m != -1


static func _never(rng: Seeded, s: Dictionary) -> bool:
	s.letter = "n"
	s.shape = rng.pick(["three", "pair"])
	if s.shape == "three":
		s.d = rng.pick(NEVER_GAPS)
		s.m = 3
		s.q0 = (2 * s.d * s.d) / 3
		s.r = (2 * s.d * s.d) % 3
	else:
		s.d = rng.pick(PAIR_GAPS)
		s.m = 2
		s.q0 = (s.d * s.d) / 2
		s.r = (s.d * s.d) % 2
	return true


static func _pair_form(rng: Seeded, s: Dictionary) -> bool:
	var names: Array = rng.pick(LETTERS)
	s.l1 = names[0]
	s.l2 = names[1]
	s.letter = s.l1
	s.m = rng.int_in(2, 9)
	s.r = rng.int_in(0, s.m - 1)
	if s.m == 2:
		s.claim = rng.pick(CLAIMS_ODD if s.r == 1 else CLAIMS_EVEN)
	else:
		s.claim = "sum-multiple" if s.r == 0 else "difference-multiple"
	return true


static func export(s: Dictionary) -> Dictionary:
	return ExtensionViews.export(s)
