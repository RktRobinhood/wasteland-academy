class_name Answer
extends RefCounted
## What a question's answer looks like, how to write it, and how to mark it.
##
## An answer is a Dictionary:
##   kind       how it is written (see text()): number, axis, xval, roots, point, yint,
##              vertex_form, vertex_form_a, general, general_a, factorised, maxmin,
##              vertex_kind, range, triple, claim; for the triangle situation also
##              measure (a length, angle or area, written to 3 s.f. with its unit); for
##              the distribution situation also pq (two unknown probabilities p and q);
##              for the cubic situation also deriv
##              (f′(x) as a quadratic), line (y = mx + c), tangent_read (f′(x₀) and f(x₀)),
##              points2 (two points, either order) and natures (maximum or minimum at
##              each stationary point)
##   template   the slot input: literal Strings, {"slot": id} for a typed number and
##              {"pick": id, "options": [...]} for a choice of words
##   values     slot id -> Q (typed number) or String (picked option)
##   fixed      values shown as given, not asked (a in "2(x − □)² + □")
##   unordered  groups of slot ids that may come in any order (two roots)
##   unit       text after the number: " cm", "°" (measure only)
##   exact      (optional) true when only the exact value is right, not 3 s.f.: Paper 1
##              answers the IB wants exact, such as a whole-number sum (2345 is not 2350)
##   show       (optional) how a number is written: "dec" as a decimal when it ends
##              (0.35, not 7/20), "money" with two decimal places (2.50); else a fraction
##
## Typed numbers go through parse_number(), which accepts whole numbers, decimals and
## fractions only. Nothing a student types is evaluated as an expression (Godot's
## Expression reads 2^3 as 1 and can call engine functions).

const MC_ONLY := ["triple", "claim", "natures"]
const NATURES := ["local maximum", "local minimum"]


static func make(kind: String, values: Dictionary, fixed: Dictionary = {}, label: String = "", unit: String = "") -> Dictionary:
	var t: Array = []
	var unordered: Array = []
	match kind:
		"number":
			t = [label, {"slot": "v"}]
			if unit != "":
				t.append(unit)
		"xval":
			t = ["x = ", {"slot": "v"}]
		"axis":
			t = [{"pick": "var", "options": ["x", "y"]}, " = ", {"slot": "h"}]
		"roots":
			t = ["x = ", {"slot": "r1"}, " and x = ", {"slot": "r2"}]
			unordered = [["r1", "r2"]]
		"point":
			t = ["(", {"slot": "x"}, ", ", {"slot": "y"}, ")"]
		"yint":
			t = ["(0, ", {"slot": "y"}, ")"]
		"vertex_form":
			t = ["f(x) = ", {"slot": "a"}, "(x − ", {"slot": "h"}, ")² + ", {"slot": "k"}]
		"vertex_form_a":
			t = ["f(x) = %s(x − " % Fmt.lead(fixed.a), {"slot": "h"}, ")² + ", {"slot": "k"}]
		"general":
			t = ["f(x) = ", {"slot": "a"}, "x² + ", {"slot": "b"}, "x + ", {"slot": "c"}]
		"general_a":
			t = ["f(x) = %sx² + " % Fmt.lead(fixed.a), {"slot": "b"}, "x + ", {"slot": "c"}]
		"factorised":
			t = ["f(x) = ", {"slot": "a"}, "(x − ", {"slot": "p"}, ")(x − ", {"slot": "q"}, ")"]
			unordered = [["p", "q"]]
		"maxmin":
			t = [{"pick": "kind", "options": ["maximum", "minimum"]}, " value ", {"slot": "k"}]
		"vertex_kind":
			t = ["(", {"slot": "x"}, ", ", {"slot": "y"}, "), a ", {"pick": "kind", "options": ["maximum", "minimum"]}]
		"range":
			t = [{"pick": "var", "options": ["x", "y"]}, " ", {"pick": "rel", "options": ["≥", "≤"]}, " ", {"slot": "k"}]
		"triple":
			unordered = [["fp", "fq"]]
		"claim":
			t = []
		"measure":
			t = [label, {"slot": "v"}, unit]
		"pq":
			t = ["p = ", {"slot": "p"}, ",  q = ", {"slot": "q"}]
		"deriv":
			t = [label if label != "" else "f′(x) = ", {"slot": "u2"}, "x² + ", {"slot": "u1"}, "x + ", {"slot": "u0"}]
		"line":
			t = ["y = ", {"slot": "m"}, "x + ", {"slot": "c"}]
		"tangent_read":
			t = ["f′(%s) = " % Fmt.num(fixed.x0), {"slot": "m"}, ",  f(%s) = " % Fmt.num(fixed.x0), {"slot": "y"}]
		"points2":
			t = ["(", {"slot": "x1"}, ", ", {"slot": "y1"}, ") and (", {"slot": "x2"}, ", ", {"slot": "y2"}, ")"]
		"natures":
			t = ["x = %s: " % Fmt.num(fixed.p), {"pick": "k1", "options": NATURES}, ",  x = %s: " % Fmt.num(fixed.q), {"pick": "k2", "options": NATURES}]
	return {"kind": kind, "template": t, "values": values, "fixed": fixed, "unordered": unordered, "label": label, "unit": unit}


