class_name DifferentiationSituation
extends RefCounted
## The `differentiation` situation (curriculum/question-types.json): one function to
## differentiate, by the standard results, the chain rule, the product rule or the
## quotient rule (SL5.6, FAL-723). Every coefficient is a whole number, so every
## derivative is exact. The SymPy checker (tools/check_answers.py) reads the function
## back from the line shown, differentiates it itself and compares the two at
## several points.
##
## need.ask is the unknown, and need.angle the method that made the numbers. generate()
## returns a Dictionary with ask, paper and fam (the function's family), the whole
## numbers a to d, the powers m and n, and k, the x a gradient is asked at (a Q).
##
##   standard-terms       a e^x + b ln x + c sin x (fam "sin") or c cos x ("cos"), + d
##   root-powers          a x^r + b/x^n: r is +1/2 ("sqrt"), +1/3 ("cbrt"), −1/2 ("invsqrt"), −1/3 ("invcbrt")
##   log-power-terms      a ln(x^n) + b x^m ("power") or a ln(dx) + b x^m ("scaled")
##   chain-power          c(a x^m + b)^n
##   chain-small-power    (ax + b)²
##   chain-function       one of FUNCTION_FAMS
##   chain-log-split      ln((ax + b)^n) ("power") or ln √(ax + b) ("root")
##   product-functions    one of PRODUCT_FAMS
##   product-polys        (ax + b)(cx² + d)
##   product-powers       a x^m √x
##   quotient-linear      (ax + b)/(cx + d), with ad − bc not zero
##   quotient-functions   (ln x)/x^n ("ln"), e^(ax)/x ("exp"), (sin x)/x ("sin")
##   quotient-split       (ax² + bx + c)/x
##   show-form            (ln x)/x^n ("ln"), (ax + b)/(x − c) ("linear"), ax/(x² + b)^n ("alg")
##   gradient             need.fam: "chain", "product" or "quotient", at x = k
##   parameter-derivative (ax + p)³/(x + c)², with the letter p left in

const FUNCTION_FAMS := ["exp-quad", "exp-lin", "ln-quad", "ln-lin", "sin-lin", "cos-lin", "sqrt-lin"]
const PRODUCT_FAMS := ["exp", "ln", "sin", "cos", "exp-sin"]
const TRIES := 400


static func nonzero(rng: Seeded, lo: int, hi: int) -> int:
	return ExtensionViews.nonzero(rng, lo, hi)


