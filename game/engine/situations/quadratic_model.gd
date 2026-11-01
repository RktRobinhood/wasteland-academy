class_name QuadraticModelSituation
extends RefCounted
## The `quadratic-model` situation (curriculum/question-types.json): a quadratic model in
## context, for fn-ext-quadratic-model (FAL-459). It is built from its vertex, so the
## best value is clean.
##
##   ball  a thrown object: h(t) = a(t − T)² + H, a = −5 or −4 (Paper 1) or −4.9 (Paper 2),
##         launched from h0 = h(0)
##   pen   a rectangular pen from L m of fence: against a wall A(x) = x(L − 2x), or free
##         standing A(x) = x(L/2 − x); best width T = L/4 either way
##
## generate() returns ctx ("ball" or "pen"), a, T, H, h0 and the general form a, b, c
## (b and c of a·t² + b·t + c), and for a pen L and wall; with need.land, the landing
## time land (a Q to nine decimal places on Paper 2) and the negative root neg.
##
## The recipe picks its own paper (a ball is Paper 2 about one time in four or five; a
## pen and a table are Paper 1). The type has no exam counts, so QuestionEngine only
## passes need.paper when a view forces one (FAL-419): then Paper 2 is a ball with
## a = −4.9, and Paper 1 a ball with a = −5 or −4, or a pen.

const TRIES := 2000


static func generate(rng: Seeded, need: Dictionary = {}) -> Dictionary:
	var ctx: String = need.get("ctx", "any")
	var forced := int(need.get("paper", 0))
	for i in TRIES:
		var c := ctx if ctx != "any" else ("ball" if forced == 2 or rng.chance(0.6) else "pen")
		var s := _ball(rng, need) if c == "ball" else _pen(rng, need)
		if not s.is_empty():
			s.ctx = c
			s.b = s.a.mul(s.T).mul(-2)
			s.c = s.h0
			return s
	push_error("QuadraticModelSituation: no clean situation for %s" % need)
	return {}


static func _ball(rng: Seeded, need: Dictionary) -> Dictionary:
	var paper2: bool = need.get("land", false) and rng.chance(0.25) or (not need.get("land", false) and not need.get("table", false) and rng.chance(0.2))
	if need.has("paper"):
		paper2 = int(need.paper) == 2 and not need.get("table", false)
	var a := Q.new(-49, 10) if paper2 else Q.new(rng.pick([-5, -4]))
	var T: Q
	if a.eq(-4) and not need.get("table", false) and rng.chance(0.5):
		T = Q.new(2 * rng.int_in(1, 3) + 1, 2)
	else:
		T = Q.new(rng.int_in(1, 3 if need.get("table", false) else 4))
	if need.get("land", false) and not paper2:
		# h(t) = a(t − T)² + H with roots T ± m: the negative one is rejected.
		var m := T.add(rng.int_in(1, 3))
		if not T.is_int():
			m = T.add(Q.new(2 * rng.int_in(0, 2) + 1, 2))
		var H := a.neg().mul(m.sq())
		var h0 := a.mul(T.sq()).add(H)
		if h0.to_float() > 60.0:
			return {}
		return {"a": a, "T": T, "H": H, "h0": h0, "land": T.add(m), "neg": T.sub(m), "paper": 1}
	var h0 := Q.new(rng.int_in(1, 20)) if not paper2 else Q.new(rng.int_in(10, 25), 10)
	var H := h0.sub(a.mul(T.sq()))
	if H.to_float() > 90.0:
		return {}
	var s := {"a": a, "T": T, "H": H, "h0": h0, "paper": 2 if paper2 else 1}
	if need.get("land", false):
		var r := sqrt(H.div(a.neg()).to_float())
		var land := T.to_float() + r
		# Clear of a rounding edge, and with a third figure that isn't 0 (4.10), where the
		# 2 s.f. rounding trap would be the answer itself.
		if not Answer.rounds_clearly(land) or Fmt.sf(land).ends_with("0"):
			return {}
		s.land = Q.new(roundi(land * 1e9), 1000000000)
		s.neg = Q.new(roundi((T.to_float() - r) * 1e9), 1000000000)
	return s


static func _pen(rng: Seeded, need: Dictionary) -> Dictionary:
	var wall: bool = need.get("wall", rng.chance(0.5))
	var L := 4 * rng.int_in(3, 15) if not need.get("table", false) else 4 * rng.int_in(3, 6)
	var T := Q.new(L, 4)
	var a := Q.new(-2 if wall else -1)
	var H := Q.new(L * L, 8 if wall else 16)
	if not H.is_int():
		return {}
	return {"a": a, "T": T, "H": H, "h0": Q.new(0), "L": Q.new(L), "wall": wall, "paper": 1}


## The model's value at t.
static func f(s: Dictionary, t: Q) -> Q:
	return s.a.mul(t.sub(s.T).sq()).add(s.H)


static func export(s: Dictionary) -> Dictionary:
	return ExtensionViews.export(s)
