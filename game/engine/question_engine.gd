class_name QuestionEngine
extends RefCounted
## The question engine: situations and views (FAL-310 plan), on the catalogue in
## res://data/catalogue.json (generated from curriculum/question-types.json).
##
## Any screen can ask for a question by an explicit view:
##   var q := QuestionEngine.make({"type": "fn-quadratic-features", "unknown": "vertex-from-general",
##       "rep": "equation", "angle": "complete-square", "format": "value", "seed": 7})
## and gets back the question, its marking (QuestionEngine.mark) and its worked
## solution (q.solutions). The same view and seed always give the same question.
## The planner (planner.gd) is one caller; the practice screen and later The Relic
## lessons are others.
##
## A coverage cell is one type × unknown × representation × angle the catalogue lists
## and a builder can make: QuestionEngine.cells().

const CATALOGUE := "res://data/catalogue.json"

## The eight formats of the FAL-310 plan. BUILT are the ones a question can use now;
## the rest are named so a view can ask for them and get a clear "not built yet".
const FORMATS := ["value", "mcq", "error-spot", "method-pick", "true-false-reason", "match", "order-steps", "pick-the-graph"]
const BUILT := ["value", "mcq", "error-spot", "method-pick", "true-false-reason", "pick-the-graph"]
const CHOICES := 4
## The formats built on a question (FAL-459), each played as four options like mcq:
## error-spot (which line of a student's working is the first wrong one),
## method-pick (which method works) and true-false-reason (is a student's answer
## right, and if not, what should it be). A cell offers one only where its type's
## catalogue `formats` lists it and its views build it (views.formats(unknown)).
const EXTRA_FORMATS := ["error-spot", "method-pick", "true-false-reason"]
const CHOICE_FORMATS := ["mcq", "error-spot", "method-pick", "true-false-reason", "pick-the-graph"]
## Pick the graph (Q13, FAL-420; the catalogue's `graph-pick`): students can't draw, so a
## sketch question shows four graphs, q.graphs, and asks which is right. Its answer is
## the `graph` kind ("Graph A" to "Graph D"), so any view whose builder makes one plays
## it, whatever format was asked. Each wrong graph changes one thing, a typical mistake:
## its option's `ref` is the misconception (logged like any other), `mistake` names the
## change (the checker tests it) and `why` says what is wrong with it.
## The share of a cell's questions the planner asks in one of its extra formats.
const EXTRA_SHARE := 0.3

## Situation id -> [recipe, views]. A situation that `extends` another one (say
## quadratic-inequality) gets its own entry: a recipe that calls the base recipe's
## generate() and adds its quantities, and views for its unknowns.
static var SITUATIONS := {
	"quadratic": [QuadraticSituation, QuadraticViews],
	"triangle": [TriangleSituation, TriangleViews],
	"arithmetic-sequence": [ArithmeticSequenceSituation, ArithmeticSequenceViews],
	"distribution": [DistributionSituation, DistributionViews],
	"quadratic-parameter": [QuadraticParameterSituation, QuadraticParameterViews],
	"curve-and-line": [CurveLineSituation, CurveLineViews],
	"quadratic-equation": [QuadraticEquationSituation, QuadraticEquationViews],
	"quadratic-inequality": [QuadraticInequalitySituation, QuadraticInequalityViews],
	"cubic": [CubicSituation, CubicViews],
	"fn-pre-expand": [ExpandSituation, ExpandViews],
	"fn-pre-factorise": [FactoriseSituation, FactoriseViews],
	"fn-pre-surds": [SurdsSituation, SurdsViews],
	"fn-pre-linear-inequalities": [LinearInequalitySituation, LinearInequalityViews],
	"quadratic-model": [QuadraticModelSituation, QuadraticModelViews],
	"fn-link-equivalent-forms": [EquivalentFormsSituation, EquivalentFormsViews],
	"fn-link-symmetry": [SymmetrySituation, SymmetryViews],
	"exp-model": [ExpModelSituation, ExpModelViews],
	"exp-log-pair": [ExpLogPairSituation, ExpLogPairViews],
	"log-quadratic": [LogQuadraticSituation, LogQuadraticViews],
	"log-function": [LogFunctionSituation, LogFunctionViews],
	"fn-pre-percent-multiplier": [PercentSituation, PercentViews],
	"exp-growth-vs-linear": [GrowthPatternsSituation, GrowthPatternsViews],
	"fn-link-multiplicative-growth": [LinkGrowthSituation, LinkGrowthViews],
	"gdc-curve": [GdcCurveSituation, GdcCurveViews],
	"gdc-two-curves": [GdcTwoCurvesSituation, GdcTwoCurvesViews],
	"gdc-combined": [GdcCombinedSituation, GdcCombinedViews],
	"gdc-context-equation": [GdcContextEquationSituation, GdcContextEquationViews],
	"graph-from-features": [GraphFromFeaturesSituation, GraphFromFeaturesViews],
	"gdc-inequality": [GdcInequalitySituation, GdcInequalityViews],
	"fn-pre-graph-reading": [GraphReadingSituation, GraphReadingViews],
}

