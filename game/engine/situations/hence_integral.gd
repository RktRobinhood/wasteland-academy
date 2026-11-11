class_name HenceIntegralSituation
extends RefCounted
## The `hence-integral` situation (curriculum/question-types.json): a derivative result, then an
## integral found from it, for t5-ext-hence-integral (FAL-776).
##
## Products (move-extra-term, find-derivative): F = x ln x, x e^(kx), x sin(kx) or x cos(kx). F′ has
## two terms; the integral asked for is one of them, so the other's integral moves across.
## Composites (adjust-factor): F = e^(px²), ln(x² + c), (x² + c)ⁿ or sin(x²). F′ is a constant times
## x times something, and the integrand is m times x times that, so the factor is divided out.
## hence-definite: ∫ from 1 to n of m ln x dx, or ∫ from 0 to b of m x e^(x²) dx, exactly.
## pick-the-derivative: an integral and four true derivative results, one of which helps.
##
## generate() returns ask, paper (1), fam and the whole numbers k, m, p, c, n, b as the family uses
## them. The clean limits are the checker's too (E13HI_*).

const PRODUCTS := ["xlnx", "xekx", "xsin", "xcos"]
const COMPOSITES := ["ex2", "lnq", "pow", "sin2"]
const PICKS := ["xcos", "xsin", "lnx", "xekx", "ex2"]


static func generate(rng: Seeded, need: Dictionary = {}) -> Dictionary:
	var ask: String = need.get("ask", "move-extra-term")
	var s := {"ask": ask, "paper": 1, "k": 1, "m": 1, "p": 1, "c": 1, "n": 2, "b": 1}
	match ask:
		"find-derivative":
			s.fam = rng.pick(["xlnx", "xekx", "xekx", "xsin", "xcos"])
			s.k = 1 if s.fam == "xlnx" else rng.pick([1, 2, 3] if s.fam == "xekx" else [1, 2])
			if s.fam == "xekx" and s.k == 1:
				s.k = 2
		"move-extra-term":
			s.fam = rng.pick(PRODUCTS)
			s.k = 1 if s.fam == "xlnx" else rng.pick([2, 3] if s.fam == "xekx" else [1, 2])
			s.m = rng.int_in(2, 5) if s.fam == "xlnx" else 1
		"adjust-factor":
			s.fam = rng.pick(COMPOSITES)
			s.p = rng.pick([1, 2, 3]) if s.fam == "ex2" else 1
			s.c = rng.int_in(1, 9)
			s.n = rng.pick([2, 3, 4])
			s.m = rng.int_in(2, 9)
			# The factor F′ carries: 2p for e^(px²), 2 for ln and sin, 2n for a power.
			var factor: int = 2 * s.p if s.fam == "ex2" else (2 * s.n if s.fam == "pow" else 2)
			if s.m == factor:
				s.m += 1
		"hence-definite":
			s.fam = rng.pick(["xlnx", "ex2"])
			s.m = rng.int_in(2, 6)
			s.n = rng.pick([2, 3, 4, 5])
			s.b = rng.pick([1, 2])
			if s.fam == "ex2" and s.m == 2:
				s.m = 3
		"pick-the-derivative":
			s.fam = rng.pick(PICKS)
			s.k = rng.pick([1, 2, 3]) if s.fam == "xekx" else 1
	return s


static func export(s: Dictionary) -> Dictionary:
	return ExtensionViews.export(s)
