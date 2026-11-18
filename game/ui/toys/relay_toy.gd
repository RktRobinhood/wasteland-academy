class_name RelayToy
extends LessonToy
## The relay (#217): Rook's box at the top of the mast. Dial a whole number in, throw the
## switch, and the rule's output goes out along the wire to a pin on the map strip. Every
## send is written on the board as "in 2 → out 0". The rule comes from the script, so
## one toy serves every rule a Functions lesson names.
##
## The toy item:
##   {"toy": "relay", "rule": "x^2 - 4", "dial": [-5, 5]}
##   "rule"    the rule in x, as the expression engine reads it (engine/expr.gd): x² − 4,
##             x^2 - 4 and 6 - 2x all work
##   "dial"    the dial's least and greatest whole numbers, [-5, 5] if left out
##   "label"   optional: written on the box, such as "f" once the lesson has named it
##   "places"  optional: settlements on the map by output, {"12": "Scrap Fields"}
##   "broken"  optional: a second rule. Every input then gives two outputs, both on the
##             wire at once (oupa's radio: "that's no function")
## Tasks: {"kind": "free", "count": 3}, {"kind": "send", "input": -3} and
## {"kind": "find", "output": 12}. Any input that gives the output meets a find, so 4 and
## −4 both do for 12. A send that misses still goes out: static on the box, a pin on the
## wrong part of the map, and the host plays a reaction line from the acted signal.

const MINUS := "−"
const DIAL_DEFAULT := [-5, 5]
## How far a finger drags the dial for one step, in base units.
const DRAG_STEP := 70.0
## Seconds: the signal along the wire, and the static after a miss.
const TRAVEL := 0.55
const STATIC := 0.9
const TOUCH := 150.0

var rule := ""
var broken := ""
var lo := -5
var hi := 5
var value := 0
## The last send's outputs, and whether it missed.
var last_outputs: Array = []
var last_hit: Variant = null

var map_strip: MapStrip
var box: RelayBox
var dial_label: Label
var minus_button: Button
var plus_button: Button
var dial_face: DialFace
var switch_button: Button
var task_label: Label
var log_scroll: ScrollContainer
var log_lines: VBoxContainer
var static_overlay: StaticOverlay
## 0 to 1 while a signal travels the wire; -1 when the wire is quiet.
var travel := -1.0
var static_left := 0.0
var _drag := 0.0


static func check_spec(item: Dictionary) -> PackedStringArray:
	var out: PackedStringArray = []
	if typeof(item.get("rule")) != TYPE_STRING or str(item.rule).strip_edges() == "":
		out.append("the relay needs a rule in x")
	elif not Expr.evaluate(str(item.rule), {"x": 1.0}).ok:
		out.append("the relay can't read its rule \"%s\"" % item.rule)
	if item.has("broken") and not Expr.evaluate(str(item.broken), {"x": 1.0}).ok:
		out.append("the relay can't read its broken rule \"%s\"" % item.broken)
	var d: Variant = item.get("dial", DIAL_DEFAULT)
	if typeof(d) != TYPE_ARRAY or d.size() != 2 or int(d[0]) >= int(d[1]) \
			or float(d[0]) != floorf(float(d[0])) or float(d[1]) != floorf(float(d[1])):
		out.append("the relay's dial is two whole numbers, least first")
	return out


## A number as the board writes it: whole numbers plain, a true minus sign.
static func num(v: float) -> String:
	var s := str(int(roundf(v))) if absf(v - roundf(v)) < 1e-9 else str(snappedf(v, 0.001))
	return s.replace("-", MINUS)


func _init() -> void:
	name = "Relay"
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_build()


func setup(item: Dictionary) -> void:
	super(item)
	rule = str(item.get("rule", "x"))
	broken = str(item.get("broken", ""))
	var d: Array = item.get("dial", DIAL_DEFAULT)
	lo = int(d[0])
	hi = int(d[1])
	value = clampi(0, lo, hi)
	box.label = str(item.get("label", ""))
	box.broken = broken != ""
	_refresh()


func start(t: Dictionary) -> void:
	super(t)
	_refresh()


func kinds() -> PackedStringArray:
	return ["free", "send", "find"]


