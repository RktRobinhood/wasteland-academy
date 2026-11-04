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
##   solid       {"shape", and the measures as text under r, d, h, l, c, big, a, b, t, e, theta}:
##               a sketch of a cone, pyramid, sphere, hemisphere, composite, hollow cylinder,
##               cylinder inside a sphere or flat sector, with only the given measures labelled

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
	custom_minimum_size = Vector2(0, {"numberline": 260, "venn": 500, "tree": 620, "solid": 640}.get(s.get("kind"), 560))
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
		"solid":
			_solid()


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


# ── Solids ───────────────────────────────────────────────────

## Part of an ellipse from angle a to b, solid or dashed. Angles run clockwise from the right
## on screen, so 0 to PI is the near side of a circle seen from above.
func _rim(c: Vector2, rx: float, ry: float, a: float, b: float, col: Color, dashed: bool = false) -> void:
	var n := 48
	for i in n:
		if dashed and i % 2 == 1:
			continue
		var t0 := a + (b - a) * i / n
		var t1 := a + (b - a) * (i + 1) / n
		draw_line(c + Vector2(cos(t0) * rx, sin(t0) * ry), c + Vector2(cos(t1) * rx, sin(t1) * ry), col, 4.0 if not dashed else 3.0, true)


func _dashes(a: Vector2, b: Vector2, col: Color = UiTheme.DIM) -> void:
	var n := maxi(2, int(a.distance_to(b) / 18.0))
	for i in n:
		if i % 2 == 0:
			draw_line(a.lerp(b, float(i) / n), a.lerp(b, float(i + 1) / n), col, 3.0)


func _edge(a: Vector2, b: Vector2) -> void:
	draw_line(a, b, UiTheme.TEAL, 4.0, true)


## A corner square at c, along the unit directions u and v.
func _square(c: Vector2, u: Vector2, v: Vector2) -> void:
	var s := 20.0
	draw_polyline(PackedVector2Array([c + u * s, c + u * s + v * s, c + v * s]), UiTheme.DIM, 2.0)


## spec[key] at a point: centred, or starting there or ending there (align -1, 0, 1).
func _mark(key: String, at: Vector2, align: int = 0) -> void:
	if not spec.has(key):
		return
	var s: String = spec[key]
	var w := get_theme_default_font().get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE - 4).x
	var x := at.x - w / 2.0 if align == 0 else (at.x if align < 0 else at.x - w)
	_text(s, Vector2(clampf(x, 4.0, size.x - w - 4.0), at.y + 10.0), UiTheme.SAND, FONT_SIZE - 4, false)


## A measuring line from a to b with arrow ends, and spec[key] beside it.
func _measure(key: String, a: Vector2, b: Vector2, at: Vector2, align: int = -1) -> void:
	if not spec.has(key):
		return
	draw_line(a, b, UiTheme.DIM, 3.0)
	var u := (b - a).normalized()
	var n := Vector2(-u.y, u.x)
	for end in [[a, u], [b, -u]]:
		var tip: Vector2 = end[0]
		var dir: Vector2 = end[1]
		draw_colored_polygon(PackedVector2Array([tip, tip + dir * 16 + n * 7, tip + dir * 16 - n * 7]), UiTheme.DIM)
	_mark(key, at, align)


