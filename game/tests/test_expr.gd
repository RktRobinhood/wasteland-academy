extends "res://tests/test_case.gd"
## The expression engine (engine/expr.gd, FAL-419): a table of expressions and their
## values, the TI rules (powers right to left, −3^2 = −9, 2x = 2 × x), degrees and
## radians, Ans, exact fractions for marking, and that it turns down anything that
## isn't maths without calling into the engine.

## [text, value, env]. env: x, ans, deg. Each value is checked to 1e-9, relative.
const TABLE := [
	["2^3^2", 512.0, {}],
	["-3^2", -9.0, {}],
	["(-3)^2", 9.0, {}],
	["2x", 6.0, {"x": 3.0}],
	["1/2", 0.5, {}],
	["sin(30)", 0.5, {"deg": true}],
	["ln(e)", 1.0, {}],
	["1+2*3", 7.0, {}],
	["(1+2)*3", 9.0, {}],
	["10-4-3", 3.0, {}],
	["12/3/2", 2.0, {}],
	["2^-1", 0.5, {}],
	["2^(1/2)", sqrt(2.0), {}],
	["-2^-2", -0.25, {}],
	["2(3+4)", 14.0, {}],
	["(1+1)(2+3)", 10.0, {}],
	["3x^2", 75.0, {"x": 5.0}],
	["x^2-4x+3", 0.0, {"x": 1.0}],
	["-x^2", -4.0, {"x": 2.0}],
	["1/2x", 2.0, {"x": 4.0}],
	["2π", 2.0 * PI, {}],
	["pi", PI, {}],
	["e^2", exp(2.0), {}],
	["e", exp(1.0), {}],
	["2e", 2.0 * exp(1.0), {}],
	["cos(60)", 0.5, {"deg": true}],
	["cos(π)", -1.0, {}],
	["sin(π/6)", 0.5, {}],
	["tan(45)", 1.0, {"deg": true}],
	["sin(30)^2", 0.25, {"deg": true}],
	["sin 30", 0.5, {"deg": true}],
	["asin(0.5)", 30.0, {"deg": true}],
	["acos(0)", PI / 2.0, {}],
	["atan(1)", 45.0, {"deg": true}],
	["arctan(1)", PI / 4.0, {}],
	["log(1000)", 3.0, {}],
	["log(100)/log(10)", 2.0, {}],
	["ln(e^3)", 3.0, {}],
	["ln 1", 0.0, {}],
	["√16", 4.0, {}],
	["√(2)^2", 2.0, {}],
	["sqrt(9)+1", 4.0, {}],
	["2√3", 2.0 * sqrt(3.0), {}],
	["abs(-4)", 4.0, {}],
	["exp(0)", 1.0, {}],
	["ans+1", 6.0, {"ans": 5.0}],
	["2Ans", 10.0, {"ans": 5.0}],
	["Ans^2", 25.0, {"ans": 5.0}],
	["3²", 9.0, {}],
	["2³", 8.0, {}],
	["x²+1", 10.0, {"x": 3.0}],
	["−5+2", -3.0, {}],
	["6÷3×2", 4.0, {}],
	["½", 0.5, {}],
	[".5+.25", 0.75, {}],
	["3.", 3.0, {}],
	["(-8)^(1/3)", -2.0, {}],
	["100(1.05)^10", 100.0 * pow(1.05, 10.0), {}],
	["5000e^(-0.2x)", 5000.0 * exp(-0.4), {"x": 2.0}],
	["2^x", 8.0, {"x": 3.0}],
	["ln(x)/ln(2)", 3.0, {"x": 8.0}],
	["--2", 2.0, {}],
	["+4", 4.0, {}],
	["3*-2", -6.0, {}],
	["[2+1]*2", 6.0, {}],
]


func test_the_table() -> void:
	check(TABLE.size() >= 50, "at least 50 expressions")
	for row in TABLE:
		var r := Expr.evaluate(row[0], row[2])
		if not r.ok:
			fail("%s did not work out: %s" % [row[0], r.error])
			continue
		var want: float = row[1]
		check(absf(r.value - want) <= 1e-9 * maxf(1.0, absf(want)), "%s = %s, not %s" % [row[0], r.value, want])


