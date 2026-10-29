class_name Calculator
extends Control
## The in-game calculator (FAL-419), a backup for a forgotten TI-Nspire on Paper 2
## questions. One device, two modes: Scientific (the keypad, recent results, 6 s.f.)
## and Graph (two functions, pan, zoom, trace, and the zero, maximum, minimum and
## intersection tools). The practice and fight screens open it from a Paper 2
## question's Calculator button; the clock keeps running and it costs nothing.
##
## It reads what is typed with the expression engine (engine/expr.gd, the same one that
## marks typed answers) and finds points with Brent's methods (engine/graph_tools.gd).
##
## The look is the Salvage Neon Bazaar style (the themed-look table on the FAL-274
## Functions recipes): a dark riveted casing with a neon border and a stamped crown, a
## charcoal screen with the maths in mint, worn keys that glow Scrap Teal when pressed,
## Rust Orange function keys and a Bazaar Magenta mode switch. Artist's casing and key
## art (FAL-421) replace the coded look file by file from assets/ui/calculator/ (see
## game/README.md, "The calculator"); each piece falls back to the coded look.

signal closed

const ART := "ui/calculator/"
## Nine-slice margins of each art file, in pixels (game/README.md lists the sizes).
const ART_MARGINS := {"casing": 72, "screen": 28, "key": 20, "key-pressed": 20, "key-fn": 20, "key-fn-pressed": 20,
	"key-mode": 20, "key-mode-pressed": 20}

const SCREEN := Color("#1F2937")
const MINT := Color("#9FF0E6")
const TEAL := Color("#22D3C5")
const RUST := Color("#FAA261")
const MAGENTA := Color("#FF3DA7")
const DUST := Color("#EACB74")
const METAL := Color("#262B33")
const METAL_EDGE := Color("#3A404A")
const KEY := Color("#CFC6B0")
const KEY_EDGE := Color("#8C8270")
const INK := Color("#1F2937")

const WIDTH := 1040
## Wrapping text on the screen is laid out at this width (inside the casing and screen
## margins on a 360 px phone), so its height is known before the first frame.
const TEXT_WIDTH := 880
const HISTORY := 30
const TITLE_FONT := preload("res://assets/fonts/bangers-latin.woff2")

var mode := "sci"
var deg := false
var ans := 0.0
## Recent results, newest last: {"expr", "value", "text"}.
var history: Array = []

var casing: PanelContainer
var mode_button: Button
var angle_button: Button
var close_button: Button
var sci_box: VBoxContainer
var history_box: VBoxContainer
var history_scroll: ScrollContainer
var input: LineEdit
var message: Label
var graph_box: VBoxContainer
var fn_edits: Array = []
var graph: CalcGraph
var on_button: Button
var tool_buttons := {}
var readout: Label
var keypad: Keypad
## The line the keypad types into.
var focus: LineEdit

static var _mono: Font


## The calculator, closed. Add it to a screen and call open().
static func make() -> Calculator:
	var c := Calculator.new()
	c.name = "Calculator"
	c._build()
	c.visible = false
	return c


## Share Tech Mono for numbers and results, with Godot's default font behind it for the
## signs it lacks (−, π, √, ², ⁻¹).
static func mono() -> Font:
	if _mono == null:
		var f := (load("res://assets/fonts/share-tech-mono-latin.woff2") as FontFile).duplicate() as FontFile
		f.fallbacks = [ThemeDB.fallback_font]
		_mono = f
	return _mono


func open(m: String = "") -> void:
	visible = true
	if m != "":
		set_mode(m)
	_fit()
	_focus_line(input if mode == "sci" else fn_edits[0])


func close() -> void:
	if visible:
		visible = false
		closed.emit()


func set_mode(m: String) -> void:
	mode = m
	sci_box.visible = mode == "sci"
	graph_box.visible = mode == "graph"
	mode_button.text = "Scientific" if mode == "graph" else "Graph"
	keypad.buttons["x"].disabled = mode != "graph"
	_focus_line(input if mode == "sci" else fn_edits[0])
	if mode == "graph":
		_refresh_graph()