## The same answer shape with other values (for a wrong option).
static func with_values(ans: Dictionary, values: Dictionary) -> Dictionary:
	var out := ans.duplicate()
	out.values = values
	return out


static func slots(ans: Dictionary) -> Array:
	var out: Array = []
	for item in ans.template:
		if item is Dictionary:
			out.append(item)
	return out


## The answer written out, as feedback and as a multiple-choice option shows it.
static func text(ans: Dictionary, values: Dictionary = {}) -> String:
	var v: Dictionary = values if not values.is_empty() else ans.values
	var fx: Dictionary = ans.fixed
	match ans.kind:
		"number":
			return ans.label + shown(ans, v.v) + ans.unit
		"xval":
			return "x = " + Fmt.num(v.v)
		"axis":
			return "%s = %s" % [v["var"], Fmt.num(v.h)]
		"roots":
			var rs := _sorted([v.r1, v.r2])
			return "x = %s and x = %s" % [Fmt.num(rs[0]), Fmt.num(rs[1])]
		"point":
			return Fmt.point(v.x, v.y)
		"yint":
			return Fmt.point(0, v.y)
		"vertex_form":
			return "f(x) = " + Fmt.vertex(v.a, v.h, v.k)
		"vertex_form_a":
			return "f(x) = " + Fmt.vertex(fx.a, v.h, v.k)
		"general":
			return "f(x) = " + Fmt.general(v.a, v.b, v.c)
		"general_a":
			return "f(x) = " + Fmt.general(fx.a, v.b, v.c)
		"factorised":
			var rs := _sorted([v.p, v.q])
			return "f(x) = " + Fmt.factorised(v.a, rs[0], rs[1])
		"maxmin":
			return "%s value %s" % [v.kind, Fmt.num(v.k)]
		"vertex_kind":
			return "%s, a %s" % [Fmt.point(v.x, v.y), v.kind]
		"range":
			return "%s %s %s" % [v["var"], v.rel, Fmt.num(v.k)]
		"triple":
			var rs := _sorted([v.fp, v.fq])
			return "%s,  %s,  %s" % [Fmt.general(v.ga, v.gb, v.gc), Fmt.factorised(v.fa, rs[0], rs[1]), Fmt.vertex(v.va, v.vh, v.vk)]
		"claim":
			return v.text
		"measure":
			return ans.label + Fmt.sf(v.v) + ans.unit
		"pq":
			return "p = %s, q = %s" % [shown(ans, v.p), shown(ans, v.q)]
		"deriv":
			return (ans.label if ans.label != "" else "f′(x) = ") + Fmt.poly([v.u2, v.u1, v.u0])
		"line":
			return "y = " + Fmt.poly([v.m, v.c])
		"tangent_read":
			return "f′(%s) = %s,  f(%s) = %s" % [Fmt.num(fx.x0), Fmt.num(v.m), Fmt.num(fx.x0), Fmt.num(v.y)]
		"points2":
			var ps := _pairs(v)
			return "%s and %s" % [Fmt.point(ps[0][0], ps[0][1]), Fmt.point(ps[1][0], ps[1][1])]
		"natures":
			return "x = %s: %s,  x = %s: %s" % [Fmt.num(fx.p), v.k1, Fmt.num(fx.q), v.k2]
	return "?"


