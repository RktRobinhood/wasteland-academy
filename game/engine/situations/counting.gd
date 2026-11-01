class_name CountingSituation
extends RefCounted
## The `counting` situation (curriculum/question-types.json): one counting problem
## (FAL-695), the first built for AA HL only (AHL1.10). Every count is a whole number, so
## everything stays exact: the largest is 26^3 × 10^4, under 2 × 10^9.
##
## need.ask is the unknown, and decides what is drawn:
##   code-count              a letters then b digits, repeats allowed
##   no-repeat-number        d digits, none repeated, not starting with 0
##   even-numbers            digits 1 to m (m is 6 or 8), d of them, none repeated, even
##   arrange-all             n different objects in a row
##   award-places            n runners, r places
##   find-n-from-npr         nP2 = v, find n
##   committee               k chosen from n
##   committee-mixed         k chosen from men and women, exactly j women
##   committee-at-least-one  k chosen from men and women, at least one woman
##   together, apart         n people in a row, two of them next to each other or not
##
## generate() returns a Dictionary: ask, ctx (the story, an index into the views'
## templates), the sizes above under the names used there (a, b, d, m, n, r, v, k, men,
## women, j), and `count`, the answer.

const TRIES := 200
const COUNT_MAX := 20_000_000


static func generate(rng: Seeded, need: Dictionary = {}) -> Dictionary:
	var ask: String = need.get("ask", "committee")
	for i in TRIES:
		var s := {"ask": ask, "ctx": rng.int_in(0, 5), "a": 0, "b": 0, "d": 0, "m": 0, "n": 0, "r": 0, "v": 0, "k": 0, "men": 0, "women": 0, "j": 0}
		match ask:
			"code-count":
				s.a = rng.int_in(2, 3)
				s.b = rng.int_in(2, 4)
			"no-repeat-number":
				s.d = rng.int_in(3, 5)
			"even-numbers":
				s.m = 6 if rng.chance(0.5) else 8
				s.d = rng.int_in(3, 4)
			"arrange-all", "together", "apart":
				s.n = rng.int_in(5, 8)
			"award-places":
				s.n = rng.int_in(6, 12)
				s.r = rng.int_in(2, 4)
			"find-n-from-npr":
				s.n = rng.int_in(6, 15)
				s.v = s.n * (s.n - 1)
			"committee":
				s.n = rng.int_in(8, 14)
				s.k = rng.int_in(3, 5)
			"committee-mixed", "committee-at-least-one":
				s.men = rng.int_in(4, 7)
				s.women = rng.int_in(3, 6)
				s.k = rng.int_in(4, 5)
				if ask == "committee-mixed":
					s.j = rng.int_in(2, mini(s.women, s.k - 1))
					if s.k - s.j > s.men:
						continue
				elif s.k > s.men:
					continue
		s.count = count(s)
		if s.count > 0 and s.count < COUNT_MAX:
			return s
	return {}


# ── The counts ───────────────────────────────────────────────

static func fact(n: int) -> int:
	var r := 1
	for i in range(2, n + 1):
		r *= i
	return r


## nPr: n × (n − 1) × ... with r terms.
static func perm(n: int, r: int) -> int:
	if r < 0 or r > n:
		return 0
	var out := 1
	for i in r:
		out *= n - i
	return out


## nCr, whole at every step.
static func comb(n: int, r: int) -> int:
	if r < 0 or r > n:
		return 0
	var out := 1
	for i in range(1, r + 1):
		out = out * (n - r + i) / i
	return out


static func count(s: Dictionary) -> int:
	match s.ask:
		"code-count":
			return int(pow(26, s.a)) * int(pow(10, s.b))
		"no-repeat-number":
			return 9 * perm(9, s.d - 1)
		"even-numbers":
			return (s.m / 2) * perm(s.m - 1, s.d - 1)
		"arrange-all":
			return fact(s.n)
		"award-places":
			return perm(s.n, s.r)
		"find-n-from-npr":
			return s.n
		"committee":
			return comb(s.n, s.k)
		"committee-mixed":
			return comb(s.women, s.j) * comb(s.men, s.k - s.j)
		"committee-at-least-one":
			return comb(s.men + s.women, s.k) - comb(s.men, s.k)
		"together":
			return 2 * fact(s.n - 1)
		"apart":
			return fact(s.n) - 2 * fact(s.n - 1)
	return 0


static func export(s: Dictionary) -> Dictionary:
	return ExtensionViews.export(s)