func set_angle(degrees: bool) -> void:
	deg = degrees
	angle_button.text = "DEG" if deg else "RAD"
	graph.deg = deg
	graph.queue_redraw()


# ── Building ─────────────────────────────────────────────────

func _build() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.name = "Dim"
	dim.color = Color(0, 0, 0, 0.55)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	casing = PanelContainer.new()
	casing.name = "Casing"
	casing.add_theme_stylebox_override("panel", _skin("casing", _casing_style()))
	add_child(casing)
	if ArtSlots.find(ART + "casing") == "":
		var rivets := Rivets.new()
		rivets.name = "Rivets"
		rivets.set_anchors_preset(Control.PRESET_FULL_RECT)
		rivets.mouse_filter = Control.MOUSE_FILTER_IGNORE
		casing.add_child(rivets)
	var col := VBoxContainer.new()
	col.name = "Body"
	col.add_theme_constant_override("separation", 16)
	casing.add_child(col)
	col.add_child(_header())
	var screen := PanelContainer.new()
	screen.name = "Screen"
	screen.add_theme_stylebox_override("panel", _skin("screen", _screen_style()))
	col.add_child(screen)
	var inner := VBoxContainer.new()
	inner.add_theme_constant_override("separation", 10)
	screen.add_child(inner)
	inner.add_child(_sci())
	inner.add_child(_graph())
	message = _mono_label("", UiTheme.SMALL, MAGENTA)
	message.name = "Message"
	message.custom_minimum_size = Vector2(TEXT_WIDTH, 0)
	message.visible = false
	inner.add_child(message)
	keypad = Keypad.make(Keypad.CALC_ROWS, Keypad.CALC_LAST)
	keypad.key.connect(press)
	_skin_keys()
	col.add_child(keypad)
	resized.connect(_fit)
	set_mode("sci")
	set_angle(false)


func _header() -> Control:
	var row := HBoxContainer.new()
	row.name = "Header"
	row.add_theme_constant_override("separation", 12)
	var crown := Crown.new()
	crown.custom_minimum_size = Vector2(64, 64)
	crown.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	crown.visible = ArtSlots.find(ART + "casing") == ""
	row.add_child(crown)
	var title := UiTheme.label("Field Calc", 56, TEAL)
	title.name = "Title"
	title.autowrap_mode = TextServer.AUTOWRAP_OFF
	title.add_theme_font_override("font", TITLE_FONT)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(title)
	angle_button = _label_button("RAD", "key-fn", RUST)
	angle_button.name = "Angle"
	angle_button.pressed.connect(func(): set_angle(not deg))
	row.add_child(angle_button)
	mode_button = _label_button("Graph", "key-mode", MAGENTA)
	mode_button.name = "Mode"
	mode_button.pressed.connect(func(): set_mode("graph" if mode == "sci" else "sci"))
	row.add_child(mode_button)
	close_button = _label_button("Close", "key", KEY)
	close_button.name = "Close"
	close_button.pressed.connect(close)
	row.add_child(close_button)
	return row


func _sci() -> Control:
	sci_box = VBoxContainer.new()
	sci_box.name = "Scientific"
	sci_box.add_theme_constant_override("separation", 8)
	history_scroll = ScrollContainer.new()
	history_scroll.name = "History"
	history_scroll.custom_minimum_size = Vector2(0, 380)
	history_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sci_box.add_child(history_scroll)
	history_box = VBoxContainer.new()
	history_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	history_box.add_theme_constant_override("separation", 4)
	history_scroll.add_child(history_box)
	var hint := _mono_label("Recent results: tap one to use it.", UiTheme.SMALL - 4, Color(MINT, 0.5))
	hint.name = "Hint"
	hint.autowrap_mode = TextServer.AUTOWRAP_OFF
	history_box.add_child(hint)
	input = _line("Input")
	input.text_submitted.connect(func(_t): evaluate())
	sci_box.add_child(input)
	return sci_box


