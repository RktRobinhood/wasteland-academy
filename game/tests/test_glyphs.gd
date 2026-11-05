extends "res://tests/test_case.gd"
## Every character the game shows can be drawn (FAL-514): the default font (Open Sans)
## has no ⁻, ∘, ↦, →, ≡, ℝ or ∈, so the maths subset of DejaVu Sans sits behind it.
## Questions are checked the same way by tools/check-answers.


func test_the_maths_signs_have_glyphs() -> void:
	var signs := "x⁻² ∘ ↦ → ≡ ℝ ℤ ∈ ∩ ∪ ⇔ ∛ ₑ ᵢ □ ❚ − √ π ≥ ≤ ½ Δ"
	check_eq(UiTheme.missing_glyphs(signs), "", "the maths signs")


func test_the_check_finds_a_character_no_font_has() -> void:
	# U+E000 is a private-use code point: no shipped font draws it.
	check_eq(UiTheme.missing_glyphs("ab"), "", "reported once")


func test_the_font_stack_is_the_fallback_of_the_calculator_font() -> void:
	UiTheme.install_math_font()
	UiTheme.install_math_font()
	check_eq(ThemeDB.fallback_font.fallbacks.count(UiTheme.MATH_FONT), 1, "installed once")
	check(Calculator.mono().has_char("⁻".unicode_at(0)), "the calculator's mono font draws ⁻ through its fallbacks")


func test_powers_are_cut_out_of_the_text() -> void:
	# FAL-743.
	var raised := func(s: String) -> Array:
		return Fmt.power_runs(s).filter(func(run): return run[1]).map(func(run): return run[0])
	check_eq(raised.call("e^(4x − 3) = 2"), ["4x − 3"])
	check_eq(raised.call("a × 10^k, and"), ["k"])
	check_eq(raised.call("P(t) = 130(1.3)^t."), ["t"])
	check_eq(raised.call("e^x(sin x)"), ["x"])
	check_eq(raised.call("1.17^9 = 4.10840."), ["9"])
	check_eq(raised.call("3e^(−0.5x²) + 2^(x/2)"), ["−0.5x²", "x/2"])
	check_eq(raised.call("e^((1/3)(x − 1))"), ["(1/3)(x − 1)"])
	check_eq(raised.call("a^−n"), ["−n"])
	check_eq(Fmt.power_runs("no power, 2 ^ 3 and ^("), [["no power, 2 ^ 3 and ^(", false]])
	check_eq(Fmt.power_runs("e^x + 1"), [["e", false], ["x", true], [" + 1", false]])


func test_only_text_with_a_power_is_rich_text() -> void:
	var plain := UiTheme.math("x² + 1")
	check(plain is Label, "plain text stays a label")
	plain.free()
	var rich := UiTheme.math("e^(2x)", UiTheme.BODY, UiTheme.SAND, true)
	check(rich is RichTextLabel, "a power is rich text")
	check_eq(rich.mouse_filter, Control.MOUSE_FILTER_IGNORE, "a swipe starts on it, as on a label")
	check_eq(rich.get_parsed_text(), "e2x")
	rich.free()


## The catalogue's copy (concepts, misconceptions, summaries) and the credits.
func test_the_catalogue_and_the_credits_have_no_boxes() -> void:
	for path in ["res://data/catalogue.json", "res://data/credits.json"]:
		var missing := UiTheme.missing_glyphs(FileAccess.get_file_as_string(path))
		check_eq(missing, "", "%s has characters no font draws" % path)