static var _cat: Dictionary = {}
static var _views: Dictionary = {}


static func catalogue() -> Dictionary:
	if _cat.is_empty():
		var f := FileAccess.open(CATALOGUE, FileAccess.READ)
		_cat = JSON.parse_string(f.get_as_text()) if f != null else {}
		if _cat == null or _cat.is_empty():
			push_error("QuestionEngine: could not read %s" % CATALOGUE)
			_cat = {"types": [], "situations": {}}
	return _cat


static func type_of(id: String) -> Dictionary:
	for t in catalogue().types:
		if t.id == id:
			return t
	return {}


## The views object for a type's situation, or null when its situation isn't built.
static func views_for(t: Dictionary) -> Object:
	var sit: String = t.get("situation", "")
	if not SITUATIONS.has(sit):
		return null
	if not _views.has(sit):
		_views[sit] = SITUATIONS[sit][1].new()
	return _views[sit]


## Types the engine can make questions for: every unknown has a builder.
static func built_types() -> Array:
	var out: Array = []
	for t in catalogue().types:
		var v = views_for(t)
		if v == null:
			continue
		var all := true
		for u in t.unknowns:
			if not v.has(u.id):
				all = false
		if all:
			out.append(t.id)
	return out


static func unknown_of(t: Dictionary, id: String) -> Dictionary:
	for u in t.get("unknowns", []):
		if u.id == id:
			return u
	return {}


## The angles (method ids) that suit an unknown, in catalogue order; ["any"] if none.
static func angles_for(t: Dictionary, unknown: String) -> Array:
	var out: Array = []
	for a in t.get("angles", []):
		if unknown in a.suits and not out.has(a.method):
			out.append(a.method)
	return out if not out.is_empty() else ["any"]


static func angle_info(t: Dictionary, unknown: String, method: String) -> Dictionary:
	for a in t.get("angles", []):
		if a.method == method and unknown in a.suits:
			return a
	return {}


static func rep_is_exam(t: Dictionary, rep: String) -> bool:
	for r in t.get("representations", []):
		if r.rep == rep:
			return bool(r.exam)
	return false


## Every coverage cell of the built types (or of `types`), each
## {"key", "type", "unknown", "rep", "angle", "level", "exam", "weight"}.
## exam_only keeps exam types and their exam unknowns and representations.
static func cells(exam_only: bool = false, types: Array = []) -> Array:
	var out: Array = []
	var ids := types if not types.is_empty() else built_types()
	for id in ids:
		var t := type_of(id)
		var exam_type: bool = t.source == "exam"
		if exam_only and not exam_type:
			continue
		for u in t.unknowns:
			if exam_only and not u.exam:
				continue
			for rep in u.reps:
				var exam: bool = exam_type and bool(u.exam) and rep_is_exam(t, rep)
				if exam_only and not exam:
					continue
				for angle in angles_for(t, u.id):
					out.append({"key": cell_key(id, u.id, rep, angle), "type": id, "unknown": u.id, "rep": rep,
						"angle": angle, "level": int(u.level), "exam": exam})
	return out


static func cell_key(type: String, unknown: String, rep: String, angle: String) -> String:
	return "%s|%s|%s|%s" % [type, unknown, rep, angle]


## Whether a question is answered by picking one of its options.
static func is_choice(q: Dictionary) -> bool:
	return q.get("format", "") in CHOICE_FORMATS


## The extra formats (EXTRA_FORMATS) a cell can be asked in: listed in its type's
## `formats` and built by its views for the unknown. method-pick needs a method that
## works: not "any", and not one the catalogue says fails for the unknown.
static func extra_formats(type_id: String, unknown: String, angle: String) -> Array:
	var t := type_of(type_id)
	var views = views_for(t)
	if views == null or not views.has_method("formats"):
		return []
	var listed: Array = t.get("formats", [])
	var works := angle != "any" and not fails(t, unknown, angle)
	return views.formats(unknown).filter(func(f): return f in EXTRA_FORMATS and f in listed and (f != "method-pick" or works))


## Whether the catalogue says a method fails for an unknown (its angle's weak kind).
static func fails(t: Dictionary, unknown: String, method: String) -> bool:
	for a in t.get("angles", []):
		var weak: Dictionary = a.get("weak", {})
		if a.method == method and weak.get("kind") == "fails" and unknown in weak.get("unknowns", []):
			return true
	return false


