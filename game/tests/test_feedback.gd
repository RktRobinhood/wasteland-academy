extends "res://tests/test_case.gd"
## The feedback check (tools/feedback_check.gd) on the kinds of string FAL-729 found.

const Check := preload("res://tools/feedback_check.gd")


func test_a_string_has_to_name_the_slip() -> void:
	for text in ["Thinking a limit can't exist when the function never reaches the value", "Assuming a right angle because it looks like one",
			"Using the wrong sign", "Not dividing by all the paths"]:
		check(Check.names_a_slip(text), text)
	for text in ["Writes the rule with the sign reversed", "Thinks the order never matters", "Gives the vertex with the wrong sign", "Joins the two regions into one interval"]:
		check(Check.names_a_slip(text), text)
	for text in ["At rest means a = 0", "A random sample is always perfectly representative", "sin 2θ = 2 sin θ", "Sign slips", "Nothing changes", "",
			"The mean is always the best average", "Angles add up to 90°", "Not writes the rule"]:
		check(not Check.names_a_slip(text), text)


func test_numbers_from_another_question_are_found() -> void:
	var stem := "Find P(X > 203 | X > 179). The answer is 0.229."
	check_eq(Check.strange_numbers("Multiplying P(X > 35) × P(X > 30)", stem), ["35", "30"])
	check_eq(Check.strange_numbers("Multiplying the wanted probability", stem), [])
	check_eq(Check.strange_numbers("Giving 203, not 179", stem), [])
	check_eq(Check.strange_numbers("Missing the factor ½", "∫ e^(4x − 3) dx = ¼e^(4x − 3)"), ["½"])
	check_eq(Check.strange_numbers("Missing the factor ½", "(1/2)x² + C"), [])
	check_eq(Check.strange_numbers("Writing 45 000", "the number 45000.0"), [])


func test_new_types_are_enforced() -> void:
	for id in ["t4-sampling", "t3-arc-sector", "t3-trig-equation"]:
		check(not id in Check.REPORT_ONLY, id)