func _graph() -> Control:
	graph_box = VBoxContainer.new()
	graph_box.name = "Graph"
	graph_box.add_theme_constant_override("separation", 8)
	for i in 2:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		var l := _mono_label("y%d =" % (i + 1), UiTheme.BODY, CalcGraph.COLORS[i])
		l.autowrap_mode = TextServer.AUTOWRAP_OFF
		l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(l)
		var e := _line("Y%d" % (i + 1))
		e.add_theme_color_override("font_color", CalcGraph.COLORS[i])
		e.text_changed.connect(func(_t): _refresh_graph())
		row.add_child(e)
		fn_edits.append(e)
		graph_box.add_child(row)
	graph = CalcGraph.new()
	graph.name = "Plot"
	graph.font = mono()
	graph.traced.connect(_on_traced)
	graph.view_changed.connect(func(): graph.marks.clear())
	graph_box.add_child(graph)
	var tools := HFlowContainer.new()
	tools.name = "Tools"
	tools.add_theme_constant_override("h_separation", 8)
	tools.add_theme_constant_override("v_separation", 8)
	on_button = _label_button("on y1", "key", KEY)
	on_button.name = "On"
	on_button.pressed.connect(func(): _set_target(1 - graph.trace_fn))
	tools.add_child(on_button)
	for id in ["zero", "max", "min", "intersect"]:
		var b := _label_button({"zero": "Zero", "max": "Max", "min": "Min", "intersect": "Intersect"}[id], "key-fn", RUST)
		b.name = "Tool_" + id
		b.pressed.connect(use_tool.bind(id))
		tools.add_child(b)
		tool_buttons[id] = b
	for z in [["Zoom_in", "+", 0.5], ["Zoom_out", "−", 2.0]]:
		var b := _label_button(z[1], "key", KEY)
		b.name = z[0]
		b.custom_minimum_size.x = 84
		b.add_theme_font_override("font", mono())
		b.add_theme_font_size_override("font_size", UiTheme.BIG)
		b.pressed.connect(graph.zoom.bind(z[2]))
		tools.add_child(b)
	var std := _label_button("Std", "key", KEY)
	std.name = "Zoom_std"
	std.pressed.connect(graph.set_window.bind(-10.0, 10.0, -10.0, 10.0))
	tools.add_child(std)
	graph_box.add_child(tools)
	readout = _mono_label("Drag to move, pinch or + − to zoom, tap to trace.", UiTheme.SMALL, MINT)
	readout.name = "Readout"
	readout.custom_minimum_size = Vector2(TEXT_WIDTH, 84)
	graph_box.add_child(readout)
	return graph_box


func _line(id: String) -> LineEdit:
	var e := LineEdit.new()
	e.name = id
	e.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	e.virtual_keyboard_enabled = false
	e.add_theme_font_override("font", mono())
	e.add_theme_font_size_override("font_size", UiTheme.BIG)
	e.add_theme_color_override("font_color", MINT)
	e.add_theme_color_override("caret_color", TEAL)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0, 0, 0, 0.25)
	sb.border_color = Color(MINT, 0.25)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(8)
	sb.content_margin_left = 14
	sb.content_margin_right = 14
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	e.add_theme_stylebox_override("normal", sb)
	var f := sb.duplicate()
	f.border_color = TEAL
	e.add_theme_stylebox_override("focus", f)
	e.focus_entered.connect(func(): focus = e)
	return e


func _mono_label(text: String, size: int, color: Color) -> Label:
	var l := UiTheme.label(text, size, color)
	l.add_theme_font_override("font", mono())
	return l


## A labelled button with the key look of `slot` (Bangers, for labels).
func _label_button(text: String, slot: String, color: Color) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(0, 84)
	b.add_theme_font_override("font", TITLE_FONT)
	b.add_theme_font_size_override("font_size", 40)
	_key_look(b, slot, color)
	return b


