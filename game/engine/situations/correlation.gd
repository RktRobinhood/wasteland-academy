class_name CorrelationSituation
extends RefCounted
## The `correlation` situation (curriculum/question-types.json): paired data in a story, made to a
## band of Pearson's r, for t4-ext-describe-correlation (FAL-778). The stories are
## CorrelationViews.STORIES.
##
## Bands, by the size of r (shown to 2 d.p., and the shown value is inside its band too):
##   strong 0.85 to 0.98, moderate 0.5 to 0.72, weak 0.2 to 0.4, none 0 to 0.12, and curve: points
##   on a hump or a dip, with r from 0 to 0.12 in size.
## generate() returns ask, paper, story, band, dir (1 or −1; 0 for none and curve), n, xs, ys, r
## and, for match-r, cards (three more point sets: [band, dir, xs, ys, mistake]) and for
## strongest-r, rs (four values of r, the strongest first).

const BANDS := {"strong": [0.85, 0.98], "moderate": [0.5, 0.72], "weak": [0.2, 0.4], "none": [0.0, 0.12], "curve": [0.0, 0.12]}
const TRIES := 4000


static func generate(rng: Seeded, need: Dictionary = {}) -> Dictionary:
	var ask: String = need.get("ask", "describe-scatter")
	var s := {"ask": ask, "paper": int(need.get("paper", 1)), "story": rng.int_in(0, CorrelationViews.STORIES.size() - 1), "cards": [], "rs": []}
	var band := "strong"
	var dir := 1
	match ask:
		"describe-scatter":
			band = ["strong", "strong", "moderate", "weak", "none"][rng.int_in(0, 4)]
			dir = -1 if rng.chance(0.6) else 1
		"describe-r":
			if rng.chance(0.45):
				dir = -1
			else:
				band = rng.pick(["moderate", "weak"])
				dir = 1 if rng.chance(0.8) else -1
		"causation":
			s.story = rng.pick(CorrelationViews.CAUSAL)
			dir = CorrelationViews.STORIES[s.story].sign
		"no-linear":
			band = "curve"
		"match-r":
			band = rng.pick(["strong", "strong", "moderate"])
			dir = -1 if rng.chance(0.6) else 1
		"strongest-r":
			band = "strong"
			dir = -1 if rng.chance(0.7) else 1
	if band in ["none", "curve"]:
		dir = 0
	# The story's own direction agrees with the data's.
	if ask != "causation" and dir != 0:
		s.story = rng.pick(range(CorrelationViews.STORIES.size()).filter(func(i): return CorrelationViews.STORIES[i].sign == dir))
	var pts := points(rng, band, dir)
	s.merge({"band": band, "dir": dir, "n": pts[0].size(), "xs": pts[0], "ys": pts[1], "r": pearson(pts[0], pts[1])})
	if ask == "match-r":
		s.cards = _cards(rng, band, dir)
	if ask == "strongest-r":
		s.rs = _rs(rng, s.r)
	return s


## Points whose r is in the band, with the direction asked.
static func points(rng: Seeded, band: String, dir: int) -> Array:
	var lim: Array = BANDS[band]
	for t in TRIES:
		var n := rng.int_in(10, 14)
		var xs: Array = rng.shuffled(range(1, 21)).slice(0, n)
		xs.sort()
		var ys: Array = []
		# Around a line through the middle of the window, with noise scaled to the band.
		var slope: int = {"strong": rng.int_in(2, 4), "moderate": 2, "weak": 1}.get(band, 0) * dir
		var noise: int = {"strong": absi(slope) * rng.int_in(2, 6), "moderate": rng.int_in(20, 35), "weak": rng.int_in(25, 40), "none": 0, "curve": rng.int_in(1, 4)}[band]
		var peak := rng.int_in(9, 12)
		var hump := 1 if rng.chance(0.5) else -1
		for x in xs:
			var y: int
			match band:
				"none":
					y = rng.int_in(15, 85)
				"curve":
					y = 50 + hump * (30 - int(roundf(0.4 * (x - peak) * (x - peak)))) + rng.int_in(-noise, noise)
				_:
					y = 50 + int(roundf(slope * (x - 10.5))) + rng.int_in(-noise, noise)
			ys.append(y)
		if ys.min() < 3 or ys.max() > 97:
			continue
		var r := pearson(xs, ys)
		var shown := absf(snappedf(r, 0.01))
		if shown < maxf(lim[0], 0.01) or shown > lim[1] or absf(r) < lim[0] or absf(r) > lim[1]:
			continue
		if dir != 0 and signf(r) != dir:
			continue
		if band == "curve" and fit_curve(xs, ys) < 0.85:
			continue
		return [xs, ys]
	push_error("CorrelationSituation: no points for %s %d" % [band, dir])
	return [[], []]