## The rule's outputs for an input: one, or two on the broken relay.
func outputs_for(x: int) -> Array:
	var out := [_eval(rule, x)]
	if broken != "":
		out.append(_eval(broken, x))
	return out


func _eval(r: String, x: int) -> float:
	var e := Expr.evaluate(r, {"x": float(x)})
	return float(e.value) if e.ok else NAN


## Every dial input that meets a find, least first.
func answers_for(output: float) -> Array:
	var out := []
	for x in range(lo, hi + 1):
		for y in outputs_for(x):
			if is_equal_approx(y, output):
				out.append(x)
				break
	return out


func script_for(t: Dictionary, with_miss := false) -> Array:
	match str(t.get("kind", "free")):
		"send":
			var target := int(t.get("input", 0))
			var acts := []
			if with_miss:
				acts.append({"send": target + 1 if target + 1 <= hi else target - 1})
			acts.append({"send": target})
			return acts
		"find":
			var ok := answers_for(float(t.get("output", 0)))
			if ok.is_empty():
				return []
			var acts := []
			if with_miss:
				for x in range(lo, hi + 1):
					if not ok.has(x):
						acts.append({"send": x})
						break
			acts.append({"send": ok[-1]})
			return acts
		_:
			var acts := []
			var count := int(t.get("count", 1))
			for i in count:
				acts.append({"send": lo + (i * 3 + 2) % (hi - lo + 1)})
			return acts


func perform(action: Dictionary) -> void:
	if action.has("dial"):
		set_dial(int(action.dial))
	if action.has("send"):
		set_dial(int(action.send))
		send()


func set_dial(v: int) -> void:
	value = clampi(v, lo, hi)
	_refresh()


func step_dial(by: int) -> void:
	set_dial(value + by)


## Throw the switch: the dial's value goes through the rule and out along the wire.
func send() -> void:
	var outs := outputs_for(value)
	var kind := str(task.get("kind", "free"))
	var hit: Variant = null
	match kind:
		"send":
			hit = value == int(task.get("input", 0))
		"find":
			hit = false
			for y in outs:
				if is_equal_approx(y, float(task.get("output", 0))):
					hit = true
	last_outputs = outs
	last_hit = hit
	var words := PackedStringArray()
	for y in outs:
		words.append(num(y))
	var line := "in %s → out %s" % [num(value), " and ".join(words)]
	_write(line, hit == false)
	travel = -1.0 if reduced_motion else 0.0
	if hit == false:
		static_left = STATIC
	map_strip.show_send(outs, hit)
	box.lit = true
	_report({"input": value, "outputs": outs, "hit": hit, "board": line})
	if task.is_empty():
		_refresh()
		return
	var done := false
	match kind:
		"send", "find":
			done = hit == true
		_:
			done = _actions >= int(task.get("count", 1))
	if done:
		var extra := {"input": value}
		if kind == "find":
			extra["answers"] = answers_for(float(task.get("output", 0)))
		_finish(extra)
	_refresh()


func _write(line: String, missed: bool) -> void:
	var l := UiTheme.label(line, UiTheme.BODY, Explainer.RUST if missed else Explainer.CHALK)
	l.name = "Send%d" % log_lines.get_child_count()
	l.add_theme_font_override("font", Explainer.mono_with_fallback())
	l.autowrap_mode = TextServer.AUTOWRAP_OFF
	log_lines.add_child(l)
	log_scroll.ensure_control_visible.call_deferred(l)


func _refresh() -> void:
	if dial_label == null:
		return
	dial_label.text = num(value)
	minus_button.disabled = value <= lo
	plus_button.disabled = value >= hi
	box.input_text = num(value)
	var words := PackedStringArray()
	for y in last_outputs:
		words.append(num(y))
	box.output_text = " / ".join(words) if not words.is_empty() else "–"
	var kind := str(task.get("kind", ""))
	match kind:
		"send":
			task_label.text = "Send %s" % num(float(task.input))
		"find":
			task_label.text = "Find an input that gives %s" % num(float(task.output))
		"free":
			task_label.text = "Send any %d" % int(task.get("count", 1)) if int(task.get("count", 1)) > 1 else "Send any signal"
		_:
			task_label.text = ""
	task_label.visible = task_label.text != ""
	map_strip.target = float(task.output) if kind == "find" else NAN
	map_strip.range_from(self)
	map_strip.places = spec.get("places", {})
	if kind == "find":
		map_strip.target_name = str(task.get("place", ""))
	map_strip.queue_redraw()
	box.queue_redraw()
	dial_face.queue_redraw()


