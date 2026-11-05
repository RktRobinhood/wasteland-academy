extends SceneTree
## The feedback check (FAL-742): what a student reads after a wrong answer. For every
## cell of every built type, across seeds, takes each wrong option with a misconception
## tag, builds the text the student sees, and fails on the two faults a machine can find:
##
##   numbers   a number in the feedback appears nowhere in that question's stem, options
##             or working, so the text was written for another question.
##   claim     the text states the false belief as if it were true, so it reads as advice
##             after "Watch out:". Every string has to name the slip ("Assuming ...",
##             "Using ...").
##   no text   the tag has no text in the type's misconceptions, so the student sees nothing.
##   overflow  an option's number is absurdly large, as when a slip divides by next to nothing
##             and the size overflows (FAL-729's σ = −9220000000). The answer checker doesn't
##             look at an untagged option's size: it only confirms that the option is wrong.
##   stop      two full stops in a row, in anything the student reads, the "The answer is"
##             line included: an answer can be a sentence of its own. Enforced on every type.
##
## It can't judge whether a tag matches its option, so --rows=/abs/file.tsv also writes one
## row per type, unknown, representation and tag (stem, picked option, feedback) to read.
##
## Every built type is enforced except those in REPORT_ONLY, the types built before this
## check, whose failures are only counted. A new type is enforced from its first commit.
## Used by tools/feedback-check. Exits non-zero on any enforced failure.
##
## Faults are counted once per type, tag and number, however many questions show them.
##
##   godot --headless --path game --script res://tools/feedback_check.gd -- \
##       [--seeds=12] [--types=id,id] [--rows=/abs/file.tsv] [--all]
##
## --all enforces the report-only types too.

const REPORT_ONLY := [
	"fn-composite", "fn-concept-asymptote-meaning", "fn-concept-function-notation",
	"fn-concept-gradient-meaning", "fn-concept-growth-patterns", "fn-concept-quadratic-forms",
	"fn-concept-solutions-as-intersections", "fn-concept-transform-order",
	"fn-curve-intersection-quadratic", "fn-discriminant", "fn-domain-range",
	"fn-evaluate-function", "fn-exp-log-inverse-composite", "fn-exponential-model",
	"fn-ext-exp-graph", "fn-ext-inequality-graphical", "fn-ext-intersection-lines",
	"fn-ext-is-function", "fn-ext-line-model", "fn-ext-match-graph", "fn-ext-quadratic-model",
	"fn-ext-rational-model", "fn-ext-transformed-reciprocal", "fn-gdc-features",
	"fn-gdc-intersection", "fn-gdc-optimise-combined", "fn-gdc-solve-equation",
	"fn-graph-table-composite-inverse", "fn-inverse-algebraic", "fn-inverse-reflection",
	"fn-line-from-conditions", "fn-link-equivalent-forms", "fn-link-extremes",
	"fn-link-graph-vs-algebra", "fn-link-multiplicative-growth", "fn-link-rate-of-change",
	"fn-link-symmetry", "fn-link-transformations", "fn-link-vectors", "fn-log-function-features",
	"fn-log-of-quadratic", "fn-pre-algebraic-fractions", "fn-pre-expand", "fn-pre-factorise",
	"fn-pre-graph-reading", "fn-pre-linear-equations", "fn-pre-linear-inequalities",
	"fn-pre-percent-multiplier", "fn-pre-rearrange", "fn-pre-simultaneous", "fn-pre-substitute",
	"fn-pre-surds", "fn-quadratic-features", "fn-quadratic-from-conditions",
	"fn-quadratic-inequality", "fn-rational-asymptotes-intercepts", "fn-rational-sketch",
	"fn-sketch-from-features", "fn-sketch-gdc", "fn-solve-quadratic", "fn-transform-apply",
	"fn-transform-describe", "t1-arithmetic-sequence", "t1-compound-interest",
	"t3-ambiguous-case", "t3-sine-cosine-rule", "t3-triangle-area", "t4-binomial",
	"t4-discrete-distribution", "t4-expected-occurrences", "t4-expected-value",
	"t4-regression-gdc", "t4-summary-statistics", "t5-differentiate-polynomial",
	"t5-stationary-points", "t5-tangent-condition", "t5-tangent-normal-equation",
]

## Two full stops, but not an ellipsis.
const DOUBLE_STOP := "(?<!\\.)\\.\\.(?!\\.)"
## Words that open a sentence and aren't a slip.
const NOT_A_SLIP := ["thing", "nothing", "everything", "something", "anything", "string", "during", "king", "ring", "wing"]
## Vulgar fractions, as a question may write them instead.
const VULGAR := {"½": "1/2", "⅓": "1/3", "⅔": "2/3", "¼": "1/4", "¾": "3/4", "⅕": "1/5", "⅙": "1/6", "⅛": "1/8"}

