class_name MutuallyExclusiveSituation
extends RefCounted
## The `mutually-exclusive` situation (curriculum/question-types.json): two events that may or
## may not overlap, for t4-ext-mutually-exclusive (FAL-777). Probabilities are counts out of 20,
## so every one is a multiple of 0.05, exact.
##
## generate() returns ask, paper (1) and:
##   decide-from-probabilities  me, form ("union" or "inter"), ka, kb, ki: P(A) = ka/20 and so on
##   decide-from-venn           me, a, i, b, o, u: the Venn regions as counts
##   decide-in-context          me, dev (an index into DEVICES), ea, eb (indexes into EVENTS), k1, k2
##                              (the numbers some events need), A, B (the outcome lists)
##   union-exclusive            ka, kb, ctx
##   missing-exclusive          ka, ku: P(A) = ka/20 and P(A ∪ B) = ku/20
##
## Where the events can both happen, half the time they are independent too, so the slip that
## mixes the two ideas up has a case. The clean limits are the checker's too (E14ME_*).

const TRIES := 400
## The fair things a single outcome comes from: the outcome count and how a question names them.
const DEVICES := [
	{"n": 6, "what": "A fair six-sided die is rolled once.", "one": "roll"},
	{"n": 8, "what": "A fair spinner numbered 1 to 8 is spun once.", "one": "spin"},
	{"n": 10, "what": "One card is drawn at random from ten cards numbered 1 to 10.", "one": "card"},
	{"n": 12, "what": "One card is drawn at random from twelve cards numbered 1 to 12.", "one": "card"},
]
## The events, as words and as a test on an outcome x; k is the number an event needs.
const EVENTS := ["number", "odd", "even", "multiple3", "multiple4", "prime", "square", "greater", "less", "factor12"]
## P(A) values whose 1 − P(A) divides a multiple of 0.05 into a decimal that ends, so the
## independence slip on missing-exclusive is always a number the game can write.
const MISSING_KA := [4, 10, 12, 15, 16]


static func generate(rng: Seeded, need: Dictionary = {}) -> Dictionary:
	var ask: String = need.get("ask", "decide-from-probabilities")
	for i in TRIES:
		var s := _try(ask, rng)
		if not s.is_empty():
			s.ask = ask
			s.paper = 1
			return s
	push_error("MutuallyExclusiveSituation: no clean situation for %s" % need)
	return {}


static func _try(ask: String, rng: Seeded) -> Dictionary:
	match ask:
		"decide-from-probabilities":
			var ka := rng.int_in(2, 12)
			var kb := rng.int_in(2, 12)
			if ka == kb or ka + kb > 18:
				return {}
			var s := {"me": rng.chance(0.5), "form": rng.pick(["union", "union", "inter"]), "ka": ka, "kb": kb, "ki": 0}
			if not s.me:
				if rng.chance(0.5):
					if (ka * kb) % 20 != 0:
						return {}
					s.ki = ka * kb / 20
				else:
					s.ki = rng.int_in(1, mini(ka, kb) - 1)
				if s.ki < 1 or s.ki >= mini(ka, kb):
					return {}
			return s
		"decide-from-venn":
			var u: int = rng.pick([20, 24, 30, 40])
			var na := rng.int_in(3, u / 2)
			var nb := rng.int_in(3, u / 2)
			if na == nb or na + nb >= u:
				return {}
			var s := {"me": rng.chance(0.5), "u": u, "i": 0}
			if not s.me:
				if rng.chance(0.5):
					if (na * nb) % u != 0:
						return {}
					s.i = na * nb / u
				else:
					s.i = rng.int_in(1, mini(na, nb) - 1)
			s.a = na - s.i
			s.b = nb - s.i
			s.o = u - s.a - s.b - s.i
			if s.a < 1 or s.b < 1 or s.o < 1 or (not s.me and s.i < 1):
				return {}
			return s
		"decide-in-context":
			var dev := rng.int_in(0, DEVICES.size() - 1)
			var n: int = DEVICES[dev].n
			var ea := rng.int_in(0, EVENTS.size() - 1)
			var eb := rng.int_in(0, EVENTS.size() - 1)
			if ea == eb:
				return {}
			var s := {"dev": dev, "ea": ea, "eb": eb, "k1": rng.int_in(2, n - 1), "k2": rng.int_in(2, n - 1)}
			s.A = outcomes(n, EVENTS[ea], s.k1)
			s.B = outcomes(n, EVENTS[eb], s.k2)
			if s.A.is_empty() or s.B.is_empty() or s.A.size() == n or s.B.size() == n or s.A == s.B:
				return {}
			s.me = s.A.filter(func(x): return x in s.B).is_empty()
			# With P(A) + P(B) = 1 (odd and even, say) the sum and complementary slips have
			# nothing wrong to say.
			if s.A.size() + s.B.size() == n:
				return {}
			# Half and half, whatever the events.
			if s.me != rng.chance(0.5):
				return {}
			return s
		"union-exclusive":
			var ka := rng.int_in(1, 12)
			var kb := rng.int_in(1, 12)
			if ka == kb or ka + kb > 19:
				return {}
			return {"ka": ka, "kb": kb, "ctx": rng.int_in(0, 3)}
		"missing-exclusive":
			var ka: int = rng.pick(MISSING_KA)
			var ku := rng.int_in(ka + 1, 19)
			if ku - ka == ka:
				return {}
			return {"ka": ka, "ku": ku}
	return {}


## The outcomes 1 to n in an event.
static func outcomes(n: int, ev: String, k: int) -> Array:
	var out: Array = []
	for x in range(1, n + 1):
		if holds(ev, x, k):
			out.append(x)
	return out


static func holds(ev: String, x: int, k: int) -> bool:
	match ev:
		"number":
			return x == k
		"odd":
			return x % 2 == 1
		"even":
			return x % 2 == 0
		"multiple3":
			return x % 3 == 0
		"multiple4":
			return x % 4 == 0
		"prime":
			return x in [2, 3, 5, 7, 11]
		"square":
			return x in [1, 4, 9]
		"greater":
			return x > k
		"less":
			return x < k
		"factor12":
			return 12 % x == 0
	return false


static func export(s: Dictionary) -> Dictionary:
	return ExtensionViews.export(s)