func test_the_named_cases() -> void:
	check_eq(Expr.evaluate("2^3^2").value, 512.0, "2^3^2")
	check_eq(Expr.evaluate("-3^2").value, -9.0, "-3^2")
	check_eq(Expr.evaluate("2x", {"x": 3.0}).value, 6.0, "2x at x = 3")
	check_eq(Expr.evaluate("1/2").value, 0.5, "1/2")
	check_eq(Expr.evaluate("sin(30)", {"deg": true}).value, 0.5, "sin(30) in degrees")
	check_eq(Expr.evaluate("ln(e)").value, 1.0, "ln(e)")


func test_radians_unless_told_degrees() -> void:
	check(absf(Expr.evaluate("sin(30)").value - sin(30.0)) < 1e-12, "radians by default")
	check(absf(Expr.evaluate("sin(30)", {"deg": false}).value - sin(30.0)) < 1e-12)


func test_exact_fractions_for_marking() -> void:
	var cases := {"1/2": "1/2", "2^-1": "1/2", "2(3)": "6", "1.5/2": "3/4", "(1/3)^2": "1/9", "√(9/4)": "3/2",
		"-3^2": "-9", "0.1+0.2": "3/10", "2^3^2": "512", "6/4": "3/2", "abs(-2/3)": "2/3",
		# Long fractions the engine exports for 3 s.f. answers stay exact.
		"1708800749/200000000": "1708800749/200000000", "3138428376721/200000000": "3138428376721/200000000"}
	for text in cases:
		var r := Expr.parse(text)
		var q := Expr.eval_exact(r.tree) if r.ok else null
		check(q != null and q.key() == cases[text], "%s exactly %s, got %s" % [text, cases[text], q])
	for text in ["√2", "π", "ln(2)", "e", "2^(1/2)", "sin(1)", "10^20"]:
		var r := Expr.parse(text)
		check(r.ok and Expr.eval_exact(r.tree) == null, "%s is not a fraction" % text)


func test_no_real_value() -> void:
	for text in ["1/0", "ln(0)", "ln(-1)", "√(-4)", "asin(2)", "0^-1", "(-8)^(1/2)", "log(-3)"]:
		var r := Expr.evaluate(text)
		check(not r.ok, "%s has no real value" % text)


## Anything that isn't maths is turned down by the parser, so nothing a student types
## can reach a function of the engine: names come only from Expr's own tables.
func test_rejects_anything_that_is_not_maths() -> void:
	for text in ["OS.execute('rm')", "print(1)", "get_tree().quit()", "quit()", "load(\"res://x\")", "$Node",
			"a = 3", "1;2", "\"text\"", "{}", "1,2", "x", "y+1", "foo", "sinx(", "2 3", "1.2.3", "2**3",
			"1 +", "(1+2", "1+2)", "*3", "^2", "sin", "self", "Engine", "str(1)", "#1", "1e3", "x==1",
			"Ans", "2 & 3", "1 % 2", "1 <2", "@x"]:
		var r := Expr.parse(text)
		check(not r.ok or not Expr.evaluate(text).ok, "%s should be turned down" % text)
	# x and Ans only where the caller allows them.
	check(Expr.parse("2x", ["x"]).ok and not Expr.parse("2x").ok, "x only when allowed")
	check(Expr.parse("ans+1", ["ans"]).ok and not Expr.parse("ans+1").ok, "Ans only when allowed")


## Nothing in the game uses Godot's Expression class: it reads 2^3 as 1 and can call
## engine functions, so it must never see student input.
func test_no_godot_expression_anywhere() -> void:
	for dir in ["res://engine", "res://engine/situations", "res://ui"]:
		for f in DirAccess.get_files_at(dir):
			if not f.ends_with(".gd"):
				continue
			var text := FileAccess.get_file_as_string("%s/%s" % [dir, f])
			check(not text.contains("Expression.new"), "%s/%s uses Godot's Expression" % [dir, f])
