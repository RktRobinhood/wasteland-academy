extends "res://tests/test_case.gd"
## The calculator's graph tools (FAL-419): Brent's root finder and minimiser
## (engine/brent.gd), and the zeros, maxima, minima and intersections built on them
## (engine/graph_tools.gd), against SymPy's answers in tests/fixtures/brent.json
## (tools/brent_reference.py), to 6 significant figures.

const FIXTURE := "res://tests/fixtures/brent.json"


## Two values agree to 6 significant figures (values near 0 to 6 decimal places of 0.01).
func _same(a: float, b: float) -> bool:
	return absf(a - b) <= 5e-7 * maxf(absf(b), 0.01)


func _fn(text: String) -> Callable:
	var r := Expr.parse(text, ["x"])
	check(r.ok, "%s parses" % text)
	return GraphTools.function_of(r.tree)


func test_root_finder() -> void:
	var r := Brent.root(func(x): return x * x - 2.0, 0.0, 2.0)
	check(r.ok and _same(r.x, sqrt(2.0)), "√2 from x² − 2")
	check(not Brent.root(func(x): return x * x + 1.0, -1.0, 1.0).ok, "no sign change, no root")
	var c := Brent.root(func(x): return cos(x) - x, 0.0, 1.0)
	check(c.ok and _same(c.x, 0.739085133215161), "cos x = x")


func test_minimiser() -> void:
	var m := Brent.minimize(func(x): return (x - 1.5) * (x - 1.5) + 2.0, 0.0, 1.0, 4.0)
	check(_same(m.x, 1.5) and _same(m.fx, 2.0), "the vertex of (x − 1.5)² + 2")


func test_twenty_functions_match_sympy() -> void:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(FIXTURE))
	var functions := {}
	for c in data.cases:
		functions[c.f] = true
		var f := _fn(c.f)
		var got: Array = []
		match c.tool:
			"zeros":
				got = GraphTools.zeros(f, c.lo, c.hi).map(func(x): return [x])
			"max", "min":
				got = GraphTools.extrema(f, c.lo, c.hi, c.tool).map(func(p): return [p.x, p.y])
			"intersect":
				got = GraphTools.intersections(f, _fn(c.g), c.lo, c.hi).map(func(p): return [p.x, p.y])
		var label := "%s of %s%s on [%s, %s]" % [c.tool, c.f, " and " + c.g if c.g != null else "", c.lo, c.hi]
		if got.size() != c.want.size():
			fail("%s: found %s, SymPy has %s" % [label, got, c.want])
			continue
		for i in got.size():
			for k in c.want[i].size():
				check(_same(got[i][k], c.want[i][k]), "%s: %s, SymPy has %s" % [label, got[i], c.want[i]])
	check(functions.size() >= 20, "at least 20 test functions, %d" % functions.size())


func test_a_pole_is_not_a_zero_or_a_turning_point() -> void:
	check(GraphTools.jumps(_fn("1/x"), -0.1, 0.1), "1/x jumps at 0")
	check(not GraphTools.jumps(_fn("x^3"), -0.1, 0.1), "x³ doesn't")
	check(GraphTools.zeros(_fn("1/x"), -2.0, 2.0).is_empty(), "1/x has no zero")
	check(GraphTools.extrema(_fn("1/x^2"), -2.0, 2.0, "max").is_empty(), "1/x² has no maximum")
	check(GraphTools.extrema(_fn("-1/x^2"), -2.0, 2.0, "min").is_empty(), "−1/x² has no minimum")
	check(GraphTools.zeros(_fn("x^2+0.001"), -1.0, 1.0).is_empty(), "a near miss isn't a zero")