static func generate(rng: Seeded, need: Dictionary = {}) -> Dictionary:
	var ask: String = need.get("ask", "standard-terms")
	var paper := int(need.get("paper", 1))
	var s := {"ask": ask, "paper": paper, "fam": "", "a": 0, "b": 0, "c": 0, "d": 0, "m": 0, "n": 0, "k": Q.new(0)}
	match ask:
		"standard-terms":
			s.fam = rng.pick(["sin", "cos"])
			s.a = nonzero(rng, -9, 9)
			s.b = nonzero(rng, -9, 9)
			s.c = nonzero(rng, -9, 9)
			s.d = rng.int_in(-9, 9)
		"root-powers":
			s.fam = rng.pick(["sqrt", "cbrt", "invsqrt", "invcbrt"])
			var r: int = 2 if s.fam.ends_with("sqrt") else 3
			s.a = r * nonzero(rng, -6, 6)
			s.b = nonzero(rng, -9, 9)
			s.n = rng.int_in(1, 3)
		"log-power-terms":
			s.fam = rng.pick(["power", "scaled"])
			s.a = nonzero(rng, -7, 7)
			s.n = rng.int_in(2, 6)
			s.d = rng.int_in(2, 9)
			s.b = nonzero(rng, -5, 5)
			s.m = rng.int_in(2, 4)
		"chain-power":
			s.a = rng.int_in(2, 5)
			s.m = rng.int_in(1, 3)
			s.b = nonzero(rng, -7, 7)
			s.n = rng.int_in(3, 6)
			s.c = rng.pick([1, 1, 2, 3, -1, -2])
		"chain-small-power":
			s.a = rng.int_in(2, 7)
			s.b = nonzero(rng, -7, 7)
		"chain-function":
			s.fam = rng.pick(FUNCTION_FAMS)
			s.a = rng.int_in(2, 6)
			s.b = nonzero(rng, -8, 8)
			if s.fam == "ln-quad":
				s.a = 1
				s.b = rng.int_in(1, 9)
		"chain-log-split":
			s.fam = rng.pick(["power", "root"])
			s.a = rng.int_in(2, 7)
			s.b = nonzero(rng, -7, 7)
			s.n = rng.int_in(2, 6)
		"product-functions":
			s.fam = rng.pick(PRODUCT_FAMS)
			s.n = rng.int_in(2, 4)
			s.a = rng.pick([1, 2, 3, 4, -1, -2, -3])
		"product-polys":
			s.a = rng.int_in(1, 6)
			s.b = nonzero(rng, -7, 7)
			s.c = rng.int_in(1, 5)
			s.d = nonzero(rng, -7, 7)
		"product-powers":
			s.a = 2 * nonzero(rng, -5, 5)
			s.m = rng.int_in(1, 4)
		"quotient-linear":
			for i in TRIES:
				s.a = nonzero(rng, -6, 6)
				s.b = nonzero(rng, -7, 7)
				s.c = rng.int_in(1, 5)
				s.d = nonzero(rng, -7, 7)
				if s.a * s.d != s.b * s.c:
					break
		"quotient-functions":
			s.fam = rng.pick(["ln", "exp", "sin"])
			s.n = rng.int_in(2, 5)
			s.a = rng.int_in(2, 5)
		"quotient-split":
			s.a = nonzero(rng, -6, 6)
			s.b = nonzero(rng, -7, 7)
			s.c = nonzero(rng, -9, 9)
		"show-form":
			s.fam = rng.pick(["ln", "linear", "alg"])
			match s.fam:
				"ln":
					s.n = rng.int_in(2, 6)
				"linear":
					for i in TRIES:
						s.a = rng.int_in(2, 7)
						s.b = nonzero(rng, -9, 9)
						s.c = rng.int_in(2, 8)
						if s.b != -s.a * s.c:
							break
				"alg":
					s.a = rng.pick([2, 3, 4, 5, 6, 8])
					s.b = rng.int_in(1, 7)
					s.n = rng.int_in(2, 4)
		"gradient":
			s.fam = need.get("fam", "chain")
			_gradient(s, rng)
		"parameter-derivative":
			s.paper = 2
			s.a = rng.int_in(2, 4)
			s.c = rng.int_in(2, 9)
	return s


## A gradient: Paper 1 at a whole x with an exact answer, Paper 2 at an x to 1 d.p. with
## an answer to 3 s.f. that a calculator gives, clear of a rounding edge.
static func _gradient(s: Dictionary, rng: Seeded) -> void:
	var p2: bool = s.paper == 2
	for i in TRIES:
		s.a = rng.int_in(2, 5)
		s.b = rng.int_in(1, 9)
		s.c = rng.int_in(1, 7)
		s.n = rng.int_in(2, 4)
		s.k = Q.new(rng.int_in(11, 39), 10) if p2 else Q.of(nonzero(rng, -3, 3))
		if p2 and s.k.is_int():
			continue
		if not p2:
			# e^(x² + b) at x = k, x^n(ax − b)^2 and (ax + b)/(x² + c): all exact.
			if s.fam == "chain":
				s.b = nonzero(rng, -9, 9)
				var e: int = s.k.n * s.k.n + s.b
				if e < 2 or e > 9:
					continue
			if s.fam == "product":
				s.b = nonzero(rng, -5, 5)
				if (s.a * s.k.n - s.b) == 0 or s.k.n == 0:
					continue
		var x: float = gradient_value(s)
		if not p2 or GdcKit.fair(x):
			return
	assert(false, "no clean gradient")


## The gradient at k as a float: on Paper 2, √(ax² + b), x^n ln x and (ln x)/(x + c).
static func gradient_value(s: Dictionary) -> float:
	var x: float = s.k.to_float()
	if s.paper == 2:
		match s.fam:
			"chain":
				return s.a * x / sqrt(s.a * x * x + s.b)
			"product":
				return s.n * pow(x, s.n - 1) * log(x) + pow(x, s.n - 1)
		return (1.0 / x * (x + s.c) - log(x)) / pow(x + s.c, 2)
	return 0.0


static func export(s: Dictionary) -> Dictionary:
	return ExtensionViews.export(s)