func _process(delta: float) -> void:
	var moving := false
	if travel >= 0.0:
		travel += delta / TRAVEL
		if travel >= 1.0:
			travel = -1.0
		moving = true
	if static_left > 0.0:
		static_left = maxf(0.0, static_left - delta)
		moving = true
	static_overlay.visible = static_left > 0.0
	static_overlay.still = reduced_motion
	box.travel = travel
	if moving:
		box.queue_redraw()
		static_overlay.queue_redraw()


func _unhandled_key_input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	if event.is_action_pressed("ui_left"):
		step_dial(-1)
	elif event.is_action_pressed("ui_right"):
		step_dial(1)
	else:
		return
	get_viewport().set_input_as_handled()


func _build() -> void:
	var col := VBoxContainer.new()
	col.name = "Column"
	col.set_anchors_preset(Control.PRESET_FULL_RECT)
	col.add_theme_constant_override("separation", 16)
	add_child(col)

	task_label = UiTheme.label("", UiTheme.BODY, Explainer.DUST)
	task_label.name = "Task"
	task_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(task_label)

	map_strip = MapStrip.new()
	map_strip.name = "Map"
	map_strip.custom_minimum_size.y = 150
	col.add_child(map_strip)

	box = RelayBox.new()
	box.name = "Box"
	box.custom_minimum_size.y = 260
	col.add_child(box)

	var dial_row := HBoxContainer.new()
	dial_row.name = "DialRow"
	dial_row.add_theme_constant_override("separation", 18)
	dial_row.alignment = BoxContainer.ALIGNMENT_CENTER
	minus_button = _key("Minus", MINUS)
	minus_button.pressed.connect(step_dial.bind(-1))
	dial_row.add_child(minus_button)
	dial_face = DialFace.new()
	dial_face.name = "Dial"
	dial_face.toy = self
	dial_face.custom_minimum_size = Vector2(320, TOUCH)
	dial_face.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dial_row.add_child(dial_face)
	dial_label = UiTheme.label("0", UiTheme.BIG, Explainer.CHALK)
	dial_label.name = "Value"
	dial_label.add_theme_font_override("font", Explainer.mono_with_fallback())
	dial_label.add_theme_font_size_override("font_size", 72)
	dial_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dial_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	dial_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	dial_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	dial_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dial_face.add_child(dial_label)
	plus_button = _key("Plus", "+")
	plus_button.pressed.connect(step_dial.bind(1))
	dial_row.add_child(plus_button)
	col.add_child(dial_row)

	switch_button = Button.new()
	switch_button.name = "Switch"
	switch_button.text = "Throw the switch"
	switch_button.custom_minimum_size.y = TOUCH
	switch_button.add_theme_font_size_override("font_size", UiTheme.BIG)
	switch_button.add_theme_color_override("font_color", Explainer.INK)
	switch_button.add_theme_color_override("font_hover_color", Explainer.INK)
	switch_button.add_theme_color_override("font_pressed_color", Explainer.INK)
	var ss := StyleBoxFlat.new()
	ss.bg_color = Explainer.RUST
	ss.border_color = Explainer.RUST_SHADE
	ss.set_border_width_all(6)
	ss.set_corner_radius_all(12)
	switch_button.add_theme_stylebox_override("normal", ss)
	switch_button.add_theme_stylebox_override("hover", ss)
	var sp := ss.duplicate() as StyleBoxFlat
	sp.bg_color = Explainer.RUST_SHADE
	switch_button.add_theme_stylebox_override("pressed", sp)
	switch_button.pressed.connect(send)
	col.add_child(switch_button)

	log_scroll = ScrollContainer.new()
	log_scroll.name = "Log"
	log_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	log_scroll.custom_minimum_size.y = 160
	log_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	col.add_child(log_scroll)
	log_lines = VBoxContainer.new()
	log_lines.name = "Lines"
	log_lines.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	log_lines.add_theme_constant_override("separation", 8)
	log_scroll.add_child(log_lines)

	static_overlay = StaticOverlay.new()
	static_overlay.name = "Static"
	static_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	static_overlay.visible = false
	box.add_child(static_overlay)
	static_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)


