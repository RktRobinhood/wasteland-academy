extends RefCounted
## A quiet chalkboard diagram. The player receives only the fields for this beat;
## an output is never computed here or inferred from the numbers on the board.

static func supports(fig: Dictionary) -> bool:
	if fig.get("kind") != "function-machine":
		return false
	for key in ["id", "title", "input", "rule"]:
		if not fig.get(key) is String or str(fig[key]).strip_edges().is_empty():
			return false
	var phase = fig.get("phase")
	if phase == "given":
		return not fig.has("expression") and not fig.has("output")
	if phase == "substitute" or phase == "evaluate":
		if not fig.get("expression") is String or str(fig.expression).strip_edges().is_empty():
			return false
		return (fig.get("output") is String and not str(fig.output).strip_edges().is_empty()) if phase == "evaluate" else not fig.has("output")
	return false


static func make(fig: Dictionary, alt: String) -> Control:
	var outer := _panel(Explainer.SLATE_DEEP, Explainer.IRON, 26, 20)
	outer.name = "FunctionMachineFigure"
	outer.accessibility_name = alt
	var layout := VBoxContainer.new()
	layout.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layout.add_theme_constant_override("separation", 14)
	outer.add_child(layout)
	var title := _label(str(fig.title), UiTheme.SMALL, Explainer.DUST)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	layout.add_child(title)

	var flow := HBoxContainer.new()
	flow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flow.add_theme_constant_override("separation", 14)
	layout.add_child(flow)
	flow.add_child(_cell("Input", str(fig.input), "InputValue", Explainer.IRON))
	flow.add_child(Arrow.new())
	flow.add_child(_cell("Relay rule", str(fig.rule), "RuleValue", Explainer.IRON_GLOSS, 2.25))
	flow.add_child(Arrow.new())
	flow.add_child(_cell("Output", str(fig.get("output", "?")), "OutputValue",
		Explainer.TEAL if fig.has("output") else Explainer.IRON))

	if fig.has("expression"):
		var expression := _label(str(fig.expression), UiTheme.BODY, Explainer.CHALK)
		expression.name = "Substitution"
		layout.add_child(expression)
	return outer


static func _cell(label: String, value: String, node_name: String, border: Color, weight := 1.0) -> PanelContainer:
	var box := _panel(Explainer.SLATE, border, 9, 9)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.size_flags_stretch_ratio = weight
	var words := VBoxContainer.new()
	words.mouse_filter = Control.MOUSE_FILTER_IGNORE
	words.add_theme_constant_override("separation", 2)
	box.add_child(words)
	words.add_child(_label(label, UiTheme.SMALL, Explainer.IRON_GLOSS))
	var content := UiTheme.math(value, UiTheme.BODY, Explainer.CHALK, true)
	content.name = node_name
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	words.add_child(content)
	return box


class Arrow extends Control:
	func _init() -> void:
		custom_minimum_size.x = 38.0
		size_flags_vertical = Control.SIZE_FILL
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var y := size.y * 0.5
		var head := Vector2(size.x - 3.0, y)
		draw_line(Vector2(3.0, y), head, Explainer.DUST, 4.0, true)
		draw_line(head - Vector2(11.0, 9.0), head, Explainer.DUST, 4.0, true)
		draw_line(head - Vector2(11.0, -9.0), head, Explainer.DUST, 4.0, true)


static func _panel(fill: Color, edge: Color, pad_x: int, pad_y: int) -> PanelContainer:
	var box := PanelContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = edge
	style.set_border_width_all(3)
	style.set_corner_radius_all(7)
	style.content_margin_left = pad_x
	style.content_margin_right = pad_x
	style.content_margin_top = pad_y
	style.content_margin_bottom = pad_y
	box.add_theme_stylebox_override("panel", style)
	return box


static func _label(value: String, size: int, colour: Color) -> Label:
	var label := UiTheme.label(value, size, colour)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return label
