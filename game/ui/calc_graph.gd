class_name CalcGraph
extends Control
## The calculator's graph screen (FAL-419), drawn with Godot's own 2D drawing: up to two
## functions in a window that pans (drag) and zooms (wheel, pinch or the calculator's
## buttons), a trace cursor (tap), gaps where a curve jumps at an asymptote
## (GraphTools.jumps), and the graph tools' marks in Dust Yellow.

signal traced(fn: int, x: float, y: float)
signal view_changed

const SCREEN := Color("#1F2937")
const MINT := Color("#9FF0E6")
const COLORS := [Color("#22D3C5"), Color("#FF3DA7")]
const MARK := Color("#EACB74")
const LINE_WIDTH := 5.0
## Base units between curve samples.
const STEP := 3.0

## Each function: a parsed tree from Expr, or null when its line is empty.
var functions: Array = [null, null]
var deg := false
var x_min := -10.0
var x_max := 10.0
var y_min := -10.0
var y_max := 10.0
## The tools' marks: {"x", "y"}.
var marks: Array = []
## The trace cursor: {"fn", "x"}, or {} for none. The function traced is `trace_fn`.
var trace := {}
var trace_fn := 0
var font: Font

var _drag_from := Vector2.ZERO
var _dragged := false
var _touches := {}
var _pinch_from := 0.0


func _init() -> void:
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	custom_minimum_size = Vector2(0, 560)


func function_at(i: int) -> Callable:
	return GraphTools.function_of(functions[i], deg) if functions[i] != null else Callable()


func set_window(x0: float, x1: float, y0: float, y1: float) -> void:
	x_min = x0
	x_max = x1
	y_min = y0
	y_max = y1
	queue_redraw()
	view_changed.emit()


## Zooms by `factor` (2 shows twice as much) about a point of the screen (the centre
## by default).
func zoom(factor: float, about: Vector2 = Vector2(-1, -1)) -> void:
	var p := about if about.x >= 0.0 else size / 2.0
	var cx := _to_x(p.x)
	var cy := _to_y(p.y)
	set_window(cx - (cx - x_min) * factor, cx + (x_max - cx) * factor, cy - (cy - y_min) * factor, cy + (y_max - cy) * factor)


func pan(by: Vector2) -> void:
	var dx := -by.x / size.x * (x_max - x_min)
	var dy := by.y / size.y * (y_max - y_min)
	set_window(x_min + dx, x_max + dx, y_min + dy, y_max + dy)


## Puts the trace cursor on function `fn` at x, and says where it is.
func trace_at(fn: int, x: float) -> void:
	if functions[fn] == null:
		return
	trace = {"fn": fn, "x": x}
	queue_redraw()
	traced.emit(fn, x, function_at(fn).call(x))


func _to_x(px: float) -> float:
	return x_min + px / maxf(size.x, 1.0) * (x_max - x_min)


func _to_y(py: float) -> float:
	return y_max - py / maxf(size.y, 1.0) * (y_max - y_min)


func to_screen(x: float, y: float) -> Vector2:
	var px := (x - x_min) / (x_max - x_min) * size.x
	var py := (y_max - y) / (y_max - y_min) * size.y
	# Far off screen: kept in range so the drawing stays sane.
	return Vector2(px, clampf(py, -4.0 * size.y, 5.0 * size.y))


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_WHEEL_UP and mb.pressed:
			zoom(0.8, mb.position)
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN and mb.pressed:
			zoom(1.25, mb.position)
		elif mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				_drag_from = mb.position
				_dragged = false
			elif not _dragged:
				trace_at(trace_fn, _to_x(mb.position.x))
		accept_event()
	elif event is InputEventMouseMotion and (event.button_mask & MOUSE_BUTTON_MASK_LEFT) and _touches.size() < 2:
		var by: Vector2 = event.position - _drag_from
		if _dragged or by.length() > 12.0:
			_dragged = true
			pan(by)
			_drag_from = event.position
		accept_event()
	elif event is InputEventScreenTouch:
		if event.pressed:
			_touches[event.index] = event.position
		else:
			_touches.erase(event.index)
		_pinch_from = _pinch_distance()
	elif event is InputEventScreenDrag:
		_touches[event.index] = event.position
		if _touches.size() >= 2:
			var d := _pinch_distance()
			if _pinch_from > 0.0 and d > 0.0:
				zoom(_pinch_from / d)
			_pinch_from = d
			_dragged = true
			accept_event()
	elif event is InputEventMagnifyGesture:
		zoom(1.0 / event.factor, event.position)
		accept_event()