## A typed number as the answer writes it: a fraction, a decimal or money (see show).
static func shown(ans: Dictionary, v: Variant) -> String:
	match ans.get("show", ""):
		"dec":
			return Fmt.dec(v)
		"money":
			return Fmt.money(v)
	return Fmt.num(v)


## A key that is the same for two answers exactly when their values are, with
## unordered slots sorted. Used to keep wrong options apart from each other and
## from the answer.
static func canon(ans: Dictionary, values: Dictionary) -> String:
	if ans.kind == "claim":
		return "claim:" + str(values.form) + ":" + str(values.vals.map(func(e): return e.key() if e is Q else str(e)))
	# A measure is told apart by what it shows: two values with the same 3 s.f. are one option.
	if ans.kind == "measure":
		return "measure:" + Fmt.sf(values.v)
	var v := values.duplicate()
	if ans.kind == "points2":
		var ps := _pairs(v)
		v = {"x1": ps[0][0], "y1": ps[0][1], "x2": ps[1][0], "y2": ps[1][1]}
	for group in ans.unordered:
		var sorted_vals := _sorted(group.map(func(id): return v[id]))
		for i in group.size():
			v[group[i]] = sorted_vals[i]
	var keys := v.keys()
	keys.sort()
	var parts: PackedStringArray = []
	for key in keys:
		parts.append("%s=%s" % [key, v[key].key() if v[key] is Q else str(v[key])])
	return ",".join(parts)


## Plain strings for the export: Q -> "3/2".
static func export_values(values: Dictionary) -> Dictionary:
	var out := {}
	for key in values:
		var x = values[key]
		if x is Q:
			out[key] = x.key()
		elif x is Array:
			out[key] = x.map(func(e): return e.key() if e is Q else e)
		else:
			out[key] = x
	return out


## The two points of a points2 answer, the one with the smaller x first.
static func _pairs(v: Dictionary) -> Array:
	var ps: Array = [[v.x1, v.y1], [v.x2, v.y2]]
	if Q.of(ps[1][0]).lt(ps[0][0]) or (Q.of(ps[1][0]).eq(ps[0][0]) and Q.of(ps[1][1]).lt(ps[0][1])):
		ps.reverse()
	return ps


static func _sorted(qs: Array) -> Array:
	var out := qs.duplicate()
	out.sort_custom(func(x, y): return Q.of(x).lt(y))
	return out


# ── Typed numbers ────────────────────────────────────────────

static var _num_re: RegEx


## Reads a typed number: 3, −1.5, .5, 3/2, -3/2, 1.5/2, ½, with an optional "x =" or
## "y =" in front and spaces anywhere. Returns {"ok": true, "q": Q, "decimal": bool}
## or {"ok": false, "error": "..."}.
static func parse_number(raw: String) -> Dictionary:
	if _num_re == null:
		_num_re = RegEx.create_from_string("^([+-]?)(\\d+(?:\\.\\d*)?|\\.\\d+)(?:/([+-]?)(\\d+(?:\\.\\d*)?|\\.\\d+))?$")
	if RegEx.create_from_string("\\d\\s+[\\d.]").search(raw) != null:
		return {"ok": false, "error": "Type a number, like 3, −1.5 or 3/2."}
	var s := raw.strip_edges().replace(" ", "").replace("−", "-").replace("–", "-").replace("—", "-")
	s = s.replace("½", "1/2")
	for prefix in ["f(x)=", "y=", "x=", "Y=", "X="]:
		if s.begins_with(prefix):
			s = s.substr(prefix.length())
	if s.begins_with("(") and s.ends_with(")") and s.length() > 2:
		s = s.substr(1, s.length() - 2)
	if s == "":
		return {"ok": false, "error": "empty"}
	var m := _num_re.search(s)
	if m == null:
		return {"ok": false, "error": "Type a number, like 3, −1.5 or 3/2."}
	var top := _decimal(m.get_string(2))
	if top == null:
		return {"ok": false, "error": "That number has too many digits."}
	if m.get_string(1) == "-":
		top = top.neg()
	var dec := m.get_string(2).contains(".")
	if m.get_string(4) != "":
		var bottom := _decimal(m.get_string(4))
		if bottom == null or bottom.is_zero():
			return {"ok": false, "error": "The bottom of a fraction can't be 0."}
		if m.get_string(3) == "-":
			bottom = bottom.neg()
		top = top.div(bottom)
		dec = dec or m.get_string(4).contains(".")
	return {"ok": true, "q": top, "decimal": dec}


