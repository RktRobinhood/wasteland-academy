class_name BinomialExpansionSituation
extends RefCounted
## The `binomial-expansion` situation (curriculum/question-types.json): one expansion of
## (ax^p + b)^n, for t1-binomial-term (FAL-728). `binomial` is the distribution of t4-binomial,
## which this isn't. Every number is a whole number, worked out exactly with ints.
##
## Paper 1 keeps n and the numbers small enough to do by hand. Paper 2 goes up to n = 10, and to
## n = 12 for nCr alone. A method that reads a row of Pascal's triangle, and a question that shows
## the triangle, keeps n to 7.
##
## need.ask is the unknown (see BinomialExpansionViews). generate() returns a Dictionary:
##   paper, ask, rep
##   n        the power
##   a, p     the term with x, a·x^p: a signed, p 1 or 2
##   b        the number in the bracket, signed
##   first    true when the number is written first: (3 − 2x)^n, not (2x + 3)^n
##   over     expand-reciprocal: the bracket is (ax + b/x), so a term has x^(j − (n − j))
##   j        how many brackets give the term in x, so the term asked is in x^(p·j)
##   r        nCr's r, for the unknowns about nCr alone
##   letter   coefficient-letter, number-of-terms: the letter standing for b
##   pick     missing-coefficient: 1 for the second term, 2 for the third
##   pos      term-by-position: the place of the term, from 1, highest power first
##   shift    ncr-formula-in-n: the top of (n + shift)C2
##
## A negative number is only ever in the second term written: (2x − 3), (3 − 2x), never (−2x + 3).
## The bank's own brackets are left out ((2x − 5) and (x + k)^8, (x + k)^11), so no question
## repeats one.
## The clean limits are the numbers behind the catalogue's `clean` text. The checker holds its own
## copy.

const TRIES := 400
## The largest size of a Paper 1 coefficient, and of any coefficient.
const HAND := 20000
const MOST := 200000000
## The largest row a question reads from Pascal's triangle, or shows.
const ROW := 7
const LETTERS := ["k", "m", "t"]
## Methods that read a row, so n stays small. An empty angle is a shared situation, which any
## method may be asked of.
const READS_A_ROW := ["pascal-build", "pascal-row", "pascal-select", ""]


static func generate(rng: Seeded, need: Dictionary = {}) -> Dictionary:
	var ask: String = need.get("ask", "ncr-value")
	var rep: String = need.get("rep", "equation")
	var paper: int = int(need.get("paper", 1))
	var angle: String = need.get("angle", "")
	var small: bool = rep == "table" or angle in READS_A_ROW
	for i in TRIES:
		var s := {"paper": paper, "ask": ask, "rep": rep, "small": small, "n": 0, "a": 1, "p": 1, "b": 1, "first": false, "over": false, "j": 0, "r": 0, "pick": 0, "pos": 0, "shift": 0, "letter": ""}
		if _draw(rng, s) and _no_factor(s):
			return s
	return {}


# ── The numbers ──────────────────────────────────────────────

static func ncr(n: int, r: int) -> int:
	if r < 0 or r > n:
		return 0
	var out := 1
	for i in mini(r, n - r):
		out = out * (n - i) / (i + 1)
	return out


static func power(v: int, e: int) -> int:
	var out := 1
	for i in e:
		out *= v
	return out


static func factorial(n: int) -> int:
	return 1 if n <= 1 else n * factorial(n - 1)


static func row(n: int) -> Array:
	return range(n + 1).map(func(r): return ncr(n, r))


## The coefficient of the term with j brackets giving ax^p.
static func coef(s: Dictionary, j: int) -> int:
	return ncr(s.n, j) * power(s.a, j) * power(s.b, s.n - j)


## The power of x in that term.
static func power_of(s: Dictionary, j: int) -> int:
	return s.p * j - (s.n - j if s.over else 0)


## The largest coefficient of the expansion, in size.
static func largest(s: Dictionary) -> int:
	var most := 0
	for j in s.n + 1:
		most = maxi(most, absi(coef(s, j)))
	return most


## (2x − 2) and (3 − 3x) would be a common factor away from a smaller bracket.
static func _no_factor(s: Dictionary) -> bool:
	for d in [2, 3]:
		if s.a % d == 0 and s.b % d == 0:
			return false
	return true


# ── Drawing ──────────────────────────────────────────────────