func _pinch_distance() -> float:
	var ps := _touches.values()
	return (ps[0] as Vector2).distance_to(ps[1]) if ps.size() >= 2 else 0.0


## A tidy grid step: 1, 2 or 5 times a power of ten, about `lines` lines across.
static func nice_step(span: float, lines: float = 8.0) -> float:
	var raw := span / lines
	var p := pow(10.0, floorf(log(raw) / log(10.0)))
	for m in [1.0, 2.0, 5.0, 10.0]:
		if raw <= m * p:
			return m * p
	return 10.0 * p


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), SCREEN)
	_draw_grid()
	for i in functions.size():
		if functions[i] != null:
			_draw_curve(function_at(i), COLORS[i])
	for m in marks:
		var p := to_screen(m.x, m.y)
		draw_circle(p, 14.0, Color(MARK, 0.35))
		draw_circle(p, 9.0, MARK)
	if not trace.is_empty() and functions[trace.fn] != null:
		var y: float = function_at(trace.fn).call(trace.x)
		if is_finite(y):
			var p := to_screen(trace.x, y)
			draw_line(Vector2(p.x, 0), Vector2(p.x, size.y), Color(MINT, 0.35), 2.0)
			draw_line(Vector2(0, p.y), Vector2(size.x, p.y), Color(MINT, 0.35), 2.0)
			draw_arc(p, 13.0, 0.0, TAU, 24, COLORS[trace.fn], 4.0)


func _draw_grid() -> void:
	var sx := nice_step(x_max - x_min)
	var sy := nice_step(y_max - y_min, 8.0 * size.y / maxf(size.x, 1.0))
	var x := ceilf(x_min / sx) * sx
	while x <= x_max:
		var px := to_screen(x, 0).x
		draw_line(Vector2(px, 0), Vector2(px, size.y), Color(MINT, 0.08), 2.0)
		x += sx
	var y := ceilf(y_min / sy) * sy
	while y <= y_max:
		var py := to_screen(0, y).y
		draw_line(Vector2(0, py), Vector2(size.x, py), Color(MINT, 0.08), 2.0)
		y += sy
	# Axes, with numbers along them (kept on screen when the axis isn't).
	var o := to_screen(0, 0)
	if x_min <= 0.0 and x_max >= 0.0:
		draw_line(Vector2(o.x, 0), Vector2(o.x, size.y), Color(MINT, 0.5), 3.0)
	if y_min <= 0.0 and y_max >= 0.0:
		draw_line(Vector2(0, o.y), Vector2(size.x, o.y), Color(MINT, 0.5), 3.0)
	if font == null:
		return
	var fs := 24
	var ly := clampf(o.y + 28.0, 28.0, size.y - 8.0)
	x = ceilf(x_min / sx) * sx
	while x <= x_max:
		if absf(x) > sx * 0.01:
			draw_string(font, Vector2(to_screen(x, 0).x + 4.0, ly), CalcFormat.short(x), HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(MINT, 0.6))
		x += 2.0 * sx
	var lx := clampf(o.x + 6.0, 6.0, size.x - 90.0)
	y = ceilf(y_min / sy) * sy
	while y <= y_max:
		if absf(y) > sy * 0.01:
			draw_string(font, Vector2(lx, to_screen(0, y).y - 4.0), CalcFormat.short(y), HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(MINT, 0.6))
		y += 2.0 * sy


## Samples f across the screen and draws it, broken where it has no value or jumps.
func _draw_curve(f: Callable, color: Color) -> void:
	var span := y_max - y_min
	var seg := PackedVector2Array()
	var n := maxi(2, int(size.x / STEP))
	var x0 := x_min
	var y0: float = f.call(x0)
	if is_finite(y0):
		seg.append(to_screen(x0, y0))
	for i in range(1, n + 1):
		var x := x_min + (x_max - x_min) * i / n
		var y: float = f.call(x)
		var gap := not is_finite(y) or not is_finite(y0)
		if not gap and absf(y - y0) > 0.5 * span and GraphTools.jumps(f, x0, x):
			gap = true
		if gap:
			if seg.size() >= 2:
				draw_polyline(seg, color, LINE_WIDTH, true)
			seg = PackedVector2Array()
		if is_finite(y):
			seg.append(to_screen(x, y))
		x0 = x
		y0 = y
	if seg.size() >= 2:
		draw_polyline(seg, color, LINE_WIDTH, true)
