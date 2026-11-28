extends LessonToy
## A training oscilloscope: gain changes height, the period dial changes spacing.
## No radio is controlled outside this scene. Only an explicit transmission is marked.

const START := Vector2(1, 8)
const PEN := Color("#5de8d6")
const REFERENCE := Color("#e9ba75")
const CRT := Color("#111f21")
var amplitude: HSlider
var period: HSlider
var feedback: Label
var readout: Label
var scope: Scope
var transmit: Button

static func check_spec(item: Dictionary) -> PackedStringArray:
	var a: Variant = item.get("amplitude", START.x)
	var t: Variant = item.get("period", START.y)
	if not legal(a, t):
		return ["signal bench requires amplitude 0–4 in halves and period 2–10 in whole seconds"]
	return []

static func legal(a: Variant, t: Variant) -> bool:
	if not (a is int or a is float) or not (t is int or t is float):
		return false
	return is_finite(float(a)) and is_finite(float(t)) and a >= 0 and a <= 4 and t >= 2 and t <= 10 and fposmod(float(a), 0.5) == 0 and fposmod(float(t), 1.0) == 0

static func valid_match(t: Dictionary) -> bool:
	return legal(t.get("amplitude"), t.get("period")) and float(t.amplitude) > 0.0

func kinds() -> PackedStringArray:
	return ["free", "match"]

func setup(item: Dictionary) -> void:
	super(item)
	var col := VBoxContainer.new()
	col.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	col.add_theme_constant_override("separation", 12)
	add_child(col)
	col.add_child(UiTheme.label("ROOK'S SIGNAL BENCH", UiTheme.SMALL, REFERENCE))
	scope = Scope.new()
	scope.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(scope)
	readout = UiTheme.label("", UiTheme.SMALL, Explainer.CHALK)
	readout.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(readout)
	amplitude = dial(col, "Amplitude", "Amplitude · volts", 0.0, 4.0, 0.5)
	period = dial(col, "Period", "Period · seconds per cycle", 2.0, 10.0, 1.0)
	transmit = Button.new()
	transmit.name = "Transmit"
	transmit.text = "Test transmission"
	transmit.custom_minimum_size.y = 135
	transmit.pressed.connect(func() -> void: perform({"kind": "send"}))
	col.add_child(transmit)
	feedback = UiTheme.label("", UiTheme.SMALL, Explainer.CHALK)
	feedback.name = "BenchFeedback"
	feedback.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(feedback)
	amplitude.set_value_no_signal(float(item.get("amplitude", START.x)))
	period.set_value_no_signal(float(item.get("period", START.y)))
	_refresh()

func dial(col: VBoxContainer, id: String, title: String, lo: float, hi: float, increment: float) -> HSlider:
	col.add_child(UiTheme.label(title, UiTheme.SMALL, Explainer.CHALK))
	var slider := HSlider.new()
	slider.name = id
	slider.accessibility_name = title
	slider.custom_minimum_size.y = 135
	slider.min_value = lo
	slider.max_value = hi
	slider.step = increment
	slider.value_changed.connect(func(_value: float) -> void: _refresh())
	col.add_child(slider)
	return slider

func start(t: Dictionary) -> void:
	if t.get("kind") == "match" and not valid_match(t):
		super({})
	else:
		super(t)
	transmit.disabled = false
	scope.reference = Vector2(float(task.amplitude), float(task.period)) if task.get("kind") == "match" else Vector2.ZERO
	feedback.text = "Match the dotted reference. Then test the transmission." if task.get("kind") == "match" else "Change one dial at a time to see what it controls."
	_refresh()

func sample(seconds: float) -> float:
	return amplitude.value * sin(TAU * seconds / period.value)

func _refresh() -> void:
	scope.signal_values = Vector2(amplitude.value, period.value)
	scope.queue_redraw()
	readout.text = "Live trace: %s V · %s s per cycle  /  Dotted: reference" % [amplitude.value, period.value] if scope.reference.y > 0 else "Live trace: %s V · %s s per cycle" % [amplitude.value, period.value]
	scope.accessibility_name = readout.text

func perform(action: Dictionary) -> void:
	if action.has("amplitude"):
		amplitude.value = float(action.amplitude)
	if action.has("period"):
		period.value = float(action.period)
	if action.get("kind") != "send" or transmit.disabled:
		return
	if task.get("kind") != "match":
		_report({"hit": null})
		return
	var height := is_equal_approx(amplitude.value, float(task.amplitude))
	var spacing := is_equal_approx(period.value, float(task.period))
	var hit := height and spacing
	if hit:
		feedback.text = "✓ Signal locked. Peak height and period both match."
		feedback.add_theme_color_override("font_color", PEN)
		transmit.disabled = true
	else:
		feedback.text = "↻ Static. Check the %s, then try again." % ("period" if height else ("amplitude" if spacing else "amplitude and period"))
		feedback.add_theme_color_override("font_color", REFERENCE)
	_report({"hit": hit, "amplitude": amplitude.value, "period": period.value})
	if hit:
		_finish({"amplitude": amplitude.value, "period": period.value})

func script_for(t: Dictionary, with_miss := false) -> Array:
	if t.get("kind") != "match" or not valid_match(t):
		return []
	var correct := {"kind": "send", "amplitude": t.amplitude, "period": t.period}
	return [{"kind": "send", "amplitude": 0.0 if t.amplitude > 0 else 1.0, "period": t.period}, correct] if with_miss else [correct]

class Scope extends Control:
	var reference := Vector2.ZERO
	var signal_values := START

	func _init() -> void:
		custom_minimum_size.y = 220
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		resized.connect(queue_redraw)

	func trace(rect: Rect2, values: Vector2) -> PackedVector2Array:
		var points := PackedVector2Array()
		for i in 145:
			var u := float(i) / 144.0
			var s := 12.0 * u
			var v := values.x * sin(TAU * s / values.y)
			points.append(rect.position + Vector2(rect.size.x * u, rect.size.y * (0.5 - v / 8.0)))
		return points

	func _draw() -> void:
		draw_style_box(_bezel(), Rect2(Vector2.ZERO, size))
		var grid := Rect2(Vector2(22, 20), Vector2(maxf(1, size.x - 44), maxf(1, size.y - 40)))
		for i in 13:
			var x := grid.position.x + float(i) * grid.size.x / 12.0
			draw_line(Vector2(x, grid.position.y), Vector2(x, grid.end.y), Color("#264a45"), 1.5)
		for i in 9:
			var y := grid.position.y + float(i) * grid.size.y / 8.0
			draw_line(Vector2(grid.position.x, y), Vector2(grid.end.x, y), Color("#426960") if i == 4 else Color("#264a45"), 2.0)
		if reference.y > 0:
			var points := trace(grid, reference)
			for i in range(0, points.size() - 2, 4):
				draw_line(points[i], points[i + 2], REFERENCE, 4.0, true)
		draw_polyline(trace(grid, signal_values), PEN, 4.5, true)

	func _bezel() -> StyleBoxFlat:
		var s := StyleBoxFlat.new()
		s.bg_color = CRT
		s.border_color = Explainer.IRON
		s.set_border_width_all(6)
		s.set_corner_radius_all(16)
		return s