static func _draw(rng: Seeded, s: Dictionary) -> bool:
	match s.ask:
		"ncr-value":
			return _ncr_value(rng, s)
		"ncr-read-triangle":
			s.n = rng.int_in(4, ROW)
			s.r = rng.int_in(2, s.n - 2)
			return true
		"ncr-large-r":
			s.n = rng.int_in(7, 10 if s.paper == 1 else 12)
			s.r = s.n - rng.int_in(2, 3 if s.paper == 1 else 4)
			return s.r > s.n - s.r
		"ncr-symmetry":
			s.n = rng.int_in(6, 12)
			s.r = rng.int_in(2, s.n - 2)
			return s.r != s.n - s.r
		"ncr-edge":
			s.n = rng.int_in(4, 12)
			s.r = 0 if rng.chance(0.7) else s.n
			return true
		"ncr-find-n":
			s.n = rng.int_in(4, ROW + 1 if s.small else (10 if s.paper == 1 else 12))
			s.r = 2
			return true
		"ncr-formula-in-n":
			s.r = 2
			s.shift = rng.pick([0, 0, 1, 2, -1])
			return true
		"pascal-row":
			s.n = rng.int_in(4, ROW)
			return true
		"pascal-next-row":
			s.n = rng.int_in(4, ROW)
			return true
		"row-from-entries":
			s.n = rng.int_in(4, 9)
			return true
		"number-of-terms":
			return _number_of_terms(rng, s)
		"expand-small":
			return _expand_small(rng, s)
		"expand-unit":
			s.n = rng.int_in(4, 5)
			s.b = rng.int_in(1, 3)
			s.first = rng.chance(0.5)
			return s.n != 4 or s.b != 1
		"expand-negative":
			s.n = rng.int_in(3, 5)
			_negative(rng, s, rng.int_in(1, 3))
			return true
		"expand-raised", "expand-from-triangle":
			return _expand_raised(rng, s)
		"expand-power":
			return _expand_power(rng, s)
		"expand-reciprocal":
			return _expand_reciprocal(rng, s)
		"first-three-terms":
			return _first_three(rng, s)
		"coefficient-plain":
			return _coefficient_plain(rng, s)
		"coefficient-negative":
			return _coefficient_negative(rng, s)
		"coefficient-raised", "coefficient-from-triangle":
			return _coefficient_raised(rng, s)
		"specific-term":
			return _specific_term(rng, s)
		"coefficient-power":
			return _coefficient_power(rng, s)
		"coefficient-letter":
			s.n = rng.int_in(5, 9)
			s.j = rng.int_in(2, s.n - 2)
			s.letter = rng.pick(LETTERS)
			return s.n != 8 and s.j != s.n - s.j
		"missing-coefficient":
			s.n = rng.int_in(5, ROW if s.paper == 1 or s.small else 9)
			s.b = rng.int_in(1, 2)
			s.pick = rng.int_in(1, 2)
			s.j = s.n - s.pick
			return not (s.n == 7 and s.b == 1)
		"term-by-position":
			return _term_by_position(rng, s)
	return false


static func _ncr_value(rng: Seeded, s: Dictionary) -> bool:
	if s.small:
		s.n = rng.int_in(5, ROW)
		s.r = rng.int_in(2, s.n / 2)
	elif s.paper == 1:
		s.n = rng.int_in(6, 10)
		s.r = rng.int_in(2, 3)
	else:
		s.n = rng.int_in(9, 12)
		s.r = rng.int_in(3, s.n / 2)
	return true


static func _number_of_terms(rng: Seeded, s: Dictionary) -> bool:
	s.n = rng.int_in(5, 12)
	s.letter = rng.pick(LETTERS)
	s.a = rng.int_in(1, 3)
	s.first = rng.chance(0.3)
	return s.n != 11 or s.a != 1


## n of 2 or 3, the one place multiplying the brackets out by hand is the sensible way.
static func _expand_small(rng: Seeded, s: Dictionary) -> bool:
	s.n = rng.int_in(2, 3)
	var size: int = rng.int_in(1, 3 if s.paper == 1 else 4)
	var mag: int = rng.int_in(1, 3)
	s.first = rng.chance(0.4)
	if rng.chance(0.65):
		s.a = -mag if s.first else mag
		s.b = size if s.first else -size
	else:
		s.a = mag
		s.b = size
	return absi(s.a) > 1 or size > 1


## The negative term, in the second place written.
static func _negative(rng: Seeded, s: Dictionary, size: int) -> void:
	s.first = rng.chance(0.4)
	s.a = -absi(s.a) if s.first else absi(s.a)
	s.b = size if s.first else -size


static func _expand_raised(rng: Seeded, s: Dictionary) -> bool:
	s.n = rng.int_in(3, 4 if s.paper == 1 else 5)
	s.a = rng.int_in(2, 3)
	if rng.chance(0.7):
		_negative(rng, s, rng.int_in(1, 3))
	else:
		s.b = rng.int_in(1, 3)
		s.first = rng.chance(0.4)
	return largest(s) <= HAND


static func _expand_power(rng: Seeded, s: Dictionary) -> bool:
	s.n = rng.int_in(3, 4)
	s.p = 2
	s.a = rng.int_in(1, 2)
	if rng.chance(0.6):
		_negative(rng, s, rng.int_in(1, 3))
	else:
		s.b = rng.int_in(1, 3)
	return absi(s.a) > 1 or absi(s.b) > 1