func _solid() -> void:
	var w := size.x
	var h := size.y
	var r := minf(w * 0.3, h * 0.3)
	var mid := Vector2(w * 0.45, h * 0.5)
	match spec.shape:
		"cone":
			_cone_top(Vector2(mid.x, h * 0.74), r * 1.15, h * 0.62, true)
			_rim(Vector2(mid.x, h * 0.74), r * 1.15, r * 0.3, 0.0, PI, UiTheme.TEAL)
			_circle_marks(Vector2(mid.x, h * 0.74), r * 1.15, r * 0.3, true)
		"pyramid":
			_pyramid()
		"sphere":
			draw_arc(mid, r * 1.2, 0.0, TAU, 96, UiTheme.TEAL, 4.0, true)
			_rim(mid, r * 1.2, r * 0.3, 0.0, PI, UiTheme.DIM)
			_rim(mid, r * 1.2, r * 0.3, PI, TAU, UiTheme.DIM, true)
			_circle_marks(mid, r * 1.2, r * 0.3, false)
		"hemisphere":
			var c := Vector2(mid.x, h * 0.68)
			_dome(c, r * 1.3, r * 0.34)
			_rim(c, r * 1.3, r * 0.34, 0.0, PI, UiTheme.TEAL)
			_circle_marks(c, r * 1.3, r * 0.34, false)
		"cone-hemisphere":
			var c := Vector2(mid.x, h * 0.54)
			_cone_top(c, r, h * 0.46, false)
			_rim(c, r, r, 0.0, PI, UiTheme.TEAL)
			_rim(c, r, r * 0.26, 0.0, PI, UiTheme.DIM)
			_circle_marks(c, r, r * 0.26, false)
		"cone-cylinder":
			var c := Vector2(mid.x, h * 0.46)
			_cone_top(c, r, h * 0.38, false)
			_drum(c, r, r * 0.26, h * 0.4, "c")
			_circle_marks(c, r, r * 0.26, false)
		"hemisphere-cylinder":
			var c := Vector2(mid.x, h * 0.42)
			_dome(c, r, r * 0.26)
			_drum(c, r, r * 0.26, h * 0.42, "c")
			_circle_marks(c, r, r * 0.26, false)
		"cylinder-minus-hemisphere":
			_scooped(mid, r * 1.2)
		"capsule":
			_capsule(mid, r * 0.8)
		"hollow":
			_hollow(mid, r * 1.15)
		"inscribed":
			_inscribed(mid, r * 1.3)
		"sector":
			_sector(mid, r * 1.3)


## The slant sides of a cone over a base centred at c, with its back edge dashed. `plain` draws
## the height from the apex and the slant label; a composite does too, but keeps its base.
func _cone_top(c: Vector2, rx: float, tall: float, plain: bool) -> void:
	var top := c - Vector2(0, tall)
	_edge(top, c + Vector2(rx, 0))
	_edge(top, c - Vector2(rx, 0))
	var ry := rx * (0.3 if plain else 0.26)
	_rim(c, rx, ry, PI, TAU, UiTheme.DIM, true)
	if spec.has("h"):
		_dashes(top, c)
		_square(c, Vector2.UP, Vector2.RIGHT)
		_mark("h", c + Vector2(-14, -tall * 0.42), 1)
	_mark("l", (top + c + Vector2(rx, 0)) / 2.0 + Vector2(18, -8), -1)


## A dome over a base centred at c, with its flat circle's back edge dashed.
func _dome(c: Vector2, rx: float, ry: float) -> void:
	_rim(c, rx, rx, PI, TAU, UiTheme.TEAL)
	_rim(c, rx, ry, PI, TAU, UiTheme.DIM, true)


## A cylinder hanging below a circle at c, and its height label.
func _drum(c: Vector2, rx: float, ry: float, tall: float, key: String) -> void:
	var low := c + Vector2(0, tall)
	_edge(c + Vector2(rx, 0), low + Vector2(rx, 0))
	_edge(c - Vector2(rx, 0), low - Vector2(rx, 0))
	_rim(c, rx, ry, 0.0, PI, UiTheme.DIM)
	_rim(low, rx, ry, 0.0, PI, UiTheme.TEAL)
	_rim(low, rx, ry, PI, TAU, UiTheme.DIM, true)
	var x := rx + 28.0
	_measure(key, c + Vector2(x, 0), low + Vector2(x, 0), (c + low) / 2.0 + Vector2(x + 12.0, 0))


## The radius or diameter drawn across a circle, with its label. `outside` puts a diameter's
## label below the rim.
func _circle_marks(c: Vector2, rx: float, ry: float, outside: bool) -> void:
	if spec.has("d"):
		_dashes(c - Vector2(rx, 0), c + Vector2(rx, 0), UiTheme.SAND)
		_mark("d", c + Vector2(0, ry + 34.0) if outside else c + Vector2(0, 30.0))
	elif spec.has("r"):
		_dashes(c, c + Vector2(rx, 0), UiTheme.SAND)
		_mark("r", c + Vector2(rx * 0.5, 30.0))