## The planner's and the dungeon's format, switched to one of the cell's extra
## formats about EXTRA_SHARE of the time. It draws only for a cell that has one, so
## every other cell's stream is unchanged.
static func upgrade_format(c: Dictionary, fmt: String, rng: Seeded) -> String:
	var extra := extra_formats(c.type, c.unknown, c.angle)
	if extra.is_empty() or not rng.chance(EXTRA_SHARE):
		return fmt
	return extra[rng.int_in(0, extra.size() - 1)]


# ── One situation, many questions ────────────────────────────
# Each view sets its own `need`, so on its own each unknown gets its own numbers. To
# ask one situation from many unknowns, the unknowns of a type that list a
# representation are split into families whose needs merge without a conflict. A
# family's situation is generated from the merged need, which is at least as strict as
# each member's own, so every member's view can be built on it. make() with
# "shared": true does that: the same type, representation, family and seed give the
# same numbers whichever unknown is asked. The explorer screen's "Ask it another way"
# uses it.

static var _families := {}


## The families of a type in a representation, in catalogue order. Each is
## {"unknowns": [ids], "need": merged need}. An unknown joins the first family its need
## merges with, so the split doesn't depend on which unknown is asked first.
static func families(type_id: String, rep: String) -> Array:
	var key := "%s|%s" % [type_id, rep]
	if _families.has(key):
		return _families[key]
	var out: Array = []
	var t := type_of(type_id)
	var views = views_for(t)
	if views != null:
		for u in t.get("unknowns", []):
			if not rep in u.reps or not views.has(u.id):
				continue
			var own: Dictionary = views.need(u.id, rep)
			var placed := false
			for fam in out:
				var merged = views.merge_need(fam.need, own) if views.has_method("merge_need") else merge_need(fam.need, own)
				if merged != null:
					fam.need = merged
					fam.unknowns.append(u.id)
					placed = true
					break
			if not placed:
				out.append({"unknowns": [u.id], "need": own.duplicate()})
	_families[key] = out
	return out


static func family_of(type_id: String, unknown: String, rep: String) -> Dictionary:
	for fam in families(type_id, rep):
		if unknown in fam.unknowns:
			return fam
	return {"unknowns": [unknown], "need": {}}


## Two needs as one, or null if they conflict. A situation's views can define their own
## merge_need(); this is the default. A missing key takes the other's value; booleans
## are or-ed (they ask for more, never less); "any" gives way to a set value, and true
## to a more particular one (table: true and table: "roots" make "roots"). Any other
## difference is a conflict.
static func merge_need(a: Dictionary, b: Dictionary) -> Variant:
	var out := a.duplicate()
	for k in b:
		var y = b[k]
		if not out.has(k):
			out[k] = y
			continue
		var x = out[k]
		if typeof(x) == typeof(y) and x == y:
			continue
		if x is bool and y is bool:
			out[k] = x or y
		elif (x is bool and not x) or (x is String and x == "any") or (x is bool and not (y is bool)):
			out[k] = y
		elif (y is bool and not y) or (y is String and y == "any") or (y is bool and not (x is bool)):
			out[k] = x
		else:
			return null
	return out


# ── Paper 1 or 2 (FAL-419) ───────────────────────────────────
# Every question is Paper 1 (no calculator: its numbers come out exact) or Paper 2 (a
# calculator: numbers that need one), and carries it as `paper`. A type the IB asks on
# both papers makes both, in the ratio of its bank parts (the catalogue's `paper`,
# {"p1", "p2"}). Each cell says which papers its views can make
# (views.papers(unknown, rep, angle)); the cells that can make both make up for the
# cells that can't, so the type as a whole lands on the exam's share. The paper is
# drawn from its own seeded stream, so the recipe's numbers stream is untouched, and the
# recipe is told it as need.paper. A situation that sets its own `paper` has the last
# word, so the badge always matches the numbers. A type with no exam counts (an
# extension type) gets no need.paper, and its recipe decides as before.

static var _paper_chance := {}


## The Paper 2 share of a type's exam parts, or -1.0 when the catalogue has none.
static func paper_share(t: Dictionary) -> float:
	var p: Dictionary = t.get("paper", {})
	var total := int(p.get("p1", 0)) + int(p.get("p2", 0))
	return float(p.get("p2", 0)) / total if total > 0 else -1.0


## The papers a cell can be asked on. Views say (papers(unknown, rep, angle)); where
## they don't, a type the exam asks on one paper only gets that paper, a type with no
## exam counts gets [] (its recipe decides, and sets the situation's `paper`), and any
## other gets Paper 1.
static func cell_papers(t: Dictionary, unknown: String, rep: String, angle: String) -> Array:
	var views = views_for(t)
	if views != null and views.has_method("papers"):
		var own: Array = views.papers(unknown, rep, angle)
		if not own.is_empty():
			return own
	var share := paper_share(t)
	if share < 0.0:
		return []
	return [2] if share == 1.0 else [1]


