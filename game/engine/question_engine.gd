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
const BUILT := ["value", "mcq"]
const CHOICES := 4

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


## Makes the question for a view. Returns {"error": "..."} if the view can't be made.
static func make(view: Dictionary) -> Dictionary:
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
	var seed: int = int(view.get("seed", 0))
	# "Another way" (FAL-310): a view with same_angle asks the question that angle made,
	# the same numbers, but by this view's angle.
	var rng_angle: String = view.get("same_angle", angle)
	var rng := Seeded.new("%s|%d" % [cell_key(t.id, u.id, rep, rng_angle), seed])
	var recipe = SITUATIONS[t.situation][0]
	# The method that made the numbers rides along, for recipes whose numbers depend on
	# it (a Paper 2 context that a factorising method can't solve). It is the stream's
	# angle, not this view's, so "Another way" keeps the numbers; the view's working then
	# says where its method fails. Other recipes ignore it.
	var nd: Dictionary = views.need(u.id, rep)
	nd["angle"] = rng_angle
	var s: Dictionary = recipe.generate(rng, nd)
	if s.is_empty():
		return {"error": "no clean situation for %s" % cell_key(t.id, u.id, rep, angle)}
	var b: Dictionary = views.build(u.id, rep, s, rng)
	var ans: Dictionary = b.answer
	if ans.kind in Answer.MC_ONLY:
		fmt = "mcq"

	var prompt: String = b.asked
	if angle != "any":
		prompt += "\nMethod: %s." % angle_info(t, u.id, angle).name
	var solutions: Array = []
	var order: Array = [angle] if angle != "any" else []
	for a in angles:
		if not order.has(a):
			order.append(a)
	for a in order:
		if b.methods.has(a):
			var info := angle_info(t, u.id, a)
			solutions.append({"angle": a, "name": info.get("name", "Worked solution"), "steps": b.methods[a].steps,
				"result": b.methods[a].result})
	var choices := _choices(ans, b, rng)
	var out_view := {"type": t.id, "unknown": u.id, "rep": rep, "angle": angle, "format": fmt, "seed": seed}
	if rng_angle != angle:
		out_view.same_angle = rng_angle
	return {
		"view": out_view,
		"marks": int(view.get("marks", t.get("marks", 0))),
		"cell": cell_key(t.id, u.id, rep, angle),
		"type_name": t.name, "level": int(u.level),
		"exam": t.source == "exam" and bool(u.exam) and rep_is_exam(t, rep),
		"format": fmt, "prompt": prompt, "asked": b.asked, "rep": rep,
		"lines": b.lines, "graph": b.graph, "table": b.table, "diagram": b.get("diagram"),
		"answer": ans, "answer_text": Answer.text(ans),
		"choices": choices, "solutions": solutions,
		"given": b.given, "situation_id": t.situation, "situation": recipe.export(s),
	}


## Four options: the answer and three wrong ones. The view's rounding trap (Q7) comes
## first where it fits, then misconception options, each tagged with its ref; generic
## ones and, if still short, a nudged number fill the rest. No two options are equal.
static func _choices(ans: Dictionary, b: Dictionary, rng: Seeded) -> Array:
	var seen := {Answer.canon(ans, ans.values): true}
	var picked: Array = []
	var pool: Array = []
	if not b.get("trap", {}).is_empty():
		pool.append({"values": b.trap, "ref": "", "trap": true})
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


## A wrong option must still be a well-formed answer: no zero leading coefficient, and
## a measure (shown to 3 s.f.) that is positive and not on a rounding edge.
static func _usable(ans: Dictionary, values: Dictionary) -> bool:
	if ans.kind == "measure":
		var x: float = Q.of(values.v).to_float()
		return x > 0.0 and Answer.rounds_clearly(x)
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
	if question.format == "mcq":
		var i := int(response.get("choice", -1))
		if i < 0 or i >= question.choices.size():
			return {"correct": false, "complete": false, "glancing": false, "errors": {"choice": "Choose one."}, "misconception": ""}
		var c: Dictionary = question.choices[i]
		return {"correct": c.correct, "complete": true, "glancing": c.get("trap", false), "errors": {}, "misconception": c.ref}
	var r := Answer.mark(question.answer, response)
	r.misconception = ""
	if r.complete and not r.correct:
		for c in question.choices:
			if not c.correct and c.ref != "" and Answer.values_right(Answer.with_values(question.answer, c.values), r.values):
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
	return {"format": "probe", "kind": c.kind, "cell": "%s|concept|%d" % [type_id, index], "type_name": t.name,
		"level": int(c.level), "prompt": c.prompt, "options": options, "verdict": verdict, "reveal": c.answer,
		"view": {"type": type_id, "probe": index, "format": "probe"}}


static func mark_probe(question: Dictionary, option: String) -> Dictionary:
	if question.verdict == "":
		return {"correct": option == SELF_MARK[0], "complete": true, "misconception": ""}
	return {"correct": option == question.verdict, "complete": true, "misconception": ""}
