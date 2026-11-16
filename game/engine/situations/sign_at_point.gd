class_name SignAtPointSituation
extends RefCounted
## The `sign-at-point` situation (curriculum/question-types.json): a function and one point where
## f′ is not 0, for t5-ext-sign-at-point (FAL-777). The sign of f(a) is the other way from the
## sign of f′(a), so the slip that reads f(a) gives the wrong direction.
##
## generate() returns ask, paper and:
##   from-formula, in-context   c (the cubic's [x³, x², x, 1] coefficients), a (the point, a whole
##                              number), ctx (an index into CONTEXTS, in-context only: a
##                              positive quantity that falls, or a negative one that rises)
##   from-derivative            k, p, r: f′(x) = k(x − p)(x − r); a
##   gdc-check                  family ("exp": e^x − bx² + d, "log": c ln x − bx + d), b, c, d,
##                              a (to 1 d.p.), fp = f′(a) and fa = f(a) as floats. Paper 2.
##
## The clean limits are the checker's too (E14SP_*).

const TRIES := 800
## The stories: the letter, what it is, the time it runs for, and the words for up and down.
## A falling question is about something that stays positive, and a rising one about something
## that stays negative (neg), so the sign of the quantity always points the other way.
const CONTEXTS := [
	{"q": "T", "what": "The temperature of a cooling tank, in °C,", "name": "temperature", "end": 6, "up": "rising", "down": "falling", "neg": false},
	{"q": "W", "what": "The depth of water in a reservoir, in metres,", "name": "depth of water", "end": 8, "up": "rising", "down": "falling", "neg": false},
	{"q": "N", "what": "The number of rats in a bunker, in hundreds,", "name": "number of rats", "end": 6, "up": "increasing", "down": "decreasing", "neg": false},
	{"q": "P", "what": "The price of fuel, in caps per litre,", "name": "price of fuel", "end": 8, "up": "rising", "down": "falling", "neg": false},
	{"q": "T", "what": "The temperature inside a freezer, in °C,", "name": "temperature", "end": 6, "up": "rising", "down": "falling", "neg": true},
	{"q": "H", "what": "The height of a diver above the surface, in metres,", "name": "diver's height", "end": 8, "up": "rising", "down": "falling", "neg": true},
	{"q": "B", "what": "The balance of a trader's account, in hundreds of caps,", "name": "balance", "end": 8, "up": "rising", "down": "falling", "neg": true},
]


static func generate(rng: Seeded, need: Dictionary = {}) -> Dictionary:
	var ask: String = need.get("ask", "from-formula")
	for i in TRIES:
		var s := _try(ask, rng)
		if not s.is_empty():
			s.ask = ask
			s.paper = 2 if ask == "gdc-check" else 1
			return s
	push_error("SignAtPointSituation: no clean situation for %s" % need)
	return {}


static func value(c: Array, x: Variant) -> Q:
	var v := Q.new(0)
	for k in c.size():
		v = v.mul(Q.of(x)).add(Q.new(c[k]))
	return v


static func slope(c: Array, x: Variant) -> Q:
	return value([3 * c[0], 2 * c[1], c[2]], x)


static func _try(ask: String, rng: Seeded) -> Dictionary:
	match ask:
		"from-formula":
			var c := [ExtensionViews.nonzero(rng, -2, 2), rng.int_in(-6, 6), rng.int_in(-9, 9), rng.int_in(-12, 12)]
			var a: int = rng.pick([-3, -2, -1, 2, 3])
			var fa := value(c, a)
			var fp := slope(c, a)
			if fa.is_zero() or fp.is_zero() or fa.sign() == fp.sign() or absf(fp.to_float()) > 40 or c[1] == 0:
				return {}
			return {"c": c, "a": a}
		"in-context":
			var ctx := rng.int_in(0, CONTEXTS.size() - 1)
			var neg: bool = CONTEXTS[ctx].neg
			var end: int = CONTEXTS[ctx].end
			var d := rng.int_in(-80, -20) if neg else rng.int_in(20, 80)
			var c := [rng.pick([-1, 1]), rng.int_in(-9, 9), rng.int_in(-20, 20), d]
			var a := rng.int_in(2, end - 1)
			var fp := slope(c, a)
			# A positive quantity falls and a negative one rises.
			if fp.is_zero() or (fp.sign() > 0) != neg or absf(fp.to_float()) > 60 or c[1] == 0 or c[2] == 0:
				return {}
			for t in end + 1:
				var v := value(c, t).to_float()
				if (v >= 0.0 or v < -200.0) if neg else (v <= 0.0 or v > 200.0):
					return {}
			return {"c": c, "a": a, "ctx": ctx}
		"from-derivative":
			var p := rng.int_in(-4, 4)
			var r := rng.int_in(-4, 4)
			var a := rng.int_in(-4, 4)
			var k: int = ExtensionViews.nonzero(rng, -3, 3)
			if p >= r or a == p or a == r or p == 0 or r == 0:
				return {}
			return {"k": k, "p": p, "r": r, "a": a}
		"gdc-check":
			var s := {"family": rng.pick(["exp", "log"]), "b": rng.int_in(1, 4), "c": rng.int_in(2, 6), "d": rng.int_in(-5, 5)}
			s.a = rng.int_in(1, 30) / 10.0
			if s.family == "exp":
				s.fp = exp(s.a) - 2.0 * s.b * s.a
				s.fa = exp(s.a) - s.b * s.a * s.a + s.d
			else:
				s.fp = s.c / s.a - s.b
				s.fa = s.c * log(s.a) - s.b * s.a + s.d
			if absf(s.fp) < 0.1 or absf(s.fa) < 0.1 or signf(s.fp) == signf(s.fa) or not GdcKit.fair(s.fp) or not GdcKit.fair(s.fa):
				return {}
			if absf(s.a - roundf(s.a)) < 0.05:
				return {}
			return s
	return {}


static func export(s: Dictionary) -> Dictionary:
	return ExtensionViews.export(s)