## The chance that a cell able to make both papers makes Paper 2, chosen so the type's
## cells together land on paper_share(): (share × cells − Paper 2-only cells) ÷ cells
## that can make both, kept between 0 and 1.
static func paper_chance(t: Dictionary) -> float:
	if _paper_chance.has(t.id):
		return _paper_chance[t.id]
	var share := paper_share(t)
	var only2 := 0
	var both := 0
	var all := 0
	for c in cells(false, [t.id]):
		var ps := cell_papers(t, c.unknown, c.rep, c.angle)
		all += 1
		if ps == [2]:
			only2 += 1
		elif ps.size() > 1:
			both += 1
	var chance := 0.0
	if share >= 0.0 and both > 0:
		chance = clampf((share * all - only2) / both, 0.0, 1.0)
	_paper_chance[t.id] = chance
	return chance


## The paper for a question: forced (1 or 2, where the cell can make it), the one
## paper the cell can make, or drawn at paper_chance(). 0 for a type with no exam
## counts, whose recipe decides.
static func _pick_paper(t: Dictionary, papers: Array, key: String, forced: Variant) -> int:
	if int(forced) in papers:
		return int(forced)
	if papers.is_empty() or paper_share(t) < 0.0:
		return 0
	if papers.size() == 1:
		return int(papers[0])
	var rng := Seeded.new("paper|" + key)
	# The stream's first draw leans low (FAL-460), so it is spent first.
	rng.int_in(0, 1)
	return 2 if rng.chance(paper_chance(t)) else 1


## Makes the question for a view. Returns {"error": "..."} if the view can't be made.
static func make(view: Dictionary) -> Dictionary:
	var v := _resolve(view)
	if v.has("error"):
		return v
	# "Another way" (FAL-310): a view with same_angle asks the question that angle made,
	# the same numbers, but by this view's angle.
	var rng_angle: String = view.get("same_angle", v.angle)
	var shared: bool = view.get("shared", false)
	var rng := Seeded.new("%s|%d" % [cell_key(v.t.id, v.u.id, v.rep, rng_angle), v.seed])
	var recipe = SITUATIONS[v.t.situation][0]
	var s: Dictionary
	var paper := 0
	if shared:
		var fam := family_of(v.t.id, v.u.id, v.rep)
		var fam_key := "%s|%s|%s|%d" % [v.t.id, v.rep, ",".join(fam.unknowns), v.seed]
		# One paper for the whole family, so every unknown asks the same numbers.
		var both := [1, 2]
		for id in fam.unknowns:
			both = both.filter(func(p): return p in cell_papers(v.t, id, v.rep, v.angle))
		paper = _pick_paper(v.t, both if not both.is_empty() else [1], fam_key, view.get("paper", 0))
		var fn: Dictionary = fam.need.duplicate()
		if paper > 0:
			fn["paper"] = paper
		s = recipe.generate(Seeded.new(fam_key), fn)
	else:
		# The method that made the numbers rides along, for recipes whose numbers depend
		# on it (a Paper 2 context that a factorising method can't solve). It is the
		# stream's angle, not this view's, so "Another way" keeps the numbers; the view's
		# working then says where its method fails. A shared situation belongs to the
		# family, not to a method, so it gets none. Other recipes ignore it.
		var nd: Dictionary = v.views.need(v.u.id, v.rep)
		nd["angle"] = rng_angle
		var key := "%s|%d" % [cell_key(v.t.id, v.u.id, v.rep, rng_angle), v.seed]
		paper = _pick_paper(v.t, cell_papers(v.t, v.u.id, v.rep, rng_angle), key, view.get("paper", 0))
		if paper > 0:
			nd["paper"] = paper
		s = recipe.generate(rng, nd)
	if s.is_empty():
		return {"error": "no clean situation for %s" % cell_key(v.t.id, v.u.id, v.rep, v.angle)}
	var q := _build(v, s, rng)
	q.paper = int(s.get("paper", paper if paper > 0 else 1))
	if rng_angle != v.angle:
		q.view.same_angle = rng_angle
	if shared:
		q.view.shared = true
	return q


