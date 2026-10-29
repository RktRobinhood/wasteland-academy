class_name ExtensionViews
extends RefCounted
## What the views of the Quadratics extension types share (FAL-459): the fn-pre-*
## prior learning, fn-ext-quadratic-model and the two fn-link-* types. Each views class
## extends this one and sets needs() (unknown -> what its situation must satisfy) and,
## where it builds them, formats() (unknown -> the extra formats its builder supports:
## error-spot needs a `spot`, method-pick a `pick_wrongs` list, true-false-reason
## nothing more than the question's own options). Builders return what
## QuadraticViews' builders return (see quadratic_views.gd), plus, for those formats:
##   spot        {"lines": [4 lines of a student's working], "bad": index of the first
##               wrong line, "ref": the misconception, "why": what went wrong}
##   pick_wrongs [{"name", "why"}]: methods that don't work here, after the catalogue's
##               own `weak` ones (method-pick)
##
## A misconception the catalogue gives no ref is "<type id>#<index>"
## (QuestionEngine.misconception_text), so every wrong option is still logged.


## unknown -> need. Overridden.
func needs() -> Dictionary:
	return {}


## unknown -> extra formats its builder supports. Overridden where there are any.
func extra() -> Dictionary:
	return {}


func has(unknown: String) -> bool:
	return needs().has(unknown)


func need(unknown: String, rep: String) -> Dictionary:
	var n: Dictionary = needs()[unknown].duplicate()
	n.rep = rep
	return n


func formats(unknown: String) -> Array:
	return extra().get(unknown, [])


## The method the view asks for, while build() runs (build_view sets it).
var angle := "any"


func build_view(unknown: String, rep: String, method_id: String, s: Dictionary, rng: Seeded) -> Dictionary:
	angle = method_id
	return build(unknown, rep, s, rng)


func build(unknown: String, rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var out: Dictionary = call("u_" + unknown.replace("-", "_"), rep, s, rng)
	for key in ["lines", "graph", "table", "wrongs", "generic"]:
		if not out.has(key):
			out[key] = [] if key in ["lines", "wrongs", "generic"] else null
	# Q7's rounding trap, where the answer needs rounding (see game/README.md).
	out.trap = Answer.rounding_trap(out.answer)
	return out


static func N(v: Variant) -> String:
	return Fmt.num(v)


static func P(v: Variant) -> String:
	return Fmt.paren(v)


## A whole number with its sign, for a grid edge or a list: "+3", "−5".
static func signed(v: Variant) -> String:
	var q := Q.of(v)
	return ("−" if q.sign() < 0 else "+") + q.abs_q().text()


static func wrong(values: Dictionary, ref: String = "") -> Dictionary:
	return {"values": values, "ref": ref}


static func method(steps: Array, result: Dictionary) -> Dictionary:
	return {"steps": steps, "result": result}


## Plain data for the export and the checker: Q -> "3/2", recursively.
static func export(s: Dictionary) -> Dictionary:
	return _plain(s)


static func _plain(v: Variant) -> Variant:
	if v is Q:
		return v.key()
	if v is Dictionary:
		var d := {}
		for k in v:
			d[k] = _plain(v[k])
		return d
	if v is Array:
		return v.map(func(e): return _plain(e))
	return v


## A nonzero whole number from lo to hi.
static func nonzero(rng: Seeded, lo: int, hi: int) -> int:
	var v := 0
	while v == 0:
		v = rng.int_in(lo, hi)
	return v
