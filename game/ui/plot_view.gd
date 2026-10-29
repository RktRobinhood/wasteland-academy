class_name PlotView
extends Control
## Draws the graphs of the Quadratics extension types (FAL-459) that are not a
## parabola: a question's "graph" with a "kind" (GraphView draws the rest).
##
##   numberline  {"x0", "x1", "marks": [{"at", "open"}], "segment": {"from", "to"}}:
##               a number line with a thick segment (null at an end runs off as an
##               arrow) and open or closed circles
##   normal      {"mu", "sigma", "x0", "x1", "shade": [[from, to]], "marks": [{"at", "label"}]}:
##               a normal curve with its areas shaded (null is an open end)
##   trig        {"fn": "sin" or "cos", "line", "points": [{"x", "y", "label"}]}: y = sin x
##               or cos x on [0, 2π] with π ticks, a level line and marked points
##   bars        {"xs", "ys", "hide": [index]}: one bar per x, its value on top (a row
##               of Pascal's triangle); hidden values show "?"

const PAD := 26.0
const FONT_SIZE := 32
const DOT := 13.0

var spec: Dictionary = {}


func _init() -> void:
	custom_minimum_size = Vector2(0, 520)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func set_spec(s: Dictionary) -> void:
	spec = s
	custom_minimum_size = Vector2(0, 260 if s.get("kind") == "numberline" else 560)
	queue_redraw()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()


func _draw() -> void:
	if spec.is_empty():
		return
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.08, 0.1, 0.14))
	match spec.get("kind", ""):
		"numberline":
			_numberline()
		"normal":
			_normal()
		"trig":
			_trig()
		"bars":
			_bars()


func _text(s: String, at: Vector2, col: Color, fs: int = FONT_SIZE, centred: bool = true) -> void:
	var font := get_theme_default_font()
	var w := font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	draw_string(font, at - Vector2(w / 2.0 if centred else 0.0, 0), s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)


static func _n(v: float) -> String:
	var r := roundi(v)
	if absf(v - r) < 1e-9:
		return ("−" if r < 0 else "") + str(absi(r))
	return ("−" if v < 0 else "") + str(snappedf(absf(v), 0.01))


# ── Number line ──────────────────────────────────────────────

func _numberline() -> void:
	var x0 := float(spec.x0)
	var x1 := float(spec.x1)
	var y := size.y * 0.45
	var left := PAD + 20.0
	var right := size.x - PAD - 20.0
	var px := func(v: float) -> float: return left + (v - x0) / (x1 - x0) * (right - left)
	draw_line(Vector2(PAD, y), Vector2(size.x - PAD, y), UiTheme.DIM, 4.0)
	for v in range(int(ceil(x0)), int(floor(x1)) + 1):
		var p: float = px.call(float(v))
		draw_line(Vector2(p, y - 14), Vector2(p, y + 14), UiTheme.DIM, 3.0)
		_text(_n(v), Vector2(p, y + 58), UiTheme.DIM, FONT_SIZE - 4)
	var seg: Dictionary = spec.get("segment", {})
	var a: float = px.call(float(seg.from)) if seg.get("from") != null else PAD
	var b: float = px.call(float(seg.to)) if seg.get("to") != null else size.x - PAD
	draw_line(Vector2(a, y - 30), Vector2(b, y - 30), UiTheme.TEAL, 10.0)
	if seg.get("from") == null:
		draw_colored_polygon(PackedVector2Array([Vector2(PAD - 6, y - 30), Vector2(PAD + 22, y - 46), Vector2(PAD + 22, y - 14)]), UiTheme.TEAL)
	if seg.get("to") == null:
		var e := size.x - PAD
		draw_colored_polygon(PackedVector2Array([Vector2(e + 6, y - 30), Vector2(e - 22, y - 46), Vector2(e - 22, y - 14)]), UiTheme.TEAL)
	for m in spec.get("marks", []):
		var c := Vector2(px.call(float(m.at)), y - 30)
		draw_circle(c, DOT + 4, UiTheme.TEAL)
		draw_circle(c, DOT - 1, UiTheme.BG if m.open else UiTheme.TEAL)


# ── Normal curve ─────────────────────────────────────────────