## Makes the linked parts of a mini-boss or boss (Q9): every part is asked on one
## situation, generated once from the needs of all of them together. steps is
## [{"type", "unknown", "rep"?, "angle"?, "format"?}], in chain order. Each part is a
## question like make()'s, plus "part" (0, 1, ...) and, from the second part on,
## "carried": the part before's right answer {"part", "asked", "values", "text"}, which
## the next part carries on from whatever the player answered (IB follow-through).
## Returns {"parts": [...], "situation"} or {"error"}.
static func make_chain(steps: Array, seed: int) -> Dictionary:
	if steps.is_empty():
		return {"error": "a chain needs steps"}
	var vs: Array = []
	var need := {}
	var sit := ""
	var keys: Array = []
	for step in steps:
		var v := _resolve(step.merged({"seed": seed}))
		if v.has("error"):
			return v
		if sit != "" and v.t.situation != sit:
			return {"error": "%s is on %s, not %s" % [v.t.id, v.t.situation, sit]}
		sit = v.t.situation
		# The first part's method shapes the numbers, where a recipe reads it.
		var nd: Dictionary = v.views.need(v.u.id, v.rep)
		if not need.has("angle"):
			nd["angle"] = v.angle
		var merged := merge_needs(need, nd)
		if merged.has("error"):
			return {"error": "%s|%s: %s" % [v.t.id, v.u.id, merged.error]}
		need = merged
		vs.append(v)
		keys.append("%s:%s" % [v.t.id, v.u.id])
	var chain_key := "chain|%s|%d" % ["+".join(keys), seed]
	# One paper for the whole chain: one that every part can be asked on.
	var both := [1, 2]
	for v in vs:
		both = both.filter(func(p): return p in cell_papers(v.t, v.u.id, v.rep, v.angle))
	var paper := _pick_paper(vs[0].t, both if not both.is_empty() else [1], chain_key, 0)
	if paper > 0:
		need["paper"] = paper
	var s: Dictionary = SITUATIONS[sit][0].generate(Seeded.new(chain_key), need)
	if s.is_empty():
		return {"error": "no clean situation for %s" % chain_key}
	var parts: Array = []
	for i in vs.size():
		var q := _build(vs[i], s, Seeded.new("%s|part %d" % [chain_key, i]))
		q.part = i
		q.paper = int(s.get("paper", paper if paper > 0 else 1))
		if i > 0:
			var before: Dictionary = parts[i - 1]
			q.carried = {"part": part_letter(i - 1), "asked": before.asked, "values": before.answer.values,
				"text": before.answer_text}
		parts.append(q)
	return {"parts": parts, "situation": SITUATIONS[sit][0].export(s)}


## (a), (b), ... for part i.
static func part_letter(i: int) -> String:
	return String.chr(97 + i)


## Two views' situation needs as one, or {"error"} where they can't both hold. A flag
## is needed if either needs it; a list (situation families) keeps what both allow; a
## mode "any..." gives way to a named one; anything else must be equal.
static func merge_needs(a: Dictionary, b: Dictionary) -> Dictionary:
	var out := a.duplicate(true)
	for key in b:
		var x = b[key]
		if not out.has(key):
			out[key] = x
			continue
		var y = out[key]
		if typeof(x) == TYPE_BOOL and typeof(y) == TYPE_BOOL:
			out[key] = x or y
		elif x is Array and y is Array:
			var both: Array = y.filter(func(e): return e in x)
			if both.is_empty():
				return {"error": "%s %s and %s share nothing" % [key, y, x]}
			out[key] = both
		elif typeof(x) == TYPE_BOOL or typeof(y) == TYPE_BOOL:
			# table: true and table: "roots" -> "roots"
			out[key] = y if typeof(x) == TYPE_BOOL else x
		elif x is String and y is String and x != y:
			if x.begins_with("any"):
				out[key] = y
			elif y.begins_with("any"):
				out[key] = x
			else:
				return {"error": "%s %s and %s clash" % [key, y, x]}
		elif x != y:
			return {"error": "%s %s and %s clash" % [key, y, x]}
	return out


## A view's type, unknown, representation, angle, format and seed, checked against the
## catalogue, or {"error"}.
static func _resolve(view: Dictionary) -> Dictionary:
	var t := type_of(view.get("type", ""))
	if t.is_empty():
		return {"error": "unknown type %s" % view.get("type")}
	var views = views_for(t)
	if views == null:
		return {"error": "situation %s is not built yet" % t.get("situation")}
	var u := unknown_of(t, view.get("unknown", ""))
	if u.is_empty() or not views.has(u.id):
		return {"error": "unknown %s is not built for %s" % [view.get("unknown"), t.id]}
	var rep: String = view.get("rep", u.reps[0])
	if not rep in u.reps:
		return {"error": "%s is not listed in %s for %s" % [rep, "representations", u.id]}
	var angles := angles_for(t, u.id)
	var angle: String = view.get("angle", angles[0])
	if angle != "any" and not angle in angles:
		return {"error": "method %s does not suit %s" % [angle, u.id]}
	var fmt: String = view.get("format", "value")
	if not fmt in FORMATS:
		return {"error": "unknown format %s" % fmt}
	if not fmt in BUILT:
		return {"error": "format %s is not built yet" % fmt}
	if fmt in EXTRA_FORMATS and not fmt in extra_formats(t.id, u.id, angle):
		return {"error": "format %s is not built for %s" % [fmt, cell_key(t.id, u.id, rep, angle)]}
	return {"t": t, "u": u, "views": views, "rep": rep, "angles": angles, "angle": angle, "format": fmt,
		"seed": int(view.get("seed", 0)), "marks": int(view.get("marks", t.get("marks", 0)))}


