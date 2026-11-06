class_name CircularMotionSituation
extends RefCounted
## The `circular-motion` situation (curriculum/question-types.json): something turning steadily
## about O (FAL-753). A sweep is a searchlight or a radar with a reach r, and a straight line d
## from O that cuts the circle it reaches at A and B, so half of angle AOB is arccos(d/r). A rotor
## is a turbine or a wheel with an arm of length r. Its rate comes as one of four things (`src`):
##   T   one full turn every T seconds
##   n   n revolutions per minute
##   k   k degrees per second
##   w   w radians per second, in words or as θ = wt
##
## need.ask is the unknown (see CircularMotionViews). generate() returns a Dictionary:
##   paper, ask, rep, ctx   2; the unknown; the representation; an index into the story list
##   src                    how the rate is given, as above
##   T, n, k                ints: the rate as given
##   w                      Q: the rate in radians per second, to 2 d.p.
##   r, d                   Q: the reach or arm, and the line's distance from O
##   ratio                  an index into LANDMARK: d/r on an exact chord, where d is `root` × `dk`
##   dk                     int: an exact chord's r is 2dk
##   deg                    int: an angle in degrees
##   pk                     Q: an angle as a multiple of π
##   th                     Q: an angle in radians, to 2 d.p.
##   tau                    Q: a time in seconds
##
## Paper 2 throughout, as the bank's three parts are. An exact answer is a multiple of π or a whole
## number of seconds, and an answer found on a GDC is to 3 s.f. The clean limits below are the
## numbers behind the catalogue's `clean` text. The SymPy checker holds its own copy.

const TRIES := 8000
const EDGE := 0.03
const SWEEPS := 5
const ROTORS := 5
## cos φ on an exact chord: the text, the root d carries, φ as a multiple of π.
const LANDMARK := [{"text": "1/2", "root": "", "phi": [1, 3]}, {"text": "√2/2", "root": "√2", "phi": [1, 4]}, {"text": "√3/2", "root": "√3", "phi": [1, 6]}]
## Degrees per second, or an angle, that count in landmarks.
const LANDMARK_DEG := [15, 30, 45, 60, 75, 90, 105, 120, 135, 150, 165, 195, 210, 225, 240, 255, 270, 285, 300, 315, 330]
const LANDMARK_RATE := [15, 30, 45, 60, 75, 90, 105, 120, 135, 150]
## A multiple of π that is a landmark: a sixth or a quarter.
const LANDMARK_PI := [[1, 6], [1, 4], [1, 3], [1, 2], [2, 3], [3, 4], [5, 6], [7, 6], [5, 4], [4, 3], [3, 2], [5, 3], [7, 4], [11, 6]]
## d/r stays between these, so A and B are well apart and the chord is not almost a tangent.
const RATIO_LO := 0.25
const RATIO_HI := 0.92
## ... and this far from a landmark cosine, so a chord found on a GDC needs the GDC.
const RATIO_GAP := 0.02
const CHORD := ["half-angle", "chord-angle", "chord-time", "chord-time-rpm", "chord-time-degrees", "dark-time", "fraction-in-view", "arc-past-line"]
const EXACT_CHORD := ["chord-angle-exact", "chord-time-exact"]
const ROTOR := ["arc-in-time", "rim-speed", "rim-speed-rpm"]


static func generate(rng: Seeded, need: Dictionary = {}) -> Dictionary:
	var ask: String = need.get("ask", "chord-time")
	var rep: String = need.get("rep", "words")
	for i in TRIES:
		var s := {"paper": 2, "ask": ask, "rep": rep, "src": "T", "ctx": rng.int_in(0, (ROTORS if ask in ROTOR else SWEEPS) - 1)}
		_draw(rng, s)
		if clear(s):
			return s
	return {}


static func _draw(rng: Seeded, s: Dictionary) -> void:
	var ask: String = s.ask
	if ask in CHORD:
		_chord(rng, s)
	if ask in EXACT_CHORD:
		_exact_chord(rng, s)
	match ask:
		"rate-from-period", "angle-expression":
			_chord(rng, s)
			s.T = 16
			while s.T == 16:
				s.T = rng.int_in(5, 60)
		"angle-after-time":
			s.T = rng.int_in(6, 60)
			s.tau = Q.new(rng.int_in(2, s.T - 1))
		"rate-from-rpm":
			s.src = "n"
			s.n = rng.int_in(2, 40)
		"rate-from-degrees":
			s.src = "k"
			s.k = rng.pick(LANDMARK_RATE)
		"sweep-to-radians":
			s.deg = rng.pick(LANDMARK_DEG)
		"sweep-to-degrees":
			var p: Array = rng.pick(LANDMARK_PI)
			s.pk = Q.new(p[0], p[1])
		"rate-to-degrees", "period-from-rate":
			_w(rng, s)
		"time-to-turn":
			_w(rng, s)
			s.deg = rng.int_in(20, 340)
			while s.deg % 15 == 0:
				s.deg = rng.int_in(20, 340)
		"time-from-period":
			s.T = rng.int_in(6, 60)
			s.th = Q.new(rng.int_in(50, 550), 100)
		"chord-time", "dark-time", "fraction-in-view":
			s.T = rng.int_in(6, 60)
		"chord-time-exact":
			s.T = 12 * rng.int_in(1, 5)
		"chord-time-rpm":
			s.src = "n"
			s.n = rng.int_in(2, 30)
		"chord-time-degrees":
			s.src = "k"
			s.k = rng.int_in(5, 80)
			while s.k % 15 == 0:
				s.k = rng.int_in(5, 80)
		"distance-from-time":
			_back(rng, s)
		"arc-in-time":
			_arm(rng, s)
			s.T = rng.int_in(6, 60)
			s.tau = Q.new(rng.int_in(2, s.T - 1))
		"rim-speed":
			_arm(rng, s)
			s.T = rng.int_in(3, 40)
		"rim-speed-rpm":
			_arm(rng, s)
			s.src = "n"
			s.n = rng.int_in(3, 30)