## A number, with the spaces or commas of 45 000 and 45,000.
const NUMBER := "\\d+(?:[ ,]\\d{3})*(?:\\.\\d+)?"
## An option past this, where the answer isn't, is an overflow.
const WILD := 1e9

var faults := {}  ## "type|fault|ref|token" -> {"type", "fault", "ref", "token", "text", "n", "first"}
var rows := {}  ## "type|unknown|rep|ref" -> row
var tag_counts := {}  ## type -> {ref: true}


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var args := {"seeds": "12", "types": "", "rows": ""}
	var enforce_all := false
	for a in OS.get_cmdline_user_args():
		if a == "--all":
			enforce_all = true
		elif a.begins_with("--") and a.contains("="):
			var kv := a.substr(2).split("=", true, 1)
			args[kv[0]] = kv[1]
	var seeds := int(args.seeds)
	var only: Array = Array(str(args.types).split(",", false))
	var n := 0
	for c in QuestionEngine.cells(false, only):
		for seed in range(1, seeds + 1):
			var views: Array = [{"format": "mcq", "seed": seed}, {"format": "mcq", "seed": seed, "shared": true}]
			for f in QuestionEngine.extra_formats(c.type, c.unknown, c.angle):
				views.append({"format": f, "seed": seed})
			for v in views:
				var q := QuestionEngine.make(v.merged({"type": c.type, "unknown": c.unknown, "rep": c.rep, "angle": c.angle}))
				if q.is_empty() or q.has("error"):
					continue
				n += 1
				_check(q)
	for id in QuestionEngine.built_types():
		if not only.is_empty() and not id in only:
			continue
		_check_strings(id)
		for steps in Dungeon.chain_windows(id):
			for seed in range(1, mini(seeds, 4) + 1):
				var chain := QuestionEngine.make_chain(steps.map(func(st): return st.merged({"format": "mcq"})), seed)
				if chain.has("error"):
					continue
				for q in chain.parts:
					n += 1
					_check(q)
	if args.rows != "":
		_write_rows(args.rows)
	var failed := _report(enforce_all)
	print("FEEDBACK %d questions, %d enforced failures" % [n, failed])
	quit(1 if failed > 0 else 0)


## Every wrong option of one question with a tag.
func _check(q: Dictionary) -> void:
	var t := QuestionEngine.type_of(q.view.type)
	var seen := {}
	var read := "%s\n%s" % [QuestionEngine.answer_sentence(q), _seen_text(q)]
	var stop := RegEx.create_from_string(DOUBLE_STOP).search(read)
	if stop != null:
		var at := stop.get_start()
		_fault(t.id, "stop", "", "", read.substr(maxi(0, at - 40), 44), q)
	for c in q.choices:
		if not c.correct and _size(c.values) >= WILD and _size(q.answer.values) < WILD:
			_fault(t.id, "overflow", "", c.text, "", q)
		if c.correct or c.get("ref", "") == "" or seen.has(c.ref):
			continue
		seen[c.ref] = true
		var why := QuestionEngine.misconception_text(t, c.ref)
		var key := "%s|%s|%s|%s" % [t.id, q.view.unknown, q.rep, c.ref]
		tag_counts.get_or_add(t.id, {})[c.ref] = true
		if not rows.has(key):
			rows[key] = {"type": t.id, "unknown": q.view.unknown, "rep": q.rep, "ref": c.ref, "stem": _stem(q),
				"option": _option_text(q, c), "answer": q.answer_text, "feedback": why, "cell": q.cell, "seed": q.view.seed, "format": q.format, "n": 0}
		rows[key].n += 1
		if why == "":
			_fault(t.id, "no text", c.ref, "", "", q)
			continue
		for token in strange_numbers(why, _seen_text(q)):
			_fault(t.id, "numbers", c.ref, token, why, q)


## How large a single-number answer is, or 0 for any other kind.
static func _size(values: Dictionary) -> float:
	var v: Variant = values.get("v")
	return absf(v.to_float()) if v is Q else 0.0


## A true-false-reason's tagged option reads "True"; the option it stands for is the claim.
func _option_text(q: Dictionary, c: Dictionary) -> String:
	return str(q.get("claim", c.text)) if q.format == "true-false-reason" else c.text


## Every misconception string of a type must name the slip, whether or not a seed reached it.
func _check_strings(id: String) -> void:
	var t := QuestionEngine.type_of(id)
	var ms: Array = t.get("misconceptions", [])
	for i in ms.size():
		var text: String = ms[i].text
		if not names_a_slip(text):
			_fault(id, "claim", ms[i].get("ref", "%s#%d" % [id, i]), "", text, {})