## The question for a resolved view on a situation.
static func _build(v: Dictionary, s: Dictionary, rng: Seeded) -> Dictionary:
	var t: Dictionary = v.t
	var u: Dictionary = v.u
	var angle: String = v.angle
	var fmt: String = v.format
	# An extra format is built on the question's multiple-choice form.
	var extra := ""
	if fmt in EXTRA_FORMATS:
		extra = fmt
		fmt = "mcq"
	# Views whose context hangs on the method (fn-link-symmetry's find-the-mirror: a
	# parabola, or nCr) are told it.
	var b: Dictionary = v.views.build_view(u.id, v.rep, angle, s, rng) if v.views.has_method("build_view") else v.views.build(u.id, v.rep, s, rng)
	var ans: Dictionary = b.answer
	if ans.kind in Answer.MC_ONLY:
		fmt = "mcq"
	if ans.kind == "graph":
		fmt = "pick-the-graph"
	elif fmt == "pick-the-graph":
		fmt = "mcq"

	var prompt: String = b.asked
	if angle != "any":
		prompt += "\nMethod: %s." % angle_info(t, u.id, angle).name
	var solutions: Array = []
	var order: Array = [angle] if angle != "any" else []
	for a in v.angles:
		if not order.has(a):
			order.append(a)
	for a in order:
		if b.methods.has(a):
			var info := angle_info(t, u.id, a)
			solutions.append({"angle": a, "name": info.get("name", "Worked solution"), "steps": b.methods[a].steps,
				"result": b.methods[a].result})
	var choices := _choices(ans, b, rng) if fmt != "pick-the-graph" else _graph_choices(b)
	var out_view := {"type": t.id, "unknown": u.id, "rep": v.rep, "angle": angle, "format": fmt, "seed": v.seed}
	var q := {
		"view": out_view,
		"marks": v.marks,
		"cell": cell_key(t.id, u.id, v.rep, angle),
		"type_name": t.name, "level": int(u.level),
		"exam": t.source == "exam" and bool(u.exam) and rep_is_exam(t, v.rep),
		"format": fmt, "prompt": prompt, "asked": b.asked, "rep": v.rep,
		"lines": b.lines, "graph": b.graph, "table": b.table, "diagram": b.get("diagram"),
		"answer": ans, "answer_text": Answer.text(ans),
		"choices": choices, "solutions": solutions,
		"given": b.given, "situation_id": t.situation, "situation": SITUATIONS[t.situation][0].export(s),
	}
	if fmt == "pick-the-graph":
		q.graphs = b.graphs.map(func(g): return g.graph)
		var reasons: Array = []
		for c in choices:
			if not c.correct and c.why != "":
				reasons.append("%s: %s." % [c.text, c.why.rstrip(".")])
		q.reason = " ".join(reasons)
	elif extra != "":
		_reformat(q, v, b, extra)
	return q


## The options of a pick-the-graph question, in its graphs' letter order (GdcKit.pick):
## each "Graph A" to "Graph D", with the misconception (`ref`) its wrong graph shows.
static func _graph_choices(b: Dictionary) -> Array:
	return b.graphs.map(func(g): return {"text": g.text, "values": {"v": g.text}, "correct": g.correct, "ref": g.ref,
		"mistake": g.mistake, "why": g.why})


## Four options: the answer and three wrong ones. The view's rounding trap (Q7) comes
## first where it fits, then misconception options, each tagged with its ref; generic
## ones and, if still short, a nudged number fill the rest. No two options are equal.
static func _choices(ans: Dictionary, b: Dictionary, rng: Seeded) -> Array:
	var seen := {Answer.canon(ans, ans.values): true}
	var picked: Array = []
	var pool: Array = []
	# A view whose misconception is "too few figures" (SL2.4.max-min#2) tags its trap
	# with it (trap_ref), so picking it is a glancing hit that logs the misconception.
	if not b.get("trap", {}).is_empty():
		pool.append({"values": b.trap, "ref": b.get("trap_ref", ""), "trap": true})
	for w in b.wrongs:
		pool.append(w)
	for g in b.generic:
		pool.append({"values": g, "ref": ""})
	for nudge in _nudges(ans):
		pool.append({"values": nudge, "ref": ""})
	for w in pool:
		if picked.size() >= CHOICES - 1:
			break
		if not _usable(ans, w.values):
			continue
		var key := Answer.canon(ans, w.values)
		if seen.has(key):
			continue
		seen[key] = true
		picked.append(w)
	var opts: Array = [{"text": Answer.text(ans), "values": ans.values, "correct": true, "ref": ""}]
	for w in picked:
		var trap: bool = w.get("trap", false)
		opts.append({"text": Answer.trap_text(ans, w.values) if trap else Answer.text(ans, w.values), "values": w.values,
			"correct": false, "ref": w.ref, "trap": trap})
	return rng.shuffled(opts)