func _key(id: String, text: String) -> Button:
	var b := Button.new()
	b.name = id
	b.text = text
	b.custom_minimum_size = Vector2(TOUCH, TOUCH)
	b.add_theme_font_size_override("font_size", 72)
	return b


## Drag along the dial to turn it; a tap on its left or right half turns it one step.
## Mouse events only: a finger arrives as the mouse too (emulate_mouse_from_touch), so
## reading both would turn the dial twice.
func _dial_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and (event.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0:
		_drag += event.relative.x
		while absf(_drag) >= DRAG_STEP:
			step_dial(1 if _drag > 0 else -1)
			_drag -= DRAG_STEP * signf(_drag)
			dial_face._dragged = true
		dial_face.accept_event()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_drag = 0.0
			dial_face._dragged = false
		elif not dial_face._dragged:
			step_dial(1 if event.position.x > dial_face.size.x / 2.0 else -1)
		dial_face.accept_event()


## The dial: ticks for every whole number, the needle at the value.
class DialFace extends Control:
	var toy: RelayToy
	var _dragged := false

	func _gui_input(event: InputEvent) -> void:
		toy._dial_input(event)

	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size)
		draw_rect(r, Explainer.SLATE_DEEP)
		draw_rect(r, Explainer.IRON, false, 4.0)
		var n := toy.hi - toy.lo
		for i in n + 1:
			var x := lerpf(24.0, size.x - 24.0, float(i) / n)
			var on := toy.lo + i == toy.value
			draw_line(Vector2(x, size.y - 10), Vector2(x, size.y - (34 if on else 20)),
				Explainer.MAGENTA if on else Explainer.IRON_GLOSS, 6.0 if on else 3.0)


## The box at the top of the mast: the input going in, the lamp, the output coming out,
## and the wire up to the map. The broken relay has two output lamps.
class RelayBox extends Control:
	var label := ""
	var input_text := "0"
	var output_text := "–"
	var lit := false
	var broken := false
	var travel := -1.0

	func _draw() -> void:
		var font := Explainer.mono_with_fallback()
		var mid := size / 2.0
		var bw := minf(size.x * 0.36, 340.0)
		var bh := size.y * 0.62
		var b := Rect2(mid.x - bw / 2.0, mid.y - bh / 2.0 + 20, bw, bh)
		# The mast and the wire up to the map strip.
		draw_line(Vector2(mid.x, 0), Vector2(mid.x, b.position.y), Explainer.IRON_GLOSS, 6.0)
		if travel >= 0.0:
			var y := lerpf(b.position.y, 0.0, travel)
			draw_circle(Vector2(mid.x, y), 16.0, Explainer.TEAL)
			if broken:
				draw_circle(Vector2(mid.x + 26, y + 10), 16.0, Explainer.MAGENTA)
		# Input and output wires.
		draw_line(Vector2(40, b.get_center().y), Vector2(b.position.x, b.get_center().y), Explainer.IRON_GLOSS, 6.0)
		draw_line(Vector2(b.end.x, b.get_center().y), Vector2(size.x - 40, b.get_center().y), Explainer.IRON_GLOSS, 6.0)
		draw_rect(b, Explainer.IRON)
		draw_rect(b, Explainer.IRON_SHADE, false, 8.0)
		var lamp := Explainer.TEAL if lit else Explainer.IRON_SHADE
		draw_circle(b.position + Vector2(bw / 2.0 - (22 if broken else 0), 34), 16, lamp)
		if broken:
			draw_circle(b.position + Vector2(bw / 2.0 + 22, 34), 16, Explainer.MAGENTA if lit else Explainer.IRON_SHADE)
		if label != "":
			draw_string(font, b.position + Vector2(0, bh * 0.72), label, HORIZONTAL_ALIGNMENT_CENTER, bw, 64, Explainer.CHALK)
		var fs := 54
		draw_string(font, Vector2(0, b.position.y - 6), "IN", HORIZONTAL_ALIGNMENT_CENTER, b.position.x, 30, Explainer.DUST)
		draw_string(font, Vector2(0, b.get_center().y + fs + 10), input_text, HORIZONTAL_ALIGNMENT_CENTER, b.position.x, fs, Explainer.CHALK)
		draw_string(font, Vector2(b.end.x, b.position.y - 6), "OUT", HORIZONTAL_ALIGNMENT_CENTER, size.x - b.end.x, 30, Explainer.DUST)
		draw_string(font, Vector2(b.end.x, b.get_center().y + fs + 10), output_text, HORIZONTAL_ALIGNMENT_CENTER, size.x - b.end.x, fs, Explainer.CHALK)