## True when a string opens by naming what the student did: a gerund ("Assuming",
## "Using"), or "Not" plus one.
static func names_a_slip(text: String) -> bool:
	var words := text.strip_edges().split(" ", false)
	if words.is_empty():
		return false
	var first := words[0].to_lower()
	if first == "not" and words.size() > 1:
		first = words[1].to_lower()
	return first.ends_with("ing") and first.length() > 4 and not first in NOT_A_SLIP


## Numbers in text that hay, all a question shows, doesn't have.
static func strange_numbers(text: String, hay: String) -> Array:
	var number := RegEx.create_from_string(NUMBER)
	var known := {}
	for m in number.search_all(hay):
		known[_norm(m.get_string())] = true
	var out: Array = []
	for m in number.search_all(text):
		var token := _norm(m.get_string())
		if not known.has(token) and not out.has(token):
			out.append(token)
	for ch in VULGAR:
		if text.contains(ch) and not hay.contains(ch) and not hay.contains(VULGAR[ch]):
			out.append(ch)
	return out


func _stem(q: Dictionary) -> String:
	var parts: Array = [q.prompt]
	parts.append_array(q.get("lines", []))
	var out := " / ".join(parts.map(func(l): return str(l)))
	if q.get("table") != null and not (q.table is Dictionary and q.table.is_empty()):
		out += " [table] " + _flat(q.table)
	if q.get("diagram") != null:
		out += " [diagram]"
	if q.get("graph") != null and not (q.graph is Dictionary and q.graph.is_empty()):
		out += " [graph]"
	return out.replace("\n", " / ").replace("\t", " ")


## Everything of a question a student can read: stem, table, diagram, options and working.
func _seen_text(q: Dictionary) -> String:
	var parts: Array = [QuestionEngine.shown_prompt(q), q.get("reason", "")]
	parts.append_array(q.get("lines", []))
	parts.append(_flat(q.get("table")))
	parts.append(_flat(q.get("diagram")))
	parts.append(_flat(q.get("graph")))
	for c in q.choices:
		parts.append(c.text)
	for sol in q.solutions:
		parts.append_array(Step.texts(sol.steps))
		parts.append(str(sol.get("result", "")))
	return "\n".join(parts.map(func(p): return str(p)))


## 45 000 is 45000, and 2.50 is 2.5.
static func _norm(token: String) -> String:
	var t := token.replace(" ", "").replace(",", "")
	if t.contains("."):
		t = t.rstrip("0").rstrip(".")
	return t


func _flat(v: Variant) -> String:
	if v == null:
		return ""
	if v is Q:
		return v.key()
	if v is Dictionary:
		return " ".join(v.values().map(func(e): return _flat(e)))
	if v is Array:
		return " ".join(v.map(func(e): return _flat(e)))
	return str(v)


func _fault(id: String, fault: String, ref: String, token: String, text: String, q: Dictionary) -> void:
	var key := "%s|%s|%s|%s" % [id, fault, ref, token]
	if not faults.has(key):
		faults[key] = {"type": id, "fault": fault, "ref": ref, "token": token, "text": text, "n": 0,
			"first": "%s seed %d" % [q.cell, q.view.seed] if not q.is_empty() else ""}
	faults[key].n += 1


## Prints the failures, enforced ones in full and the rest as a count per type. Returns
## how many enforced failures there are.
func _report(enforce_all: bool) -> int:
	var enforced := 0
	var counted := {}
	var keys := faults.keys()
	keys.sort()
	for key in keys:
		var f: Dictionary = faults[key]
		if not enforce_all and f.type in REPORT_ONLY and f.fault != "stop":
			var row: Dictionary = counted.get_or_add(f.type, {"numbers": 0, "claim": 0, "no text": 0, "overflow": 0})
			row[f.fault] += 1
			continue
		enforced += 1
		print("FAIL %s: %s %s%s x%d: %s%s" % [f.type, f.fault, f.ref, " [%s]" % f.token if f.token != "" else "", f.n, f.text,
			" (%s)" % f.first if f.first != "" else ""])
	var ids := counted.keys()
	ids.sort()
	for id in ids:
		print("REPORT %s: numbers %d, claim %d, no text %d, overflow %d" % [id, counted[id].numbers, counted[id].claim, counted[id]["no text"], counted[id].overflow])
	return enforced


func _write_rows(path: String) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		printerr("feedback_check: can't write %s" % path)
		return
	f.store_line("\t".join(["type", "unknown", "rep", "ref", "stem", "answer", "option", "feedback", "seen", "cell", "seed", "format"]))
	var keys := rows.keys()
	keys.sort()
	for key in keys:
		var r: Dictionary = rows[key]
		f.store_line("\t".join([r.type, r.unknown, r.rep, r.ref, r.stem, r.answer, r.option, r.feedback, r.n, r.cell, r.seed, r.format].map(func(x): return str(x))))
	f.close()
	print("FEEDBACK %d rows -> %s" % [keys.size(), path])