## (x + 2/x)^n: n is small, as every term is written out.
static func _expand_reciprocal(rng: Seeded, s: Dictionary) -> bool:
	s.n = rng.int_in(3, 4 if s.paper == 1 else 5)
	s.over = true
	s.a = 1
	s.b = rng.pick([-3, -2, -1, 1, 2, 3])
	return s.n != 4 or absi(s.b) != 1


## The first three terms need no more than x², but a large n: only the row is long.
static func _first_three(rng: Seeded, s: Dictionary) -> bool:
	s.n = rng.int_in(5, ROW) if s.small else rng.int_in(5, 8) if s.paper == 1 else rng.int_in(6, 10)
	s.a = rng.int_in(1, 3)
	if rng.chance(0.65):
		_negative(rng, s, rng.int_in(1, 3))
	else:
		s.b = rng.int_in(1, 3)
		s.first = rng.chance(0.7)
	if absi(s.a) == 1 and absi(s.b) == 1:
		return false
	return maxi(maxi(absi(coef(s, 0)), absi(coef(s, 1))), absi(coef(s, 2))) <= (HAND if s.paper == 1 else MOST)


## n, and the brackets j giving x: at least two of each, so both powers are real powers.
static func _term(rng: Seeded, s: Dictionary, lo: int, hand: int, long: int) -> void:
	s.n = rng.int_in(lo, ROW) if s.small else rng.int_in(lo, hand) if s.paper == 1 else rng.int_in(hand, long)
	s.j = rng.int_in(2, s.n - 2)


static func _coefficient_plain(rng: Seeded, s: Dictionary) -> bool:
	_term(rng, s, 4, 6, 10)
	s.b = rng.int_in(2, 3 if s.paper == 1 else 4)
	s.first = rng.chance(0.3)
	return absi(coef(s, s.j)) <= (HAND if s.paper == 1 else MOST)


## The negative term comes to an odd power most of the time, so the sign has to be kept.
static func _coefficient_negative(rng: Seeded, s: Dictionary) -> bool:
	_term(rng, s, 4, 6, 10)
	_negative(rng, s, rng.int_in(2, 3 if s.paper == 1 else 4))
	if coef(s, s.j) > 0 and rng.chance(0.7):
		return false
	return absi(coef(s, s.j)) <= (HAND if s.paper == 1 else MOST)


## (2x − 3)^n: never 5 beside 2x, the bank's bracket.
static func _coefficient_raised(rng: Seeded, s: Dictionary) -> bool:
	_term(rng, s, 4, 6, 10)
	s.a = rng.int_in(2, 3)
	if rng.chance(0.75):
		_negative(rng, s, rng.int_in(1, 3 if s.paper == 1 else 4))
	else:
		s.b = rng.int_in(1, 3 if s.paper == 1 else 4)
		s.first = rng.chance(0.4)
	return absi(coef(s, s.j)) <= (HAND if s.paper == 1 else MOST)


## "The term in x^j" rather than its coefficient, and (2 − x)^n with no number beside x is fair.
static func _specific_term(rng: Seeded, s: Dictionary) -> bool:
	_term(rng, s, 4, 6, 10)
	s.a = rng.int_in(1, 3)
	var size: int = rng.int_in(2, 3 if s.paper == 1 else 4)
	if rng.chance(0.7):
		_negative(rng, s, size)
	else:
		s.b = size
		s.first = rng.chance(0.4)
	return absi(coef(s, s.j)) <= (HAND if s.paper == 1 else MOST)


static func _coefficient_power(rng: Seeded, s: Dictionary) -> bool:
	_term(rng, s, 4, 6, 8)
	s.p = 2
	s.a = rng.int_in(1, 2)
	if rng.chance(0.6):
		_negative(rng, s, rng.int_in(1, 3))
	else:
		s.b = rng.int_in(2, 3)
	return absi(coef(s, s.j)) <= (HAND if s.paper == 1 else MOST)


## The term in place pos, written highest power first. It stops short of both ends, so a slip of
## one place is still a term of the expansion.
static func _term_by_position(rng: Seeded, s: Dictionary) -> bool:
	s.n = rng.int_in(4, ROW) if s.small else rng.int_in(4, 6) if s.paper == 1 else rng.int_in(5, 9)
	s.pos = rng.int_in(2, s.n - 1)
	s.j = s.n - (s.pos - 1)
	s.a = rng.int_in(1, 3)
	s.b = rng.pick([-3, -2, 2, 3])
	return absi(coef(s, s.j)) <= (HAND if s.paper == 1 else MOST)


static func export(s: Dictionary) -> Dictionary:
	return ExtensionViews.export(s)