# ── The look ─────────────────────────────────────────────────

## A slot's art as a nine-slice stylebox, or the coded look when it has no file.
static func _skin(slot: String, fallback: StyleBox) -> StyleBox:
	var tex := ArtSlots.texture(ART + slot)
	if tex == null:
		return fallback
	var sb := StyleBoxTexture.new()
	sb.texture = tex
	var m: int = ART_MARGINS.get(slot, 20)
	sb.texture_margin_left = m
	sb.texture_margin_top = m
	sb.texture_margin_right = m
	sb.texture_margin_bottom = m
	for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		sb.set_content_margin(side, fallback.get_content_margin(side))
	return sb


static func _casing_style() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = METAL
	sb.border_color = TEAL
	sb.set_border_width_all(5)
	sb.set_corner_radius_all(26)
	sb.shadow_color = Color(TEAL, 0.35)
	sb.shadow_size = 22
	sb.set_content_margin_all(34)
	return sb


static func _screen_style() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = SCREEN
	sb.border_color = Color("#11161D")
	sb.set_border_width_all(6)
	sb.set_corner_radius_all(14)
	sb.set_content_margin_all(18)
	return sb


## Worn keys (sheet 3's answer buttons): light worn face and dark text for digits, Rust
## Orange for functions, Bazaar Magenta for the mode switch; pressed glows Scrap Teal.
static func _key_style(face: Color, pressed: bool) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = face.darkened(0.12) if pressed else face
	sb.border_color = TEAL if pressed else face.darkened(0.35)
	sb.set_border_width_all(5 if pressed else 2)
	sb.border_width_bottom = 5 if pressed else 7
	sb.set_corner_radius_all(12)
	if pressed:
		sb.shadow_color = Color(TEAL, 0.6)
		sb.shadow_size = 12
	sb.content_margin_left = 10
	sb.content_margin_right = 10
	sb.content_margin_top = 6
	sb.content_margin_bottom = 6
	return sb


static func _key_look(b: Button, slot: String, face: Color) -> void:
	var normal := _skin(slot, _key_style(face, false))
	var down := _skin(slot + "-pressed", _key_style(face, true))
	for state in ["normal", "hover", "disabled", "focus"]:
		b.add_theme_stylebox_override(state, normal)
	b.add_theme_stylebox_override("pressed", down)
	b.add_theme_stylebox_override("hover_pressed", down)
	var ink := Color.WHITE if face == MAGENTA else INK
	for c in ["font_color", "font_hover_color", "font_focus_color"]:
		b.add_theme_color_override(c, ink)
	b.add_theme_color_override("font_pressed_color", TEAL.darkened(0.5))
	b.add_theme_color_override("font_hover_pressed_color", TEAL.darkened(0.5))
	b.add_theme_color_override("font_disabled_color", Color(ink, 0.35))


func _skin_keys() -> void:
	for k in keypad.buttons:
		var b: Button = keypad.buttons[k]
		b.add_theme_font_override("font", mono())
		if k == "EXE":
			_key_look(b, "key-mode", TEAL)
		elif k in Keypad.FUNCTION_KEYS:
			_key_look(b, "key-fn", RUST)
		else:
			_key_look(b, "key", KEY)


## The casing fits the screen: 1040 base units wide at most (a 360 px phone shows the
## 1080-wide canvas), centred across and sitting at the bottom, so the top of the
## question stays in sight above it.
func _fit() -> void:
	if casing == null:
		return
	var w := minf(WIDTH, size.x - 24.0)
	casing.custom_minimum_size = Vector2(w, 0)
	casing.size = Vector2(w, 0)
	casing.reset_size()
	var h := casing.get_combined_minimum_size().y
	casing.position = Vector2((size.x - w) / 2.0, maxf(12.0, size.y - h - 24.0))


# ── Keys and typing ──────────────────────────────────────────