## The catalogue text of a misconception ref ("" if the type has none by that ref).
## A misconception without a ref of its own is "<type id>#<index>".
static func misconception_text(t: Dictionary, ref: String) -> String:
	var ms: Array = t.get("misconceptions", [])
	for i in ms.size():
		if ms[i].get("ref", "%s#%d" % [t.id, i]) == ref:
			return ms[i].text
	return ""


## Turns a built multiple-choice question into an extra format, in place. The
## question's answer, working and its own options (kept as base_choices, for the
## checker) stay; the prompt and the four options change, and `reason` says why
## the right option is right.
static func _reformat(q: Dictionary, v: Dictionary, b: Dictionary, fmt: String) -> void:
	var t: Dictionary = v.t
	var rng := Seeded.new("%s|%s|%d" % [q.cell, fmt, v.seed])
	# The stream's first draw leans low (FAL-460), so it is spent before anything is picked.
	rng.int_in(0, 1)
	q.base_choices = q.choices
	q.format = fmt
	q.view.format = fmt
	var opts: Array = []
	match fmt:
		"true-false-reason":
			var right: Dictionary = q.choices.filter(func(c): return c.correct)[0]
			var wrongs: Array = q.choices.filter(func(c): return not c.correct)
			var claims: Array = wrongs.filter(func(c): return not c.get("trap", false))
			var tagged: Array = claims.filter(func(c): return c.ref != "")
			var claim: Dictionary = right
			if not claims.is_empty() and not rng.chance(0.5):
				claim = rng.pick(tagged if not tagged.is_empty() else claims)
			if claim.correct:
				opts.append({"text": "True", "correct": true, "ref": ""})
			else:
				opts.append({"text": "False: it should be %s" % right.text, "correct": true, "ref": ""})
				# Agreeing with a misconception's answer is that misconception.
				opts.append({"text": "True", "correct": false, "ref": claim.ref})
			for w in wrongs:
				if opts.size() < CHOICES and w != claim:
					opts.append({"text": "False: it should be %s" % w.text, "correct": false, "ref": ""})
			q.claim = claim.text
			q.prompt = "%s\nA student's answer: %s. True or false?" % [b.asked, claim.text]
			var why := misconception_text(t, claim.ref) if not claim.correct else ""
			if claim.correct:
				q.reason = "The student is right: the answer is %s." % right.text
			else:
				q.reason = "The answer is %s, not %s." % [right.text, claim.text] + (" The mistake: %s." % why.rstrip(".") if why != "" else "")
		"method-pick":
			var right_name: String = angle_info(t, v.u.id, v.angle).name
			var works: Array = v.angles.filter(func(a): return not fails(t, v.u.id, a)).map(func(a): return angle_info(t, v.u.id, a).get("name", a))
			var pool: Array = []
			for a in t.get("angles", []):
				if fails(t, v.u.id, a.method):
					pool.append({"name": a.name, "why": a.weak.why})
			pool.append_array(b.get("pick_wrongs", []))
			opts.append({"text": right_name, "correct": true, "ref": ""})
			var whys: Array = []
			for w in pool:
				if opts.size() >= CHOICES:
					break
				if w.name in works or opts.any(func(o): return o.text == w.name):
					continue
				opts.append({"text": w.name, "correct": false, "ref": ""})
				whys.append("%s: %s." % [w.name, w.why.rstrip(".")])
			q.prompt = "%s\nWhich method works for this question?" % b.asked
			q.reason = "%s works. %s" % [right_name, " ".join(whys)]
		"error-spot":
			var spot: Dictionary = b.spot
			var shown: Array = q.lines.duplicate()
			shown.append("A student's working:")
			for i in spot.lines.size():
				shown.append("Line %d: %s" % [i + 1, spot.lines[i]])
				opts.append({"text": "Line %d" % (i + 1), "correct": i == spot.bad, "ref": ""})
			q.lines = shown
			q.spot = {"lines": spot.lines, "bad": spot.bad, "ref": spot.ref}
			q.prompt = "%s\nA student answered this. Which line has the first mistake?" % b.asked
			q.reason = "Line %d is wrong: %s." % [spot.bad + 1, spot.why.rstrip(".")]
	for o in opts:
		o.values = {"v": o.text}
	q.choices = opts if fmt == "error-spot" else rng.shuffled(opts)