## A reach to the half metre and a line's distance to 1 d.p., well away from a landmark cosine.
## The bank's own numbers are left out, as its rate is for the exact angle in one second.
static func _chord(rng: Seeded, s: Dictionary) -> void:
	s.r = Q.new(rng.int_in(16, 120), 2)
	while true:
		s.d = Q.new(rng.int_in(5, 1100), 10)
		var c: float = s.d.to_float() / s.r.to_float()
		var bank: bool = s.r.eq(Q.new(20)) and s.d.eq(Q.new(14))
		if c >= RATIO_LO and c <= RATIO_HI and absf(c - 0.5) >= RATIO_GAP and absf(c - sqrt(0.5)) >= RATIO_GAP and absf(c - sqrt(0.75)) >= RATIO_GAP and not bank:
			return


## An even reach and a line at a landmark share of it: k, k√2 or k√3 from O, with r = 2k.
static func _exact_chord(rng: Seeded, s: Dictionary) -> void:
	s.ratio = rng.int_in(0, LANDMARK.size() - 1)
	s.dk = rng.int_in(2, 30)
	s.r = Q.new(2 * s.dk)


static func _w(rng: Seeded, s: Dictionary) -> void:
	s.src = "w"
	s.w = Q.new(rng.int_in(15, 300), 100)


static func _arm(rng: Seeded, s: Dictionary) -> void:
	s.r = Q.new(rng.int_in(20, 140), 10)


## How long the stretch is swept, from which the line's distance is worked back.
static func _back(rng: Seeded, s: Dictionary) -> void:
	s.r = Q.new(rng.int_in(8, 60))
	s.T = rng.int_in(8, 60)
	s.tau = Q.new(rng.int_in(ceili(1.5 * s.T), floori(4.2 * s.T)), 10)


## Half of angle AOB, in radians.
static func phi(s: Dictionary) -> float:
	if s.has("ratio"):
		var p: Array = LANDMARK[s.ratio].phi
		return PI * p[0] / p[1]
	return acos(s.d.to_float() / s.r.to_float())


## The same with the sine: the slip.
static func phi_sin(s: Dictionary) -> float:
	return asin(s.d.to_float() / s.r.to_float())


## The line's distance from O, however it is written.
static func dist(s: Dictionary) -> float:
	return s.r.to_float() * cos(phi(s)) if s.has("ratio") else s.d.to_float()


## The rate in radians per second.
static func rate(s: Dictionary) -> float:
	match s.src:
		"T":
			return TAU / s.T
		"n":
			return TAU * s.n / 60.0
		"k":
			return deg_to_rad(float(s.k))
	return s.w.to_float()


## The time for one turn.
static func period(s: Dictionary) -> float:
	return TAU / rate(s)


## Every value offered is clear of a rounding edge, and each tagged slip reads as its own value. The
## working, which runs on from the figures it shows, lands on the answer, and an answer that ends
## in 0 would read as its own 2 s.f. trap.
static func clear(s: Dictionary) -> bool:
	var v := CircularMotionViews.new()
	var out: Dictionary = v.build(s.ask, s.rep, s, null)
	if out.answer.kind != "number":
		return v.exact_ok(out)
	var text := Fmt.sf(out.answer.values.v)
	if text.right(1) == "0":
		return false
	var vs: Array = [out.answer.values.v]
	for w in out.wrongs:
		vs.append(w.values.v)
	var seen := {}
	for x in vs:
		seen[Fmt.sf(x)] = true
	if seen.size() != vs.size():
		return false
	for g in out.generic:
		vs.append(g.v)
	if not vs.all(func(x): return Answer.rounds_clearly(x.to_float(), EDGE)):
		return false
	return v.chains.all(func(c): return Fmt.sf(c) == text)


static func export(s: Dictionary) -> Dictionary:
	return ExtensionViews.export(s)