func _pyramid() -> void:
	var w := size.x
	var h := size.y
	var bl := Vector2(w * 0.12, h * 0.78)
	var br := Vector2(w * 0.62, h * 0.86)
	var tr := Vector2(w * 0.84, h * 0.66)
	var tl := bl + tr - br
	var centre := (bl + tr) / 2.0
	var top := Vector2(centre.x, h * 0.06)
	_edge(bl, br)
	_edge(br, tr)
	_edge(top, bl)
	_edge(top, br)
	_edge(top, tr)
	_dashes(bl, tl)
	_dashes(tl, tr)
	_dashes(top, tl)
	_mark("a", (bl + br) / 2.0 + Vector2(-10, 38))
	_mark("b", (br + tr) / 2.0 + Vector2(20, 26), -1)
	if spec.has("h"):
		_dashes(top, centre)
		_square(centre, Vector2.UP, Vector2.LEFT)
		_mark("h", (top + centre) / 2.0 + Vector2(12, 40), -1)
	if spec.has("t"):
		var foot := (bl + br) / 2.0
		_dashes(top, foot, UiTheme.SAND)
		_mark("t", top.lerp(foot, 0.5) + Vector2(-12, 0), 1)
	_mark("e", (top + tr) / 2.0 + Vector2(18, -6), -1)


## A cylinder with a bowl in its top.
func _scooped(c: Vector2, rx: float) -> void:
	var ry := rx * 0.26
	var tall := size.y * 0.56
	var top := c - Vector2(0, tall * 0.5)
	var low := top + Vector2(0, tall)
	_edge(top + Vector2(rx, 0), low + Vector2(rx, 0))
	_edge(top - Vector2(rx, 0), low - Vector2(rx, 0))
	_rim(top, rx, ry, 0.0, TAU, UiTheme.TEAL)
	_rim(low, rx, ry, 0.0, PI, UiTheme.TEAL)
	_rim(low, rx, ry, PI, TAU, UiTheme.DIM, true)
	var inner := rx * 0.62
	_rim(top, inner, inner * 0.26, 0.0, TAU, UiTheme.TEAL)
	_rim(top, inner, inner, 0.0, PI, UiTheme.DIM, true)
	_dashes(top, top + Vector2(inner, 0), UiTheme.SAND)
	_mark("r", top + Vector2(inner * 0.5, 30.0))
	_dashes(low, low + Vector2(rx, 0), UiTheme.SAND)
	_mark("big", low + Vector2(rx * 0.5, -22.0))
	var x := rx + 28.0
	_measure("c", top + Vector2(x, 0), low + Vector2(x, 0), c + Vector2(x + 12.0, 0))


## A cylinder lying down with a hemisphere on each end.
func _capsule(c: Vector2, rx: float) -> void:
	var len := minf(rx * 1.5, size.x * 0.34)
	var a := c - Vector2(len / 2.0, 0)
	var b := c + Vector2(len / 2.0, 0)
	draw_arc(a, rx, PI * 0.5, PI * 1.5, 48, UiTheme.TEAL, 4.0, true)
	draw_arc(b, rx, -PI * 0.5, PI * 0.5, 48, UiTheme.TEAL, 4.0, true)
	_edge(a - Vector2(0, rx), b - Vector2(0, rx))
	_edge(a + Vector2(0, rx), b + Vector2(0, rx))
	_rim(a, rx * 0.26, rx, -PI * 0.5, PI * 0.5, UiTheme.DIM, true)
	_rim(b, rx * 0.26, rx, PI * 0.5, PI * 1.5, UiTheme.DIM, true)
	_rim(a, rx * 0.26, rx, PI * 0.5, PI * 1.5, UiTheme.DIM)
	_rim(b, rx * 0.26, rx, -PI * 0.5, PI * 0.5, UiTheme.DIM)
	var y := rx + 28.0
	_measure("c", a + Vector2(0, y), b + Vector2(0, y), c + Vector2(0, y + 40.0), 0)
	_dashes(b, b - Vector2(0, rx), UiTheme.SAND)
	_mark("r", b + Vector2(16, -rx * 0.5), -1)


