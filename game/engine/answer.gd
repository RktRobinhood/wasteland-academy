class_name Answer
extends RefCounted
## What a question's answer looks like, how to write it, and how to mark it.
##
## An answer is a Dictionary:
##   kind       how it is written (see text()): number, axis, xval, roots, point, yint,
##              vertex_form, vertex_form_a, general, general_a, factorised, maxmin,
##              vertex_kind, range, triple, claim
##   template   the slot input: literal Strings, {"slot": id} for a typed number and
##              {"pick": id, "options": [...]} for a choice of words
##   values     slot id -> Q (typed number) or String (picked option)
##   fixed      values shown as given, not asked (a in "2(x − □)² + □")
##   unordered  groups of slot ids that may come in any order (two roots)
##   exact      (optional) true when only the exact value is right, not 3 s.f.: Paper 1
##              answers the IB wants exact, such as a whole-number sum (2345 is not 2350)
##
## Typed numbers go through parse_number(), which accepts whole numbers, decimals and
## fractions only. Nothing a student types is evaluated as an expression (Godot's
## Expression reads 2^3 as 1 and can call engine functions).

const MC_ONLY := ["triple", "claim"]


static func make(kind: String, values: Dictionary, fixed: Dictionary = {}, label: String = "") -> Dictionary:
	var t: Array = []
	var unordered: Array = []
	match kind:
		"number":
			t = [label, {"slot": "v"}]
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
	return {"kind": kind, "template": t, "values": values, "fixed": fixed, "unordered": unordered, "label": label}


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
			return ans.label + Fmt.num(v.v)
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
	return "?"


## A key that is the same for two answers exactly when their values are, with
## unordered slots sorted. Used to keep wrong options apart from each other and
## from the answer.
static func canon(ans: Dictionary, values: Dictionary) -> String:
	if ans.kind == "claim":
		return "claim:" + str(values.form) + ":" + str(values.vals.map(func(e): return e.key() if e is Q else str(e)))
	var v := values.duplicate()
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
## exact value.
static func number_right(typed: Q, exact: Q) -> bool:
	if typed.eq(exact):
		return true
	if exact.is_zero():
		return false
	var t := exact.to_float()
	var e := floori(log(absf(t)) / log(10.0) + 1e-12)
	var unit := pow(10.0, e - 2)
	return roundi(t / unit) == roundi(typed.to_float() / unit)


## Marks typed slot entries. response: slot id -> String (typed or picked).
## Returns {"correct": bool, "complete": bool, "errors": {id: message}, "values": {...}}.
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
		return {"correct": false, "complete": false, "errors": errors, "values": got}
	return {"correct": values_right(ans, got), "complete": true, "errors": {}, "values": got}


## Whether typed values match the answer, slot by slot, trying each order of an
## unordered group.
static func values_right(ans: Dictionary, got: Dictionary) -> bool:
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
		if not _slot_right(want[id], got.get(id), exact):
			return false
	for group in ans.unordered:
		var ok := false
		for perm in _perms(group):
			var all := true
			for i in group.size():
				if not _slot_right(want[group[i]], got.get(perm[i]), exact):
					all = false
					break
			if all:
				ok = true
				break
		if not ok:
			return false
	return true


static func _slot_right(want: Variant, got: Variant, exact: bool = false) -> bool:
	if want is Q:
		return got is Q and (got.eq(want) if exact else number_right(got, want))
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
