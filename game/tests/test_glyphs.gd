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


## The catalogue's copy (concepts, misconceptions, summaries) and the credits.
func test_the_catalogue_and_the_credits_have_no_boxes() -> void:
	for path in ["res://data/catalogue.json", "res://data/credits.json"]:
		var missing := UiTheme.missing_glyphs(FileAccess.get_file_as_string(path))
		check_eq(missing, "", "%s has characters no font draws" % path)