func _focus_line(e: LineEdit) -> void:
	focus = e
	if is_inside_tree() and visible:
		e.grab_focus.call_deferred()


## A key from the keypad (or a test).
func press(k: String) -> void:
	if focus == null:
		focus = input
	match k:
		"Del":
			var c := focus.caret_column
			if c > 0:
				focus.text = focus.text.substr(0, c - 1) + focus.text.substr(c)
				focus.caret_column = c - 1
		"AC":
			focus.text = ""
			message.visible = false
		"EXE":
			if mode == "sci":
				evaluate()
			else:
				_refresh_graph()
		_:
			if k == "x" and mode != "graph":
				return
			var t := Keypad.typed(k)
			var c := focus.caret_column
			focus.text = focus.text.substr(0, c) + t + focus.text.substr(c)
			focus.caret_column = c + t.length()
	if focus in fn_edits:
		_refresh_graph()


## Works out the input line (Scientific mode), adds it to the recent results and
## clears the line. Returns the value, or NAN with a message.
func evaluate() -> float:
	var text := input.text.strip_edges()
	if text == "":
		return NAN
	var r := Expr.evaluate(text, {"ans": ans, "deg": deg})
	if not r.ok:
		_say(r.error if r.error != "empty" else "")
		return NAN
	message.visible = false
	ans = r.value
	var entry := {"expr": text, "value": r.value, "text": CalcFormat.sf6(r.value)}
	history.append(entry)
	if history.size() > HISTORY:
		history.pop_front()
	_add_history_row(entry)
	input.text = ""
	return r.value


func _add_history_row(entry: Dictionary) -> void:
	var b := Button.new()
	b.name = "Result%d" % history.size()
	b.flat = true
	b.focus_mode = Control.FOCUS_NONE
	b.alignment = HORIZONTAL_ALIGNMENT_RIGHT
	b.text = "%s\n= %s" % [entry.expr, entry.text]
	b.add_theme_font_override("font", mono())
	b.add_theme_font_size_override("font_size", UiTheme.BODY)
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		b.add_theme_color_override(c, MINT)
	b.pressed.connect(func():
		var t: String = entry.text.replace("−", "-").replace("E", "*10^")
		var c := input.caret_column
		input.text = input.text.substr(0, c) + t + input.text.substr(c)
		input.caret_column = c + t.length()
		_focus_line(input))
	history_box.add_child(b)
	while history_box.get_child_count() > HISTORY + 1:
		history_box.get_child(1).queue_free()
		history_box.remove_child(history_box.get_child(1))
	_scroll_down.call_deferred()


func _scroll_down() -> void:
	if is_instance_valid(history_scroll):
		history_scroll.scroll_vertical = int(history_scroll.get_v_scroll_bar().max_value)


func _say(text: String) -> void:
	message.text = text
	message.visible = text != ""


# ── Graph mode ───────────────────────────────────────────────

## Reads the two function lines into the graph; a line that doesn't read is left out
## and says why.
func _refresh_graph() -> void:
	var errors: Array = []
	for i in 2:
		var text: String = fn_edits[i].text.strip_edges()
		if text == "":
			graph.functions[i] = null
			continue
		var r := Expr.parse(text, ["x"])
		graph.functions[i] = r.tree if r.ok else null
		if not r.ok:
			errors.append("y%d: %s" % [i + 1, r.error])
	graph.marks.clear()
	graph.trace = {}
	if graph.functions[graph.trace_fn] == null and graph.functions[1 - graph.trace_fn] != null:
		_set_target(1 - graph.trace_fn)
	_say(" ".join(errors))
	graph.queue_redraw()


func _set_target(fn: int) -> void:
	graph.trace_fn = fn
	on_button.text = "on y%d" % (fn + 1)
	_key_look(on_button, "key", KEY)
	on_button.add_theme_color_override("font_color", CalcGraph.COLORS[fn].darkened(0.45))