## A wrong option must still be a well-formed answer: no zero leading coefficient, and
## a measure (shown to 3 s.f.) that is positive (or, for a signed one such as a decay
## rate, not zero) and not on a rounding edge.
static func _usable(ans: Dictionary, values: Dictionary) -> bool:
	if ans.kind == "measure":
		var x: float = Q.of(values.v).to_float()
		return (x > 0.0 or (ans.get("signed", false) and x != 0.0)) and Answer.rounds_clearly(x)
	for id in ["a", "ga", "fa", "va"]:
		if values.has(id) and values[id] is Q and values[id].is_zero():
			return false
	return true


## Last-resort wrong options: each typed number nudged by 1 either way.
static func _nudges(ans: Dictionary) -> Array:
	var out: Array = []
	for d in [1, -1, 2]:
		for item in Answer.slots(ans):
			if not item.has("slot"):
				continue
			var v := (ans.values as Dictionary).duplicate()
			v[item.slot] = Q.of(v[item.slot]).add(d)
			out.append(v)
	return out


## Marks a response. For "mcq", response is {"choice": index}; for "value", it is
## slot id -> typed text. Returns {"correct", "complete", "glancing", "errors",
## "misconception"}: glancing is the right value with too few figures, or the rounding
## trap picked (Q7); misconception is the ref of the wrong option the answer matches, or "".
static func mark(question: Dictionary, response: Dictionary) -> Dictionary:
	if is_choice(question):
		var i := int(response.get("choice", -1))
		if i < 0 or i >= question.choices.size():
			return {"correct": false, "complete": false, "glancing": false, "errors": {"choice": "Choose one."}, "misconception": ""}
		var c: Dictionary = question.choices[i]
		return {"correct": c.correct, "complete": true, "glancing": c.get("trap", false), "errors": {}, "misconception": c.ref}
	var r := Answer.mark(question.answer, response)
	r.misconception = ""
	if r.complete and not r.correct:
		for c in question.choices:
			if not c.correct and c.ref != "" and Answer.typable(question.answer, c.values) \
					and Answer.values_right(Answer.with_values(question.answer, c.values), r.values):
				r.misconception = c.ref
				break
	return r


# ── Concept probes ───────────────────────────────────────────

const VERDICTS := {
	"true-false-reason": ["True", "False"],
	"always-sometimes-never": ["Always", "Sometimes", "Never"],
	"predict-check": ["Positive", "Negative"],
}
const SELF_MARK := ["I had it", "Not yet"]


## Every concept probe of the built types: {"key", "type", "index", "kind", "level"}.
## Probes are extension material, so "Exam-style only" leaves them out.
static func probes(exam_only: bool = false) -> Array:
	if exam_only:
		return []
	var out: Array = []
	for id in built_types():
		var t := type_of(id)
		var cs: Array = t.get("concepts", [])
		for i in cs.size():
			out.append({"key": "%s|concept|%d" % [id, i], "type": id, "index": i, "kind": cs[i].kind, "level": int(cs[i].level)})
	return out


## A concept probe as a question. The student picks a verdict (true or false;
## always, sometimes or never; the sign predicted), which is marked against the first
## word of the catalogue answer, then reads the reason. A probe with no verdict to
## pick (interpret-parameter) is a think-then-reveal with self-marking.
static func probe(type_id: String, index: int) -> Dictionary:
	var t := type_of(type_id)
	var cs: Array = t.get("concepts", [])
	if index < 0 or index >= cs.size():
		return {"error": "no probe %d on %s" % [index, type_id]}
	var c: Dictionary = cs[index]
	var first: String = c.answer.split(" ")[0].rstrip(".:,")
	var options: Array = VERDICTS.get(c.kind, [])
	var verdict := first if first in options else ""
	if verdict == "":
		options = SELF_MARK
	return {"format": "probe", "paper": 1, "kind": c.kind, "cell": "%s|concept|%d" % [type_id, index], "type_name": t.name,
		"level": int(c.level), "prompt": c.prompt, "options": options, "verdict": verdict, "reveal": c.answer,
		"view": {"type": type_id, "probe": index, "format": "probe"}}


static func mark_probe(question: Dictionary, option: String) -> Dictionary:
	if question.verdict == "":
		return {"correct": option == SELF_MARK[0], "complete": true, "misconception": ""}
	return {"correct": option == question.verdict, "complete": true, "misconception": ""}
