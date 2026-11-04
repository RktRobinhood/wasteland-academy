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
##   venn        {"names": [A, B], "a", "i", "b", "o"}: two circles in a box, with the text of
##               each region: A only, both, B only and outside
##   tree        {"first": [A, A′], "second": [B, B′], "p": [2 labels], "q": [[2 labels], [2 labels]]}:
##               a two-stage tree with the probability on every branch
##   cumfreq     {"x1", "dx", "y1", "dy", "curve": [[x, y], ...], "x_name", "y_name"}: a cumulative
##               frequency curve on a grid of dx by dy squares, with every fifth line bold and labelled

const PAD := 26.0
const FONT_SIZE := 32
const DOT := 13.0
const LABEL_GAP := 90.0

var spec: Dictionary = {}


func _init() -> void:
	custom_minimum_size = Vector2(0, 520)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func set_spec(s: Dictionary) -> void:
	spec = s
	custom_minimum_size = Vector2(0, {"numberline": 260, "venn": 500, "tree": 620, "cumfreq": 900}.get(s.get("kind"), 560))
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
		"venn":
			_venn()
		"tree":
			_tree()
		"cumfreq":
			_cumfreq()


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
	var r := Rect2(Vector2(PAD, PAD + 20), size - Vector2(PAD * 2, PAD * 2 + 110))
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
	# Two values close together: the second label drops a row, so they don't run into each other.
	var placed: Array = []
	for m in spec.get("marks", []):
		var p: Vector2 = to_px.call(float(m.at), 0.0)
		var drop := 34.0 if placed.any(func(x): return absf(x - p.x) < LABEL_GAP) else 0.0
		placed.append(p.x)
		draw_line(p, p + Vector2(0, 16), UiTheme.TEXT, 3.0)
		_text(m.label, p + Vector2(0, 54 + drop), UiTheme.TEXT, FONT_SIZE - 4)


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


# ── Venn diagram ─────────────────────────────────────────────

func _venn() -> void:
	var box := Rect2(Vector2(PAD, PAD), size - Vector2(PAD, PAD) * 2.0)
	draw_rect(box, UiTheme.DIM, false, 4.0)
	var mid := box.position + box.size / 2.0
	var r := minf(box.size.x * 0.27, box.size.y * 0.4)
	var left := mid - Vector2(r * 0.62, 0)
	var right := mid + Vector2(r * 0.62, 0)
	draw_circle(left, r, Color(UiTheme.TEAL, 0.14))
	draw_circle(right, r, Color(UiTheme.SAND, 0.14))
	draw_arc(left, r, 0.0, TAU, 96, UiTheme.TEAL, 5.0, true)
	draw_arc(right, r, 0.0, TAU, 96, UiTheme.SAND, 5.0, true)
	var names: Array = spec.get("names", ["A", "B"])
	_text(names[0], left + Vector2(-r * 0.72, -r * 0.82), UiTheme.TEAL)
	_text(names[1], right + Vector2(r * 0.72, -r * 0.82), UiTheme.SAND)
	var base := Vector2(0, FONT_SIZE * 0.35)
	_text(spec.a, left + Vector2(-r * 0.42, 0) + base, UiTheme.TEXT, FONT_SIZE - 2)
	_text(spec.i, mid + base, UiTheme.TEXT, FONT_SIZE - 2)
	_text(spec.b, right + Vector2(r * 0.42, 0) + base, UiTheme.TEXT, FONT_SIZE - 2)
	_text(spec.o, box.end - Vector2(96, 26), UiTheme.TEXT, FONT_SIZE - 2)


# ── Tree diagram ─────────────────────────────────────────────

func _tree() -> void:
	var w := size.x
	var h := size.y
	var root := Vector2(PAD + 10, h / 2.0)
	var mids: Array = [Vector2(w * 0.42, h * 0.26), Vector2(w * 0.42, h * 0.74)]
	var ends: Array = [[Vector2(w * 0.86, h * 0.1), Vector2(w * 0.86, h * 0.38)], [Vector2(w * 0.86, h * 0.62), Vector2(w * 0.86, h * 0.9)]]
	var first: Array = spec.first
	var second: Array = spec.second
	for i in 2:
		var m: Vector2 = mids[i]
		draw_line(root, m - Vector2(30, 0), UiTheme.TEAL, 4.0, true)
		var lift := -30.0 if i == 0 else 42.0
		_text(spec.p[i], (root + m) / 2.0 + Vector2(-16, lift), UiTheme.SAND, FONT_SIZE - 2)
		_text(first[i], m + Vector2(0, 12), UiTheme.TEXT)
		for j in 2:
			var e: Vector2 = ends[i][j]
			draw_line(m + Vector2(30, 0), e - Vector2(30, 0), UiTheme.TEAL, 4.0, true)
			var up := -28.0 if j == 0 else 40.0
			_text(spec.q[i][j], (m + e) / 2.0 + Vector2(-10, up), UiTheme.SAND, FONT_SIZE - 2)
			_text(second[j], e + Vector2(10, 12), UiTheme.TEXT)


# ── Cumulative frequency curve ───────────────────────────────

func _cumfreq() -> void:
	var x1 := float(spec.x1)
	var y1 := float(spec.y1)
	var dx := float(spec.dx)
	var dy := float(spec.dy)
	var r := Rect2(Vector2(PAD + 96, PAD + 10), size - Vector2(PAD * 2 + 120, PAD + 116))
	var to_px := func(x: float, yv: float) -> Vector2:
		return Vector2(r.position.x + x / x1 * r.size.x, r.end.y - yv / y1 * r.size.y)
	var across := roundi(x1 / dx)
	var up := roundi(y1 / dy)
	for k in across + 1:
		draw_line(to_px.call(k * dx, 0.0), to_px.call(k * dx, y1), UiTheme.GRID_MAJOR if k % 5 == 0 else UiTheme.GRID, 2.0)
		if k % 5 == 0 and k > 0:
			_text(_n(k * dx), to_px.call(k * dx, 0.0) + Vector2(0, 42), UiTheme.DIM, FONT_SIZE - 6)
	for k in up + 1:
		draw_line(to_px.call(0.0, k * dy), to_px.call(x1, k * dy), UiTheme.GRID_MAJOR if k % 5 == 0 else UiTheme.GRID, 2.0)
		if k % 5 == 0 and k > 0:
			var label := _n(k * dy)
			var w := get_theme_default_font().get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE - 6).x
			_text(label, to_px.call(0.0, k * dy) + Vector2(-w - 10, 9), UiTheme.DIM, FONT_SIZE - 6, false)
	_text("0", to_px.call(0.0, 0.0) + Vector2(-20, 34), UiTheme.DIM, FONT_SIZE - 6)
	draw_line(to_px.call(0.0, 0.0), to_px.call(x1, 0.0), UiTheme.DIM, 4.0)
	draw_line(to_px.call(0.0, 0.0), to_px.call(0.0, y1), UiTheme.DIM, 4.0)
	var line := PackedVector2Array()
	for p in spec.curve:
		line.append(to_px.call(float(p[0]), float(p[1])))
	draw_polyline(line, UiTheme.TEAL, 5.0, true)
	_text(spec.x_name, Vector2(r.get_center().x, size.y - 12), UiTheme.TEXT, FONT_SIZE - 4)
	draw_set_transform(Vector2(PAD + 8, r.get_center().y), -PI / 2.0)
	_text(spec.y_name, Vector2.ZERO, UiTheme.TEXT, FONT_SIZE - 4)
	draw_set_transform(Vector2.ZERO)
