extends "res://tests/test_case.gd"
## Typed answers (IB style): exact or right to 3 s.f., the forms a student would type,
## slot inputs for forms, read by the calculator's expression engine (never Godot's).


func _q(text: String) -> Variant:
	var r := Answer.parse_number(text)
	return r.q.key() if r.ok else null


func test_parses_what_students_type() -> void:
	var cases := {"3": "3", "-3": "-3", "−3": "-3", "3/2": "3/2", "1.5": "3/2", "-0.5": "-1/2", "−0.5": "-1/2",
		".5": "1/2", " 2 ": "2", "x = 2": "2", "x=−4": "-4", "y = 7": "7", "½": "1/2", "-½": "-1/2", "(−3)": "-3",
		"-3/2": "-3/2", "3/-2": "-3/2", "6/4": "3/2", "1.50": "3/2", "+4": "4", "0": "0"}
	for text in cases:
		check_eq(_q(text), cases[text], text)


func test_rejects_anything_that_is_not_a_number() -> void:
	for text in ["2**3", "abc", "1/0", "3x", "", "OS.execute()", "1e3", "3 4", "√2", "ln(2)", "π", "x = y"]:
		check(_q(text) == null, "%s should not parse" % text)


## Typed answers go through the calculator's expression engine (FAL-419), so arithmetic
## that works out to a fraction is read as that fraction.
func test_reads_arithmetic_with_the_expression_engine() -> void:
	var cases := {"2^3": "8", "1+1": "2", "sqrt(4)": "2", "--2": "2", "1/2/3": "1/6", "2(3)": "6", "2^-1": "1/2",
		"-3^2": "-9", "(1/2)^2": "1/4", "3/(1+1)": "3/2"}
	for text in cases:
		check_eq(_q(text), cases[text], text)
	check(Answer.parse_number("1.5").decimal and not Answer.parse_number("3/2").decimal, "decimal flag")
	check(Answer.parse_number("√2").error.begins_with("Work that out"), "an irrational value is turned down kindly")


func test_three_significant_figures() -> void:
	var third := Q.new(1, 3)
	check(Answer.number_right(Answer.parse_number("0.333").q, third))
	check(Answer.number_right(Answer.parse_number("0.3333").q, third))
	check(not Answer.number_right(Answer.parse_number("0.33").q, third))
	check(not Answer.number_right(Answer.parse_number("0.334").q, third))
	check(Answer.number_right(Answer.parse_number("-6.67").q, Q.new(-20, 3)))
	check(Answer.number_right(Answer.parse_number("1/3").q, third))
	check(not Answer.number_right(Answer.parse_number("0").q, Q.new(1, 1000)))
	check(not Answer.number_right(Answer.parse_number("0.1").q, Q.new(0)))


func test_slots_and_unordered_roots() -> void:
	var ans := Answer.make("roots", {"r1": Q.new(-1), "r2": Q.new(5)})
	check(Answer.mark(ans, {"r1": "-1", "r2": "5"}).correct)
	check(Answer.mark(ans, {"r1": "5", "r2": "−1"}).correct, "either order")
	check(not Answer.mark(ans, {"r1": "1", "r2": "-5"}).correct)
	var blank := Answer.mark(ans, {"r1": "5", "r2": ""})
	check(not blank.complete, "a blank slot is not marked")
	var bad := Answer.mark(ans, {"r1": "5", "r2": "two"})
	check(not bad.complete and bad.errors.has("r2"), "a non-number is not marked")


func test_vertex_form_slots() -> void:
	var ans := Answer.make("vertex_form", {"a": Q.new(1, 2), "h": Q.new(-3), "k": Q.new(7, 2)})
	check_eq(Answer.text(ans), "f(x) = ½(x + 3)² + 7/2")
	check(Answer.mark(ans, {"a": "0.5", "h": "-3", "k": "3.5"}).correct)
	check(not Answer.mark(ans, {"a": "0.5", "h": "3", "k": "3.5"}).correct)


func test_picks() -> void:
	var ans := Answer.make("maxmin", {"kind": "minimum", "k": Q.new(-4)})
	check(Answer.mark(ans, {"kind": "minimum", "k": "-4"}).correct)
	check(not Answer.mark(ans, {"kind": "maximum", "k": "-4"}).correct)
	check(not Answer.mark(ans, {"kind": "", "k": "-4"}).complete)


func test_formatting() -> void:
	check_eq(Fmt.general(Q.new(2), Q.new(-12), Q.new(5)), "2x² − 12x + 5")
	check_eq(Fmt.general(Q.new(-1, 2), Q.new(3, 2), Q.new(0)), "−½x² + (3/2)x")
	check_eq(Fmt.factorised(Q.new(-1), Q.new(-1), Q.new(5)), "−(x + 1)(x − 5)")
	check_eq(Fmt.vertex(Q.new(2), Q.new(3), Q.new(-4)), "2(x − 3)² − 4")
	check_eq(Fmt.point(Q.new(-3, 2), Q.new(0)), "(−3/2, 0)")