## Runs a graph tool on the window shown: "zero", "max" or "min" on the function the
## tools are on, or "intersect" on y1 and y2. Marks every point found in Dust Yellow and
## lists them to 6 s.f. Returns the points ({"x", "y"}).
func use_tool(id: String) -> Array:
	var lo := graph.x_min
	var hi := graph.x_max
	var pts: Array = []
	var fn := graph.trace_fn
	if id == "intersect":
		if graph.functions[0] == null or graph.functions[1] == null:
			readout.text = "Intersect needs y1 and y2."
			return []
		pts = GraphTools.intersections(graph.function_at(0), graph.function_at(1), lo, hi)
	else:
		if graph.functions[fn] == null:
			readout.text = "Type a function in y%d first." % (fn + 1)
			return []
		var f := graph.function_at(fn)
		if id == "zero":
			pts = GraphTools.zeros(f, lo, hi).map(func(x): return {"x": x, "y": 0.0})
		else:
			pts = GraphTools.extrema(f, lo, hi, id)
	graph.marks = pts
	graph.queue_redraw()
	var what: String = {"zero": "Zero", "max": "Maximum", "min": "Minimum", "intersect": "Intersection"}[id]
	if pts.is_empty():
		readout.text = "No %s in this window. Move or zoom out." % what.to_lower()
	else:
		var lines: Array = []
		for p in pts.slice(0, 4):
			lines.append("%s: x = %s, y = %s" % [what, CalcFormat.sf6(p.x), CalcFormat.sf6(p.y)])
		if pts.size() > 4:
			lines.append("and %d more" % (pts.size() - 4))
		readout.text = "\n".join(lines)
	return pts


func _on_traced(fn: int, x: float, y: float) -> void:
	readout.text = "Trace y%d: x = %s, y = %s" % [fn + 1, CalcFormat.sf6(x), CalcFormat.sf6(y) if is_finite(y) else "no value"]


## Rivets in the casing's corners and along its edges, in the coded look.
class Rivets extends Control:
	func _draw() -> void:
		# The rivets sit in the casing's rim, outside the content this control covers.
		var inset := -17.0
		var pts := [Vector2(inset, inset), Vector2(size.x - inset, inset), Vector2(inset, size.y - inset),
			Vector2(size.x - inset, size.y - inset), Vector2(size.x / 2.0, inset), Vector2(size.x / 2.0, size.y - inset),
			Vector2(inset, size.y / 2.0), Vector2(size.x - inset, size.y / 2.0)]
		for p in pts:
			draw_circle(p, 8.0, Color("#15181D"))
			draw_circle(p, 6.0, Color("#6B7280"))
			draw_circle(p + Vector2(-2, -2), 2.5, Color("#C9CED6"))
		# Worn edges: a few scratches across the metal.
		var scratch := Color(1, 1, 1, 0.05)
		draw_line(Vector2(size.x * 0.08, size.y * 0.3), Vector2(size.x * 0.2, size.y * 0.27), scratch, 3.0)
		draw_line(Vector2(size.x * 0.85, size.y * 0.62), Vector2(size.x * 0.95, size.y * 0.66), scratch, 3.0)
		draw_line(Vector2(size.x * 0.4, size.y * 0.97), Vector2(size.x * 0.55, size.y * 0.965), scratch, 3.0)


## The crown motif, stamped in Bazaar Magenta.
class Crown extends Control:
	func _draw() -> void:
		var w := size.x
		var h := size.y
		var pts := PackedVector2Array([Vector2(0.1 * w, 0.8 * h), Vector2(0.1 * w, 0.3 * h), Vector2(0.32 * w, 0.55 * h),
			Vector2(0.5 * w, 0.2 * h), Vector2(0.68 * w, 0.55 * h), Vector2(0.9 * w, 0.3 * h), Vector2(0.9 * w, 0.8 * h),
			Vector2(0.1 * w, 0.8 * h)])
		draw_polyline(pts, Color(MAGENTA, 0.9), 5.0, true)
