extends ExtensionViews

const SLIP := "t3-ahl-vector-basics#"

func needs() -> Dictionary:
	return {"basis-vector-to-components": {}}

func papers(unknown: String, _rep: String, _angle: String) -> Array:
	return [1] if has(unknown) else []

static func term(coefficient: int, basis: String) -> String:
	return ("" if absi(coefficient) == 1 else str(absi(coefficient))) + basis

static func slots(v: Array) -> Dictionary:
	return {"x": v[0], "y": v[1], "z": v[2],
		"text": "(%s, %s, %s)" % [Fmt.num(v[0]), Fmt.num(v[1]), Fmt.num(v[2])]}

func u_basis_vector_to_components(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var letters := ["i", "j", "k"]
	var p: Array = s.terms[0]
	var q: Array = s.terms[1]
	var expression := ("−" if p[1] < 0 else "") + term(p[1], letters[p[0]])
	expression += (" − " if q[1] < 0 else " + ") + term(q[1], letters[q[0]])
	var v := [0, 0, 0]
	v[p[0]] = p[1]
	v[q[0]] = q[1]
	var swapped := v.duplicate()
	swapped[p[0]] = v[q[0]]
	swapped[q[0]] = v[p[0]]
	var answer := Answer.make("form", slots(v), {"parts": ["(", {"slot": "x"}, ", ", {"slot": "y"}, ", ", {"slot": "z"}, ")"]})
	answer.exact = true
	return {
		"lines": [rng.pick(["The Beacon Bench stores the sensor vector in (x, y, z) order.",
			"The Pump Archive stores the marker vector in (x, y, z) order."]),
			"The unit vectors i, j and k point along the positive x, y and z axes, respectively.",
			"Vector: " + expression],
		"asked": "Write the vector as (x, y, z).",
		"answer": answer,
		"wrongs": [wrong(slots(swapped), SLIP + "0"),
			wrong(slots(v.map(func(n): return absi(n))), SLIP + "1"),
			wrong(slots(v.map(func(n): return -n)), SLIP + "2")],
		"given": {"terms": s.terms},
		"methods": {"read-axis-labels": method([
			"Read the signed coefficients of i, j and k in that order. The missing axis has coefficient 0.",
			"So the vector is %s." % answer.values.text
		], answer.values)}
	}