## The strip of map the wire reaches: the settlements along it by output, the target of
## a find, and a pin where the last send landed (rust when it missed).
class MapStrip extends Control:
	var lo_out := 0.0
	var hi_out := 1.0
	var places: Dictionary = {}
	var target := NAN
	var target_name := ""
	var pins: Array = []
	var pin_hit: Variant = null

	func range_from(toy: RelayToy) -> void:
		lo_out = INF
		hi_out = -INF
		for x in range(toy.lo, toy.hi + 1):
			for y in toy.outputs_for(x):
				if is_finite(y):
					lo_out = minf(lo_out, y)
					hi_out = maxf(hi_out, y)
		if not is_finite(lo_out) or hi_out <= lo_out:
			lo_out = 0.0
			hi_out = 1.0

	func show_send(outs: Array, hit: Variant) -> void:
		pins = outs
		pin_hit = hit
		queue_redraw()

	func x_of(v: float) -> float:
		return lerpf(60.0, size.x - 60.0, clampf((v - lo_out) / (hi_out - lo_out), 0.0, 1.0))

	func _draw() -> void:
		var font := Explainer.mono_with_fallback()
		var ground := size.y * 0.7
		draw_rect(Rect2(0, 0, size.x, size.y), Color(Explainer.DUST, 0.08))
		draw_line(Vector2(30, ground), Vector2(size.x - 30, ground), Color(Explainer.DUST, 0.5), 4.0)
		for k in places:
			var x := x_of(float(k))
			draw_rect(Rect2(x - 18, ground - 30, 36, 30), Explainer.IRON_GLOSS)
			draw_string(font, Vector2(x - 150, size.y - 6), str(places[k]), HORIZONTAL_ALIGNMENT_CENTER, 300, 26, Explainer.CHALK)
		if is_finite(target):
			var x := x_of(target)
			draw_rect(Rect2(x - 22, ground - 38, 44, 38), Explainer.DUST)
			var name := target_name if target_name != "" else "wants %s" % RelayToy.num(target)
			draw_string(font, Vector2(x - 160, size.y - 6), name, HORIZONTAL_ALIGNMENT_CENTER, 320, 28, Explainer.DUST)
		for i in pins.size():
			var y: float = pins[i]
			if not is_finite(y):
				continue
			var c := Explainer.RUST if pin_hit == false else (Explainer.TEAL if i == 0 else Explainer.MAGENTA)
			var p := Vector2(x_of(y), ground - 64)
			draw_line(p, Vector2(p.x, ground), c, 5.0)
			draw_circle(p, 18.0, c)
			draw_string(font, p + Vector2(-80, -28), RelayToy.num(y), HORIZONTAL_ALIGNMENT_CENTER, 160, 30, c)


## Static over the box after a miss. With reduced motion it is a still wash, so the cost
## still shows without flicker.
class StaticOverlay extends Control:
	var still := false

	func _draw() -> void:
		var rng := RandomNumberGenerator.new()
		rng.seed = 11 if still else Time.get_ticks_msec()
		draw_rect(Rect2(Vector2.ZERO, size), Color(Explainer.INK, 0.35))
		for i in 220:
			var p := Vector2(rng.randf() * size.x, rng.randf() * size.y)
			draw_rect(Rect2(p, Vector2(rng.randf_range(6, 26), 3)), Color(Explainer.CHALK, rng.randf_range(0.15, 0.5)))