static func pearson(xs: Array, ys: Array) -> float:
	var n := float(xs.size())
	var sx := 0.0
	var sy := 0.0
	for i in xs.size():
		sx += xs[i]
		sy += ys[i]
	var mx := sx / n
	var my := sy / n
	var sxy := 0.0
	var sxx := 0.0
	var syy := 0.0
	for i in xs.size():
		sxy += (xs[i] - mx) * (ys[i] - my)
		sxx += (xs[i] - mx) * (xs[i] - mx)
		syy += (ys[i] - my) * (ys[i] - my)
	if sxx == 0.0 or syy == 0.0:
		return 0.0
	return sxy / sqrt(sxx * syy)


## R² of the best parabola through the points: how well they follow a curve.
static func fit_curve(xs: Array, ys: Array) -> float:
	# Least squares in 1, x, x² by the normal equations, solved by Cramer's rule.
	var S := [0.0, 0.0, 0.0, 0.0, 0.0]
	var T := [0.0, 0.0, 0.0]
	for i in xs.size():
		var x := float(xs[i])
		var y := float(ys[i])
		for p in 5:
			S[p] += pow(x, p)
		for p in 3:
			T[p] += y * pow(x, p)
	var m := [[S[0], S[1], S[2]], [S[1], S[2], S[3]], [S[2], S[3], S[4]]]
	var d: float = _det(m)
	var c: Array = []
	for k in 3:
		var mk := [m[0].duplicate(), m[1].duplicate(), m[2].duplicate()]
		for row in 3:
			mk[row][k] = T[row]
		c.append(_det(mk) / d)
	var my: float = T[0] / xs.size()
	var res := 0.0
	var tot := 0.0
	for i in xs.size():
		var x := float(xs[i])
		var f: float = c[0] + c[1] * x + c[2] * x * x
		res += (ys[i] - f) * (ys[i] - f)
		tot += (ys[i] - my) * (ys[i] - my)
	return 1.0 - res / tot


static func _det(m: Array) -> float:
	return m[0][0] * (m[1][1] * m[2][2] - m[1][2] * m[2][1]) - m[0][1] * (m[1][0] * m[2][2] - m[1][2] * m[2][0]) + m[0][2] * (m[1][0] * m[2][1] - m[1][1] * m[2][0])


## The three wrong scatters of match-r: the other sign, the same sign but weak (a strong negative r
## read as weak), and no correlation.
static func _cards(rng: Seeded, band: String, dir: int) -> Array:
	var out: Array = []
	for c in [[band, -dir, "sign"], ["weak", dir, "weak"], ["none", 0, "none"]]:
		var pts := points(rng, c[0], c[1])
		out.append([c[0], c[1], pts[0], pts[1], c[2]])
	return out


## Four values of r to 2 d.p. with different sizes: the strongest first, then one smaller in size
## but larger as a number where the strongest is negative, and two weaker ones.
static func _rs(rng: Seeded, r: float) -> Array:
	var top := snappedf(r, 0.01)
	for t in TRIES:
		var a := snappedf(rng.int_in(55, 80) / 100.0, 0.01) * (1.0 if top < 0.0 else (1.0 if rng.chance(0.5) else -1.0))
		var b := snappedf(rng.int_in(20, 45) / 100.0, 0.01) * (1.0 if rng.chance(0.5) else -1.0)
		var c := snappedf(rng.int_in(1, 12) / 100.0, 0.01) * (1.0 if rng.chance(0.5) else -1.0)
		if absf(top) - absf(a) >= 0.08:
			return [top, a, b, c]
	return [top, 0.6, 0.3, 0.05]


static func export(s: Dictionary) -> Dictionary:
	return ExtensionViews.export(s)