static func _decimal(s: String) -> Q:
	var parts := s.split(".")
	var whole := parts[0]
	var frac := parts[1] if parts.size() > 1 else ""
	var digits := (whole + frac).lstrip("0")
	if digits.length() > 15:
		return null
	var den := 1
	for i in frac.length():
		den *= 10
		if den > 1000000000000000:
			return null
	return Q.new((whole + frac).to_int(), den)


## IB style: right if exact, or if it rounds to the same 3 significant figures as the
## exact value, or if it is the exact value correctly rounded to the 3 or more figures
## typed (12.35 for 12.3456 is right, though 12.35 itself rounds to 12.4).
static func number_right(typed: Q, exact: Q) -> bool:
	if typed.eq(exact):
		return true
	if exact.is_zero():
		return false
	var t := exact.to_float()
	var e := floori(log(absf(t)) / log(10.0) + 1e-12)
	var unit := pow(10.0, e - 2)
	return roundi(t / unit) == roundi(typed.to_float() / unit) or _rounded_to_own_figures(typed, t, unit)


## Whether x is at least `edge` units of its 3rd significant figure away from a
## rounding edge, so its 3 s.f. value does not hang on the last digits of a
## calculation (32.55 can show as 32.5 or 32.6).
static func rounds_clearly(x: float, edge: float = 0.02) -> bool:
	if x == 0.0 or not is_finite(x):
		return false
	var e := floori(log(absf(x)) / log(10.0) + 1e-12)
	var scaled := absf(x) / pow(10.0, e - 2)
	return absf(scaled - floorf(scaled) - 0.5) >= edge


## Whether a typed decimal at least as fine as t's 3rd significant figure (unit) is t
## rounded to as many decimal places as it has. 100 is not right for 99.94: it has
## three digits, but it is coarser than 99.9.
static func _rounded_to_own_figures(typed: Q, t: float, unit: float) -> bool:
	var scale := 1
	var places := 0
	while scale % typed.d != 0:
		scale *= 10
		places += 1
		if places > 9:
			return false
	if scale * unit < 1.0 - 1e-9:
		return false
	return roundi(t * scale) == typed.n * (scale / typed.d)


## Q7 on the FAL-274 plan: the right value written with too few significant figures
## (2.3 for 2.347) is a glancing hit, not a miss. Only when the exact value needs
## rounding at 3 s.f. (so 1 is not a glancing 1/2), and only when the typed number is
## the value rounded to its own, coarser, places.
static func number_glancing(typed: Q, exact: Q) -> bool:
	if exact.is_zero() or typed.is_zero() or number_right(typed, exact) or not needs_rounding(exact):
		return false
	var t := exact.to_float()
	var e := floori(log(absf(t)) / log(10.0) + 1e-12)
	var unit := pow(10.0, e - 2)
	var scale := 1
	var places := 0
	while scale % typed.d != 0:
		scale *= 10
		places += 1
		if places > 9:
			return false
	if scale * unit >= 1.0 - 1e-9:
		return false
	return roundi(t * scale) == typed.n * (scale / typed.d)


## Whether a value can't be written exactly in 3 significant figures (2/3, 2.347), so
## a 3 s.f. answer is a rounded one.
static func needs_rounding(v: Q) -> bool:
	if v.is_zero():
		return false
	var r := parse_number(Fmt.sf(v).replace("−", "-"))
	return not (r.ok and r.q.eq(v))


## Kinds whose one typed number can be shown rounded, as a rounding trap.
const TRAP_KINDS := ["number", "xval", "axis", "yint"]