func _normal() -> void:
	var mu := float(spec.mu)
	var sigma := float(spec.sigma)
	var x0 := float(spec.x0)
	var x1 := float(spec.x1)
	var top := 1.0 / (sigma * sqrt(TAU))
	var r := Rect2(Vector2(PAD, PAD + 20), size - Vector2(PAD * 2, PAD * 2 + 90))
	var to_px := func(x: float, yv: float) -> Vector2:
		return Vector2(r.position.x + (x - x0) / (x1 - x0) * r.size.x, r.end.y - yv / (top * 1.1) * r.size.y)
	var pdf := func(x: float) -> float: return top * exp(-0.5 * pow((x - mu) / sigma, 2))
	for sh in spec.get("shade", []):
		var a := float(sh[0]) if sh[0] != null else x0
		var b := float(sh[1]) if sh[1] != null else x1
		var poly := PackedVector2Array([to_px.call(a, 0.0)])
		for i in 81:
			var x := a + (b - a) * i / 80.0
			poly.append(to_px.call(x, pdf.call(x)))
		poly.append(to_px.call(b, 0.0))
		draw_colored_polygon(poly, Color(UiTheme.SAND, 0.45))
	var curve := PackedVector2Array()
	for i in 241:
		var x := x0 + (x1 - x0) * i / 240.0
		curve.append(to_px.call(x, pdf.call(x)))
	draw_polyline(curve, UiTheme.TEAL, 6.0, true)
	draw_line(to_px.call(x0, 0.0), to_px.call(x1, 0.0), UiTheme.DIM, 4.0)
	var dash := r.size.y / 24.0
	var mx: Vector2 = to_px.call(mu, 0.0)
	var t := 0.0
	while t < r.size.y:
		draw_line(mx - Vector2(0, t), mx - Vector2(0, minf(t + dash * 0.5, r.size.y)), UiTheme.DIM, 3.0)
		t += dash
	for m in spec.get("marks", []):
		var p: Vector2 = to_px.call(float(m.at), 0.0)
		draw_line(p, p + Vector2(0, 16), UiTheme.TEXT, 3.0)
		_text(m.label, p + Vector2(0, 54), UiTheme.TEXT, FONT_SIZE - 4)


# ── sin x or cos x ───────────────────────────────────────────

func _trig() -> void:
	var r := Rect2(Vector2(PAD + 40, PAD + 10), size - Vector2(PAD * 2 + 50, PAD * 2 + 70))
	var to_px := func(x: float, yv: float) -> Vector2:
		return Vector2(r.position.x + x / TAU * r.size.x, r.position.y + (1.25 - yv) / 2.5 * r.size.y)
	for k in 13:
		var x := k * PI / 6.0
		var major := k % 3 == 0
		draw_line(to_px.call(x, -1.2), to_px.call(x, 1.2), UiTheme.GRID_MAJOR if major else UiTheme.GRID, 2.0)
	for yv in [-1.0, -0.5, 0.5, 1.0]:
		draw_line(to_px.call(0.0, yv), to_px.call(TAU, yv), UiTheme.GRID, 2.0)
	draw_line(to_px.call(0.0, 0.0), to_px.call(TAU, 0.0), UiTheme.DIM, 4.0)
	draw_line(to_px.call(0.0, -1.2), to_px.call(0.0, 1.2), UiTheme.DIM, 4.0)
	for lab in [[PI / 2, "π/2"], [PI, "π"], [1.5 * PI, "3π/2"], [TAU, "2π"]]:
		_text(lab[1], to_px.call(lab[0], 0.0) + Vector2(0, 40), UiTheme.DIM, FONT_SIZE - 6)
	_text("1", to_px.call(0.0, 1.0) + Vector2(-26, 10), UiTheme.DIM, FONT_SIZE - 6)
	_text("−1", to_px.call(0.0, -1.0) + Vector2(-30, 10), UiTheme.DIM, FONT_SIZE - 6)
	if spec.get("line") != null:
		var lv := float(spec.line)
		var x := 0.0
		while x < TAU:
			draw_line(to_px.call(x, lv), to_px.call(minf(x + 0.12, TAU), lv), UiTheme.SAND, 4.0)
			x += 0.24
	var curve := PackedVector2Array()
	for i in 241:
		var x := TAU * i / 240.0
		curve.append(to_px.call(x, sin(x) if spec.fn == "sin" else cos(x)))
	draw_polyline(curve, UiTheme.TEAL, 6.0, true)
	for p in spec.get("points", []):
		var c: Vector2 = to_px.call(float(p.x), float(p.y))
		draw_circle(c, DOT, UiTheme.PINK)
		draw_circle(c, DOT * 0.45, UiTheme.BG)
		_text(p.label, c + Vector2(0, -24 if float(p.y) >= 0.0 else 50), UiTheme.TEXT, FONT_SIZE - 4)


# ── Bars ─────────────────────────────────────────────────────

func _bars() -> void:
	var xs: Array = spec.xs
	var ys: Array = spec.ys
	var hide: Array = spec.get("hide", [])
	var top := 0.0
	for v in ys:
		top = maxf(top, float(v))
	var r := Rect2(Vector2(PAD, PAD + 46), size - Vector2(PAD * 2, PAD * 2 + 100))
	var w := r.size.x / xs.size()
	for i in xs.size():
		var h := float(ys[i]) / top * r.size.y
		var rect := Rect2(Vector2(r.position.x + i * w + w * 0.15, r.end.y - h), Vector2(w * 0.7, h))
		draw_rect(rect, Color(UiTheme.TEAL, 0.35 if i in hide else 0.85))
		_text("?" if i in hide else _n(float(ys[i])), Vector2(rect.get_center().x, rect.position.y - 10), UiTheme.TEXT, FONT_SIZE - 8)
		_text(_n(float(xs[i])), Vector2(rect.get_center().x, r.end.y + 40), UiTheme.DIM, FONT_SIZE - 6)
	draw_line(Vector2(r.position.x, r.end.y), Vector2(r.end.x, r.end.y), UiTheme.DIM, 4.0)