## A cylinder with a smaller one taken out of its centre.
func _hollow(c: Vector2, rx: float) -> void:
	var ry := rx * 0.3
	var tall := size.y * 0.52
	var top := c - Vector2(0, tall * 0.5)
	var low := top + Vector2(0, tall)
	var inner := rx * 0.42
	_edge(top + Vector2(rx, 0), low + Vector2(rx, 0))
	_edge(top - Vector2(rx, 0), low - Vector2(rx, 0))
	_rim(top, rx, ry, 0.0, TAU, UiTheme.TEAL)
	_rim(low, rx, ry, 0.0, PI, UiTheme.TEAL)
	_rim(low, rx, ry, PI, TAU, UiTheme.DIM, true)
	_rim(top, inner, inner * 0.3, 0.0, TAU, UiTheme.TEAL)
	_dashes(top + Vector2(inner, 0), low + Vector2(inner, 0))
	_dashes(top - Vector2(inner, 0), low - Vector2(inner, 0))
	var up := top - Vector2(0, ry + 16.0)
	_measure("r", up, up + Vector2(inner, 0), up + Vector2(inner * 0.5, -32.0), 0)
	_measure("big", up, up + Vector2(rx, 0), up + Vector2(rx * 0.75, -32.0), 0)
	if spec.has("big"):
		draw_line(top, up, UiTheme.DIM, 2.0)
	var x := rx + 28.0
	_measure("h", top + Vector2(x, 0), low + Vector2(x, 0), c + Vector2(x + 12.0, 0))


## A cylinder that fits exactly inside a sphere.
func _inscribed(c: Vector2, rx: float) -> void:
	draw_arc(c, rx, 0.0, TAU, 96, UiTheme.TEAL, 4.0, true)
	var half := rx * 0.62
	var wide := sqrt(rx * rx - half * half)
	var ry := wide * 0.24
	var top := c - Vector2(0, half)
	var low := c + Vector2(0, half)
	_edge(top + Vector2(wide, 0), low + Vector2(wide, 0))
	_edge(top - Vector2(wide, 0), low - Vector2(wide, 0))
	_rim(top, wide, ry, 0.0, TAU, UiTheme.DIM)
	_rim(low, wide, ry, 0.0, PI, UiTheme.DIM)
	_rim(low, wide, ry, PI, TAU, UiTheme.DIM, true)
	var x := rx + 26.0
	_measure("h", c - Vector2(x, half), c - Vector2(x, -half), c - Vector2(x - 14.0, 48.0 - half * 0.0), 1)
	_dashes(c, c + Vector2(rx, 0).rotated(-0.32), UiTheme.SAND)
	_mark("r", c + Vector2(rx * 0.5, -rx * 0.28))


## A flat sector. The angle is drawn to size when the label gives it.
func _sector(c: Vector2, rad: float) -> void:
	var text: String = spec.get("theta", "")
	var deg := text.to_float()
	if deg <= 0.0:
		deg = 216.0
	var sweep := deg_to_rad(deg)
	var start := -PI / 2.0 - sweep / 2.0
	var o := c + Vector2(0, rad * 0.14)
	var a := o + Vector2(cos(start), sin(start)) * rad
	var b := o + Vector2(cos(start + sweep), sin(start + sweep)) * rad
	_edge(o, a)
	_edge(o, b)
	draw_arc(o, rad, start, start + sweep, 96, UiTheme.TEAL, 4.0, true)
	draw_arc(o, rad * 0.2, start, start + sweep, 32, UiTheme.SAND, 3.0, true)
	var up := o + Vector2(0, -rad * 0.34)
	_mark("theta", up)
	var m := (o + b) / 2.0
	_mark("l", m + Vector2(16, 30), -1)