## The rounding trap for a multiple-choice question (Q7): the answer's value rounded to
## 2 significant figures, a glancing hit if picked. {} where it doesn't fit: the answer
## is exact-only, has more than one number, or its number needs no rounding. Every
## situation's views offer it as `trap` (see game/README.md).
static func rounding_trap(ans: Dictionary) -> Dictionary:
	if ans.get("exact", false) or not ans.kind in TRAP_KINDS:
		return {}
	var nums := slots(ans).filter(func(item): return item.has("slot"))
	if nums.size() != 1:
		return {}
	var id: String = nums[0].slot
	var v: Variant = ans.values[id]
	if not v is Q or not needs_rounding(v):
		return {}
	var r := parse_number(Fmt.sf(v, 2).replace("−", "-"))
	if not r.ok or r.q.is_zero():
		return {}
	var out := (ans.values as Dictionary).duplicate()
	out[id] = r.q
	return out


## A rounding trap written as a student would write it, as a decimal.
static func trap_text(ans: Dictionary, values: Dictionary) -> String:
	match ans.kind:
		"number":
			return ans.label + Fmt.dec(values.v) + ans.unit
		"xval":
			return "x = " + Fmt.dec(values.v)
		"axis":
			return "%s = %s" % [values["var"], Fmt.dec(values.h)]
		"yint":
			return "(0, %s)" % Fmt.dec(values.y)
	return text(ans, values)


## Marks typed slot entries. response: slot id -> String (typed or picked).
## Returns {"correct": bool, "complete": bool, "glancing": bool, "errors": {id: message},
## "values": {...}}. glancing: not right, but right with too few figures (Q7).
static func mark(ans: Dictionary, response: Dictionary) -> Dictionary:
	var errors := {}
	var got := {}
	for item in slots(ans):
		var id: String = item.get("slot", item.get("pick", ""))
		var raw := str(response.get(id, ""))
		if item.has("pick"):
			if raw == "":
				errors[id] = "Choose one."
			got[id] = raw
		else:
			var r := parse_number(raw)
			if not r.ok:
				errors[id] = r.error if r.error != "empty" else "Fill this in."
			else:
				got[id] = r.q
	if not errors.is_empty():
		return {"correct": false, "complete": false, "glancing": false, "errors": errors, "values": got}
	var right := values_right(ans, got)
	return {"correct": right, "complete": true, "glancing": not right and values_right(ans, got, true),
		"errors": {}, "values": got}


## Whether typed values match the answer, slot by slot, trying each order of an
## unordered group. With glancing, a number with too few figures counts too.
static func values_right(ans: Dictionary, got: Dictionary, glancing: bool = false) -> bool:
	if ans.kind == "points2" and not got.is_empty():
		var swapped := {"x1": got.get("x2"), "y1": got.get("y2"), "x2": got.get("x1"), "y2": got.get("y1")}
		var plain := ans.duplicate()
		plain.kind = "point_pair"
		return values_right(plain, got, glancing) or values_right(plain, swapped, glancing)
	var want: Dictionary = ans.values
	var exact: bool = ans.get("exact", false)
	var free := {}
	for group in ans.unordered:
		for id in group:
			free[id] = true
	for item in slots(ans):
		var id: String = item.get("slot", item.get("pick", ""))
		if free.has(id):
			continue
		if not _slot_right(want[id], got.get(id), exact, glancing):
			return false
	for group in ans.unordered:
		var ok := false
		for perm in _perms(group):
			var all := true
			for i in group.size():
				if not _slot_right(want[group[i]], got.get(perm[i]), exact, glancing):
					all = false
					break
			if all:
				ok = true
				break
		if not ok:
			return false
	return true


static func _slot_right(want: Variant, got: Variant, exact: bool = false, glancing: bool = false) -> bool:
	if want is Q:
		if not got is Q:
			return false
		if exact:
			return got.eq(want)
		return number_right(got, want) or (glancing and number_glancing(got, want))
	return str(want) == str(got)


static func _perms(ids: Array) -> Array:
	if ids.size() <= 1:
		return [ids]
	var out: Array = []
	for i in ids.size():
		var rest := ids.duplicate()
		rest.remove_at(i)
		for p in _perms(rest):
			out.append([ids[i]] + p)
	return out
